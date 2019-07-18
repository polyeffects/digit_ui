##################### DIGIT #######
import sys, time, json, os.path, os, subprocess, queue, threading
from multiprocessing import Process, Queue
##### Hardware backend
# --------------------------------------------------------------------------------------------------------
import pedal_hardware, digit_frontend
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

os.sched_setaffinity(0, (0, 1, 3))

pedal_hardware.add_hardware_listeners()
# --------------------------------------------------------------------------------------------------------
# Poly Globals
# default connections, in 1, delay 1, in 1 to cab 1
# delay 1 to reverb 1
# reverb 1 to cab 1
# source_port_names = {"In 1": ("system", "capture_1"),
#     "In 2": ("system", "capture_2"),
#     "In 3": ("system", "capture_3"),
#     "In 4": ("system", "capture_4"),
#     "Delay 1 Out": ("delay1", "Left Out")}

output_port_names = {"Out 1": ("system", "playback_3"),
    "Out 2": ("system", "playback_4"),
    "Out 3": ("system", "playback_6"),
    "Out 4": ("system", "playback_8"),
    "Delay 1 In": ("delay1", "in0"),
    "Delay 2 In": ("delay2", "in0"),
    "Delay 3 In": ("delay3", "in0"),
    "Delay 4 In": ("delay4", "in0"),
    "Cab": ("cab", "In"),
    "Reverb": ("eq2", "In"),
    }
# inv_source_port_names = dict({(v, k) for k,v in source_port_names.items()})
inv_output_port_names = dict({(v, k) for k,v in output_port_names.items()})

portMap = {}
invPortMap = {}
# plugin names to Carla IDs
pluginMap = {}
#
parameterMap = {}
current_connections = {} # these are group port group port to connection id pairs #TODO remove stale
pending_connect = queue.Queue()
ui_messages = Queue()
core_messages = Queue()

def send_ui_message(command, args):
    ui_messages.put((command, args))


# --------------------------------------------------------------------------------------------------------

def set_active(effect, is_active):
    # print(effect, " active state is ", bool(is_active))
    if ("delay" in effect) or (effect == "reverb") or (effect == "cab"):
        host.set_volume(pluginMap[effect], is_active)
    else:
        host.set_drywet(pluginMap[effect], is_active) # full wet if active else full dry
    plugin_state[effect] = is_active


def knob_change(effect_name, parameter, value):
    # print(x, y, z)
    if effect_name in pluginMap:
        if parameter == "carla_level":
            host.set_volume(pluginMap[effect_name], value)
        else:
            host.set_parameter_value(pluginMap[effect_name],
                    parameterMap[effect_name][parameter], value)
    else:
        print("effect not found")

def add_connection(effect, source_port, x):
    host.patchbay_connect(patchbay_external, portMap[effect]["group"],
            portMap[effect]["ports"][source_port],
            portMap[output_port_names[x][0]]["group"],
            portMap[output_port_names[x][0]]["ports"][output_port_names[x][1]])

def add_connection_pair(source_pair, target_pair):
    host.patchbay_connect(patchbay_external, portMap[source_pair[0]]["group"],
            portMap[source_pair[0]]["ports"][source_pair[1]],
            portMap[target_pair[0]]["group"],
            portMap[target_pair[0]]["ports"][target_pair[1]])

def remove_connection(effect, source_port, x):
    host.patchbay_disconnect(patchbay_external, current_connections[(portMap[effect]["group"],
            portMap[effect]["ports"][source_port],
            portMap[output_port_names[x][0]]["group"],
            portMap[output_port_names[x][0]]["ports"][output_port_names[x][1]])])

def toggle_enabled(effect):
    is_active = not plugin_state[effect]
    set_active(effect, is_active)

