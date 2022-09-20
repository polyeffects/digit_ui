.pragma library
var parameter_map = {'input_gain': 'in gain', 'feedback': 'feedback', 'rec_thresh': 'threshold',
    'wet': 'out', 'playback_sync': 'play sync', 'use_feedback_play': 'play feedback', 'sync': 'sync', 'round' : 'round',
    "pitch_shift": "pitch", "stretch_ratio": "stretch", "scratch_pos": "scratch", "rate":"rate",
    "mute_quantized":"mute quantized", "overdub_quantized":"overdub quantized", "relative_sync":"relative sync",
    "fade_samples": "cross fade", "input_gain":"input gain", "wet": "wet", "dry":"dry", "pan_1":"pan L", "pan_2": "pan R", "select_prev_loop": "prev loop", "select_next_loop": "next loop"
};
var rate_list = [0.5, 1, 2];
var rate_bind_list = ["rate_05", "rate_1", "rate_2"];
var param_bounds = {"rate": [0.25, 4.0], "stretch_ratio": [0.5, 4.0], "pitch_shift": [-12.0, 12.0], "fade_samples": [0, 2048]}

var sync_to_map = [-3, -2, 0, 1];
var sync_to_index = {"-3":0, "-2":1, "0": 2, "1": 3};
//  sync_source  :: -3 = internal,  -2 = midi, -1 = jack, 0 = none, # > 0 = loop number (1 indexed) 

var state_map = {//-1: 'unknown',
               0: 'Off',
               1: 'Waiting to Start', // Waiting to start recording
               2: 'Recording',
               3: 'Waiting to Stop', // Waiting to stop recording
               4: 'Playing', // Or maybe waiting to mute
               5: 'Overdubbing',
               6: 'Multiplying',
               7: 'Inserting',
               8: 'Replacing',
               9: 'Delay',
               10: 'Muted', // Or maybe waiting to play
               11: 'Scratching',
               12: 'OneShot',
               13: 'Substitute',
               14: 'Paused',
               20: 'Off and muted'};//20 isn't documented...  

var command_map = {'undo': -2, 'overdub': 5, 'replace': 8, 'record': 2, 'solo': -2, 'oneshot': 12, 'reverse': -2, 'redo': -2, 'mute': 10, 'multiply': 6, 'insert': 7, 'substitute': 13, 'pause': 14, 'delay': 9, 'trigger': 4}

var next_command_map = {'undo': -2, 'overdub': 5, 'replace': 8, 'solo': -2, 'oneshot': 12, 'reverse': -2, 'redo': -2, 'mute': 10, 'multiply': 6, 'insert': 7, 'substitute': 13, 'delay': 9, 'trigger': 4, 'pause': 14}

var state_png_map = {'-1': 'play', '0': 'pause', '1': 'record', '2': 'record', '3': 'record', '4': 'play', '5': 'overdub', '6': 'multiply', '7': 'insert', '8': 'replace', '9': 'delay', '10': 'mute', '11': 'scratch', '12': 'oneshot', '13': 'substitute', '14': 'pause', '20': 'mute'}
