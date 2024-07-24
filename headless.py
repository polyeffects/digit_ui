import sys, time, json, os.path, os, subprocess, queue, threading, traceback, glob
import shutil, socket
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit
from collections import OrderedDict
from enum import Enum, IntEnum
import urllib.parse
from pathlib import Path

sys._excepthook = sys.excepthook
def exception_hook(exctype, value, tb):
    debug_print("except hook 1 got a thing!") #, exctype, value, traceback)
    traceback.print_exception(exctype, value, tb)
    sys._excepthook(exctype, value, tb)
    sys.exit(1)
sys.excepthook = exception_hook

import ingen_wrapper
import mcu_comms
import module_info
from static_globals import IS_REMOTE_TEST, PEDAL_TYPE, pedal_types


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
is_loading = False




verbs_controllable_modules = {'/main/wet_dry_stereo1', '/main/filter_uberheim1', '/main/sum1', '/main/delay1', '/main/wet_dry_stereo2', '/main/vca1', '/main/quad_ir_reverb1'}

ample_controllable_modules = {'/main/amp_nam1', '/main/mono_cab1', '/main/amp_nam2', '/main/mono_cab2', '/main/tonestack1', '/main/tonestack2', '/main/boost1', '/main/boost2'}

if PEDAL_TYPE == pedal_types.ample: # pedal_types.verbs
    verbs_controllable_modules = ample_controllable_modules

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

amp_browser_model_s = None

def debug_print(*args, **kwargs):
    print( "From py: "+" ".join(map(str,args)), **kwargs)
    pass


effect_type_maps = module_info.effect_type_maps

effect_prototypes_models_all = module_info.effect_prototypes_models_all
# effect_prototypes_models_all = 

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

bare_output_ports =  ("output", "midi_output", "loop_common_in", "loop_extra_midi")
bare_input_ports = ("input", "midi_input", "loop_common_out", "loop_midi_out")
bare_ports = bare_output_ports + bare_input_ports


def clamp(v, min_value, max_value):
    return max(min(v, max_value), min_value)

def insert_row(model, row):
    j = len(model)
    model.insertRows(j, 1)
    model.setData(model.index(j), row)

def remove_row(model, row):
    i = model.index(row)
    model.removeRows(i, 1)

preset_list = []
preset_list_model = preset_list
hardware_info = {}
def load_preset_list():
    global preset_list
    preset_list = ["file:///home/pleb/Verbs2.ingen"]
    preset_list_model = preset_list

try:
    with open("/pedal_state/hardware_info.json") as f:
        hardware_info = json.load(f)
    hardware_info["revision"]
except:
    hardware_info = {"revision": 10, "pedal": "beebo"}

if hardware_info["pedal"] == "digit":
    hardware_info["pedal"] = "beebo"


class MyWorker():

    def __init__(self, command, after=None):
        super().__init__()
        self.command = command
        self.after = after

    def run(self):
        # run subprocesses, grab output
        ret_var = subprocess.run(self.command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True, shell=True)
        if self.after is not None:
            self.after()

class MyTask():

    def __init__(self, delay, command):
        super(MyTask, self).__init__()
        self.command = command
        self.delay = delay

    def run(self):
        # run subprocesses, grab output
        time.sleep(self.delay)
        ret_var = self.command()

def PolyBool(v):
    return bool(v)

class PolyValue():
    # name, min, max, value
    def __init__(self, startname="", startval=0, startmin=0, startmax=1, v_type="float", curve_type="lin", startcc=-1):
        self.nameval = startname
        self.valueval = startval
        self.defaultval = startval
        self.rmax = startmax
        self.rmin = startmin
        self.ccval = startcc

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        # clamp values
        self.valueval = clamp(val, self.rmin, self.rmax)
        # debug_print("setting value", val)

    def value_changed(self):
        pass

    value = property(readValue, setValue)

    def readDefaultValue(self):
        return self.defaultval

    def setDefaultValue(self,val):
        # clamp values
        self.defaultval = clamp(val, self.rmin, self.rmax)
        # debug_print("setting value", val)

    def default_value_changed(self):
        pass

    default_value = property(readDefaultValue, setDefaultValue)

    def readCC(self):
        return self.ccval

    def setCC(self,val):
        self.ccval = val
        # debug_print("setting value", val)

    def cc_changed(self):
        pass

    cc = property(readCC, setCC)

    def readName(self):
        return self.nameval

    def setName(self,val):
        self.nameval = val

    name = property(readName, setName)

def jump_to_preset(is_inc, num, initial=False):

    if is_loading == True:
        return
    # TODO need to call frontend function to jump to home page
    before_change_preset_num = current_preset.value
    p_list = preset_list_model
    preset_load_counter.value = preset_load_counter.value + 1
    if is_inc:
        current_preset.value = (current_preset.value + num) % len(p_list)
    else:
        if num < len(p_list):
            current_preset.value = num
        else:
            return
    if before_change_preset_num == current_preset.value and not initial:
        debug_print("already on preset, not jumping ", p_list[current_preset.value], "num is", num)
    else:
        debug_print("jumping to preset ", p_list[current_preset.value], "num is", num)
        knobs.ui_load_preset_by_name(p_list[current_preset.value])

def write_pedal_state():
    with open("/pedal_state/state.json", "w") as f:
        json.dump(pedal_state, f)
    os.sync()


def load_pedal_state():
    global pedal_state
    try:
        with open("/pedal_state/state.json") as f:
            pedal_state = json.load(f)
            if "midi_channel" not in pedal_state:
                pedal_state["midi_channel"] = 1
            if "thru" not in pedal_state:
                pedal_state["thru"] = True
            if "invert_enc" not in pedal_state:
                pedal_state["invert_enc"] = False
            if "screen_flipped" not in pedal_state:
                pedal_state["screen_flipped"] = False
            if "l_to_r" not in pedal_state:
                pedal_state["l_to_r"] = False
            if "d_is_tuner" not in pedal_state:
                pedal_state["d_is_tuner"] = True
            if "set_list" not in pedal_state:
                pedal_state["set_list"] = [0, 8, 16, 24, 32, 40, 48]
    except:
        pedal_state = {"input_level": 0, "midi_channel": 1, "author": "poly player",
                "model": "beebo", "thru": True, "invert_enc": False, "screen_flipped": False,
                "d_is_tuner": True, "set_list" : [0, 8, 16, 24, 32, 40, 48],
                }


selected_source_effect_ports = ["val1", "val2"]
selected_dest_effect_ports = ["val1", "val2"]
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