# def update_ir(is_reverb, ir_file):
#     print("updating ir", ir_file)
#     current_ir_file = ir_file[7:] # strip file:// prefix
#     # cause call file callback
#     # by calling show GUI
#     if is_reverb:
#         # kill existing jconvolver
#         # write jconvolver file
#         # start jconvolver
#         if is_loading["reverb"]
#             return
#         is_loading["reverb"] = True
#         to_ui_update_value("reverb", "ir", ir_file)
#         # host.show_custom_ui(pluginMap["reverb"], True)
#         start_jconvolver.generate_reverb_conf(current_ir_file)
#         # host.set_program(pluginMap["reverb"], 0)
#     else:
#         if is_loading["cab"]
#             return
#         is_loading["cab"] = True
#         to_ui_update_value("cab", "ir", ir_file)
#         start_jconvolver.generate_cab_conf(current_ir_file)


def map_parameter(source, effect_name, parameter, rmin=0, rmax=1):
    if source == "left" or source == "right":
        # mapping and encoder
        set_knob_current_effect(source, effect_name, parameter, rmin, rmax)
        # print("mapping knob core")

def map_parameter_to_lfo(source, effect_name, parameter, cc_num):
    # we're mapping to LFO
    # print("mapping lfo core", source, effect_name, parameter, cc_num)
    host.set_parameter_midi_cc(pluginMap[effect_name], parameterMap[effect_name][parameter],
            cc_num)
    host.set_parameter_midi_channel(pluginMap[effect_name], parameterMap[effect_name][parameter], midi_channel - 1)
    # connect ports
    host.patchbay_connect(patchbay_external, portMap[source]["group"],
            portMap[source]["ports"]["events-out"],
            portMap[effect_name]["group"],
            portMap[effect_name]["ports"]["events-in"])


def unmap_parameter(effect_name, parameter):
    host.set_parameter_midi_cc(pluginMap[effect_name], parameterMap[effect_name][parameter],
                0)

def map_parameter_cc(effect_name, parameter, cc, connect_ports=True):
    host.set_parameter_midi_cc(pluginMap[effect_name], parameterMap[effect_name][parameter],
            cc)
    host.set_parameter_midi_channel(pluginMap[effect_name], parameterMap[effect_name][parameter], midi_channel - 1)
    # connect ports
    # ("ttymidi", "MIDI_in")
    if connect_ports:
        host.patchbay_connect(patchbay_external, portMap["ttymidi"]["group"],
                portMap["ttymidi"]["ports"]["MIDI_in"],
                portMap[effect_name]["group"],
                portMap[effect_name]["ports"]["events-in"])


# @Slot()
# def ui_copy_irs(self):
#     print("copy irs from USB")
#     # could convert any that aren't 48khz.
#     # instead we just only copy ones that are
#     command_reverb = """cd /media/reverbs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/audio/reverbs --parents"""
#     command_cab = """cd /media/cabs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/audio/cabs --parents"""
#     # copy all wavs in /usb/reverbs and /usr/cabs to /audio/reverbs and /audio/cabs
#     command_status[0].value = -1
#     command_status[1].value = -1
#     command_status[0].value = subprocess.call(command_reverb, shell=True)
#     command_status[1].value = subprocess.call(command_cab, shell=True)

# @Slot()
# def import_presets(self):
#     print("copy presets from USB")
#     # could convert any that aren't 48khz.
#     # instead we just only copy ones that are
#     command = """cd /media/presets; find . -iname "*.json" -type f -print0 | xargs -0 cp --target-directory=/presets --parents"""
#     command_status[0].value = subprocess.call(command, shell=True)

# @Slot()
# def export_presets(self):
#     print("copy presets to USB")
#     # could convert any that aren't 48khz.
#     # instead we just only copy ones that are
#     command = """cd /presets; mkdir -p /media/presets; find . -iname "*.json" -type f -print0 | xargs -0 cp --target-directory=/media/presets --parents"""
#     command_status[0].value = subprocess.call(command, shell=True)

# @Slot()
# def ui_update_firmware(self):
#     print("Updating firmware")
#     # dpkg the debs in the folder
#     command = """sudo dpkg -i /media/*.deb"""
#     command_status[0].value = subprocess.call(command, shell=True)

