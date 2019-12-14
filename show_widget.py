import sys, time, json, os.path, os, subprocess, queue, threading, traceback
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit
from collections import OrderedDict
# import random
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal, QTimer, QThreadPool, QRunnable
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtGui import QIcon
# # compiled QML files, compile with pyside2-rcc
# import qml.qml

sys._excepthook = sys.excepthook
def exception_hook(exctype, value, traceback):
    sys._excepthook(exctype, value, traceback)
    sys.exit(1)
sys.excepthook = exception_hook

os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
import icons.icons
# #, imagine_assets
import resource_rc

import patch_bay_model
import ingen_wrapper

worker_pool = QThreadPool()
EXIT_PROCESS = [False]
ui_messages = queue.Queue()

current_source_port = None
# current_effects = OrderedDict()
current_effects = {}
# current_effects["delay1"] = {"x": 20, "y": 30, "effect_type": "delay", "controls": {}, "highlight": False}
# current_effects["delay2"] = {"x": 250, "y": 290, "effect_type": "delay", "controls": {}, "highlight": False}
port_connections = {} # key is port, value is list of ports

context = None

preset_list = []
try:
    with open("/pedal_state/preset_list.json") as f:
        preset_list = json.load(f)
except:
    preset_list = ["Akg eq ed", "Back at u"]
preset_list_model = QStringListModel(preset_list)

patch_bay_model.local_effects = current_effects
    # effect = {"parameters", "inputs", "outputs", "effect_type", "id", "x", "y"}