def load_preset(name, initial=False, force=False):
    global is_loading
    if is_loading == True and not force:
        return
    debug_print("in load preset")
    is_loading = True
    global preset_started_loading_time
    preset_started_loading_time = time.perf_counter()
    # is_loading.value = True
    # delete existing blocks
    port_connections.clear()
    reset_footswitch_assignments()
    knobs.spotlight_entries = []
    preset_description.name = "Tap here to enter preset description"
    to_delete = list(current_effects.keys())
    for effect_id in to_delete:
        if effect_id in ["/main/out_1", "/main/out_2", "/main/out_3", "/main/out_4", "/main/in_1", "/main/in_2", "/main/in_3", "/main/in_4"]:
            pass
        else:
            try:
                current_effects.pop(effect_id)
            except:
                pass
    if not initial:
        # debug_print("deleting sub graph", current_sub_graph)
        delete_sub_graph(current_sub_graph)
    add_inc_sub_graph(False)
    # debug_print("adding inc sub graph", current_sub_graph)
    debug_print("calling ingen wrapper loading pedalboard", name, "sub graph", current_sub_graph)
    ingen_wrapper.load_pedalboard(name, current_sub_graph.rstrip("/"))
    # if this preset has a looper config, load it
    # check if preset file exists

    time.sleep(0.1)
    ingen_wrapper.get_state("/engine")

def from_backend_new_effect(effect_name, effect_type, x=20, y=30, is_enabled=True):
    # called by engine code when new effect is created
    debug_print("from backend new effect", effect_name, effect_type)
    if effect_type in effect_prototypes:
        broadcast_ports = {}
        if "broadcast_ports" in effect_prototypes[effect_type]:
            broadcast_ports = {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["broadcast_ports"].items()}
        current_effects[effect_name] = {"x": x, "y": y, "effect_type": effect_type,
                "controls": {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["controls"].items()},
                "broadcast_ports" : broadcast_ports,
                "enabled": PolyBool(is_enabled)}

        # if were the last verbs needed effect, load verbs preset

        if effect_name in verbs_controllable_modules and len(verbs_controllable_modules - set(current_effects.keys())) == 0:
            # load verbs preset
            if not mcu_comms.verbs_initial_preset_loaded:
                print("loading vebs initial preset", pedal_state["set_list"][0])
                mcu_comms.load_verbs_preset(pedal_state["set_list"][0])
                debug_print("loading verbs initial preset! midi channel", midi_channel.value)
                mcu_comms.update_midi_ccs(midi_channel.value)
                mcu_comms.verbs_initial_preset_loaded = True
                mcu_comms.set_main_enable(True)

    else:
        debug_print("### backend tried to add an unknown effect!")

def from_backend_remove_effect(effect_name):
    # called by engine code when effect is removed
    if effect_name not in current_effects:
        return
    effect_type = current_effects[effect_name]["effect_type"]
    debug_print("### from backend removing effect")

    # if we're in spotlight, remove from spotlight
    if len([[k, v, v2] for k,v,v2 in knobs.spotlight_entries if k == effect_name]) > 0:

        for spotlight_entry in knobs.spotlight_entries:
            if spotlight_entry[0] == effect_name:
                spotlight_entries_changed(spotlight_entry[0], spotlight_entry[1], '', spotlight_entry[2])
        knobs.spotlight_entries = [[k, v, v2] for k,v, v2 in knobs.spotlight_entries if k != effect_name]
    for source_port, targets in list(port_connections.items()):
        s_effect, s_port = source_port.rsplit("/", 1)
        if s_effect == effect_name:
            del port_connections[source_port]
        else:
            port_connections[source_port] = [[e, p] for e, p in port_connections[source_port] if e != effect_name]

    # if this was a looper module, check if there are any left
    for k in footswitch_assignments.keys(): # if this module has a foot switch assigned to it
        footswitch_assignments[k].discard(effect_name)
    # debug_print("removing effects, current keys", current_effects.keys())

    # current_effects.pop(effect_name) # done after UI removes it
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
    update_counter.value+=1


def du(path):
    """disk usage in human readable format (e.g. '2,1GB')"""
    return subprocess.check_output(['du','-sh', path]).split()[0].decode('utf-8')

