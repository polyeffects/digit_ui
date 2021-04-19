import sys, time, json, os.path, os, subprocess, queue, threading, traceback, glob
import shutil
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit
from collections import OrderedDict
from enum import Enum, IntEnum
import urllib.parse
# import random
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal, QTimer, QThreadPool, QRunnable, qWarning, qCritical, qDebug
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtGui import QIcon, QFontDatabase, QFont
# # compiled QML files, compile with pyside2-rcc
# import qml.qml

sys._excepthook = sys.excepthook
def exception_hook(exctype, value, tb):
    debug_print("except hook 1 got a thing!") #, exctype, value, traceback)
    traceback.print_exception(exctype, value, tb)
    sys._excepthook(exctype, value, tb)
    sys.exit(1)
sys.excepthook = exception_hook

os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
import icons.icons
# #, imagine_assets
import resource_rc

import ingen_wrapper
import pedal_hardware
import module_info
from static_globals import IS_REMOTE_TEST
import loopler as loopler_lib

worker_pool = QThreadPool()
EXIT_PROCESS = [False]
ui_messages = queue.Queue()

current_source_port = None
current_sub_graph = "/main/sub1/"
sub_graphs = set(["/main/sub1"])
# current_effects = OrderedDict()
current_effects = {}
# current_effects["delay1"] = {"x": 20, "y": 30, "effect_type": "delay", "controls": {}, "highlight": False}
# current_effects["delay2"] = {"x": 250, "y": 290, "effect_type": "delay", "controls": {}, "highlight": False}
port_connections = {} # key is port, value is list of ports
current_patchbay_mode = 0
current_selected_effect = ""
footswitch_assignments = {}
looper_footswitch_assignments = {}
preset_started_loading_time = 0

def reset_footswitch_assignments():
    global footswitch_assignments
    footswitch_assignments = {"a":set(), "b":set(), "c":set(), "d":set(), "e":set()}

reset_footswitch_assignments()

def reset_looper_footswitch_assignments():
    global looper_footswitch_assignments
    looper_footswitch_assignments = {"a":[], "b":[], "c":[], "d":[], "e":[]}

reset_looper_footswitch_assignments()

class PatchMode(IntEnum):
    SELECT = 0
    MOVE = 1
    CONNECT = 2
    SLIDERS = 3
    DETAILS = 4
    HOLD = 5

context = None

def debug_print(*args, **kwargs):
    pass
    # print( "From py: "+" ".join(map(str,args)), **kwargs)


effect_type_maps = module_info.effect_type_maps

effect_prototypes_models_all = module_info.effect_prototypes_models_all

for k, v in effect_prototypes_models_all.items():
    n = 0
    for p in v["inputs"].values():
        if p[1] == "CVPort":
            n = n + 1
    effect_prototypes_models_all[k]["num_cv_in"] = n

effect_prototypes_models = {"beebo": {k:effect_prototypes_models_all[k] for k in effect_type_maps["beebo"].keys()}}

