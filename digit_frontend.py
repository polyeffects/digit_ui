import sys, time, json, os.path, os, subprocess, queue, threading
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit
###### UI
# --------------------------------------------------------------------------------------------------------

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

def ui_worker(ui_mess, core_mess):
    os.sched_setaffinity(0, (2, ))
    EXIT_PROCESS = [False]
    from PySide2.QtGui import QGuiApplication
    from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal
    from PySide2.QtQml import QQmlApplicationEngine
    from PySide2.QtGui import QIcon
    # compiled QML files, compile with pyside2-rcc
    import qml.qml
    import icons.icons#, imagine_assets
    import resource_rc
    import start_jconvolver

    def clamp(v, min_value, max_value):
        return max(min(v, max_value), min_value)

    def send_core_message(command, args):
        core_messages.put((command, args))

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

    source_ports = ["sigmoid1:Output", "delay2:out0","delay3:out0", "delay4:out0",
            "postreverb:Out Left", "postreverb:Out Right", "system:capture_2", "system:capture_4",
        "system:capture_3", "system:capture_5", "postcab:Out"]
    available_port_models = dict({(k, QStringListModel()) for k in source_ports})
    used_port_models = dict({(k, QStringListModel()) for k in available_port_models.keys()})

    preset_list = []
    try:
        with open("/pedal_state/preset_list.json") as f:
            preset_list = json.load(f)
    except:
        preset_list = ["Akg eq ed", "Back at u"]
    preset_list_model = QStringListModel(preset_list)

    def set_knob_current_effect(knob, effect, parameter):
        # get current value and update encoder / cache.
        knob_map[knob].effect = effect
        knob_map[knob].parameter = parameter

    def insert_row(model, row):
        j = len(model.stringList())
        model.insertRows(j, 1)
        model.setData(model.index(j), row)

    def remove_row(model, row):
        i = model.stringList().index(row)
        model.removeRows(i, 1)

    # preset map number to filename
    # playlists
    # add number + filename
    def jump_to_preset(is_inc, num):
        p_list = preset_list_model.stringList()
        if is_inc:
            current_preset.value = (current_preset.value + num) % len(p_list)
        else:
            if num < len(p_list):
                current_preset.value = num
            else:
                return
        load_preset("/presets/"+p_list[current_preset.value]+".json")


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
        output["delay_num_bars"] = delay_num_bars.value
        with open(filename, "w") as f:
            json.dump(output, f)

    def load_preset(filename):
        preset = {}
        with open(filename) as f:
            preset = json.load(f)
        current_preset.name = os.path.splitext(os.path.basename(filename))[0]
        # read first as clips
        if "delay_num_bars" in preset:
            if preset["delay_num_bars"] != delay_num_bars.value:
                delay_num_bars.value = preset["delay_num_bars"]
                effect_parameter_data["delay1"]["Delay_1"].rmax = preset["delay_num_bars"] * 4
                effect_parameter_data["delay2"]["Delay_1"].rmax = preset["delay_num_bars"] * 4
                effect_parameter_data["delay3"]["Delay_1"].rmax = preset["delay_num_bars"] * 4
                effect_parameter_data["delay4"]["Delay_1"].rmax = preset["delay_num_bars"] * 4
        else:
            delay_num_bars.value = 2
            effect_parameter_data["delay1"]["Delay_1"].rmax = 2 * 4
            effect_parameter_data["delay2"]["Delay_1"].rmax = 2 * 4
            effect_parameter_data["delay3"]["Delay_1"].rmax = 2 * 4
            effect_parameter_data["delay4"]["Delay_1"].rmax = 2 * 4

        # read all effect parameters
        for effect_name, effect_value in preset["effects"].items():
            for parameter_name, parameter_value in effect_value.items():
                # update changed
                if parameter_name == "ir":
                    if effect_parameter_data[effect_name][parameter_name].name != parameter_value:
                        knobs.update_ir(effect_name == "reverb", parameter_value)
                else:
                    if effect_parameter_data[effect_name][parameter_name].value != parameter_value:
                        # print("loading parameter", effect_name, parameter_name, parameter_value)
                        knobs.ui_knob_change(effect_name, parameter_name, parameter_value)
                    # remove all existing MIDI mapping
                    if effect_parameter_data[effect_name][parameter_name].assigned_cc is not None:
                        knobs.unmap_parameter(effect_name, parameter_name)
        for effect_name, effect_value in preset["midi_map"].items():
            for parameter_name, parameter_value in effect_value.items():
                send_core_message("map_parameter_cc", (effect_name, parameter_name, parameter_value, False))
                effect_parameter_data[effect_name][parameter_name].assigned_cc = parameter_value
        # read enabled state
        for effect, is_active in preset["state"].items():
            if effect == "global":
                pass
            else:
                send_core_message("set_active", (effect, is_active))
                plugin_state[effect].value = is_active
        # read connections
        # preset_con_list = []
        # for conn in preset["connections"]:
        #     if conn[0] == "system:capture_2":
        #         preset_con_list.append(("balance1:Out Left", conn[1]))
        #     else:
        #         preset_con_list.append(tuple(conn))
        preset_connections = set([tuple(a) for a in preset["connections"]])
        # preset_connections = set(preset_con_list)
        # remove connections that aren't in the new preset
        for source_port, target_port in (current_connection_pairs_poly-preset_connections):
            effect, source_p = source_port.split(":")
            knobs.ui_remove_connection(effect, source_p, target_port)
        # add connections that are in the new preset but not the old
        for source_port, target_port in (preset_connections - current_connection_pairs_poly):
            effect, source_p = source_port.split(":")
            knobs.ui_add_connection(effect, source_p, target_port)
        midi_connections = set([(tuple(a[0]), tuple(a[1])) for a in preset["midi_connections"]])
        for source_pair, target_pair in midi_connections:
            send_core_message("add_connection_pair", (source_pair, target_pair))
        global current_midi_connection_pairs_poly
        current_midi_connection_pairs_poly = midi_connections
        # read knob mapping
        for knob, mapping in preset["knobs"].items():
            set_knob_current_effect(knob, mapping[0], mapping[1])
            send_core_message("map_parameter", (knob, mapping[0], mapping[1],
                    effect_parameter_data[mapping[0]][mapping[1]].rmin,
                    effect_parameter_data[mapping[0]][mapping[1]].rmax))
        # read bpm
        if current_bpm.value != preset["bpm"]:
            current_bpm.value = preset["bpm"]
            send_core_message("set_bpm", (preset["bpm"], ))


    class Knobs(QObject):
        """Basically all functions for QML to call"""

        def __init__(self):
            QObject.__init__(self)
            self.waitingval = ""

        @Slot(str, str, 'double')
        def ui_knob_change(self, effect_name, parameter, value):
            # print(x, y, z)
            if (effect_name in effect_parameter_data) and (parameter in effect_parameter_data[effect_name]):
                effect_parameter_data[effect_name][parameter].value = value
                send_core_message("knob_change", (effect_name, parameter, value))
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
            send_core_message("add_connection", (effect, source_port, x))

        @Slot(str, str, str)
        def ui_remove_connection(self, effect, source_port, x):
            effect_source = effect + ":" + source_port
            remove_row(used_port_models[effect_source], x)
            insert_row(available_port_models[effect_source], x)
            current_connection_pairs_poly.remove((effect_source, x))

            send_core_message("remove_connection", (effect, source_port, x))

        @Slot(str)
        def toggle_enabled(self, effect):
            # print("toggling", effect)
            is_active = not plugin_state[effect].value
            plugin_state[effect].value = is_active
            send_core_message("toggle_enabled", (effect, ))

        @Slot(str)
        def set_bypass_type(self, t):
            print("setting bypass type", t)
            send_core_message("set_bypass_type", (t, ))

        @Slot(bool, str)
        def update_ir(self, is_reverb, ir_file):
            # print("updating ir", ir_file)
            current_ir_file = ir_file[7:] # strip file:// prefix
            # cause call file callback
            # by calling show GUI
            # TODO queue reverb loading for presets
            if is_reverb:
                # kill existing jconvolver
                # write jconvolver file
                # start jconvolver
                if is_loading["reverb"].value:
                    return
                is_loading["reverb"].value = True
                effect_parameter_data["reverb"]["ir"].name = ir_file
                # host.show_custom_ui(pluginMap["reverb"], True)
                start_jconvolver.generate_reverb_conf(current_ir_file)
                # host.set_program(pluginMap["reverb"], 0)
            else:
                if is_loading["cab"].value:
                    return
                is_loading["cab"].value = True
                effect_parameter_data["cab"]["ir"].name = ir_file
                start_jconvolver.generate_cab_conf(current_ir_file)



        @Slot(str, str)
        def map_parameter(self, effect_name, parameter):
            if self.waiting == "left" or self.waiting == "right":
                # mapping and encoder
                set_knob_current_effect(self.waiting, effect_name, parameter)
                send_core_message("map_parameter", (self.waiting, effect_name, parameter,
                    effect_parameter_data[effect_name][parameter].rmin,
                    effect_parameter_data[effect_name][parameter].rmax))
                # print("mapping knob core")
            else:
                # we're mapping to LFO
                # print("mapping lfo frontend")
                send_core_message("map_parameter_to_lfo", (self.waiting, effect_name, parameter, effect_parameter_data[self.waiting]["cc_num"].value))
                # connect ports
                effect_parameter_data[effect_name][parameter].assigned_cc = effect_parameter_data[self.waiting]["cc_num"].value
                current_midi_connection_pairs_poly.add(((self.waiting, "events-out"), (effect_name, "events-in")))
            self.waiting = ""

        @Slot(str, str)
        def unmap_parameter(self, effect_name, parameter):
            send_core_message("unmap_parameter", (effect_name, parameter))
            effect_parameter_data[effect_name][parameter].assigned_cc = None

        @Slot(str, str, int)
        def map_parameter_cc(self, effect_name, parameter, cc):
            send_core_message("map_parameter_cc", (effect_name, parameter, cc))
            effect_parameter_data[effect_name][parameter].assigned_cc = cc
            current_midi_connection_pairs_poly.add((("ttymidi", "MIDI_in"), (effect_name, "events-in")))

        @Slot(str)
        def set_waiting(self, knob):
            # print("waiting", knob)
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
            # print("saving", preset_name)
            # TODO add folders
            outfile = "/presets/"+preset_name+".json"
            current_preset.name = preset_name
            save_preset(outfile)

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
            command_reverb = """cd /media/reverbs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/audio/reverbs --parents"""
            command_cab = """cd /media/cabs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/audio/cabs --parents"""
            # copy all wavs in /usb/reverbs and /usr/cabs to /audio/reverbs and /audio/cabs
            command_status[0].value = -1
            command_status[1].value = -1
            command_status[0].value = subprocess.call(command_reverb, shell=True)
            command_status[1].value = subprocess.call(command_cab, shell=True)

        @Slot()
        def import_presets(self):
            # print("copy presets from USB")
            # could convert any that aren't 48khz.
            # instead we just only copy ones that are
            command = """cd /media/presets; find . -iname "*.json" -type f -print0 | xargs -0 cp --target-directory=/presets --parents"""
            command_status[0].value = subprocess.call(command, shell=True)

        @Slot()
        def export_presets(self):
            # print("copy presets to USB")
            # could convert any that aren't 48khz.
            # instead we just only copy ones that are
            command = """cd /presets; mkdir -p /media/presets; find . -iname "*.json" -type f -print0 | xargs -0 cp --target-directory=/media/presets --parents;sudo umount /media"""
            command_status[0].value = subprocess.call(command, shell=True)

        @Slot()
        def copy_logs(self):
            # print("copy presets to USB")
            # could convert any that aren't 48khz.
            # instead we just only copy ones that are
            command = """mkdir -p /media/logs; sudo cp /var/log/syslog /media/logs/;sudo umount /media"""
            command_status[0].value = subprocess.call(command, shell=True)

        @Slot()
        def ui_update_firmware(self):
            # print("Updating firmware")
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
            args = []
            for effect, parameters in effect_parameter_data.items():
                for param_name, p_value in parameters.items():
                    if p_value.assigned_cc is not None:
                        args.append((pluginMap[effect], parameterMap[effect][param_name]))

            send_core_message("set_channel", (channel, args))
            midi_channel.value = channel
            pedal_state["midi_channel"] = channel
            write_pedal_state()

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

    def add_ports(port):
        source_ports_self = {"sigmoid1:Output":"delay1", "delay2:out0":"delay2",
                "delay3:out0": "delay3", "delay4:out0": "delay4",
                "postreverb:Out Left":"eq2", "postreverb:Out Right":"eq2",
                "system:capture_2":"system", "system:capture_4":"system",
                "system:capture_3":"system", "system:capture_5":"system",
                "postcab:Out":"cab"}
        for k, model in available_port_models.items():
            if source_ports_self[k] == "system" or source_ports_self[k] != output_port_names[port][0]:
                # print("add_port", k, port)
                insert_row(model, port)

    def process_ui_messages():
        # pop from queue
        try:
            while not EXIT_PROCESS[0]:
                m = ui_messages.get(block=False)
                # print("got ui message", m)
                if m[0] == "is_loading":
                    # print("setting is loading is process_ui")
                    is_loading[m[1][0]].value = False
                elif m[0] == "value_change":
                    # print("got value change in process_ui")
                    effect_name, parameter, value = m[1]
                    if (effect_name in effect_parameter_data) and (parameter in effect_parameter_data[effect_name]):
                        effect_parameter_data[effect_name][parameter].value = value
                elif m[0] == "bpm_change":
                    current_bpm.value = m[1][0]
                elif m[0] == "set_plugin_state":
                    plugin_state[m[1][0]].value = m[1][1]
                elif m[0] == "add_port":
                    add_ports(m[1][0])
                elif m[0] == "jump_to_preset":
                    jump_to_preset(m[1][0], m[1][1])
                elif m[0] == "exit":
                    # global EXIT_PROCESS
                    EXIT_PROCESS[0] = True
        except queue.Empty:
            pass

    def write_pedal_state():
        with open("/pedal_state/state.json", "w") as f:
            json.dump(pedal_state, f)


    lfos = []


    for n in range(1):
        lfos.append({})
        lfos[n]["num_points"] = PolyValue("num_points", 1, 1, 16)
        lfos[n]["channel"] = PolyValue("channel", 1, 1, 16)
        lfos[n]["cc_num"] = PolyValue("cc_num", 102+n, 0, 127)
        lfos[n]["speed_mul"] = PolyValue("speed_mul", 1, 0.01, 10.0)
        lfos[n]["amount_mul"] = PolyValue("amount_mul", 1, 0, 1.0)
        for i in range(1,17):
            lfos[n]["time"+str(i)] = PolyValue("time"+str(i), 0, 0, 1)
            lfos[n]["value"+str(i)] = PolyValue("value"+str(i), 0, 0, 1)
            lfos[n]["style"+str(i)] = PolyValue("style"+str(i), 0, 0, 5)

    # this is not great

    effect_parameter_data = {"delay1": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
            "Delay_1" : PolyValue("Time", 0.500000, 0.001000, 4.000000),
            "Warp_2" : PolyValue("Warp", 0.000000, -1.000000, 1.000000),
            "DelayT60_3" : PolyValue("Glide", 0.500000, 0.000000, 100.000000),
            "Feedback_4" : PolyValue("Feedback", 0.300000, 0.000000, 1.000000),
            "Amp_5" : PolyValue("Level", 0.500000, 0.000000, 1.000000),
            "FeedbackSm_6" : PolyValue("Tone", 0.000000, 0.000000, 1.000000),
            "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
            "carla_level": PolyValue("level", 1, 0, 1)},
        "delay2": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
                "Delay_1" : PolyValue("Time", 0.500000, 0.001000, 4.000000),
                "Warp_2" : PolyValue("Warp", 0.000000, -1.000000, 1.000000),
                "DelayT60_3" : PolyValue("Glide", 0.500000, 0.000000, 100.000000),
                "Feedback_4" : PolyValue("Feedback", 0.300000, 0.000000, 1.000000),
                "Amp_5" : PolyValue("Level", 0.500000, 0.000000, 1.000000),
                "FeedbackSm_6" : PolyValue("Tone", 0.000000, 0.000000, 1.000000),
                "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
                "carla_level": PolyValue("level", 1, 0, 1)},
        "delay3": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
                "Delay_1" : PolyValue("Time", 0.500000, 0.001000, 4.000000),
                "Warp_2" : PolyValue("Warp", 0.000000, -1.000000, 1.000000),
                "DelayT60_3" : PolyValue("Glide", 0.500000, 0.000000, 100.000000),
                "Feedback_4" : PolyValue("Feedback", 0.300000, 0.000000, 1.000000),
                "Amp_5" : PolyValue("Level", 0.500000, 0.000000, 1.000000),
                "FeedbackSm_6" : PolyValue("Tone", 0.000000, 0.000000, 1.000000),
                "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
                "carla_level": PolyValue("level", 1, 0, 1)},
        "delay4": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
                "Delay_1" : PolyValue("Time", 0.500000, 0.001000, 4.000000),
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

    knob_map = {"left": PolyEncoder("delay1", "Delay_1"), "right": PolyEncoder("delay1", "Amp_5")}

    all_effects = [("delay1", True), ("delay2", True), ("delay3", True),
            ("delay4", True), ("reverb", True), ("postreverb", True), ("mixer", True),
            ("tape1", False), ("reverse1", False),
            ("sigmoid1", False), ("eq2", True), ("cab", True), ("postcab", True)]
    plugin_state = dict({(k, PolyBool(initial)) for k, initial in all_effects})
    plugin_state["global"] = PolyBool(True)
    current_connection_pairs_poly = set()
    current_midi_connection_pairs_poly = set()

    # Instantiate the Python object.
    knobs = Knobs()
    # read persistant state
    pedal_state = {}
    with open("/pedal_state/state.json") as f:
        pedal_state = json.load(f)
    current_bpm = PolyValue("BPM", 120, 30, 250) # bit of a hack
    current_preset = PolyValue("Default Preset", 0, 0, 127)
    update_counter = PolyValue("update counter", 0, 0, 500000)
    command_status = [PolyValue("command status", -1, -10, 100000), PolyValue("command status", -1, -10, 100000)]
    delay_num_bars = PolyValue("Num bars", 1, 1, 16)
    midi_channel = PolyValue("channel", pedal_state["midi_channel"], 1, 16)
    input_level = PolyValue("input level", pedal_state["input_level"], -80, 10)
    knobs.set_input_level(pedal_state["input_level"], write=False)
    is_loading = {"reverb":PolyBool(False), "cab":PolyBool(False)}
    # global ui_messages, core_messages
    ui_messages = ui_mess
    core_messages = core_mess
    app = QGuiApplication(sys.argv)
    QIcon.setThemeName("digit")
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
    context.setContextProperty("isLoading", is_loading)
    context.setContextProperty("inputLevel", input_level)
    context.setContextProperty("presetList", preset_list_model)

    # engine.load(QUrl("qrc:/qml/digit.qml"))
    qmlEngine.load(QUrl("qml/digit.qml"))
    ######### UI is setup
    def signalHandler(sig, frame):
        if sig in (SIGINT, SIGTERM):
            # print("frontend got signal")
            # global EXIT_PROCESS
            EXIT_PROCESS[0] = True
    signal(SIGINT,  signalHandler)
    signal(SIGTERM, signalHandler)

    initial_preset = False
    while not EXIT_PROCESS[0]:
        app.processEvents()
        process_ui_messages()
        sleep(0.01)
        if not initial_preset:
            load_preset("/presets/Default Preset.json")
            update_counter.value+=1
            initial_preset = True

    # print("exiting frontend")
    exit(1)
