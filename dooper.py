"""
A Python library for interfacing with SooperLooper.

Tracks full state and provides interface to all loop commands. Almost a complete client, just missing saving sessions.
"""

import liblo
from collections import namedtuple
from threading import Event, Lock
import subprocess

# Quantize and relative sync are actually global looper parameters, but SL handles them via the loop interface. We handle them separately as special cases so they are commented below but left for reference.
loop_parameters_settable = (
    'rec_thresh',  	# expected range is 0 -> 1
    'feedback',    	# range 0 -> 1
    'dry',         	# range 0 -> 1
    'wet',         	# range 0 -> 1
    'input_gain',    # range 0 -> 1
    'rate',        	# range 0.25 -> 4.0
    'scratch_pos',  	 # 0 -> 1
    'delay_trigger',  # any changes
    'quantize', # 0 = off, 1 = cycle, 2 = 8th, 3 = loop
    'round',          # 0 = off,  not 0 = on
    'redo_is_tap',    # 0 = off,  not 0 = on
    'sync',           # 0 = off,  not 0 = on
    'playback_sync',  # 0 = off,  not 0 = on
    'use_rate',       # 0 = off,  not 0 = on
    'fade_samples',   # 0 -> ...
    'use_feedback_play',   # 0 = off,  not 0 = on
    'use_common_ins',   # 0 = off,  not 0 = on
    'use_common_outs',   # 0 = off,  not 0 = on
   'relative_sync',   # 0 = off, not 0 = on
    'use_safety_feedback',   # 0 = off, not 0 = on
    'pan_1',        	# range 0 -> 1
    'pan_2',        	# range 0 -> 1
    'pan_3',        	# range 0 -> 1
    'pan_4',        	# range 0 -> 1
    'input_latency', # range 0 -> ...
    'output_latency', # range 0 -> ...
    'trigger_latency', # range 0 -> ...
    'autoset_latency',  # 0 = off, not 0 = on
    'mute_quantized',  # 0 = off, not 0 = on
    'overdub_quantized', # 0 == off, not 0 = on
    'pitch_shift', # range 0 -> 1
    'stretch_ratio', # range 0 -> 1
    )

loop_parameters_gettable = (
    'state',   # codes mapped below
    'next_state',  # same as state
    'loop_len',  # in seconds
    'loop_pos',  # in seconds
    'cycle_len', # in seconds
    'free_time', # in seconds
    'total_time', # in seconds
    'rate_output',
    'channel_count',
    'in_peak_meter',  # absolute float sample value 0.0 -> 1.0 (or higher)
    'out_peak_meter',  # absolute float sample value 0.0 -> 1.0 (or higher)
    'is_soloed',       # 1 if soloed, 0 if not
    'waiting',
    )

loop_parameters = loop_parameters_gettable + loop_parameters_settable

loop_commands = (
    'record',
    'overdub',
    'multiply',
    'insert',
    'replace',
    'reverse',
    'mute',
    'undo',
    'redo',
    'oneshot',
    'trigger',
    'substitute',
    'undo_all',
    'redo_all',
    'mute_on',
    'mute_off',
    'solo',
    'pause',
    'solo_next',
    'solo_prev',
    'record_solo',
    'record_solo_next',
    'record_solo_prev',
    'set_sync_pos',
    'reset_sync_pos'
    'scratch',
    )

looper_parameters = (
    'tempo',
    'eighth_per_cycle',
    'dry', # range 0 -> 1 affects common input passthru
    'wet', # range 0 -> 1  affects common output level
    'input_gain', # range 0 -> 1  affects common input gain
    'sync_source', # -3 = internal, -2 = midi, -1 = jack, 0 = none, # > 0 = loop number (1 indexed)
    'tap_tempo', # any changes
    'save_loop', # any change triggers quick save, be careful
    'auto_disable_latency',  # when 1, disables compensation when monitoring main inputs
    'select_next_loop',  # any changes
    'select_prev_loop',  # any changes
    'select_all_loops',   # any changes
    'selected_loop_num',  # -1 = all, 0->N selects loop instances (first loop is 0, etc)
    'output_midi_clock' , # 0 no 1 yes
    'smart_eighths'  # 0 no 1 yes
    )

