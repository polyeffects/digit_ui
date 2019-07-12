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
import sys, time, json, os.path, os, subprocess, queue
from collections import defaultdict
##### Hardware backend
# --------------------------------------------------------------------------------------------------------
import pedal_hardware, start_jconvolver
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
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
current_connection_pairs_poly = set()
current_midi_connection_pairs_poly = set()
current_ir_file = None

# --------------------------------------------------------------------------------------------------------
source_ports = ["sigmoid1:Output", "delay2:out0","delay3:out0", "delay4:out0",
    "postreverb:Out Left", "postreverb:Out Right", "system:capture_2", "system:capture_4",
    "system:capture_3", "system:capture_5", "postcab:Out"]
available_port_models = dict({(k, QStringListModel()) for k in source_ports})
used_port_models = dict({(k, QStringListModel()) for k in available_port_models.keys()})
# XXX temp, until I fix bypassing


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
    plugin_state[effect].value = is_active

def clamp(v, min_value, max_value):
    return max(min(v, max_value), min_value)

class PolyEncoder(QObject):
    # name, min, max, value
    def __init__(self, starteffect="", startparameter=""):
        QObject.__init__(self)
        self.effectval = starteffect
        self.parameterval = startparameter
        self.speed = 1
        self.value = 1

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

def time_to_tempo_text(v):
    if v >= 1:
        return (1, "1")
    elif v > 0.75:
        return (0.75, "1/2.")
    elif v > 0.5:
        return (0.5, "1/2")
    elif v > 0.33:
        return (0.33, "1/2t")
    elif v > 0.25:
        return (0.25, "1/4")
    elif v > 0.125:
        return (0.125, "1/8")
    elif v > 1/16.0:
        return (1/16.0, "1/16")
    elif v > 1/32.0:
        return (1/32.0, "1/32")
    else: #hif v > 1/64.0:
        return (1/64.0, "1/64")
    # lv2:scalePoint [rdfs:label "Dotted1/2note"; rdf:value 1];
    # lv2:scalePoint [rdfs:label "1/2note"; rdf:value 2];
    # lv2:scalePoint [rdfs:label "1/2notetriplets"; rdf:value 3];
    # lv2:scalePoint [rdfs:label "Dotted1/4note"; rdf:value 4];
    # lv2:scalePoint [rdfs:label "1/4note"; rdf:value 5];
    # lv2:scalePoint [rdfs:label "1/4notetriplets"; rdf:value 6];
    # lv2:scalePoint [rdfs:label "Dotted1/8note"; rdf:value 7];
    # lv2:scalePoint [rdfs:label "1/8note"; rdf:value 8];
    # lv2:scalePoint [rdfs:label "1/8notetriplets"; rdf:value 9];
    # lv2:scalePoint [rdfs:label "Dotted1/16note"; rdf:value 10];
    # lv2:scalePoint [rdfs:label "1/16note"; rdf:value 11];
    # lv2:scalePoint [rdfs:label "1/16notetriplets"; rdf:value 12];
    # lv2:scalePoint [rdfs:label "Dotted1/32note"; rdf:value 13];
    # lv2:scalePoint [rdfs:label "1/32note"; rdf:value 14];
    # lv2:scalePoint [rdfs:label "1/32notetriplets"; rdf:value 15];
    # lv2:scalePoint [rdfs:label "Dotted1/64note"; rdf:value 16];
    # lv2:scalePoint [rdfs:label "1/64note"; rdf:value 17];
    # lv2:scalePoint [rdfs:label "1/64notetriplets"; rdf:value 18];

