import serial, os
# digit main
from collections import defaultdict
# import Adafruit_BBIO.GPIO as GPIO
import time, queue, threading, json, subprocess
import itertools, operator, statistics
# from Adafruit_BBIO.Encoder import RotaryEncoder, eQEP2, eQEP0
# left_encoder = RotaryEncoder(eQEP0)
# right_encoder = RotaryEncoder(eQEP2)
from static_globals import IS_REMOTE_TEST, PEDAL_TYPE, pedal_types, trails_range_map, trails_mode_settings
from static_globals import trails_control_map, trails_enable_map, verbs_keys, verbs_keys_invert


# is_on = False
KNOB_MAX = 255
EXIT_THREADS = False
bypass_setup = False
main_enable = False
knobs = None # set from headless

# GPIO.setup("P8_17", GPIO.OUT)
# GPIO.setup("P8_18", GPIO.OUT)

# GPIO.setup("P9_12", GPIO.IN)
# GPIO.setup("P9_14", GPIO.IN)
# GPIO.setup("P9_16", GPIO.IN)

footswitch_is_down = defaultdict(bool)
footswitch_action_done = defaultdict(bool)
footswitch_action_time = defaultdict(int)
# shared to headless
verbs_initial_preset_loaded = False
a_tap_time = 0
prev_a_tap_time = [0, 0, 0]
b_tap_time = 0
B_HOLD_TIME = 0.8
PRESET_SWITCH_TIME = 0.5
NUM_PRESETS = 56
set_list_number = 0
current_preset_number = [0, 0]
audio_side = "1" # 1 or 2
current_mode = 0
sustain = False
sequencer_on = False
last_step_time = 0
step_duration = 0.500


input_queue = queue.Queue()
to_mcu_queue = queue.Queue()
ser = serial.Serial('/dev/ttyS2', 62500, timeout=0)

hardware_info = {"revision": 12, "pedal": "verbs"}


PEDAL_VERSION = hardware_info["revision"]

sub_graph = "ingen:/main/"
current_bytes = bytearray()

if PEDAL_TYPE == pedal_types.verbs:
    with open("/pedal_state/verbs_presets.json") as f:
        verbs_presets = json.load(f)
elif PEDAL_TYPE == pedal_types.ample:
    with open("/pedal_state/ample_presets.json") as f:
        verbs_presets = json.load(f)
elif PEDAL_TYPE == pedal_types.trails:
    with open("/pedal_state/trails_presets.json") as f:
        verbs_presets = json.load(f)

hardware_state = {}

cc_messages = {"ONSET_CC": 14,
        "MIX_CC": 15,
        "LOW_CUT_CC": 16,
        "SMOOSH_CC": 17,
        "CRESCENDO_CC": 43, #remapped to 18 external
        "BYPASS_CC": 44, # remapped to 19 external
        "BOOST_CC": 20,
        "MID_CC": 21,
        "ROOM_CC": 22,
# internal only to CPU analog side
        "PRESET_CHANGE_CC": 50,
        "MIDI_CHANNEL_CHANGE": 51,
        "SAVE_PRESET_CC": 52,
        "IMPORT_FILES_CC": 53,
# internal to mcu
        "IMPORT_DONE_CC": 54,
        "LOADING_PROGRESS_CC": 55,
# internal only to CPU analog side
        "MONO_SUM_CC": 56,
        "KILL_DRY_CC": 57,
        "SPLIT_CC": 58,
        "SIDE_CC": 59,
        "LUM_CC": 60,
        }

try:
    with open("/pedal_state/hardware_state.json") as f:
        hardware_state = json.load(f)
        if "cab_enabled" not in hardware_state:
            hardware_state["cab_enabled"] = True
        if "split" not in hardware_state:
            hardware_state["split"] = False
        if "lum" not in hardware_state:
            hardware_state["lum"] = 80
except:
    hardware_state = {"mono": False, "kill_dry": False, "cab_enabled": True, "split": False, "lum": 80}

if PEDAL_TYPE != pedal_types.verbs:
    hardware_state["kill_dry"] = True
    if hardware_state['split']:
        to_mcu_queue.put([176, cc_messages["SPLIT_CC"], int(hardware_state['split'])])
    # send lum to mcu
    to_mcu_queue.put([176, cc_messages["LUM_CC"], hardware_state["lum"]])

def set_mono_sum_kill_dry(mono, kill_dry):
    command = ""
    if mono:
        # with jack_connect, need to connect capture 1 to in 2
        command += "jack_connect system:capture_1 ingen:in_2;"
        command += "jack_disconnect system:capture_2 ingen:in_2;"
    else:
        command += "jack_connect system:capture_2 ingen:in_2;"
        command += "jack_disconnect system:capture_1 ingen:in_2;"

    if PEDAL_TYPE == pedal_types.verbs or PEDAL_TYPE == pedal_types.trails:
        if kill_dry or PEDAL_TYPE == pedal_type.trails:
            command += "amixer -- cset name='Left Playback Mixer Left Bypass Volume' 0;"
            command += "amixer -- cset name='Right Playback Mixer Right Bypass Volume' 0;"
            command += "amixer -- cset name='Right Playback Mixer Left Bypass Volume' 0;"
        else:
            command += "amixer -- cset name='Left Playback Mixer Left Bypass Volume' 5;"
            command += "amixer -- cset name='Right Playback Mixer Right Bypass Volume' 5;"
            if mono:
                command += "amixer -- cset name='Right Playback Mixer Left Bypass Volume' 5;"
            else:
                command += "amixer -- cset name='Right Playback Mixer Left Bypass Volume' 0;"
    subprocess.call(command, shell=True)