class Knobs():
    spotlight_entries = []

    def __init__(self, parent=None):
        super().__init__()
        self.spotlight_entries = []
        # type(self).__dict__["spotlight_entries"].setter(self, [])

    def get_current_parameter_value(self, effect_id, parameter):
        return current_effects[effect_id]["controls"][parameter].value

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
        else:
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


    def select_effect(self, is_source, effect_id, interconnect=False):
        restrict_port_types = not interconnect
        effect_type = current_effects[effect_id]["effect_type"]
        # debug_print("selecting effect type", effect_type, is_source, "interconnect is ", interconnect)
        if is_source:
            ports = sorted([v[1]+'|'+v[0]+'|'+k for k,v in effect_prototypes[effect_type]["outputs"].items()])
            selected_source_effect_ports = ports
        else:

            s_effect_id, s_port = connect_source_port.name.rsplit("/", 1)
            source_port_type = effect_prototypes[current_effects[s_effect_id]["effect_type"]]["outputs"][s_port][1]
            # if hector, if source is an physical input or output is a physical output, 
            # disable restrict_port_types
            if current_pedal_model.name == "hector":
                if effect_type in ["output", "midi_output"] or current_effects[s_effect_id]["effect_type"] in ["input", "midi_input"]:
                    restrict_port_types = False

            if restrict_port_types or source_port_type == "AtomPort":
                ports = sorted([v[1]+'|'+v[0]+'|'+k for k,v in effect_prototypes[effect_type]["inputs"].items() if v[1] == source_port_type])
            else:
                ports = sorted([v[1]+'|'+v[0]+'|'+k for k,v in effect_prototypes[effect_type]["inputs"].items() if (v[1] not in ["AtomPort", "ControlPort"])])

            # debug_print("ports is ", ports)
            selected_dest_effect_ports = ports

    def list_connected(self, effect_id):
        ports = []
        for source_port, connected in port_connections.items():
            s_effect, s_port = source_port.rsplit("/", 1)
            display_s_port = effect_prototypes[current_effects[s_effect]["effect_type"]]["inputs"][s_port][0]
            # connections where we are target
            for c_effect, c_port in connected:
                display_c_port = effect_prototypes[current_effects[c_effect]["effect_type"]]["outputs"][c_port][0]
                if c_effect == effect_id:
                    ports.append("output==="+display_c_port+" connected to "+s_effect.rsplit("/", 1)[1]+" "+ display_s_port +"==="+s_effect+"/"+s_port+"---"+c_effect+"/"+c_port)
                elif s_effect == effect_id:
                    ports.append("input==="+c_effect.rsplit("/", 1)[1]+ " "+display_c_port+" connected to "+display_s_port+"==="+s_effect+"/"+s_port+"---"+c_effect+"/"+c_port)
        # debug_print("connected ports:", ports, effect_id)
        # qWarning("connected Ports "+ str(ports) + " " + effect_id)
        ports.sort()
        selected_source_effect_ports = ports

    def disconnect_port(self, port_pair, original_item):
        ports_list = [v for v in selected_source_effect_ports if v != original_item]
        selected_source_effect_ports = ports_list

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

    def add_new_effect(self, effect_type):
        # calls backend to add effect
        global seq_num
        seq_num = seq_num + 1
        debug_print("add new effect", effect_type)
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
            # debug_print("new effect si bare port")
            bare_ports_map = {"input" : "in", "output" : "out", "midi_input" : "midi_in",
                    "midi_output" : "midi_out", "loop_common_in" : "out",
                    "loop_common_out" : "in",
                    "loop_extra_midi": "midi_out", "loop_midi_out": "midi_in"}
            if bare_ports_map[effect_type] == "in":
                ingen_wrapper.add_input(effect_name, 900, 150)
            elif bare_ports_map[effect_type] == "out":
                ingen_wrapper.add_output(effect_name, 900, 150)
            elif effect_type == "loop_extra_midi":
                ingen_wrapper.add_loop_extra_midi(effect_name, 900, 150)
            elif effect_type == "loop_midi_out":
                ingen_wrapper.add_loop_midi_out(effect_name, 900, 150)
            # ingen_wrapper.add_input("/main/in_"+str(i), x=1192, y=(80*i))
        else:
            ingen_wrapper.add_plugin(effect_name, effect_type_map[effect_type])
        # from_backend_new_effect(effect_name, effect_type)


    def set_bypass(self, effect_name, is_active):
        # check if were kill dry, if so, set enabled value, else just call default ingen:enabled
        effect_type = current_effects[effect_name]["effect_type"]
        if "kill_dry" in effect_prototypes[effect_type]:
            v = 1.0 - (current_effects[effect_name]["controls"]["enabled"])
            knobs.ui_knob_change(effect_name, "enabled", v)
            current_effects[effect_name]["enabled"] = bool(v)
        else:
            ingen_wrapper.set_bypass(effect_name, is_active)

    def set_description(self, description):
        ingen_wrapper.set_description(current_sub_graph.rstrip("/"), description)
        preset_description.name = description

    def move_effect(self, effect_name, x, y):
        try:
            current_effects[effect_name]["x"] = x
            current_effects[effect_name]["y"] = y
        except KeyError:
            pass
        ingen_wrapper.set_plugin_position(effect_name, x, y)

    def remove_effect(self, effect_id):
        # calls backend to remove effect
        # debug_print("remove effect", effect_id)
        ingen_wrapper.remove_plugin(effect_id)

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

    def ui_knob_toggle(self, effect_name, parameter):
        # debug_print(x, y, z)
        if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
            value = 1.0 - current_effects[effect_name]["controls"][parameter].value
            # clamping here to make it a bit more obvious
            value = clamp(value, current_effects[effect_name]["controls"][parameter].rmin, current_effects[effect_name]["controls"][parameter].rmax)
            current_effects[effect_name]["controls"][parameter].value = value
            ingen_wrapper.set_parameter_value(effect_name+"/"+parameter, value)

            mcu_comms.send_value_to_mcu(effect_name, parameter, float(value))
        else:
            debug_print("effect not found", effect_name, parameter, value, effect_name in current_effects)

    def ui_knob_inc(self, effect_name, parameter, is_inc=True):
        if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
            v = current_effects[effect_name]["controls"][parameter].value
            change  = abs(v / 10.0)
            if change < 0.01:
                change = 0.01

            if is_inc:
                v = v + change
            else:
                v = v - change
            # clamping here to make it a bit more obvious
            v = clamp(v, current_effects[effect_name]["controls"][parameter].rmin, current_effects[effect_name]["controls"][parameter].rmax)
            # bit sketch but check if BPM here? XXX
            if parameter == "bpm":
                set_bpm(v)

            current_effects[effect_name]["controls"][parameter].value = v
            ingen_wrapper.set_parameter_value(effect_name+"/"+parameter, v)
        else:
            debug_print("effect not found", effect_name, parameter, v, effect_name in current_effects)

    def update_ir(self, effect_id, ir_file):
        is_cab = True
        prefix="file://"
        effect_type = current_effects[effect_id]["effect_type"]
        if effect_type in ["mono_reverb", "stereo_reverb", "quad_ir_reverb"]:
            is_cab = False

        if "file://" in ir_file:
            prefix=''

        current_effects[effect_id]["controls"]["ir"].name = ir_file
        # ir_browser_model_s.external_ir_set(ir_file)
        # print("#### file", ir_file, "prefix", prefix)
        ingen_wrapper.set_file(effect_id, prefix+ir_file, is_cab)

    def update_json(self, effect_id, ir_file):
        effect_type = current_effects[effect_id]["effect_type"]
        current_effects[effect_id]["controls"]["ir"].name = ir_file
        if effect_type == "amp_rtneural":
            ingen_wrapper.set_json(effect_id, ir_file)
        else:
            ingen_wrapper.set_json_nam(effect_id, ir_file)

    def ui_load_empty_preset(self, force=False):
        if force:
            # load_preset("file:///mnt/presets/beebo/Empty.ingen/main.ttl", True)
            knobs.ui_load_qa_preset_by_name("file:///mnt/presets/beebo/Empty.ingen")
        else:
            knobs.ui_load_preset_by_name("file:///mnt/presets/beebo/Empty.ingen")


    def ui_load_preset_by_name(self, preset_file):
        if is_loading == True:
            return

        # debug_print("loading", preset_file)
        # outfile = preset_file[7:] # strip file:// prefix
        load_preset(preset_file+"/main.ttl")
        current_preset.name = preset_file.strip("/").split("/")[-1][:-6]
        global current_preset_filename
        global previous_preset_filename
        previous_preset_filename = current_preset_filename
        current_preset_filename = preset_file[7:]
        update_counter.value+=1

    def ui_load_qa_preset_by_name(self, preset_file):
        if is_loading == True:
            return

        # debug_print("loading", preset_file)
        # outfile = preset_file[7:] # strip file:// prefix
        load_preset(preset_file+"/main.ttl")
        current_preset.name = preset_file.strip("/").split("/")[-1][:-6]
        global current_preset_filename
        global previous_preset_filename
        previous_preset_filename = current_preset_filename
        current_preset_filename = preset_file[7:]
        update_counter.value+=1

    def ui_save_pedalboard(self, pedalboard_name):
        # debug_print("saving", preset_name)
        # TODO add folders
        if pedalboard_name.lower() == 'empty':
            return

        current_preset.name = pedalboard_name
        ingen_wrapper.set_author(current_sub_graph.rstrip("/"), pedal_state["author"])
        ingen_wrapper.save_pedalboard("beebo", pedalboard_name, current_sub_graph.rstrip("/"))
        self.launch_task(2, os.sync) # wait 2 seconds then sync to drive
        # update preset meta
        clean_filename = ingen_wrapper.get_valid_filename(pedalboard_name)
        if len(clean_filename) > 0:
            filename = "/mnt/presets/beebo/"+clean_filename+".ingen"
            global current_preset_filename
            global previous_preset_filename
            previous_preset_filename = current_preset_filename
            current_preset_filename = filename
            if filename in preset_meta_data:
                preset_meta_data[filename]["author"] = pedal_state["author"]
                preset_meta_data[filename]["description"] = preset_description.name
            else:
                preset_meta_data[filename] = {"author": pedal_state["author"], "description": preset_description.name}



    def ui_copy_irs(self):
        # debug_print("copy irs from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        # remount RW 
        # copy all wavs in /usb/reverbs and /usr/cabs to /audio/reverbs and /audio/cabs
        # remount RO 
        command = """if [ -b /dev/sda1 ]; then sudo mount /dev/sda1 /usb_flash;
        elif [ -b /dev/sdb1 ]; then sudo mount /dev/sdb1 /usb_flash;
        elif [ -b /dev/sda ]; then sudo mount /dev/sda /usb_flash;
        fi;
        if [ -d /usb_flash/reverbs ];
        then cd /usb_flash/reverbs; find . -maxdepth 1 -name "[0-7].wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/pedal_state/reverbs ; fi;
        if [ -f /usb_flash/set_list.txt ];
        then sudo cp /usb_flash/set_list.txt /pedal_state/ ; fi;
        sudo umount /usb_flash
        """
        debug_print("ui_copy_irs")
        command_status[0].value = -1
        self.launch_subprocess(command, after=mcu_comms.import_done)

    def ui_copy_amps(self):
        # remount RW 
        # copy all zips in /usb_flash/amps to /mnt/audio/amp_nam
        # remount RO 
        command = """ sudo mount -o remount,rw /dev/mmcblk0p2 /mnt;
        if [ -d /usb_flash/amps ]; then
        cd /usb_flash/amps; rename 's/[^a-zA-Z0-9. _-]/_/g' **;
        find . -iname "*.zip" -type f -print0 | xargs -0 cp --target-directory=/mnt/audio/amp_nam --parents;
        cd /mnt/audio/amp_nam/;
        find . -iname "*.zip" -type f -print0 | xargs -0 -n1 unzip;
        find . -iname "*.zip" -type f -print0 | xargs -0 rm;
        fi;
        sudo mount -o remount,ro /dev/mmcblk0p2 /mnt;"""
        command_status[0].value = -1

        self.launch_subprocess(command, after=amp_browser_model_s.external_update_reset)

    def ui_usb_folder_size(self, folder):
        # return how large a USB folder is in mb, just du the folder, will give us an approx idea of what will be copied
        try:
            return du(folder)
        except:
            return "Folder not found"

    def remaining_user_storage(self):
        # return how much space in mb is available
        return subprocess.check_output(['df','-h', '--output=avail', '/dev/mmcblk0p2']).split()[1].decode('utf-8')

    def usb_information_text(self):
        # return how much space in mb is available
        return f"""<h3>USB info</h3>
        <p>Cabs: {self.ui_usb_folder_size("/usb_flash/cabs")} </p>
        <p>Reverbs: {self.ui_usb_folder_size("/usb_flash/reverbs")} </p>
        <p>Amps: {self.ui_usb_folder_size("/usb_flash/amps")} </p>
        <h3>Remaining user storage</h3>
        <p>{self.remaining_user_storage()}</p>
        """

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

    def copy_logs(self):
        # debug_print("copy presets to USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """mkdir -p /usb_flash/logs; sudo cp /var/log/syslog /usb_flash/logs/;sudo umount /usb_flash"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    def ui_shutdown(self):
        ret_obj = subprocess.run("shutdown -h 'now'", shell=True)

    def ui_update_firmware(self):
        # debug_print("Updating firmware")
        # dpkg the debs in the folder
        # report if files can't be found, see if no usb drive is found, or if it's incompatible.
        # clear preset to save CPU
        self.ui_load_empty_preset(True)
        # if the drive can't be remounted RW then auto repair the drive and restart
        # /sbin/e2fsck -fy /dev/mmcblk0p1
        command_status[0].name = "Firmware update failed. The files were found, the flash drive appears to work but something else happened, please contact us. info@polyeffects.com Extra debugging info:"
        if len(glob.glob("/usb_flash/*.deb")) > 0:
            command = """sudo /usr/bin/polyoverlayroot-chroot dpkg -i -E -G /usb_flash/*.deb && sync && sudo shutdown -h 'now'"""
            # sync then sleep before shutdown
            command_status[0].value = -1
            self.launch_subprocess(command)
        else:
            # no files found, is there a usb drive?
            if os.path.exists("/dev/sda2"):
                command_status[0].name = """Firmware update failed. There's a USB drive inserted but it's got more partitions than we expect...
you'll need to flash the usb flash drive to a format that works for Beebo, please follow the instructions on the website"""
            elif os.path.exists("/dev/sda1"):
                # usb drive found, no files
                command_status[0].name = """Firmware update failed. There's a USB drive inserted but it doesn't have the files unzipped directly on the drive.
Please unzip the update and copy it directly to the drive. If that doesn't work, please contact info@polyeffects.com"""
            elif os.path.exists("/dev/sda"):
                command_status[0].name = """Firmware update failed. There's a USB drive inserted but it doesn't have any partitions on it...
you'll need to flash the usb flash drive to a format that works for Beebo, please follow the instructions on the website"""
            else:
                command_status[0].name = """Firmware update failed. No USB drive found. If you've got another one please try that. If that doesn't work please contact us, info@polyeffecs.com"""

            # 
            command_status[0].value = 1

    def ui_run_debug(self):
        if len(glob.glob("/usb_flash/*.sh")) > 0:
            command = """sudo /bin/bash /usb_flash/debug.sh"""
            command_status[0].value = -1
            self.launch_subprocess(command)
        else:
            command_status[0].value = 1


    def set_input_level(self, level, write=True):
        debug_print("setting input_level, ", level, input_level.value)
        if True:
            return
        # if IS_REMOTE_TEST:
        #     return
        # command = "amixer -- sset ADC1 "+str(level)+"db; amixer -- sset ADC2 "+str(level)+"db; amixer -- sset ADC3 "+str(level)+"db"
        # command_status[0].value = subprocess.call(command, shell=True)
        # if hardware_info["revision"] < 10 and pedal_state["model"] != "hector":
        #     command = "amixer -- sset 'ADC1 Invert' off,on; amixer -- sset 'ADC2 Invert' on,on"
        # elif pedal_state["model"] == "hector":
        #     command = ("amixer -- sset 'ADC1 Invert' on,on; amixer -- sset 'ADC2 Invert' on,on; amixer -- sset 'ADC3 Invert' on,on; "
        #             "amixer -- sset 'DAC1 Invert' on,on; amixer -- sset 'DAC2 Invert' on,on; amixer -- sset 'DAC3 Invert' on,on; amixer -- sset 'DAC4 Invert' on,on;")
        # else:
        #     command = "amixer -- sset 'ADC1 Invert' on,on; amixer -- sset 'ADC2 Invert' on,on"

        # command_status[0].value = subprocess.call(command, shell=True)
        # input_level.value = level
        # if write:
        #     pedal_state["input_level"] = level
        #     write_pedal_state()

    def set_channel(self, channel):
        debug_print("setting channel, ", channel, midi_channel.value)
        midi_channel.value = channel
        pedal_state["midi_channel"] = midi_channel.value
        write_pedal_state()

    def save_set_list(self, set_list):
        # debug_print("saving set list, ", set_list)
        pedal_state["set_list"] = set_list
        write_pedal_state()

    def get_set_list(self):
        return pedal_state["set_list"]

    def set_preset_list_length(self, v):
        if (v > len(preset_list_model)):
            # debug_print("inserting new row in preset list", v)
            insert_row(preset_list_model, "file:///mnt/presets/beebo/Default_Preset.ingen")
        else:
            # debug_print("removing row in preset list", v)
            preset_list_model.removeRows(v, 1)

    def map_preset(self, v, name):
        preset_list_model.setData(preset_list_model.index(v), name)

    def on_worker_done(self, ret_var):
        # debug_print("updating UI")
        command_status[0].value = ret_var

    def on_worker_done_output(self, ret_var):
        # debug_print("updating UI")
        command_status[1].name = ret_var

    def on_task_done(self, ret_var):
        # debug_print("updating UI")
        command_status[0].value = ret_var

    def launch_subprocess(self, command, after=None):
        # debug_print("launch_threadpool")
        worker = MyWorker(command, after)
        worker.run()

    def launch_task(self, delay, command):
        # debug_print("launch_threadpool")
        worker = MyTask(delay, command)
        worker_pool.start(worker)

    def set_knob_current_effect(self, effect_id, parameter):
        # get current value and update encoder / cache.
        # qDebug("setting knob current effect" + parameter)
        knob = "left"
        if not (knob_map[knob].effect == effect_id and knob_map[knob].parameter == parameter):
            knob_map[knob].effect = effect_id
            knob_map[knob].parameter = parameter
            knob_map[knob].rmin = current_effects[effect_id]["controls"][parameter].rmin
            knob_map[knob].rmax = current_effects[effect_id]["controls"][parameter].rmax

    def clear_knob_effect(self):
        # get current value and update encoder / cache.
        # qDebug("setting knob current effect" + parameter)
        knob = "left"
        knob_map[knob].effect = ""
        knob_map[knob].parameter = ""
        knob_map[knob].rmin = 0
        knob_map[knob].rmax = 1

    def set_pedal_model(self, pedal_model):
        if is_loading == True:
            return
        pedal_state["model"] = pedal_model
        write_pedal_state()
        change_pedal_model(pedal_model)

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

    def delete_preset(self, in_preset_file):
        preset_file = in_preset_file[len("file://"):]
        debug_print("delete: preset_file files is ", preset_file)
        # is always a directory
        # empty / default
        if ".ingen" not in preset_file or preset_file in ["/mnt/presets/digit/Default_Preset.ingen", "/mnt/presets/beebo/Empty.ingen", "/mnt/presets/digit/Empty.ingen"]:
            return
        # delete
        try: # if it doesn't exist, we still want to remove it from the preset list and meta cache
            shutil.rmtree(preset_file)
        except:
            pass
        # remove from set list.
        preset_list = preset_list_model
        debug_print("preset list is", preset_list)
        if in_preset_file in preset_list:
            preset_list = [v for v in preset_list if v != in_preset_file]
            preset_list_model = preset_list
            self.save_preset_list()
        preset_meta_data.pop(preset_file, False)
        os.sync()

    def save_preset_list(self):
        debug_print("saving preset list")
        with open("/mnt/pedal_state/beebo_preset_list.json", "w") as f:
            json.dump(preset_list_model, f)
        os.sync()
    preset_list_model = preset_list


    def set_pedal_author(self, author):
        pedal_state["author"] = author
        write_pedal_state()

    def set_current_mode(self, mode, effect_name):
        # debug_print("updating UI")
        global current_patchbay_mode
        global current_selected_effect
        current_patchbay_mode = mode
        current_selected_effect = effect_name

    def get_ip(self):
        ret_obj = subprocess.run("hostname -I", capture_output=True, shell=True)
        current_ip.name = ret_obj.stdout.decode()

    def set_broadcast(self, effect_name, is_broadcast):
        # debug_print(x, y, z)
        if (effect_name in current_effects) and ("broadcast_ports" in current_effects[effect_name]):
            for parameter in current_effects[effect_name]["broadcast_ports"].keys():
                ingen_wrapper.set_broadcast(effect_name+"/"+parameter, is_broadcast)
        else:
            debug_print("effect not found", effect_name, effect_name in current_effects)

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

    def set_midi_cc(self, effect_name, parameter, channel, cc):
        ingen_wrapper.midi_set_cc(effect_name+"/"+parameter, channel, cc)

    def get_midi_assignments(self):
        r = ""
        for effect_name in current_effects:

            effect_display_name = effect_name.rsplit("/", 1)[1].rstrip("1").replace("_", " ")
            for parameter in current_effects[effect_name]["controls"]:
                cc = current_effects[effect_name]["controls"][parameter].cc
                parameter_name = current_effects[effect_name]["controls"][parameter].name
                if cc > -1:
                    r = r + f"Effect: {effect_display_name} Parameter: {parameter_name} Channel: {(cc >> 8)+1} CC: {cc & 0xFF}\n"
        return r

    def finish_remove_effect(self, effect_name):
        try:
            current_effects.pop(effect_name) # done after UI removes it
        except:
            pass

    def expose_spotlight(self, effect_name, parameter):
        # this toggles, if we're already learned, forget. No way to currently cancel waiting for midi
        l_spotlight_entries = [b for b in self.spotlight_entries if b[0:2] == [effect_name, parameter]]
        if l_spotlight_entries != []:
            spotlight_entry = l_spotlight_entries[0]
            # remove it
            spotlight_entries_changed(spotlight_entry[0], spotlight_entry[1], '', spotlight_entry[2])
            ingen_wrapper.spotlight_remove(effect_name+"/"+parameter)
            self.spotlight_entries.remove(spotlight_entry)
        else:
            self.spotlight_entries.append([effect_name, parameter, "1"])
            if len(self.spotlight_entries) > 10:
                e_r, p_r, p_v = self.spotlight_entries.pop(0)
                spotlight_entries_changed(e_r, p_r, '', p_v)
                ingen_wrapper.spotlight_remove(e_r+"/"+p_r)
            ingen_wrapper.spotlight_set(effect_name+"/"+parameter, "1")

    def toggle_spotlight_binding(self, effect_name, parameter, control):
        # this toggles, control is l, r, x, y
        spotlight_entry = [b for b in self.spotlight_entries if b[0:2] == [effect_name, parameter]]
        if spotlight_entry == []:
            # shouldn't ever happen, spotlight should be bound already
            return
        i = self.spotlight_entries.index(spotlight_entry[0])

        current_v = spotlight_entry[0][2]
        prev_v = current_v


        if control in current_v:
            current_v = current_v.replace(control, "")
        else:
            current_v = current_v+control
        # print("#### current v ", current_v, effect_name, parameter)
        ingen_wrapper.spotlight_set(effect_name+"/"+parameter, current_v)
        self.spotlight_entries[i] = [effect_name, parameter, current_v]
        spotlight_entries_changed(effect_name, parameter, current_v, prev_v)

    def spotlight_set_y_remove_x(self, effect_name, parameter):
        # this toggles, control is l, r, x, y
        spotlight_entry = [b for b in self.spotlight_entries if b[0:2] == [effect_name, parameter]]
        if spotlight_entry == []:
            # shouldn't ever happen, spotlight should be bound already
            return
        i = self.spotlight_entries.index(spotlight_entry[0])

        current_v = spotlight_entry[0][2]
        prev_v = current_v

        current_v = current_v.replace('x', "")
        current_v = current_v+"y"
        # print("#### current v ", current_v, effect_name, parameter)
        ingen_wrapper.spotlight_set(effect_name+"/"+parameter, current_v)
        self.spotlight_entries[i] = [effect_name, parameter, current_v]
        spotlight_entries_changed(effect_name, parameter, current_v, prev_v)

    def xy_pad_change(self, x, y):
        spotlighted_x = spotlight_map["x"]
        spotlighted_y = spotlight_map["y"]
        y = 1.0 - y # flip from UI direction

        for effect_name, parameter in spotlighted_x:
            value = lerp(current_effects[effect_name]["controls"][parameter].rmin, current_effects[effect_name]["controls"][parameter].rmax, x)
            knobs.ui_knob_change(effect_name, parameter, value)

        for effect_name, parameter in spotlighted_y:
            value = lerp(current_effects[effect_name]["controls"][parameter].rmin, current_effects[effect_name]["controls"][parameter].rmax, y)
            knobs.ui_knob_change(effect_name, parameter, value)

