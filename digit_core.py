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
###### UI
# --------------------------------------------------------------------------------------------------------
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot
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

# --------------------------------------------------------------------------------------------------------
# Poly Globals
effects = IntEnum("Effects", "delay1 reverb mixer cab")
# default connections, in 1, delay 1, in 1 to cab 1
# delay 1 to reverb 1
# reverb 1 to cab 1
user_port_name = {}#

portMap = {}
invPortMap = {}
# plugin names to Carla IDs
pluginMap = {}
#
parameterMap = {}

# --------------------------------------------------------------------------------------------------------
class Knobs(QObject):
    """Output stuff on the console."""

    @Slot(str, str, 'double')
    def ui_knob_change(self, effect_name, parameter, value):
        # print(x, y, z)
        if effect_name in pluginMap:
            host.set_parameter_value(pluginMap[effect_name], parameterMap[effect_name][parameter], value / 100.0)
        else:
            print("effect not found")


def engineCallback(host, action, pluginId, value1, value2, value3, valueStr):
    valueStr = charPtrToString(valueStr)
    if action == ENGINE_CALLBACK_PATCHBAY_PORT_ADDED:
        print("patchbay port added", pluginId, value1, value2, valueStr)
        if pluginId in invPortMap:
            portMap[invPortMap[pluginId]]["ports"][valueStr] = value1
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
    # elif action == ENGINE_CALLBACK_PATCHBAY_CONNECTION_ADDED:
    #     gOut, pOut, gIn, pIn = [int(i) for i in valueStr.split(":")] # FIXME
    #     host.PatchbayConnectionAddedCallback.emit(pluginId, gOut, pOut, gIn, pIn)
    # elif action == ENGINE_CALLBACK_PATCHBAY_CONNECTION_REMOVED:
    #     host.PatchbayConnectionRemovedCallback.emit(pluginId, value1, value2)
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

signal(SIGINT,  signalHandler)
signal(SIGTERM, signalHandler)

# class Knobs(QObject):
#     """Output stuff on the console."""
#     @Slot(str, str, 'double')
#     def ui_knob_change(self, effect_name, parameter_id, value):
#         # print(x, y)
#         host.set_parameter_value(effects[effect_name], parameter_id, value)

###


app = QGuiApplication(sys.argv)
QIcon.setThemeName("digit")
# Instantiate the Python object.
knobs = Knobs()

qmlEngine = QQmlApplicationEngine()
# Expose the object to QML.
context = qmlEngine.rootContext()
context.setContextProperty("knobs", knobs)
# engine.load(QUrl("qrc:/qml/digit.qml"))
qmlEngine.load(QUrl("qml/digit.qml"))

while host.is_engine_running() and not gCarla.term:
    # print("engine is idle")
    host.engine_idle()
    # print("processing GUI events in CALLBACK")
    app.processEvents()
    sleep(0.01)
    # wait until the last of our plugins is added, then connect them if they haven't been connected yet
    # default routing is input 1 to delay 1 to reverb to cab to out

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