# wait until ingen has io exists before calling this
while b"ingen:in_2" not in subprocess.run(["/usr/bin/jack_lsp", "ingen:in_2"], capture_output=True).stdout:
    time.sleep(1)
set_mono_sum_kill_dry(hardware_state["mono"], hardware_state["kill_dry"])




# effect_name / parameter to CC number and range

if PEDAL_TYPE == pedal_types.verbs:
    effect_name_parameter_cc_map = {
            ("wet_dry_stereo1", "level") : (cc_messages["MIX_CC"], 0, 1),
            ("delay1", "Delay_1") : (cc_messages["ONSET_CC"], 0.01, 0.7), # also delay6
            ("filter_uberheim1", "cutoff") : (cc_messages["LOW_CUT_CC"], 0.01, 0.7), # also filter_uberheim2
            ("vca1", "gain") : (cc_messages["SMOOSH_CC"], 0, 1),
            ("sum1", "a") : (cc_messages["CRESCENDO_CC"], 0, 1),
            }
elif PEDAL_TYPE == pedal_types.ample:
    effect_name_parameter_cc_map = {
            ("boost1", "gain") : (cc_messages["BOOST_CC"], 1, 4), # bypass
            ("amp_nam1", "output_level") : (cc_messages["MIX_CC"], -20, 6), # volume
            ("amp_nam1", "input_level") : (cc_messages["ONSET_CC"], -45.0, 5), # gain
            ("tonestack1", "bass_0") : (cc_messages["LOW_CUT_CC"], -10, 10), #  bass
            ("tonestack1", "mid_1") : (cc_messages["MID_CC"], -10, 10), # treble
            ("tonestack1", "treble_2") : (cc_messages["SMOOSH_CC"], -10, 10), # treble
            ("boost1", "on") : (cc_messages["CRESCENDO_CC"], 0, 1), # boost
            ("stereo_reverb1", "wet") : (cc_messages["ROOM_CC"], -60, -20), # boost
            }
elif PEDAL_TYPE == pedal_types.trails:
    effect_name_parameter_cc_map = {
            ("wet_dry_stereo1", "level") : (cc_messages["MIX_CC"], -1, 1),
            ("delay1", "Delay_1") : (cc_messages["ONSET_CC"], 0.01, 0.7), # also delay6
            ("filter_uberheim1", "cutoff") : (cc_messages["LOW_CUT_CC"], 0.01, 0.7), # also filter_uberheim2
            ("vca1", "gain") : (cc_messages["SMOOSH_CC"], 0, 1),
            ("sum1", "a") : (cc_messages["CRESCENDO_CC"], 0, 1),
            }

# verb_presets = {0: (("wet_dry_stereo2", "level", 1),
#         ("wet_dry_stereo1", "level", 0.4),
#         ("delay1", "Delay_1", 0.01),
#         ("filter_uberheim1", "cutoff", 0.1),
#         ("vca1", "gain", 0),
#         ("foot_switch_a1", "value", 0),
#         ("quad_ir_reverb1", "ir", "/audio/0/0.wav"))}

# invert map 
cc_effect_name_parameter_map = {v[0]: (k, *v[1:]) for k, v in effect_name_parameter_cc_map.items()}

def write_hardware_state():
    with open("/pedal_state/hardware_state.json", "w") as f:
        json.dump(hardware_state, f)
    os.sync()

def load_verbs_preset_from_set_list(set_list_entry, load_now=True):
    if PEDAL_TYPE == pedal_types.ample:
        # if load now is false we just change the indictors
        try:
            #load left and right if they exist
            l = set_list_entry[0]
            r = set_list_entry[1]

            if hardware_state["split"]:
                global audio_side
                prev_audio_side = audio_side
                if audio_side == "2":
                    audio_side = "1"
                    to_mcu_queue.put([176, cc_messages["SIDE_CC"], int(audio_side)-1])
                load_verbs_preset(l, load_now)
                audio_side = "2"
                to_mcu_queue.put([176, cc_messages["SIDE_CC"], int(audio_side)-1])
                load_verbs_preset(r, load_now)
                if prev_audio_side != audio_side:
                    audio_side = prev_audio_side
                    to_mcu_queue.put([176, cc_messages["SIDE_CC"], int(audio_side)-1])
                if len(set_list_entry) == 4: # we've got cab info
                    knobs.set_bypass(sub_graph+"mono_cab1", not set_list_entry[2])
                    knobs.set_bypass(sub_graph+"mono_cab2", not set_list_entry[3])
            else:
                # print("## loading non split")
                load_verbs_preset(l, load_now)
        except TypeError:
            load_verbs_preset(set_list_entry, load_now)
    else:
        load_verbs_preset(set_list_entry)

