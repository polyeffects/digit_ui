
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal, QTimer, QThreadPool, QRunnable, QMetaObject, Qt
from dooper import LooperThread, loop_parameters, looper_parameters
from properties import PropertyMeta, Property

l_thread = LooperThread()
l_thread.start_server()

unused = ('redo_is_tap', 'use_rate', 'use_common_ins', 'use_common_outs', 'use_safety_feedback', 'pan_1', 'pan_2', 'pan_3', 'pan_4', 'input_latency', 'output_latency', 'trigger_latency', 'autoset_latency')

unused_looper = ( 'tap_tempo', # any changes
        'save_loop', # any change triggers quick save, be careful
    'auto_disable_latency',  # when 1, disables compensation when monitoring main inputs
    'select_next_loop',  # any changes
    'select_prev_loop',  # any changes
    'select_all_loops',   # any changes
    )
# loop_parameters_gettable = (
#     'state',   # codes mapped below
#     'next_state',  # same as state
#     'loop_len',  # in seconds
# #    'loop_pos',  # in seconds
#     'cycle_len', # in seconds
#     'free_time', # in seconds
#     'total_time', # in seconds
#     'rate_output',
#     'in_peak_meter',  # absolute float sample value 0.0 -> 1.0 (or higher)
#     'out_peak_meter',  # absolute float sample value 0.0 -> 1.0 (or higher)
#     'is_soloed',       # 1 if soloed, 0 if not
#     )

class Loop(QObject, metaclass=PropertyMeta):
    state = Property(int)   # codes mapped below
    next_state = Property(int)  # same as state
    loop_len = Property(float)  # in seconds
    loop_pos = Property(float)  # in seconds
    cycle_len = Property(float) # in seconds
    free_time = Property(float) # in seconds
    total_time = Property(float) # in seconds
    rate_output = Property(float)
    in_peak_meter = Property(float)  # absolute float sample value 0.0 -> 1.0 (or higher)
    out_peak_meter = Property(float)  # absolute float sample value 0.0 -> 1.0 (or higher)
    is_soloed = Property(float)       # 1 if soloed, 0 if not
    rec_thresh = Property(float)  	# expected range is 0 -> 1
    feedback = Property(float)    	# range 0 -> 1
    dry = Property(float)         	# range 0 -> 1
    wet = Property(float)         	# range 0 -> 1
    input_gain = Property(float)    # range 0 -> 1
    rate = Property(float)        	# range 0.25 -> 4.0
    scratch_pos = Property(float)  	 # 0 -> 1
    delay_trigger = Property(float)  # any changes
    round = Property(float)          # 0 = off,  not 0 = on
    sync = Property(float)           # 0 = off,  not 0 = on
    playback_sync = Property(float)  # 0 = off,  not 0 = on
    use_feedback_play = Property(float)   # 0 = off,  not 0 = on
    # redo_is_tap = Property(float)    # 0 = off,  not 0 = on
    # use_rate = Property(float)       # 0 = off,  not 0 = on
    # use_common_ins = Property(float)   # 0 = off,  not 0 = on
    # use_common_outs = Property(float)   # 0 = off,  not 0 = on
    # use_safety_feedback = Property(float)   # 0 = off, not 0 = on
    # pan_1 = Property(float)        	# range 0 -> 1
    # pan_2 = Property(float)        	# range 0 -> 1
    # pan_3 = Property(float)        	# range 0 -> 1
    # pan_4 = Property(float)        	# range 0 -> 1
    # # input_latency = Property(float) # range 0 -> ...
    # output_latency = Property(float) # range 0 -> ...
    # trigger_latency = Property(float) # range 0 -> ...
    # autoset_latency = Property(float)  # 0 = off, not 0 = on
    mute_quantized = Property(float)
    overdub_quantized = Property(float)
    pitch_shift = Property(float)
    stretch_ratio = Property(float)
    waiting = Property(float)
    fade_samples = Property(float)   # per loop 0 -> ...
    relative_sync = Property(float)   # per loop 0 -> ...
    quantize = Property(int)   # per loop 0 -> ...
#   'quantize', # 0 = off, 1 = cycle, 2 = 8th, 3 = loop

    def __init__(self, loop_num, parent=None):
        super().__init__(parent)
        a = list(l_thread.loops[loop_num].__dict__.items())
        for k, v in a:
            if k in loop_parameters and k not in unused:
                # print("adding loop num", loop_num, k, v)
                # self.__dict__[k] = v
                type(self).__dict__[k].setter(self, v)
                # if k == "feedback":
                #     self.feedback = v
                #     print("adding loop num", loop_num, k, v)
        # self.name = name