def enable_ableton_link(enable):
    extra = ":link:" if enable else ""
    host.transportExtra = extra
    host.set_engine_option(ENGINE_OPTION_TRANSPORT_MODE,
                                host.transportMode,
                                host.transportExtra)

def set_channel(channel, effect_params):
    for effect, parameter in effect_params:
        host.set_parameter_midi_channel(pluginMap[effect], parameterMap[effect][parameter], channel - 1)
    global midi_channel
    midi_channel = channel

def engineCallback(host, action, pluginId, value1, value2, value3, valuef, valueStr):
    valueStr = charPtrToString(valueStr)
    if action == ENGINE_CALLBACK_PATCHBAY_PORT_ADDED:
        # print("patchbay port added", pluginId, value1, value2, valueStr)
        if pluginId in invPortMap:
            portMap[invPortMap[pluginId]]["ports"][valueStr] = value1
            if (invPortMap[pluginId], valueStr) in inv_output_port_names:
                send_ui_message("add_port", (inv_output_port_names[(invPortMap[pluginId], valueStr)], ))
            if "jconvolver" in  portMap and pluginId == portMap["jconvolver"]["group"]:
                # auto connect jconvolver ports
                # print("auto connect jconvolver", pluginId, value1, value2, valueStr)
                if valueStr == "OutL":
                     pending_connect.put("OutL")
                elif valueStr == "OutR":
                     pending_connect.put("OutR")
                elif valueStr == "In":
                     pending_connect.put("ReverbIn")
            if "jconvolver_cab" in  portMap and pluginId == portMap["jconvolver_cab"]["group"]:
                # auto connect jconvolver ports
                # print("auto connect jconv cab", pluginId, value1, value2, valueStr)
                if valueStr == "Out":
                     pending_connect.put("Out")
                elif valueStr == "In":
                     pending_connect.put("CabIn")
        else:
            print("got port without client")
    elif action == ENGINE_CALLBACK_PATCHBAY_CLIENT_ADDED:
        # print("patchbay client added", pluginId, value1, value2, valueStr)
        portMap[valueStr] = {"group" : pluginId, "ports": {}}
        invPortMap[pluginId] = valueStr
    elif action == ENGINE_CALLBACK_PLUGIN_ADDED:
        pluginMap[valueStr] = pluginId
        pluginParams = {}
        for i in range(host.get_parameter_count(pluginId)):
             p = host.get_parameter_info(pluginId, i)
             pluginParams[p["symbol"]] = i
        parameterMap[valueStr] = pluginParams
        # print("plugin added", pluginId, valueStr)
    # elif action == ENGINE_CALLBACK_IDLE:
    #     print("processing GUI events in CALLBACK")
    #     app.processEvents()
    elif action == ENGINE_CALLBACK_PATCHBAY_CLIENT_DATA_CHANGED:
        pass
        # print("patchbay data changed", pluginId, value1, value2)
    elif action == ENGINE_CALLBACK_PATCHBAY_CONNECTION_ADDED:
        gOut, pOut, gIn, pIn = [int(i) for i in valueStr.split(":")] # FIXME
        current_connections[(gOut, pOut, gIn, pIn)] = pluginId
        # print("patchbay connection added", pluginId, gOut, pOut, gIn, pIn)
        # host.PatchbayConnectionAddedCallback.emit(pluginId, gOut, pOut, gIn, pIn)
    # elif action == ENGINE_CALLBACK_PATCHBAY_CONNECTION_REMOVED:
    #     pass
        # host.PatchbayConnectionRemovedCallback.emit(pluginId, value1, value2)
        # print("patchbay connection removed", pluginId, value1, value2)

    # if action == ENGINE_CALLBACK_ENGINE_STARTED:
    #     host.processMode   = value1
    #     host.transportMode = value2
    # elif action == ENGINE_CALLBACK_PROCESS_MODE_CHANGED:
    #     host.processMode   = value1
    # elif action == ENGINE_CALLBACK_TRANSPORT_MODE_CHANGED:
    #     print("transport change", value1, valueStr)
        # host.transportMode  = value1
        # host.transportExtra = valueStr

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
        # def slot_handlePatchbayPortAddedCallback(clientId, portId, portFlags, portName):
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