def cab_enabled_name(value):
    # given a name, return the full rig name if cab is enable, else name
    if hardware_state["cab_enabled"]:
        # return value[:-len(".nam")]+"_full_rig.nam"
        return value
    else:
        return value


def load_verbs_preset(p, load_now=True, from_sequencer=False):
    # verbs presets are index : {(effect_name, effect_parameter, value), 
    to_mcu_queue.put([176, cc_messages["PRESET_CHANGE_CC"], int(p)])
    # mute before loading if ample
    if PEDAL_TYPE == pedal_types.ample:
        if hardware_state["split"]:
            current_preset_number[int(audio_side)-1] = int(p)
            if not load_now:
                return
            knobs.ui_knob_change(sub_graph+"mono_cab"+str(audio_side), "wet", -60.0)
        else:
            current_preset_number[0] = int(p)
            current_preset_number[1] = int(p)
            if not load_now:
                return
            knobs.ui_knob_change(sub_graph+"mono_cab1", "wet", -60.0)
            time.sleep(0.01)
            knobs.ui_knob_change(sub_graph+"mono_cab2", "wet", -60.0)
    else:
        current_preset_number[0] = int(p)
        if not load_now:
            return

    if PEDAL_TYPE == pedal_types.trails:
        load_trails(p, from_sequencer)
        return

    for effect_id, parameter, value in verbs_presets[str(p)]:
        if parameter == "ir":
            if effect_id in ("amp_nam1", "amp_nam2"):
                # load to left and right if we're in normal mode
                amp_name = cab_enabled_name(value)

                # if we're ample only send to the current side of MCU if split
                if hardware_state["split"]:
                    if str(audio_side) == effect_id[-1:]:
                        # print("calling update nam json split, ", effect_id, amp_name, value)
                        knobs.update_json(sub_graph+effect_id, amp_name)
                else:
                    if effect_id[-1:] == "1": # side 1s value to both sides in non-split mode
                        # print("calling update nam json not split, ", effect_id, amp_name, value)
                        knobs.update_json(sub_graph+effect_id, amp_name)
                        time.sleep(0.02)
                        knobs.update_json(sub_graph+effect_id[:-1]+"2", amp_name)
            else:
                if PEDAL_TYPE == pedal_types.ample:
                    # if we're ample only send to the current side of MCU if split
                    if hardware_state["split"]:
                        if str(audio_side) == effect_id[-1:]:
                            # print("calling update ir split, ", effect_id, value)
                            knobs.update_ir(sub_graph+effect_id, value)
                    else:
                        if effect_id[-1:] == "1": # side 1s value to both sides in non-split mode
                            # print("calling update ir not split, ", effect_id, value)
                            knobs.update_ir(sub_graph+effect_id, value)
                            time.sleep(0.02)
                            knobs.update_ir(sub_graph+effect_id[:-1]+"2", value)
                else:
                    knobs.update_ir(sub_graph+effect_id, value)
            time.sleep(0.02)
        else:
            time.sleep(0.01)
            if PEDAL_TYPE == pedal_types.ample:
                # if we're ample only send to the current side of MCU if split
                if hardware_state["split"]:
                    if str(audio_side) == effect_id[-1:]:
                        send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
                        knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
                else:
                    if effect_id[-1:] == "1": # side 1s value to both sides in non-split mode
                        send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
                        knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
                        time.sleep(0.01)
                        knobs.ui_knob_change(sub_graph+effect_id[:-1]+"2", parameter, float(value))
            else:
                knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
                send_value_to_mcu(sub_graph+effect_id, parameter, float(value))

    # we're loaded, now unmute
    if PEDAL_TYPE == pedal_types.ample:
        time.sleep(0.2)
        if hardware_state["split"]:
            knobs.ui_knob_change(sub_graph+"mono_cab"+str(audio_side), "wet", -19.1)
            knobs.ui_knob_change(sub_graph+"mono_cab"+str(audio_side), "wet", -19.0)
        else:
            knobs.ui_knob_change(sub_graph+"mono_cab1", "wet", -19.1)
            time.sleep(0.01)
            knobs.ui_knob_change(sub_graph+"mono_cab2", "wet", -19.0)
            time.sleep(0.01)
            knobs.ui_knob_change(sub_graph+"mono_cab1", "wet", -19.0)

def load_trails(p, from_sequencer=False):
    # enable and disable modules based on category, 
    # disable first then enable
    global current_mode
    # disable anything that isn't used by this patch
    current_mode = p // 8 # groups of 8
    if not from_sequencer:
        all_modules = set(itertools.chain.from_iterable(trails_enable_map.values()))
        # print("### loading trails preset", p, current_mode)
        for e in (all_modules - trails_enable_map[current_mode]):
            knobs.set_bypass(sub_graph+e, False)
            # print("### bypass", e)
        for e in trails_enable_map[current_mode]:
            knobs.set_bypass(sub_graph+e, True)
            # print("### enable", e)
    # set the values required by this mode TODO
        for effect_id, parameter, value in trails_mode_settings[current_mode]:
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
    # set the values from the preset, lookup mapping
    for i, value in enumerate(verbs_presets[str(p)]):
        if i < 4:
            effect_id, parameter = trails_control_map[current_mode][i]
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            # print("### sending value to MCU", sub_graph+effect_id, parameter, float(value))
            send_value_to_mcu(sub_graph+effect_id, parameter, float(value))

