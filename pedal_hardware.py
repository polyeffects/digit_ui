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

# GPIO.setup("P8_17", GPIO.OUT)
# GPIO.setup("P8_18", GPIO.OUT)

# GPIO.setup("P9_12", GPIO.IN)
# GPIO.setup("P9_14", GPIO.IN)
# GPIO.setup("P9_16", GPIO.IN)

# footswitch_is_down = defaultdict(bool)
foot_callback = None
encoder_change_callback = None
switch_is_down = [False, False, False]
tap_down_timestamp = 0
step_down_timestamp = 0
bypass_down_timestamp = 0

knob_prev={"left":127, "right":127}
max_knob_speed = 20

input_queue = queue.Queue()
hardware_info = {}
try:
    with open("/pedal_state/hardware_info.json") as f:
        hardware_info = json.load(f)
except:
    hardware_info = {"revision": 9, "pedal": "digit"}

PEDAL_VERSION = hardware_info["revision"]

def effect_on(t=0.01):
    # global is_on
    # echo 1 > /sys/class/gpio/gpio131/value
    # echo 0 > /sys/class/gpio/gpio131/value
    if PEDAL_VERSION < 10:
        with open('/sys/class/gpio/gpio130/value', 'w') as f:
            f.write("1")
        time.sleep(t)
        with open('/sys/class/gpio/gpio130/value', 'w') as f:
            f.write("0")
    else:
        with open('/sys/class/gpio/gpio130/value', 'w') as f:
            f.write("1")

    # is_on = True

def effect_off(t=0.01):
    # global is_on
    if PEDAL_VERSION < 10:
        with open('/sys/class/gpio/gpio131/value', 'w') as f:
            f.write("1")
        time.sleep(t)
        with open('/sys/class/gpio/gpio131/value', 'w') as f:
            f.write("0")
    else:
        with open('/sys/class/gpio/gpio130/value', 'w') as f:
            f.write("0")
    # is_on = False

def setup_bypass():
    try:
        with open('/sys/class/gpio/export', 'w') as f:
            f.write(str(130))
        with open('/sys/class/gpio/export', 'w') as f:
            f.write(str(131))
    except OSError:
        pass
    time.sleep(1.5)
    with open('/sys/class/gpio/gpio130/direction', 'w') as f:
        f.write("out")
    with open('/sys/class/gpio/gpio131/direction', 'w') as f:
        f.write("out")
    global bypass_setup
    bypass_setup = True
    effect_on()

# from threading import Timer
# """Thanks to https://gist.github.com/walkermatt/2871026"""

# def debounce(wait):
#     """ Decorator that will postpone a functions
#         execution until after wait seconds
#         have elapsed since the last time it was invoked. """
#     def decorator(fn):
#         def debounced(*args, **kwargs):
#             def call_it():
#                 fn(*args, **kwargs)
#             try:
#                 debounced.t.cancel()
#             except(AttributeError):
#                 pass
#             debounced.t = Timer(wait, call_it)
#             #TODO: does this spawn too many threads on repeated calls and t.cancels?
#             debounced.t.start()
#         return debounced
#     return decorator

# possible foot actions
# on, off, tap, next preset, previous preset, step, send MIDI

# store all values as floats and then multiply all things acting on it
# multiply by 255 before sending

# actions are either set internal value, send MIDI or set digi pot

# has range and curve? 
# can map to multiple outputs cutoff and gain

def set_master_tempo():
    pass

def set_master_time_sig():
    pass

# def footswitch_just_down(footswitch):
#     footswitch_is_down[footswitch] = not footswitch_is_down[footswitch]
#     if footswitch_is_down[footswitch]:
#         print('tap event on', footswitch)
#     return footswitch_is_down[footswitch]

# called from main thread
initial_press = {30: True, 48: True, 46: True}
switch_down = {30: 1, 48: 1, 46: 1}
switch_up = {30: 0, 48: 0, 46: 0}
same_time_delay = 0.045 # 30 ms

prev_t = None
e_code = 0
e_value = 0
was_multi = False
multi_combo = ""

def button_is_together(a_t, b_t):
    return abs(a_t - b_t) < 0.02