# Map sl's integer codes to loop states
state_codes = {-1: 'unknown',
               0: 'Off',
               1: 'WaitStart', # Waiting to start recording
               2: 'Recording',
               3: 'WaitStop', # Waiting to stop recording
               4: 'Playing', # Or maybe waiting to mute
               5: 'Overdubbing',
               6: 'Multiplying',
               7: 'Inserting',
               8: 'Replacing',
               9: 'Delay',
               10: 'Muted', # Or maybe waiting to play
               11: 'Scratching',
               12: 'OneShot',
               13: 'Substitute',
               14: 'Paused',
               20: 'Off and muted'} #20 isn't documented...


class LooperThread:
    """
    Handles I/O with SooperLooper via OSC. Organizes loops.

    Uses a threaded liblo server to register for updates and automatically track looper and loop state.

    See documentation here: http://essej.net/sooperlooper/doc_osc.html

    """

    def __init__(self, port=9950, sl_port=9951, verbose=False):
        self.port = port
        self.sl_port = sl_port
        self.verbose = verbose

        self.server = liblo.ServerThread(self.port) #Define liblo server for replies

        self.ping_flag = Event()

        self.loop_count = 0
        self.loops = []

        self.loop_callbacks = []
        self.looper_callbacks = []
        self.ping_callbacks = []
        self.loop_added_callbacks = []
        self.loop_removed_callbacks = []
        self.midi_binding_callbacks = []

        #self.start_server()

    def __repr__(self):
        return 'LooperThread(port={}, sl_port={}, verbose={})'.format(self.port, self.sl_port, self.verbose)


    def __setattr__(self, name, val):
        if name in ['sync_source', 'quantize', 'selected_loop_num', 'output_midi_clock', 'smart_eighths']:
            super().__setattr__(name, val)

        elif name in looper_parameters:
            self.set(name, val)

        else:
            self.__dict__[name] = val

    def start_server(self):
        # actually spawn sooplerlooper as well
        subprocess.Popen(['/usr/bin/sooperlooper'])

        self.server.add_method('/sl/ping', None, self.ping_responder)
        self.server.add_method('/sl/loop', None, self.loop_responder)
        self.server.add_method('/sl/looper', None, self.looper_responder)
        self.server.add_method('/sl/loop_num', None, self.loop_num_responder)
        self.server.add_method('/sl/midi_bindings', None, self.midi_binding_responder)

        self.server.start()
        self.initialize()
        self.register_updates()

    def stop_server(self):
        self.server.del_method('/sl/ping', None)
        self.server.del_method('/sl/loop', None)
        self.server.del_method('/sl/looper', None)
        self.server.del_method('/sl/loop_num', None)
        self.server.del_method('/sl/midi_bindings', None)
        # actually kill sooplerlooper as well
        self.send_osc('/quit')

        self.unregister_updates()
        self.server.stop()

    def initialize(self):
        self.loop_count = 0
        self.loops = []
        attempt = 0
        while not self.ping():
            attempt = attempt + 1
            if attempt > 50: # 50 seconds
                print("No ping reply from SooperLooper")
                return

        for param in looper_parameters:
            self.send_osc('/get', param, self.server.url, '/sl/looper')


        #Quantize and relative sync are global, but control relies on a loop
        self.send_osc('/sl/0/get', 'quantize', self.server.url, '/sl/looper')
        self.send_osc('/sl/0/get', 'relative_sync', self.server.url, '/sl/looper')


        if self.loop_count:
            for i in range(self.loop_count):
                self.loops.append(Loop(self, i))
                for param in loop_parameters:
                    self.loops[i].get(param)
        else:
            print("Loop count is zero")

    def send_osc(self, path, *args):
        if self.verbose:
            print('Sending OSC message: {} {}'.format(path, args))
        liblo.send(self.sl_port, liblo.Message(path, *args))

    def ping_responder(self, path, args):
        if self.verbose:
            print('ping Received OSC message: {} {}'.format(path, args))

        self.loop_count = args[2]
        self.ping_flag.set()

        for f in self.ping_callbacks:
            f(args)

    def loop_num_responder(self, path, args):
        """ Listens for replies from SL about loop count"""
        if self.verbose:
            print('loop num responder Received OSC message: {} {} server {}'.format(path, args, self.server.url))
        prev_loop_count = self.loop_count
        self.loop_count = args[2]
        if self.loop_count > prev_loop_count:
            for loop_num in range(prev_loop_count, self.loop_count):
            # register new loop
                self.loops.append(Loop(self, loop_num))
                for f in self.loop_added_callbacks:
                    f(loop_num)
                for param in loop_parameters:
                    self.loops[loop_num].get(param)
                    self.send_osc('/sl/' + str(loop_num) + '/register_auto_update', param, 100, self.server.url, '/sl/loop')
        elif self.loop_count < prev_loop_count:
            loop_num = self.loop_count # instead of + 1 as they are counting from 1
            for f in self.loop_removed_callbacks:
                f(loop_num) # UI needs to pop first, otherwise it'll try to get data that isn't available
            self.loops.pop()
            for param in loop_parameters:
                self.send_osc('/sl/' + str(loop_num) + '/unregister_auto_update', param, self.server.url, '/sl/loop')
        # self.__dict__[args[1]] = args[2]

        # for f in self.looper_callbacks:
        #     f(args)

    def loop_responder(self, path, args):
        """ Listens for replies from SL about loops, then updates loop object accordingly."""

        try:
            loop = self.loops[args[0]]
        except IndexError:
            return
        control, value = args[1:]

        if self.verbose:
            if control != "loop_pos":
                print('loop responder Received OSC message: {} {}'.format(path, args))

        loop.__dict__[control] = value

        for f in self.loop_callbacks:
            f(args)

    def looper_responder(self, path, args):
        """ Listens for replies from SL about looper global state"""
        if self.verbose:
            print('looper responder Received OSC message: {} {} server {}'.format(path, args, self.server.url))

        self.__dict__[args[1]] = args[2]

        for f in self.looper_callbacks:
            f(args)

    def midi_binding_responder(self, path, args):
        """ Listens for replies from SL about midi bindings"""
        if self.verbose:
            print('midi binding responder Received OSC message: {} {} server {}'.format(path, args, self.server.url))
            #/sl/midi_bindings ['done', '0 n 57  note overdub 1  0 1  norm 0 127'] server osc.udp://loki-ldesktop:9950/
        if args[0] == "done":
            for f in self.midi_binding_callbacks:
                f(args)

        # self.__dict__[args[1]] = args[2]
        # for f in self.looper_callbacks:
        #     f(args)

    def send(self, path1, path2, *args):
        message = '/sl/' + str(path1)
        if path2:
            message += '/' + str(path2)
        self.send_osc(message, *args)

    def set(self, control, value):
        self.send_osc('/set', control, value)

    def register_updates(self):
        """ Ask SL to updates us on changes to global and loop states. While the documentation indicates that register_update should trigger whenever any client updates an input control, in practice the auto variety seems necessary to catch changes not initiated from SL's frontend. Auto is always necessary for loop states. We pass a polling interval of 100ms, but this is actually fixed on the backend. Updates only fire if the value has been changed. """

        for param in looper_parameters:
            self.send_osc('/register_auto_update', param, 100, self.server.url, '/sl/looper')

        self.send_osc('/sl/0/register_auto_update', 'quantize', 100, self.server.url, '/sl/looper')
        self.send_osc('/register', self.server.url, '/sl/loop_num')

        for loop in self.loops:
            for param in loop_parameters:
                self.send_osc('/sl/' + str(loop.number) + '/register_auto_update', param, 100, self.server.url, '/sl/loop')

    def unregister_updates(self):
        """ Ask SL to stop updating us"""

        for param in looper_parameters:
            self.send_osc('/unregister_auto_update', param, self.server.url, '/sl/looper')

        self.send_osc('/sl/0/unregister_auto_update', 'quantize', self.server.url, '/sl/looper')
        self.send_osc('/unregister', self.server.url, '/sl/loop_num')

        for loop in self.loops:
            for param in loop_parameters:
                self.send_osc('/sl/' + str(loop.number) + '/unregister_auto_update', param, self.server.url, '/sl/loop')

    def ping(self, timeout=1):
        self.ping_flag.clear()
        self.send_osc('/ping', self.server.url, '/sl/ping')
        return self.ping_flag.wait(timeout)

    def add_loop(self, num_channels):
        self.send_osc('/loop_add', num_channels, 43.0)

    def remove_loop(self):
        self.send_osc('/loop_del', -1)

    def select_loop(self, n):
        self.selected_loop_num = n

    def enable_midi_clock(self):
        self.set('output_midi_clock', 1.0)

    def disable_smart_eighths(self):
        self.set('smart_eighths', 0.0)

    @property
    def quantize(self):
        return ('off', 'cycle', '8th', 'loop')[int(self.__dict__['quantize'])]

    @quantize.setter
    def quantize(self, val):
        q = ('off', 'cycle', '8th', 'loop').index(val)
        self.send_osc('/sl/0/set', 'quantize', q)

    @property
    def selected_loop_num(self):
        n = self.__dict__['selected_loop_num']
        if n == -1:
            return 'all'
        else:
            return int(n)

    @selected_loop_num.setter
    def selected_loop_num(self, val):
        if val == 'all':
            n = -1
        else:
            n = val
        self.set('selected_loop_num', n)

    @property
    def selected_loop(self):
        n = self.selected_loop_num
        if isinstance(n, int):
            return self.loops[n]

    @property
    def sync_source(self):
        s = self.__dict__['sync_source']
        # if s > 0:
        return int(s)
        # else:
        #     return ('none', 'internal', 'midi', 'jack')[i]

    @sync_source.setter
    def sync_source(self, val):
        # if isinstance(val, str):
        #     s = - ('none', 'jack', 'midi', 'internal').index(val)
        # else:
        s = val
        self.set('sync_source', s)

    @property
    def output_midi_clock(self):
        s = self.__dict__['output_midi_clock']
        return int(s)

    @output_midi_clock.setter
    def output_midi_clock(self, val):
        # if isinstance(val, str):
        #     s = - ('none', 'jack', 'midi', 'internal').index(val)
        # else:
        s = val
        self.set('output_midi_clock', s)

    @property
    def smart_eighths(self):
        s = self.__dict__['smart_eighths']
        return int(s)

    @output_midi_clock.setter
    def smart_eighths(self, val):
        # if isinstance(val, str):
        #     s = - ('none', 'jack', 'midi', 'internal').index(val)
        # else:
        s = val
        self.set('smart_eighths', s)

    def cancel_midi_learn(self):
         # /cancel_midi_learn    s:returl  s:retpath
        self.send_osc('/cancel_midi_learn', self.server.url, '/sl/midi_bindings')

    def save_session(self, target_file):
        self.send_osc('/save_session', target_file, self.server.url, '/error')

    def save_midi_bindings(self, target_file):
        self.send_osc('/save_midi_bindings', target_file, "")

    def load_session(self, target_file):
        self.send_osc('/load_session', target_file, self.server.url, '/error')

    def load_midi_bindings(self, target_file):
        self.send_osc('/load_midi_bindings', target_file, "")

    def midi_learn(self, control, loop_num):

        info = namedtuple('MidiBinding', ['channel', 'type', "param", "command", "control", "instance", "lbound", "ubound", "style"])
        donothing = False
        val = control

        info.channel = 0
        info.type = "cc"
        info.command = "set"
        info.instance = loop_num
        info.lbound = 0.0
        info.ubound = 1.0
        info.style = "norm"

        if (val == "tempo"):
            info.lbound = 20.0
            info.ubound = 274.0
            info.control = "tempo"

        elif (val == "taptempo"):
            info.instance = -2
            info.control = "tap_tempo"

        elif (val == "select_next_loop"):
            info.type = "on"
            info.instance = -2
            info.control = "select_next_loop"

        elif (val == "select_prev_loop"):
            info.type = "on"
            info.instance = -2
            info.control = "select_prev_loop"

        elif (val == "eighth"):
            info.control = "eighth_per_cycle"
            info.lbound = 1.0
            info.ubound = 128.0

        elif (val == "fade_samples"):
            info.control = "fade_samples"
            info.lbound = 0.0
            info.ubound = 16384.0

        elif (val == "dry"):
            info.control = "dry"
            info.style = "gain"

        elif (val == "wet"):
            info.control = "wet"
            info.style = "gain"

        elif (val == "input_gain"):
            info.control = "input_gain"
            info.style = "gain"

        elif (val == "round"):
            info.instance = -1
            info.control = "round"

        elif (val == "sync"):
            info.control = "sync_source"
            info.lbound = -3.0
            info.ubound = 16.0

        elif (val == "output_midi_clock"):
            info.control = "output_midi_clock"
            info.lbound = 0.0
            info.ubound = 1.0

        elif (val == "quantize"):
            info.instance = -1
            info.control = "quantize"
            info.lbound = 0.0
            info.ubound = 3.0

        elif (val == "mute_quantized"):
            info.control = "mute_quantized"
            info.instance = -1

        elif (val == "overdub_quantized"):
            info.control = "overdub_quantized"
            info.instance = -1

        elif (val == "replace_quantized"):
            info.control = "replace_quantized"
            info.instance = -1

        elif (val == "smart_eighths"):
            info.control = "smart_eighths"
            info.instance = -1

        elif (val == "rate_1"):
            info.type = "on"
            info.control = "rate"
            info.command = "set"
            info.lbound = 1.0
            info.ubound = 1.0

        elif (val == "rate_05"):
            info.type = "on"
            info.control = "rate"
            info.command = "set"
            info.lbound = 0.5
            info.ubound = 0.5

        elif (val == "rate_2"):
            info.type = "on"
            info.control = "rate"
            info.command = "set"
            info.lbound = 2.0
            info.ubound = 2.0
        elif (val == "rate"):
            info.control = val
            info.lbound = 0.25
            info.ubound = 4.0
        elif (val in ('rec_thresh', 'feedback', 'scratch_pos', 'pan_1', 'pan_2')):
            info.control = val
        else:
            info.type = "on"
            info.control = val
            info.command = "note"
            #donothing = true

        if info.command == "set":
            info.param = 0
        else:
            info.param = 2013629443


        if not donothing:

        # info = namedtuple('MidiBinding', ['channel', 'type', "command", "instance", "lbound", "ubound", "style"])
   #      // i:ch s:type i:param  s:cmd  s:ctrl i:instance f:min_val_bound f:max_val_bound s:valstyle i:min_data i:max_data
            info_str = "{} {} {} {} {} {} {} {} {} 0 127".format(info.channel, info.type, info.param, info.command, info.control, info.instance, info.lbound, info.ubound, info.style)
            # print("sending osc learning midi binding", info_str)

            self.send_osc('/learn_midi_binding', info_str, 'exclusive', self.server.url, '/sl/midi_bindings')



