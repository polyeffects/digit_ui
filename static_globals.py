from enum import Enum, IntEnum
IS_REMOTE_TEST = False

pedal_types = Enum("pedals", """verbs
ample
trails
""")

PEDAL_TYPE = pedal_types.trails # pedal_types.verbs

trails_enable_map = {0 : {"granular1", "reverse1"},
        1 : {"multi_resonator1", "reverse1"},
        2 : {"vinyl1", "twist_delay1", "turntable_stop1", "turntable_stop2"},
        3 : {"multi_resonator1", "looping_envelope1"},
        4 : {"time_stretch1", "delay1", "delay2"},
        5 : {"wavefolder1", "delay1", "delay2", "delay3", "delay4", "chorus_j1"},
        6 : {"delay1", "delay2", "delay3", "delay4", "chorus_j1", "reverse1", "twist_delay1"},
        }

trails_control_map = {
    0 : [["wet_dry_stereo1" ,"xfade"],
        ["granular1", "density_param"],
        ["granular1", "size_param"],
        ["granular1", "pitch_param"]],
    1 : [["wet_dry_stereo1" ,"xfade"],
        ["multi_resonator1", "frequency_param"],
        ["multi_resonator1", "structure_param"],
        ["multi_resonator1", "damping_param"]],
    2 : [["wet_dry_stereo1" ,"xfade"],
        ["twist_delay1", "speed_direction"],
        ["vinyl1", "aging"],
        ["vinyl1", "gain0"]],
    3 : [["wet_dry_stereo1" ,"xfade"],
        ["looping_envelope1", "frequency_param"],
        ["multi_resonator1", "frequency_param"],
        ["multi_resonator1", "structure_param"]],
    4 : [["wet_dry_stereo1" ,"xfade"],
        ["delay1", "Delay_1"],
        ["time_stretch1", "density_param"],
        ["time_stretch1", "pitch_param"]],
    5 : [["wet_dry_stereo1" ,"xfade"],
        ["delay1", "Delay_1"],
        ["wavefolder1", "n_folds"],
        ["delay1", "Amp_5"]],
    6 : [["wet_dry_stereo1" ,"xfade"],
        ["delay1", "Delay_1"],
        ["reverse1", "fragment"],
        ["delay1", "Amp_5"]],
        }

trails_range_map = {
    0 : [
        [-1.0 , 1.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        [-12.0 , 12.0]
        ],
    1 : [
        [-1.0 , 1.0],
        [0.0 , 60.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        ],
    2 : [
        [-1.0 , 1.0],
        [0.0 , 8.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        ],
    3 : [
        [-1.0 , 1.0],
        [-48.0 , 48.0],
        [0.0 , 60.0],
        [0.0 , 1.0],
        ],
    4 : [
        [-1.0 , 1.0],
        [0.001 , 1.0],
        [0.0 , 1.0],
        [-48.0 , 48.0],
        ],
    5 : [
        [-1.0 , 1.0],
        [0.001 , 1.0],
        [0.0 , 8.0],
        [0.0 , 1.0],
        ],
    6 : [
        [-1.0 , 1.0],
        [0.001 , 1.0],
        [0.0 , 1.0],
        [100.0 , 1600.0],
        ],
        }

# values that need to be set per mode but aren't user controlled
trails_mode_settings = {
    0 : [
        ],
    1 : [
        ["multi_resonator1", "polyphony_param", 1.0],
        ["multi_resonator1", "position_param", 0.798],
        ["multi_resonator1", "resonator_param", 4.0],
        ["multi_resonator1", "brightness_param", 0.61],
        ["multi_resonator1", "position_mod_param", 0.0],
        ],
    2 : [],
    3 : [
        ["multi_resonator1", "polyphony_param", 1.0],
        ["multi_resonator1", "position_param", 0.67],
        ["multi_resonator1", "brightness_param", 0.84],
        ["multi_resonator1", "damping_param", 0.31],
        ["multi_resonator1", "resonator_param", 6.0],
        ["multi_resonator1", "position_mod_param", 0.49],
        ],
    4 : [
        ["delay1", "Amp_5", 0.5],
        ["delay2", "Amp_5", 1.0],
        ],
    5 : [
        ["delay1", "Amp_5", 0.2],
        ["delay2", "Amp_5", 0.2],
        ],
    6 : [
        ],
        }

verbs_keys = {
    ("delay1", "Delay_1") : 0,
    ("wet_dry_stereo1", "level") : 1,
    ("filter_uberheim1", "cutoff") : 2,
    ("vca1", "gain") : 3,
    ("sum1", "a") : 4,
            }
verbs_keys_invert = {v: k for k, v in verbs_keys.items()}