def process_input():
    # pop from queue
    # t = time.perf_counter()
    try:
        global tap_down_timestamp
        global bypass_down_timestamp
        global step_down_timestamp
        global prev_t
        global e_code
        global e_value
        global was_multi
        global multi_combo

        while True:
            if prev_t and (time.perf_counter() - prev_t) > same_time_delay:
                # send switch press
                prev_t = None
                was_multi = False
                # print("got button press")
                if e_code == 30 and e_value == switch_down[e_code]: # tap down
                    foot_callback("tap_down", tap_down_timestamp)
                elif e_code == 48 and e_value == switch_down[e_code]: # tap down
                    foot_callback("step_down", step_down_timestamp)
                elif e_code == 46 and e_value == switch_down[e_code]: # tap down
                    foot_callback("bypass_down", bypass_down_timestamp)
            # if prev_t:
                # print("prev_t", prev_t, time.perf_counter( )-prev_t)

            e = input_queue.get(block=False)
            if e.code in (30, 48, 46) and initial_press[e.code] == True :
                # pressed down, so this value must be down
                switch_down[e.code] = e.value
                switch_up[e.code] = 1 - e.value
                initial_press[e.code] = False
                # print("setting initial button state")

            if prev_t:
                # if another press arrives before send, send it and cancel previous 
                if e.code in (30, 48) and e.value == switch_down[e.code] and e_code in  (30, 48): # tap + step down
                    prev_t = None
                    was_multi = True
                    multi_combo = "tap_step"
                    tap_down_timestamp = e.timestamp()
                    foot_callback("tap_step_down", tap_down_timestamp)
                elif e.code in (46, 48) and e.value == switch_down[e.code] and e_code in (46, 48): # step + bypass
                    prev_t = None
                    was_multi = True
                    bypass_down_timestamp = e.timestamp()
                    multi_combo = "step_bypass"
                    foot_callback("step_bypass_down", bypass_down_timestamp)
            else:
                if e.code == 30 and e.value == switch_down[e.code]: # tap down
                    prev_t = time.perf_counter()
                    tap_down_timestamp = e.timestamp()
                    e_code = e.code
                    e_value = e.value
                elif e.code == 48 and e.value == switch_down[e.code]: # step
                    prev_t = time.perf_counter()
                    step_down_timestamp = e.timestamp()
                    e_code = e.code
                    e_value = e.value
                elif e.code == 46 and e.value == switch_down[e.code]: # bypass
                    prev_t = time.perf_counter()
                    bypass_down_timestamp = e.timestamp()
                    e_code = e.code
                    e_value = e.value

            # each action clears the others states if multiple
            # if we get an up before down time is elapsed, send down first

            if e.code == 30 and e.value == switch_up[e.code]: # tap up
                if was_multi and multi_combo == "tap_step":
                    foot_callback("tap_step_up", tap_down_timestamp)
                else:
                    if prev_t:
                        prev_t = None
                        foot_callback("tap_down", tap_down_timestamp)
                    foot_callback("tap_up", tap_down_timestamp)
            elif e.code == 48 and e.value == switch_up[e.code]: # step
                prev_t = None
                if was_multi and multi_combo == "tap_step":
                    foot_callback("tap_step_up", step_down_timestamp)
                elif was_multi and multi_combo == "step_bypass":
                    foot_callback("step_bypass_up", step_down_timestamp)
                else:
                    if prev_t:
                        prev_t = None
                        foot_callback("step_down", step_down_timestamp)
                    foot_callback("step_up", step_down_timestamp)
            elif e.code == 46 and e.value == switch_up[e.code]: # bypass
                prev_t = None
                if was_multi and multi_combo == "step_bypass":
                    foot_callback("step_bypass_up", bypass_down_timestamp)
                else:
                    if prev_t:
                        prev_t = None
                        foot_callback("bypass_down", bypass_down_timestamp)
                    foot_callback("bypass_up", bypass_down_timestamp)

            if e.type == 2: # knob
                if PEDAL_VERSION < 10:
                    if e.code == 1: # left
                        encoder_change_callback(True, e.value)
                    if e.code == 0: # right
                        encoder_change_callback(False, e.value)
                else:
                    if e.code == 0: # left
                        encoder_change_callback(True, -e.value)
                    if e.code == 1: # right
                        encoder_change_callback(False, -e.value)
    except queue.Empty:
        pass

def input_worker():
    import selectors, evdev
    from evdev import InputDevice
    from selectors import DefaultSelector, EVENT_READ
    selector = selectors.DefaultSelector()
    knob_left = evdev.InputDevice('/dev/input/event1')
    footswitches = evdev.InputDevice('/dev/input/event2')
    knob_right = evdev.InputDevice('/dev/input/event3')
    # This works because InputDevice has a `fileno()` method.
    selector.register(knob_left, selectors.EVENT_READ)
    selector.register(knob_right, selectors.EVENT_READ)
    selector.register(footswitches, selectors.EVENT_READ)
    while True:
        if EXIT_THREADS:
            break
        if not bypass_setup:
            setup_bypass()
        # print("looping")
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