class Loop:
    def __init__(self, looper, number, state='Off'):
        self.looper = looper
        self.number = number
        #self.state = state

    def __repr__(self):
        #return 'Loop(looper={}, number={}, state={})'.format(
        #        self.looper.sl_port, self.number, self.state)
        return 'Loop({}, {})'.format(self.number, self.state)

    def __str__(self):
        return 'Loop({}, {})'.format(self.number, self.state)

    def __getattr__(self, name):
        if name in loop_commands:
            return lambda: self.hit(name)
        # elif name in loop_parameters:

    def __setattr__(self, name, val):
        if name in loop_parameters_settable:
            self.send('set', name, val)
        else:
            self.__dict__[name] = val

    def set(self, control, value):
        print("sending set value", control, value)
        self.looper.send('set', control, value)

    def loop_set(self, name, val):
        self.send('set', name, val)

    def get(self, control):
        self.send('get', control, self.looper.server.url, '/sl/loop')

    def send(self, action, *args):
        self.looper.send(self.number, action, *args)

    def hit(self, command):
        self.send('hit', command)

    @property
    def state(self):
        return state_codes[int(self.__dict__['state'])]

    @property
    def next_state(self):
        return state_codes[int(self.__dict__['next_state'])]


# class Looper:
#     """
#     The original, unthreaded looper class. It's missing features that have been added to the threaded version and will likely be merged to a single class with both options at some point.