def import_done():
    # if we've got a set list now, parse it
    try:
        with open("/pedal_state/set_list.txt") as f:
            a = f.read()
            s = a.strip().split(',')
            s_l = []
            if PEDAL_TYPE == pedal_types.verbs:
                s_l = [int(b) for b in s if int(b) >= 0 and int(b) < 56]
            else:
                if ":" in a:
                    for b in s:
                        l_c = -1
                        if b.count(":") == 3: # got cab on off info
                            l, r, l_c, r_c = b.split(":")
                        elif ":" in b:
                            l, r = b.split(":")
                        else:
                            l = b
                            r = b
                        if (int(l) >= 0 and int(l) < 56 and int(r) >= 0 and int(r) < 56 ):
                            if (l_c != -1):
                                s_l.append((int(l), int(r), bool(int(l_c)), bool(int(r_c)) ))
                            else:
                                s_l.append((int(l), int(r)))
                else:
                    s_l = [int(b) for b in s if int(b) >= 0 and int(b) < 56]
            if (len(s_l) > 0):
                knobs.save_set_list(s_l)
    except FileNotFoundError:
        pass
    # send to MCU that it's imported, fail or success...
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def save_verbs_preset(ignored):
    p = current_preset_number[int(audio_side)-1]
    c_p = verbs_presets[str(p)]
    # print("preset is", c_p)

    if PEDAL_TYPE == pedal_types.trails:
        n_p = [knobs.get_current_parameter_value(sub_graph+effect_id, parameter) for effect_id, parameter in trails_control_map[current_mode]]
    else:
        n_p = [[effect_id, parameter, knobs.get_current_parameter_value(sub_graph+effect_id, parameter) if parameter not in ("ir", "model" ) else v] for effect_id, parameter, v in c_p ]
    verbs_presets[str(p)] = n_p
    # import pprint
    # pprint.pprint(n_p)

    out_file_map = {pedal_types.verbs : "/pedal_state/verbs_presets.json",
            pedal_types.ample : "/pedal_state/ample_presets.json",
            pedal_types.trails : "/pedal_state/trails_presets.json",
            }
    with open(out_file_map[PEDAL_TYPE], "w") as f:
        json.dump(verbs_presets, f)
    os.sync()

def get_trails_param(effect_name, parameter):
    # map between verbs names and trails 
    k = verbs_keys[(effect_name, parameter)]
    return trails_control_map[current_mode][k]

def reverse_trails_param(effect_name, parameter):
    # map between verbs names and trails 
    try:
        i = trails_control_map[current_mode].index([effect_name, parameter])
        r = trails_range_map[current_mode][i]
        return tuple(verbs_keys_invert[i])+tuple(r)
    except ValueError:
        print("not in control map", effect_name, parameter)
        return ["not/notin1", "notparam", 0, 1]

def update_mcu_values():
    # print("update mcu values")
    for (effect_name, parameter) in effect_name_parameter_cc_map.keys():
        if "stereo_reverb" not in effect_name:
            # print(f"effect name {effect_name} {parameter} ")
            effect_name_side = sub_graph+effect_name[:-1]+str(audio_side)
            if PEDAL_TYPE == pedal_types.trails:
                t_e, t_p = get_trails_param(effect_name, parameter)
                value = float(knobs.get_current_parameter_value(sub_graph+t_e, t_p))
            else:
                value = float(knobs.get_current_parameter_value(effect_name_side, parameter))
            # print(f"effect name side {effect_name_side} {parameter} value {value}")
            send_value_to_mcu(effect_name_side, parameter, value)

def update_midi_ccs(channel):
    for cc in cc_effect_name_parameter_map.keys():
        effect_id_parameter, min_s, max_s = cc_effect_name_parameter_map[cc]
        effect_id, parameter = effect_id_parameter
        effect_id_trim = effect_id[:-1]
        # scale
        # set the values
        # onset and low cut are two modules each
        if effect_id == "delay1":
            knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, cc)
            if PEDAL_TYPE == pedal_types.verbs:
                knobs.set_midi_cc(sub_graph+"delay6", parameter, channel, cc)
        elif effect_id == 'filter_uberheim1':
            knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, cc)
            knobs.set_midi_cc(sub_graph+"filter_uberheim2", parameter, channel, cc)
        else:
            if cc == cc_messages["CRESCENDO_CC"]: # remap these
                if PEDAL_TYPE != pedal_types.ample:
                    knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, 18)
                else:
                    knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, 18)
                    knobs.set_midi_cc(sub_graph+effect_id_trim+"2", parameter, channel, 18+20)
            elif cc == cc_messages["BYPASS_CC"]: # remap these
                knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, 19)
            else:
                if PEDAL_TYPE == pedal_types.verbs:
                    knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, cc)
                else:
                    knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, cc)
                    if cc != cc_messages["ROOM_CC"]: # room only on 1 side
                        knobs.set_midi_cc(sub_graph+effect_id_trim+"2", parameter, channel, cc+20)

