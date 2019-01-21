##################### DIGIT #######
##################### DIGIT #######
##################### DIGIT #######
# 26 total effect slots? 
# delay 1-4
# reverb
# cab
# effects 1-4 per delay & reverb

#    


# from pluginsmanager.jack.jack_client import JackClient
# client = JackClient()
# sys_effect = SystemEffect('system', ['capture_1', 'capture_2', "capture_3, capture_4"],
#         ['playback_1', 'playback_2', 'playback_3', 'playback_4'])
import sys
from collections import defaultdict
##### Hardware backend
# --------------------------------------------------------------------------------------------------------
import pedal_hardware
###### UI
# --------------------------------------------------------------------------------------------------------
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal
from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtGui import QIcon
# compiled QML files, compile with pyside2-rcc
import qml.qml
import icons.icons, imagine_assets
import resource_rc
######## Carla
# --------------------------------------------------------------------------------------------------------
sys.path.append('/git_repos/Carla/source/frontend')
from enum import IntEnum
from carla_backend import *
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit

class CarlaObject(object):
    __slots__ = [
        'term'
    ]

gCarla = CarlaObject()
gCarla.term = False

def signalHandler(sig, frame):
    if sig in (SIGINT, SIGTERM):
        gCarla.term = True

pedal_hardware.add_hardware_listeners()
# --------------------------------------------------------------------------------------------------------
# Poly Globals
effects = IntEnum("Effects", "delay1 reverb mixer cab")
# default connections, in 1, delay 1, in 1 to cab 1
# delay 1 to reverb 1
# reverb 1 to cab 1
# source_port_names = {"In 1": ("system", "capture_1"),
#     "In 2": ("system", "capture_2"),
#     "In 3": ("system", "capture_3"),
#     "In 4": ("system", "capture_4"),
#     "Delay 1 Out": ("delay1", "Left Out")}

output_port_names = {"Out 1": ("system", "playback_1"),
    "Out 2": ("system", "playback_2"),
    "Out 3": ("system", "playback_3"),
    "Out 4": ("system", "playback_4"),
    "Delay 1 In": ("delay1", "Left In"),
    "Cab": ("cab", "in"),
    "Reverb L": ("reverb", "In"),
    "Reverb R": ("reverb", "In1")
    }
default_source = {"delay1": "Left Out", "reverb": "Out" }
# inv_source_port_names = dict({(v, k) for k,v in source_port_names.items()})
inv_output_port_names = dict({(v, k) for k,v in output_port_names.items()})

portMap = {}
invPortMap = {}
# plugin names to Carla IDs
pluginMap = {}
#
parameterMap = {}
current_connections = {} # these are group port group port to connection id pairs #TODO remove stale

# --------------------------------------------------------------------------------------------------------
source_ports = ["delay1:Left Out", "reverb:Out", "reverb:Out1", "system:capture_1", "system:capture_2", "system:capture_3", "system:capture_4", "cab:Out"]
available_port_models = dict({(k, QStringListModel()) for k in source_ports})
used_port_models = dict({(k, QStringListModel()) for k in available_port_models.keys()})
# XXX temp, until I fix bypassing
plugin_state = defaultdict(bool)
knob_value_cache = defaultdict(int)


def insert_row(model, row):
    j = len(model.stringList())
    model.insertRows(j, 1)
    model.setData(model.index(j), row)

def remove_row(model, row):
    i = model.stringList().index(row)
    model.removeRows(i, 1)

def set_active(effect, is_active):
    print(effect, " active state is ", bool(is_active))
    host.set_drywet(pluginMap[effect], is_active) # full wet if active else full dry
    plugin_state[effect] = is_active

class PolyEncoder(QObject):
    # name, min, max, value
    def __init__(self, starteffect="", startparameter=""):
        QObject.__init__(self)
        self.effectval = starteffect
        self.parameterval = startparameter

    def readEffect(self):
        return self.effectval

    def setEffect(self,val):
        self.effectval = val
        self.effect_changed.emit()

    @Signal
    def effect_changed(self):
        pass

    effect = Property(str, readEffect, setEffect, notify=effect_changed)

    def readParameter(self):
        return self.parameterval

    def setParameter(self,val):
        self.parameterval = val
        self.parameter_changed.emit()

    @Signal
    def parameter_changed(self):
        pass

    parameter = Property(str, readParameter, setParameter, notify=parameter_changed)



