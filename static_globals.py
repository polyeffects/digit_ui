from enum import Enum, IntEnum
IS_REMOTE_TEST = False

pedal_types = Enum("pedals", """verbs
ample
trails
""")

PEDAL_TYPE = pedal_types.trails # pedal_types.verbs

trails_enable_map = {
        0 : {"granular1", "multi_resonator1", "reverse1", "vca1", "vca2", "vca3"},
        1 : {"granular1", "multi_resonator1", "reverse1", "vca1", "vca2", "vca3"},
        2 : {"vinyl1", "twist_delay1", "turntable_stop1", "turntable_stop2", "vca1", "vca2", "vca3"},
        3 : {"granular1", "multi_resonator1", "looping_envelope1", "vca1", "vca2", "vca3"},
        4 : {"time_stretch1", "delay1", "delay2", "vca1", "chorus_j1", "vca2", "vca3"},
        5 : {"wavefolder1", "delay3", "delay4", "chorus_j1", "vca1", "vca2", "vca3"},
        6 : {"granular1", "reverse1", "vca1", "vca2", "vca3"},
        }

trails_control_map = {
    0 : [["wet_dry_stereo1" ,"xfade"],
        ["multi_resonator1", "frequency_param"],
        ["multi_resonator1", "structure_param"],
        ["granular1", "density_param"],
        ["granular1", "freeze_param"]
        ],
    1 : [["wet_dry_stereo1" ,"xfade"],
        ["multi_resonator1", "frequency_param"],
        ["multi_resonator1", "structure_param"],
        ["granular1", "density_param"],
        ["granular1", "freeze_param"]
        ],
    2 : [["wet_dry_stereo1" ,"xfade"],
        ["twist_delay1", "speed_direction"],
        ["vinyl1", "aging"],
        ["vinyl1", "gain0"],
        ["turntable_stop1", "PULL_THE_PLUG"]
        ],
    3 : [["wet_dry_stereo1" ,"xfade"],
        ["looping_envelope1", "frequency_param"],
        ["looping_envelope1", "shape_param"],
        ["multi_resonator1", "position_param"],
        ["multi_resonator1", "damping_param"]
         ],
    4 : [["wet_dry_stereo1" ,"xfade"],
        ["delay1", "Delay_1"],
        ["time_stretch1", "feedback_param"],
        ["time_stretch1", "pitch_param"],
        ["time_stretch1", "freeze_param"]
         ],
    5 : [["wet_dry_stereo1" ,"xfade"],
        ["delay3", "Amp_5"],
        ["wavefolder1", "n_folds"],
        ["wavefolder1", "input_bias"],
        ["delay3", "Feedback_4"],
         ],
    6 : [["wet_dry_stereo1" ,"xfade"],
        ["granular1", "size_param"],
        ["granular1", "texture_param"],
        ["granular1", "density_param"],
        ["granular1", "freeze_param"]
        ],
    }

