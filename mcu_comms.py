import serial
# digit main
from collections import defaultdict
# import Adafruit_BBIO.GPIO as GPIO
import time, queue, threading, json
# from Adafruit_BBIO.Encoder import RotaryEncoder, eQEP2, eQEP0
# left_encoder = RotaryEncoder(eQEP0)
# right_encoder = RotaryEncoder(eQEP2)
from static_globals import IS_REMOTE_TEST
# is_on = False
KNOB_MAX = 255
EXIT_THREADS = False
bypass_setup = False
knobs = None # set from headless

# GPIO.setup("P8_17", GPIO.OUT)
# GPIO.setup("P8_18", GPIO.OUT)

# GPIO.setup("P9_12", GPIO.IN)
# GPIO.setup("P9_14", GPIO.IN)
# GPIO.setup("P9_16", GPIO.IN)

# footswitch_is_down = defaultdict(bool)

input_queue = queue.Queue()
to_mcu_queue = queue.Queue()
ser = serial.Serial('/dev/ttyS0', 62500, timeout=0)

hardware_info = {"revision": 12, "pedal": "verbs"}

PEDAL_VERSION = hardware_info["revision"]

sub_graph = "/main/"
current_bytes = bytearray()

with open("/pedal_state/verbs_presets.json") as f:
    verbs_presets = json.load(f)

cc_messages = {"ONSET_CC": 14,
        "MIX_CC": 15,
        "LOW_CUT_CC": 16,
        "SMOOSH_CC": 17,
        "CRESCENDO_CC": 43,
        "BYPASS_CC": 44,
# internal only to CPU analog side
        "PRESET_CHANGE_CC": 50,
        "MIDI_CHANNEL_CHANGE": 51,
        "SAVE_PRESET_CC": 52,
        "IMPORT_FILES_CC": 53,
# internal to mcu
        "IMPORT_DONE_CC": 54,
        "LOADING_PROGRESS_CC": 55}

# effect_name / parameter to CC number and range
effect_name_parameter_cc_map = {
        ("wet_dry_stereo2", "level") : (cc_messages["BYPASS_CC"], 0, 1),
        ("wet_dry_stereo1", "level") : (cc_messages["MIX_CC"], 0, 1),
        ("delay1", "Delay_1") : (cc_messages["ONSET_CC"], 0.01, 0.1), # also delay6
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

def load_verbs_preset(p):
    # iterate over json file, ui_knob_change each value
    # verbs presets are index : {(effect_name, effect_parameter, value), 
    for effect_id, parameter, value in verbs_presets[str(p)]:
        if parameter == "ir":
            knobs.update_ir(sub_graph+effect_id, value)
            time.sleep(0.2)
        elif effect_id  == "wet_dry_stereo2":
            time.sleep(0.03)
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            send_value_to_mcu(sub_graph+effect_id, parameter, 1.0-float(value))
        else:
            time.sleep(0.03)
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            send_value_to_mcu(sub_graph+effect_id, parameter, float(value))
    to_mcu_queue.put([176, cc_messages["PRESET_CHANGE_CC"], int(p)])

def import_done():
    # send to MCU that it's imported, fail or success...
    to_mcu_queue.put([176, cc_messages["IMPORT_DONE_CC"], 127])

def save_verbs_preset(p):
    c_p = verbs_presets[str(p)]
    # print("preset is", c_p)
    n_p = [[effect_id, parameter, knobs.get_current_parameter_value(sub_graph+effect_id, parameter) if effect_id != "quad_ir_reverb1" else v] for effect_id, parameter, v in c_p ]
    verbs_presets[str(p)] = n_p
    with open("/pedal_state/verbs_presets.json", "w") as f:
        json.dump(verbs_presets, f)

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
            knobs.set_midi_cc(sub_graph+effect_id, parameter, channel, cc)

def process_cc(b_bytes):
    cc = b_bytes[1] # cc number
    v = b_bytes[2] # value 0-127
    if cc in cc_effect_name_parameter_map:
        effect_id_parameter, min_s, max_s = cc_effect_name_parameter_map[cc]
        effect_id, parameter = effect_id_parameter
        # scale
        value = scale_number(v, 0, 127, min_s, max_s)
        # set the values
        # onset and low cut are two modules each
        if effect_id == "delay1":
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            knobs.ui_knob_change(sub_graph+"delay6", parameter, float(value))
        elif effect_id == 'filter_uberheim1':
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
            knobs.ui_knob_change(sub_graph+"filter_uberheim2", parameter, float(value))
        elif effect_id  == "wet_dry_stereo2":
            knobs.ui_knob_change(sub_graph+effect_id, parameter, 1.0-float(value))
        else:
            knobs.ui_knob_change(sub_graph+effect_id, parameter, float(value))
    elif cc == cc_messages["PRESET_CHANGE_CC"]:
        # change preset, loading values from file
        load_verbs_preset(v)
    elif cc == cc_messages["MIDI_CHANNEL_CHANGE"]:
        # iterate over all bindings, setting to new channel val.
        knobs.set_channel(v)
        update_midi_ccs(v)
    elif cc == cc_messages["SAVE_PRESET_CC"]:
        # val is preset number, flush to file, 
        # json document of all presets, values and file names
        # key is preset number
        save_verbs_preset(v)
    elif cc == cc_messages["IMPORT_FILES_CC"]:
        knobs.ui_copy_irs()

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
        while True:
            e = to_mcu_queue.get(block=False)
            a = bytes(e)
            ser.write(a)
    except queue.Empty:
        pass

def process_from_mcu():
    # read internal MIDI messages
    global current_bytes
    while True:
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


def input_worker():
    while True:
        if EXIT_THREADS:
            break
        for key, mask in selector.select(0.2):
            device = key.fileobj
            for event in device.read():
                # print(event)
                input_queue.put(event)

hw_thread = None
def add_hardware_listeners():
    # # check if switches or pots have changed
    # # 
    # for knob in "left", "right":
    #     on_knob_change(knob)
    if not IS_REMOTE_TEST:
        global hw_thread
        hw_thread = threading.Thread(target=input_worker)
        hw_thread.start()

# if __name__ == "__main__":
#     main()