def lerp(a, b, f):
    # start, stop, 0-1 fraction 
    return (a * (1.0 - f)) + (b * f)

def spotlight_entries_changed(effect_name, parameter, cur_v, prev_v):
    # online 
    # l, r, x, y are stored in a list for easy iteration
    cur_v  = cur_v.replace("1", "").replace("0", "")
    prev_v  = prev_v.replace("1", "").replace("0", "")
    added = set(cur_v) - set(prev_v)
    removed = set(prev_v) - set(cur_v)
    for control in added:
        spotlight_map[control].add((effect_name, parameter))
    for control in removed:
        spotlight_map[control].discard((effect_name, parameter))

def io_new_effect(effect_name, effect_type, x=20, y=30):
    # called by engine code when new effect is created
    # debug_print("from backend new effect", effect_name, effect_type)
    if effect_type in effect_prototypes:
        current_effects[effect_name] = {"x": x, "y": y, "effect_type": effect_type,
                "controls": {},
                }

def add_io():
    ingen_wrapper.add_midi_input("/main/midi_in", x=1192, y=(80 * 5))
    ingen_wrapper.add_midi_input2("/main/loop_midi_out", x=1192, y=(80 * 6))
    ingen_wrapper.add_midi_output("/main/loop_extra_midi", x=20, y=(80 * 3))
    ingen_wrapper.add_midi_output2("/main/midi_out", x=-20, y=(80 * 5))
    if current_pedal_model.name == "hector":
        for i in range(1,7):
            ingen_wrapper.add_input("/main/in_"+str(i), x=1192, y=(80*i))
        for i in range(1,9):
            ingen_wrapper.add_output("/main/out_"+str(i), x=-20, y=(80 * i))
    else:
        for i in range(1,5):
            ingen_wrapper.add_input("/main/in_"+str(i), x=1192, y=(80*i))
        for i in range(1,5):
            ingen_wrapper.add_output("/main/out_"+str(i), x=-20, y=(80 * i))
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
        self.is_locked = False
        self.loop_index = -1

