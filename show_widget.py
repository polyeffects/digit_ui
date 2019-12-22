import sys, time, json, os.path, os, subprocess, queue, threading, traceback
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit
from collections import OrderedDict
from enum import Enum
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
import pedal_hardware

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
effect_prototypes = {
        "input": {"inputs": {},
            "outputs": {"output": ["in", "AudioPort"]},
            "controls": {}},
        "output": {"inputs": {"input": ["out", "AudioPort"]},
            "outputs": {},
            "controls": {}},
    'control_to_midi': {'controls': {'AUTOFF': ['Auto Note-Off', 0, 0, 1],
                                      'CHAN': ['Channel', 0, 0, 15],
                                      'DATA1': ['Note/CC/PG Number', 0, 0, 127],
                                      'DATA2': ['Value', 0, 0, 127],
                                      'DELAY': ['1st Msg Repeat Delay Time',
                                                0.0,
                                                0.0,
                                                2000.0],
                                      'ENABLE': ['Enable', 1, 0, 1],
                                      'MSGTYPE': ['Message Type', 11, 8, 15]},
                         'inputs': {},
                         'outputs': {'MIDI_OUT': ['MIDI Out', ':AtomPort']}},
     'delay': {'controls': {'Amp_5': ['Level', 0.5, 0, 1],
                      'BPM_0': ['BPM', 120, 30, 300],
                      'DelayT60_3': ['Glide', 0.5, 0, 100],
                      'Delay_1': ['Time', 0.5, 0.001, 64],
                      'FeedbackSm_6': ['Tone', 0, 0, 1],
                      'Feedback_4': ['Feedback', 0.3, 0, 1],
                      'Warp_2': ['Warp', 0, -1, 1]},
         'inputs': {'Amp_5': ['Amp', 'CVPort'],
                    'DelayT60_3': ['Glide', 'CVPort'],
                    'Delay_1': ['Time', 'CVPort'],
                    'FeedbackSm_6': ['Tone', 'CVPort'],
                    'Feedback_4': ['Feedback', 'CVPort'],
                    'Warp_2': ['Warp', 'CVPort'],
                    'in0': ['in', 'AudioPort']},
         'outputs': {'out0': ['out', 'AudioPort']}},
     'env_follower': {'controls': {'ATIME': ['Attack Time', 0.01, 0.001, 15.0],
                                   'CDIRECTION': ['Invert', 0, 0, 1],
                                   'CMAXV': ['Maximum Value',
                                             1.0,
                                             0.0,
                                             1.0],
                                   'CMINV': ['Minimum Value',
                                             0.0,
                                             0.0,
                                             1.0],
                                   'DTIME': ['Decay Time', 1.0, 0.001, 30.0],
                                   'PEAKRMS': ['Peak/RMS', 0.0, 0.0, 1.0],
                                   'SATURATION': ['Saturation', 1.0, 0.0, 2.0],
                                   'THRESHOLD': ['Threshold', 0.0, 0.0, 1.0]},
                      'inputs': {'INPUT': ['Audio In', 'AudioPort']},
                      'outputs': {#'CTL_IN': ['Input Level', 'ControlPort'],
                                  #'CTL_OUT': ['Control Out', 'ControlPort'],
                                  'CV_OUT': ['CV Out', 'CVPort']}},
     'filter': {'controls': {'exp_fm_gain': ['Exp. FM gain', 0.5, 0.0, 10.0],
                             'freq': ['Frequency', 440.0, 1e-06, 1.0],
                             'in_gain': ['Input gain', 0.0, -60.0, 10.0],
                             'out_gain': ['Output gain', 0.0, -15.0, 15.0],
                             'res': ['Resonance', 0.5, 0.0, 1.0],
                             'res_gain': ['Resonance gain', 0.5, 0.0, 1.0]},
                'inputs': {'exp_fm': ['Exp FM', 'CVPort'],
                           'fm': ['FM', 'CVPort'],
                           'in': ['Input', 'AudioPort'],
                           'res_mod': ['Resonance Mod', 'CVPort']},
                'outputs': {'out': ['Output', 'AudioPort']}},
     'foot_switch_a': {'controls': {'in': ['Control Input', 0.5, 0.0, 1.0]},
                       'inputs': {},
                       'outputs': {'out': ['Out', 'CVPort']}},
     'foot_switch_b': {'controls': {'in': ['Control Input', 0.5, 0.0, 1.0]},
                       'inputs': {},
                       'outputs': {'out': ['Out', 'CVPort']}},
     'foot_switch_c': {'controls': {'in': ['Control Input', 0.5, 0.0, 1.0]},
                       'inputs': {},
                       'outputs': {'out': ['Out', 'CVPort']}},

     'lfo': {'controls': {'phi0': ['Phi0', 0, 0.0, 6.28],
                          'reset': ['Reset', 0.0, -1.0, 1.0],
                          'tempo': ['Tempo', 120.0, 1.0, 320.0],
                          'tempoMultiplier': ['Tempo Multiplier',
                                              1.0,
                                              0.0078125,
                                              32.0],
                          'waveForm': ['Wave Form', 0, 0, 5]},
             'inputs': {'reset': ['Reset', 'CVPort']},
             'outputs': {'output': ['Output', 'CVPort']}},
     'mix_vca': {'controls': {'gain1': ['Gain Offset', 0, 0, 1],
                              'gain1Data': ['Main Gain', 0.0, -1.0, 1.0],
                              'gain2': ['2nd Gain Boost', 0, 0, 1],
                              'gain2Data': ['2nd Gain', 0.0, -1.0, 1.0],
                              'in1': ['In 1 Level', 1, 0, 2],
                              'in2': ['In 2 Level', 1, 0, 2],
                              'outputLevel': ['Output Level', 1, 0, 2]},
                 'inputs': {'gain1Data': ['Main Gain', 'CVPort'],
                            'gain2Data': ['2nd Gain', 'CVPort'],
                            'in1Data': ['In 1', 'AudioPort'],
                            'in2Data': ['In 2', 'AudioPort']},
                 'outputs': {'out': ['Out', 'AudioPort']}},
     'mono_EQ': {'controls': {'HPQ': ['HighPass Resonance', 0.7, 0.0, 1.4],
                              'HPfreq': ['Highpass Frequency', 20.0, 5.0, 1250.0],
                              'HSfreq': ['Highshelf Frequency',
                                         8000.0,
                                         1000.0,
                                         16000.0],
                              'HSgain': ['Highshelf Gain', 0.0, -18.0, 18.0],
                              'HSq': ['Highshelf Bandwidth', 1.0, 0.0625, 4.0],
                              'HSsec': ['Highshelf', 1, 0, 1],
                              'HighPass': ['Highpass', 0, 0, 1],
                              'LPQ': ['LowPass Resonance', 1.0, 0.0, 1.4],
                              'LPfreq': ['Lowpass Frequency',
                                         20000.0,
                                         500.0,
                                         20000.0],
                              'LSfreq': ['Lowshelf Frequency', 80.0, 25.0, 400.0],
                              'LSgain': ['Lowshelf Gain', 0.0, -18.0, 18.0],
                              'LSq': ['Lowshelf Bandwidth', 1.0, 0.0625, 4.0],
                              'LSsec': ['Lowshelf', 1, 0, 1],
                              'LowPass': ['Lowpass', 0, 0, 1],
                              'enable': ['Enable', 1, 0, 1],
                              'freq1': ['Frequency 1', 160.0, 20.0, 2000.0],
                              'freq2': ['Frequency 2', 397.0, 40.0, 4000.0],
                              'freq3': ['Frequency 3', 1250.0, 100.0, 10000.0],
                              'freq4': ['Frequency 4', 2500.0, 200.0, 20000.0],
                              'gain': ['Gain', 0.0, -18.0, 18.0],
                              'gain1': ['Gain 1', 0.0, -18.0, 18.0],
                              'gain2': ['Gain 2', 0.0, -18.0, 18.0],
                              'gain3': ['Gain 3', 0.0, -18.0, 18.0],
                              'gain4': ['Gain 4', 0.0, -18.0, 18.0],
                              'peakreset': ['Reset Peak Hold', 1, 0, 1],
                              'q1': ['Bandwidth 1', 0.6, 0.0625, 4.0],
                              'q2': ['Bandwidth 2', 0.6, 0.0625, 4.0],
                              'q3': ['Bandwidth 3', 0.6, 0.0625, 4.0],
                              'q4': ['Bandwidth 4', 0.6, 0.0625, 4.0],
                              'sec1': ['Section 1', 1, 0, 1],
                              'sec2': ['Section 2', 1, 0, 1],
                              'sec3': ['Section 3', 1, 0, 1],
                              'sec4': ['Section 4', 1, 0, 1]},
                 'inputs': {'in': ['In', 'AudioPort']},
                 'outputs': { 'out': ['Out', 'AudioPort']}},
     'mono_cab': {'controls': {'gain': ['Output Gain', 0.0, -24.0, 24.0],
                            "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
                  'inputs': {'gain': ['Output Gain', 'CVPort'],
                             'in': ['In', 'AudioPort']},
                  'outputs': {'out': ['Out', 'AudioPort']}},
     'mono_reverb': {'controls': {'gain': ['Output Gain', 0.0, -24.0, 24.0],
                                 "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
                     'inputs': {'gain': ['Output Gain', 'CVPort'],
                                'in': ['In', 'AudioPort']},
                     'outputs': {'out': ['Out', 'AudioPort']}},
     'pan': {'controls': {'panCV': ['Pan CV', 0.0, -1.0, 1.0],
                          'panGain': ['Pan Gain', 0, 0, 2],
                          'panOffset': ['Pan Offset', 0, -1, 1],
                          'panningMode': ['Panning Mode', 0, 0, 4]},
             'inputs': {'in': ['In', 'AudioPort'], 'panCV': ['Pan CV', 'CVPort']},
             'outputs': {'out1': ['Out L', 'AudioPort'],
                         'out2': ['Out R', 'AudioPort']}},
     'reverse': {'controls': {'dry': ['Dry Level', 0.0, -90.0, 20.0],
                              'fragment': ['Fragment Length',
                                           1000.0,
                                           100.0,
                                           1600.0],
                              'wet': ['Wet Level', 0.0, -90.0, 20.0]},
                 'inputs': {'dry': ['Dry Level', 'CVPort'],
                            'input': ['Input', 'AudioPort'],
                            'wet': ['Wet Level', 'CVPort']},
                 'outputs': {'output': ['Output', 'AudioPort']}},
     'saturator': {'controls': {'Postgain': ['Postgain', 0, -90, 20],
                                'Pregain': ['Pregain', 0, -90, 20]},
                   'inputs': {'Input': ['Input', 'AudioPort'],
                              'Postgain': ['Postgain', 'CVPort'],
                              'Pregain': ['Pregain', 'CVPort']},
                   'outputs': {'Output': ['Output', 'AudioPort']}},
     'slew_limiter': {'controls': {'in': ['In', 0.0, -1.0, 1.0],
                                   'timeDown': ['Time Down', 0.5, 0, 10],
                                   'timeUp': ['Time Up', 0.5, 0.0, 10]},
                      'inputs': {'in': ['In', 'CVPort']},
                      'outputs': {'out': ['Out', 'CVPort']}},
     'square_distortion': {'controls': {'DOWN': ['Down', 0.02, -0.5, 1.0],
                                        'IN_GAIN': ['Input Gain', 1.0, 0.0, 1.0],
                                        'OCTAVE': ['Octave', 0, -2, 1.0],
                                        'OUT_GAIN': ['Output Gain', 1.0, 0.0, 1.0],
                                        'UP': ['Up', 0.02, -0.5, 1.0],
                                        'WETDRY': ['Wet/Dry Mix', 0.7, 0.0, 1.0]},
                           'inputs': {'INPUT': ['Audio In', 'AudioPort']},
                           'outputs': {'LATENCY': ['Latency', 'ControlPort'],
                                       'OUTPUT': ['Audio Out', 'AudioPort']}},
     'stereo_EQ': {'controls': {'HPQ': ['HighPass Resonance', 0.7, 0.0, 1.4],
                                'HPfreq': ['Highpass Frequency', 20.0, 5.0, 1250.0],
                                'HSfreq': ['Highshelf Frequency',
                                           8000.0,
                                           1000.0,
                                           16000.0],
                                'HSgain': ['Highshelf Gain', 0.0, -18.0, 18.0],
                                'HSq': ['Highshelf Bandwidth', 1.0, 0.0625, 4.0],
                                'HSsec': ['Highshelf', 1, 0, 1],
                                'HighPass': ['Highpass', 0, 0, 1],
                                'LPQ': ['LowPass Resonance', 1.0, 0.0, 1.4],
                                'LPfreq': ['Lowpass Frequency',
                                           20000.0,
                                           500.0,
                                           20000.0],
                                'LSfreq': ['Lowshelf Frequency', 80.0, 25.0, 400.0],
                                'LSgain': ['Lowshelf Gain', 0.0, -18.0, 18.0],
                                'LSq': ['Lowshelf Bandwidth', 1.0, 0.0625, 4.0],
                                'LSsec': ['Lowshelf', 1, 0, 1],
                                'LowPass': ['Lowpass', 0, 0, 1],
                                'enable': ['Enable', 1, 0, 1],
                                'freq1': ['Frequency 1', 160.0, 20.0, 2000.0],
                                'freq2': ['Frequency 2', 397.0, 40.0, 4000.0],
                                'freq3': ['Frequency 3', 1250.0, 100.0, 10000.0],
                                'freq4': ['Frequency 4', 2500.0, 200.0, 20000.0],
                                'gain': ['Gain', 0.0, -18.0, 18.0],
                                'gain1': ['Gain 1', 0.0, -18.0, 18.0],
                                'gain2': ['Gain 2', 0.0, -18.0, 18.0],
                                'gain3': ['Gain 3', 0.0, -18.0, 18.0],
                                'gain4': ['Gain 4', 0.0, -18.0, 18.0],
                                'q1': ['Bandwidth 1', 0.6, 0.0625, 4.0],
                                'q2': ['Bandwidth 2', 0.6, 0.0625, 4.0],
                                'q3': ['Bandwidth 3', 0.6, 0.0625, 4.0],
                                'q4': ['Bandwidth 4', 0.6, 0.0625, 4.0],
                                'sec1': ['Section 1', 1, 0, 1],
                                'sec2': ['Section 2', 1, 0, 1],
                                'sec3': ['Section 3', 1, 0, 1],
                                'sec4': ['Section 4', 1, 0, 1]},
                   'inputs': {'inL': ['In Left', 'AudioPort'],
                              'inR': ['In Right', 'AudioPort']},
                   'outputs': {'outL': ['Out Left', 'AudioPort'],
                               'outR': ['Out Right', 'AudioPort']}},
     'stereo_cab': {'controls': {'gain': ['Output Gain', 0.0, -24.0, 24.0],
                            "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
                    'inputs': {'gain': ['Output Gain', 'CVPort'],
                               'in': ['In', 'AudioPort']},
                    'outputs': {'out_1': ['OutL', 'AudioPort'],
                                'out_2': ['OutR', 'AudioPort']}},
     'stereo_reverb': {'controls': {'gain': ['Output Gain', 0.0, -24.0, 24.0],
                                 "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
                       'inputs': {'gain': ['Output Gain', 'CVPort'],
                                  'in': ['In', 'AudioPort']},
                       'outputs': {'out_1': ['OutL', 'AudioPort'],
                                   'out_2': ['OutR', 'AudioPort']}},
     'true_stereo_cab': {'controls': {'gain': ['Gain', 0.0, -24.0, 24.0],
                            "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
                         'inputs': {'gain': ['Gain', 'CVPort'],
                                    'in_1': ['InL', 'AudioPort'],
                                    'in_2': ['InR', 'AudioPort']},
                         'outputs': {'out_1': ['OutL', 'AudioPort'],
                                     'out_2': ['OutR', 'AudioPort']}},
     'true_stereo_reverb': {'controls': {'gain': ['Output Gain', 0.0, -24.0, 24.0],
                                 "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
                            'inputs': {'gain': ['Output Gain', 'CVPort'],
                                       'in_1': ['InL', 'AudioPort'],
                                       'in_2': ['InR', 'AudioPort']},
                            'outputs': {'out_1': ['OutL', 'AudioPort'],
                                        'out_2': ['OutR', 'AudioPort']}},
     'warmth': {'controls': {'blend': ['Tape--Tube Blend', 10, -10, 10],
                             'drive': ['Drive', 5.0, 0.1, 10]},
                'inputs': {'blend': ['Tape--Tube Blend', 'CVPort'],
                           'drive': ['Drive', 'CVPort'],
                           'input': ['Input', 'AudioPort']},
                'outputs': {'output': ['Output', 'AudioPort']}}}


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
            out_port_type = effect_prototypes[current_effects[effect_id]["effect_type"]]["outputs"][port_name][1]
            for id, effect in current_effects.items():
                effect["highlight"] = False
                if id != effect_id:
                    # if out_port_type in ["CVPort", "ControlPort"]: # looking for controls
                    #     if len(current_effects[id]["controls"]) > 0:
                    #         effect["highlight"] = True
                    # else:
                    for input_port, style in effect_prototypes[effect["effect_type"]]["inputs"].items():
                        if style[1] == out_port_type:
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
            ports = [k+'|'+v[0] for k,v in effect_prototypes[effect_type]["outputs"].items()]
            selected_effect_ports.setStringList(ports)
        else:
            s_effect_id, s_port = connect_source_port.name.split("/")
            source_port_type = effect_prototypes[current_effects[s_effect_id]["effect_type"]]["outputs"][s_port][1]
            ports = [k+'|'+v[0] for k,v in effect_prototypes[effect_type]["inputs"].items() if v[1] == source_port_type]
            selected_effect_ports.setStringList(ports)

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

    @Slot(str, str)
    def set_knob_current_effect(self, effect_id, parameter):
        # get current value and update encoder / cache.
        knob = "left"
        if knob_map[knob].effect != effect_id:
            knob_map[knob].effect = effect_id
            knob_map[knob].parameter = parameter
            knob_map[knob].rmin = current_effects[effect_id]["controls"][parameter].rmin
            knob_map[knob].rmax = current_effects[effect_id]["controls"][parameter].rmax


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

class Encoder():
    # name, min, max, value
    def __init__(self, starteffect="", startparameter="", s_speed=1):
        self.effect = starteffect
        self.parameter = startparameter
        self.speed = s_speed
        self.rmin = 0
        self.rmax = 1

knob_map = {"left": Encoder(s_speed=0.1), "right": Encoder(s_speed=2)}

def handle_encoder_change(is_left, change):
    # increase or decrease the current knob value depending on knob speed
    # knob_value = knob_value + (change * knob_speed)
    normal_speed = 48.0
    knob = "left"
    knob_effect = knob_map[knob].effect
    knob_parameter = knob_map[knob].parameter
    value = current_effects[knob_effect]["controls"][knob_parameter]
    if is_left:
        knob_speed = knob_map["left"].speed
    else:
        knob_speed = knob_map["right"].speed
    # base speed * speed multiplier
    base_speed = (abs(knob_map[knob].rmin) + abs(knob_map[knob].rmax)) / normal_speed
    value = value + (change * knob_speed * base_speed)
    # print("knob value is", value)
    # knob change handles clamping
    knobs.ui_knob_change(knob_effect, knob_parameter, value)

def set_bpm(bpm):
    current_bpm.value = bpm
    # host.transport_bpm(bpm)
    # send_ui_message("bpm_change", (bpm, ))
    # print("setting tempo", bpm)

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
foot_action_groups = [{"tap_up":[Actions.set_value] , "step_up": [Actions.set_value], "bypass_up":[Actions.toggle_pedal],
    "tap_down":[Actions.set_value_down] , "step_down": [Actions.set_value_down], #"bypass_down":[Actions.se],
    "tap_step_up": [Actions.previous_preset], "step_bypass_up": [Actions.next_preset]}]
current_action_group = 0

def send_to_footswitch_blocks(switch_name, value=0):
    # send to all foot switch blocks
    if "tap" in switch_name:
        foot_switch_name = "foot_switch_a"
    if "step" in switch_name:
        foot_switch_name = "foot_switch_b"
    if "bypass" in switch_name:
        foot_switch_name = "foot_switch_c"

    for effect_id, effect in current_effects.items():
        if effect["effect_type"] == "foot_switch":
            if foot_switch_name in effect_id:
                knobs.ui_knob_change(effect_id, "in", value)

def handle_foot_change(switch_name, timestamp):
    action = foot_action_groups[current_action_group][switch_name][0]
    params = None
    if len(foot_action_groups[current_action_group][switch_name]) > 1:
        params = foot_action_groups[current_action_group][switch_name][1:]
    if action is Actions.tap:
        handle_tap(timestamp)
    elif action is Actions.toggle_pedal:
        handle_bypass()

    elif action is Actions.set_value:
        send_to_footswitch_nodes(switch_name, 0)
    elif action is Actions.set_value_down:
        send_to_footswitch_blocks(switch_name, 1)
    elif action is Actions.select_preset:
        pass

    elif action is Actions.next_preset:
        next_preset()

    elif action is Actions.previous_preset:
        previous_preset()

    elif action is Actions.toggle_effect:
        pass

start_tap_time = None
## tap callback is called by hardware button from the GPIO checking thread
def handle_tap(timestamp):
    global start_tap_time
    current_tap = timestamp
    if start_tap_time is not None:
        # just use this and previous to calculate BPM
        # BPM must be in range 30-250
        d = current_tap - start_tap_time
        # 120 bpm, 0.5 seconds per tap
        bpm = 60 / d
        if bpm > 30 and bpm < 350:
            # set host BPM
            set_bpm(bpm)

    # record start time
    start_tap_time = current_tap

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
                    if effect_type == "http://drobilla.net/plugins/blop/interpolator":
                        mapped_type = effect_name.rstrip("123456789")
                        if mapped_type in effect_type_map:
                            from_backend_new_effect(effect_name, mapped_type, x, y)
                    else:
                        from_backend_new_effect(effect_name, inv_effect_type_map[effect_type], x, y)
                        ingen_wrapper.ingen.get("/engine")
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
            elif m[0] == "dsp_load":
                max_load, mean_load, min_load = m[1:]
                dsp_load.rmin = min_load
                dsp_load.rmax = max_load
                dsp_load.value = mean_load
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
        "foot_switch_a": "http://drobilla.net/plugins/blop/interpolator",
        "foot_switch_b": "http://drobilla.net/plugins/blop/interpolator",
        "foot_switch_c": "http://drobilla.net/plugins/blop/interpolator",
        "slew_limiter": "http://avwlv2.sourceforge.net/plugins/avw/slew",
        "square_distortion": "http://ssj71.github.io/infamousPlugins/plugs.html#hip2b",
        "control_to_midi": "http://ssj71.github.io/infamousPlugins/plugs.html#mindi",
        "pan": "http://avwlv2.sourceforge.net/plugins/avw/vcpanning",
        "mix_vca": "http://avwlv2.sourceforge.net/plugins/avw/vcaexp_audio",
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
    dsp_load = PolyValue("DSP Load", 0, 0, 0.3)
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
    context.setContextProperty("dspLoad", dsp_load)
    # context.setContextProperty("pluginState", plugin_state)
    context.setContextProperty("currentPreset", current_preset)
    context.setContextProperty("commandStatus", command_status)
    context.setContextProperty("delayNumBars", delay_num_bars)
    context.setContextProperty("connectSourcePort", connect_source_port)
    # context.setContextProperty("midiChannel", midi_channel)
    # context.setContextProperty("isLoading", is_loading)
    # # context.setContextProperty("inputLevel", input_level)
    # context.setContextProperty("presetList", preset_list_model)
    engine.load(QUrl("qml/TestWrapper.qml")) # XXX 
    print("starting send thread")
    ingen_wrapper.start_send_thread()
    print("starting recv thread")
    ingen_wrapper.start_recv_thread(ui_messages)

    pedal_hardware.foot_callback = handle_foot_change
    pedal_hardware.encoder_change_callback = handle_encoder_change
    pedal_hardware.add_hardware_listeners()
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
    ingen_wrapper.ingen.get("/main")
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