class PolyValue(QObject):
    # name, min, max, value
    def __init__(self, startname="", startval=0, startmin=0, startmax=1, curve_type="lin"):
        QObject.__init__(self)
        self.nameval = startname
        self.valueval = startval
        self.rminval = startmin
        self.rmax = startmax

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        self.valueval = val
        self.value_changed.emit()
        print("setting value", val)

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


class Knobs(QObject):
    """Output stuff on the console."""

    def __init__(self):
        QObject.__init__(self)
        self.waitingval = ""

    @Slot(str, str, 'double')
    def ui_knob_change(self, effect_name, parameter, value):
        # print(x, y, z)
        if effect_name in pluginMap:
            host.set_parameter_value(pluginMap[effect_name], parameterMap[effect_name][parameter], value)
            effect_parameter_data[effect_name][parameter].value = value
        else:
            print("effect not found")

    @Slot(str, str, str)
    def ui_add_connection(self, effect, source_port, x):
        effect_source = effect + ":" + source_port
        remove_row(available_port_models[effect_source], x)
        insert_row(used_port_models[effect_source], x)
        # print("portMap is", portMap)

        host.patchbay_connect(portMap[effect]["group"],
                portMap[effect]["ports"][source_port],
                portMap[output_port_names[x][0]]["group"],
                portMap[output_port_names[x][0]]["ports"][output_port_names[x][1]])
        print(x)

    @Slot(str, str, str)
    def ui_remove_connection(self, effect, source_port, x):
        effect_source = effect + ":" + source_port
        remove_row(used_port_models[effect_source], x)
        insert_row(available_port_models[effect_source], x)

        host.patchbay_disconnect(current_connections[(portMap[effect]["group"],
                portMap[effect]["ports"][source_port],
                portMap[output_port_names[x][0]]["group"],
                portMap[output_port_names[x][0]]["ports"][output_port_names[x][1]])])
        print(x)

    @Slot(str)
    def toggle_enabled(self, effect):
        print("toggling", effect)
        # host.set_active(pluginMap[effect], not bool(host.get_internal_parameter_value(pluginMap[effect], PARAMETER_ACTIVE)))
        # active = host.get_internal_parameter_value(pluginMap[effect], PARAMETER_ACTIVE))
        is_active = not plugin_state[effect]
        set_active(effect, is_active)

    @Slot(str, str)
    def map_parameter_to_encoder(self, effect_name, parameter):
        set_knob_current_effect(self.waiting, effect_name, parameter)
        self.waiting = ""

    @Slot(str)
    def set_waiting(self, knob):
        print("waiting", knob)
        self.waiting = knob

    def readWaiting(self):
        return self.waitingval

    def setWaiting(self,val):
        self.waitingval = val
        self.waiting_changed.emit()

    @Signal
    def waiting_changed(self):
        pass

    waiting = Property(str, readWaiting, setWaiting, notify=waiting_changed)