knob_map = {"left": Encoder(s_speed=0.04), "right": Encoder(s_speed=0.8)}
spotlight_map = {"l": set(), "r": set(), "x": set(), "y": set()}

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

def next_preset():
    jump_to_preset(True, 1)

def previous_preset():
    jump_to_preset(True, -1)

def toggle_tuner():

    if is_loading == True:
        return
    preset_load_counter.value = preset_load_counter.value + 1

    if current_preset_filename == "/mnt/presets/beebo/Tuner.ingen":
        # if we've got a previous_preset, jump to it
        if previous_preset_filename != "":
            knobs.ui_load_preset_by_name("file://"+previous_preset_filename)
    else:
        knobs.ui_load_preset_by_name("file:///mnt/presets/beebo/Tuner.ingen")

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
            debug_print("got ui message", m)
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
                            current_effects[effect_name]["enabled"] = bool(float(value))
                        current_effects[effect_name]["controls"][parameter].value = float(value)
                        debug_print("send value to mcu", effect_name, parameter, value )
                        if not mcu_comms.verbs_initial_preset_loaded:
                            mcu_comms.send_value_to_mcu(effect_name, parameter, float(value))
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
                debug_print("got add", m)
                if (effect_name not in current_effects and (effect_type in inv_effect_type_map or effect_type in bare_ports)):
                    debug_print("adding ", m)
                    if effect_type == "http://polyeffects.com/lv2/polyfoot":
                        mapped_type = effect_name.rsplit("/", 1)[1].rstrip("123456789")
                        if mapped_type in effect_type_map:
                            from_backend_new_effect(effect_name, mapped_type, x, y, is_enabled)
                    elif effect_type in bare_ports:
                        if current_pedal_model.name == "hector":
                            from_backend_new_effect(effect_name, effect_type, x, y, is_enabled)
                        else:
                            try:
                                l_effect_num = int(effect_name.rsplit("/", 1)[1][-1])
                            except:
                                l_effect_num = 0
                            if l_effect_num < 5: # filter out Hector ports
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
                    current_effects[effect_name]["enabled"] = bool(is_enabled)
            elif m[0] == "pedalboard_loaded":
                subgraph, file_name = m[1:]
                # disable loading sign
                print ("pedalboard loaded", subgraph, file_name, current_sub_graph)
                if subgraph == current_sub_graph.rstrip("/"):
                    global is_loading
                    is_loading = False
                    done_loading_time = time.perf_counter()
                    # check if we've got MIDI IO, if not add them
                    print("### preset loaded in ", done_loading_time - preset_started_loading_time)
                    debug_print("checking if MIDI exists")
                    if not (current_sub_graph+"midi_in" in current_effects):
                        ingen_wrapper.add_midi_input(current_sub_graph+"midi_in", x=1192, y=(80 * 5))
                        # debug_print("adding MIDI")
                    if not (current_sub_graph+"midi_out" in current_effects):
                        ingen_wrapper.add_midi_output(current_sub_graph+"midi_out", x=-20, y=(80 * 5))
                    if current_pedal_model.name == "hector" and not (current_sub_graph+"out_5" in current_effects):
                        # add hector IO
                        for i in range(5,7):
                            ingen_wrapper.add_input(current_sub_graph+"in_"+str(i), x=1192, y=(80*i))
                        for i in range(5,9):
                            ingen_wrapper.add_output(current_sub_graph+"out_"+str(i), x=-20, y=(80 * i))

            elif m[0] == "dsp_load":
                max_load, mean_load, min_load = m[1:]
                dsp_load.rmin = min_load
                dsp_load.rmax = max_load
                dsp_load.value = mean_load + 0.25
            elif m[0] == "set_comment":
                description, subject = m[1:]
                preset_description.name = description
            elif m[0] == "looper_footswitch":
                footswitch, effect_name = m[1:]
                global looper_footswitch_assignments
                looper_footswitch_assignments = json.loads(footswitch)
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
                            elif effect_type in ["amp_rtneural", "amp_nam"]:
                                knobs.update_json(effect_name, urllib.parse.unquote(ir_file))
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
                        current_effects[effect_name]["enabled"] = bool(float(value))
                    current_effects[effect_name]["controls"][parameter].value = float(value)
                    mcu_comms.send_value_to_mcu(effect_name, parameter, float(value))
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["broadcast_ports"]):
                        current_effects[effect_name]["broadcast_ports"][parameter].value = float(value)
                        # print("updated ", effect_name, parameter, value)
                except ValueError:
                    pass
            elif m[0] == "midi_learn":
                # debug_print("got midi_learn in process_ui")
                effect_name_parameter, value = m[1:]
                effect_name, parameter = effect_name_parameter.rsplit("/", 1)
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
                        current_effects[effect_name]["controls"][parameter].cc = int(value)
                        # print("updated ", effect_name, parameter, value)
                except ValueError:
                    pass
            elif m[0] == "spotlight":
                effect_name_parameter, value = m[1:]
                # debug_print("got spotlight in process_ui", value)
                effect_name, parameter = effect_name_parameter.rsplit("/", 1)
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
                        if value != "0":
                            # we're spotlighted
                            if [effect_name, parameter, value] not in knobs.spotlight_entries:
                                knobs.spotlight_entries.append([effect_name, parameter, value])
                                spotlight_entries_changed(effect_name, parameter, value, '')
                        else:
                            # remove spotlight if found
                            l_spotlight_entries = [b for b in knobs.spotlight_entries if b[0:2] == [effect_name, parameter]]
                            if l_spotlight_entries != []:
                                spotlight_entry = l_spotlight_entries[0]
                                spotlight_entries_changed(spotlight_entry[0], spotlight_entry[1], '', spotlight_entry[2])
                                knobs.spotlight_entries.remove(spotlight_entry)
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
        available_effects[i] = sorted(a)