#     """

#     def __init__(self, port=9950, sl_port=9951, verbose=False):
#         self.port = port
#         self.sl_port = sl_port
#         self.verbose = verbose

#     def __repr__(self):
#         return 'Looper(port={}, sl_port={}, verbose={})'.format(self.port, self.sl_port, self.verbose)

#     def start_server(self):
#             self.server = liblo.Server(self.port) #Define liblo server for replies

#             self.server.add_method('/sl/ping', None, self.ping_responder)
#             self.server.add_method('/sl/loop', None, self.loop_responder)

#             self.init_loops()

#     def init_loops(self):
#         self.loop_count = 0
#         self.loops = []
#         if self.ping() and self.loop_count:
#             for i in range(self.loop_count):
#                 self.loops.append(Loop(self, i))
#                 self.loops[i].get('state')
#                 self.receive()
#         else:
#             print("Couldn't initialize loops. Either ping to SooperLooper failed, or loop count is zero.")

#     def send_osc(self, path, *args):
#         if self.verbose:
#             print('Sending OSC message: {} {}'.format(path, args))
#         liblo.send(self.sl_port, liblo.Message(path, *args))

#     def ping_responder(self, path, args):
#         self.loop_count = args[2]
#         if self.verbose:
#             print('Received OSC message: {} {}'.format(path, args))

#     def loop_responder(self, path, args):
#         """ Listens for replies from SL about loops (probably set all loop replies to come to one path, like '/sl/loop'), then update loop object accordingly."""

#         loop = self.loops[args[0]]
#         control, value = args[1:]

#         if control == 'state':
#             loop.state = state_codes[value]

#         else:
#             pass

#         if self.verbose:
#             print('Received OSC message: {} {}'.format(path, args))

#     def send(self, path1, path2, *args):
#         message = '/sl/' + str(path1)
#         if path2:
#             message += '/' + str(path2)
#         self.send_osc(message, *args)

#     def receive(self, timeout=1):
#         #Timeout of 0 is too small to reliably receive replies, and there's no way to recover from blocking in the main thread, at least in this case
#         return self.server.recv(timeout)

#     def register_updates(self):
#         # Int is update interval, currently ignored and set to 100ms
#         # We have to auto update to get state info but it only sends with change
#         # Don't forget to receive messages
#         for n in len(self.loops):
#             self.send_osc('/sl/' + str(loop.number) + '/register_auto_update', 'state', 100, self.server.url, '/sl/loop')

#     def ping(self, timeout=1):
#         self.send_osc('/ping', self.server.url, '/sl/ping')
#         return self.receive(timeout)