def toggle_mono_sum():
    # toggle value, write out to file to persist
    hardware_state["mono"] = not hardware_state["mono"] # {"mono": False, "kill_dry": False}
    # print("mono to stereo is now", hardware_state["mono"])
    write_hardware_state()
    set_mono_sum_kill_dry(hardware_state["mono"], hardware_state["kill_dry"])
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def toggle_split():
    # toggle value, write out to file to persist
    hardware_state["split"] = not hardware_state["split"] # {"mono": False, "kill_dry": False}
    write_hardware_state()
    global audio_side
    if audio_side == "2":
        audio_side = "1"
        to_mcu_queue.put([176, cc_messages["SIDE_CC"], int(audio_side)-1])
    to_mcu_queue.put([176, cc_messages["SPLIT_CC"], int(hardware_state['split'])])
    update_mcu_values()

def set_side(n):
    # only do anything if we are split
    if hardware_state["split"]:
        global audio_side
        if n:
            audio_side = "2"
        else:
            audio_side = "1"
        to_mcu_queue.put([176, cc_messages["SIDE_CC"], int(audio_side)-1])
        update_mcu_values()

def toggle_side():
    # toggle value
    # only do anything if we are split
    if (PEDAL_TYPE == pedal_types.ample):
        if hardware_state["split"]:
            global audio_side
            if audio_side == "1":
                audio_side = "2"
            else:
                audio_side = "1"
            to_mcu_queue.put([176, cc_messages["SIDE_CC"], int(audio_side)-1])
            update_mcu_values()
    elif (PEDAL_TYPE == pedal_types.trails):
        global sequencer_on
        sequencer_on = not sequencer_on


def toggle_cab():
    # toggle value, write out to file to persist
    hardware_state["cab_enabled"] = not hardware_state["cab_enabled"]
    # print("cab enabled is now", hardware_state["cab_enabled"])
    knobs.set_bypass(sub_graph+"mono_cab1", hardware_state["cab_enabled"])
    knobs.set_bypass(sub_graph+"mono_cab2", hardware_state["cab_enabled"])
    write_hardware_state()
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def set_cab(): # called from headless
    knobs.set_bypass(sub_graph+"mono_cab1", hardware_state["cab_enabled"])
    knobs.set_bypass(sub_graph+"mono_cab2", hardware_state["cab_enabled"])

def toggle_kill_dry():
    # toggle value, write out to file to persist
    hardware_state["kill_dry"] = not hardware_state["kill_dry"] # {"mono": False, "kill_dry": False}
    write_hardware_state()
    set_mono_sum_kill_dry(hardware_state["mono"], hardware_state["kill_dry"])
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def set_lum(v):
    # if it's changed
    if (v >> 4) != (hardware_state["lum"] >> 4):
        # set v, write out to file to persist
        hardware_state["lum"] = v
        write_hardware_state()
        to_mcu_queue.put([176, cc_messages["LUM_CC"], v])

def set_main_enable(is_enabled):
    command = ""
    # set bypass state, 
    global main_enable
    main_enable = is_enabled


# # for testing

#     if is_enabled:
#         knobs.ui_knob_change(sub_graph+"mono_cab1", "wet", 0.0)
#         knobs.ui_knob_change(sub_graph+"mono_cab2", "wet", 0.0)
#     else:
#         knobs.ui_knob_change(sub_graph+"mono_cab1", "wet", -60.0)
#         knobs.ui_knob_change(sub_graph+"mono_cab2", "wet", -60.0)
#     to_mcu_queue.put([176, cc_messages["BYPASS_CC"], 127 if main_enable else 0])
#     return

# # for testing

    # update mixer for dry signal
    if is_enabled:
        # print("is enabled is ", is_enabled)
        # enable amps, disable dry
        if (PEDAL_TYPE == pedal_types.ample):
            knobs.set_bypass(sub_graph+"amp_nam1", True)
            knobs.set_bypass(sub_graph+"amp_nam2", True)
            knobs.set_bypass(sub_graph+"amp_nam2", True) # double due to ingen bug
        command += "amixer -- cset name='Left Playback Mixer Left DAC Switch' on;"
        command += "amixer -- cset name='Right Playback Mixer Right DAC Switch' on;"
        command += "amixer -- cset name='Left Playback Mixer Left Bypass Volume' 0;"
        command += "amixer -- cset name='Right Playback Mixer Right Bypass Volume' 0;"
        command += "amixer -- cset name='Right Playback Mixer Left Bypass Volume' 0;"
    else:
        # print("is enabled is ", is_enabled)
        # disenable amps, enable dry
        # knobs.set_bypass(sub_graph+"amp_nam1", False)
        # knobs.set_bypass(sub_graph+"amp_nam2", False)
        # knobs.set_bypass(sub_graph+"amp_nam2", False) # double due to ingen bug
        command += "amixer -- cset name='Left Playback Mixer Left DAC Switch' off;"
        command += "amixer -- cset name='Right Playback Mixer Right DAC Switch' off;"
        command += "amixer -- cset name='Left Playback Mixer Left Bypass Volume' 5;"
        command += "amixer -- cset name='Right Playback Mixer Right Bypass Volume' 5;"
        if hardware_state["mono"]:
            command += "amixer -- cset name='Right Playback Mixer Left Bypass Volume' 5;"
        else:
            command += "amixer -- cset name='Right Playback Mixer Left Bypass Volume' 0;"
    subprocess.call(command, shell=True)

    # communicate setting to MCU
    to_mcu_queue.put([176, cc_messages["BYPASS_CC"], 127 if main_enable else 0])
    # set_mono_sum_kill_dry(hardware_state["mono"], hardware_state["kill_dry"])