def change_pedal_model(name, initial=False):
    _name = "beebo" # override
    global inv_effect_type_map
    global effect_type_map
    global effect_prototypes
    effect_type_map = effect_type_maps[_name]
    effect_prototypes = effect_prototypes_models[_name]

    set_available_effects()
    accent_color_models = {"beebo": "#FFA0E0", "digit": "#FFA0E0", "hector": "#32D2BE"}
    accent_color.name = accent_color_models[name]

    inv_effect_type_map = {v:k for k, v in effect_type_map.items()}
    current_pedal_model.name = name
    load_preset_list()
    # jump_to_preset(False, 0, initial)

class ExceptionThread(threading.Thread):
    def __init__(self, *args, **kwargs):
        threading.Thread.__init__(self, *args, **kwargs)

    def run(self):
        try:
            if self._target:
                self._target(*self._args, **self._kwargs)
        except Exception:
            print(traceback.format_exc())
            # logging.error(traceback.format_exc())

cc_thread = None
def handle_MIDI_program_change():
    global cc_thread
    cc_thread = ExceptionThread(target=midi_pc_thread)
    cc_thread.start()

def midi_pc_thread():
    # This is pretty dodgy... but I don't want to depend on jack in the main process as it'll slow down startup
    # we need to wait here for ttymidi to be up
    # on program change, iterate over values, set values
    # same function from internal and external.
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
    while p.poll() is None and not EXIT_PROCESS[0]:
        l = p.stdout.readline() # This blocks until it receives a newline.
        # debug_print("got midi", l)
        if len(l) > 8 and l[6] == b'c'[0]: # 0xC0 is program change
            b = l.decode()
            ig, b1, b2 = b.split()
            channel = int("0x"+b1, 16) - 0xC0
            program = int("0x"+b2, 16)
            # debug_print("GOT midi change", channel, program, midi_channel.value)
            if channel == midi_channel.value:# - 1: # our channel
                # debug_print("####### channel == midi_channel.value", channel)
                # put this in the queue
                mcu_comms.load_verbs_preset(program % 56)
        elif PEDAL_TYPE == pedal_types.ample and len(l) > 12 and l[6] == b'b'[0]: # 0xB0 is CC
            b = l.decode()
            debug_print(f"####### b {b} split {b.split()} len l {len(l)}")
            ig, b1, b2, v = b.split()[:4]
            channel = int("0x"+b1, 16) - 0xB0
            cc = int("0x"+b2, 16)
            value = int("0x"+v, 16)
            # debug_print("GOT midi change", channel, program, midi_channel.value)
            if channel == midi_channel.value and cc == 18 :# - 1: # our channel and we're the enable CC
                debug_print(f"####### channel == midi_channel.value {channel} cc {cc} v {v} value {value} len l {len(l)}")
                # toggle enable
                mcu_comms.set_main_enable(value > 63)
    # When the subprocess terminates there might be unconsumed output 
    # that still needs to be processed.
    ignored = p.stdout.read()

