import serial, os
# digit main
from collections import defaultdict
# import Adafruit_BBIO.GPIO as GPIO
import time, queue, threading, json, subprocess
# from Adafruit_BBIO.Encoder import RotaryEncoder, eQEP2, eQEP0
# left_encoder = RotaryEncoder(eQEP0)
# right_encoder = RotaryEncoder(eQEP2)
from static_globals import IS_REMOTE_TEST, PEDAL_TYPE, pedal_types
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

# footswitch_is_down = defaultdict(bool)
# shared to headless
verbs_initial_preset_loaded = False
a_tap_time = 0
b_tap_time = 0
B_HOLD_TIME = 1.0
NUM_PRESETS = 56
set_list_number = 0
current_preset_number = 0
audio_side = "1" # 1 or 2

input_queue = queue.Queue()
to_mcu_queue = queue.Queue()
ser = serial.Serial('/dev/ttyS0', 62500, timeout=0)

hardware_info = {"revision": 12, "pedal": "verbs"}


PEDAL_VERSION = hardware_info["revision"]

sub_graph = "/main/"
current_bytes = bytearray()

if PEDAL_TYPE == pedal_types.verbs:
    with open("/pedal_state/verbs_presets.json") as f:
        verbs_presets = json.load(f)
else:
    with open("/pedal_state/ample_presets.json") as f:
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
        }

try:
    with open("/pedal_state/hardware_state.json") as f:
        hardware_state = json.load(f)
        if "cab_enabled" not in hardware_state:
            hardware_state["cab_enabled"] = True
        if "split" not in hardware_state:
            hardware_state["split"] = False
except:
    hardware_state = {"mono": False, "kill_dry": False, "cab_enabled": True, "split": False}

if PEDAL_TYPE != pedal_types.verbs:
    hardware_state["kill_dry"] = True
    if hardware_state['split']:
        to_mcu_queue.put([176, cc_messages["SPLIT_CC"], int(hardware_state['split'])])

def set_mono_sum_kill_dry(mono, kill_dry):
    command = ""
    if mono:
        # with jack_connect, need to connect capture 1 to in 2
        command += "jack_connect system:capture_1 ingen:in_2;"
        command += "jack_disconnect system:capture_2 ingen:in_2;"
    else:
        command += "jack_connect system:capture_2 ingen:in_2;"
        command += "jack_disconnect system:capture_1 ingen:in_2;"

    if PEDAL_TYPE == pedal_types.verbs:
        if kill_dry:
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

set_mono_sum_kill_dry(hardware_state["mono"], hardware_state["kill_dry"])

if PEDAL_TYPE != pedal_types.verbs:
    # set cab disabled if disabled
    if hardware_state["cab_enabled"] == False:
        knobs.set_bypass(sub_graph+"mono_cab1", False)
        knobs.set_bypass(sub_graph+"mono_cab2", False)



# effect_name / parameter to CC number and range

if PEDAL_TYPE == pedal_types.verbs:
    effect_name_parameter_cc_map = {
            ("wet_dry_stereo2", "level") : (cc_messages["BYPASS_CC"], 0, 1),
            ("wet_dry_stereo1", "level") : (cc_messages["MIX_CC"], 0, 1),
            ("delay1", "Delay_1") : (cc_messages["ONSET_CC"], 0.01, 0.7), # also delay6
            ("filter_uberheim1", "cutoff") : (cc_messages["LOW_CUT_CC"], 0.01, 0.7), # also filter_uberheim2
            ("vca1", "gain") : (cc_messages["SMOOSH_CC"], 0, 1),
            ("sum1", "a") : (cc_messages["CRESCENDO_CC"], 0, 1),
            }