def process_cc(b_bytes):
    cc = b_bytes[1] # cc number
    v = b_bytes[2] # value 0-127
    # check if press on a is a short press vs hold, if short press, 
    # print("got bytes", b_bytes, "cc is ", cc)
    # then go to next preset in set list

    # check if we're bypass, footswitch B actions
    if cc == cc_messages["BYPASS_CC"]:
        # print("b foot switch", v)
        global b_tap_time
        if v == 127:# button down
            # print("b foot switch down")
            # set on time
            b_tap_time = time.perf_counter()
            # toggle bypass
            if PEDAL_TYPE in (pedal_types.ample, pedal_types.trails):
                # start counting for preset change
                footswitch_is_down["b"] = True
                footswitch_action_done["b"] = False
            else:
                effect_id_parameter, min_s, max_s = cc_effect_name_parameter_map[cc]
                effect_id, parameter = effect_id_parameter
                knobs.ui_knob_toggle(sub_graph+effect_id, parameter)
        else:
            # print("b foot switch up")
            # print("checking", time.perf_counter() - a_tap_time)
            # if we didn't switch presets
            if PEDAL_TYPE in (pedal_types.ample, pedal_types.trails):
                # print("b foot switch up")
                footswitch_is_down["b"] = False
                if not footswitch_action_done["b"]:
                    # print("b foot switch up toggle enable")
                    set_main_enable(not main_enable)
                else:
                    load_verbs_preset(current_preset_number[int(audio_side)-1], True)
            else:
                if time.perf_counter() - b_tap_time > B_HOLD_TIME:
                    b_tap_time = 0
                    # load next verbs preset 
                    n_p = (current_preset_number[0] + 1) % NUM_PRESETS
                    # print("loading next in set list", set_list_number)
                    load_verbs_preset(n_p)
    elif cc in cc_effect_name_parameter_map:
        effect_id_parameter, min_s, max_s = cc_effect_name_parameter_map[cc]
        effect_id, parameter = effect_id_parameter
        if (PEDAL_TYPE == pedal_types.trails):
            effect_id, parameter = get_trails_param(effect_id, parameter)
            ig_a, ig_b, min_s, max_s = reverse_trails_param(effect_id, parameter)
        # scale
        value = scale_number(v, 0, 127, min_s, max_s)
        # for trails quantise pitch param to ints
        if (PEDAL_TYPE == pedal_types.trails and parameter in ("pitch_param", "frequency_param")):
            value = round(value)
        # print("cc", v, value, effect_id, parameter)
        # check if we're crescendo, footswitch A actions
        if cc == cc_messages["CRESCENDO_CC"]:
            # value is processed in generic else
            # print("a foot switch", v, value, effect_id, parameter)
            if v == 127:# button down
                # print("a foot switch down")
                # set on time
                global a_tap_time
                a_tap_time = time.perf_counter()

                prev_a_tap_time[2] = prev_a_tap_time[1]
                prev_a_tap_time[1] = prev_a_tap_time[0]
                prev_a_tap_time[0] = a_tap_time
                # print("setting a tap time ", a_tap_time)
                if PEDAL_TYPE in (pedal_types.ample, pedal_types.trails):
                    footswitch_is_down["a"] = True
                    footswitch_action_done["a"] = False
                else:
                    knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
                    send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
            else:
                global set_list_number
                if PEDAL_TYPE in (pedal_types.ample, pedal_types.trails):
                    # print("a foot switch up")
                    footswitch_is_down["a"] = False
                    if not footswitch_action_done["a"]:
                        # print("a foot switch up toggling")
                        if (PEDAL_TYPE == pedal_types.trails):
                            # if the sequencer is currently on, we're doing tap tempo
                            if sequencer_on:
                                # calculate average time between beats

                                average_beat_time = statistics.fmean([abs(y-x) for (x, y) in itertools.pairwise(prev_a_tap_time)])
                                # if it's too large, wait for another beat
                                # print("average_beat_time is ", average_beat_time)
                                if average_beat_time < 4.0 and average_beat_time > 0.15:
                                    global step_duration
                                    step_duration = average_beat_time
                            else:
                                global sustain
                                sustain = not sustain
                                if sustain:
                                    v_s = 127
                                else:
                                    v_s = 0
                                value = scale_number(v_s, 0, 127, min_s, max_s)
                                knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
                                if effect_id == "turntable_stop1":
                                    knobs.ui_knob_change(sub_graph+"turntable_stop2", parameter, float(value))
                                send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
                        else:
                            knobs.ui_knob_toggle(sub_graph+"boost1", "on")
                            time.sleep(0.01)
                            knobs.ui_knob_toggle(sub_graph+"boost2", "on")
                    else:
                        # load next verbs preset in list
                        set_list = knobs.get_set_list()
                        load_verbs_preset_from_set_list(set_list[set_list_number], True)
                else:
                    # print("checking", time.perf_counter() - a_tap_time)
                    # send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
                    time_diff = time.perf_counter() - a_tap_time
                    if PEDAL_TYPE == pedal_types.verbs and time_diff < 0.2:
                        a_tap_time = 0
                        # load next verbs preset in list
                        set_list = knobs.get_set_list()
                        set_list_number = (set_list_number + 1) % len(set_list)
                        # print("loading next in set list", set_list_number)
                        load_verbs_preset_from_set_list(set_list[set_list_number], True)
        # set the values
        # onset and low cut are two modules each
        elif effect_id in ("delay1", "delay2", "delay3", "delay4"):
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            if (PEDAL_TYPE == pedal_types.verbs):
                knobs.ui_knob_change(sub_graph+"delay6", parameter, float(value))
            if (PEDAL_TYPE == pedal_types.trails):
                knobs.ui_knob_change(sub_graph+"delay2", parameter, float(value))
                knobs.ui_knob_change(sub_graph+"delay3", parameter, float(value))
                knobs.ui_knob_change(sub_graph+"delay4", parameter, float(value))
        elif effect_id == 'filter_uberheim1':
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            knobs.ui_knob_change(sub_graph+"filter_uberheim2", parameter, float(value))
        elif effect_id  == "wet_dry_stereo2" or effect_id == "sum1":
            # knobs.ui_knob_change(sub_graph+effect_id, parameter, 1.0-float(value))
            pass # processed already
        elif effect_id == 'stereo_reverb1':
            # only 1 side
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
        else:
            # print(f"param {parameter} value {value}")
            # if were ample, if were are not split, send to both sides, 
            if PEDAL_TYPE == pedal_types.ample:
                e = effect_id[:-1]
                if not hardware_state["split"]:
                    knobs.ui_knob_change(sub_graph+e+"1", parameter, float(value))
                    knobs.ui_knob_change(sub_graph+e+"2", parameter, float(value))
                else:
                    # otherwise check which side we need to send to
                    knobs.ui_knob_change(sub_graph+e+audio_side, parameter, float(value))
            else:
                knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
    elif cc == cc_messages["PRESET_CHANGE_CC"]:
        # change preset, loading values from file
        global verbs_initial_preset_loaded
        # print ("got preset change CC", v, verbs_initial_preset_loaded)
        if verbs_initial_preset_loaded:
            load_verbs_preset(v)
    elif cc == cc_messages["MIDI_CHANNEL_CHANGE"]:
        # iterate over all bindings, setting to new channel val.
        # print("midi channel is", v)
        knobs.set_channel(v)
        update_midi_ccs(v)
    elif cc == cc_messages["SAVE_PRESET_CC"]:
        # val is preset number, flush to file, 
        # json document of all presets, values and file names
        # key is preset number
        save_verbs_preset(v)
    elif cc == cc_messages["IMPORT_FILES_CC"]:
        knobs.ui_copy_irs()
    elif cc == cc_messages["MONO_SUM_CC"]:
        toggle_mono_sum()
    elif cc == cc_messages["SPLIT_CC"]:
        toggle_split()
    elif cc == cc_messages["SIDE_CC"]:
        toggle_side()
    elif cc == cc_messages["LUM_CC"]:
        # store luminance and send to MCU
        # print("got lum change", v)
        set_lum(v)
    elif cc == cc_messages["KILL_DRY_CC"]:
        if PEDAL_TYPE != pedal_types.ample: # trails and verbs have kill dry
            toggle_kill_dry()
        else:
            toggle_cab()