def next_preset():
    # need to have some kind of mapping for all presets so you can assign numbers to them
    pass

def auto_connect_ports():
    try:
        while not gCarla.term:
            valueStr = pending_connect.get(block=False)
            if valueStr == "OutL":
                # connect to "postreverb:In Left" 
                host.patchbay_connect(patchbay_external, portMap["jconvolver"]["group"],
                        portMap["jconvolver"]["ports"]["OutL"],
                        portMap["postreverb"]["group"],
                        portMap["postreverb"]["ports"]["In Left"])
            elif valueStr == "OutR":
                # connect to "postreverb:In Left" 
                host.patchbay_connect(patchbay_external, portMap["jconvolver"]["group"],
                        portMap["jconvolver"]["ports"]["OutR"],
                        portMap["postreverb"]["group"],
                        portMap["postreverb"]["ports"]["In Right"])
                # if we had the loading screen up, we are now loaded
                send_ui_message("is_loading", ("reverb", ))
            elif valueStr == "ReverbIn":
                # connect to "postreverb:In Left" 
                host.patchbay_connect(patchbay_external,
                        portMap["reverb"]["group"],
                        portMap["reverb"]["ports"]["Out"],
                        portMap["jconvolver"]["group"],
                        portMap["jconvolver"]["ports"]["In"])
            elif valueStr == "CabIn":
                # connect to "postreverb:In Left" 
                host.patchbay_connect(patchbay_external,
                        portMap["cab"]["group"],
                        portMap["cab"]["ports"]["Out"],
                        portMap["jconvolver_cab"]["group"],
                        portMap["jconvolver_cab"]["ports"]["In"])
            elif valueStr == "Out":
                # connect to "postreverb:In Left" 
                host.patchbay_connect(patchbay_external, portMap["jconvolver_cab"]["group"],
                        portMap["jconvolver_cab"]["ports"]["Out"],
                        portMap["postcab"]["group"],
                        portMap["postcab"]["ports"]["In"])
                # if we had the loading screen up, we are now loaded
                send_ui_message("is_loading", ("cab", ))
    except queue.Empty:
        pass


binaryDir = "/git_repos/Carla/bin"
host = CarlaHostDLL("/git_repos/Carla/bin/libcarla_standalone2.so", False)
host.set_engine_option(ENGINE_OPTION_PATH_BINARIES, 0, binaryDir)
# host.set_engine_callback(lambda h,a,p,v1,v2,v3,vs: engineCallback(host,a,p,v1,v2,v3,vs))
host.set_engine_callback(lambda h,a,p,v1,v2,v3,vf,vs: engineCallback(host,a,p,v1,v2,v3,vf,vs))

if not host.engine_init("JACK", "PolyCarla"):
    print("Engine failed to initialize, possible reasons:\n%s" % host.get_last_error())
    exit(1)


host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "delay1", "http://polyeffects.com/lv2/digit_delay",  0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "delay2", "http://polyeffects.com/lv2/digit_delay",  0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "delay3", "http://polyeffects.com/lv2/digit_delay",  0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "delay4", "http://polyeffects.com/lv2/digit_delay",  0, None, 0)
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "reverb", "http://drobilla.net/plugins/fomp/reverb", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "reverb", "http://lv2plug.in/plugins/eg-amp", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "postreverb", "http://gareus.org/oss/lv2/stereoroute", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "cab", "http://lv2plug.in/plugins/eg-amp", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "postcab", "http://lv2plug.in/plugins/eg-amp", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "mixer", "http://gareus.org/oss/lv2/matrixmixer#i4o4", 0, None, 0)
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "", "http://gareus.org/oss/lv2/matrixmixer#i4o4", effects.cab, None, 0)
##### ---- Effects
# tape/tube http://moddevices.com/plugins/tap/tubewarmth
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "tape1", "http://moddevices.com/plugins/tap/tubewarmth", 0, None, 0)