else:
    effect_name_parameter_cc_map = {
            ("boost1", "gain") : (cc_messages["BOOST_CC"], 1, 2), # bypass
            ("amp_nam1", "output_level") : (cc_messages["MIX_CC"], -20, 0), # volume
            ("amp_nam1", "input_level") : (cc_messages["ONSET_CC"], -20, 20), # gain
            ("tonestack1", "bass") : (cc_messages["LOW_CUT_CC"], 0.01, 0.9), #  bass
            ("tonestack1", "treble") : (cc_messages["SMOOSH_CC"], 0, 1), # treble
            ("tonestack1", "mid") : (cc_messages["MID_CC"], 0, 1), # treble
            ("boost1", "enable") : (cc_messages["CRESCENDO_CC"], 0, 1), # boost
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

def load_verbs_preset(p):
    # iterate over json file, ui_knob_change each value
    # verbs presets are index : {(effect_name, effect_parameter, value), 
    for effect_id, parameter, value in verbs_presets[str(p)]:
        if parameter == "ir":
            if effect_id in ("amp_nam1", "amp_nam2"):
                # load to left and right if we're in normal mode

                # if we're ample only send to the current side of MCU if split
                if hardware_state["split"]:
                    if str(audio_side) == effect_id[-1:]:
                        print("calling update nam json split, ", effect_id, value)
                        knobs.update_json(sub_graph+effect_id, value)
                else:
                    if effect_id[-1:] == "1": # side 1s value to both sides in non-split mode
                        print("calling update nam json not split, ", effect_id, value)
                        knobs.update_json(sub_graph+effect_id, value)
                        knobs.update_json(sub_graph+effect_id[:-1]+"2", value)
            else:
                if PEDAL_TYPE == pedal_types.ample:
                    # if we're ample only send to the current side of MCU if split
                    if hardware_state["split"]:
                        if str(audio_side) == effect_id[-1:]:
                            print("calling update ir split, ", effect_id, value)
                            knobs.update_ir(sub_graph+effect_id, value)
                    else:
                        if effect_id[-1:] == "1": # side 1s value to both sides in non-split mode
                            print("calling update ir not split, ", effect_id, value)
                            knobs.update_ir(sub_graph+effect_id, value)
                            knobs.update_ir(sub_graph+effect_id[:-1]+"2", value)
                else:
                    knobs.update_ir(sub_graph+effect_id, value)
            time.sleep(0.2)
        else:
            time.sleep(0.03)
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            if PEDAL_TYPE == pedal_types.ample:
                # if we're ample only send to the current side of MCU if split
                if hardware_state["split"]:
                    if str(audio_side) == effect_id[-1:]:
                        send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
                else:
                    if effect_id[-1:] == "1": # side 1s value to both sides in non-split mode
                        send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
                        send_value_to_mcu(sub_graph+effect_id[:-1]+"2", parameter, float(value))
            else:
                send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
    global current_preset_number
    current_preset_number = int(p)
    to_mcu_queue.put([176, cc_messages["PRESET_CHANGE_CC"], int(p)])

def import_done():
    # if we've got a set list now, parse it
    try:
        with open("/pedal_state/set_list.txt") as f:
            a = f.read()
            s = a.strip().split(',')
            s_l = [int(b) for b in s if int(b) >= 0 and int(b) < 56]
            knobs.save_set_list(s_l)
    except FileNotFoundError:
        pass
    # send to MCU that it's imported, fail or success...
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def save_verbs_preset(p):
    c_p = verbs_presets[str(p)]
    # print("preset is", c_p)
    n_p = [[effect_id, parameter, knobs.get_current_parameter_value(sub_graph+effect_id, parameter) if effect_id != "quad_ir_reverb1" else v] for effect_id, parameter, v in c_p ]
    verbs_presets[str(p)] = n_p

    if PEDAL_TYPE == pedal_types.verbs:
        with open("/pedal_state/verbs_presets.json", "w") as f:
            json.dump(verbs_presets, f)
    else:
        with open("/pedal_state/ample_presets.json", "w") as f:
            json.dump(verbs_presets, f)
    os.sync()

def update_midi_ccs(channel):
    for cc in cc_effect_name_parameter_map.keys():
        effect_id_parameter, min_s, max_s = cc_effect_name_parameter_map[cc]
        effect_id, parameter = effect_id_parameter
        # scale
        # set the values
        # onset and low cut are two modules each
        if effect_id == "delay1":
            knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, cc)
            knobs.set_midi_cc(sub_graph+"delay6", parameter, channel, cc)
        elif effect_id == 'filter_uberheim1':
            knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, cc)
            knobs.set_midi_cc(sub_graph+"filter_uberheim2", parameter, channel, cc)
        else:
            if cc == cc_messages["CRESCENDO_CC"]: # remap these
                knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, 18)
            elif cc == cc_messages["BYPASS_CC"]: # remap these
                knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, 19)
            else:
                knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, cc)
                # todo bind both sides of Ample

def toggle_mono_sum():
    # toggle value, write out to file to persist
    hardware_state["mono"] = not hardware_state["mono"] # {"mono": False, "kill_dry": False}
    write_hardware_state()
    set_mono_sum_kill_dry(hardware_state["mono"], hardware_state["kill_dry"])
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def toggle_split():
    # toggle value, write out to file to persist
    hardware_state["split"] = not hardware_state["split"] # {"mono": False, "kill_dry": False}
    write_hardware_state()
    to_mcu_queue.put([176, cc_messages["SPLIT_CC"], int(hardware_state['split'])])

def toggle_side():
    # toggle value, write out to file to persist
    # only do anything if we are split
    if hardware_state["split"]:
        global audio_side
        if audio_side == "1":
            audio_side = "2"
        else:
            audio_side = "1"
        to_mcu_queue.put([176, cc_messages["SIDE_CC"], int(audio_side)-1])