def engineCallback(host, action, pluginId, value1, value2, value3, valueStr):
    valueStr = charPtrToString(valueStr)
    if action == ENGINE_CALLBACK_PATCHBAY_PORT_ADDED:
        print("patchbay port added", pluginId, value1, value2, valueStr)
        if pluginId in invPortMap:
            portMap[invPortMap[pluginId]]["ports"][valueStr] = value1
            for k, model in available_port_models.items():
                if (invPortMap[pluginId], valueStr) in inv_output_port_names:
                    insert_row(model, inv_output_port_names[(invPortMap[pluginId], valueStr)])

        else:
            print("got port without client")
    elif action == ENGINE_CALLBACK_PATCHBAY_CLIENT_ADDED:
        print("patchbay client added", pluginId, value1, value2, valueStr)
        portMap[valueStr] = {"group" : pluginId, "ports": {}}
        invPortMap[pluginId] = valueStr
    elif action == ENGINE_CALLBACK_PLUGIN_ADDED:
        pluginMap[valueStr] = pluginId
        pluginParams = {}
        for i in range(host.get_parameter_count(pluginId)):
             p = host.get_parameter_info(pluginId, i)
             pluginParams[p["symbol"]] = i
        parameterMap[valueStr] = pluginParams
        print("plugin added", pluginId, valueStr)
    # elif action == ENGINE_CALLBACK_IDLE:
    #     print("processing GUI events in CALLBACK")
    #     app.processEvents()
    elif action == ENGINE_CALLBACK_PATCHBAY_CLIENT_DATA_CHANGED:
        print("patchbay data changed", pluginId, value1, value2)
    elif action == ENGINE_CALLBACK_PATCHBAY_CONNECTION_ADDED:
        gOut, pOut, gIn, pIn = [int(i) for i in valueStr.split(":")] # FIXME
        current_connections[(gOut, pOut, gIn, pIn)] = pluginId
        print("patchbay connection added", pluginId, gOut, pOut, gIn, pIn)
        # host.PatchbayConnectionAddedCallback.emit(pluginId, gOut, pOut, gIn, pIn)
    elif action == ENGINE_CALLBACK_PATCHBAY_CONNECTION_REMOVED:
        # host.PatchbayConnectionRemovedCallback.emit(pluginId, value1, value2)
        print("patchbay connection removed", pluginId, value1, value2)

    # if action == ENGINE_CALLBACK_ENGINE_STARTED:
    #     host.processMode   = value1
    #     host.transportMode = value2
    # elif action == ENGINE_CALLBACK_PROCESS_MODE_CHANGED:
    #     host.processMode   = value1
    # elif action == ENGINE_CALLBACK_TRANSPORT_MODE_CHANGED:
    #     host.transportMode  = value1
    #     host.transportExtra = valueStr

    # if action == ENGINE_CALLBACK_DEBUG:
    #     host.DebugCallback.emit(pluginId, value1, value2, value3, valueStr)
    # elif action == ENGINE_CALLBACK_PLUGIN_REMOVED:
    #     host.PluginRemovedCallback.emit(pluginId)
    # elif action == ENGINE_CALLBACK_PLUGIN_RENAMED:
    #     host.PluginRenamedCallback.emit(pluginId, valueStr)
    # elif action == ENGINE_CALLBACK_PLUGIN_UNAVAILABLE:
    #     host.PluginUnavailableCallback.emit(pluginId, valueStr)
    # elif action == ENGINE_CALLBACK_PARAMETER_VALUE_CHANGED:
    #     host.ParameterValueChangedCallback.emit(pluginId, value1, value3)
    # elif action == ENGINE_CALLBACK_PARAMETER_DEFAULT_CHANGED:
    #     host.ParameterDefaultChangedCallback.emit(pluginId, value1, value3)
    # elif action == ENGINE_CALLBACK_PARAMETER_MIDI_CC_CHANGED:
    #     host.ParameterMidiCcChangedCallback.emit(pluginId, value1, value2)
    # elif action == ENGINE_CALLBACK_PARAMETER_MIDI_CHANNEL_CHANGED:
    #     host.ParameterMidiChannelChangedCallback.emit(pluginId, value1, value2)
    # elif action == ENGINE_CALLBACK_PROGRAM_CHANGED:
    #     host.ProgramChangedCallback.emit(pluginId, value1)
    # elif action == ENGINE_CALLBACK_MIDI_PROGRAM_CHANGED:
    #     host.MidiProgramChangedCallback.emit(pluginId, value1)
    # elif action == ENGINE_CALLBACK_OPTION_CHANGED:
    #     host.OptionChangedCallback.emit(pluginId, value1, bool(value2))
    # elif action == ENGINE_CALLBACK_UI_STATE_CHANGED:
    #     host.UiStateChangedCallback.emit(pluginId, value1)
    # elif action == ENGINE_CALLBACK_NOTE_ON:
    #     host.NoteOnCallback.emit(pluginId, value1, value2, round(value3))
    # elif action == ENGINE_CALLBACK_NOTE_OFF:
    #     host.NoteOffCallback.emit(pluginId, value1, value2)
    # elif action == ENGINE_CALLBACK_UPDATE:
    #     host.UpdateCallback.emit(pluginId)
    # elif action == ENGINE_CALLBACK_RELOAD_INFO:
    #     host.ReloadInfoCallback.emit(pluginId)
    # elif action == ENGINE_CALLBACK_RELOAD_PARAMETERS:
    #     host.ReloadParametersCallback.emit(pluginId)
    # elif action == ENGINE_CALLBACK_RELOAD_PROGRAMS:
    #     host.ReloadProgramsCallback.emit(pluginId)
    # elif action == ENGINE_CALLBACK_RELOAD_ALL:
    #     host.ReloadAllCallback.emit(pluginId)
    # elif action == ENGINE_CALLBACK_PATCHBAY_CLIENT_ADDED:
    #     host.PatchbayClientAddedCallback.emit(pluginId, value1, value2, valueStr)
    # elif action == ENGINE_CALLBACK_PATCHBAY_CLIENT_REMOVED:
    #     host.PatchbayClientRemovedCallback.emit(pluginId)
    # elif action == ENGINE_CALLBACK_PATCHBAY_CLIENT_RENAMED:
    #     host.PatchbayClientRenamedCallback.emit(pluginId, valueStr)
    # elif action == ENGINE_CALLBACK_PATCHBAY_PORT_ADDED:
    #     print("patchbay port added", pluginId, value1, value2, valueStr)
        # def slot_handlePatchbayPortAddedCallback(self, clientId, portId, portFlags, portName):
        # host.PatchbayPortAddedCallback.emit(pluginId, value1, value2, valueStr)
    # elif action == ENGINE_CALLBACK_PATCHBAY_PORT_REMOVED:
    #     host.PatchbayPortRemovedCallback.emit(pluginId, value1)
    # elif action == ENGINE_CALLBACK_PATCHBAY_PORT_RENAMED:
    #     host.PatchbayPortRenamedCallback.emit(pluginId, value1, valueStr)
    # elif action == ENGINE_CALLBACK_ENGINE_STARTED:
    #     host.EngineStartedCallback.emit(value1, value2, value3, valueStr)
    # elif action == ENGINE_CALLBACK_ENGINE_STOPPED:
    #     host.EngineStoppedCallback.emit()
    # elif action == ENGINE_CALLBACK_PROCESS_MODE_CHANGED:
    #     host.ProcessModeChangedCallback.emit(value1)
    # elif action == ENGINE_CALLBACK_TRANSPORT_MODE_CHANGED:
    #     host.TransportModeChangedCallback.emit(value1, valueStr)
    # elif action == ENGINE_CALLBACK_BUFFER_SIZE_CHANGED:
    #     host.BufferSizeChangedCallback.emit(value1)
    # elif action == ENGINE_CALLBACK_SAMPLE_RATE_CHANGED:
    #     host.SampleRateChangedCallback.emit(value3)
    # elif action == ENGINE_CALLBACK_PROJECT_LOAD_FINISHED:
    #     host.ProjectLoadFinishedCallback.emit()
    # elif action == ENGINE_CALLBACK_NSM:
    #     host.NSMCallback.emit(value1, value2, valueStr)
    # elif action == ENGINE_CALLBACK_INFO:
    #     host.InfoCallback.emit(valueStr)
    # elif action == ENGINE_CALLBACK_ERROR:
    #     host.ErrorCallback.emit(valueStr)
    # elif action == ENGINE_CALLBACK_QUIT:
    #     host.QuitCallback.emit()