for k in effect_prototypes_models.keys():
    effect_prototypes_models[k]["input"] = {"inputs": {},
            "outputs": {"output": ["in", "AudioPort"]},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["output"] = {"inputs": {"input": ["out", "AudioPort"]},
            "outputs": {},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["midi_input"] = {"inputs": {},
            "outputs": {"output": ["in", "AtomPort"]},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["midi_output"] = {"inputs": {"input": ["out", "AtomPort"]},
            "outputs": {},
            "num_cv_in": 0,
            "controls": {}}

bare_output_ports =  ("output", "midi_output", "loop_common_in")
bare_input_ports = ("input", "midi_input", "loop_common_out")
bare_ports = bare_output_ports + bare_input_ports
loopler_modules = ["loop_common_in", "loop_common_out"]


def clamp(v, min_value, max_value):
    return max(min(v, max_value), min_value)

def insert_row(model, row):
    j = len(model.stringList())
    model.insertRows(j, 1)
    model.setData(model.index(j), row)

def remove_row(model, row):
    i = model.stringList().index(row)
    model.removeRows(i, 1)

preset_list = []
preset_list_model = QStringListModel(preset_list)
hardware_info = {}
def load_preset_list():
    global preset_list
    try:
        with open("/mnt/pedal_state/beebo_preset_list.json") as f:
            preset_list = json.load(f)
    except:
        preset_list = ["file:///mnt/presets/beebo/Empty.ingen"]
    preset_list_model.setStringList(preset_list)

try:
    with open("/pedal_state/hardware_info.json") as f:
        hardware_info = json.load(f)
    hardware_info["revision"]
except:
    hardware_info = {"revision": 10, "pedal": "beebo"}

if hardware_info["pedal"] == "digit":
    hardware_info["pedal"] = "beebo"

class MyEmitter(QObject):
    # setting up custom signal
    done = Signal(int)

class MyWorker(QRunnable):

    def __init__(self, command, after=None):
        super(MyWorker, self).__init__()
        self.command = command
        self.after = after
        self.emitter = MyEmitter()

    def run(self):
        # run subprocesses, grab output
        ret_var = subprocess.call(self.command, shell=True)
        if self.after is not None:
            self.after()
        self.emitter.done.emit(ret_var)

class MyTask(QRunnable):

    def __init__(self, delay, command):
        super(MyTask, self).__init__()
        self.command = command
        self.delay = delay
        self.emitter = MyEmitter()

    def run(self):
        # run subprocesses, grab output
        time.sleep(self.delay)
        ret_var = self.command()
        self.emitter.done.emit(ret_var)

class PolyBool(QObject):
    # name, min, max, value
    def __init__(self, startval=False):
        QObject.__init__(self)
        self.valueval = startval

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        self.valueval = val
        self.value_changed.emit()

    @Signal
    def value_changed(self):
        pass

    value = Property(bool, readValue, setValue, notify=value_changed)

class PolyStr(QObject):
    # name, min, max, value
    def __init__(self, startval=False):
        QObject.__init__(self)
        self.valueval = startval

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        self.valueval = val
        self.value_changed.emit()

    @Signal
    def value_changed(self):
        pass

    value = Property(str, readValue, setValue, notify=value_changed)

class PatchBayNotify(QObject):

    def __init__(self):
        QObject.__init__(self)

    add_module = Signal(str)
    remove_module = Signal(str)
    loading_preset = Signal(bool)


# class PolyEncoder(QObject):
#     # name, min, max, value
#     def __init__(self, starteffect="", startparameter=""):
#         QObject.__init__(self)
#         self.effectval = starteffect
#         self.parameterval = startparameter
#         self.speed = 1
#         self.value = 1

#     def readEffect(self):
#         return self.effectval

#     def setEffect(self,val):
#         self.effectval = val
#         self.effect_changed.emit()

#     @Signal
#     def effect_changed(self):
#         pass

#     effect = Property(str, readEffect, setEffect, notify=effect_changed)

#     def readParameter(self):
#         return self.parameterval

#     def setParameter(self,val):
#         self.parameterval = val
#         self.parameter_changed.emit()

#     @Signal
#     def parameter_changed(self):
#         pass

#     parameter = Property(str, readParameter, setParameter, notify=parameter_changed)

class PolyValue(QObject):
    # name, min, max, value
    def __init__(self, startname="", startval=0, startmin=0, startmax=1, v_type="float", curve_type="lin", startcc=-1):
        QObject.__init__(self)
        self.nameval = startname
        self.valueval = startval
        self.defaultval = startval
        self.rminval = startmin
        self.rmax = startmax
        self.ccval = startcc

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        # clamp values
        self.valueval = clamp(val, self.rmin, self.rmax)
        self.value_changed.emit()
        # debug_print("setting value", val)

    @Signal
    def value_changed(self):
        pass

    value = Property(float, readValue, setValue, notify=value_changed)

    def readDefaultValue(self):
        return self.defaultval

    def setDefaultValue(self,val):
        # clamp values
        self.defaultval = clamp(val, self.rmin, self.rmax)
        self.default_value_changed.emit()
        # debug_print("setting value", val)

    @Signal
    def default_value_changed(self):
        pass

    default_value = Property(float, readDefaultValue, setDefaultValue, notify=default_value_changed)

    def readCC(self):
        return self.ccval

    def setCC(self,val):
        self.ccval = val
        self.cc_changed.emit()
        # debug_print("setting value", val)

    @Signal
    def cc_changed(self):
        pass

    cc = Property(float, readCC, setCC, notify=cc_changed)

    def readName(self):
        return self.nameval

    def setName(self,val):
        self.nameval = val
        self.name_changed.emit()

    @Signal
    def name_changed(self):
        pass

    name = Property(str, readName, setName, notify=name_changed)

    def readRMin(self):
        return self.rminval

    def setRMin(self,val):
        self.rminval = val
        self.rmin_changed.emit()

    @Signal
    def rmin_changed(self):
        pass

    rmin = Property(float, readRMin, setRMin, notify=rmin_changed)

    def readRMax(self):
        return self.rmaxval

    def setRMax(self,val):
        self.rmaxval = val
        self.rmax_changed.emit()

    @Signal
    def rmax_changed(self):
        pass

    rmax = Property(float, readRMax, setRMax, notify=rmax_changed)

def jump_to_preset(is_inc, num):

    if is_loading.value == True:
        return
    # need to call frontend function to jump to home page
    p_list = preset_list_model.stringList()
    if is_inc:
        current_preset.value = (current_preset.value + num) % len(p_list)
    else:
        if num < len(p_list):
            current_preset.value = num
        else:
            return
    debug_print("jumping to preset ", p_list[current_preset.value], "num is", num)
    knobs.ui_load_preset_by_name(p_list[current_preset.value])

def write_pedal_state():
    if IS_REMOTE_TEST:
        return
    with open("/mnt/pedal_state/state.json", "w") as f:
        json.dump(pedal_state, f)
    os.sync()

def write_preset_meta_cache():
    with open("/mnt/pedal_state/preset_meta.json", "w") as f:
        json.dump(preset_meta_data, f)
    os.sync()

def load_preset_meta_cache():
    global preset_meta_data
    try:
        with open("/mnt/pedal_state/preset_meta.json") as f:
            preset_meta_data = json.load(f)
    except:
        try:
            get_meta_from_files(True)
        except:
            preset_meta_data = {}

def write_favourites_data():
    with open("/mnt/pedal_state/favourites.json", "w") as f:
        json.dump(favourites, f)
    os.sync()

def load_favourites_data():
    global favourites
    try:
        with open("/mnt/pedal_state/favourites.json") as f:
            favourites = json.load(f)
    except:
        favourites = {"modules":{}, "presets":{}}


def load_pedal_state():
    global pedal_state
    try:
        with open("/mnt/pedal_state/state.json") as f:
            pedal_state = json.load(f)
            if "input_level" not in pedal_state:
                pedal_state["input_level"] = 0
            if "midi_channel" not in pedal_state:
                pedal_state["midi_channel"] = 1
            if "author" not in pedal_state:
                pedal_state["author"] = "poly player"
            pedal_state["model"] = hardware_info["pedal"]
            if "thru" not in pedal_state:
                pedal_state["thru"] = True
            if "invert_enc" not in pedal_state:
                pedal_state["invert_enc"] = False
    except:
        pedal_state = {"input_level": 0, "midi_channel": 1, "author": "poly player", "model": "beebo", "thru": True, "invert_enc": False}


selected_source_effect_ports = QStringListModel()
selected_source_effect_ports.setStringList(["val1", "val2"])
selected_dest_effect_ports = QStringListModel()
selected_dest_effect_ports.setStringList(["val1", "val2"])
seq_num = 10

sub_graph_suffix = 0
def add_inc_sub_graph(actually_add=True):
    global sub_graph_suffix
    sub_graph_suffix = sub_graph_suffix + 1
    name = "/main/sub"+str(sub_graph_suffix)+"/"
    global current_sub_graph
    current_sub_graph = name
    sub_graphs.add(name.rstrip("/"))
    if actually_add:
        add_sub_graph(name)
    return name

def add_sub_graph(name):
    ingen_wrapper.add_sub_graph(name.rstrip("/"))
    global current_sub_graph
    current_sub_graph = name
    sub_graphs.add(name.rstrip("/"))

def delete_sub_graph(name):
    name = name.rstrip("/")
    if name in sub_graphs:
        ingen_wrapper.remove_plugin(name)
        sub_graphs.remove(name)

def loopler_in_use():
    # debug_print("checking if loopler is in use", current_effects.keys())
    num_modules = 0
    for effect in current_effects.values():
        if effect["effect_type"] in loopler_modules:
            num_modules = num_modules + 1
    return num_modules


def load_preset(name, initial=False, force=False):
    if is_loading.value == True and not force:
        return
    is_loading.value = True
    global preset_started_loading_time
    preset_started_loading_time = time.perf_counter()
    # is_loading.value = True
    # delete existing blocks
    port_connections.clear()
    reset_footswitch_assignments()
    preset_description.name = "Tap here to enter preset description"
    to_delete = list(current_effects.keys())
    for effect_id in to_delete:
        if effect_id in ["/main/out_1", "/main/out_2", "/main/out_3", "/main/out_4", "/main/in_1", "/main/in_2", "/main/in_3", "/main/in_4"]:
            pass
        else:
            patch_bay_notify.remove_module.emit(effect_id)
            try:
                current_effects.pop(effect_id)
            except:
                pass
    if not initial:
        # debug_print("deleting sub graph", current_sub_graph)
        delete_sub_graph(current_sub_graph)
        if loopler.is_running:
            loopler.stop_loopler()
    add_inc_sub_graph(False)
    # debug_print("adding inc sub graph", current_sub_graph)
    ingen_wrapper.load_pedalboard(name, current_sub_graph.rstrip("/"))
    context.setContextProperty("currentEffects", current_effects) # might be slow
    context.setContextProperty("portConnections", port_connections)
    # if this preset has a looper config, load it
    # check if preset file exists

    loopler_file = name[len("file://"):].rsplit("/", 1)[0] + "/loopler.slsess"
    # debug_print("checking if loopler_file exists", loopler_file)
    if os.path.exists(loopler_file):
        loopler.load_session(loopler_file)
        # debug_print("it does", loopler_file)
    time.sleep(0.1)
    ingen_wrapper.get_state("/engine")

def from_backend_new_effect(effect_name, effect_type, x=20, y=30, is_enabled=True):
    # called by engine code when new effect is created
    # debug_print("from backend new effect", effect_name, effect_type)
    if effect_type in effect_prototypes:
        broadcast_ports = {}
        if "broadcast_ports" in effect_prototypes[effect_type]:
            broadcast_ports = {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["broadcast_ports"].items()}
        current_effects[effect_name] = {"x": x, "y": y, "effect_type": effect_type,
                "controls": {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["controls"].items()},
                "assigned_footswitch": PolyStr(""),
                "broadcast_ports" : broadcast_ports,
                "highlight": PolyBool(False), "enabled": PolyBool(is_enabled)}
        # insert in context or model? 
        # emit add signal
        context.setContextProperty("currentEffects", current_effects) # might be slow
        patch_bay_notify.add_module.emit(effect_name)
        # if loopler isn't already running, start it
        if effect_type in loopler_modules:
            if not loopler.is_running:
                loopler.start_loopler()
        # if effect_type == "midi_clock_in":
        #     # set broadcast on port
        #     ingen_wrapper.set_broadcast(effect_name+"/bpm", True)
    else:
        debug_print("### backend tried to add an unknown effect!")

def from_backend_remove_effect(effect_name):
    # called by engine code when effect is removed
    if effect_name not in current_effects:
        return
    effect_type = current_effects[effect_name]["effect_type"]
    debug_print("### from backend removing effect")
    # emit remove signal
    for source_port, targets in list(port_connections.items()):
        s_effect, s_port = source_port.rsplit("/", 1)
        if s_effect == effect_name:
            del port_connections[source_port]
        else:
            port_connections[source_port] = [[e, p] for e, p in port_connections[source_port] if e != effect_name]

    # if this was a looper module, check if there are any left
    if effect_type in loopler_modules:
        if loopler_in_use() <= 1:
            if loopler.is_running:
                loopler.stop_loopler()
    patch_bay_notify.remove_module.emit(effect_name)
    for k in footswitch_assignments.keys(): # if this module has a foot switch assigned to it
        footswitch_assignments[k].discard(effect_name)
    debug_print("removing effects, current keys", current_effects.keys())

    # current_effects.pop(effect_name) # done after UI removes it
    context.setContextProperty("portConnections", port_connections)
    ingen_wrapper.get_state("/engine")
    # debug_print("### from backend removing effect setting portConnections")
    update_counter.value+=1

def from_backend_add_connection(head, tail):
    # debug_print("head ", head, "tail", tail)
    current_source_port = head
    if current_source_port.rsplit("/", 1)[0] in sub_graphs:
        s_effect = current_source_port
        # debug_print("## s_effect", s_effect)
        if s_effect not in current_effects:
            return
        s_effect_type = current_effects[s_effect]["effect_type"]
        if s_effect_type in bare_output_ports:
            s_port = "input"
        elif s_effect_type in bare_input_ports:
            s_port = "output"
        current_source_port = s_effect + "/" + s_port
        # debug_print("## current_source_port", current_source_port)
    else:
        if current_source_port.rsplit("/", 1)[0] == "/main":
            return
        # debug_print("## current_source_port not in sub graph", current_source_port, sub_graphs)


    effect_id_port_name = tail.rsplit("/", 1)
    if effect_id_port_name[0] in sub_graphs :
        t_effect = tail
        if t_effect not in current_effects:
            return
        t_effect_type = current_effects[t_effect]["effect_type"]
        t_port = None
        if t_effect_type in bare_output_ports:
            t_port = "input"
        elif t_effect_type in bare_input_ports:
            t_port = "output"
        # debug_print("## tail in sub_graph", tail, t_effect, t_port)
        if t_port is None:
            return
    else:
        if effect_id_port_name[0] == "/main":
            return
        # print("effect_id_port_name", effect_id_port_name)
        t_effect, t_port = effect_id_port_name
        # debug_print("## tail not in sub_graph", tail, t_effect, t_port, sub_graphs)
        if t_effect not in current_effects:
            return

    if current_source_port not in port_connections:
        port_connections[current_source_port] = []
    if [t_effect, t_port] not in port_connections[current_source_port]:
        port_connections[current_source_port].append([t_effect, t_port])

    # debug_print("port_connections is", port_connections)
    # global context
    context.setContextProperty("portConnections", port_connections)
    update_counter.value+=1


def from_backend_disconnect(head, tail):
    # debug_print("head ", head, "tail", tail)
    current_source_port = head
    try:
        if current_source_port.rsplit("/", 1)[0] in sub_graphs:
            s_effect = current_source_port
            s_effect_type = current_effects[s_effect]["effect_type"]
            if s_effect_type in bare_output_ports:
                s_port = "input"
            elif s_effect_type in bare_input_ports:
                s_port = "output"
            current_source_port = s_effect + "/" + s_port

        effect_id_port_name = tail.rsplit("/", 1)
        if effect_id_port_name[0] in sub_graphs:
            t_effect = tail
            t_effect_type = current_effects[t_effect]["effect_type"]
            if t_effect_type in bare_output_ports:
                t_port = "input"
            elif t_effect_type in bare_input_ports:
                t_port = "output"
        else:
            t_effect, t_port = effect_id_port_name
    except KeyError:
        return

    # debug_print("before port_connections is", port_connections)
    if current_source_port in port_connections and [t_effect, t_port] in port_connections[current_source_port]:
        port_connections[current_source_port].pop(port_connections[current_source_port].index([t_effect, t_port]))
    # debug_print("after port_connections is", port_connections)
    # global context
    context.setContextProperty("portConnections", port_connections)
    update_counter.value+=1

def get_meta_from_files(initial=False):
    r_dict = {}
    def get_rdf_element_from_files(rdf_name="rdfs:comment", element_name="description"):
        command =  'grep -ir "'+ rdf_name +'" /mnt/presets'
        # command =  ['grep' , '-ir',  '"'+ element_name +'"',  '/mnt/presets']
        ret_obj = subprocess.run(command, capture_output=True, shell=True)
        for a in ret_obj.stdout.splitlines():
            b = a.decode().split(":", 1)
            v = b[1].split('"')[1]
            preset_name = b[0].rsplit("/", 1)[0]
            if preset_name not in r_dict:
                r_dict[preset_name] = {}
            r_dict[preset_name][element_name] = v
    get_rdf_element_from_files("rdfs:comment", "description")
    get_rdf_element_from_files("doap:maintainer", "author")
    get_rdf_element_from_files("doap:category", "tags")
    global preset_meta_data
    preset_meta_data = r_dict
    if not initial:
        context.setContextProperty("presetMeta", preset_meta_data)
    # flush to file
    write_preset_meta_cache()

class Knobs(QObject):
    @Slot(bool, str, str)
    def set_current_port(self, is_source, effect_id, port_name):
        # debug_print("port name is", port_name, "effect id", effect_id)
        # if source highlight targets
        if is_source:
            # set current source port
            # effect_id, port_name
            # highlight effects given source port
            global current_source_port
            current_source_port = "/".join((effect_id, port_name))
            connect_source_port.name = current_source_port
            try:
                out_port_type = effect_prototypes[current_effects[effect_id]["effect_type"]]["outputs"][port_name][1]
            except KeyError:
                return
            for id, effect in current_effects.items():
                effect["highlight"].value = False
                if id != effect_id:
                    # if out_port_type in ["CVPort", "ControlPort"]: # looking for controls
                    #     if len(current_effects[id]["controls"]) > 0:
                    #         effect["highlight"] = True
                    # else:
                    for input_port, style in effect_prototypes[effect["effect_type"]]["inputs"].items():
                        if style[1] == out_port_type:
                            # highlight and break
                            # qWarning("port highlighted")
                            effect["highlight"].value = True
                            break
        else:
            # if target disable highlight
            for id, effect in current_effects.items():
                effect["highlight"].value = False
            # add connection between source and target
            # or just wait until it's automatically created from engine? 
            # if current_source_port not in port_connections:
            #     port_connections[current_source_port] = []
            # if [effect_id, port_name] not in port_connections[current_source_port]:
            #     port_connections[current_source_port].append([effect_id, port_name])


            s_effect, s_port = current_source_port.rsplit("/", 1)
            s_effect_type = current_effects[s_effect]["effect_type"]
            t_effect_type = current_effects[effect_id]["effect_type"]
            if t_effect_type in bare_ports:
                if s_effect_type in bare_ports:
                    ingen_wrapper.connect_port(s_effect, effect_id)
                else:
                    ingen_wrapper.connect_port(current_source_port, effect_id)
            else:
                if s_effect_type in bare_ports:
                    ingen_wrapper.connect_port(s_effect, effect_id+"/"+port_name)
                else:
                    ingen_wrapper.connect_port(current_source_port, effect_id+"/"+port_name)


            # if [effect_id, port_name] not in inv_port_connections:
            #     inv_port_connections[[effect_id, port_name]] = []
            # if current_source_port not in inv_port_connections[[effect_id, port_name]]:
            #     inv_port_connections[[effect_id, port_name]].append(current_source_port)

            # debug_print("port_connections is", port_connections)
            # global context
            # context.setContextProperty("portConnections", port_connections)


    @Slot(bool, str, bool)
    def select_effect(self, is_source, effect_id, restrict_port_types=True):
        effect_type = current_effects[effect_id]["effect_type"]
        # debug_print("selecting effect type", effect_type)
        if is_source:
            ports = [k+'|'+v[0] for k,v in effect_prototypes[effect_type]["outputs"].items()]
            selected_source_effect_ports.setStringList(ports)
        else:
            s_effect_id, s_port = connect_source_port.name.rsplit("/", 1)
            source_port_type = effect_prototypes[current_effects[s_effect_id]["effect_type"]]["outputs"][s_port][1]
            if restrict_port_types or source_port_type == "AtomPort":
                ports = [k+'|'+v[0] for k,v in effect_prototypes[effect_type]["inputs"].items() if v[1] == source_port_type]
            else:
                ports = [k+'|'+v[0] for k,v in effect_prototypes[effect_type]["inputs"].items() if v[1] != "AtomPort"]
            selected_dest_effect_ports.setStringList(ports)

    @Slot(str)
    def list_connected(self, effect_id):
        ports = []
        for source_port, connected in port_connections.items():
            s_effect, s_port = source_port.rsplit("/", 1)
            display_s_port = effect_prototypes[current_effects[s_effect]["effect_type"]]["inputs"][s_port][0]
            # connections where we are target
            for c_effect, c_port in connected:
                display_c_port = effect_prototypes[current_effects[c_effect]["effect_type"]]["outputs"][c_port][0]
                if c_effect == effect_id:
                    ports.append("output==="+display_c_port+" connect to "+s_effect.rsplit("/", 1)[1]+" "+ display_s_port +"==="+s_effect+"/"+s_port+"---"+c_effect+"/"+c_port)
                elif s_effect == effect_id:
                    ports.append("input==="+c_effect.rsplit("/", 1)[1]+ " "+display_c_port+" connected to "+display_s_port+"==="+s_effect+"/"+s_port+"---"+c_effect+"/"+c_port)
        # debug_print("connected ports:", ports, effect_id)
        # qWarning("connected Ports "+ str(ports) + " " + effect_id)
        ports.sort()
        selected_source_effect_ports.setStringList(ports)

    @Slot(str)
    def disconnect_port(self, port_pair):
        target_pair, source_pair = port_pair.split("---")
        t_effect, t_port = target_pair.rsplit("/", 1)
        # debug_print("### disconnect, port pair", port_pair)

        s_effect, s_port = source_pair.rsplit("/", 1)
        s_effect_type = current_effects[s_effect]["effect_type"]
        t_effect_type = current_effects[t_effect]["effect_type"]
        if t_effect_type in bare_ports:
            if s_effect_type in bare_ports:
                ingen_wrapper.disconnect_port(s_effect, t_effect)
            else:
                ingen_wrapper.disconnect_port(source_pair, t_effect)
        else:
            if s_effect_type in bare_ports:
                ingen_wrapper.disconnect_port(s_effect, target_pair)
            else:
                ingen_wrapper.disconnect_port(source_pair, target_pair)

    @Slot(str)
    def add_new_effect(self, effect_type):
        # calls backend to add effect
        global seq_num
        seq_num = seq_num + 1
        # debug_print("add new effect", effect_type)
        # if there's existing effects of this type, increment the ID
        is_bare_port = effect_type in bare_ports
        num_sep = ""
        if is_bare_port:
            num_sep = "_"

        effect_name = current_sub_graph+effect_type+num_sep+str(1)
        for i in range(1, 1000):
            if current_sub_graph+effect_type+num_sep+str(i) not in current_effects:
                effect_name = current_sub_graph+effect_type+num_sep+str(i)
                break

        if is_bare_port:
            bare_ports_map = {"input" : "in", "output" : "out", "midi_input" : "midi_in", "midi_output" : "midi_out", "loop_common_in" : "out", "loop_common_out" : "in"}
            if bare_ports_map[effect_type] == "in":
                ingen_wrapper.add_input(effect_name, 900, 150)
            if bare_ports_map[effect_type] == "out":
                ingen_wrapper.add_output(effect_name, 900, 150)
            # ingen_wrapper.add_input("/main/in_"+str(i), x=1192, y=(80*i))
        else:
            ingen_wrapper.add_plugin(effect_name, effect_type_map[effect_type])
        # from_backend_new_effect(effect_name, effect_type)


    @Slot(str, bool)
    def set_bypass(self, effect_name, is_active):
        # check if were kill dry, if so, set enabled value, else just call default ingen:enabled
        effect_type = current_effects[effect_name]["effect_type"]
        if "kill_dry" in effect_prototypes[effect_type]:
            v = 1.0 - (current_effects[effect_name]["controls"]["enabled"].value)
            knobs.ui_knob_change(effect_name, "enabled", v)
            current_effects[effect_name]["enabled"].value = bool(v)
        else:
            ingen_wrapper.set_bypass(effect_name, is_active)

    @Slot(str)
    def set_description(self, description):
        ingen_wrapper.set_description(current_sub_graph.rstrip("/"), description)
        preset_description.name = description

    @Slot(str, int, int)
    def move_effect(self, effect_name, x, y):
        try:
            current_effects[effect_name]["x"] = x
            current_effects[effect_name]["y"] = y
        except KeyError:
            pass
        ingen_wrapper.set_plugin_position(effect_name, x, y)

    @Slot(str)
    def remove_effect(self, effect_id):
        # calls backend to remove effect
        # debug_print("remove effect", effect_id)
        # if effect is loopler we need to just hide it instead, because otherwise Ingen crashes
        if effect_id in current_effects and current_effects[effect_id]["effect_type"] in loopler_modules:
            # find all connections and remove them, disconnect plugin doesn't work
            for source_port, targets in list(port_connections.items()):
                # target_pair, source_pair = port_pair.split("---")
                s_effect, s_port = source_port.rsplit("/", 1)
                if s_effect == effect_id:
                    for e, p in port_connections[source_port]:
                        knobs.disconnect_port(source_port + "---" + "/".join([e, p]) )
                else:
                    for e, p in port_connections[source_port]:
                        if e == effect_id:
                            knobs.disconnect_port("/".join([e, p]) + "---" + source_port )
            from_backend_remove_effect(effect_id)
        else:
            ingen_wrapper.remove_plugin(effect_id)

    @Slot(str, str, 'double')
    def ui_knob_change(self, effect_name, parameter, value):
        # debug_print(x, y, z)
        if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
            current_effects[effect_name]["controls"][parameter].value = value
            # clamping here to make it a bit more obvious
            value = clamp(value, current_effects[effect_name]["controls"][parameter].rmin, current_effects[effect_name]["controls"][parameter].rmax)
            # bit sketch but check if BPM here? XXX
            if parameter == "bpm":
                set_bpm(value)

            ingen_wrapper.set_parameter_value(effect_name+"/"+parameter, value)
        else:
            debug_print("effect not found", effect_name, parameter, value, effect_name in current_effects)

    @Slot(str, str)
    def update_ir(self, effect_id, ir_file):
        is_cab = True
        effect_type = current_effects[effect_id]["effect_type"]
        if effect_type in ["mono_reverb", "stereo_reverb", "quad_ir_reverb"]:
            is_cab = False
        current_effects[effect_id]["controls"]["ir"].name = ir_file
        ingen_wrapper.set_file(effect_id, ir_file, is_cab)

    @Slot()
    def ui_load_empty_preset(self):
        knobs.ui_load_preset_by_name("file:///mnt/presets/beebo/Empty.ingen")

    @Slot(str)
    def ui_load_preset_by_name(self, preset_file):
        if is_loading.value == True:
            return

        patch_bay_notify.loading_preset.emit(True)
        # debug_print("loading", preset_file)
        # outfile = preset_file[7:] # strip file:// prefix
        load_preset(preset_file+"/main.ttl")
        current_preset.name = preset_file.strip("/").split("/")[-1][:-6]
        global current_preset_filename
        current_preset_filename = preset_file[7:]
        update_counter.value+=1

    @Slot(str)
    def ui_load_qa_preset_by_name(self, preset_file):
        if is_loading.value == True:
            return

        # debug_print("loading", preset_file)
        # outfile = preset_file[7:] # strip file:// prefix
        load_preset(preset_file+"/main.ttl")
        current_preset.name = preset_file.strip("/").split("/")[-1][:-6]
        global current_preset_filename
        current_preset_filename = preset_file[7:]
        update_counter.value+=1

    @Slot(str)
    def ui_save_pedalboard(self, pedalboard_name):
        # debug_print("saving", preset_name)
        # TODO add folders
        current_preset.name = pedalboard_name
        ingen_wrapper.set_author(current_sub_graph.rstrip("/"), pedal_state["author"])
        ingen_wrapper.save_pedalboard("beebo", pedalboard_name, current_sub_graph.rstrip("/"))
        self.launch_task(2, os.sync) # wait 2 seconds then sync to drive
        # update preset meta
        clean_filename = ingen_wrapper.get_valid_filename(pedalboard_name)
        if len(clean_filename) > 0:
            filename = "/mnt/presets/beebo/"+clean_filename+".ingen"
            global current_preset_filename
            current_preset_filename = filename
            if filename in preset_meta_data:
                preset_meta_data[filename]["author"] = pedal_state["author"]
                preset_meta_data[filename]["description"] = preset_description.name
            else:
                preset_meta_data[filename] = {"author": pedal_state["author"], "description": preset_description.name}

            context.setContextProperty("presetMeta", preset_meta_data)
            # check if loopler in use
            if loopler_in_use():
                loopler_file = filename + "/loopler.slsess"
                loopler.save_session(loopler_file)

            # flush to file
            write_preset_meta_cache()

    @Slot(str)
    def toggle_favourite(self, preset_file):
        p_f = preset_file[7:]
        if p_f in favourites["presets"]:
            favourites["presets"][p_f] = not favourites["presets"][p_f]
        elif p_f in preset_meta_data:
            favourites["presets"][p_f] = True
        else:
            return
        context.setContextProperty("favourites", favourites)
        # flush to file
        write_favourites_data()

    @Slot()
    def ui_copy_irs(self):
        # debug_print("copy irs from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        # remount RW 
        command = """ sudo mount -o remount,rw /dev/mmcblk0p2 /mnt; if [ -d /usb_flash/reverbs ]; then cd /usb_flash/reverbs; rename 's/[^a-zA-Z0-9. _-]/_/g' **; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/mnt/audio/reverbs --parents; fi;
        if [ -d /usb_flash/cabs ]; then cd /usb_flash/cabs; rename 's/[^a-zA-Z0-9. _-]/_/g' **; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/mnt/audio/cabs --parents; fi; sudo mount -o remount,ro /dev/mmcblk0p2 /mnt;"""
        # copy all wavs in /usb/reverbs and /usr/cabs to /audio/reverbs and /audio/cabs
        command_status[0].value = -1
        self.launch_subprocess(command)
        # remount RO 

    @Slot()
    def import_presets(self):
        # debug_print("copy presets from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """cd /usb_flash/presets;
        if test -n "$(find /usb_flash/presets/ -maxdepth 1 -name '*.ingen' -print -quit)";
        then find . -iname "*.ingen" -type d -print0 | xargs -0 cp -r --target-directory=/mnt/presets --parents;
        fi
        if test -n "$(find /usb_flash/presets/ -maxdepth 1 -name '*.instr' -print -quit)";
        then cd /mnt/presets;
        find /usb_flash/presets/ -iname "*.instr" -type f -exec tar -xjf {} \; ;
        fi
        find /mnt/presets/digit/ -iname '*.ingen' -type d -exec mv -t /mnt/presets/beebo/ {} + ;
        rm -rf /mnt/presets/digit/*"""
        command_status[0].value = -1
        self.launch_subprocess(command, after=get_meta_from_files)
        # after presets have copied we need to parse all the tags / author and update cache

    @Slot()
    def export_presets(self):
        # debug_print("copy presets to USB")
        # export as tar.bz2
        # 
        command = """cd /mnt/presets; mkdir -p /usb_flash/presets; find . -iname "*.ingen" -type d -exec bash -c 'tar -cjf /usb_flash/presets/$(basename "$@" .ingen).instr $@' _ {} \; ;sudo umount /usb_flash"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def export_current_preset(self):
        # debug_print("copy current preset to USB")
        i = current_preset_filename.find("presets")+len("presets")+1
        out_file = current_preset_filename[i:] # strip starting folders
        command = """cd /mnt/presets; mkdir -p /usb_flash/presets; tar -cjf /usb_flash/presets/"""+out_file.split("/")[1][:-len(".ingen")]+".instr " + out_file +""" ;sudo umount /usb_flash"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def copy_logs(self):
        # debug_print("copy presets to USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """mkdir -p /usb_flash/logs; sudo cp /var/log/syslog /usb_flash/logs/;sudo umount /usb_flash"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def ui_update_firmware(self):
        # debug_print("Updating firmware")
        # dpkg the debs in the folder
        if len(glob.glob("/usb_flash/*.deb")) > 0:
            command = """sudo /usr/bin/polyoverlayroot-chroot dpkg -i /usb_flash/*.deb && sudo shutdown -h 'now'"""
            command_status[0].value = -1
            self.launch_subprocess(command)
        else:
            command_status[0].value = 1


    @Slot(int)
    def set_input_level(self, level, write=True):
        if IS_REMOTE_TEST:
            return
        command = "amixer -- sset ADC1 "+str(level)+"db; amixer -- sset ADC2 "+str(level)+"db"
        command_status[0].value = subprocess.call(command, shell=True)
        if hardware_info["revision"] <= 10:
            command = "amixer -- sset 'ADC1 Invert' off,on; amixer -- sset 'ADC2 Invert' on,on"
        else:
            command = "amixer -- sset 'ADC1 Invert' off,off; amixer -- sset 'ADC2 Invert' off,off"
        command_status[0].value = subprocess.call(command, shell=True)
        input_level.value = level
        if write:
            pedal_state["input_level"] = level
            write_pedal_state()

    @Slot(int)
    def set_channel(self, channel):
        midi_channel.value = channel
        pedal_state["midi_channel"] = channel
        write_pedal_state()

    @Slot(bool)
    def set_enc_invert(self, invert):
        pedal_state["invert_enc"] = invert
        context.setContextProperty("pedalState", pedal_state)
        write_pedal_state()

    @Slot(bool)
    def set_thru_enabled(self, thru_on):
        pedal_state["thru"] = thru_on
        context.setContextProperty("pedalState", pedal_state)
        write_pedal_state()
        try:
            if thru_on:
                command = ["/usr/bin/jack_connect",  "ttymidi:MIDI_in", "ttymidi:MIDI_out"]
                ret_var = subprocess.run(command)
            else:
                command = ["/usr/bin/jack_disconnect",  "ttymidi:MIDI_in", "ttymidi:MIDI_out"]
                ret_var = subprocess.run(command)
        except:
            pass

    @Slot(int)
    def set_preset_list_length(self, v):
        if v > len(preset_list_model.stringList()):
            # debug_print("inserting new row in preset list", v)
            insert_row(preset_list_model, "file:///mnt/presets/digit/Default_Preset.ingen")
        else:
            # debug_print("removing row in preset list", v)
            preset_list_model.removeRows(v, 1)

    @Slot(int, str)
    def map_preset(self, v, name):
        preset_list_model.setData(preset_list_model.index(v), name)

    @Slot()
    def save_preset_list(self):
        # debug_print("saving preset list")
        with open("/mnt/pedal_state/beebo_preset_list.json", "w") as f:
            json.dump(preset_list_model.stringList(), f)
        os.sync()

    @Slot(int)
    def on_worker_done(self, ret_var):
        # debug_print("updating UI")
        command_status[0].value = ret_var

    @Slot(int)
    def on_task_done(self, ret_var):
        # debug_print("updating UI")
        command_status[0].value = ret_var

    def launch_subprocess(self, command, after=None):
        # debug_print("launch_threadpool")
        worker = MyWorker(command, after)
        worker.emitter.done.connect(self.on_worker_done)
        worker_pool.start(worker)

    def launch_task(self, delay, command):
        # debug_print("launch_threadpool")
        worker = MyTask(delay, command)
        # worker.emitter.done.connect(self.on_worker_done)
        worker_pool.start(worker)

    @Slot(str, str)
    def set_knob_current_effect(self, effect_id, parameter):
        # get current value and update encoder / cache.
        # qDebug("setting knob current effect" + parameter)
        knob = "left"
        if not (knob_map[knob].effect == effect_id and knob_map[knob].parameter == parameter):
            knob_map[knob].effect = effect_id
            knob_map[knob].parameter = parameter
            knob_map[knob].rmin = current_effects[effect_id]["controls"][parameter].rmin
            knob_map[knob].rmax = current_effects[effect_id]["controls"][parameter].rmax
            knob_map[knob].is_loopler = False

    @Slot(str, int, str, float, float)
    def set_loopler_knob(self, effect_id, loop_index, parameter, rmin, rmax):
        # get current value and update encoder / cache.
        # qDebug("setting knob current effect" + parameter)
        knob = "left"
        if not (knob_map[knob].effect == effect_id and knob_map[knob].parameter == parameter and
                knob_map[knob].loop_index == loop_index):
            knob_map[knob].effect = effect_id
            knob_map[knob].parameter = parameter
            knob_map[knob].rmin = rmin
            knob_map[knob].rmax = rmax
            knob_map[knob].is_loopler = True
            knob_map[knob].loop_index = loop_index

    @Slot(str)
    def set_pedal_model(self, pedal_model):
        if is_loading.value == True:
            return
        pedal_state["model"] = pedal_model
        write_pedal_state()
        change_pedal_model(pedal_model)

    @Slot(str)
    def delete_ir(self, ir):
        # debug_print("delete: ir files is ", ir)
        ir = ir[len("file://"):]
        # can be a directory or file
        # check if it isn't a base dir. 
        if "imported" not in ir or ir in ["/audio/cabs/imported", "/audio/reverbs/imported"]:
            return
        # delete
        # remount as RW
        command = "sudo mount -o remount,rw /dev/mmcblk0p2 /mnt"
        ret_var = subprocess.call(command, shell=True)
        try:
            os.remove(ir)
        except IsADirectoryError:
            shutil.rmtree(ir)
        os.sync()
        # remount as RO
        command = "sudo mount -o remount,ro /dev/mmcblk0p2 /mnt"
        ret_var = subprocess.call(command, shell=True)

    @Slot()
    def delete_all_irs(self):
        # debug_print("delete: ir files is ", ir)
        # can be a directory or file
        # check if it isn't a base dir. 
        # delete
        # remount as RW
        command = "sudo mount -o remount,rw /dev/mmcblk0p2 /mnt"
        ret_var = subprocess.call(command, shell=True)
        shutil.rmtree("/mnt/audio/cabs")
        shutil.rmtree("/mnt/audio/reverbs")
        os.mkdir("/mnt/audio/cabs")
        os.mkdir("/mnt/audio/reverbs")
        os.sync()
        # remount as RO
        command = "sudo mount -o remount,ro /dev/mmcblk0p2 /mnt"
        ret_var = subprocess.call(command, shell=True)

    @Slot(str)
    def delete_preset(self, in_preset_file):
        preset_file = in_preset_file[len("file://"):]
        debug_print("delete: preset_file files is ", preset_file)
        # is always a directory
        # empty / default
        if ".ingen" not in preset_file or preset_file in ["/mnt/presets/digit/Default_Preset.ingen", "/mnt/presets/beebo/Empty.ingen", "/mnt/presets/digit/Empty.ingen"]:
            return
        # delete
        shutil.rmtree(preset_file)
        # remove from set list.
        preset_list = preset_list_model.stringList()
        debug_print("preset list is", preset_list)
        if in_preset_file in preset_list:
            preset_list = [v for v in preset_list if v != in_preset_file]
            preset_list_model.setStringList(preset_list)
            self.save_preset_list()
        os.sync()

    @Slot()
    def save_preset_list(self):
        debug_print("saving preset list")
        with open("/mnt/pedal_state/beebo_preset_list.json", "w") as f:
            json.dump(preset_list_model.stringList(), f)
        os.sync()
    preset_list_model.setStringList(preset_list)


    @Slot(str)
    def set_pedal_author(self, author):
        pedal_state["author"] = author
        write_pedal_state()
        context.setContextProperty("pedalState", pedal_state)

    @Slot(int, str)
    def set_current_mode(self, mode, effect_name):
        # debug_print("updating UI")
        global current_patchbay_mode
        global current_selected_effect
        current_patchbay_mode = mode
        current_selected_effect = effect_name

    @Slot()
    def get_ip(self):
        ret_obj = subprocess.run("hostname -I", capture_output=True, shell=True)
        current_ip.name = ret_obj.stdout.decode()

    @Slot(str, bool)
    def set_broadcast(self, effect_name, is_broadcast):
        # debug_print(x, y, z)
        if (effect_name in current_effects) and ("broadcast_ports" in current_effects[effect_name]):
            for parameter in current_effects[effect_name]["broadcast_ports"].keys():
                ingen_wrapper.set_broadcast(effect_name+"/"+parameter, is_broadcast)
        else:
            debug_print("effect not found", effect_name, effect_name in current_effects)

    @Slot(str, str)
    def midi_learn(self, effect_name, parameter):
        # this toggles, if we're already learned, forget. No way to currently cancel waiting for midi
        if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
            if current_effects[effect_name]["controls"][parameter].cc > -1:
                # have current, forget
                ingen_wrapper.midi_forget(effect_name+"/"+parameter)
            else:
                ingen_wrapper.midi_learn(effect_name+"/"+parameter)
        else:
            debug_print("effect not found", effect_name, parameter, value, effect_name in current_effects)

    @Slot(str)
    def finish_remove_effect(self, effect_name):
        try:
            current_effects.pop(effect_name) # done after UI removes it
        except:
            pass
        context.setContextProperty("currentEffects", current_effects) # might be slow

def io_new_effect(effect_name, effect_type, x=20, y=30):
    # called by engine code when new effect is created
    # debug_print("from backend new effect", effect_name, effect_type)
    if effect_type in effect_prototypes:
        current_effects[effect_name] = {"x": x, "y": y, "effect_type": effect_type,
                "controls": {},
                "highlight": PolyBool(False)}

def add_io():
    for i in range(1,5):
        ingen_wrapper.add_input("/main/in_"+str(i), x=1192, y=(80*i))
    for i in range(1,5):
        ingen_wrapper.add_output("/main/out_"+str(i), x=-20, y=(80 * i))
    ingen_wrapper.add_midi_input("/main/midi_in", x=1192, y=(80 * 5))
    ingen_wrapper.add_midi_output("/main/midi_out", x=-20, y=(80 * 5))
    ingen_wrapper.add_output("/main/loop_common_in_1", x=1092, y=(80*1))
    ingen_wrapper.add_output("/main/loop_common_in_2", x=1092, y=(80*2))
    ingen_wrapper.add_input("/main/loop_common_out_1", x=20, y=(80*1))
    ingen_wrapper.add_input("/main/loop_common_out_2", x=20, y=(80*2))

class Encoder():
    # name, min, max, value
    def __init__(self, starteffect="", startparameter="", s_speed=1):
        self.effect = starteffect
        self.parameter = startparameter
        self.speed = s_speed
        self.rmin = 0
        self.rmax = 1
        self.is_loopler = False
        self.loop_index = -1

knob_map = {"left": Encoder(s_speed=0.04), "right": Encoder(s_speed=0.8)}

def handle_encoder_change(is_left, change):
    # debug_print(is_left, change)
    # qDebug("encoder change "+ str(is_left) + str(change))
    # increase or decrease the current knob value depending on knob speed
    # knob_value = knob_value + (change * knob_speed)
    normal_speed = 24.0
    knob = "left"
    knob_effect = knob_map[knob].effect
    knob_parameter = knob_map[knob].parameter

    # invert if we're running new style encoders

    if "invert_enc" in pedal_state and pedal_state["invert_enc"]:
        is_left = not is_left
        change = change * -1
    if True: # qa_view:
        if is_left:
            qa_k = "left"
        else:
            qa_k = "right"
        value = encoder_qa[qa_k].value
        base_speed = 1 / normal_speed
        knob_speed = 5
        value = value + (change * knob_speed * base_speed)
        encoder_qa[qa_k].value = value

    if not knob_effect or knob_effect not in current_effects and not knob_map[knob].is_loopler:
        return
    if is_left:
        knob_speed = knob_map["left"].speed
    else:
        knob_speed = knob_map["right"].speed
    # base speed * speed multiplier
    base_speed = (abs(knob_map[knob].rmin) + abs(knob_map[knob].rmax)) / normal_speed

    if knob_map[knob].is_loopler:
        loopler.change_from_knob(knob_effect, knob_parameter, knob_map[knob].loop_index, change, knob_speed * base_speed, knob_map[knob].rmin, knob_map[knob].rmax)
    else:
        value = current_effects[knob_effect]["controls"][knob_parameter].value
        value = value + (change * knob_speed * base_speed)

        # debug_print("knob value is", value)
        # knob change handles clamping
        knobs.ui_knob_change(knob_effect, knob_parameter, value)

def set_bpm(bpm):
    current_bpm.value = bpm
    # host.transport_bpm(bpm)
    # send_ui_message("bpm_change", (bpm, ))
    # debug_print("setting tempo", bpm)

### Assignable actions
# 

Actions = Enum("Actions", """set_value
set_value_down
tap
set_tempo
toggle_pedal
select_preset
next_preset
previous_preset
next_action_group previous_action_group
toggle_effect
""")
foot_action_groups = [{"tap_up":[Actions.set_value] , "step_up": [Actions.set_value], "bypass_up":[Actions.set_value],
    "tap_down":[Actions.set_value_down] , "step_down": [Actions.set_value_down], "bypass_down":[Actions.set_value_down],
    "tap_step_up": [Actions.set_value], "step_bypass_up": [Actions.set_value],
    "tap_step_down": [Actions.set_value_down], "step_bypass_down": [Actions.set_value_down]}]
    # "tap_step_up": [Actions.previous_preset], "step_bypass_up": [Actions.next_preset]}]
current_action_group = 0

def handle_bypass():
    # global bypass
    pedal_bypassed.value = not pedal_bypassed.value
    if pedal_bypassed.value:
        pedal_hardware.effect_off()
    else:
        pedal_hardware.effect_on()

def hide_foot_switch_warning():
    foot_switch_warning.value = False

def looper_footswitch_action(foot_switch_name):
    # command, value, set_all, global value, add loop, remove loop, 
    # foot switches store command and arguments
    for action_params in looper_footswitch_assignments[foot_switch_name]:
        # getattr(loopler, "cancel_midi_learn")() 
        print("command is ", action_params[0], "params", repr(action_params[1]))
        func = getattr(loopler, action_params[0])
        func(*action_params[1])
        return True
    return False

def send_to_footswitch_blocks(timestamp, switch_name, value=0):
    # send to all foot switch blocks
    # qDebug("sending to switch_name "+str(switch_name) + "value" + str(value))
    if "tap_step" in switch_name:
        foot_switch_name = "foot_switch_d"
    elif "step_bypass" in switch_name:
        foot_switch_name = "foot_switch_e"
    elif "tap" in switch_name:
        foot_switch_name = "foot_switch_a"
    elif "step" in switch_name:
        foot_switch_name = "foot_switch_b"
    elif "bypass" in switch_name:
        foot_switch_name = "foot_switch_c"

    trimmed_name = foot_switch_name[-1]
    # if we're in hold mode then we're assigning something to a foot switch
    if value == 0 and current_patchbay_mode == PatchMode.HOLD:
        # set this foot swtich to the currently held effect
        if current_selected_effect != "":
            if current_effects[current_selected_effect]["assigned_footswitch"].value == trimmed_name:
                ingen_wrapper.set_footswitch_control(current_selected_effect, "")
            else:
                ingen_wrapper.set_footswitch_control(current_selected_effect, foot_switch_name[-1])
            return

    #  
    if value == 0 and loopler.current_command_params:
        looper_footswitch_assignments[foot_switch_name[-1]] = [loopler.current_command_params]
        # show foot switch selection screen, choose if for current loop, all loops, momentary, latching, toggle?
        # exclusive or adds on
        loopler.current_command_params = None
        return

    if True: # qa_view
        foot_switch_qa[foot_switch_name[-1]].value = value

    found_effect = False
    bpm = None
    if value == 1:
        bpm = handle_tap(foot_switch_name, timestamp)

    # toggle all assigned effects
    if value == 0:
        for effect_id in footswitch_assignments[trimmed_name]:
            enabled = current_effects[effect_id]["enabled"].value
            knobs.set_bypass(effect_id, not enabled) # toggle
            found_effect = True
        if looper_footswitch_action(trimmed_name):
            found_effect = True

    for effect_id, effect in current_effects.items():
        if "foot_switch" in effect["effect_type"]:
            if foot_switch_name in effect_id:
                if bpm is not None:
                    # qDebug("sending knob change from foot switch "+effect_id + "bpm" + str(float(bpm)))
                    knobs.ui_knob_change(effect_id, "bpm", float(bpm))
                # qDebug("sending knob change from foot switch "+effect_id + "value" + str(float(value)))
                if effect["controls"]["latching"].value < 0.9:
                    effect["controls"]["cur_out"].value = float(value)
                else:
                    if value > 0:
                        effect["controls"]["cur_out"].value = 1.0 - effect["controls"]["cur_out"].value
                knobs.ui_knob_change(effect_id, "value", float(value))
                found_effect = True

    if not found_effect and value == 0:
        if foot_switch_name == "foot_switch_c":
            handle_bypass()
            # TODO add next / previous here
        else:
            # show you're pressing a footswitch that isn't connected to anything
            foot_switch_warning.value = True
            QTimer.singleShot(2500, hide_foot_switch_warning)


def next_preset():
    jump_to_preset(True, 1)

def previous_preset():
    jump_to_preset(True, -1)

def handle_foot_change(switch_name, timestamp):
    # debug_print(switch_name, timestamp)
    # qDebug("foot change "+ str(switch_name) + str(timestamp))
    action = foot_action_groups[current_action_group][switch_name][0]
    params = None
    if len(foot_action_groups[current_action_group][switch_name]) > 1:
        params = foot_action_groups[current_action_group][switch_name][1:]

    if action is Actions.tap:
        pass
    elif action is Actions.toggle_pedal:
        handle_bypass()

    elif action is Actions.set_value:
        send_to_footswitch_blocks(timestamp, switch_name, 0)
    elif action is Actions.set_value_down:
        send_to_footswitch_blocks(timestamp, switch_name, 1)
    elif action is Actions.select_preset:
        pass

    elif action is Actions.next_preset:
        next_preset()

    elif action is Actions.previous_preset:
        previous_preset()

    elif action is Actions.toggle_effect:
        pass

start_tap_time = {"foot_switch_a":None, "foot_switch_b":None, "foot_switch_c":None, "foot_switch_d":None, "foot_switch_e":None}
## tap callback is called by hardware button from the GPIO checking thread
def handle_tap(footswitch, timestamp):
    current_tap = timestamp
    bpm = None
    if start_tap_time[footswitch] is not None:
        # just use this and previous to calculate BPM
        # BPM must be in range 30-250
        d = current_tap - start_tap_time[footswitch]
        # 120 bpm, 0.5 seconds per tap
        bpm = 60 / d
        if bpm > 30 and bpm < 350:
            # set host BPM
            pass
        else:
            bpm = None

    # record start time
    start_tap_time[footswitch] = current_tap
    return bpm

def process_ui_messages():
    # pop from queue
    try:
        while not EXIT_PROCESS[0]:
            m = ui_messages.get(block=False)
            # debug_print("got ui message", m)
            if m[0] == "value_change":
                # debug_print("got value change in process_ui")
                effect_name_parameter, value = m[1:]
                effect_name, parameter = effect_name_parameter.rsplit("/", 1)
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
                        effect_type = current_effects[effect_name]["effect_type"]
                        # debug_print("value set", value, effect_type, parameter )
                        if "kill_dry" in effect_prototypes[effect_type] and parameter == "enabled":
                            # debug_print("kill dry value set", value)
                            current_effects[effect_name]["enabled"].value = bool(float(value))
                        current_effects[effect_name]["controls"][parameter].value = float(value)
                except ValueError:
                    pass

            elif m[0] == "bpm_change":
                current_bpm.value = m[1][0]
            elif m[0] == "set_plugin_state":
                pass
                # plugin_state[m[1][0]].value = m[1][1]
            elif m[0] == "add_connection":
                head, tail = m[1:]
                from_backend_add_connection(head, tail)
            elif m[0] == "remove_connection":
                head, tail = m[1:]
                from_backend_disconnect(head, tail)
            elif m[0] == "add_plugin":
                effect_name, effect_type, x, y, is_enabled = m[1:6]
                # debug_print("got add", m)
                if (effect_name not in current_effects and (effect_type in inv_effect_type_map or effect_type in bare_ports)):
                    # debug_print("adding ", m)
                    if effect_type == "http://polyeffects.com/lv2/polyfoot":
                        mapped_type = effect_name.rsplit("/", 1)[1].rstrip("123456789")
                        if mapped_type in effect_type_map:
                            from_backend_new_effect(effect_name, mapped_type, x, y, is_enabled)
                    elif effect_type in bare_ports:
                        debug_print("### adding in bare ports", m)
                        from_backend_new_effect(effect_name, effect_type, x, y, is_enabled)
                    else:
                        from_backend_new_effect(effect_name, inv_effect_type_map[effect_type], x, y, is_enabled)
                        ingen_wrapper.get_state("/engine")
            elif m[0] == "remove_plugin":
                effect_name = m[1]
                if (effect_name in current_effects):
                    from_backend_remove_effect(effect_name)
            elif m[0] == "enabled_change":
                effect_name, is_enabled = m[1:]
                # debug_print("enabled changed ", m)
                if (effect_name in current_effects):
                    # debug_print("adding ", m)
                    current_effects[effect_name]["enabled"].value = bool(is_enabled)
            elif m[0] == "pedalboard_loaded":
                subgraph, file_name = m[1:]
                # disable loading sign
                print ("pedalboard loaded", subgraph, file_name, current_sub_graph)
                if subgraph == current_sub_graph.rstrip("/"):
                    is_loading.value = False
                    done_loading_time = time.perf_counter()
                    # check if we've got MIDI IO, if not add them
                    print("### preset loaded in ", done_loading_time - preset_started_loading_time)
                    debug_print("checking if MIDI exists")
                    if not (current_sub_graph+"midi_in" in current_effects):
                        ingen_wrapper.add_midi_input(current_sub_graph+"midi_in", x=1192, y=(80 * 5))
                        debug_print("adding MIDI")
                    if not (current_sub_graph+"midi_out" in current_effects):
                        ingen_wrapper.add_midi_output(current_sub_graph+"midi_out", x=-20, y=(80 * 5))
                    if current_pedal_model.name == "hector" and not (current_sub_graph+"out_5" in current_effects):
                        # add hector IO TODO
                        pass

            elif m[0] == "dsp_load":
                max_load, mean_load, min_load = m[1:]
                dsp_load.rmin = min_load
                dsp_load.rmax = max_load
                dsp_load.value = mean_load + 0.25
            elif m[0] == "set_comment":
                description, subject = m[1:]
                preset_description.name = description
            elif m[0] == "assign_footswitch":
                footswitch, effect_name = m[1:]
                if effect_name in current_effects:
                    current_effects[effect_name]["assigned_footswitch"].value = footswitch
                    # remove existing assignment if any
                    for k in footswitch_assignments.keys():
                        footswitch_assignments[k].discard(effect_name)
                    if footswitch in footswitch_assignments:
                        footswitch_assignments[footswitch].add(effect_name)
            elif m[0] == "midi_pc":
                program = m[1]
                jump_to_preset(False, program)
            elif m[0] == "add_port":
                pass
            elif m[0] == "set_file":
                effect_name, ir_file = m[1:]
                try:
                    if (effect_name in current_effects) and ("ir" in current_effects[effect_name]["controls"]):
                        if current_effects[effect_name]["controls"]["ir"].name != ir_file:
                            current_effects[effect_name]["controls"]["ir"].name = ir_file
                            effect_type = current_effects[effect_name]["effect_type"]
                            if effect_type in ["mono_reverb", "stereo_reverb", "quad_ir_reverb"]:
                                # debug_print("setting reverb file", urllib.parse.unquote(ir_file))
                                knobs.update_ir(effect_name, urllib.parse.unquote(ir_file))
                            elif effect_type in ["mono_cab", "stereo_cab", "quad_ir_cab"]:
                                knobs.update_ir(effect_name, urllib.parse.unquote(ir_file))
                                # debug_print("setting cab file", urllib.parse.unquote(ir_file))
                        # qDebug("setting knob file " + ir_file)
                except ValueError:
                    pass
            elif m[0] == "remove_port":
                pass
            elif m[0] == "exit":
                # global EXIT_PROCESS
                EXIT_PROCESS[0] = True
            elif m[0] == "broadcast_update":
                # debug_print("got value change in process_ui")
                effect_name_parameter, value = m[1:]
                effect_name, parameter = effect_name_parameter.rsplit("/", 1)

                if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
                    effect_type = current_effects[effect_name]["effect_type"]
                    # debug_print("value set", value, effect_type, parameter )
                    if "kill_dry" in effect_prototypes[effect_type] and parameter == "enabled":
                        # debug_print("kill dry value set", value)
                        current_effects[effect_name]["enabled"].value = bool(float(value))
                    current_effects[effect_name]["controls"][parameter].value = float(value)
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["broadcast_ports"]):
                        current_effects[effect_name]["broadcast_ports"][parameter].value = float(value)
                        # print("updated ", effect_name, parameter, value)
                except ValueError:
                    pass
            elif m[0] == "midi_learn":
                debug_print("got midi_learn in process_ui")
                effect_name_parameter, value = m[1:]
                effect_name, parameter = effect_name_parameter.rsplit("/", 1)
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
                        current_effects[effect_name]["controls"][parameter].cc = int(value)
                        # print("updated ", effect_name, parameter, value)
                except ValueError:
                    pass
    except queue.Empty:
        pass




effect_type_map = {}
effect_prototypes = {}
inv_effect_type_map = {}


def set_available_effects():
    hidden_effects = ["mix_vca"]
    # add list is effect_category:effect_name
    effects = set(effect_type_map.keys()) - set(hidden_effects)
    cat_effects = [[], [], [], []]
    for e in effects:
        cat_effects[effect_prototypes[e]["category"]].append(e)
    #     print(e)
    #     # qDebug(e)
    #     if "category" not in effect_prototypes[e]:
    #         print(e)
    #         qDebug("MISSING")
    #         qDebug(e)
        # print(e, str(effect_prototypes[e]["category"]))
    # cat_effects = sorted([str(effect_prototypes[e]["category"])+":"+e for e in effects])
    for i, a in enumerate(cat_effects):
        available_effects[i].setStringList(sorted(a))
    # available_effects.setStringList(list(effects))

def change_pedal_model(name, initial=False):
    _name = "beebo" # override
    global inv_effect_type_map
    global effect_type_map
    global effect_prototypes
    effect_type_map = effect_type_maps[_name]
    effect_prototypes = effect_prototypes_models[_name]

    set_available_effects()
    context.setContextProperty("effectPrototypes", effect_prototypes)
    accent_color_models = {"beebo": "#FFA0E0", "digit": "#FFA0E0", "hector": "#32D2BE"}
    accent_color.name = accent_color_models[name]

    inv_effect_type_map = {v:k for k, v in effect_type_map.items()}
    current_pedal_model.name = name
    load_preset_list()
    jump_to_preset(False, 0)

def handle_MIDI_program_change():
    # This is pretty dodgy... but I don't want to depend on jack in the main process as it'll slow down startup
    # we need to wait here for ttymidi to be up
    ttymidi_found = False
    if IS_REMOTE_TEST:
        return
    while not ttymidi_found:
        a = subprocess.run(["jack_lsp", "ttymidi"], capture_output=True)
        if b"ttymidi" in a.stdout:
            ttymidi_found = True
        time.sleep(1)
    p = subprocess.Popen('jack_midi_dump', stdout=subprocess.PIPE)
    # Grab stdout line by line as it becomes available.  This will loop until 
    time.sleep(2)
    try:
        command = ["/usr/bin/jack_connect",  "ttymidi:MIDI_in", "midi-monitor:input"]
        ret_var = subprocess.run(command)
        # check if MIDI thru is needed
        if pedal_state["thru"] == True:
            command = ["/usr/bin/jack_connect",  "ttymidi:MIDI_in", "ttymidi:MIDI_out"]
            ret_var = subprocess.run(command)
    except:
        pass
    # p terminates.
    while p.poll() is None:
        l = p.stdout.readline() # This blocks until it receives a newline.
        if len(l) > 8 and l[6] == b'c'[0]:
            b = l.decode()
            ig, b1, b2 = b.split()
            channel = int("0x"+b1, 16) - 0xC0
            program = int("0x"+b2, 16)
            # debug_print(channel, program)
            if channel == midi_channel.value - 1: # our channel
                # put this in the queue
                ui_messages.put(("midi_pc", program))
    # When the subprocess terminates there might be unconsumed output 
    # that still needs to be processed.
    ignored = p.stdout.read()

if __name__ == "__main__":

    debug_print("in Main")
    app = QGuiApplication(sys.argv)
    QIcon.setThemeName("digit")
    QFontDatabase.addApplicationFont("qml/fonts/BarlowSemiCondensed-SemiBold.ttf")
    font = QFont("BarlowSemiCondensed", 20, QFont.DemiBold)
    app.setFont(font)

    # preset might not have been copied on an update, as file system might not have been supported
    if not os.path.isfile("/mnt/presets/beebo/Empty.ingen/main.ttl") and not IS_REMOTE_TEST:
        # rsync
        command = "sudo rsync -a /to_nor_flash/ /nor_flash"
        ret_var = subprocess.call(command, shell=True)

    if os.path.isfile("/mnt/presets/digit/Empty.ingen/main.ttl") and not IS_REMOTE_TEST:
        # first time running after merge update
        command = "mv -f /mnt/presets/digit/* /mnt/presets/beebo/;rm -rf /mnt/presets/digit/*"
        ret_var = subprocess.call(command, shell=True)
        get_meta_from_files(True)

    # Instantiate the Python object.
    knobs = Knobs()
    loopler = loopler_lib.Loopler()


    update_counter = PolyValue("update counter", 0, 0, 500000)
    # read persistant state
    pedal_state = {}
    load_pedal_state()
    current_bpm = PolyValue("BPM", 120, 30, 250) # bit of a hack
    current_preset = PolyValue("Default Preset", 0, 0, 127)
    current_preset_filename = ""
    update_counter = PolyValue("update counter", 0, 0, 500000)
    command_status = [PolyValue("command status", -1, -10, 100000), PolyValue("command status", -1, -10, 100000)]
    delay_num_bars = PolyValue("Num bars", 1, 1, 16)
    dsp_load = PolyValue("DSP Load", 0, 0, 0.3)
    foot_switch_qa = {"a":PolyValue("a", 0, 0, 1), "b":PolyValue("b", 0, 0, 1), "c":PolyValue("c", 0, 0, 1), "d":PolyValue("d", 0, 0, 1), "e":PolyValue("e", 0, 0, 1)}
    encoder_qa = {"left":PolyValue("a", 0, 0, 1), "right":PolyValue("b", 0, 0, 1)}
    connect_source_port = PolyValue("", 1, 1, 16) # for sharing what type the selected source is
    midi_channel = PolyValue("channel", pedal_state["midi_channel"], 1, 16)
    input_level = PolyValue("input level", pedal_state["input_level"], -80, 10)
    preset_description = PolyValue("tap to write description", 0, 0, 1)
    debug_print("### Input level is", input_level.value)
    knobs.set_input_level(pedal_state["input_level"], write=False)
    pedal_bypassed = PolyBool(False)
    is_loading = PolyBool(False)
    foot_switch_warning = PolyBool(False)
    preset_meta_data = {}
    favourites = {}
    load_preset_meta_cache()
    load_favourites_data()

    patch_bay_notify = PatchBayNotify()

    available_effects = [QStringListModel() for i in range(4)]
    set_available_effects()
    engine = QQmlApplicationEngine()

    current_pedal_model = PolyValue(hardware_info["pedal"], 0, -1, 1)
    # accent_color = PolyValue("#8BB8E8", 0, -1, 1)
    accent_color = PolyValue("#FF75D0", 0, -1, 1)
    current_ip = PolyValue("", 0, -1, 1)

    # Expose the object to QML.
    # global context
    context = engine.rootContext()
    context.setContextProperty("knobs", knobs)
    context.setContextProperty("loopler", loopler)
    change_pedal_model(pedal_state["model"], True)
    context.setContextProperty("available_effects", available_effects)
    context.setContextProperty("selectedSourceEffectPorts", selected_source_effect_ports)
    context.setContextProperty("selectedDestEffectPorts", selected_dest_effect_ports)
    context.setContextProperty("portConnections", port_connections)
    context.setContextProperty("effectPrototypes", effect_prototypes)
    context.setContextProperty("updateCounter", update_counter)
    context.setContextProperty("currentBPM", current_bpm)
    context.setContextProperty("dspLoad", dsp_load)
    context.setContextProperty("isPedalBypassed", pedal_bypassed)
    context.setContextProperty("currentPreset", current_preset)
    context.setContextProperty("commandStatus", command_status)
    context.setContextProperty("delayNumBars", delay_num_bars)
    context.setContextProperty("connectSourcePort", connect_source_port)
    context.setContextProperty("midiChannel", midi_channel)
    context.setContextProperty("isLoading", is_loading)
    context.setContextProperty("inputLevel", input_level)
    context.setContextProperty("currentPedalModel", current_pedal_model)
    context.setContextProperty("accent_color", accent_color)
    context.setContextProperty("presetList", preset_list_model)
    context.setContextProperty("footSwitchQA", foot_switch_qa)
    context.setContextProperty("encoderQA", encoder_qa)
    context.setContextProperty("footSwitchWarning", foot_switch_warning)
    context.setContextProperty("pedalboardDescription", preset_description)
    context.setContextProperty("patchBayNotify", patch_bay_notify)
    context.setContextProperty("presetMeta", preset_meta_data)
    context.setContextProperty("favourites", favourites)
    context.setContextProperty("pedalState", pedal_state)
    context.setContextProperty("currentIP", current_ip)
    engine.load(QUrl("qml/TopLevelWindow.qml"))
    debug_print("starting send thread")
    ingen_wrapper.start_send_thread()
    debug_print("starting recv thread")
    ingen_wrapper.start_recv_thread(ui_messages)

    pedal_hardware.foot_callback = handle_foot_change
    pedal_hardware.encoder_change_callback = handle_encoder_change
    pedal_hardware.add_hardware_listeners()
    knobs.launch_task(0.5, handle_MIDI_program_change)

    # qWarning("logging with qwarning")
    try:
        add_io()
    except Exception as e:
        debug_print("########## e1 is:", e)
        ex_type, ex_value, tb = sys.exc_info()
        error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
        debug_print("EXception is:", error)
        sys.exit()

    sys._excepthook = sys.excepthook
    def exception_hook(exctype, value, tb):
        debug_print("except hook got a thing!")
        traceback.print_exception(exctype, value, tb)
        sys._excepthook(exctype, value, tb)
        # sys.exit(1)
    sys.excepthook = exception_hook
    # try:
    # crash_here
    # except:
    #     debug_print("caught crash")
    # timer = QTimer()
    # timer.timeout.connect(tick)
    # timer.start(1000)

    def signalHandler(sig, frame):
        if sig in (SIGINT, SIGTERM):
            qWarning("frontend got signal")
            # global EXIT_PROCESS
            EXIT_PROCESS[0] = True
            ingen_wrapper._FINISH = True
            ingen_wrapper.ingen._FINISH = True
            pedal_hardware.EXIT_THREADS = True
            ingen_wrapper.ingen.sock.close()
    signal(SIGINT,  signalHandler)
    signal(SIGTERM, signalHandler)
    initial_preset = False
    debug_print("starting UI")
    time.sleep(0.2)
    ingen_wrapper.get_state("/main")
    # load_preset("file:///mnt/presets/Default_Preset.ingen/main.ttl", False)
    # ingen_wrapper._FINISH = True
    update_dsp_usage_count = 200
    num_loops = 0
    while not EXIT_PROCESS[0]:
        # debug_print("processing events")
        try:
            app.processEvents()
            # debug_print("processing ui messages")
            process_ui_messages()
            pedal_hardware.process_input()
            if num_loops > update_dsp_usage_count:
                num_loops = 0
                ingen_wrapper.get_state("/engine")
        except Exception as e:
            qCritical("########## e2 is:"+ str(e))
            ex_type, ex_value, tb = sys.exc_info()
            error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
            debug_print("EXception is:", error)
            qCritical("########## exception is:"+ str(error))
            sys.exit()
        sleep(0.01)

    qWarning("mainloop exited")
    ingen_wrapper.s_thread.join()
    qWarning("s_thread exited")
    if pedal_hardware.hw_thread is not None:
        qWarning("hw_thread joining")
        pedal_hardware.hw_thread.join()
        qWarning("hw_thread exited")
    ingen_wrapper.r_thread.join()
    qWarning("r_thread exited")
    app.exit()
    sys.exit()
    qWarning("sys exit called")
        # if not initial_preset:
        #     load_preset("/presets/Default Preset.json")
        #     update_counter.value+=1
        #     initial_preset = True