effect_prototypes ={
        "input": {"inputs": {},
        "outputs": {"out": "AudioPort"},
        "controls": {}},
        "output": {"inputs": {"in": "AudioPort"},
        "outputs": {},
        "controls": {}},
        "delay": {"inputs": {"in0": "AudioPort"},
        "outputs": {"out0": "AudioPort"},
        "controls": {"BPM_0" : ["BPM_0", 120.000000, 30.000000, 300.000000],
            "Delay_1" : ["Time", 0.500000, 0.001000, 4.000000],
            "Warp_2" : ["Warp", 0.000000, -1.000000, 1.000000],
            "DelayT60_3" : ["Glide", 0.500000, 0.000000, 100.000000],
            "Feedback_4" : ["Feedback", 0.300000, 0.000000, 1.000000],
            "Amp_5" : ["Level", 0.500000, 0.000000, 1.000000],
            "FeedbackSm_6" : ["Tone", 0.000000, 0.000000, 1.000000],
            "EnableEcho_7" : ["EnableEcho_7", 1.000000, 0.000000, 1.000000]}
        },
        # "mixer":  {"inputs": {"in0": "AudioPort"},
        # "outputs": {"out0": "AudioPort"},
        # "controls":{"mix_1_1": ["mix 1,1", 1, 0, 1], "mix_1_2": ["mix 1,2", 0, 0, 1],
        #     "mix_1_3": ["mix 1,3", 0, 0, 1],"mix_1_4": ["mix 1,4", 0, 0, 1],
        #     "mix_2_1": ["mix 2,1", 0, 0, 1],"mix_2_2": ["mix 2,2", 1, 0, 1],
        #     "mix_2_3": ["mix 2,3", 0, 0, 1],"mix_2_4": ["mix 2,4", 0, 0, 1],
        #     "mix_3_1": ["mix 3,1", 0, 0, 1],"mix_3_2": ["mix 3,2", 0, 0, 1],
        #     "mix_3_3": ["mix 3,3", 1, 0, 1],"mix_3_4": ["mix 3,4", 0, 0, 1],
        #     "mix_4_1": ["mix 4,1", 0, 0, 1],"mix_4_2": ["mix 4,2", 0, 0, 1],
        #     "mix_4_3": ["mix 4,3", 0, 0, 1],"mix_4_4": ["mix 4,4", 1, 0, 1]
        #     },
        "warmth": {"inputs": {"input": "AudioPort"},
                "outputs": {"output": "AudioPort"},
            "controls":{"drive": ["drive", 5, 0, 10], "blend": ["tape vs tube", 10, -10, 10]},
            },
        "lfo": {'inputs': {'reset': 'CVPort'},
            'outputs': {'output': 'CVPort'},
            'controls': {'tempo': ['Tempo', 120.0, 1.0, 320.0],
                'tempoMultiplier': ['Tempo Multiplier', 1.0, 0.0078125, 32.0],
                'waveForm': ['Wave Form', 0, 0, 5], 'phi0': ['Phi0', 0, 0.0, 6.28]}},
        "env_follower": {'controls': {'ATIME': ['Attack Time', 0.01, 0.001, 15.0],
              'CDIRECTION': ['Invert', 0, 0, 1],
              'CMAXV': ['Maximum Value', 1.0, 0.0, 1.0],
              'CMINV': ['Minimum Value', 0.0, 0.0, 1.0],
              'DTIME': ['Decay Time', 1.0, 0.001, 30.0],
              'PEAKRMS': ['Peak/RMS', 0.0, 0.0, 1.0],
              'SATURATION': ['Saturation', 1.0, 0.0, 2.0],
              'THRESHOLD': ['Threshold', 0.0, 0.0, 1.0]},
              'inputs': {'INPUT': 'AudioPort'},
              'outputs': {#'CTL_OUT': 'ControlPort',
                  'CV_OUT': 'CVPort'}},
        "mono_reverb": {"inputs": {"in": "AudioPort"},
                "outputs": {"out": "AudioPort"},
                "controls":{"gain": ["gain", 0, -24, 24], "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
            },
        "stereo_reverb": {"inputs": {"in": "AudioPort"},
            "outputs": {"out_1": "AudioPort", "out_2": "AudioPort"},
                "controls":{"gain": ["gain", 0, -24, 24], "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
            },
        "true_stereo_reverb": {"inputs": {"in_1": "AudioPort", "in_2": "AudioPort"},
            "outputs": {"out_1": "AudioPort", "out_2": "AudioPort"},
                "controls":{"gain": ["gain", 0, -24, 24], "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
            },
        "mono_cab": {"inputs": {"in": "AudioPort"},
                "outputs": {"out": "AudioPort"},
                "controls":{"gain": ["gain", 0, -24, 24], "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
            },
        "stereo_cab": {"inputs": {"in": "AudioPort"},
            "outputs": {"out_1": "AudioPort", "out_2": "AudioPort"},
                "controls":{"gain": ["gain", 0, -24, 24], "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
            },
        "true_stereo_cab": {"inputs": {"in_1": "AudioPort", "in_2": "AudioPort"},
            "outputs": {"out_1": "AudioPort", "out_2": "AudioPort"},
                "controls":{"gain": ["gain", 0, -24, 24], "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
            },
        # "filter1": {"freq": ["cutoff", 440, 20, 15000, "log"], "res": ["resonance", 0, 0, 0.8]},
        "saturator": {"inputs": {"input": "AudioPort"},
            "outputs": {"output": "AudioPort"},
            "controls":{"Pregain": ["pre gain", 0, -90, 20], "Postgain": ["post gain", 0, -90, 20]},
            },
        "reverse": {"inputs": {"input": "AudioPort"},
            "outputs": {"output": "AudioPort"},
            "controls":{"fragment": ["fragment", 1000, 100, 1600],
                "wet": ["wet", 0, -90, 20],
                "dry": ["dry", 0, -90, 20]},
            },
        "mono_EQ": {"inputs": {"In": "AudioPort"},
            "outputs": {"Out": "AudioPort"},
            "controls": {
                "enable": ["Enable", 1.000000, 0.000000, 1.0],
                "gain": ["Gain", 0.000000, -18.000000, 18.000000],
                "HighPass": ["Highpass", 0.000000, 0.000000, 1.000000],
                "HPfreq": ["Highpass Frequency", 20.000000, 5.000000, 1250.000000],
                "HPQ": ["HighPass Resonance", 0.700000, 0.000000, 1.400000],
                "LowPass": ["Lowpass", 0.000000, 0.000000, 1.000000],
                "LPfreq": ["Lowpass Frequency", 20000.000000, 500.000000, 20000.000000],
                "LPQ": ["LowPass Resonance", 1.000000, 0.000000, 1.400000],
                "LSsec": ["Lowshelf", 1.000000, 0.000000, 1.000000],
                "LSfreq": ["Lowshelf Frequency", 80.000000, 25.000000, 400.000000],
                "LSq": ["Lowshelf Bandwidth", 1.000000, 0.062500, 4.000000],
                "LSgain": ["Lowshelf Gain", 0.000000, -18.000000, 18.000000],
                "sec1": ["Section 1", 1.000000, 0.000000, 1.000000],
                "freq1": ["Frequency 1", 160.000000, 20.000000, 2000.000000],
                "q1": ["Bandwidth 1", 0.600000, 0.062500, 4.000000],
                "gain1": ["Gain 1", 0.000000, -18.000000, 18.000000],
                "sec2": ["Section 2", 1.000000, 0.000000, 1.000000],
                "freq2": ["Frequency 2", 397.000000, 40.000000, 4000.000000],
                "q2": ["Bandwidth 2", 0.600000, 0.062500, 4.000000],
                "gain2": ["Gain 2", 0.000000, -18.000000, 18.000000],
                "sec3": ["Section 3", 1.000000, 0.000000, 1.000000],
                "freq3": ["Frequency 3", 1250.000000, 100.000000, 10000.000000],
                "q3": ["Bandwidth 3", 0.600000, 0.062500, 4.000000],
                "gain3": ["Gain 3", 0.000000, -18.000000, 18.000000],
                "sec4": ["Section 4", 1.000000, 0.000000, 1.000000],
                "freq4": ["Frequency 4", 2500.000000, 200.000000, 20000.000000],
                "q4": ["Bandwidth 4", 0.600000, 0.062500, 4.000000],
                "gain4": ["Gain 4", 0.000000, -18.000000, 18.000000],
                "HSsec": ["Highshelf", 1.000000, 0.000000, 1.000000],
                "HSfreq": ["Highshelf Frequency", 8000.000000, 1000.000000, 16000.000000],
                "HSq": ["Highshelf Bandwidth", 1.000000, 0.062500, 4.000000],
                "HSgain": ["Highshelf Gain", 0.000000, -18.000000, 18.000000]}
            },
        "stereo_EQ": {"inputs": {"inR": "AudioPort", "inL": "AudioPort"},
            "outputs": {"outR": "AudioPort", "outL": "AudioPort"},
            "controls": {
                "enable": ["Enable", 1.000000, 0.000000, 1.0],
                "gain": ["Gain", 0.000000, -18.000000, 18.000000],
                "HighPass": ["Highpass", 0.000000, 0.000000, 1.000000],
                "HPfreq": ["Highpass Frequency", 20.000000, 5.000000, 1250.000000],
                "HPQ": ["HighPass Resonance", 0.700000, 0.000000, 1.400000],
                "LowPass": ["Lowpass", 0.000000, 0.000000, 1.000000],
                "LPfreq": ["Lowpass Frequency", 20000.000000, 500.000000, 20000.000000],
                "LPQ": ["LowPass Resonance", 1.000000, 0.000000, 1.400000],
                "LSsec": ["Lowshelf", 1.000000, 0.000000, 1.000000],
                "LSfreq": ["Lowshelf Frequency", 80.000000, 25.000000, 400.000000],
                "LSq": ["Lowshelf Bandwidth", 1.000000, 0.062500, 4.000000],
                "LSgain": ["Lowshelf Gain", 0.000000, -18.000000, 18.000000],
                "sec1": ["Section 1", 1.000000, 0.000000, 1.000000],
                "freq1": ["Frequency 1", 160.000000, 20.000000, 2000.000000],
                "q1": ["Bandwidth 1", 0.600000, 0.062500, 4.000000],
                "gain1": ["Gain 1", 0.000000, -18.000000, 18.000000],
                "sec2": ["Section 2", 1.000000, 0.000000, 1.000000],
                "freq2": ["Frequency 2", 397.000000, 40.000000, 4000.000000],
                "q2": ["Bandwidth 2", 0.600000, 0.062500, 4.000000],
                "gain2": ["Gain 2", 0.000000, -18.000000, 18.000000],
                "sec3": ["Section 3", 1.000000, 0.000000, 1.000000],
                "freq3": ["Frequency 3", 1250.000000, 100.000000, 10000.000000],
                "q3": ["Bandwidth 3", 0.600000, 0.062500, 4.000000],
                "gain3": ["Gain 3", 0.000000, -18.000000, 18.000000],
                "sec4": ["Section 4", 1.000000, 0.000000, 1.000000],
                "freq4": ["Frequency 4", 2500.000000, 200.000000, 20000.000000],
                "q4": ["Bandwidth 4", 0.600000, 0.062500, 4.000000],
                "gain4": ["Gain 4", 0.000000, -18.000000, 18.000000],
                "HSsec": ["Highshelf", 1.000000, 0.000000, 1.000000],
                "HSfreq": ["Highshelf Frequency", 8000.000000, 1000.000000, 16000.000000],
                "HSq": ["Highshelf Bandwidth", 1.000000, 0.062500, 4.000000],
                "HSgain": ["Highshelf Gain", 0.000000, -18.000000, 18.000000]}
            }
    }

def clamp(v, min_value, max_value):
    return max(min(v, max_value), min_value)

def insert_row(model, row):
    j = len(model.stringList())
    model.insertRows(j, 1)
    model.setData(model.index(j), row)

def remove_row(model, row):
    i = model.stringList().index(row)
    model.removeRows(i, 1)

class MyEmitter(QObject):
    # setting up custom signal
    done = Signal(int)

class MyWorker(QRunnable):

    def __init__(self, command):
        super(MyWorker, self).__init__()
        self.command = command
        self.emitter = MyEmitter()

    def run(self):
        # run subprocesses, grab output
        ret_var = subprocess.call(self.command, shell=True)
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
    def __init__(self, startname="", startval=0, startmin=0, startmax=1, curve_type="lin"):
        QObject.__init__(self)
        self.nameval = startname
        self.valueval = startval
        self.rminval = startmin
        self.rmax = startmax
        self.assigned_cc = None

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        # clamp values
        self.valueval = clamp(val, self.rmin, self.rmax)
        self.value_changed.emit()
        # print("setting value", val)

    @Signal
    def value_changed(self):
        pass

    value = Property(float, readValue, setValue, notify=value_changed)

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
    p_list = preset_list_model.stringList()
    if is_inc:
        current_preset.value = (current_preset.value + num) % len(p_list)
    else:
        if num < len(p_list):
            current_preset.value = num
        else:
            return
    # load_preset("/presets/"+p_list[current_preset.value]+".json")
    print("load preset here") # TODO

def write_pedal_state():
    with open("/pedal_state/state.json", "w") as f:
        json.dump(pedal_state, f)

selected_effect_ports = QStringListModel()
selected_effect_ports.setStringList(["val1", "val2"])
seq_num = 10

def from_backend_new_effect(effect_name, effect_type, x=20, y=30):
    # called by engine code when new effect is created
    # print("from backend new effect", effect_name, effect_type)
    if effect_type in effect_prototypes:
        if patch_bay_model.patch_bay_singleton is not None:
            patch_bay_model.patch_bay_singleton.startInsert()

        current_effects[effect_name] = {"x": x, "y": y, "effect_type": effect_type,
                "controls": {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["controls"].items()},
                "highlight": False, "enabled": PolyBool(True)}
        if patch_bay_model.patch_bay_singleton is not None:
            patch_bay_model.patch_bay_singleton.endInsert()
        # insert in context or model? 
        context.setContextProperty("currentEffects", current_effects) # might be slow
    else:
        print("### backend tried to add an unknown effect!")



def from_backend_remove_effect(effect_name):
    # called by engine code when effect is removed
    if patch_bay_model.patch_bay_singleton is not None:
        patch_bay_model.patch_bay_singleton.startRemove(effect_name)
    current_effects.pop(effect_name)
    if patch_bay_model.patch_bay_singleton is not None:
        patch_bay_model.patch_bay_singleton.endRemove()

def from_backend_add_connection(head, tail):
    print("head ", head, "tail", tail)
    current_source_port = head[6:]
    if len(current_source_port.split("/")) == 1:
        s_effect = current_source_port
        print("## s_effect", s_effect)
        if s_effect not in current_effects:
            return
        s_effect_type = current_effects[s_effect]["effect_type"]
        if s_effect_type == "output":
            s_port = "input"
        elif s_effect_type == "input":
            s_port = "output"
        current_source_port = s_effect + "/" + s_port
        print("## current_source_port", current_source_port)

    effect_id_port_name = tail[6:].split("/")
    if len(effect_id_port_name) == 1:
        t_effect = effect_id_port_name[0]
        if t_effect not in current_effects:
            return
        t_effect_type = current_effects[t_effect]["effect_type"]
        if t_effect_type == "output":
            t_port = "input"
        elif t_effect_type == "input":
            t_port = "output"
    else:
        t_effect, t_port = effect_id_port_name
        if t_effect not in current_effects:
            return

    if current_source_port not in port_connections:
        port_connections[current_source_port] = []
    if [t_effect, t_port] not in port_connections[current_source_port]:
        port_connections[current_source_port].append([t_effect, t_port])

    print("port_connections is", port_connections)
    # global context
    context.setContextProperty("portConnections", port_connections)
    update_counter.value+=1


def from_backend_disconnect(head, tail):
    print("head ", head, "tail", tail)
    current_source_port = head[6:]
    if len(current_source_port.split("/")) == 1:
        s_effect = current_source_port
        s_effect_type = current_effects[s_effect]["effect_type"]
        if s_effect_type == "output":
            s_port = "input"
        elif s_effect_type == "input":
            s_port = "output"
        current_source_port = s_effect + "/" + s_port

    effect_id_port_name = tail[6:].split("/")
    if len(effect_id_port_name) == 1:
        t_effect = effect_id_port_name[0]
        t_effect_type = current_effects[t_effect]["effect_type"]
        if t_effect_type == "output":
            t_port = "input"
        elif t_effect_type == "input":
            t_port = "output"
    else:
        t_effect, t_port = effect_id_port_name

    print("before port_connections is", port_connections)
    if current_source_port in port_connections and [t_effect, t_port] in port_connections[current_source_port]:
        port_connections[current_source_port].pop(port_connections[current_source_port].index([t_effect, t_port]))
    print("after port_connections is", port_connections)
    # global context
    context.setContextProperty("portConnections", port_connections)
    update_counter.value+=1

class Knobs(QObject):
    @Slot(bool, str, str)
    def set_current_port(self, is_source, effect_id, port_name):
        print("port name is", port_name)
        # if source highlight targets
        if is_source:
            # set current source port
            # effect_id, port_name
            # highlight effects given source port
            global current_source_port
            current_source_port = "/".join((effect_id, port_name))
            connect_source_port.name = current_source_port
            out_port_type = effect_prototypes[current_effects[effect_id]["effect_type"]]["outputs"][port_name]
            for id, effect in current_effects.items():
                effect["highlight"] = False
                if id != effect_id:
                    if out_port_type in ["CVPort", "ControlPort"]: # looking for controls
                        if len(current_effects[id]["controls"]) > 0:
                            effect["highlight"] = True
                    else:
                        for input_port, style in effect_prototypes[effect["effect_type"]]["inputs"].items():
                            if style == out_port_type:
                                # highlight and break
                                effect["highlight"] = True
                                break
        else:
            # if target disable highlight
            for id, effect in current_effects.items():
                effect["highlight"] = False
            # add connection between source and target
            # or just wait until it's automatically created from engine? 
            # if current_source_port not in port_connections:
            #     port_connections[current_source_port] = []
            # if [effect_id, port_name] not in port_connections[current_source_port]:
            #     port_connections[current_source_port].append([effect_id, port_name])


            s_effect, s_port = current_source_port.split("/")
            s_effect_type = current_effects[s_effect]["effect_type"]
            t_effect_type = current_effects[effect_id]["effect_type"]
            if t_effect_type == "output" or t_effect_type == "input":
                if s_effect_type == "output" or s_effect_type == "input":
                    ingen_wrapper.connect_port("/main/"+s_effect, "/main/"+effect_id)
                else:
                    ingen_wrapper.connect_port("/main/"+current_source_port, "/main/"+effect_id)
            else:
                if s_effect_type == "output" or s_effect_type == "input":
                    ingen_wrapper.connect_port("/main/"+s_effect, "/main/"+effect_id+"/"+port_name)
                else:
                    ingen_wrapper.connect_port("/main/"+current_source_port, "/main/"+effect_id+"/"+port_name)


            # if [effect_id, port_name] not in inv_port_connections:
            #     inv_port_connections[[effect_id, port_name]] = []
            # if current_source_port not in inv_port_connections[[effect_id, port_name]]:
            #     inv_port_connections[[effect_id, port_name]].append(current_source_port)

            # print("port_connections is", port_connections)
            # global context
            # context.setContextProperty("portConnections", port_connections)


    @Slot(bool, str)
    def select_effect(self, is_source, effect_id):
        effect_type = current_effects[effect_id]["effect_type"]
        print("selecting effect type", effect_type)
        if is_source:
            selected_effect_ports.setStringList(list(effect_prototypes[effect_type]["outputs"].keys()))
        else:
            # source_port_pair = connectSourcePort.split("/")
            # var source_port_type = effectPrototypes[currentEffects[source_port_pair[0]]["effect_type"]]["outputs"][source_port_pair[1]]
            s_effect_id, s_port = connect_source_port.name.split("/")
            source_port_type = effect_prototypes[current_effects[s_effect_id]["effect_type"]]["outputs"][s_port]
            if source_port_type == "AudioPort":
                selected_effect_ports.setStringList(list(effect_prototypes[effect_type]["inputs"].keys()))
            else:
                selected_effect_ports.setStringList(list(effect_prototypes[effect_type]["controls"].keys()))

    @Slot(str)
    def list_connected(self, effect_id):
        ports = []
        for source_port, connected in port_connections.items():
            s_effect, s_port = source_port.split("/")
            # connections where we are target
            for c_effect, c_port in connected:
                if c_effect == effect_id or s_effect == effect_id:
                    ports.append(s_effect+"/"+s_port+"---"+c_effect+"/"+c_port)
        print("connected ports:", ports)
        selected_effect_ports.setStringList(ports)

    @Slot(str)
    def disconnect_port(self, port_pair):
        target_pair, source_pair = port_pair.split("---")
        t_effect, t_port = target_pair.split("/")
        print("### disconnect, port pair", port_pair)

        s_effect, s_port = source_pair.split("/")
        s_effect_type = current_effects[s_effect]["effect_type"]
        t_effect_type = current_effects[t_effect]["effect_type"]
        if t_effect_type == "output" or t_effect_type == "input":
            if s_effect_type == "output" or s_effect_type == "input":
                ingen_wrapper.disconnect_port("/main/"+s_effect, "/main/"+t_effect)
            else:
                ingen_wrapper.disconnect_port("/main/"+source_pair, "/main/"+t_effect)
        else:
            if s_effect_type == "output" or s_effect_type == "input":
                ingen_wrapper.disconnect_port("/main/"+s_effect, "/main/"+target_pair)
            else:
                ingen_wrapper.disconnect_port("/main/"+source_pair, "/main/"+target_pair)

    @Slot(str)
    def add_new_effect(self, effect_type):
        # calls backend to add effect
        # TODO actually call backend.
        global seq_num
        seq_num = seq_num + 1
        print("add new effect", effect_type)
        # if there's existing effects of this type, increment the ID
        effect_name = effect_type+str(1)
        for i in range(1, 1000):
            if effect_type+str(i) not in current_effects:
                effect_name = effect_type+str(i)
                break
        ingen_wrapper.add_plugin(effect_name, effect_type_map[effect_type])
        # from_backend_new_effect(effect_name, effect_type)


    @Slot(str, bool)
    def set_bypass(self, effect_name, is_active):
        ingen_wrapper.set_bypass(effect_name, is_active)

    @Slot(str, int, int)
    def move_effect(self, effect_name, x, y):
        current_effects[effect_name]["x"] = x
        current_effects[effect_name]["y"] = y
        ingen_wrapper.set_plugin_position(effect_name, x, y)

    @Slot(str)
    def remove_effect(self, effect_id):
        # calls backend to remove effect
        # TODO actually call backend.
        print("remove effect", effect_id)
        ingen_wrapper.remove_plugin("/main/"+effect_id)
        # from_backend_remove_effect(effect_id)

    @Slot(str, str, 'double')
    def ui_knob_change(self, effect_name, parameter, value):
        # print(x, y, z)
        if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
            current_effects[effect_name]["controls"][parameter].value = value
            # send_core_message("knob_change", (effect_name, parameter, value))
            ingen_wrapper.set_parameter_value("/main/"+effect_name+"/"+parameter, value)
        else:
            print("effect not found")

    @Slot(str, str)
    def update_ir(self, effect_id, ir_file):
        is_cab = True
        effect_type = current_effects[effect_id]["effect_type"]
        if effect_type in ["mono_reverb", "stereo_reverb", "true_stereo_reverb"]:
            is_cab = False
        ingen_wrapper.set_file(effect_id, ir_file, is_cab)

    @Slot(str)
    def ui_load_preset_by_name(self, preset_file):
        # print("loading", preset_file)
        outfile = preset_file[7:] # strip file:// prefix
        load_preset(outfile)
        update_counter.value+=1

    @Slot()
    def ui_copy_irs(self):
        # print("copy irs from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """cd /media/reverbs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/audio/reverbs --parents;
        cd /media/cabs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/audio/cabs --parents"""
        # copy all wavs in /usb/reverbs and /usr/cabs to /audio/reverbs and /audio/cabs
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def import_presets(self):
        # print("copy presets from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """cd /media/presets; find . -iname "*.json" -type f -print0 | xargs -0 cp --target-directory=/presets --parents"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def export_presets(self):
        # print("copy presets to USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """cd /presets; mkdir -p /media/presets; find . -iname "*.json" -type f -print0 | xargs -0 cp --target-directory=/media/presets --parents;sudo umount /media"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def copy_logs(self):
        # print("copy presets to USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """mkdir -p /media/logs; sudo cp /var/log/syslog /media/logs/;sudo umount /media"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def ui_update_firmware(self):
        # print("Updating firmware")
        # dpkg the debs in the folder
        command = """sudo dpkg -i /media/*.deb"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot(int)
    def set_input_level(self, level, write=True):
        command = "amixer -- sset ADC1 "+str(level)+"db"""
        command_status[0].value = subprocess.call(command, shell=True)
        if write:
            pedal_state["input_level"] = level
            write_pedal_state()

    @Slot(int)
    def set_preset_list_length(self, v):
        if v > len(preset_list_model.stringList()):
            # print("inserting new row in preset list", v)
            insert_row(preset_list_model, "Default Preset")
        else:
            # print("removing row in preset list", v)
            preset_list_model.removeRows(v, 1)

    @Slot(int, str)
    def map_preset(self, v, name):
        current_name = name[16:-5] # strip file://presets/ prefix
        preset_list_model.setData(preset_list_model.index(v), current_name)

    @Slot()
    def save_preset_list(self):
        with open("/pedal_state/preset_list.json", "w") as f:
            json.dump(preset_list_model.stringList(), f)

    @Slot(int)
    def on_worker_done(self, ret_var):
        # print("updating UI")
        command_status[0].value = ret_var

    def launch_subprocess(self, command):
        # print("launch_threadpool")
        worker = MyWorker(command)
        worker.emitter.done.connect(self.on_worker_done)
        worker_pool.start(worker)


def io_new_effect(effect_name, effect_type, x=20, y=30):
    # called by engine code when new effect is created
    # print("from backend new effect", effect_name, effect_type)
    if effect_type in effect_prototypes:
        current_effects[effect_name] = {"x": x, "y": y, "effect_type": effect_type,
                "controls": {},
                "highlight": False}

def add_io():
    # if patch_bay_model.patch_bay_singleton is not None:
    #     patch_bay_model.patch_bay_singleton.startInsert()
    for i in range(1,5):
        ingen_wrapper.add_input("in_"+str(i), x=1192, y=(80*i))
        # io_new_effect("input"+str(i), "input", x=1200, y=(80 * i))
        from_backend_new_effect("in_"+str(i), "input", x=1192, y=(80 * i))
    for i in range(1,5):
        ingen_wrapper.add_output("out_"+str(i), x=-20, y=(80 * i))
        # io_new_effect("output"+str(i), "output", x=50, y=(80 * i))
        from_backend_new_effect("out_"+str(i), "output", x=-20, y=(80 * i))
    # if patch_bay_model.patch_bay_singleton is not None:
    #     patch_bay_model.patch_bay_singleton.endInsert()
    # context.setContextProperty("currentEffects", current_effects) # might be slow

def process_ui_messages():
    # pop from queue
    try:
        while not EXIT_PROCESS[0]:
            m = ui_messages.get(block=False)
            print("got ui message", m)
            if m[0] == "value_change":
                # print("got value change in process_ui")
                effect_name_parameter, value = m[1:]
                effect_name, parameter = effect_name_parameter.split("/")
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
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
                effect_name, effect_type, x, y = m[1:5]
                print("got add", m)
                if (effect_name not in current_effects and effect_type in inv_effect_type_map):
                    print("adding ", m)
                    from_backend_new_effect(effect_name, inv_effect_type_map[effect_type], x, y)
            elif m[0] == "remove_plugin":
                effect_name = m[1]
                if (effect_name in current_effects):
                    from_backend_remove_effect(effect_name)
            elif m[0] == "enabled_change":
                effect_name, is_enabled = m[1:]
                # print("enabled changed ", m)
                if (effect_name in current_effects):
                    # print("adding ", m)
                    current_effects[effect_name]["enabled"].value = bool(is_enabled)
            elif m[0] == "add_port":
                pass
            elif m[0] == "remove_port":
                pass
            elif m[0] == "exit":
                # global EXIT_PROCESS
                EXIT_PROCESS[0] = True
    except queue.Empty:
        pass

effect_type_map = { "delay": "http://polyeffects.com/lv2/digit_delay",
        "mono_reverb": "http://polyeffects.com/lv2/polyconvo#Mono",
        "stereo_reverb": "http://polyeffects.com/lv2/polyconvo#MonoToStereo",
        "true_stereo_reverb": "http://polyeffects.com/lv2/polyconvo#Stereo",
        "mono_cab": "http://gareus.org/oss/lv2/convoLV2#Mono",
        "stereo_cab": "http://gareus.org/oss/lv2/convoLV2#MonoToStereo",
        "true_stereo_cab": "http://gareus.org/oss/lv2/convoLV2#Stereo",
        "mixer": "http://gareus.org/oss/lv2/matrixmixer#i4o4",
        "warmth": "http://moddevices.com/plugins/tap/tubewarmth",
        "reverse": "http://moddevices.com/plugins/tap/reflector",
        "saturator": "http://moddevices.com/plugins/tap/sigmoid",
        "mono_EQ": "http://gareus.org/oss/lv2/fil4#mono",
        "stereo_EQ": "http://gareus.org/oss/lv2/fil4#stereo",
        "filter": "http://drobilla.net/plugins/fomp/mvclpf1",
        "lfo": "http://avwlv2.sourceforge.net/plugins/avw/lfo_tempo",
        "env_follower": "http://ssj71.github.io/infamousPlugins/plugs.html#envfollowerCV",
        }

inv_effect_type_map = {v:k for k, v in effect_type_map.items()}

if __name__ == "__main__":

    print("in Main")
    app = QGuiApplication(sys.argv)
    QIcon.setThemeName("digit")
    # Instantiate the Python object.
    knobs = Knobs()

    update_counter = PolyValue("update counter", 0, 0, 500000)
    # read persistant state
    # pedal_state = {}
    # with open("/pedal_state/state.json") as f:
    #     pedal_state = json.load(f)
    current_bpm = PolyValue("BPM", 120, 30, 250) # bit of a hack
    current_preset = PolyValue("Default Preset", 0, 0, 127)
    update_counter = PolyValue("update counter", 0, 0, 500000)
    command_status = [PolyValue("command status", -1, -10, 100000), PolyValue("command status", -1, -10, 100000)]
    delay_num_bars = PolyValue("Num bars", 1, 1, 16)
    connect_source_port = PolyValue("", 1, 1, 16) # for sharing what type the selected source is
    # midi_channel = PolyValue("channel", pedal_state["midi_channel"], 1, 16)
    # input_level = PolyValue("input level", pedal_state["input_level"], -80, 10)
    # knobs.set_input_level(pedal_state["input_level"], write=False)

    available_effects = QStringListModel()
    available_effects.setStringList(list(effect_type_map.keys()))
    engine = QQmlApplicationEngine()

    qmlRegisterType(patch_bay_model.PatchBayModel, 'Poly', 1, 0, 'PatchBayModel')
    # Expose the object to QML.
    # global context
    context = engine.rootContext()
    context.setContextProperty("knobs", knobs)
    context.setContextProperty("available_effects", available_effects)
    context.setContextProperty("selectedEffectPorts", selected_effect_ports)
    context.setContextProperty("portConnections", port_connections)
    context.setContextProperty("effectPrototypes", effect_prototypes)
    context.setContextProperty("updateCounter", update_counter)
    context.setContextProperty("currentBPM", current_bpm)
    # context.setContextProperty("pluginState", plugin_state)
    context.setContextProperty("currentPreset", current_preset)
    context.setContextProperty("commandStatus", command_status)
    context.setContextProperty("delayNumBars", delay_num_bars)
    context.setContextProperty("connectSourcePort", connect_source_port)
    # context.setContextProperty("midiChannel", midi_channel)
    # context.setContextProperty("isLoading", is_loading)
    # # context.setContextProperty("inputLevel", input_level)
    # context.setContextProperty("presetList", preset_list_model)
    print("starting recv thread")
    engine.load(QUrl("qml/TestWrapper.qml")) # XXX 
    ingen_wrapper.start_recv_thread(ui_messages)
    print("starting send thread")
    ingen_wrapper.start_send_thread()
    try:
        add_io()
    except Exception as e:
        print("########## e is:", e)
        ex_type, ex_value, tb = sys.exc_info()
        error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
        print("EXception is:", error)
        sys.exit()

    sys._excepthook = sys.excepthook
    def exception_hook(exctype, value, traceback):
        print("except hook got a thing!")
        sys._excepthook(exctype, value, traceback)
        sys.exit(1)
    sys.excepthook = exception_hook
    # try:
    # crash_here
    # except:
    #     print("caught crash")
    # timer = QTimer()
    # timer.timeout.connect(tick)
    # timer.start(1000)

    def signalHandler(sig, frame):
        if sig in (SIGINT, SIGTERM):
            # print("frontend got signal")
            # global EXIT_PROCESS
            EXIT_PROCESS[0] = True
            ingen_wrapper._FINISH = True
    signal(SIGINT,  signalHandler)
    signal(SIGTERM, signalHandler)
    initial_preset = False
    print("starting UI")
    # ingen_wrapper._FINISH = True
    while not EXIT_PROCESS[0]:
        # print("processing events")
        try:
            app.processEvents()
            # print("processing ui messages")
            process_ui_messages()
        except Exception as e:
            print("########## e is:", e)
            ex_type, ex_value, tb = sys.exc_info()
            error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
            print("EXception is:", error)
            sys.exit()
        sleep(0.01)

        # if not initial_preset:
        #     load_preset("/presets/Default Preset.json")
        #     update_counter.value+=1
        #     initial_preset = True
