# digit main
from collections import defaultdict
import Adafruit_BBIO.GPIO as GPIO
import time
from Adafruit_BBIO.Encoder import RotaryEncoder, eQEP2, eQEP0
left_encoder = RotaryEncoder(eQEP0)
right_encoder = RotaryEncoder(eQEP2)

is_on = False
KNOB_MAX = 255

GPIO.setup("P8_17", GPIO.OUT)
GPIO.setup("P8_18", GPIO.OUT)

GPIO.setup("P9_12", GPIO.IN)
GPIO.setup("P9_14", GPIO.IN)
GPIO.setup("P9_16", GPIO.IN)


def effect_on(t=0.001):
    global is_on
    GPIO.output("P8_17", GPIO.HIGH)
    time.sleep(t)
    GPIO.output("P8_17", GPIO.LOW)
    is_on = True

def effect_off(t=0.001):
    global is_on
    GPIO.output("P8_18", GPIO.HIGH)
    time.sleep(t)
    GPIO.output("P8_18", GPIO.LOW)
    is_on = False

from threading import Timer
"""Thanks to https://gist.github.com/walkermatt/2871026"""

def debounce(wait):
    """ Decorator that will postpone a functions
        execution until after wait seconds
        have elapsed since the last time it was invoked. """
    def decorator(fn):
        def debounced(*args, **kwargs):
            def call_it():
                fn(*args, **kwargs)
            try:
                debounced.t.cancel()
            except(AttributeError):
                pass
            debounced.t = Timer(wait, call_it)
            #TODO: does this spawn too many threads on repeated calls and t.cancels?
            debounced.t.start()
        return debounced
    return decorator

# possible foot actions
# on, off, tap, next preset, previous preset, step, send MIDI

def get_encoder(knob):
    encoder = None
    if knob == "left":
        encoder = left_encoder
    else:
        encoder = right_encoder

    cur_pos = encoder.position
    if cur_pos > KNOB_MAX:
        encoder.position = KNOB_MAX
        cur_pos = KNOB_MAX
    elif cur_pos < 0:
        encoder.position = 0
        cur_pos = 0
    return cur_pos

def set_encoder_value(knob, value):
    encoder = None
    if knob == "left":
        encoder = left_encoder
    else:
        encoder = right_encoder
    encoder.position = value

# store all values as floats and then multiply all things acting on it
# multiply by 255 before sending

# actions are either set internal value, send MIDI or set digi pot

# has range and curve? 
# can map to multiple outputs cutoff and gain

# def on_knob_change(knob):
#     cur_value = 0
#     if knob == "left":
#         cur_value = get_encoder(left_encoder)
#     else:
#         cur_value = get_encoder(right_encoder)
#     if cur_value != value_cache[target]:
#         print("knob value is", cur_value)
#         knob_mapping[knob](cur_value)
#         value_cache[target] = cur_value

def set_master_tempo():
    pass

def set_master_time_sig():
    pass

@debounce(0.1) #debounce to call event only after stable for 0.1s
def tap(gpio):
    print('tap event on', gpio)

@debounce(0.1) #debounce to call event only after stable for 0.1s
def toggle_reverb(gpio):
    print('toggle reverb event on', gpio)

@debounce(0.1) #debounce to call event only after stable for 0.1s
def toggle_delay(gpio):
    print('toggle delay event on', gpio)

def add_hardware_listeners():
    GPIO.add_event_detect("P9_12", GPIO.RISING, tap)
    GPIO.add_event_detect("P9_14", GPIO.RISING, toggle_reverb)
    GPIO.add_event_detect("P9_16", GPIO.RISING, toggle_delay)


        # # check if switches or pots have changed
        # # 
        # for knob in "left", "right":
        #     on_knob_change(knob)

# if __name__ == "__main__":
#     main()
