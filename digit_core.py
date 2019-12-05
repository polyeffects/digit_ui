##################### DIGIT #######
import sys, time, json, os.path, os, subprocess, queue, threading
from multiprocessing import Process, Queue
from enum import Enum
##### Hardware backend
# --------------------------------------------------------------------------------------------------------
import pedal_hardware, digit_frontend
######## Carla
# --------------------------------------------------------------------------------------------------------
from enum import IntEnum
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit

# def signalHandler(sig, frame):
#     if sig in (SIGINT, SIGTERM):
#         gCarla.term = True

# os.sched_setaffinity(0, (0, 1, 3))

pedal_hardware.add_hardware_listeners()
ui_messages = Queue()
core_messages = Queue()

def send_ui_message(command, args):
    ui_messages.put((command, args))

# --------------------------------------------------------------------------------------------------------

def map_parameter(source, effect_name, parameter, rmin=0, rmax=1):
    if source == "left" or source == "right":
        # mapping and encoder
        set_knob_current_effect(source, effect_name, parameter, rmin, rmax)
        # print("mapping knob core")

def next_preset():
    send_ui_message("jump_to_preset", (True, 1))

def previous_preset():
    send_ui_message("jump_to_preset", (True, -1))

def jump_to_preset(num):
    send_ui_message("jump_to_preset", (False, num))

# signal(SIGINT,  signalHandler)
# signal(SIGTERM, signalHandler)

class Encoder():
    # name, min, max, value
    def __init__(self, starteffect="", startparameter=""):
        self.effect = starteffect
        self.parameter = startparameter
        self.speed = 1
        self.rmin = 0
        self.rmax = 1


knob_map = {"left": Encoder("delay1", "Amp_5"), "right": Encoder("delay1", "Feedback_4")}

current_bpm = 120
current_preset = "Default Preset"
command_status = [-1, -1]
midi_channel = 1
# is_loading = {"reverb":False, "cab":False}

mixer_is_connected = False
effects_are_connected = False
knobs_are_initial_mapped  = False

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

### Assignable actions
# 

Actions = Enum("Actions", """set_value
tap
toggle_pedal toggle_delay toggle_cab toggle_reverb
next_step
set_tempo
send_cc
select_preset
next_preset
previous_preset
next_action_group previous_action_group
toggle_effect
""")
foot_action_groups = [{"tap_up":[Actions.tap] , "step_up": [Actions.toggle_delay], "bypass_up":[Actions.toggle_pedal],
    "tap_step_up": [Actions.previous_preset], "step_bypass_up": [Actions.next_preset]}]
current_action_group = 0

def handle_foot_change(switch_name, timestamp):
    action = foot_action_groups[current_action_group][switch_name][0]
    params = None
    if len(foot_action_groups[current_action_group][switch_name]) > 1:
        params = foot_action_groups[current_action_group][switch_name][1:]
    if action is Actions.tap:
        handle_tap(timestamp)
    elif action is Actions.toggle_pedal:
        handle_bypass()
    elif action is Actions.toggle_delay:
        toggle_enabled("delay1")
        toggle_enabled("delay2")
        toggle_enabled("delay3")
        toggle_enabled("delay4")
        send_ui_message("set_plugin_state", ("delay1", plugin_state["delay1"]))
        send_ui_message("set_plugin_state", ("delay2", plugin_state["delay2"]))
        send_ui_message("set_plugin_state", ("delay3", plugin_state["delay3"]))
        send_ui_message("set_plugin_state", ("delay4", plugin_state["delay4"]))

    elif action is Actions.toggle_cab:
        toggle_enabled("cab")

    elif action is Actions.toggle_reverb:
        toggle_enabled("reverb")

    elif action is Actions.next_step:
        pass

    elif action is Actions.set_tempo:
        pass

    elif action is Actions.send_cc:
        pass

    elif action is Actions.select_preset:
        pass

    elif action is Actions.next_preset:
        next_preset()

    elif action is Actions.previous_preset:
        previous_preset()

    elif action is Actions.next_action_group:
        pass

    elif action is Actions.previous_action_group:
        pass

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
        if bpm > 30 and bpm < 250:
            # set host BPM
            set_bpm(bpm)

    # record start time
    start_tap_time = current_tap

def handle_bypass():
    # global bypass
    plugin_state["global"] = not plugin_state["global"]
    send_ui_message("set_plugin_state", ("global", plugin_state["global"] ))
    if plugin_state["global"]:
        pedal_hardware.effect_on()
    else:
        pedal_hardware.effect_off()

pedal_hardware.foot_callback = handle_foot_change
pedal_hardware.encoder_change_callback = handle_encoder_change

p = Process(name="digit_frontend.py", target=digit_frontend.ui_worker, args=(ui_messages, core_messages))
p.start()

while not SHOULD_EXIT:
    # print("processing GUI events in CALLBACK")
    sleep(0.01)
    # check if encoders have changed
    pedal_hardware.process_input()

pedal_hardware.EXIT_THREADS = True
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
print("Normal exit")
exit(1)