def scale_number(unscaled, from_min, from_max, to_min, to_max):
    return (to_max-to_min)*(unscaled-from_min)/(from_max-from_min)+to_min

def send_value_to_mcu(effect_name, parameter, value):
    # check if we need to send this value
    # print("sending to mcu", effect_name, parameter)
    if (PEDAL_TYPE == pedal_types.ample):
        effect_name = effect_name[:-1]+"1"
    effect_name = effect_name.rsplit('/', 1)[1]
    if (PEDAL_TYPE == pedal_types.trails):
        effect_name, parameter, min_s, max_s = reverse_trails_param(effect_name, parameter)
        # print("### MCU mapped param", effect_name, parameter, float(value))
    if (effect_name, parameter) in effect_name_parameter_cc_map:
        if (PEDAL_TYPE == pedal_types.trails):
            cc_num, ingore_min_s, ingore_max_s = effect_name_parameter_cc_map[(effect_name, parameter)]
        else:
            cc_num, min_s, max_s = effect_name_parameter_cc_map[(effect_name, parameter)]
        # scale it
        v = int(scale_number(value, min_s, max_s,  0, 127))
        # add to mcu queue
        # print("added", effect_name, parameter, value, "v is", v, "to mcu queue")
        add_to_mcu_queue(cc_num, v)