binaryDir = "/git_repos/Carla/bin"
host = CarlaHostDLL("/git_repos/Carla/bin/libcarla_standalone2.so", False)
host.set_engine_option(ENGINE_OPTION_PATH_BINARIES, 0, binaryDir)
host.set_engine_callback(lambda h,a,p,v1,v2,v3,vs: engineCallback(host,a,p,v1,v2,v3,vs))

if not host.engine_init("JACK", "PolyCarla"):
    print("Engine failed to initialize, possible reasons:\n%s" % host.get_last_error())
    exit(1)


host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "delay1", "http://drobilla.net/plugins/mda/Delay",  0, None, 0)
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "reverb", "http://drobilla.net/plugins/fomp/reverb", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "reverb", "http://guitarix.sourceforge.net/plugins/gx_reverb_stereo#_reverb_stereo", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "mixer", "http://gareus.org/oss/lv2/matrixmixer#i4o4", 0, None, 0)
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "", "http://gareus.org/oss/lv2/matrixmixer#i4o4", effects.cab, None, 0)
##### ---- Effects
# tape/tube http://moddevices.com/plugins/tap/tubewarmth
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "tape1", "http://moddevices.com/plugins/tap/tubewarmth", 0, None, 0)
# filter http://drobilla.net/plugins/fomp/mvclpf4
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "filter1", "http://drobilla.net/plugins/fomp/mvclpf1", 0, None, 0)
# sigmoid  http://moddevices.com/plugins/tap/sigmoid
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "sigmoid1", "http://moddevices.com/plugins/tap/sigmoid", 0, None, 0)
# bitcrusher 
# eq 
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "cab", "http://guitarix.sourceforge.net/plugins/gx_cabinet#CABINET", 0, None, 0)