host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "reverse1", "http://moddevices.com/plugins/tap/reflector", 0, None, 0)
# sigmoid  http://moddevices.com/plugins/tap/sigmoid
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "sigmoid1", "http://moddevices.com/plugins/tap/sigmoid", 0, None, 0)
# bitcrusher 
# plugins for reverb
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "reverse2", "http://moddevices.com/plugins/tap/reflector", 0, None, 0)

host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "eq2", "http://gareus.org/oss/lv2/fil4#mono", 0, None, 0)
# filter http://drobilla.net/plugins/fomp/mvclpf4
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "filter1", "http://drobilla.net/plugins/fomp/mvclpf1", 0, None, 0)
# eq 
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "cab", "http://guitarix.sourceforge.net/plugins/gx_cabinet#CABINET", 0, None, 0)
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "cab", "http://gareus.org/oss/lv2/convoLV2#Mono", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "lfo1", "http://polyeffects.com/lv2/polylfo", 0, None, 0)
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "lfo2", "http://polyeffects.com/lv2/polylfo", 0, None, 0)
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "lfo3", "http://polyeffects.com/lv2/polylfo", 0, None, 0)
# host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "lfo4", "http://polyeffects.com/lv2/polylfo", 0, None, 0)
host.add_plugin(BINARY_NATIVE, PLUGIN_LV2, None, "mclk", "http://gareus.org/oss/lv2/mclk", 0, None, 0)

signal(SIGINT,  signalHandler)
signal(SIGTERM, signalHandler)

class Encoder():
    # name, min, max, value
    def __init__(self, starteffect="", startparameter=""):
        self.effect = starteffect
        self.parameter = startparameter
        self.speed = 1
        self.rmin = 0
        self.rmax = 1


knob_map = {"left": Encoder("delay1", "Delay_1"), "right": Encoder("delay1", "Feedback_4")}

all_effects = [("delay1", True), ("delay2", True), ("delay3", True),
        ("delay4", True), ("reverb", True), ("postreverb", True), ("mixer", True),
        ("tape1", False), ("reverse1", False),
        ("sigmoid1", False), ("eq2", True), ("cab", True), ("postcab", True)]
plugin_state = dict({(k, initial) for k, initial in all_effects})
plugin_state["global"] = True

current_bpm = 120
current_preset = "Default Preset"
command_status = [-1, -1]
midi_channel = 1
# is_loading = {"reverb":False, "cab":False}

mixer_is_connected = False
effects_are_connected = False
knobs_are_initial_mapped  = False

# def translate_range(value, leftMin, leftMax, rightMin, rightMax):
#     # Figure out how 'wide' each range is
#     leftSpan = leftMax - leftMin
#     rightSpan = rightMax - rightMin

#     # Convert the left range into a 0-1 range (float)
#     valueScaled = float(value - leftMin) / float(leftSpan)

#     # Convert the 0-1 range into a value in the right range.
#     return rightMin + (valueScaled * rightSpan)

# def map_ui_parameter_lv2_value(effect, parameter, in_min, in_max, value):
#     # map UI or hardware range to effect range
#     # in_min / in_max are what the knob / ui generates
#     #   from numpy import interp
#     #  interp(256,[1,512],[5,10])
#     out_min = effect_parameter_data[effect][parameter].rmin
#     out_max = effect_parameter_data[effect][parameter].rmax
#     return translate_range(value, in_min, in_max, out_min, out_max)