class Knobs(QObject):
    """Basically all functions for QML to call"""

    def __init__(self):
        QObject.__init__(self)
        self.waitingval = ""

    @Slot(str, str, 'double')
    def ui_knob_change(self, effect_name, parameter, value):
        # print(x, y, z)
        if effect_name in pluginMap:
            effect_parameter_data[effect_name][parameter].value = value
            if parameter == "carla_level":
                host.set_volume(pluginMap[effect_name], value)
            else:
                host.set_parameter_value(pluginMap[effect_name],
                        parameterMap[effect_name][parameter], value)
        else:
            print("effect not found")

    @Slot(str, str, str)
    def ui_add_connection(self, effect, source_port, x, midi=False):
        effect_source = effect + ":" + source_port
        if not midi:
            remove_row(available_port_models[effect_source], x)
            insert_row(used_port_models[effect_source], x)
        current_connection_pairs_poly.add((effect_source, x))
        # print("portMap is", portMap)

        host.patchbay_connect(patchbay_external, portMap[effect]["group"],
                portMap[effect]["ports"][source_port],
                portMap[output_port_names[x][0]]["group"],
                portMap[output_port_names[x][0]]["ports"][output_port_names[x][1]])
        print(x)

    @Slot(str, str, str)
    def ui_remove_connection(self, effect, source_port, x):
        effect_source = effect + ":" + source_port
        remove_row(used_port_models[effect_source], x)
        insert_row(available_port_models[effect_source], x)
        current_connection_pairs_poly.remove((effect_source, x))

        host.patchbay_disconnect(patchbay_external, current_connections[(portMap[effect]["group"],
                portMap[effect]["ports"][source_port],
                portMap[output_port_names[x][0]]["group"],
                portMap[output_port_names[x][0]]["ports"][output_port_names[x][1]])])
        print(x)

    @Slot(str)
    def toggle_enabled(self, effect):
        print("toggling", effect)
        # host.set_active(pluginMap[effect], not bool(host.get_internal_parameter_value(pluginMap[effect], PARAMETER_ACTIVE)))
        # active = host.get_internal_parameter_value(pluginMap[effect], PARAMETER_ACTIVE))
        is_active = not plugin_state[effect].value
        set_active(effect, is_active)

    @Slot(bool, str)
    def update_ir(self, is_reverb, ir_file):
        print("updating ir", ir_file)
        global current_ir_file
        current_ir_file = ir_file[7:] # strip file:// prefix
        # cause call file callback
        # by calling show GUI
        if is_reverb:
            # kill existing jconvolver
            # write jconvolver file
            # start jconvolver
            if is_loading["reverb"]:
                return
            is_loading["reverb"] = True
            effect_parameter_data["reverb"]["ir"].name = ir_file
            # host.show_custom_ui(pluginMap["reverb"], True)
            start_jconvolver.generate_reverb_conf(current_ir_file)
            # host.set_program(pluginMap["reverb"], 0)
        else:
            if is_loading["reverb"]:
                return
            is_loading["cab"] = True
            effect_parameter_data["cab"]["ir"].name = ir_file
            start_jconvolver.generate_cab_conf(current_ir_file)



    @Slot(str, str)
    def map_parameter(self, effect_name, parameter):
        if self.waiting == "left" or self.waiting == "right":
            # mapping and encoder
            set_knob_current_effect(self.waiting, effect_name, parameter)
        else:
            # we're mapping to LFO
            host.set_parameter_midi_cc(pluginMap[effect_name], parameterMap[effect_name][parameter],
                    effect_parameter_data[self.waiting]["cc_num"].value)
            # connect ports
            host.patchbay_connect(patchbay_external, portMap[self.waiting]["group"],
                    portMap[self.waiting]["ports"]["events-out"],
                    portMap[effect_name]["group"],
                    portMap[effect_name]["ports"]["events-in"])
            effect_parameter_data[effect_name][parameter].assigned_cc = effect_parameter_data[self.waiting]["cc_num"].value
            current_midi_connection_pairs_poly.add(((self.waiting, "events-out"), (effect_name, "events-in")))
        self.waiting = ""

    @Slot(str, str)
    def unmap_parameter(self, effect_name, parameter):
            host.set_parameter_midi_cc(pluginMap[effect_name], parameterMap[effect_name][parameter],
                    0)
            effect_parameter_data[effect_name][parameter].assigned_cc = None

    @Slot(str, str, int)
    def map_parameter_cc(self, effect_name, parameter, cc):
        host.set_parameter_midi_cc(pluginMap[effect_name], parameterMap[effect_name][parameter],
                cc)
        host.set_parameter_midi_channel(pluginMap[effect_name], parameterMap[effect_name][parameter], midi_channel.value)
        # connect ports
        # ("ttymidi", "MIDI_in")
        host.patchbay_connect(patchbay_external, portMap["ttymidi"]["group"],
                portMap["ttymidi"]["ports"]["MIDI_in"],
                portMap[effect_name]["group"],
                portMap[effect_name]["ports"]["events-in"])
        effect_parameter_data[effect_name][parameter].assigned_cc = cc
        current_midi_connection_pairs_poly.add((("ttymidi", "MIDI_in"), (effect_name, "events-in")))

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

    @Slot(str)
    def ui_save_preset(self, preset_name):
        print("saving", preset_name)
        # TODO add folders
        outfile = "/presets/"+preset_name+".json"
        current_preset.name = preset_name
        save_preset(outfile)

    @Slot(str)
    def ui_load_preset_by_name(self, preset_file):
        print("loading", preset_file)
        outfile = preset_file[7:] # strip file:// prefix
        load_preset(outfile)
        update_counter.value+=1

    @Slot()
    def ui_copy_irs(self):
        print("copy irs from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command_reverb = """cd /media/reverbs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/audio/reverbs --parents"""
        command_cab = """cd /media/cabs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/audio/cabs --parents"""
        # copy all wavs in /usb/reverbs and /usr/cabs to /audio/reverbs and /audio/cabs
        command_status[0].value = -1
        command_status[1].value = -1
        command_status[0].value = subprocess.call(command_reverb, shell=True)
        command_status[1].value = subprocess.call(command_cab, shell=True)

    @Slot()
    def import_presets(self):
        print("copy presets from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """cd /media/presets; find . -iname "*.json" -type f -print0 | xargs -0 cp --target-directory=/presets --parents"""
        command_status[0].value = subprocess.call(command, shell=True)

    @Slot()
    def export_presets(self):
        print("copy presets to USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """cd /presets; mkdir -p /media/presets; find . -iname "*.json" -type f -print0 | xargs -0 cp --target-directory=/media/presets --parents"""
        command_status[0].value = subprocess.call(command, shell=True)

    @Slot()
    def ui_update_firmware(self):
        print("Updating firmware")
        # dpkg the debs in the folder
        command = """sudo dpkg -i /media/*.deb"""
        command_status[0].value = subprocess.call(command, shell=True)

    @Slot(bool)
    def enable_ableton_link(self, enable):
        extra = ":link:" if enable else ""
        host.transportExtra = extra
        host.set_engine_option(ENGINE_OPTION_TRANSPORT_MODE,
                                    host.transportMode,
                                    host.transportExtra)

    @Slot(int)
    def set_channel(self, channel):
        for effect, parameters in effect_parameter_data.items():
            for param_name, p_value in parameters.items():
                if p_value.assigned_cc is not None:
                    host.set_parameter_midi_channel(pluginMap[effect], parameterMap[effect][param_name], channel)
        midi_channel.value = channel

def engineCallback(host, action, pluginId, value1, value2, value3, valuef, valueStr):
    valueStr = charPtrToString(valueStr)
    if action == ENGINE_CALLBACK_PATCHBAY_PORT_ADDED:
        print("patchbay port added", pluginId, value1, value2, valueStr)
        if pluginId in invPortMap:
            portMap[invPortMap[pluginId]]["ports"][valueStr] = value1
            for k, model in available_port_models.items():
                if (invPortMap[pluginId], valueStr) in inv_output_port_names:
                    if (((k.split(":")[0] == invPortMap[pluginId]) and
                            (invPortMap[pluginId] != "system"))) or \
                                    ((k.split(":")[0] == "sigmoid1") and \
                                    (invPortMap[pluginId] == "delay1")):
                        pass # don't allow effect to self connect
                    else:
                        # print("adding port:", invPortMap[pluginId], k)
                        insert_row(model, inv_output_port_names[(invPortMap[pluginId], valueStr)])
            if "jconvolver" in  portMap and pluginId == portMap["jconvolver"]["group"]:
                # auto connect jconvolver ports
                print("auto connect jconvolver", pluginId, value1, value2, valueStr)
                if valueStr == "OutL":
                     pending_connect.put("OutL")
                elif valueStr == "OutR":
                     pending_connect.put("OutR")
                elif valueStr == "In":
                     pending_connect.put("ReverbIn")
            if "jconvolver_cab" in  portMap and pluginId == portMap["jconvolver_cab"]["group"]:
                # auto connect jconvolver ports
                print("auto connect jconv cab", pluginId, value1, value2, valueStr)
                if valueStr == "Out":
                     pending_connect.put("Out")
                elif valueStr == "In":
                     pending_connect.put("CabIn")
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

def fileCallback(ptr, action, isDir, title, filter):
    title  = charPtrToString(title)
    filter = charPtrToString(filter)
    global current_ir_file
    global fileRet

    # if action == FILE_CALLBACK_OPEN:
    #     ret, ok = QFileDialog.getOpenFileName(gCarla.gui, title, "", filter) #, QFileDialog.ShowDirsOnly if isD ir else 0x0)
    # elif action == FILE_CALLBACK_SAVE:
    #     ret, ok = QFileDialog.getSaveFileName(gCarla.gui, title, "", filter, QFileDialog.ShowDirsOnly if isDir else 0x0)
    # else:
    #     ret, ok = ("", "")
    # check if a file is selected, and if we're setting reverb or cab IR

    if not current_ir_file:
        return None

    # FIXME
    fileRet = c_char_p(current_ir_file.encode("utf-8"))
    retval  = cast(byref(fileRet), POINTER(c_uintptr))
    return retval.contents.value

def save_preset(filename):
    # write all effect parameters
    output = {"effects":{}}
    output["midi_map"] = {}
    for effect, parameters in effect_parameter_data.items():
        output["effects"][effect] = {}
        # output["midi_map"][effect] = {}
        for param_name, p_value in parameters.items():
            if param_name == "ir":
                output["effects"][effect][param_name] = p_value.name
            else:
                output["effects"][effect][param_name] = p_value.value
            if p_value.assigned_cc is not None:
                if effect not in output["midi_map"]:
                    output["midi_map"][effect] = {}
                output["midi_map"][effect][param_name] = p_value.assigned_cc
    # write enabled state
    output["state"] = {k:v.value for k,v in plugin_state.items()}
    # write connections
    output["connections"] = tuple(current_connection_pairs_poly)
    output["midi_connections"] = tuple(current_midi_connection_pairs_poly)
    # write knob / midi mapping XXX
    output["knobs"] = {k:[v.effect, v.parameter] for k,v in knob_map.items()}
    # write bpm
    output["bpm"] = current_bpm.value
    with open(filename, "w") as f:
        json.dump(output, f)

def load_preset(filename):
    preset = {}
    with open(filename) as f:
        preset = json.load(f)
    current_preset.name = os.path.splitext(os.path.basename(filename))[0]
    # read all effect parameters
    for effect_name, effect_value in preset["effects"].items():
        for parameter_name, parameter_value in effect_value.items():
            # update changed
            if parameter_name == "ir":
                if effect_parameter_data[effect_name][parameter_name].name != parameter_value:
                    knobs.update_ir(effect_name == "reverb", parameter_value)
            else:
                if effect_parameter_data[effect_name][parameter_name].value != parameter_value:
                    print("loading parameter", effect_name, parameter_name, parameter_value)
                    knobs.ui_knob_change(effect_name, parameter_name, parameter_value)
                # remove all existing MIDI mapping
                if effect_parameter_data[effect_name][parameter_name].assigned_cc is not None:
                    knobs.unmap_parameter(effect_name, parameter_name)
    for effect_name, effect_value in preset["midi_map"].items():
        for parameter_name, parameter_value in effect_value.items():
            host.set_parameter_midi_cc(pluginMap[effect_name],
                    parameterMap[effect_name][parameter_name], value)
            effect_parameter_data[effect_name][parameter_name].assigned_cc = value
            host.set_parameter_midi_channel(pluginMap[effect_name], parameterMap[effect][parameter_name], midi_channel.value)
    # read enabled state
    for effect, is_active in preset["state"].items():
        if effect == "global":
            pass
        else:
            set_active(effect, is_active)
    # read connections
    preset_connections = set([tuple(a) for a in preset["connections"]])
    # remove connections that aren't in the new preset
    for source_port, target_port in (current_connection_pairs_poly-preset_connections):
        effect, source_p = source_port.split(":")
        knobs.ui_remove_connection(effect, source_p, target_port)
    # add connections that are in the new preset but not the old
    for source_port, target_port in (preset_connections - current_connection_pairs_poly):
        effect, source_p = source_port.split(":")
        knobs.ui_add_connection(effect, source_p, target_port)
    midi_connections = set([tuple(a) for a in preset["midi_connections"]])
    for source_pair, target_pair in midi_connections:
        host.patchbay_connect(patchbay_external, portMap[source_pair[0]]["group"],
                portMap[source_pair[0]]["ports"][source_pair[1]],
                portMap[target_pair[0]]["group"],
                portMap[target_pair[0]]["ports"][target_pair[1]])
    global current_midi_connection_pairs_poly
    current_midi_connection_pairs_poly = midi_connections
    # read knob mapping
    for knob, mapping in preset["knobs"].items():
        set_knob_current_effect(knob, mapping[0], mapping[1])
    # read bpm
    if current_bpm.value != preset["bpm"]:
        current_bpm.value = preset["bpm"]
        host.transport_bpm(preset["bpm"])

def next_preset():
    # need to have some kind of mapping for all presets so you can assign numbers to them
    pass

def auto_connect_ports():
    try:
        while True:
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
                is_loading["reverb"] = False
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
                is_loading["cab"] = False
    except queue.Empty:
        pass


binaryDir = "/git_repos/Carla/bin"
host = CarlaHostDLL("/git_repos/Carla/bin/libcarla_standalone2.so", False)
host.set_engine_option(ENGINE_OPTION_PATH_BINARIES, 0, binaryDir)
# host.set_engine_callback(lambda h,a,p,v1,v2,v3,vs: engineCallback(host,a,p,v1,v2,v3,vs))
host.set_engine_callback(lambda h,a,p,v1,v2,v3,vf,vs: engineCallback(host,a,p,v1,v2,v3,vf,vs))
host.set_file_callback(fileCallback)

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

# class Knobs(QObject):
#     """Output stuff on the console."""
#     @Slot(str, str, 'double')
#     def ui_knob_change(self, effect_name, parameter_id, value):
#         # print(x, y)
#         host.set_parameter_value(effects[effect_name], parameter_id, value)

###

knob_map = {"left": PolyEncoder("delay1", "Delay_1"), "right": PolyEncoder("delay1", "Feedback_4")}
lfos = []
pending_connect = queue.Queue()


for n in range(1):
    lfos.append({})
    lfos[n]["num_points"] = PolyValue("num_points", 1, 1, 16)
    lfos[n]["channel"] = PolyValue("channel", 1, 1, 16)
    lfos[n]["cc_num"] = PolyValue("cc_num", 102+n, 0, 127)
    for i in range(1,17):
        lfos[n]["time"+str(i)] = PolyValue("time"+str(i), 0, 0, 1)
        lfos[n]["value"+str(i)] = PolyValue("value"+str(i), 0, 0, 1)
        lfos[n]["style"+str(i)] = PolyValue("style"+str(i), 0, 0, 5)

# this is not great

effect_parameter_data = {"delay1": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
        "Delay_1" : PolyValue("Time", 0.500000, 0.001000, 1.000000),
        "Warp_2" : PolyValue("Warp", 0.000000, -1.000000, 1.000000),
        "DelayT60_3" : PolyValue("Glide", 0.500000, 0.000000, 100.000000),
        "Feedback_4" : PolyValue("Feedback", 0.300000, 0.000000, 1.000000),
        "Amp_5" : PolyValue("Level", 0.500000, 0.000000, 1.000000),
        "FeedbackSm_6" : PolyValue("Tone", 0.000000, 0.000000, 1.000000),
        "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
        "carla_level": PolyValue("level", 1, 0, 1)},
    "delay2": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
            "Delay_1" : PolyValue("Time", 0.500000, 0.001000, 1.000000),
            "Warp_2" : PolyValue("Warp", 0.000000, -1.000000, 1.000000),
            "DelayT60_3" : PolyValue("Glide", 0.500000, 0.000000, 100.000000),
            "Feedback_4" : PolyValue("Feedback", 0.300000, 0.000000, 1.000000),
            "Amp_5" : PolyValue("Level", 0.500000, 0.000000, 1.000000),
            "FeedbackSm_6" : PolyValue("Tone", 0.000000, 0.000000, 1.000000),
            "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
            "carla_level": PolyValue("level", 1, 0, 1)},
    "delay3": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
            "Delay_1" : PolyValue("Time", 0.500000, 0.001000, 1.000000),
            "Warp_2" : PolyValue("Warp", 0.000000, -1.000000, 1.000000),
            "DelayT60_3" : PolyValue("Glide", 0.500000, 0.000000, 100.000000),
            "Feedback_4" : PolyValue("Feedback", 0.300000, 0.000000, 1.000000),
            "Amp_5" : PolyValue("Level", 0.500000, 0.000000, 1.000000),
            "FeedbackSm_6" : PolyValue("Tone", 0.000000, 0.000000, 1.000000),
            "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
            "carla_level": PolyValue("level", 1, 0, 1)},
    "delay4": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
            "Delay_1" : PolyValue("Time", 0.500000, 0.001000, 1.000000),
            "Warp_2" : PolyValue("Warp", 0.000000, -1.000000, 1.000000),
            "DelayT60_3" : PolyValue("Glide", 0.500000, 0.000000, 100.000000),
            "Feedback_4" : PolyValue("Feedback", 0.300000, 0.000000, 1.000000),
            "Amp_5" : PolyValue("Level", 0.500000, 0.000000, 1.000000),
            "FeedbackSm_6" : PolyValue("Tone", 0.000000, 0.000000, 1.000000),
            "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
            "carla_level": PolyValue("level", 1, 0, 1)},
    "reverb": {"gain": PolyValue("gain", 0, -90, 24), "ir": PolyValue("/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1),
        "carla_level": PolyValue("level", 1, 0, 1)},
    "postreverb": {"routing": PolyValue("gain", 6, 0, 6), "carla_level": PolyValue("level", 1, 0, 1)},
    "mixer": {"mix_1_1": PolyValue("mix 1,1", 1, 0, 1), "mix_1_2": PolyValue("mix 1,2", 0, 0, 1),
        "mix_1_3": PolyValue("mix 1,3", 0, 0, 1),"mix_1_4": PolyValue("mix 1,4", 0, 0, 1),
        "mix_2_1": PolyValue("mix 2,1", 0, 0, 1),"mix_2_2": PolyValue("mix 2,2", 1, 0, 1),
        "mix_2_3": PolyValue("mix 2,3", 0, 0, 1),"mix_2_4": PolyValue("mix 2,4", 0, 0, 1),
        "mix_3_1": PolyValue("mix 3,1", 0, 0, 1),"mix_3_2": PolyValue("mix 3,2", 0, 0, 1),
        "mix_3_3": PolyValue("mix 3,3", 1, 0, 1),"mix_3_4": PolyValue("mix 3,4", 0, 0, 1),
        "mix_4_1": PolyValue("mix 4,1", 0, 0, 1),"mix_4_2": PolyValue("mix 4,2", 0, 0, 1),
        "mix_4_3": PolyValue("mix 4,3", 0, 0, 1),"mix_4_4": PolyValue("mix 4,4", 1, 0, 1)
        },
    "tape1": {"drive": PolyValue("drive", 5, 0, 10), "blend": PolyValue("tape vs tube", 10, -10, 10)},
    # "filter1": {"freq": PolyValue("cutoff", 440, 20, 15000, "log"), "res": PolyValue("resonance", 0, 0, 0.8)},
    "sigmoid1": {"Pregain": PolyValue("pre gain", 0, -90, 20), "Postgain": PolyValue("post gain", 0, -90, 20)},
    "reverse1": {"fragment": PolyValue("fragment", 1000, 100, 1600),
        "wet": PolyValue("wet", 0, -90, 20),
        "dry": PolyValue("dry", 0, -90, 20)},
    # "reverse2": {"fragment": PolyValue("fragment", 1000, 100, 1600),
    #     "wet": PolyValue("wet", 0, -90, 20),
    #     "dry": PolyValue("dry", 0, -90, 20)},
    "eq2": {
        "enable": PolyValue("Enable", 1.000000, 0.000000, 1.0),
        "gain": PolyValue("Gain", 0.000000, -18.000000, 18.000000),
        "HighPass": PolyValue("Highpass", 0.000000, 0.000000, 1.000000),
        "HPfreq": PolyValue("Highpass Frequency", 20.000000, 5.000000, 1250.000000),
        "HPQ": PolyValue("HighPass Resonance", 0.700000, 0.000000, 1.400000),
        "LowPass": PolyValue("Lowpass", 0.000000, 0.000000, 1.000000),
        "LPfreq": PolyValue("Lowpass Frequency", 20000.000000, 500.000000, 20000.000000),
        "LPQ": PolyValue("LowPass Resonance", 1.000000, 0.000000, 1.400000),
        "LSsec": PolyValue("Lowshelf", 1.000000, 0.000000, 1.000000),
        "LSfreq": PolyValue("Lowshelf Frequency", 80.000000, 25.000000, 400.000000),
        "LSq": PolyValue("Lowshelf Bandwidth", 1.000000, 0.062500, 4.000000),
        "LSgain": PolyValue("Lowshelf Gain", 0.000000, -18.000000, 18.000000),
        "sec1": PolyValue("Section 1", 1.000000, 0.000000, 1.000000),
        "freq1": PolyValue("Frequency 1", 160.000000, 20.000000, 2000.000000),
        "q1": PolyValue("Bandwidth 1", 0.600000, 0.062500, 4.000000),
        "gain1": PolyValue("Gain 1", 0.000000, -18.000000, 18.000000),
        "sec2": PolyValue("Section 2", 1.000000, 0.000000, 1.000000),
        "freq2": PolyValue("Frequency 2", 397.000000, 40.000000, 4000.000000),
        "q2": PolyValue("Bandwidth 2", 0.600000, 0.062500, 4.000000),
        "gain2": PolyValue("Gain 2", 0.000000, -18.000000, 18.000000),
        "sec3": PolyValue("Section 3", 1.000000, 0.000000, 1.000000),
        "freq3": PolyValue("Frequency 3", 1250.000000, 100.000000, 10000.000000),
        "q3": PolyValue("Bandwidth 3", 0.600000, 0.062500, 4.000000),
        "gain3": PolyValue("Gain 3", 0.000000, -18.000000, 18.000000),
        "sec4": PolyValue("Section 4", 1.000000, 0.000000, 1.000000),
        "freq4": PolyValue("Frequency 4", 2500.000000, 200.000000, 20000.000000),
        "q4": PolyValue("Bandwidth 4", 0.600000, 0.062500, 4.000000),
        "gain4": PolyValue("Gain 4", 0.000000, -18.000000, 18.000000),
        "HSsec": PolyValue("Highshelf", 1.000000, 0.000000, 1.000000),
        "HSfreq": PolyValue("Highshelf Frequency", 8000.000000, 1000.000000, 16000.000000),
        "HSq": PolyValue("Highshelf Bandwidth", 1.000000, 0.062500, 4.000000),
        "HSgain": PolyValue("Highshelf Gain", 0.000000, -18.000000, 18.000000)},
    "cab": {"gain": PolyValue("gain", 0, -90, 24), "ir": PolyValue("/audio/cabs/1x12cab.wav", 0, 0, 1),
        "carla_level": PolyValue("level", 1, 0, 1)},
    "postcab": {"gain": PolyValue("gain", 0, -90, 24), "carla_level": PolyValue("level", 1, 0, 1)},
    "lfo1": lfos[0],
    # "lfo2": lfos[1],
    # "lfo3": lfos[2],
    # "lfo4": lfos[3],
    "mclk": {"carla_level": PolyValue("level", 1, 0, 1)},
    }

all_effects = [("delay1", True), ("delay2", True), ("delay3", True),
        ("delay4", True), ("reverb", True), ("postreverb", True), ("mixer", True),
        ("tape1", False), ("reverse1", False),
        ("sigmoid1", False), ("eq2", True), ("cab", True), ("postcab", True)]
plugin_state = dict({(k, PolyBool(initial)) for k, initial in all_effects})
plugin_state["global"] = PolyBool(True)

app = QGuiApplication(sys.argv)
QIcon.setThemeName("digit")
# Instantiate the Python object.
knobs = Knobs()
current_bpm = PolyValue("BPM", 120, 30, 250) # bit of a hack
global_bypass = PolyValue("BPM", 120, 30, 250) # bit of a hack
current_preset = PolyValue("Default Preset", 0, 0, 1)
update_counter = PolyValue("update counter", 0, 0, 100000)
command_status = [PolyValue("command status", -1, -10, 100000), PolyValue("command status", -1, -10, 100000)]
delay_num_bars = PolyValue("Num bars", 1, 1, 16)
midi_channel = PolyValue("channel", 1, 1, 16)
is_loading = {"reverb":PolyBool(False), "cab":PolyBool(False)}

qmlEngine = QQmlApplicationEngine()
# Expose the object to QML.
context = qmlEngine.rootContext()
for k, v in available_port_models.items():
    context.setContextProperty(k.replace(" ", "_").replace(":", "_")+"AvailablePorts", v)
for k, v in used_port_models.items():
    context.setContextProperty(k.replace(" ", "_").replace(":", "_")+"UsedPorts", v)
context.setContextProperty("knobs", knobs)
context.setContextProperty("polyValues", effect_parameter_data)
context.setContextProperty("knobMap", knob_map)
context.setContextProperty("currentBPM", current_bpm)
context.setContextProperty("pluginState", plugin_state)
context.setContextProperty("currentPreset", current_preset)
context.setContextProperty("updateCounter", update_counter)
context.setContextProperty("commandStatus", command_status)
context.setContextProperty("delayNumBars", delay_num_bars)
context.setContextProperty("midiChannel", midi_channel)
context.setContextProperty("isLoading", midi_channel)

# engine.load(QUrl("qrc:/qml/digit.qml"))
qmlEngine.load(QUrl("qml/digit.qml"))

mixer_is_connected = False
effects_are_connected = False
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

def handle_encoder_change(is_left, change):
    # increase or decrease the current knob value depending on knob speed
    # knob_value = knob_value + (change * knob_speed)
    normal_speed = 48.0
    knob = "right"
    if is_left:
        knob = "left"
    knob_effect = knob_map[knob].effect
    knob_parameter = knob_map[knob].parameter
    value = effect_parameter_data[knob_effect][knob_parameter].value
    # base speed * speed multiplier
    base_speed = (abs(effect_parameter_data[knob_effect][knob_parameter].rmin) + abs(effect_parameter_data[knob_effect][knob_parameter].rmax)) / normal_speed
    value = value + (change * knob_map[knob].speed * base_speed)
    print("knob value is", value)
    # knob change handles clamping
    knobs.ui_knob_change(knob_effect, knob_parameter, value)

def update_delay_bpms():
    for effect_name in ["delay1", "delay2", "delay3", "delay4"]:
        knobs.ui_knob_change(effect_name, "BPM_0", current_bpm.value)

start_tap_time = None
## tap callback is called by hardware button from the GPIO checking thread
def handle_tap():
    global start_tap_time
    current_tap = time.perf_counter()
    if start_tap_time is not None:
        # just use this and previous to calculate BPM
        # BPM must be in range 30-250
        d = current_tap - start_tap_time
        # 120 bpm, 0.5 seconds per tap
        bpm = 60 / d
        if bpm > 30 and bpm < 250:
            # set host BPM
            host.transport_bpm(bpm)
            print("setting tempo", bpm)
            current_bpm.value = bpm
            update_delay_bpms()

    # record start time
    start_tap_time = current_tap

def handle_next():
    # disable delay
    # plugin_state["global"].value = not plugin_state["global"].value
    knobs.toggle_enabled("delay1")

def handle_bypass():
    # global bypass
    plugin_state["global"].value = not plugin_state["global"].value
    if plugin_state["global"].value:
        pedal_hardware.effect_on()
    else:
        pedal_hardware.effect_off()

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
        auto_connect_ports()

pedal_hardware.EXIT_THREADS = True

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