if __name__ == "__main__":

    debug_print("in Main")

    # preset might not have been copied on an update, as file system might not have been supported
    # if not os.path.isfile("/mnt/presets/beebo/Empty.ingen/main.ttl") and not IS_REMOTE_TEST:
    #     # rsync
    #     command = "sudo rsync -a /to_nor_flash/ /nor_flash"
    #     ret_var = subprocess.call(command, shell=True)

    # if os.path.isfile("/mnt/presets/digit/Empty.ingen/main.ttl") and not IS_REMOTE_TEST:
    #     # first time running after merge update
    #     command = "mv -f /mnt/presets/digit/* /mnt/presets/beebo/;rm -rf /mnt/presets/digit/*"
    #     ret_var = subprocess.call(command, shell=True)
    #     get_meta_from_files(True)

    # Instantiate the Python object.
    knobs = Knobs()

    # read persistant state
    pedal_state = {}
    load_pedal_state()
    current_bpm = PolyValue("BPM", 120, 30, 250) # bit of a hack
    current_preset = PolyValue("Default Preset", 0, 0, 127)
    preset_load_counter = PolyValue("", 0, 0, 500000)
    current_preset_filename = ""
    previous_preset_filename = ""
    update_counter = PolyValue("", 0, 0, 500000)
    command_status = [PolyValue("", -1, -10, 100000), PolyValue("", -1, -10, 100000)]
    delay_num_bars = PolyValue("Num bars", 1, 1, 16)
    dsp_load = PolyValue("DSP Load", 0, 0, 0.3)
    foot_switch_qa = {"a":PolyValue("a", 0, 0, 1), "b":PolyValue("b", 0, 0, 1), "c":PolyValue("c", 0, 0, 1), "d":PolyValue("d", 0, 0, 1), "e":PolyValue("e", 0, 0, 1)}
    encoder_qa = {"left":PolyValue("a", 0, 0, 1), "right":PolyValue("b", 0, 0, 1)}
    connect_source_port = PolyValue("", 1, 1, 16) # for sharing what type the selected source is
    midi_channel = PolyValue("channel", pedal_state["midi_channel"], 0, 16)
    input_level = PolyValue("input level", pedal_state["input_level"], -80, 10)
    preset_description = PolyValue("tap to write description", 0, 0, 1)
    debug_print("### Input level is", input_level.value)
    knobs.set_input_level(pedal_state["input_level"], write=False)
    is_loading = PolyBool(False)
    preset_meta_data = {}
    favourites = {}
    mcu_comms.knobs = knobs

    available_effects = [list() for i in range(4)]
    set_available_effects()

    current_pedal_model = PolyValue(pedal_state["model"], 0, -1, 1)
    # accent_color = PolyValue("#8BB8E8", 0, -1, 1)
    accent_color = PolyValue("#FF75D0", 0, -1, 1)
    current_ip = PolyValue("", 0, -1, 1)

    time.sleep(3)
    debug_print("starting send thread")
    ingen_wrapper.start_send_thread()
    debug_print("starting recv thread")
    ingen_wrapper.start_recv_thread(ui_messages)

    # pedal_hardware.add_hardware_listeners()
    handle_MIDI_program_change()

    # qWarning("logging with qwarning")
    time.sleep(1)
    try:
        add_io()
    except Exception as e:
        debug_print("########## e1 is:", e)
        ex_type, ex_value, tb = sys.exc_info()
        error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
        debug_print("EXception is:", error)
        EXIT_PROCESS[0] = True
        sys.exit()

    sys._excepthook = sys.excepthook
    def exception_hook(exctype, value, tb):
        debug_print("except hook got a thing!")
        EXIT_PROCESS[0] = True
        traceback.print_exception(exctype, value, tb)
        sys._excepthook(exctype, value, tb)
        # sys.exit(1)
    sys.excepthook = exception_hook

    def signalHandler(sig, frame):
        if sig in (SIGINT, SIGTERM):
            # global EXIT_PROCESS
            EXIT_PROCESS[0] = True
            ingen_wrapper._FINISH = True
            ingen_wrapper.ingen._FINISH = True
            mcu_comms.EXIT_THREADS = True
            debug_print("finish set in sig handler")
            try:
                ingen_wrapper.ingen.sock.shutdown(socket.SHUT_RDWR)
                ingen_wrapper.ingen.sock.close()
            except Exception as e:
                ex_type, ex_value, tb = sys.exc_info()
                error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
                print("tried to close sock EXception is:", error)
    signal(SIGINT,  signalHandler)
    signal(SIGTERM, signalHandler)
    initial_preset = False
    debug_print("starting UI")
    time.sleep(0.3)
    change_pedal_model("beebo")
    time.sleep(0.5)
    ingen_wrapper.get_state("/main")
    # load_preset("file:///home/pleb/Verbs2.ingen/main.ttl", True)
    debug_print("attempting load preset")
    time.sleep(0.5)
    # mcu_comms.load_verbs_preset(0)
    # ingen_wrapper._FINISH = True
    update_dsp_usage_count = 200
    type_v = 1 if PEDAL_TYPE == pedal_types.ample else 0
    mcu_comms.send_loading_progress_to_mcu(type_v)
    while not EXIT_PROCESS[0]:
        # debug_print("processing events")
        try:
            # debug_print("processing ui messages")
            process_ui_messages()
            mcu_comms.process_from_mcu()
            mcu_comms.send_to_mcu()
        except Exception as e:
            ex_type, ex_value, tb = sys.exc_info()
            error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
            print("EXception is:", error)
            try:
                ingen_wrapper.ingen.sock.shutdown(socket.SHUT_RDWR)
            except:
                pass
            sys.exit()
        sleep(0.01)

    debug_print("EXIT PROCESS")
    try:
        ingen_wrapper.ingen.sock.shutdown(socket.SHUT_RDWR)
    except:
        pass
    ingen_wrapper.s_thread.join()
    debug_print("s_thread exited")
    mcu_comms.EXIT_THREADS = True
    debug_print("mcu_thread exited")
    ingen_wrapper.r_thread.join()
    debug_print("r_thread exited")
    sys.exit()
    debug_print("should not get past exit")