signal(SIGINT,  signalHandler)
signal(SIGTERM, signalHandler)

# class Knobs(QObject):
#     """Output stuff on the console."""
#     @Slot(str, str, 'double')
#     def ui_knob_change(self, effect_name, parameter_id, value):
#         # print(x, y)
#         host.set_parameter_value(effects[effect_name], parameter_id, value)

###

knob_map = {"left": PolyEncoder("delay1", "l_delay"), "right": PolyEncoder("delay1", "feedback")}

effect_parameter_data = {"delay1": {"l_delay": PolyValue("time", 0.5, 0, 1), "feedback": PolyValue("feedback", 0.7, 0, 1)},
    "reverb": {"dry_wet": PolyValue("mix", 50, 0, 100), "roomsize": PolyValue("size", 0.5, 0, 1)},
    "mixer": {"mixr_1_1": PolyValue("mix 1,1", 0, 0, 1), "mix_1_2": PolyValue("mix 1,2", 0, 0, 1),
        "mix_1_3": PolyValue("mix 1,3", 0, 0, 1),"mix_1_4": PolyValue("mix 1,4", 0, 0, 1),
        "mix_2_1": PolyValue("mix 2,1", 0, 0, 1),"mix_2_2": PolyValue("mix 2,2", 0, 0, 1),
        "mix_2_3": PolyValue("mix 2,3", 0, 0, 1),"mix_2_4": PolyValue("mix 2,4", 0, 0, 1),
        "mix_3_1": PolyValue("mix 3,1", 0, 0, 1),"mix_3_2": PolyValue("mix 3,2", 0, 0, 1),
        "mix_3_3": PolyValue("mix 3,3", 0, 0, 1),"mix_3_4": PolyValue("mix 3,4", 0, 0, 1),
        "mix_4_1": PolyValue("mix 4,1", 0, 0, 1),"mix_4_2": PolyValue("mix 4,2", 0, 0, 1),
        "mix_4_3": PolyValue("mix 4,3", 0, 0, 1),"mix_4_4": PolyValue("mix 4,4", 0, 0, 1)
        },
    "tape1": {"drive": PolyValue("drive", 5, 0, 10), "blend": PolyValue("tape vs tube", 10, -10, 10)},
    "filter1": {"freq": PolyValue("cutoff", 440, 20, 15000, "log"), "res": PolyValue("resonance", 0, 0, 0.8)},
    "sigmoid1": {"Pregain": PolyValue("pre gain", 0, -90, 20), "Postgain": PolyValue("post gain", 0, -90, 20)},
    "cab": {"CBass": PolyValue("bass", 0, -10, 10), "CTreble": PolyValue("treble", 0, -10, 10),
        "c_model": PolyValue("Cab Model", 0, 0, 18)}
    }

app = QGuiApplication(sys.argv)
QIcon.setThemeName("digit")
# Instantiate the Python object.
knobs = Knobs()

qmlEngine = QQmlApplicationEngine()
# Expose the object to QML.
context = qmlEngine.rootContext()
context.setContextProperty("knobs", knobs)
for k, v in available_port_models.items():
    context.setContextProperty(k.replace(" ", "_").replace(":", "_")+"AvailablePorts", v)
for k, v in used_port_models.items():
    context.setContextProperty(k.replace(" ", "_").replace(":", "_")+"UsedPorts", v)
context.setContextProperty("knobs", knobs)
context.setContextProperty("polyValues", effect_parameter_data)
context.setContextProperty("knobMap", knob_map)


# engine.load(QUrl("qrc:/qml/digit.qml"))
qmlEngine.load(QUrl("qml/digit.qml"))

mixer_is_connected = False
knobs_are_initial_mapped  = False

######### UI is setup



def translate_range(value, leftMin, leftMax, rightMin, rightMax):
    # Figure out how 'wide' each range is
    leftSpan = leftMax - leftMin
    rightSpan = rightMax - rightMin

    # Convert the left range into a 0-1 range (float)
    valueScaled = float(value - leftMin) / float(leftSpan)

    # Convert the 0-1 range into a value in the right range.
    return rightMin + (valueScaled * rightSpan)