# def map_lv2_value_to_ui_knob(effect, parameter, in_min, in_max, value):
#     # map UI or hardware range to effect range
#     # in_min / in_max are what the knob / ui generates
#     out_min = effect_parameter_data[effect][parameter].rmin
#     out_max = effect_parameter_data[effect][parameter].rmax
#     return translate_range(value, out_min, out_max, in_min, in_max)


def set_knob_current_effect(knob, effect, parameter, rmin=0, rmax=1):
    # get current value and update encoder / cache.
    knob_map[knob].effect = effect
    knob_map[knob].parameter = parameter
    knob_map[knob].rmin = rmin
    knob_map[knob].rmax = rmax

def handle_encoder_change(is_left, change):
    # increase or decrease the current knob value depending on knob speed
    # knob_value = knob_value + (change * knob_speed)
    normal_speed = 48.0
    knob = "right"
    if is_left:
        knob = "left"
    knob_effect = knob_map[knob].effect
    knob_parameter = knob_map[knob].parameter
    value = host.get_current_parameter_value (pluginMap[knob_effect],
                    parameterMap[knob_effect][knob_parameter])
    # base speed * speed multiplier
    base_speed = (abs(knob_map[knob].rmin) + abs(knob_map[knob].rmax)) / normal_speed
    value = value + (change * knob_map[knob].speed * base_speed)
    # print("knob value is", value)
    # knob change handles clamping
    knob_change(knob_effect, knob_parameter, value)
    send_ui_message("value_change", (knob_effect, knob_parameter, value))

def update_delay_bpms():
    for effect_name in ["delay1", "delay2", "delay3", "delay4"]:
        knob_change(effect_name, "BPM_0", current_bpm)

def set_bpm(bpm):
    global current_bpm
    current_bpm = bpm
    update_delay_bpms()
    host.transport_bpm(bpm)
    send_ui_message("bpm_change", (bpm, ))
    # print("setting tempo", bpm)


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
        if bpm > 30 and bpm < 250:
            # set host BPM
            set_bpm(bpm)

    # record start time
    start_tap_time = current_tap

def handle_next():
    # disable delay
    toggle_enabled("delay1")
    toggle_enabled("delay2")
    toggle_enabled("delay3")
    toggle_enabled("delay4")
    send_ui_message("set_plugin_state", ("delay1", plugin_state["delay1"]))
    send_ui_message("set_plugin_state", ("delay2", plugin_state["delay2"]))
    send_ui_message("set_plugin_state", ("delay3", plugin_state["delay3"]))
    send_ui_message("set_plugin_state", ("delay4", plugin_state["delay4"]))

def handle_bypass():
    # global bypass
    plugin_state["global"] = not plugin_state["global"]
    send_ui_message("set_plugin_state", ("global", plugin_state["global"] ))
    if plugin_state["global"]:
        pedal_hardware.effect_on()
    else:
        pedal_hardware.effect_off()

def process_core_messages():
    # pop from queue
    try:
        while not gCarla.term:
            m = core_messages.get(block=False)
            if m[0] == "add_connection_pair":
                add_connection_pair(*m[1])
            elif m[0] == "add_connection":
                add_connection(*m[1])
            elif m[0] == "map_parameter":
                map_parameter(*m[1])
            elif m[0] == "map_parameter_to_lfo":
                map_parameter_to_lfo(*m[1])
            elif m[0] == "map_parameter_cc":
                map_parameter_cc(*m[1])
            elif m[0] == "unmap_parameter":
                unmap_parameter(*m[1])
            elif m[0] == "set_bpm":
                set_bpm(*m[1])
            elif m[0] == "remove_connection":
                remove_connection(*m[1])
            elif m[0] == "knob_change":
                knob_change(*m[1])
            elif m[0] == "toggle_enabled":
                toggle_enabled(*m[1])
            elif m[0] == "set_active":
                set_active(*m[1])
            elif m[0] == "set_channel":
                set_channel(*m[1])
    except queue.Empty:
        pass