def toggle_cab():
    # toggle value, write out to file to persist
    hardware_state["cab_enabled"] = not hardware_state["cab_enabled"]
    knobs.set_bypass(sub_graph+"mono_cab1", hardware_state["cab_enabled"])
    knobs.set_bypass(sub_graph+"mono_cab2", hardware_state["cab_enabled"])
    write_hardware_state()
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def toggle_kill_dry():
    # toggle value, write out to file to persist
    hardware_state["kill_dry"] = not hardware_state["kill_dry"] # {"mono": False, "kill_dry": False}
    write_hardware_state()
    set_mono_sum_kill_dry(hardware_state["mono"], hardware_state["kill_dry"])
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def set_main_enable(is_enabled):
    command = ""
    # set bypass state, 
    global main_enable
    main_enable = is_enabled
    # update mixer for dry signal
    if is_enabled:
        print("is enabled is ", is_enabled)
        # enable amps, disable dry
        knobs.set_bypass(sub_graph+"amp_nam1", True)
        knobs.set_bypass(sub_graph+"amp_nam2", True)
        command += "amixer -- cset name='Left Playback Mixer Left DAC Switch' on;"
        command += "amixer -- cset name='Right Playback Mixer Right DAC Switch' on;"
        command += "amixer -- cset name='Left Playback Mixer Left Bypass Volume' 0;"
        command += "amixer -- cset name='Right Playback Mixer Right Bypass Volume' 0;"
        command += "amixer -- cset name='Right Playback Mixer Left Bypass Volume' 0;"
    else:
        print("is enabled is ", is_enabled)
        # disenable amps, enable dry
        knobs.set_bypass(sub_graph+"amp_nam1", False)
        knobs.set_bypass(sub_graph+"amp_nam2", False)
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
    # print("got bytes", b_bytes)
    # then go to next preset in set list
    if cc in cc_effect_name_parameter_map:
        effect_id_parameter, min_s, max_s = cc_effect_name_parameter_map[cc]
        effect_id, parameter = effect_id_parameter
        # scale
        value = scale_number(v, 0, 127, min_s, max_s)
        # check if we're crescendo, footswitch A actions
        if cc == cc_messages["CRESCENDO_CC"]:
            # value is processed in generic else
            # print("a foot switch", value)
            if v == 127:# button down
                # print("a foot switch down")
                # set on time
                global a_tap_time
                a_tap_time = time.perf_counter()
                # print("setting a tap time ", a_tap_time)
                knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
                send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
            else:
                knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
                # print("a foot switch up")
                # print("checking", time.perf_counter() - a_tap_time)
                send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
                if time.perf_counter() - a_tap_time < 0.2:
                    a_tap_time = 0
                    # load next verbs preset in list
                    set_list = knobs.get_set_list()
                    global set_list_number
                    set_list_number = (set_list_number + 1) % len(set_list)
                    # print("loading next in set list", set_list_number)
                    load_verbs_preset(set_list[set_list_number])
        # check if we're bypass, footswitch B actions
        elif cc == cc_messages["BYPASS_CC"]:
            # print("b foot switch", value)
            if v == 127:# button down
                # print("b foot switch down")
                # set on time
                global b_tap_time
                b_tap_time = time.perf_counter()
                # toggle bypass
                set_main_enable(not main_enable)
            else:
                # print("b foot switch up")
                # print("checking", time.perf_counter() - a_tap_time)
                if time.perf_counter() - b_tap_time > B_HOLD_TIME:
                    b_tap_time = 0
                    # load next verbs preset 
                    n_p = (current_preset_number + 1) % NUM_PRESETS
                    # print("loading next in set list", set_list_number)
                    load_verbs_preset(n_p)
        # set the values
        # onset and low cut are two modules each
        if effect_id == "delay1":
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            knobs.ui_knob_change(sub_graph+"delay6", parameter, float(value))
        elif effect_id == 'filter_uberheim1':
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            knobs.ui_knob_change(sub_graph+"filter_uberheim2", parameter, float(value))
        elif effect_id  == "wet_dry_stereo2" or effect_id == "sum1":
            # knobs.ui_knob_change(sub_graph+effect_id, parameter, 1.0-float(value))
            pass # processed already
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
    elif cc == cc_messages["KILL_DRY_CC"]:
        if PEDAL_TYPE == pedal_types.verbs:
            toggle_kill_dry()
        else:
            toggle_cab()

def scale_number(unscaled, from_min, from_max, to_min, to_max):
    return (to_max-to_min)*(unscaled-from_min)/(from_max-from_min)+to_min

def send_value_to_mcu(effect_name, parameter, value):
    # check if we need to send this value
    # print("sending to mcu", effect_name, parameter)
    effect_name = effect_name.rsplit('/', 1)[1]
    if (effect_name, parameter) in effect_name_parameter_cc_map:
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

def process_from_mcu():
    # read internal MIDI messages
    global current_bytes
    while not EXIT_THREADS:
        msg = ser.read(3-len(current_bytes))
        if len(msg) == 0:
            break
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