def map_ui_parameter_lv2_value(effect, parameter, in_min, in_max, value):
    # map UI or hardware range to effect range
    # in_min / in_max are what the knob / ui generates
    #   from numpy import interp
    #  interp(256,[1,512],[5,10])
    out_min = effect_parameter_data[effect][parameter].rmin
    out_max = effect_parameter_data[effect][parameter].rmax
    return translate_range(value, in_min, in_max, out_min, out_max)

def map_lv2_value_to_ui_knob(effect, parameter, in_min, in_max, value):
    # map UI or hardware range to effect range
    # in_min / in_max are what the knob / ui generates
    out_min = effect_parameter_data[effect][parameter].rmin
    out_max = effect_parameter_data[effect][parameter].rmax
    return translate_range(value, out_min, out_max, in_min, in_max)

def set_knob_current_effect(knob, effect, parameter):
    # get current value and update encoder / cache.
    knob_map[knob].effect = effect
    knob_map[knob].parameter = parameter
    value = effect_parameter_data[effect][parameter].value
    mapped_value = map_lv2_value_to_ui_knob(effect, parameter, 0, pedal_hardware.KNOB_MAX, value)
    pedal_hardware.set_encoder_value(knob, mapped_value)
    knob_value_cache[knob] = mapped_value

def check_encoder_change():
    for knob in ["left", "right"]:
        cur_value = 0
        knob_effect = knob_map[knob].effect
        knob_parameter = knob_map[knob].parameter
        cur_value = pedal_hardware.get_encoder(knob)
        if cur_value != knob_value_cache[knob]:
            mapped_value = map_ui_parameter_lv2_value(knob_effect, knob_parameter, 0, pedal_hardware.KNOB_MAX, cur_value)
            print("knob value is", cur_value, "mapped", mapped_value)
            knobs.ui_knob_change(knob_effect, knob_parameter, mapped_value)
            # knob_mapping[knob](cur_value)
            knob_value_cache[knob] = cur_value

while host.is_engine_running() and not gCarla.term:
    # print("engine is idle")
    host.engine_idle()
    # print("processing GUI events in CALLBACK")
    app.processEvents()
    sleep(0.01)
    # wait until the last of our plugins is added, then connect them if they haven't been connected yet
    # default routing is input 1 to delay 1 to reverb to cab to out
    # check if encoders have changed
    if (not mixer_is_connected) and "mixer" in portMap:
        # mixer 1-4 to outputs
        for source_port, output_port in [("Audio Output 1", "playback_1"), ("Audio Output 2", "playback_2"),
                ("Audio Output 3", "playback_3"), ("Audio Output 4", "playback_4") ]:
            host.patchbay_connect(portMap["mixer"]["group"],
                    portMap["mixer"]["ports"][source_port],
                    portMap["system"]["group"],
                    portMap["system"]["ports"][output_port])
        for source_port, output_port in [("capture_1", "Audio Input 1"),
                ("capture_2", "Audio Input 2"), ("capture_3", "Audio Input 3"),
                ("capture_4", "Audio Input 4")]:
            host.patchbay_connect(portMap["system"]["group"],
                    portMap["system"]["ports"][source_port],
                    portMap["mixer"]["group"],
                    portMap["mixer"]["ports"][output_port])
        mixer_is_connected = True
    if (not knobs_are_initial_mapped):
        if "delay1" in portMap:
            set_knob_current_effect("left", "delay1", "l_delay")
            set_knob_current_effect("right", "delay1", "feedback")
            knobs_are_initial_mapped = True
    else:
        check_encoder_change()


if not gCarla.term:
    print("Engine closed abruptely")

if not host.engine_close():
    print("Engine failed to close, possible reasons:\n%s" % host.get_last_error())
exit(1)

## on ui knob change, set value in lv2
# def ui_knob_change(value):
    # knob is zero to 1, map to pedal range 
    #fuzz.params[0].minimum / fuzz.params[0].maximum
    #fuzz.params[0].value

# 4 out, delay, reverb, cab
# 4 in, delay, reverb, cab

#
# fuzz.toggle()
# or
# fuzz.active = not fuzz.active

# mixer points
# effects on wet path dry option later
# delay wet to other delay
# delay wet to [reverb .... 
# delay post to
# one effect is send?


# delay 1 wet to delay 2,3,4. Reverb, output 1,2,3,4
# collapsable mixer? only 1->1 shown?
# delay 1 post to delay 2,3,4. Reverb, output 1,2,3,4


# tape / tube, filter, eq, flange, bit crush


# cv mixer


# calculate tap tempo then
# set transport state