# def connect_ports(source_effect, source_port, target_effect, target_port):
#     host.patchbay_connect(patchbay_external, portMap["mixer"]["group"],
#             portMap["mixer"]["ports"][source_port],
#             portMap["system"]["group"],
#             portMap["system"]["ports"][output_port])
#     pass

pedal_hardware.tap_callback = handle_tap
pedal_hardware.next_callback = handle_next
pedal_hardware.bypass_callback = handle_bypass
pedal_hardware.encoder_change_callback = handle_encoder_change
patchbay_external = False

p = Process(name="digit_frontend.py", target=digit_frontend.ui_worker, args=(ui_messages, core_messages))
p.start()

while host.is_engine_running() and not gCarla.term:
    # print("engine is idle")
    host.engine_idle()
    # print("processing GUI events in CALLBACK")
    sleep(0.01)
    # wait until the last of our plugins is added, then connect them if they haven't been connected yet
    # default routing is input 1 to delay 1 to reverb to cab to out
    # check if encoders have changed
    if (not mixer_is_connected) and "mixer" in portMap:
        # mixer 1-4 to outputs
        for source_port, output_port in [("Audio Output 1", "playback_3"), ("Audio Output 2", "playback_4"),
                ("Audio Output 3", "playback_6"), ("Audio Output 4", "playback_8") ]:
            host.patchbay_connect(patchbay_external, portMap["mixer"]["group"],
                    portMap["mixer"]["ports"][source_port],
                    portMap["system"]["group"],
                    portMap["system"]["ports"][output_port])
        for source_port, output_port in [("capture_2", "Audio Input 1"),
                ("capture_4", "Audio Input 2"), ("capture_3", "Audio Input 3"),
                ("capture_5", "Audio Input 4")]:
            host.patchbay_connect(patchbay_external, portMap["system"]["group"],
                    portMap["system"]["ports"][source_port],
                    portMap["mixer"]["group"],
                    portMap["mixer"]["ports"][output_port])
        mixer_is_connected = True
    if (not effects_are_connected) and "mclk" in portMap:
        for source_pair, output_pair in [(("delay1", "out0"), ("tape1","Input")),
                (("tape1", "Output"), ("reverse1", "Input")),
                (("reverse1", "Output"), ("sigmoid1", "Input")),
                (("eq2", "Out"), ("reverb", "In")),
                (("ttymidi", "MIDI_in"), ("ttymidi", "MIDI_out")),
                (("mclk", "events-out"), ("ttymidi", "MIDI_out")),
                ]:
            source_effect, source_port = source_pair
            output_effect, output_port = output_pair
            host.patchbay_connect(patchbay_external, portMap[source_effect]["group"],
                    portMap[source_effect]["ports"][source_port],
                    portMap[output_effect]["group"],
                    portMap[output_effect]["ports"][output_port])
        for effect in ["tape1", "reverse1", "sigmoid1"]:
            # set to all dry at start
            set_active(effect, False)
        effects_are_connected = True

    if (not knobs_are_initial_mapped):
        if "delay1" in portMap:
            set_knob_current_effect("left", "delay1", "Delay_1")
            set_knob_current_effect("right", "delay1", "Feedback_4")
            host.transport_play()
            knobs_are_initial_mapped = True
    else:
        pedal_hardware.process_input()
        process_core_messages()
        auto_connect_ports()

pedal_hardware.EXIT_THREADS = True
host.set_engine_about_to_close()
send_ui_message("exit", ("exit", ))
p.terminate()
p.join()

while True:
    try:
        ui_messages.get(block=False)
    except queue.Empty:
        break

while True:
    try:
        core_messages.get(block=False)
    except queue.Empty:
        break

ui_messages.close()
ui_messages.join_thread()
core_messages.close()
core_messages.join_thread()
# print("exiting core")

if not gCarla.term:
    print("Engine closed abruptely")
else:
    print("Normal exit")

if not host.engine_close():
    print("Engine failed to close, possible reasons:\n%s" % host.get_last_error())
else:
    print("Engine Closed")
exit(1)