trails_range_map = {
    0 : [
        [-1.0 , 1.0],
        [0.0 , 60.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        ],
    1 : [
        [-1.0 , 1.0],
        [0.0 , 60.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        ],
    2 : [
        [-1.0 , 1.0],
        [0.0 , 8.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        ],
    3 : [
        [-1.0 , 1.0],
        [-48.0 , 48.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        [0.31 , 0.7],
        ],
    4 : [
        [-1.0 , 1.0],
        [0.001 , 1.0],
        [0.0 , 0.4],
        [-48.0 , 48.0],
        [0.0 , 1.0],
        ],
    5 : [
        [-1.0 , 1.0],
        [0.0 , 1.0],
        [0.0 , 8.0],
        [0.0 , 1.0],
        [0.45 , 0.90],
        ],
    6 : [
        [-1.0 , 1.0],
        [0.0 , 1.0],
        [0.07 , 1.0],
        [0.0 , 1.0],
        [0.0 , 1.0],
        ],
        }

# values that need to be set per mode but aren't user controlled
trails_mode_settings = {
    0 : [
        ["granular1", "freeze_param", 0.0],
        ["granular1", "reverse_param", 0.0],
        ["granular1", "size_param", 0.71],
        ["granular1", "pitch_param", -0.01],
        ["granular1", "texture_param", 0.89],
        ["granular1", "spread_param", 0.98],
        ["granular1", "position_param", 0.58],
        ["granular1", "blend_param", 0.5],
        ["multi_resonator1", "polyphony_param", 0.0],
        ["multi_resonator1", "position_param", 0.75],
        ["multi_resonator1", "brightness_param", 0.94],
        ["multi_resonator1", "damping_param", 0.76],
        ["multi_resonator1", "resonator_param", 1.0],
        ["multi_resonator1", "position_mod_param", 0.0],
        ["multi_resonator1", "internal_exciter_param", 0.0],
        ["reverse1", "fragment", 475.798],
        ["reverse1", "wet", -31.0],
        ["vca1", "gain", 0.0],
        ["vca2", "gain", 0.0],
        ["vca3", "gain", 0.0],
        ],
    1 : [
        ["granular1", "freeze_param", 0.0],
        ["granular1", "reverse_param", 0.0],
        ["granular1", "size_param", 0.71],
        ["granular1", "pitch_param", -0.01],
        ["granular1", "texture_param", 0.8],
        ["granular1", "spread_param", 0.98],
        ["granular1", "position_param", 0.58],
        ["granular1", "blend_param", 0.5],
        ["multi_resonator1", "polyphony_param", 1.0],
        ["multi_resonator1", "resonator_param", 4.0],
        ["multi_resonator1", "position_param", 0.84],
        ["multi_resonator1", "brightness_param", 0.81],
        ["multi_resonator1", "damping_param", 0.56],
        ["multi_resonator1", "position_mod_param", 0.0],
        ["multi_resonator1", "internal_exciter_param", 0.0],
        ["reverse1", "fragment", 475.798],
        ["reverse1", "wet", -31.0],
        ["vca1", "gain", 0.0],
        ["vca2", "gain", 0.0],
        ["vca3", "gain", 0.0],
        ],
    2 : [
        ["turntable_stop1", "PULL_THE_PLUG", 0.0],
        ["turntable_stop2", "PULL_THE_PLUG", 0.0],
        ["vca1", "gain", 0.0],
        ["vca2", "gain", 0.0],
        ["vca3", "gain", 0.0],
        ],
    3 : [
        ["multi_resonator1", "polyphony_param", 1.0],
        ["multi_resonator1", "position_param", 0.67],
        ["multi_resonator1", "brightness_param", 0.84],
        ["multi_resonator1", "damping_param", 0.31],
        ["multi_resonator1", "resonator_param", 6.0],
        ["multi_resonator1", "position_mod_param", 0.49],
        ["multi_resonator1", "internal_exciter_param", 0.0],
        ["granular1", "blend_param", 0.0],
        ["vca1", "gain", 0.0],
        ["vca2", "gain", 0.0],
        ["vca3", "gain", 0.0],
        ],
    4 : [
        ["delay1", "Amp_5", 0.5],
        ["delay2", "Amp_5", 1.0],
        ["time_stretch1", "freeze_param", 0],
        ["vca1", "gain", 0.0],
        ["vca2", "gain", 0.0],
        ["vca3", "gain", 0.0],
        ],
    5 : [
        ["delay3", "Amp_5", 0.2],
        ["delay4", "Amp_5", 0.2],
        ["delay3", "Feedback_4", 0.45],
        ["delay4", "Feedback_4", 0.55],
        ["vca1", "gain", 0.55],
        ["vca2", "gain", 0.0],
        ["vca3", "gain", 0.0],
        ],
    6 : [
        ["granular1", "freeze_param", 0],
        ["granular1", "reverse_param", 0.0],
        ["granular1", "position_param", 0.0],
        # ["granular1", "texture_param", 0.7],
        ["granular1", "pitch_param", 0.0],
        ["granular1", "spread_param", 0.8],
        ["granular1", "blend_param", 1.0],
        ["reverse1", "fragment", 875.798],
        ["reverse1", "wet", -10.0],
        ["vca1", "gain", 0.0],
        ["vca2", "gain", 1.0],
        ["vca3", "gain", 1.0],
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

TRAILS_SUSTAIN = 4