def add_to_mcu_queue(cc, value): # value needs to be scaled first
    v = int(max(min(value, 127), 0))
    to_mcu_queue.put([176, cc, v])

def send_loading_progress_to_mcu(value): # 0 - 100
    to_mcu_queue.put([176, cc_messages["LOADING_PROGRESS_CC"], int(value)])

def send_to_mcu():
    # pop from queue, send message
    # when preset is loaded, send all values and preset number
    # import done
    # send values so that MIDI changes will show on sliders
    try:
        while not EXIT_THREADS:
            e = to_mcu_queue.get(block=False)
            a = bytes(e)
            ser.write(a)
    except queue.Empty:
        pass

def process_hold_actions():
    # called often to check if timers have elapsed. 
    global b_tap_time
    global a_tap_time
    global prev_a_tap_time
    if footswitch_is_down["b"]:
        # check how long since last b action
        if not footswitch_action_done["b"] and time.perf_counter() - b_tap_time > B_HOLD_TIME:
            footswitch_action_done["b"] = True
            footswitch_action_time["b"] = time.perf_counter()
            b_tap_time = 0
            # load next verbs preset 
            n_p = (current_preset_number[int(audio_side)-1] + 1) % NUM_PRESETS
            # print("loading next in set list", set_list_number)
            load_verbs_preset(n_p, False)
        elif footswitch_action_done["b"] and time.perf_counter() - footswitch_action_time["b"] > PRESET_SWITCH_TIME:
            footswitch_action_time["b"] = time.perf_counter()
            # load next verbs preset 
            n_p = (current_preset_number[int(audio_side)-1] + 1) % NUM_PRESETS
            # print("loading next in set list", set_list_number)
            load_verbs_preset(n_p, False)

    if footswitch_is_down["a"]:
        time_diff = time.perf_counter() - a_tap_time
        global set_list_number
        if not footswitch_action_done["a"] and time_diff > B_HOLD_TIME:
            footswitch_action_done["a"] = True
            footswitch_action_time["a"] = time.perf_counter()
            a_tap_time = 0
            # load next verbs preset in list
            set_list = knobs.get_set_list()
            set_list_number = (set_list_number + 1) % len(set_list)
            # print("loading next in set list", set_list_number)
            load_verbs_preset_from_set_list(set_list[set_list_number], False)
        elif footswitch_action_done["a"] and time.perf_counter() - footswitch_action_time["a"] > PRESET_SWITCH_TIME:
            footswitch_action_time["a"] = time.perf_counter()
            # load next verbs preset in list
            set_list = knobs.get_set_list()
            set_list_number = (set_list_number + 1) % len(set_list)
            # print("loading next in set list", set_list_number)
            load_verbs_preset_from_set_list(set_list[set_list_number], False)

def process_sequencer():
    if sequencer_on:
        # check how long since we changed presets, 
        # if elapsed time is great that step time, change preset
        global last_step_time
        if (time.perf_counter() - last_step_time) > step_duration:
            last_step_time = time.perf_counter()
            n_p = (current_preset_number[0] + 1)
            if n_p > ((current_mode * 8) + 7 ):
                n_p = current_mode * 8
            # print("loading next in set list", set_list_number)
            load_verbs_preset(n_p, True, True)

def process_from_mcu():
    # read internal MIDI messages
    global current_bytes
    while not EXIT_THREADS:
        # first check if we need to process hold actions
        if PEDAL_TYPE in (pedal_types.ample, pedal_types.trails):
            process_hold_actions()
        if PEDAL_TYPE == pedal_types.trails:
            process_sequencer()
        msg = ser.read(3-len(current_bytes))
        if len(msg) == 0:
            break
        # print("got bytes from serial", msg)
        current_bytes = current_bytes + bytearray(msg)
        if len(current_bytes) == 3: # if we have a full message
            if current_bytes[0] == 176: #midi cc
                process_cc(current_bytes)
                current_bytes = bytearray()
            else:
                if current_bytes[1] == 176:
                    # something weird is going on, first byte isn't cc, shuffle
                    current_bytes = current_bytes[1:3]
                    break
        else:
            break


# def input_worker():
#     while not EXIT_THREADS:
#         for key, mask in selector.select(0.2):
#             device = key.fileobj
#             for event in device.read():
#                 # print(event)
#                 input_queue.put(event)

# hw_thread = None
# def add_hardware_listeners():
#     # # check if switches or pots have changed
#     # # 
#     # for knob in "left", "right":
#     #     on_knob_change(knob)
#     if not IS_REMOTE_TEST:
#         global hw_thread
#         hw_thread = threading.Thread(target=input_worker)
#         hw_thread.start()

# if __name__ == "__main__":
#     main()