class Loopler(QObject, metaclass=PropertyMeta):
    # @Slot(bool, str, str)
    # @Slot(str, str, 'double')
    loops = Property(list)
    loopAddedSignal = Signal(int)
    loopRemovedSignal = Signal(int)
    selected_loop_num = Property(int)
    input_gain = Property(float)    # range 0 -> 1
    wet = Property(float)    # range 0 -> 1
    dry = Property(float)    # range 0 -> 1
    tempo = Property(float)
    eighth_per_cycle = Property(int)
    sync_source = Property(int)
    relative_sync = Property(float)   # per loop 0 -> ...
    midi_learn_waiting = Property(bool)   # per loop 0 -> ...
    # mute_quantized = Property(int) # per loop
    # overdub_quantized = Property(int) # per loopo
    current_command_params = None

    def __init__(self):
        super().__init__()
        self.loops = [Loop(i) for i,l in enumerate(l_thread.loops)]
        l_thread.loop_callbacks.append(self.loop_responder)
        l_thread.looper_callbacks.append(self.looper_responder)
        l_thread.loop_added_callbacks.append(self.loop_added_responder)
        l_thread.loop_removed_callbacks.append(self.loop_removed_responder)
        l_thread.midi_binding_callbacks.append(self.midi_binding_responder)
        self.loopAddedSignal.connect(self.add_loop)
        self.loopRemovedSignal.connect(self.remove_loop)
        self.selected_loop_num = l_thread.selected_loop_num
        self.midi_learn_waiting = False

        a = list(l_thread.__dict__.items())
        for k, v in a:
            if k in looper_parameters and k not in unused_looper:
                type(self).__dict__[k].setter(self, v)

    @Slot(int, str)
    def ui_loop_command(self, loop_id, command):
        l_thread.loops[loop_id].hit(command)

    def loop_command(self, loop_id, command):
        print("loop id is", loop_id, "command is", command)
        loop_id = int(loop_id)
        l_thread.loops[loop_id].hit(command)

    @Slot(int, str, "double")
    def ui_set(self, loop_id, parameter, value):
        l_thread.loops[loop_id].loop_set(parameter, value)

    @Slot(str, "double")
    def ui_set_all(self, parameter, value):
        for loop in l_thread.loops:
            loop.loop_set(parameter, value)

    @Slot(str, "double")
    def ui_set_global(self, parameter, value):
        l_thread.set(parameter, value)

    @Slot(int)
    def select_loop(self, loop_id):
        l_thread.select_loop(loop_id)

    @Slot()
    def ui_add_loop(self):
        l_thread.add_loop()

    @Slot()
    def ui_remove_loop(self):
        l_thread.remove_loop()

    @Slot(str, "QVariantList")
    def ui_set_current_command(self, command, args):
        self.current_command_params = (command, args)
        # XXX
        print("current_command", repr(self.current_command_params))

    @Slot()
    def ui_unset_current_command(self):
        print("unset current_command")
        self.current_command_params = None

    def loop_responder(self, args):
        """ Listens for replies from SL about loops, then updates loop object accordingly."""
        try:
            loop = self.loops[args[0]]
        except IndexError:
            return
        control, value = args[1:]
        if control in type(loop).__dict__:
            type(loop).__dict__[control].setter(loop, value)

    def looper_responder(self, args):
        """ Listens for replies from SL about looper global state"""
        control, value = args[1:]
        # print("looper responder",  control, value)
        if control in type(self).__dict__:
            type(self).__dict__[control].setter(self, value)

    def loop_added_responder(self, loop_num):
        # QMetaObject.invokeMethod(self, b"add_loop", Qt.QueuedConnection, loop_num)
        self.loopAddedSignal.emit(loop_num)

    def midi_binding_responder(self, args):
        # QMetaObject.invokeMethod(self, b"add_loop", Qt.QueuedConnection, loop_num)
        self.midi_learn_waiting = False

    def add_loop(self, loop_num):
        self.loops.append(Loop(loop_num))

    def loop_removed_responder(self, loop_num):
        self.loopRemovedSignal.emit(loop_num)

    def remove_loop(self, loop_num):
        self.loops.pop()

## learn

    @Slot(str, int)
    def ui_bind_request(self, control, loop_num):
        self.midi_learn_waiting = True
        l_thread.midi_learn(control, loop_num)

    @Slot()
    def ui_cancel_bind_request(self):
        self.midi_learn_waiting = False
        l_thread.cancel_midi_learn()

   # if (style == GainStyle) {
   #              snprintf(stylebuf, sizeof(stylebuf), "gain");
   #      } else if (style == ToggleStyle) {
   #              snprintf(stylebuf, sizeof(stylebuf), "toggle");
   #      } else if (style == IntegerStyle) {
   #              snprintf(stylebuf, sizeof(stylebuf), "integer");
   #      } else {
   #              strncpy(stylebuf, "norm", sizeof(stylebuf));
   #      }

   #      // i:ch s:type i:param  s:cmd  s:ctrl i:instance f:min_val_bound f:max_val_bound s:valstyle i:min_data i:max_data
   #      snprintf(buf, sizeof(buf), "%d %s %d  %s %s %d  %.9g %.9g  %s %d %d",
   #               channel, type.c_str(), param, command.c_str(),
   #               control.c_str(), instance, lbound, ubound, stylebuf, data_min, data_max);
