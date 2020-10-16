import sys, time, json, os.path, os, subprocess, queue, threading, traceback, glob
import platform, shutil
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit
from collections import OrderedDict
from enum import Enum, IntEnum
import urllib.parse
# import random
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal, QTimer, QThreadPool, QRunnable, qWarning, qCritical, qDebug
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtGui import QIcon
# # compiled QML files, compile with pyside2-rcc
# import qml.qml

sys._excepthook = sys.excepthook
def exception_hook(exctype, value, tb):
    debug_print("except hook 1 got a thing!") #, exctype, value, traceback)
    traceback.print_exception(exctype, value, tb)
    sys._excepthook(exctype, value, tb)
    sys.exit(1)
sys.excepthook = exception_hook

os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
import icons.icons
# #, imagine_assets
import resource_rc

import ingen_wrapper
import pedal_hardware

worker_pool = QThreadPool()
EXIT_PROCESS = [False]
ui_messages = queue.Queue()

current_source_port = None
current_sub_graph = "/main/sub1/"
sub_graphs = set(["/main/sub1"])
# current_effects = OrderedDict()
current_effects = {}
# current_effects["delay1"] = {"x": 20, "y": 30, "effect_type": "delay", "controls": {}, "highlight": False}
# current_effects["delay2"] = {"x": 250, "y": 290, "effect_type": "delay", "controls": {}, "highlight": False}
port_connections = {} # key is port, value is list of ports
current_patchbay_mode = 0
current_selected_effect = ""
footswitch_assignments = {}
preset_started_loading_time = 0

def reset_footswitch_assignments():
    global footswitch_assignments
    footswitch_assignments = {"a":set(), "b":set(), "c":set(), "d":set(), "e":set()}

reset_footswitch_assignments()

class PatchMode(IntEnum):
    SELECT = 0
    MOVE = 1
    CONNECT = 2
    SLIDERS = 3
    DETAILS = 4
    HOLD = 5

context = None

def debug_print(*args, **kwargs):
    pass
    # print( "From py: "+" ".join(map(str,args)), **kwargs)


effect_type_maps = {"digit":  { "delay": "http://polyeffects.com/lv2/digit_delay",
        "mono_reverb": "http://polyeffects.com/lv2/polyconvo#Mono",
        "stereo_reverb": "http://polyeffects.com/lv2/polyconvo#MonoToStereo",
        "quad_ir_reverb": "http://polyeffects.com/lv2/polyconvo#Stereo",
        "mono_cab": "http://polyeffects.com/lv2/polyconvo#CabMono",
        "stereo_cab": "http://polyeffects.com/lv2/polyconvo#CabMonoToStereo",
        "quad_ir_cab": "http://polyeffects.com/lv2/polyconvo#CabStereo",
        "warmth": "http://moddevices.com/plugins/tap/tubewarmth",
        "reverse": "http://moddevices.com/plugins/tap/reflector",
        "saturator": "http://moddevices.com/plugins/tap/sigmoid",
        "mono_EQ": "http://gareus.org/oss/lv2/fil4#mono",
        "stereo_EQ": "http://gareus.org/oss/lv2/fil4#stereo",
        "filter": "http://drobilla.net/plugins/fomp/mvclpf1",
        "lfo": "http://avwlv2.sourceforge.net/plugins/avw/lfo_tempo",
        "env_follower": "http://ssj71.github.io/infamousPlugins/plugs.html#envfollowerCV",
        "foot_switch_a": "http://polyeffects.com/lv2/polyfoot",
        "foot_switch_b": "http://polyeffects.com/lv2/polyfoot",
        "foot_switch_c": "http://polyeffects.com/lv2/polyfoot",
        "slew_limiter": "http://avwlv2.sourceforge.net/plugins/avw/slew",
        # "control_to_midi": "http://ssj71.github.io/infamousPlugins/plugs.html#mindi",
        "pan": "http://avwlv2.sourceforge.net/plugins/avw/vcpanning",
        "mix_vca": "http://avwlv2.sourceforge.net/plugins/avw/vcaexp_audio",
        "turntable_stop":"http://ssj71.github.io/infamousPlugins/plugs.html#powercut",
        "amp_bass":"http://guitarix.sourceforge.net/plugins/gx_ampegsvt_#_ampegsvt_",
        # "amp_bass_venue":"http://guitarix.sourceforge.net/plugins/gx_voxbass_#_voxbass_",
        "power_amp_cream":"http://guitarix.sourceforge.net/plugins/gx_CreamMachine_#_CreamMachine_",
        # "power_amp_plexi":"http://guitarix.sourceforge.net/plugins/gx_plexi_#_plexi_",
        "power_amp_super":"http://guitarix.sourceforge.net/plugins/gx_supersonic_#_supersonic_",
        "auto_swell": "http://guitarix.sourceforge.net/plugins/gx_slowgear_#_slowgear_",
        "freeze": "http://ssj71.github.io/infamousPlugins/plugs.html#stuck",
        "attenuverter":"http://drobilla.net/plugins/blop/product",
        # "tempo_ratio": "http://drobilla.net/plugins/blop/ratio",
        "granular" : "http://polyeffects.com/lv2/polyclouds#granular",
        "looping_delay" : "http://polyeffects.com/lv2/polyclouds#looping_delay",
        "time_stretch" : "http://polyeffects.com/lv2/polyclouds#stretch",
        "algo_reverb" : "http://polyeffects.com/lv2/polyclouds#oliverb",
        "bitmangle" : "http://polyeffects.com/lv2/polywarps#bitcrusher",
        "twist_delay" : "http://polyeffects.com/lv2/polywarps#delay",
        # "meta_modulation" : "http://polyeffects.com/lv2/polywarps#meta",
        "k_org_hpf": "http://polyeffects.com/lv2/polyfilter#korg_hpf",
        "k_org_lpf": "http://polyeffects.com/lv2/polyfilter#korg_lpf",
        "uberheim_filter": "http://polyeffects.com/lv2/polyfilter#oberheim",
        "midi_cc": "http://github.com/blablack/midimsg-lv2/controller",
        # "midi_note": "http://drobilla.net/ns/ingen-internals#Note",
        # "midi_trigger": "http://drobilla.net/ns/ingen-internals#Trigger",
        "cv_to_midi_cc": "http://polyeffects.com/lv2/cv_to_cc",
        'midi_clock_in': "http://polyeffects.com/lv2/mclk_in",
        "midi_clock_out": "http://gareus.org/oss/lv2/mclk",
        "vca": "http://polyeffects.com/lv2/basic_modular#amp",
        "difference": "http://polyeffects.com/lv2/basic_modular#difference",
        "rectify_value": "http://polyeffects.com/lv2/basic_modular#abs",
        "max" : "http://polyeffects.com/lv2/basic_modular#max",
        "min" : "http://polyeffects.com/lv2/basic_modular#min",
        "product" : "http://polyeffects.com/lv2/basic_modular#product",
        "ratio" : "http://polyeffects.com/lv2/basic_modular#ratio",
        "sum" : "http://polyeffects.com/lv2/basic_modular#sum",
        "midi_note_to_cv": "http://polyeffects.com/lv2/midi_to_cv_mono",
        "pitch_shift": "http://moddevices.com/plugins/tap/pitch",
        "onset_detect": "http://polyeffects.com/lv2/detect#onset",
        "adsr": "http://drobilla.net/plugins/blop/adsr",
        "sample_hold": "http://avwlv2.sourceforge.net/plugins/avw/samplehold",
        "dahdsr": "http://drobilla.net/plugins/blop/dahdsr",
        'wet_dry': 'http://polyeffects.com/lv2/wet_dry',
        'wet_dry_stereo': 'http://polyeffects.com/lv2/wet_dry_stereo',
        'ad_env_level': 'http://drobilla.net/plugins/omins/adenv_lvl',
        'ad_envelope': 'http://drobilla.net/plugins/omins/adenv',
        'tempo_ratio': 'http://polyeffects.com/lv2/basic_modular#tempo_ratio',
        'toggle': 'http://polyeffects.com/lv2/basic_modular#toggle',
        'harmonic_tremolo': 'http://polyeffects.com/lv2/harm_trem',
        'harmonic_trem_ext': 'http://polyeffects.com/lv2/harm_trem_ext',
        'step_sequencer_ext': 'http://polyeffects.com/lv2/step_sequencer',
        'step_sequencer': 'http://polyeffects.com/lv2/step_sequencer_bpm',
    },
    "beebo" : { "delay": "http://polyeffects.com/lv2/digit_delay",
        "warmth": "http://moddevices.com/plugins/tap/tubewarmth",
        "reverse": "http://moddevices.com/plugins/tap/reflector",
        "saturator": "http://moddevices.com/plugins/tap/sigmoid",
        "mono_EQ": "http://gareus.org/oss/lv2/fil4#mono",
        "stereo_EQ": "http://gareus.org/oss/lv2/fil4#stereo",
        "filter": "http://drobilla.net/plugins/fomp/mvclpf1",
        "lfo": "http://avwlv2.sourceforge.net/plugins/avw/lfo_tempo",
        "env_follower": "http://ssj71.github.io/infamousPlugins/plugs.html#envfollowerCV",
        "foot_switch_a": "http://polyeffects.com/lv2/polyfoot",
        "foot_switch_b": "http://polyeffects.com/lv2/polyfoot",
        "foot_switch_c": "http://polyeffects.com/lv2/polyfoot",
        "slew_limiter": "http://avwlv2.sourceforge.net/plugins/avw/slew",
        # "control_to_midi": "http://ssj71.github.io/infamousPlugins/plugs.html#mindi",
        "pan": "http://avwlv2.sourceforge.net/plugins/avw/vcpanning",
        "mix_vca": "http://avwlv2.sourceforge.net/plugins/avw/vcaexp_audio",
        "turntable_stop":"http://ssj71.github.io/infamousPlugins/plugs.html#powercut",
        "auto_swell": "http://guitarix.sourceforge.net/plugins/gx_slowgear_#_slowgear_",
        "freeze": "http://ssj71.github.io/infamousPlugins/plugs.html#stuck",
        "mono_compressor": "http://gareus.org/oss/lv2/darc#mono",
        "stereo_compress": "http://gareus.org/oss/lv2/darc#stereo",
        "thruzero_flange": "http://drobilla.net/plugins/mda/ThruZero",
        "rotary": "http://gareus.org/oss/lv2/b_whirl#simple",
        "rotary_advanced": "http://gareus.org/oss/lv2/b_whirl#extended",
        "attenuverter":"http://drobilla.net/plugins/blop/product",
        # "tempo_ratio": "http://drobilla.net/plugins/blop/ratio",
        "phaser": "http://jpcima.sdf1.org/lv2/stone-phaser",
        "stereo_phaser": "http://jpcima.sdf1.org/lv2/stone-phaser-stereo",
        "j_chorus": "https://chrisarndt.de/plugins/ykchorus",
        "granular" : "http://polyeffects.com/lv2/polyclouds#granular",
        "looping_delay" : "http://polyeffects.com/lv2/polyclouds#looping_delay",
        "algo_reverb" : "http://polyeffects.com/lv2/polyclouds#oliverb",
        "resonestor" : "http://polyeffects.com/lv2/polyclouds#resonestor",
        # "spectral_twist" : "http://polyeffects.com/lv2/polyclouds#spectral",
        "time_stretch" : "http://polyeffects.com/lv2/polyclouds#stretch",
        "bitmangle" : "http://polyeffects.com/lv2/polywarps#bitcrusher",
        # "chebyschev_waveshaper" : "http://polyeffects.com/lv2/polywarps#chebyschev",
        # "comparator" : "http://polyeffects.com/lv2/polywarps#comparator",
        "twist_delay" : "http://polyeffects.com/lv2/polywarps#delay",
        "doppler_panner" : "http://polyeffects.com/lv2/polywarps#doppler",
        "wavefolder" : "http://polyeffects.com/lv2/polywarps#fold",
        # "frequency_shifter" : "http://polyeffects.com/lv2/polywarps#frequency_shifter",
        "meta_modulation" : "http://polyeffects.com/lv2/polywarps#meta",
        # "vocoder" : "http://polyeffects.com/lv2/polywarps#vocoder",
        "diode_ladder_lpf": "http://polyeffects.com/lv2/polyfilter#diode_ladder",
        "k_org_hpf": "http://polyeffects.com/lv2/polyfilter#korg_hpf",
        "k_org_lpf": "http://polyeffects.com/lv2/polyfilter#korg_lpf",
        "oog_half_lpf": "http://polyeffects.com/lv2/polyfilter#moog_half_ladder",
        # "oog_ladder_lpf": "http://polyeffects.com/lv2/polyfilter#moog_ladder",
        "uberheim_filter": "http://polyeffects.com/lv2/polyfilter#oberheim",
        "midi_cc": "http://github.com/blablack/midimsg-lv2/controller",
        "cv_to_midi_cc": "http://polyeffects.com/lv2/cv_to_cc",
        # "midi_note": "http://drobilla.net/ns/ingen-internals#Note",
        # "midi_trigger": "http://drobilla.net/ns/ingen-internals#Trigger",
        'midi_clock_in': "http://polyeffects.com/lv2/mclk_in",
        "midi_clock_out": "http://gareus.org/oss/lv2/mclk",
        "vca": "http://polyeffects.com/lv2/basic_modular#amp",
        "difference": "http://polyeffects.com/lv2/basic_modular#difference",
        "rectify_value": "http://polyeffects.com/lv2/basic_modular#abs",
        "max" : "http://polyeffects.com/lv2/basic_modular#max",
        "min" : "http://polyeffects.com/lv2/basic_modular#min",
        "product" : "http://polyeffects.com/lv2/basic_modular#product",
        "ratio" : "http://polyeffects.com/lv2/basic_modular#ratio",
        "sum" : "http://polyeffects.com/lv2/basic_modular#sum",
        "macro_osc": "http://polyeffects.com/lv2/polyplaits",
        "midi_note_to_cv": "http://polyeffects.com/lv2/midi_to_cv_mono",
        # "two_voice": "http://moddevices.com/plugins/mod-devel/2Voices",
        # "capo": "http://moddevices.com/plugins/mod-devel/Capo",
        # "drop": "http://moddevices.com/plugins/mod-devel/Drop",
        # "harmony": "http://moddevices.com/plugins/mod-devel/Harmonizer",
        # "harmony2": "http://moddevices.com/plugins/mod-devel/Harmonizer2",
        # "harmony_custom": "http://moddevices.com/plugins/mod-devel/HarmonizerCS",
        # "extra_capo": "http://moddevices.com/plugins/mod-devel/SuperCapo",
        # "pitch_wam": "http://moddevices.com/plugins/mod-devel/SuperWhammy",
        "pitch_detect": "http://polyeffects.com/lv2/detect#pitch",
        "onset_detect": "http://polyeffects.com/lv2/detect#onset",
        # "pitch_corrector" : "http://gareus.org/oss/lv2/fat1",
        # "octaver" : "http://guitarix.sourceforge.net/plugins/gx_oc_2_#_oc_2_"
        "pitch_shift": "http://moddevices.com/plugins/tap/pitch",
        "adsr": "http://drobilla.net/plugins/blop/adsr",
        "sample_hold": "http://avwlv2.sourceforge.net/plugins/avw/samplehold",
        "dahdsr": "http://drobilla.net/plugins/blop/dahdsr",
        'drum_patterns': 'http://polyeffects.com/lv2/polygrids',
        'wet_dry': 'http://polyeffects.com/lv2/wet_dry',
        'wet_dry_stereo': 'http://polyeffects.com/lv2/wet_dry_stereo',
        'ad_env_level': 'http://drobilla.net/plugins/omins/adenv_lvl',
        'ad_envelope': 'http://drobilla.net/plugins/omins/adenv',
        'poly_note_to_cv': 'http://polyeffects.com/lv2/midi_to_cv_poly',
        # 'beat_repeat': 'http://polyeffects.com/lv2/polyclouds#beat_repeat',
        'tempo_ratio': 'http://polyeffects.com/lv2/basic_modular#tempo_ratio',
        'toggle': 'http://polyeffects.com/lv2/basic_modular#toggle',
        'phaser_ext': 'http://polyeffects.com/lv2/stone-phaser-ext',
        'phaser_stereo_ext': 'http://polyeffects.com/lv2/stone-phaser-stereo-ext',
        'harmonic_tremolo': 'http://polyeffects.com/lv2/harm_trem',
        'harmonic_trem_ext': 'http://polyeffects.com/lv2/harm_trem_ext',
        'chorus_d': 'http://polyeffects.com/lv2/chorus',
        'chorus_d_ext': 'http://polyeffects.com/lv2/chorus_ext',
        'flanger': 'http://polyeffects.com/lv2/flanger',
        'flanger_ext': 'http://polyeffects.com/lv2/flanger_ext',
        'vibrato': 'http://polyeffects.com/lv2/vibrato',
        'vibrato_ext': 'http://polyeffects.com/lv2/vibrato_ext',
        'step_sequencer_ext': 'http://polyeffects.com/lv2/step_sequencer',
        'step_sequencer': 'http://polyeffects.com/lv2/step_sequencer_bpm',
        }}

# categories effect, IO, control, synth, 

effect_prototypes_models_all = {
        "input": {"inputs": {},
            "outputs": {"output": ["in", "AudioPort"]},
            "controls": {}},
        "output": {"inputs": {"input": ["out", "AudioPort"]},
            "outputs": {},
            "controls": {}},
        "midi_input": {"inputs": {},
            "outputs": {"output": ["in", "AtomPort"]},
            "controls": {}},
        "midi_output": {"inputs": {"input": ["out", "AtomPort"]},
            "outputs": {},
            "controls": {}},
    'control_to_midi': {'description': '',
        'category': 1,
        'controls': {'AUTOFF': ['Auto Note-Off', 0, 0, 1],
                                      'CHAN': ['Channel', 0, 0, 15, "int"],
                                      'DATA1': ['Note/CC/PG Number', 0, 0, 127, "int"],
                                      'DATA2': ['Value', 0, 0, 127, "int"],
                                      'DELAY': ['1st Msg Repeat Delay Time',
                                                0.0,
                                                0.0,
                                                2000.0],
                                      'ENABLE': ['Enable', 1, 0, 1, "bool"],
                                      'MSGTYPE': ['Message Type', 11, 8, 15, "int"]},
                         'inputs': {},
                         'outputs': {'MIDI_OUT': ['MIDI Out', 'AtomPort']}},
    'delay': {'description': 'Flexible delay module. Add modules on the repeats for variations.',
        'category': 0,
        'kill_dry': True,
         'controls': {'Amp_5': ['Level', 0.5, 0, 1],
                      'BPM_0': ['BPM', 120, 30, 300],
                      'DelayT60_3': ['Glide', 0.5, 0, 100],
                      'Delay_1': ['Time', 0.5, 0.001, 64],
                      'FeedbackSm_6': ['Tone', 0, 0, 1],
                      'Feedback_4': ['Feedback', 0.3, 0, 1],
                      'Warp_2': ['Warp', 0, -1, 1],
                      'enabled': ['Enabled', 1, 0, 1]
                      },
         'inputs': {'Amp_5': ['Level', 'CVPort'],
                    'BPM_0': ['BPM', 'ControlPort'],
                    'DelayT60_3': ['Glide', 'CVPort'],
                    'Delay_1': ['Time', 'CVPort'],
                    'FeedbackSm_6': ['Tone', 'CVPort'],
                    'Feedback_4': ['Feedback', 'CVPort'],
                    'Warp_2': ['Warp', 'CVPort'],
                    'in0': ['in', 'AudioPort']},
         'outputs': {'out0': ['out', 'AudioPort']}},
     'env_follower': {'description': 'Track an input signal and convert it into a control signal', 
        'category': 2,
         'controls': {'ATIME': ['Attack Time', 0.01, 0.001, 2.0],
                                   'CDIRECTION': ['Invert', 0, 0, 1, "bool"],
                                   'CMAXV': ['Maximum Value',
                                             1.0,
                                             0.0,
                                             1.0],
                                   'CMINV': ['Minimum Value',
                                             0.0,
                                             0.0,
                                             1.0],
                                   'DTIME': ['Decay Time', .10, 0.001, 2.0],
                                   'PEAKRMS': ['Peak/RMS', 0.0, 0.0, 1.0],
                                   'SATURATION': ['Saturation', 1.0, 0.0, 2.0],
                                   'THRESHOLD': ['Threshold', 0.0, 0.0, 0.5]},
                      'inputs': {'INPUT': ['Audio In', 'AudioPort']},
                      'outputs': {#'CTL_IN': ['Input Level', 'ControlPort'],
                                  #'CTL_OUT': ['Control Out', 'ControlPort'],
                                  'CV_OUT': ['CV Out', 'CVPort']}},
     'filter': {'description': 'Virtual analog resonant low pass filter',
        'category': 3,
             'controls': {'exp_fm_gain': ['Exp. FM gain', 0.5, 0.0, 10.0],
                             'freq': ['Frequency', 440.0, 25, 18000],
                             'in_gain': ['Input gain', 0.0, -60.0, 10.0],
                             'out_gain': ['Output gain', 0.0, -15.0, 15.0],
                             'res': ['Resonance', 0.5, 0.0, 1.0],
                             'res_gain': ['Resonance gain', 0.5, 0.0, 1.0]},
                'inputs': {'exp_fm': ['Exp FM', 'CVPort'],
                           'fm': ['FM', 'CVPort'],
                           'in': ['Input', 'AudioPort'],
                           'res_mod': ['Resonance Mod', 'CVPort']},
                'outputs': {'out': ['Output', 'AudioPort']}},
     'foot_switch_a': {'description': 'The left footswitch', 
        'category': 1,
             'controls': {'bpm': ['BPM', 120.0, 35.0, 350.0],
                          'latching': ['Is Latching', 0.0, 0.0, 1.0, "bool"],
                          'on_v': ['On Value', 1.0, -1.0, 1.0],
                          'off_v': ['Off Value', 0.0, -1.0, 1.0],
                          'value': ['value', 0.0, 0.0, 1.0, "hide"],
                          'cur_out': ['value', 0.0, 0.0, 1.0, "hide"],
                          },
                         'inputs': {},
                         'outputs': {'bpm_out': ['BPM Out', 'ControlPort'],
                                     'out': ['Value Out', 'CVPort']}},

     'foot_switch_b': {'description': 'The center footswitch', 
        'category': 1,
             'controls': {'bpm': ['BPM', 120.0, 35.0, 350.0],
                          'latching': ['Is Latching', 0.0, 0.0, 1.0, "bool"],
                          'on_v': ['On Value', 1.0, -1.0, 1.0],
                          'off_v': ['Off Value', 0.0, -1.0, 1.0],
                          'value': ['value', 0.0, 0.0, 1.0, "hide"],
                          'cur_out': ['value', 0.0, 0.0, 1.0, "hide"],
                          },
                         'inputs': {},
                         'outputs': {'bpm_out': ['BPM Out', 'ControlPort'],
                                     'out': ['Value Out', 'CVPort']}},
     'foot_switch_c': {'description': 'The right footswitch',
        'category': 1,
             'controls': {'bpm': ['BPM', 120.0, 35.0, 350.0],
                          'latching': ['Is Latching', 0.0, 0.0, 1.0, "bool"],
                          'on_v': ['On Value', 1.0, -1.0, 1.0],
                          'off_v': ['Off Value', 0.0, -1.0, 1.0],
                          'value': ['value', 0.0, 0.0, 1.0, "hide"],
                          'cur_out': ['value', 0.0, 0.0, 1.0, "hide"],
                          },
                         'inputs': {},
                         'outputs': {'bpm_out': ['BPM Out', 'ControlPort'],
                                     'out': ['Value Out', 'CVPort']}},
     'lfo': {'description': 'Low frequency oscillator, send a control signal.',
        'category': 2,
             'controls': {'phi0': ['Shape Mod', 0, 0.0, 6.28],
                          'tempo': ['Tempo', 120.0, 1.0, 320.0],
                          'tempoMultiplier': ['Tempo Multiplier',
                                              1.0,
                                              0.0078125,
                                              32.0],
                          'waveForm': ['Wave Form', 0, 0, 5, "int"],
                          'level': ["Level", 1.0, -1.0, 1.0],
                          'is_uni': ["Unipolar", 1.0, 0.0, 1.0, "bool"],
                          },
             'inputs': {'reset': ['Reset', 'CVPort'],
                    'tempo': ['BPM', 'ControlPort']
                 },
             'outputs': {'output': ['Output', 'CVPort']}},
     'mix_vca': {'description': 'Voltage controlled amplifier. Used to change the level from a control signal.',
        'category': 2,
             'controls': {'gain1': ['Gain Offset', 0, 0, 1],
                              'gain1Data': ['Main Gain', 0.0, -1.0, 1.0],
                              'gain2': ['2nd Gain Boost', 0, 0, 1],
                              'gain2Data': ['2nd Gain', 0.0, -1.0, 1.0],
                              'in1': ['In 1 Level', 1, 0, 2],
                              'in2': ['In 2 Level', 1, 0, 2],
                              'outputLevel': ['Output Level', 1, 0, 2]},
                 'inputs': {'gain1Data': ['Main Gain', 'CVPort'],
                            'gain2Data': ['2nd Gain', 'CVPort'],
                            'in1Data': ['In 1', 'AudioPort'],
                            'in2Data': ['In 2', 'AudioPort']},
                 'outputs': {'out': ['Out', 'AudioPort']}},
     'mono_EQ': {'description': 'Mono multiband parametric EQ',
        'category': 0,
        # 'kill_dry': True,
             'controls': {'HPQ': ['HighPass Resonance', 0.7, 0.0, 1.4],
                              'HPfreq': ['Highpass Frequency', 20.0, 5.0, 1250.0],
                              'HSfreq': ['Highshelf Frequency',
                                         8000.0,
                                         1000.0,
                                         16000.0],
                              'HSgain': ['Highshelf Gain', 0.0, -18.0, 18.0],
                              'HSq': ['Highshelf Bandwidth', 1.0, 0.0625, 4.0],
                              'HSsec': ['Highshelf', 1, 0, 1],
                              'HighPass': ['Highpass', 0, 0, 1],
                              'LPQ': ['LowPass Resonance', 1.0, 0.0, 1.4],
                              'LPfreq': ['Lowpass Frequency',
                                         20000.0,
                                         500.0,
                                         20000.0],
                              'LSfreq': ['Lowshelf Frequency', 80.0, 25.0, 400.0],
                              'LSgain': ['Lowshelf Gain', 0.0, -18.0, 18.0],
                              'LSq': ['Lowshelf Bandwidth', 1.0, 0.0625, 4.0],
                              'LSsec': ['Lowshelf', 1, 0, 1],
                              'LowPass': ['Lowpass', 0, 0, 1],
                              'enable': ['Enable', 1, 0, 1],
                              'freq1': ['Frequency 1', 160.0, 20.0, 2000.0],
                              'freq2': ['Frequency 2', 397.0, 40.0, 4000.0],
                              'freq3': ['Frequency 3', 1250.0, 100.0, 10000.0],
                              'freq4': ['Frequency 4', 2500.0, 200.0, 20000.0],
                              'gain': ['Gain', 0.0, -18.0, 18.0],
                              'gain1': ['Gain 1', 0.0, -18.0, 18.0],
                              'gain2': ['Gain 2', 0.0, -18.0, 18.0],
                              'gain3': ['Gain 3', 0.0, -18.0, 18.0],
                              'gain4': ['Gain 4', 0.0, -18.0, 18.0],
                              'peakreset': ['Reset Peak Hold', 1, 0, 1],
                              'q1': ['Bandwidth 1', 0.6, 0.0625, 4.0],
                              'q2': ['Bandwidth 2', 0.6, 0.0625, 4.0],
                              'q3': ['Bandwidth 3', 0.6, 0.0625, 4.0],
                              'q4': ['Bandwidth 4', 0.6, 0.0625, 4.0],
                              'sec1': ['Section 1', 1, 0, 1],
                              'sec2': ['Section 2', 1, 0, 1],
                              'sec3': ['Section 3', 1, 0, 1],
                              'sec4': ['Section 4', 1, 0, 1]},
                 'inputs': {'in': ['In', 'AudioPort']},
                 'outputs': { 'out': ['Out', 'AudioPort']}},
     'mono_cab': {'description': 'Mono cab sim',
        'category': 0,
             'controls': {'gain': ['Output Gain', 0.0, -40.0, 24.0],
                            "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
                  'inputs': {'gain': ['Output Gain', 'CVPort'],
                             'in': ['In', 'AudioPort']},
                  'outputs': {'out': ['Out', 'AudioPort']}},
     'mono_reverb': {'description': 'Mono convolution based reverb.',
        'kill_dry': True,
        'category': 0,
             'controls': {'gain': ['Output Gain', 0.0, -40.0, 4.0],
                 'enabled': ['Enabled', 1, 0, 1],
                                 "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
                     'inputs': {'gain': ['Output Gain', 'CVPort'],
                                'in': ['In', 'AudioPort']},
                     'outputs': {'out': ['Out', 'AudioPort']}},
     'pan': {'description': 'Control signal controlled panner',
        'category': 0,
             'controls': {'panOffset': ['Pan Offset', 0, -1, 1]},
             'inputs': {'in': ['In', 'AudioPort'], 'panCV': ['Pan CV', 'CVPort']},
             'outputs': {'out1': ['Out L', 'AudioPort'],
                         'out2': ['Out R', 'AudioPort']}},
     'reverse': {'description': 'Reverse effect. Try short fragment length for weird tremolo',
        'category': 0,
             'controls': {'dry': ['Dry Level', 0.0, -90.0, 20.0],
                              'fragment': ['Fragment Length',
                                           1000.0,
                                           100.0,
                                           1600.0],
                              'wet': ['Wet Level', 0.0, -90.0, 20.0]},
                 'inputs': {'dry': ['Dry Level', 'CVPort'],
                            'input': ['Input', 'AudioPort'],
                            'wet': ['Wet Level', 'CVPort']},
                 'outputs': {'output': ['Output', 'AudioPort']}},
     'saturator': {'description': 'Nonlinear saturation and soft limiting.',
        'category': 0,
             'controls': {'Postgain': ['Postgain', 0, -90, 20],
                                'Pregain': ['Pregain', 0, -90, 20]},
                   'inputs': {'Input': ['Input', 'AudioPort'],
                              'Postgain': ['Postgain', 'CVPort'],
                              'Pregain': ['Pregain', 'CVPort']},
                   'outputs': {'Output': ['Output', 'AudioPort']}},
     'slew_limiter': {'description': 'Slows how fast a control signal changes. Useful with foot switches.',
        'category': 2,
             'controls': {  'timeDown': ['Time Down', 0.5, 0, 10],
                            'timeUp': ['Time Up', 0.5, 0.0, 10]},
                      'inputs': {'in': ['In', 'CVPort']},
                      'outputs': {'out': ['Out', 'CVPort']}},
     'square_distortion': {'description': '',
        'category': 0,
             'controls': {'DOWN': ['Down', 0.02, -0.5, 1.0],
                                        'IN_GAIN': ['Input Gain', 1.0, 0.0, 1.0],
                                        'OCTAVE': ['Octave', 0, -2, 1.0],
                                        'OUT_GAIN': ['Output Gain', 1.0, 0.0, 1.0],
                                        'UP': ['Up', 0.02, -0.5, 1.0],
                                        'WETDRY': ['Wet/Dry Mix', 0.7, 0.0, 1.0]},
                           'inputs': {'INPUT': ['Audio In', 'AudioPort']},
                           'outputs': {'OUTPUT': ['Audio Out', 'AudioPort']}},
     'stereo_EQ': {'description': 'Stereo multiband parametric EQ.',
        # 'kill_dry': True,
        'category': 0,
             'controls': {'HPQ': ['HighPass Resonance', 0.7, 0.0, 1.4],
                                'HPfreq': ['Highpass Frequency', 20.0, 5.0, 1250.0],
                                'HSfreq': ['Highshelf Frequency',
                                           8000.0,
                                           1000.0,
                                           16000.0],
                                'HSgain': ['Highshelf Gain', 0.0, -18.0, 18.0],
                                'HSq': ['Highshelf Bandwidth', 1.0, 0.0625, 4.0],
                                'HSsec': ['Highshelf', 1, 0, 1],
                                'HighPass': ['Highpass', 0, 0, 1],
                                'LPQ': ['LowPass Resonance', 1.0, 0.0, 1.4],
                                'LPfreq': ['Lowpass Frequency',
                                           20000.0,
                                           500.0,
                                           20000.0],
                                'LSfreq': ['Lowshelf Frequency', 80.0, 25.0, 400.0],
                                'LSgain': ['Lowshelf Gain', 0.0, -18.0, 18.0],
                                'LSq': ['Lowshelf Bandwidth', 1.0, 0.0625, 4.0],
                                'LSsec': ['Lowshelf', 1, 0, 1],
                                'LowPass': ['Lowpass', 0, 0, 1],
                                'enable': ['Enable', 1, 0, 1],
                                'freq1': ['Frequency 1', 160.0, 20.0, 2000.0],
                                'freq2': ['Frequency 2', 397.0, 40.0, 4000.0],
                                'freq3': ['Frequency 3', 1250.0, 100.0, 10000.0],
                                'freq4': ['Frequency 4', 2500.0, 200.0, 20000.0],
                                'gain': ['Gain', 0.0, -18.0, 18.0],
                                'gain1': ['Gain 1', 0.0, -18.0, 18.0],
                                'gain2': ['Gain 2', 0.0, -18.0, 18.0],
                                'gain3': ['Gain 3', 0.0, -18.0, 18.0],
                                'gain4': ['Gain 4', 0.0, -18.0, 18.0],
                                'q1': ['Bandwidth 1', 0.6, 0.0625, 4.0],
                                'q2': ['Bandwidth 2', 0.6, 0.0625, 4.0],
                                'q3': ['Bandwidth 3', 0.6, 0.0625, 4.0],
                                'q4': ['Bandwidth 4', 0.6, 0.0625, 4.0],
                                'sec1': ['Section 1', 1, 0, 1],
                                'sec2': ['Section 2', 1, 0, 1],
                                'sec3': ['Section 3', 1, 0, 1],
                                'sec4': ['Section 4', 1, 0, 1]},
                   'inputs': {'inL': ['In Left', 'AudioPort'],
                              'inR': ['In Right', 'AudioPort']},
                   'outputs': {'outL': ['Out Left', 'AudioPort'],
                               'outR': ['Out Right', 'AudioPort']}},
     'stereo_cab': {'description': 'Stereo cab sim. You normally do not want this. Requires stereo IRs.',
        'category': 0,
             'controls': {'gain': ['Output Gain', 0.0, -40.0, 24.0],
                            "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
                    'inputs': {'gain': ['Output Gain', 'CVPort'],
                               'in': ['In', 'AudioPort']},
                    'outputs': {'out_1': ['OutL', 'AudioPort'],
                                'out_2': ['OutR', 'AudioPort']}},
     'stereo_reverb': {'description': 'Stereo convolution reverb',
        'category': 0,
        'kill_dry': True,
             'controls': {'gain': ['Output Gain', 0.0, -40.0, 4.0],
                          'enabled': ['Enabled', 1, 0, 1],
                                 "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
                       'inputs': {'gain': ['Output Gain', 'CVPort'],
                                  'in': ['In', 'AudioPort']},
                       'outputs': {'out_1': ['OutL', 'AudioPort'],
                                   'out_2': ['OutR', 'AudioPort']}},
     'quad_ir_cab': {'description': 'Requires quad channel IR. You do not want this unless you have special IRs',
        'category': 0,
             'controls': {'gain': ['Gain', 0.0, -40.0, 24.0],
                            "ir": ["/audio/cabs/1x12cab.wav", 0, 0, 1]},
                         'inputs': {'gain': ['Gain', 'CVPort'],
                                    'in_1': ['InL', 'AudioPort'],
                                    'in_2': ['InR', 'AudioPort']},
                         'outputs': {'out_1': ['OutL', 'AudioPort'],
                                     'out_2': ['OutR', 'AudioPort']}},
     'quad_ir_reverb': {'description': 'Convolution reverb. Quad channel IRs required.',
        'category': 0,
        'kill_dry': True,
             'controls': {'gain': ['Output Gain', 0.0, -40.0, 4.0],
                          'enabled': ['Enabled', 1, 0, 1],
                                 "ir": ["/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1]},
                            'inputs': {'gain': ['Output Gain', 'CVPort'],
                                       'in_1': ['InL', 'AudioPort'],
                                       'in_2': ['InR', 'AudioPort']},
                            'outputs': {'out_1': ['OutL', 'AudioPort'],
                                        'out_2': ['OutR', 'AudioPort']}},
     'warmth': {'description': 'Tube triode emulation',
        'category': 0,
             'controls': {'blend': ['Tape--Tube Blend', 10, -10, 10],
                             'drive': ['Drive', 5.0, 0.1, 10]},
                'inputs': {'blend': ['Tape--Tube Blend', 'CVPort'],
                           'drive': ['Drive', 'CVPort'],
                           'input': ['Input', 'AudioPort']},
                'outputs': {'output': ['Output', 'AudioPort']}},
    'amp_bass': {'description': 'SVT40 bass amp sim',
        'category': 0,
            'controls': {'BASS': ['BASS', 0.5, 0.0, 1.0],
                                 'CABSWITCH': ['CABSWITCH', 0.0, 0.0, 1.0, "int"],
                                 'HIGHSWITCH': ['HIGHSWITCH', 0.0, 0.0, 1.0, "int"],
                                 'LOWSWITCH': ['LOWSWITCH', 1.0, 0.0, 2.0, "int"],
                                 'MIDDLE': ['MIDDLE', 0.5, 0.0, 1.0],
                                 'MIDSWITCH': ['MIDSWITCH', 1.0, 0.0, 2.0, "int"],
                                 'TREBLE': ['TREBLE', 0.5, 0.0, 1.0],
                                 'VOLUME': ['VOLUME', 0.2, 0.0, 1.0]},
                    'inputs': {'in': ['In', 'AudioPort']},
                    'outputs': {'out': ['Out', 'AudioPort']}},
     'amp_bass_venue': {'description': '',
        'category': 0,
             'controls': {'BASS': ['BASS', 0.5, 0.0, 1.0],
                                     'CAB': ['CAB', 0.0, 0.0, 1.0],
                                     'MID': ['MID', 0.5, 0.0, 1.0],
                                     'TREBLE': ['TREBLE', 0.5, 0.0, 1.0],
                                     'VOLUME': ['VOLUME', 0.5, 0.0, 1.0]},
                        'inputs': {'in': ['In', 'AudioPort']},
                        'outputs': {'out': ['Out', 'AudioPort']}},
     'auto_swell': {'description': 'Automatically swells volume to remove note attack',
        'category': 0,
             'controls': {'DOWNTIME': ['DOWNTIME', 5.0, 0.0, 5000],
                                 'TRESHOLD': ['THRESHOLD', 1.0, 0.0, 1],
                                 'UPTIME': ['UPTIME', 100, 0.0, 5000]},
                    'inputs': {'TRESHOLD': ['THRESHOLD', 'CVPort'],
                               'in': ['In', 'AudioPort']},
                    'outputs': {'out': ['Out', 'AudioPort']}},
     'freeze': {'description': 'Holds what you’re playing when the control level is active, creating a drone.',
        'category': 0,
             'controls': {'DRONE_GAIN': ['Drone Gain', 0.5, 0.0, 2.0],
                             'RELEASE': ['Release', 0.5, 0.01, 3.0],
                             'STICK_IT': ['Freeze', 0, 0, 1, "bool"]},
                'inputs': {'INPUT': ['Audio In', 'AudioPort'],
                           'STICK_IT': ['Freeze', 'CVPort']},
                'outputs': {'OUTPUT': ['Audio Out', 'AudioPort']}},
     'power_amp_cream': {'description': 'An attempt at a cream coloured power amp emulation.',
        'category': 0,
             'controls': {'BASS': ['BASS', 0.5, 0.0, 1.0],
                                      'LEVEL': ['LEVEL', 0.5, 0.0, 1.0],
                                      'TREBLE': ['TREBLE', 0.5, 0.0, 1.0],
                                      'VOLUME': ['VOLUME', 0.5, 0.0, 1.0]},
                         'inputs': {'in': ['In', 'AudioPort']},
                         'outputs': {'out': ['Out', 'AudioPort']}},
     'power_amp_plexi': {'description': '',
        'category': 0,
             'controls': {'BASS': ['BASS', 0.5, 0.0, 1.0],
                                      'MASTER': ['MASTER', 0.4, 0.0, 1.0],
                                      'MID': ['MID', 0.5, 0.0, 1.0],
                                      'PRESENSE': ['PRESENSE', 0.15, 0.0, 1.0],
                                      'TREBLE': ['TREBLE', 0.5, 0.0, 1.0],
                                      'VOLUME': ['VOLUME', 0.15, 0.0, 1.0]},
                         'inputs': {'in': ['In', 'AudioPort']},
                         'outputs': {'out': ['Out', 'AudioPort']}},
     'power_amp_super': {'description': 'An attempt at a power amp emulation',
        'category': 0,
             'controls': {'BASS': ['BASS', 0.5, 0.0, 1.0],
                                      'GAIN': ['GAIN', 0.15, 0.0, 1.0],
                                      'TREBLE': ['TREBLE', 0.5, 0.0, 1.0],
                                      'VOLUME': ['VOLUME', 0.25, 0.0, 1.0]},
                         'inputs': {'in': ['In', 'AudioPort']},
                         'outputs': {'out': ['Out', 'AudioPort']}},
     'turntable_stop': {'description': 'Simulates turning off a turntable. Connect a control to pull the plug.',
        'category': 0,
             'controls': {'DCURVE': ['Decay Curve', 0.0, -10.0, 10.0],
                                     'DTIME': ['Decay Time', 0.5, 0.01, 10.0],
                                     'PULL_THE_PLUG': ['Pull the Plug', 0, 0, 1, "bool"]},
                        'inputs': {'DTIME': ['Decay Time', 'CVPort'],
                                   'INPUT': ['Audio In', 'AudioPort'],
                                   'PULL_THE_PLUG': ['Pull the Plug', 'CVPort']},
                        'outputs': {'OUTPUT': ['Audio Out', 'AudioPort']}},
     'whammy': {'description': '',
        'category': 0,
             'controls': {'EXPRESSION': ['Expression', 0.0, 0.0, 1.0],
                             'FINISH': ['Finish', 12, -36, 24],
                             'LOCK': ['Lock Mode', 1, 0, 2],
                             'MODE': ['Mode', 0, 0, 2],
                             'START': ['Start', 0, -36, 24]},
                'inputs': {'EXPRESSION': ['Expression', 'CVPort'],
                           'FINISH': ['Finish', 'CVPort'],
                           'INPUT': ['Audio In', 'AudioPort'],
                           'START': ['Start', 'CVPort']},
                'outputs': { 'OUTPUT': ['Audio Out', 'AudioPort']}},
    'attenuverter': {'description': 'The attenuverter changes level and/or phase of a control signal. A x B',
        'category': 2,
            'controls': {'multiplicand': ['A', 0.5, -1.0, 1.0],
                               'multiplier': ['B', 0.5, -1.0, 1.0]},
                  'inputs': {'multiplicand': ['A', 'CVPort'],
                           'multiplier': ['B', 'CVPort']},
                  'outputs': {'product': ['Product', 'CVPort']}},
 'mono_compressor': {'description': 'RMS downward compressor with auto markup',
        'category': 0,
        # "kill_dry": True,
         'controls': {'Ratio': ['Ratio', 0.0, 0.0, 1.0],
                     'enable': ['Enable', 1, 0, 1, "hide"],
                                  'attack': ['Attack Time', 0.01, 0.001, 0.1],
                                  'hold': ['Hold', 0, 0, 1, "bool"],
                                  'inputgain': ['Input Gain', 0.0, -10.0, 30.0],
                                  'release': ['Release Time', 0.3, 0.03, 3.0],
                                  'threshold': ['Threshold',
                                                -30.0,
                                                -50.0,
                                                -10.0]},
                     'inputs': {'in': ['In', 'AudioPort']},
                     'outputs': {'out': ['Out', 'AudioPort']}},
 'rotary': {'description': 'A rotating loudspeaker using physical modelling. Same sound as advanced.',
        'category': 0,
        # "kill_dry": True,
         'controls': {'drumlvl': ['Drum Level', 0.0, -20.0, 20.0],
                         'drumwidth': ['Drum Stereo Width', 1.0, 0.0, 2.0],
                         'enable': ['Enable', 1, 0, 1],
                         'hornlvl': ['Horn Level', 0.0, -20.0, 20.0],
                         'rt_speed': ['Motors Ac/Dc', 4, 0, 8]},
            'inputs': {'in': ['Input', 'AudioPort'],
                             'horn_speed_cv': ['Horn Speed', 'CVPort'],
                             'drum_speed_cv': ['Drum Speed', 'CVPort'],
                             'horn_brake_cv': ['Horn Brake', 'CVPort'],
                             'drum_brake_cv': ['Drum Brake', 'CVPort'],
                         },
            'outputs': {'left': ['Left Output', 'AudioPort'],
                        'right': ['Right Output', 'AudioPort']}},
 'stereo_compress': {'description': 'RMS downward compressor with auto markup',
        'category': 0,
        # "kill_dry": True,
         'controls': {'Ratio': ['Ratio', 0.0, 0.0, 1.0],
                                    'attack': ['Attack Time', 0.01, 0.001, 0.1],
                                    'enable': ['Enable', 1, 0, 1, "hide"],
                                    'hold': ['Hold', 0, 0, 1, "bool"],
                                    'inputgain': ['Input Gain',
                                                  0.0,
                                                  -10.0,
                                                  30.0],
                                    'release': ['Release Time', 0.3, 0.03, 3.0],
                                    'threshold': ['Threshold',
                                                  -30.0,
                                                  -50.0,
                                                  -10.0]},
                       'inputs': {'inL': ['In Left', 'AudioPort'],
                                  'inR': ['In Right', 'AudioPort']},
                       'outputs': {'outL': ['Out Left', 'AudioPort'],
                                   'outR': ['Out Right', 'AudioPort']}},
 'j_chorus': {'description': 'chorus based on vintage Japanese synth chorus',
        'category': 0,
         'controls': {u'chorus_1_enable': [u'Chorus 1 On/Off',
                                                1.0,
                                                0.0,
                                                1.0, "bool"],
                           u'chorus_1_lfo_rate': [u'Chorus 1 LFO Rate',
                                                  5.0,
                                                  0.1,
                                                  10.0],
                           u'chorus_2_enable': [u'Chorus 2 On/Off',
                                                0.0,
                                                0.0,
                                                1.0, "bool"],
                           u'chorus_2_lfo_rate': [u'Chorus 2 LFO Rate',
                                                  8.3,
                                                  0.1,
                                                  10.0]},
              'inputs': {u'lv2_audio_in_1': [u'Audio Input 1', 'AudioPort'],
                           u'chorus_2_enable': [u'2 Enable', "CVPort"],
                           u'chorus_1_enable': [u'1 Enable', "CVPort"],
                         u'lv2_audio_in_2': [u'Audio Input 2', 'AudioPort']},
              'outputs': {u'lv2_audio_out_1': [u'Audio Output 1',
                                               u'AudioPort'],
                          u'lv2_audio_out_2': [u'Audio Output 2',
                                               u'AudioPort']}},
 'phaser': {'description': 'Basic phaser',
        'category': 0,
         'controls': {u'color': [u'Color', 1, 0, 1, "bool"],
                         u'feedback_depth': [u'Feedback depth', 75, 0, 99],
                         u'feedback_hpf_cutoff': [u'Feedback bass cut',
                                                  500.0,
                                                  10.0,
                                                  5000.0],
                         u'lfo_frequency': [u'LFO frequency',
                                            0.2,
                                            0.01,
                                            5.0],
                         u'mix': [u'Dry/wet mix', 50, 0, 100]},
            'inputs': {u'lv2_audio_in_1': [u'Audio Input 1', 'AudioPort']},
            'outputs': {u'lv2_audio_out_1': [u'Audio Output 1',
                                             u'AudioPort']}},
 'stereo_phaser': {'description': 'Basic stereo phaser',
        'category': 0,
         'controls': {u'color': [u'Color', 1, 0, 1, "bool"],
                                u'feedback_depth': [u'Feedback depth',
                                                    75,
                                                    0,
                                                    99],
                                u'feedback_hpf_cutoff': [u'Feedback bass cut',
                                                         500.0,
                                                         10.0,
                                                         5000.0],
                                u'lfo_frequency': [u'LFO frequency',
                                                   0.2,
                                                   0.01,
                                                   5.0],
                                u'mix': [u'Dry/wet mix', 50, 0, 100],
                                u'stereo_phase': [u'Stereo phase',
                                                  0,
                                                  -180,
                                                  180]},
                   'inputs': {u'lv2_audio_in_1': [u'Audio Input 1',
                                                  'AudioPort'],
                              u'lv2_audio_in_2': [u'Audio Input 2',
                                                  'AudioPort']},
                   'outputs': {u'lv2_audio_out_1': [u'Audio Output 1',
                                                    u'AudioPort'],
                               u'lv2_audio_out_2': [u'Audio Output 2',
                                                    u'AudioPort']}},
 'thruzero_flange': {'description': 'Through Zero Flanger.',
        'category': 0,
         'controls': {'depth': ['Depth', 0.43, 0.0, 1.0],
                                  'depth_mod': ['Depth Mod', 1.0, 0.0, 1.0],
                                  'feedback': ['Feedback', 0.3, 0.0, 1.0],
                                  'mix': ['Mix', 0.47, 0.0, 1.0],
                                  'rate': ['Rate', 0.3, 0.0, 1.0]},
                     'inputs': {'left_in': ['Left In', 'AudioPort'],
                                'depth': ['Depth', "CVPort"],
                                  'depth_mod': ['Depth Mod', "CVPort"],
                                  'feedback': ['Feedback', "CVPort"],
                                  'mix': ['Mix', "CVPort"],
                                  'rate': ['Rate', "CVPort"],
                                'right_in': ['Right In', 'AudioPort']},
                     'outputs': {'left_out': ['Left Out', 'AudioPort'],
                                 'right_out': ['Right Out', 'AudioPort']}},
    'algo_reverb': {'description': 'An algorthmic reverb, featuring longer tails than the convolution reverb.',
        'category': 0,
            'controls': {'blend_param': ['blend', 0.5, 0.0, 1.0],
                              'density_param': ['decay', 0.7, 0.0, 1.0],
                              'feedback_param': ['Modulation Speed',
                                                 0.44,
                                                 0.0,
                                                 1.0],
                              'freeze_param': ['hold', 0.5, 0.0, 1.0],
                              # 'in_gain_param': ['in_gain', 0.5, 0.0, 1.0],
                              'pitch_param': ['pitch', 0.0, -48.0, 48.0, "int"],
                              'position_param': ['pre-delay', 0.5, 0.0, 1.0],
                              'reverb_param': ['Modulation Amount',
                                               0.0,
                                               0.0,
                                               1.0],
                              'reverse_param': ['reverse', 0.0, 0.0, 1.0],
                              'size_param': ['size', 0.77, 0.0, 1.0],
                              'spread_param': ['diffusion', 0.09, 0.0, 1.0],
                              'texture_param': ['damp', 0.33, 0.0, 1.0]},
                 'inputs': {'Feedback': ['Modulation Speed', 'CVPort'],
                            'blend': ['Blend', 'CVPort'],
                            'density': ['Decay', 'CVPort'],
                            'freeze': ['Hold', 'CVPort'],
                            'l_in': ['L in', 'AudioPort'],
                            'pitch': ['Pitch', 'CVPort'],
                            'position': ['pre-delay', 'CVPort'],
                            'r_in': ['R in', 'AudioPort'],
                            'reverb': ['Modulation Amount', 'CVPort'],
                            'reverse': ['Reverse', 'CVPort'],
                            'size': ['Size', 'CVPort'],
                            'spread': ['Diffusion', 'CVPort'],
                            'texture': ['Damp', 'CVPort'],
                            'trig': ['Trigger', 'CVPort']},
                 'outputs': {'l_out': ['L Out', 'AudioPort'],
                             'r_out': ['R Out', 'AudioPort']}},
 'bitmangle': {'description': 'Brutal bitmangler. Warning, can get very loud.', 
        'category': 0,
         'controls': {'bits': ['bits', 0.0, 0.0, 3.0],
                            'input_amp': ['amp or freq', 0.04, 0.0, 1.0],
                            'input_amp_2': ['input amplitude 2', 0.15, 0.0, 1.0],
                            'int_osc': ['int_osc', 0.0, 0.0, 3.0],
                            'xor_vs_and': ['xor vs and', 0.5, 0.0, 1.0]},
               'inputs': {'bit_cv': ['bit cv', 'CVPort'],
                          'carrier': ['carrier', 'AudioPort'],
                          'input_amp_2_cv': ['input_amp_2_cv', 'CVPort'],
                          'input_amp_cv': ['input_amp_cv', 'CVPort'],
                          'modulator': ['modulator', 'AudioPort'],
                          'xor_vs_and_cv': ['xor vs and cv', 'CVPort']},
               'outputs': {'aux': ['aux', 'AudioPort'],
                           'out': ['out', 'AudioPort']}},
 'chebyschev_waveshaper': {'description': '',
        'category': 2,
         'controls': {'gain': ['gain', 0.5, 0.0, 1.0],
                                        'input_amp': ['amp or freq',
                                                      1.0,
                                                      0.0,
                                                      1.0],
                                        'input_amp_2': ['input amplitude 2',
                                                        1.0,
                                                        0.0,
                                                        1.0],
                                        'int_osc': ['int_osc', 0.0, 0.0, 3.0],
                                        'order': ['order', 0.0, 0.0, 8.0]},
                           'inputs': {'carrier': ['carrier', 'AudioPort'],
                                      'gain_cv': ['gain cv', 'CVPort'],
                                      'input_amp_2_cv': ['input_amp_2_cv',
                                                         'CVPort'],
                                      'input_amp_cv': ['input_amp_cv',
                                                       'CVPort'],
                                      'modulator': ['modulator', 'AudioPort'],
                                      'order_cv': ['order cv', 'CVPort']},
                           'outputs': {'aux': ['aux', 'AudioPort'],
                                       'out': ['out', 'AudioPort']}},
 'comparator': {'description': '',
        'category': 0,
         'controls': {'comparator': ['comparator', 0.0, 0.0, 8.0],
                             'input_amp': ['amp or freq', 1.0, 0.0, 1.0],
                             'input_amp_2': ['input amplitude 2',
                                             1.0,
                                             0.0,
                                             1.0],
                             'int_osc': ['int_osc', 0.0, 0.0, 3.0],
                             'order': ['order', 0.5, 0.0, 1.0]},
                'inputs': {'carrier': ['carrier', 'AudioPort'],
                           'comparator_cv': ['comparator cv', 'CVPort'],
                           'input_amp_2_cv': ['input_amp_2_cv', 'CVPort'],
                           'input_amp_cv': ['input_amp_cv', 'CVPort'],
                           'modulator': ['modulator', 'AudioPort'],
                           'order_cv': ['order_cv', 'CVPort']},
                'outputs': {'aux': ['aux', 'AudioPort'],
                            'out': ['out', 'AudioPort']}},
 'doppler_panner': {'description': 'binaural panner, allows positioning in 3D.',
        'category': 0,
         'controls': {'lfo_amplitude': ['lfo_amplitude',
                                                   0.22,
                                                   0.0,
                                                   1.0],
                                 'lfo_frequency': ['lfo_frequency',
                                                   0.11,
                                                   0.0,
                                                   1.0],
                                 'space_size': ['space_size', 2.0, 0.0, 3.0],
                                 'x_coord': ['x coordinate', 4.45, 0.0, 8.0],
                                 'y_coord': ['y coordinate', 0.04, 0.0, 1.0]},
                    'inputs': {'carrier': ['right in', 'AudioPort'],
                               'lfo_amplitude_cv': ['lfo_amplitude_cv',
                                                    'CVPort'],
                               'lfo_frequency_cv': ['lfo frequency cv',
                                                    'CVPort'],
                               'modulator': ['left in', 'AudioPort'],
                               'x_coord_cv': ['x coordinate cv', 'CVPort'],
                               'y_coord_cv': ['y coordinate cv', 'CVPort']},
                    'outputs': {'aux': ['right out', 'AudioPort'],
                                'out': ['left out', 'AudioPort']}},
 'frequency_shifter': {'description': '', 
        'category': 0,
         'controls': {'crossfade': ['crossfade', 0.5, 0.0, 1.0],
                                    'dry_wet': ['dry wet', 1.0, 0.0, 1.0],
                                    'feedback': ['feedback', 1.0, 0.0, 1.0],
                                    'frequency_shift': ['frequency shift',
                                                        0.0,
                                                        0.0,
                                                        8.0],
                                    'mode': ['mode', 0.0, 0.0, 3.0]},
                       'inputs': {'carrier': ['in 1', 'AudioPort'],
                                  'crossfade_cv': ['crossfade cv', 'CVPort'],
                                  'dry_wet_cv': ['dry wet cv', 'CVPort'],
                                  'feedback_cv': ['feedback cv', 'CVPort'],
                                  'frequency_shift_cv': ['frequency shift cv',
                                                         'CVPort'],
                                  'modulator': ['in 2', 'AudioPort']},
                       'outputs': {'aux': ['down', 'AudioPort'],
                                   'out': ['up', 'AudioPort']}},
 'granular': {'description': 'granular texture generator, can work as a weird delay or reverb',
        'category': 3,
              'controls': {'blend_param': ['blend', 0.78, 0.0, 1.0],
                           'density_param': ['density', 0.27, 0.0, 1.0],
                           'feedback_param': ['feedback', 0.55, 0.0, 1.0],
                           'freeze_param': ['freeze', 0.0, 0.0, 1.0],
                           # 'in_gain_param': ['in_gain', 0.5, 0.0, 1.0],
                           'pitch_param': ['pitch', 0.1, -48.0, 48.0, "int"],
                           'position_param': ['position', 0.24, 0.0, 1.0],
                           'reverb_param': ['reverb', 0.6, 0.0, 1.0],
                           'reverse_param': ['reverse', 0.0, 0.0, 1.0],
                           'size_param': ['size', 0.69, 0.0, 1.0],
                           'spread_param': ['spread', 0.7, 0.0, 1.0],
                           'texture_param': ['texture', 0.73, 0.0, 1.0]},
              'inputs': {'Feedback': ['feedback', 'CVPort'],
                         'blend': ['Blend', 'CVPort'],
                         'density': ['Density', 'CVPort'],
                         'freeze': ['Freeze', 'CVPort'],
                         'l_in': ['L in', 'AudioPort'],
                         'pitch': ['Pitch', 'CVPort'],
                         'position': ['Position', 'CVPort'],
                         'r_in': ['R in', 'AudioPort'],
                         'reverb': ['Reverb', 'CVPort'],
                         'reverse': ['Reverse', 'CVPort'],
                         'size': ['Size', 'CVPort'],
                         'spread': ['Spread', 'CVPort'],
                         'texture': ['Texture', 'CVPort'],
                         'trig': ['Trigger', 'CVPort']},
              'outputs': {'l_out': ['L Out', 'AudioPort'],
                          'r_out': ['R Out', 'AudioPort']}},
 'looping_delay': {'description': 'granular pitch shifting, micro looping delay',
        'category': 0,
                   'controls': {'blend_param': ['blend', 0.44, 0.0, 1.0],
                                'density_param': ['diffusion', 0.7, 0.0, 1.0],
                                'feedback_param': ['feedback', 0.53, 0.0, 1.0],
                                'freeze_param': ['freeze', 0.0, 0.0, 1.0],
                                # 'in_gain_param': ['in_gain', 0.5, 0.0, 1.0],
                                'pitch_param': ['pitch', 0.0, -48.0, 48.0, "int"],
                                'position_param': ['tape length', 0.4, 0.0, 1.0],
                                'reverb_param': ['reverb', 0.3, 0.0, 1.0],
                                'reverse_param': ['reverse', 0.0, 0.0, 1.0],
                                'size_param': ['pitch windows', 0.6, 0.0, 1.0],
                                'spread_param': ['spread', 0.81, 0.0, 1.0],
                                'texture_param': ['filter', 0.44, 0.0, 1.0]},
                   'inputs': {'Feedback': ['feedback', 'CVPort'],
                              'blend': ['Blend', 'CVPort'],
                              'density': ['Diffusion', 'CVPort'],
                              'freeze': ['Loop', 'CVPort'],
                              'l_in': ['L in', 'AudioPort'],
                              'pitch': ['Pitch', 'CVPort'],
                              'position': ['tape length', 'CVPort'],
                              'r_in': ['R in', 'AudioPort'],
                              'reverb': ['Reverb', 'CVPort'],
                              'reverse': ['Reverse', 'CVPort'],
                              'size': ['pitch window', 'CVPort'],
                              'spread': ['Spread', 'CVPort'],
                              'texture': ['Filter', 'CVPort'],
                              'trig': ['Trigger', 'CVPort']},
                   'outputs': {'l_out': ['L Out', 'AudioPort'],
                               'r_out': ['R Out', 'AudioPort']}},
 'meta_modulation': {'description': 'Powerful cross modulation module. Applies an algorithm to the two inputs.', 
        'category': 3,
         'controls': {'algorithm': ['algorithm', 0.0, 0.0, 8.0],
                                  'level1': ['level 1', 1.0, 0.0, 1.0],
                                  'level2': ['level 2', 1.0, 0.0, 1.0],
                                  'shape': ['shape', 0.0, 0.0, 3.0],
                                  'timbre': ['timbre', 0.5, 0.0, 1.0]},
                     'inputs': {'algorthm_cv': ['algorthm cv', 'CVPort'],
                                'carrier': ['carrier', 'AudioPort'],
                                'level1_cv': ['level 1 cv', 'CVPort'],
                                'level2_cv': ['level 2 cv', 'CVPort'],
                                'modulator': ['modulator', 'AudioPort'],
                                'timbre_cv': ['timbre cv', 'CVPort']},
                     'outputs': {'aux': ['aux', 'AudioPort'],
                                 'out': ['out', 'AudioPort']}},
 'resonestor': {'description': 'dual voice four part resonator',
        'category': 3,
         'controls': {'blend_param': ['random mod', 0.05, 0.0, 1.0],
                             'density_param': ['decay', 0.52, 0.0, 1.0],
                             'feedback_param': ['harmonics', 0.6, 0.0, 1.0],
                             'freeze_param': ['Switch Voice', 0.0, 0.0, 1.0],
                             # 'in_gain_param': ['in_gain', 0.5, 0.0, 1.0],
                             'pitch_param': ['pitch', 0.0, -48.0, 48.0, "int"],
                             'position_param': ['timbre', 0.83, 0.0, 1.0],
                             'reverb_param': ['scatter', 0.08, 0.0, 1.0],
                             'reverse_param': ['reverse', 0.0, 0.0, 1.0],
                             'size_param': ['chord', 0.36, 0.0, 1.0],
                             'spread_param': ['spread', 0.82, 0.0, 1.0],
                             'texture_param': ['filter', 0.5, 0.0, 1.0]},
                'inputs': {'blend': ['Random Mod', 'CVPort'],
                           'density': ['Decay', 'CVPort'],
                           'feedback': ['Harmonics', 'CVPort'],
                           'freeze': ['Switch Voice', 'CVPort'],
                           'l_in': ['L in', 'AudioPort'],
                           'pitch': ['Pitch', 'CVPort'],
                           'position': ['Timbre', 'CVPort'],
                           'r_in': ['R in', 'AudioPort'],
                           'reverb': ['Scatter', 'CVPort'],
                           'reverse': ['Reverse', 'CVPort'],
                           'size': ['Chord', 'CVPort'],
                           'spread': ['Spread', 'CVPort'],
                           'texture': ['Filter', 'CVPort'],
                           'trig': ['Trigger', 'CVPort']},
                'outputs': {'l_out': ['L Out', 'AudioPort'],
                            'r_out': ['R Out', 'AudioPort']}},
 'spectral_twist': {'description': '',
        'category': 3,
         'controls': {'blend_param': ['blend', 0.5, 0.0, 1.0],
                                 'density_param': ['density', 0.5, 0.0, 1.0],
                                 'feedback_param': ['feedback', 0.5, 0.0, 1.0],
                                 'freeze_param': ['freeze', 0.5, 0.0, 1.0],
                                 # 'in_gain_param': ['in_gain', 0.5, 0.0, 1.0],
                                 'pitch_param': ['pitch', 0.0, -48.0, 48.0, "int"],
                                 'position_param': ['position', 0.5, 0.0, 1.0],
                                 'reverb_param': ['reverb', 0.5, 0.0, 1.0],
                                 'reverse_param': ['reverse', 0.5, 0.0, 1.0],
                                 'size_param': ['size', 0.5, 0.0, 1.0],
                                 'spread_param': ['spread', 0.5, 0.0, 1.0],
                                 'texture_param': ['texture', 0.5, 0.0, 1.0]},
                    'inputs': {'Feedback': ['feedback', 'CVPort'],
                               'blend': ['Blend', 'CVPort'],
                               'density': ['Density', 'CVPort'],
                               'freeze': ['Freeze', 'CVPort'],
                               'l_in': ['L in', 'AudioPort'],
                               'pitch': ['Pitch', 'CVPort'],
                               'position': ['Position', 'CVPort'],
                               'r_in': ['R in', 'AudioPort'],
                               'reverb': ['Reverb', 'CVPort'],
                               'reverse': ['Reverse', 'CVPort'],
                               'size': ['Size', 'CVPort'],
                               'spread': ['Spread', 'CVPort'],
                               'texture': ['Texture', 'CVPort'],
                               'trig': ['Trigger', 'CVPort']},
                    'outputs': {'l_out': ['L Out', 'AudioPort'],
                                'r_out': ['R Out', 'AudioPort']}},
 'time_stretch': {'description': 'A granular time stretching and pitch shifting module', 
        'category': 3,
         'controls': {'blend_param': ['blend', 0.5, 0.0, 1.0],
                               'density_param': ['Diffusion', 0.18, 0.0, 1.0],
                               'feedback_param': ['feedback', 0.48, 0.0, 1.0],
                               'freeze_param': ['freeze', 0.0, 0.0, 1.0],
                               # 'in_gain_param': ['in_gain', 0.5, 0.0, 1.0],
                               'pitch_param': ['pitch', 0.0, -48.0, 48.0, "int"],
                               'position_param': ['position', 0.5, 0.0, 1.0],
                               'reverb_param': ['reverb', 0.15, 0.0, 1.0],
                               'reverse_param': ['reverse', 0.0, 0.0, 1.0],
                               'size_param': ['size', 0.66, 0.0, 1.0],
                               'spread_param': ['spread', 0.79, 0.0, 1.0],
                               'texture_param': ['Filter', 0.48, 0.0, 1.0]},
                  'inputs': {'Feedback': ['feedback', 'CVPort'],
                             'blend': ['Blend', 'CVPort'],
                             'density': ['Diffusion', 'CVPort'],
                             'freeze': ['Loop', 'CVPort'],
                             'l_in': ['L in', 'AudioPort'],
                             'pitch': ['Pitch', 'CVPort'],
                             'position': ['Position', 'CVPort'],
                             'r_in': ['R in', 'AudioPort'],
                             'reverb': ['Reverb', 'CVPort'],
                             'reverse': ['Reverse', 'CVPort'],
                             'size': ['Size', 'CVPort'],
                             'spread': ['Spread', 'CVPort'],
                             'texture': ['Filter', 'CVPort'],
                             'trig': ['Trigger', 'CVPort']},
                  'outputs': {'l_out': ['L Out', 'AudioPort'],
                              'r_out': ['R Out', 'AudioPort']}},
 'twist_delay': {'description': 'A delay where speed & length interact with quality', 
        'category': 0,
         'controls': {'dry_wet': ['dry wet', 0.5, 0.0, 1.0],
                              'feedback': ['feedback', 0.75, 0.0, 1.0],
                              'length': ['length', 0.95, 0.0, 1.0],
                              'mode': ['mode', 1.0, 0.0, 3.0],
                              'speed_direction': ['speed direction',
                                                  2.39,
                                                  0.0,
                                                  8.0]},
                 'inputs': {'carrier': ['in 1', 'AudioPort'],
                            'dry_wet_cv': ['dry wet cv', 'CVPort'],
                            'feedback_cv': ['feedback cv', 'CVPort'],
                            'length_cv': ['length cv', 'CVPort'],
                            'modulator': ['in 2', 'AudioPort'],
                            'speed_direct_cv': ['speed direction cv',
                                                'CVPort']},
                 'outputs': {'aux': ['out 2', 'AudioPort'],
                             'out': ['out 1', 'AudioPort']}},
 'vocoder': {'description': '', 
        'category': 0,
         'controls': {'input_amp': ['amp or freq', 1.0, 0.0, 1.0],
                          'input_amp_2': ['input amplitude 2', 1.0, 0.0, 1.0],
                          'int_osc': ['int_osc', 0.0, 0.0, 3.0],
                          'release': ['release time', 0.5, 0.0, 1.0],
                          'warping': ['warping', 0.0, 0.0, 8.0]},
             'inputs': {'carrier': ['carrier', 'AudioPort'],
                        'input_amp_2_cv': ['input_amp_2_cv', 'CVPort'],
                        'input_amp_cv': ['input_amp_cv', 'CVPort'],
                        'modulator': ['modulator', 'AudioPort'],
                        'release_cv': ['release time cv', 'CVPort'],
                        'warping_cv': ['warping cv', 'CVPort']},
             'outputs': {'aux': ['aux', 'AudioPort'],
                         'out': ['out', 'AudioPort']}},
 'wavefolder': {'description': 'Chebyshev wave folder', 
        'category': 3,
         'controls': {'input_amp': ['amp or freq', 1.0, 0.0, 1.0],
                             'input_amp_2': ['input amplitude 2',
                                             1.0,
                                             0.0,
                                             1.0],
                             'input_bias': ['input_bias', 0.5, 0.0, 1.0],
                             'int_osc': ['int_osc', 0.0, 0.0, 3.0],
                             'n_folds': ['number of folds', 0.0, 0.0, 8.0]},
                'inputs': {'carrier': ['carrier', 'AudioPort'],
                           'input_amp_2_cv': ['input_amp_2_cv', 'CVPort'],
                           'input_amp_cv': ['input_amp_cv', 'CVPort'],
                           'input_bias_cv': ['input_bias_cv', 'CVPort'],
                           'modulator': ['modulator', 'AudioPort'],
                           'num_fold_cv': ['num_fold_cv', 'CVPort']},
                'outputs': {'aux': ['aux', 'AudioPort'],
                            'out': ['out', 'AudioPort']}},
 'diode_ladder_lpf': {'description': 'A diode ladder low pass filter similar to the vintage Japanese designs',
        'category': 3,
         'controls': {'Q': ['Q', 1, 0.7072, 25],
                                   'cutoff': ['cutoff', 0.1, 0, 1]},
                      'inputs': {'cutoff_cv': ['Cutoff CV', 'CVPort'],
                                 'in': ['in', 'AudioPort'],
                                 'q_cv': ['Q CV', 'CVPort']},
                      'outputs': {'out': ['out', 'AudioPort']}},
 'k_org_hpf': {'description': 'A high pass filter similar to the vintage Japanese designs',
        'category': 3,
         'controls': {'Q': ['Q', 1, 0.5, 10],
                            'cutoff': ['cutoff', 0.5, 0, 1]},
               'inputs': {'cutoff_cv': ['Cutoff CV', 'CVPort'],
                          'in': ['in', 'AudioPort'],
                          'q_cv': ['Q CV', 'CVPort']},
               'outputs': {'out': ['out', 'AudioPort']}},
 'k_org_lpf': {'description': 'A low pass filter similar to the vintage Japanese designs',
        'category': 3,
               'controls': {'Q': ['Q', 1, 0.5, 10],
                            'cutoff': ['cutoff', 0.5, 0, 1]},
               'inputs': {'cutoff_cv': ['Cutoff CV', 'CVPort'],
                          'in': ['in', 'AudioPort'],
                          'q_cv': ['Q CV', 'CVPort']},
               'outputs': {'out': ['out', 'AudioPort']}},
 'oog_half_lpf': {'description': 'A low pass filter inspired by vintage American designs',
        'category': 3,
         'controls': {'Q': ['Q', 1, 0.7072, 25],
                               'cutoff': ['cutoff', 0.5, 0, 1]},
                  'inputs': {'cutoff_cv': ['Cutoff CV', 'CVPort'],
                             'in': ['in', 'AudioPort'],
                             'q_cv': ['Q CV', 'CVPort']},
                  'outputs': {'out': ['out', 'AudioPort']}},
 'oog_ladder_lpf': {'description': 'A low pass filter inspired by vintage American designs',
        'category': 3,
         'controls': {'Q': ['Q', 1, 0.7072, 25],
                                 'cutoff': ['cutoff', 0.5, 0, 1]},
                    'inputs': {'cutoff_cv': ['Cutoff CV', 'CVPort'],
                               'in': ['in', 'AudioPort'],
                               'q_cv': ['Q CV', 'CVPort']},
                    'outputs': {'out': ['out', 'AudioPort']}},
 'uberheim_filter': {'description': 'A multi out filter inspired by vintage American designs',
        'category': 3,
         'controls': {'Q': ['Q', 1, 0.5, 10],
                                  'cutoff': ['cutoff', 0.5, 0, 1]},
                     'inputs': {'cutoff_cv': ['Cutoff CV', 'CVPort'],
                                'in': ['in', 'AudioPort'],
                                'q_cv': ['Q CV', 'CVPort']},
                     'outputs': {'band_pass': ['Band Pass', 'AudioPort'],
                                 'band_stop': ['Band Stop', 'AudioPort'],
                                 'high_pass': ['High Pass', 'AudioPort'],
                                 'low_pass': ['Low Pass', 'AudioPort']}},
 'rotary_advanced': { 'description': 'A rotating loudspeaker using physical modelling. Same sound, more controls.',
         # "kill_dry": True,
        'category': 0,
        'controls': {'drumaccel': ['Drum Acceleration',
                                                4.127,
                                                0.01,
                                                20.0],
                                  'drumbrake': ['Drum Brake Position',
                                                0.0,
                                                0.0,
                                                1.0],
                                  'drumdecel': ['Drum Deceleration',
                                                1.371,
                                                0.01,
                                                20.0],
                                  'drumlvl': ['Drum Level', 0.0, -20.0, 20.0],
                                  'drumradius': ['Drum Radius',
                                                 22.0,
                                                 9.0,
                                                 50.0],
                                  'drumrpmfast': ['Drum Speed Fast',
                                                  357.3,
                                                  60.0,
                                                  600.0],
                                  'drumrpmslow': ['Drum Speed Slow',
                                                  36.0,
                                                  5.0,
                                                  100.0],
                                  'drumwidth': ['Drum Stereo Width',
                                                1.0,
                                                0.0,
                                                2.0],
                                  'enable': ['Enable', 1, 0, 1],
                                  'filtafreq': ['Frequency',
                                                4500.0,
                                                250.0,
                                                8000.0],
                                  'filtagain': ['Gain',
                                                -30.0,
                                                -48.0,
                                                48.0],
                                  'filtaq': ['Q',
                                             2.7456,
                                             0.01,
                                             6.0],
                                  'filtatype': ['Horn Filter-1 Type', 0, 0, 8],
                                  'filtbfreq': ['Frequency',
                                                300.0,
                                                250.0,
                                                8000.0],
                                  'filtbgain': ['Gain',
                                                -30.0,
                                                -48.0,
                                                48.0],
                                  'filtbq': ['Q',
                                             1.0,
                                             0.01,
                                             6.0],
                                  'filtbtype': ['Horn Filter-2 Type', 7, 0, 8],
                                  'filtdfreq': ['Frequency',
                                                811.9695,
                                                50.0,
                                                8000.0],
                                  'filtdgain': ['Gain',
                                                -38.9291,
                                                -48.0,
                                                48.0],
                                  'filtdq': ['Q',
                                             1.6016,
                                             0.01,
                                             6.0],
                                  'filtdtype': ['Drum Filter Type', 8, 0, 8],
                                  'hornaccel': ['Horn Acceleration',
                                                0.161,
                                                0.001,
                                                10.0],
                                  'hornbrakepos': ['Horn Brake Position',
                                                   0.0,
                                                   0.0,
                                                   1.0],
                                  'horndecel': ['Horn Deceleration',
                                                0.321,
                                                0.001,
                                                10.0],
                                  'hornleak': ['Horn Signal Leakage',
                                               -16.47,
                                               -80.0,
                                               -3.0],
                                  'hornlvl': ['Horn Level', 0.0, -20.0, 20.0],
                                  'hornradius': ['Horn Radius',
                                                 19.2,
                                                 9.0,
                                                 50.0],
                                  'hornrpmfast': ['Horn Speed Fast',
                                                  423.36,
                                                  100.0,
                                                  1000.0],
                                  'hornrpmslow': ['Horn Speed Slow',
                                                  40.32,
                                                  5.0,
                                                  200.0],
                                  'hornwidth': ['Horn Stereo Width',
                                                1.0,
                                                0.0,
                                                2.0],
                                  'hornxoff': ['Horn X-Axis Offset',
                                               0.0,
                                               -20.0,
                                               20.0],
                                  'hornzoff': ['Horn Z-Axis Offset',
                                               0.0,
                                               -20.0,
                                               20.0],
                                  'link': ['Link Speed Control', 0, -1, 1],
                                  'micangle': ['Microphone Angle',
                                               180.0,
                                               0.0,
                                               180.0],
                                  'micdist': ['Microphone Distance',
                                              42.0,
                                              9.0,
                                              150.0],
                                  'rt_speed': ['Motors Ac/Dc', 4, 0, 8]},
                     'inputs': {'in': ['Input', 'AudioPort'], 
                             'horn_speed_cv': ['Horn Speed', 'CVPort'],
                             'drum_speed_cv': ['Drum Speed', 'CVPort'],
                             'horn_brake_cv': ['Horn Brake', 'CVPort'],
                             'drum_brake_cv': ['Drum Brake', 'CVPort'],
                             },
                     'outputs': {
                             # 'drumang': ['Current Drum position',
                             #                 'ControlPort'],
                             #     'drumrpm': ['Current Drum speed',
                             #                 'ControlPort'],
                             #     'hornang': ['Current Horn position',
                             #                 'ControlPort'],
                             #     'hornrpm': ['Current Horn speed',
                             #                 'ControlPort'],
                                 'left': ['Left Output', 'AudioPort'],
                                 'right': ['Right Output', 'AudioPort']}},
     'midi_cc': {'description': 'MIDI CC to control value',
        'category': 1,
             'controls': {'controller_number': ['CC Number', 0, 0.0, 127.0, "int"],
                          'logarithmic': ['Logarithmic', 0.0, 0.0, 1.0, "bool"],
                          'maximum': ['Maximum',
                                              1.0,
                                              0.00,
                                              1.0],
                          'minimum': ['Minimum', 0, -1, 1],
                          },
             'inputs': {'input': ['MIDI Input', 'AtomPort']},
             'outputs': {'output_cv': ['Output', 'CVPort']}},
    'cv_to_midi_cc': {'description': 'convert control to MIDI CC', 
        'category': 1,
            'controls': {'CC_NUM': ['CC Number', 0, 0, 127, "int"],
                           'CHAN': ['Channel', 1, 1, 16, "int"],
                           'RESOLUTION': ['resolution', 0.01, 0.00001, 1]},
              'inputs': {'CV_IN': ['CV In', 'CVPort']},
              'outputs': {'MIDI_OUT': ['MIDI Out', 'AtomPort']}},
        # "midi_note": "http://drobilla.net/ns/ingen-internals#Note",
        # "midi_trigger": "http://drobilla.net/ns/ingen-internals#Trigger",
     'midi_clock_in': {'description': 'MIDI Clock to BPM',
        'category': 1,
             'controls': {},
                   'inputs': {'control': ['MIDI Input', 'AtomPort']},
                   'outputs': {'bpm': ['BPM', 'ControlPort']}},
     'midi_clock_out': {'description': 'BPM to MIDI Clock',
        'category': 1,
             'controls': {'bpm': ['BPM', 120.0, 40.0, 208.0]},
                    'inputs': { 'bpm': ['BPM', 'ControlPort'] },
                    'outputs': {'mclk': ['Midi Out', 'AtomPort']}},
    'vca': {'description': 'simple voltage controlled amplifier',
        'category': 2,
            'controls': {'gain': ['Gain', 1.0, 0.0, 1.0]},
         'inputs': {'gain': ['Gain', 'CVPort'], 'in': ['Input', 'AudioPort']},
         'outputs': {'out': ['Output', 'AudioPort']}},
        # "product" : "http://polyeffects.com/lv2/basic_modular#product",
        # "ratio" : "http://polyeffects.com/lv2/basic_modular#ratio",
    'difference': {'description': 'a - b for control signals', 
        'category': 2,
            'controls': {'a': ['a', 0, 0, 1], 'b': ['b', 0, 0, 1]},
                'inputs': {'a_cv': ['A CV', 'CVPort'],
                           'b_cv': ['B CV', 'CVPort']},
                'outputs': {'out': ['Output', 'CVPort']}},
    'rectify_value': {'description': 'rectify or get the absolute value of the input. ', 
        'category': 2,
            'controls': {},
                'inputs': {'a_cv': ['A CV', 'CVPort']},
                'outputs': {'out': ['Output', 'CVPort']}},
    'max': {'description': 'max of a, b also logical or', 'controls': {'a': ['a', 0, 0, 1], 'b': ['b', 0, 0, 1]},
        'category': 2,
                'inputs': {'a_cv': ['A CV', 'CVPort'],
                           'b_cv': ['B CV', 'CVPort']},
                'outputs': {'out': ['Output', 'CVPort']}},
    'min': {'description': 'min of a, b also logical and', 'controls': {'a': ['a', 0, 0, 1], 'b': ['b', 0, 0, 1]},
        'category': 2,
                'inputs': {'a_cv': ['A CV', 'CVPort'],
                           'b_cv': ['B CV', 'CVPort']},
                'outputs': {'out': ['Output', 'CVPort']}},
    'sum': {'description': 'a + b for control signals', 'controls': {'a': ['a', 0, 0, 1], 'b': ['b', 0, 0, 1]},
        'category': 2,
                'inputs': {'a_cv': ['A CV', 'CVPort'],
                           'b_cv': ['B CV', 'CVPort']},
                'outputs': {'out': ['Output', 'CVPort']}},
    'product': {'description': 'a times b for control signals', 'controls': {'a': ['a', 0, 0, 1], 'b': ['b', 0, 0, 1]},
        'category': 2,
                'inputs': {'a_cv': ['A CV', 'CVPort'],
                           'b_cv': ['B CV', 'CVPort']},
                'outputs': {'out': ['Output', 'CVPort']}},
    'ratio': {'description': 'a divided by b for control signals', 'controls': {'a': ['a', 0, 0, 1], 'b': ['b', 0, 0, 1]},
        'category': 2,
                'inputs': {'a_cv': ['A CV', 'CVPort'],
                           'b_cv': ['B CV', 'CVPort']},
                'outputs': {'out': ['Output', 'CVPort']}},
    'macro_osc': {'description': 'a powerful multi model oscillator voice',
        'category': 3,
            'controls': {'freq_mod': ['Frequency Mod', 0.0, -1.0, 1.0],
                            'frequency': ['frequency', 0.0, -4.0, 4.0],
                            'harmonics': ['harmonics', 0.5, 0.0, 1.0],
                            'lpg_color': ['LPG Color', 0.5, 0.0, 1.0],
                            'lpg_decay': ['LPG Decay', 0.5, 0.0, 1.0],
                            'model': ['model', 0, 0.0, 16.0],
                            'morph': ['morph', 0.5, 0.0, 1.0],
                            'morph_mod': ['Morph Mod', 0.0, -1.0, 1.0],
                            'timbre': ['timbre', 0.5, 0.0, 1.0],
                            'timbre_mod': ['Timbre Mod', 0.0, -1.0, 1.0]},
               'inputs': {'engine_cv': ['engine cv', 'CVPort'],
                          'freq_cv': ['frequency cv', 'CVPort'],
                          'harmonics_cv': ['harmonics cv', 'CVPort'],
                          'level_cv': ['level cv', 'CVPort'],
                          'morph_cv': ['morph cv', 'CVPort'],
                          'note_cv': ['V per oct CV', 'CVPort'],
                          'timbre_cv': ['timbre cv', 'CVPort'],
                          'trigger_cv': ['trigger cv', 'CVPort']},
               'outputs': {'aux': ['aux', 'AudioPort'],
                           'out': ['out', 'AudioPort']}},
    'midi_note_to_cv': {'description': 'convert MIDI notes to v per octave pitch CVs',
        'category': 1,
            'controls': {'Cent': ['Cent', 0, -100, 100, "int"],
                                  'Octave': ['Octave', 0, -3, 3, "int"],
                                  'Panic': ['Panic', 0, 0, 1, "bool"],
                                  'Retrigger': ['Retrigger', 0.0, 0.0, 1.0, "bool"],
                                  'Semitone': ['Semitone', 0, -12, 12, "int"],
                                  'channel': ['Channel', 1, 1, 16, "int"]},
                     'inputs': {'in': ['MIDI Input', 'AtomPort']},
                     'outputs': {'Gate': ['Gate', 'CVPort'],
                                 'Pitch': ['Pitch', 'CVPort'],
                                 'Velocity': ['Velocity', 'CVPort']}},
'capo': {'controls': {'Fidelity': ['Fidelity', 1, 0, 2],
                       'Gain': ['Gain', 3.0, -20.0, 20.0],
                       'Step': ['Step', 0, 0, 12]},
          'inputs': {'In': ['In', 'AudioPort']},
          'outputs': {'Out': ['Out', 'AudioPort']}},
 'drop': {'controls': {'Fidelity': ['Fidelity', 1, 0, 2],
                       'Gain': ['Gain', 3.0, -20.0, 20.0],
                       'Step': ['Step', 0, -12, 0]},
          'inputs': {'In': ['In', 'AudioPort']},
          'outputs': {'Out': ['Out', 'AudioPort']}},
 'extra_capo': {'controls': {'Fidelity': ['Fidelity', 1, 0, 2],
                             'Gain': ['Gain', 3.0, -20.0, 20.0],
                             'Step': ['Step', 0, 0, 24]},
                'inputs': {'In': ['In', 'AudioPort']},
                'outputs': {'Out': ['Out', 'AudioPort']}},
 'harmony': {'controls': {'Fidelity': ['Fidelity', 1, 0, 2],
                          'Gain1': ['Gain 1', 0.0, -20.0, 20.0],
                          'Gain2': ['Gain 2', 3.0, -20.0, 20.0],
                          'Interval': ['Interval', 0, 0, 9],
                          'LowestNoteToChangeThePitch': ['Lowest note to change the pitch',
                                                         0,
                                                         0,
                                                         14],
                          'Mode': ['Mode', 0, 0, 2],
                          'Scale': ['Scale', 0, 0, 2],
                          'Tone': ['Tone', 0, 0, 11]},
             'inputs': {'In': ['In', 'AudioPort']},
             'outputs': {'Out1': ['Out 1', 'AudioPort'],
                         'Out2': ['Out 2', 'AudioPort']}},
 'harmony2': {'controls': {'Fidelity': ['Fidelity', 1, 0, 2],
                           'Gain1': ['Gain 1', 3.0, -20.0, 20.0],
                           'Gain2': ['Gain 2', 3.0, -20.0, 20.0],
                           'Gain_clean': ['Clean Gain', 0.0, -20.0, 20.0],
                           'Interval_1': ['Interval 1', 0, 0, 11],
                           'Interval_2': ['Interval 2', 2, 0, 11],
                           'LowestNoteToChangeThePitch': ['Lowest note to change the pitch',
                                                          0,
                                                          0,
                                                          14],
                           'Mode': ['Mode', 0, 0, 2],
                           'Scale': ['Scale', 0, 0, 2],
                           'Tone': ['Tone', 0, 0, 11]},
              'inputs': {'In': ['In', 'AudioPort']},
              'outputs': {'Out1': ['Out 1', 'AudioPort'],
                          'Out2': ['Out 2', 'AudioPort'],
                          'Out_clean': ['Clean Output', 'AudioPort']}},
 'harmony_custom': {'controls': {'Fidelity': ['Fidelity', 1, 0, 2],
                                 'Gain1': ['Gain 1', 0.0, -20.0, 20.0],
                                 'Gain2': ['Gain 2', 3.0, -20.0, 20.0],
                                 'LowestNoteToChangeThePitch': ['Lowest note to change the pitch',
                                                                0,
                                                                0,
                                                                14],
                                 'Step_0': ['Tonic', 0, -12, 12],
                                 'Step_1': ['Minor 2nd', 0, -12, 12],
                                 'Step_10': ['Minor 7th', 0, -12, 12],
                                 'Step_11': ['Major 7th', 0, -12, 12],
                                 'Step_2': ['Major 2nd', 0, -12, 12],
                                 'Step_3': ['Minor 3rd', 0, -12, 12],
                                 'Step_4': ['Major 3rd', 0, -12, 12],
                                 'Step_5': ['Perfect 4th', 0, -12, 12],
                                 'Step_6': ['Diminished 5th', 0, -12, 12],
                                 'Step_7': ['Perfect 5th', 0, -12, 12],
                                 'Step_8': ['Minor 6th', 0, -12, 12],
                                 'Step_9': ['Major 6th', 0, -12, 12],
                                 'Tone': ['Tone', 0, 0, 11]},
                    'inputs': {'In': ['In', 'AudioPort']},
                    'outputs': {'Out1': ['Out 1', 'AudioPort'],
                                'Out2': ['Out 2', 'AudioPort']}},
 'pitch_wam': {'controls': {'Clean': ['Clean', 0, 0, 1],
                            'Fidelity': ['Fidelity', 1, 0, 3],
                            'First': ['First', 0, -12, 24],
                            'Gain': ['Gain', 3.0, -20.0, 20.0],
                            'Last': ['Last', 12, -12, 24],
                            'Step': ['Step', 0.0, 0.0, 1.0]},
               'inputs': {'In': ['In', 'AudioPort']},
               'outputs': {'Out': ['Out', 'AudioPort']}},
 'two_voice': {'controls': {'Fidelity': ['Fidelity', 1, 0, 3],
                            'Gain_1': ['Gain 1', 3.0, -20.0, 20.0],
                            'Gain_2': ['Gain 2', 3.0, -20.0, 20.0],
                            'Step1': ['Step 1', 0, -12, 24],
                            'Step2': ['Step 2', 0, -12, 24]},
               'inputs': {'In': ['In', 'AudioPort']},
               'outputs': {'Out1': ['Out 1', 'AudioPort'],
                           'Out2': ['Out 2', 'AudioPort']}},
'onset_detect': {
        'description': 'detects when a note starts and sends a trigger',
        'category': 2,
    'controls': { 'onset_threshold': ['Onset Threshold',
                                                   0.3,
                                                   0.1,
                                                   1.0],
                               'silence_threshold': ['Silence Threshold',
                                                     -90.0,
                                                     -90.0,
                                                     -10.0]},
                  'inputs': {'in': ['In', 'AudioPort']},
                  'outputs': {"gate": ["Gate", "CVPort"]}},
'pitch_detect': {
        'description': 'BETA detects played notes and converts it volt per octave and MIDI',
        'category': 2,
        'controls': { 'onset_threshold': ['Onset Threshold',
                                                   0.3,
                                                   0.1,
                                                   1.0],
                               'pitch_threshold': ['Pitch Detection Tolerance',
                                                   0.3,
                                                   0.1,
                                                   0.7],
                               'silence_threshold': ['Silence Threshold',
                                                     -90.0,
                                                     -90.0,
                                                     -10.0]},
                  'inputs': {'in': ['In', 'AudioPort']},
                  'outputs': {'midi_out': ['Midi Out', 'AtomPort'],
                            "gate": ["Gate", "CVPort"],
                            "voct": ["V/Oct Pitch", "CVPort"],
                            }},
'pitch_corrector': {'controls': {'bias': ['Bias', 0.5, 0.0, 1.0],
                                  'channelf': ['Filter Channel', 0, 0, 16],
                                  'corr': ['Correction', 1.0, 0.0, 1.0],
                                  'filter': ['Filter', 0.1, 0.02, 0.5],
                                  'm00': ['C', 1, 0, 1],
                                  'm01': ['C#', 1, 0, 1],
                                  'm02': ['D', 1, 0, 1],
                                  'm03': ['D#', 1, 0, 1],
                                  'm04': ['E', 1, 0, 1],
                                  'm05': ['F', 1, 0, 1],
                                  'm06': ['F#', 1, 0, 1],
                                  'm07': ['G', 1, 0, 1],
                                  'm08': ['G#', 1, 0, 1],
                                  'm09': ['A', 1, 0, 1],
                                  'm10': ['A#', 1, 0, 1],
                                  'm11': ['B', 1, 0, 1],
                                  'mode': ['Mode', 0, 0, 2],
                                  'offset': ['Offset', 0.0, -2.0, 2.0],
                                  'panic': ['MIDI Panic', 0, 0, 1],
                                  'tuning': ['Tuning', 440.0, 400.0, 480.0]},
                     'inputs': {'in': ['Input', 'AudioPort']},
                     'outputs': {'error': ['Pitch Error', 'ControlPort'],
                                 'latency': ['latency', 'ControlPort'],
                                 'nmask': ['Note Mask', 'ControlPort'],
                                 'nset': ['Note Set', 'ControlPort'],
                                 'out': ['Output', 'AudioPort']}},
'octaver': {'controls': {'DIRECT': ['DIRECT', 0.5, 0.0, 1.0],
                          'OCTAVE1': ['OCTAVE1', 0.5, 0.0, 1.0],
                          'OCTAVE2': ['OCTAVE2', 0.5, 0.0, 1.0]},
             'inputs': {'in': ['In', 'AudioPort']},
             'outputs': {'out': ['Out', 'AudioPort']}},
'vinyl': {'controls': {'active0': ['Activate Hum', 0, 0, 1], # hum motor static noise rumble crackle crinkle
                        'active1': ['Activate Motor', 0, 0, 1],
                        'active2': ['Activate Static', 0, 0, 1],
                        'active3': ['Activate Noise', 0, 0, 1],
                        'active4': ['Activate Rumble', 0, 0, 1],
                        'active5': ['Activate Crackle', 0, 0, 1],
                        'active6': ['Activate Crinkle', 0, 0, 1],
                        'aging': ['Aging', 0, 0, 1],
                        'drone': ['Drone', 0, 0, 1],
                        'freq': ['Frequency', 1000, 600, 1800],
                        # 'gain0': ['Vol Hum', 0.0078125, 1.5849e-05, 1],
                        # 'gain1': ['Vol Motor', 0.0078125, 1.5849e-05, 1],
                        # 'gain2': ['Vol Static', 0.015625, 1.5849e-05, 1],
                        # 'gain3': ['Vol Noise', 0.0078125, 1.5849e-05, 1],
                        # 'gain4': ['Vol Rumble', 0.03125, 1.5849e-05, 1],
                        # 'gain5': ['Vol Crackle', 0.0625, 1.5849e-05, 1],
                        # 'gain6': ['Vol Crinkle', 0.0625, 1.5849e-05, 1],
                        'level_in': ['Input Gain', 1, 0.015625, 64],
                        'level_out': ['Output Gain', 1, 0.015625, 64],
                        # 'pitch0': ['Pitch Hum', 0, -1, 1],
                        # 'pitch1': ['Pitch Motor', 0, -1, 1],
                        # 'pitch2': ['Pitch Static', 0, -1, 1],
                        # 'pitch3': ['Pitch Noise', 0, -1, 1],
                        # 'pitch4': ['Pitch Rumble', 0, -1, 1],
                        # 'pitch5': ['Pitch Crackle', 0, -1, 1],
                        # 'pitch6': ['Pitch Crinkle', 0, -1, 1],
                        'speed': ['Speed', 33, 33, 78]},
           'inputs': {'in_l': ['In L', 'AudioPort'],
                      'in_r': ['In R', 'AudioPort']},
           'outputs': {'out_l': ['Out L', 'AudioPort'],
                       'out_r': ['Out R', 'AudioPort']}},
'pitch_shift': {'description': 'a basic pitch shifter. It delays the input signal',
        'category': 3,
            'controls': {'Drylevel': ['Dry Level', -90, -90, 20],
                              # 'Latency': ['latency', 0, 0, 16027],
                              # 'Rate': ['Rate Shift [%]', 0, -50, 100],
                              'Semitone': ['Semitone Shift', 0, -12, 12, "int"],
                              'Wetlevel': ['Wet Level', 0, -90, 20]},
                 'inputs': {'Input': ['Input', 'AudioPort']},
                 'outputs': {'Output': ['Output', 'AudioPort']}},
'adsr': {'description': 'Basic ADSR envelope generator. Takes in a gate.',
        'category': 2,
        'controls': {'attack': ['Attack Time', 0, 0, 1.0],
                       'decay': ['Decay Time', 0, 0, 1.0],
                       'release': ['Release Time', 0, 0, 1.0],
                       'sustain': ['Sustain Level', 1, 0, 1],
                       'thresh': ['Trigger Threshold', 0.5, 0.0, 1.0]},
          'inputs': {'drive': ['Driving Signal', 'CVPort']},
          'outputs': {'out': ['Envelope Out', 'CVPort']}},
'dahdsr': {'controls': { 'attack': ['Attack Time', 0, 0, 1.0],
                         'decay': ['Decay Time', 0, 0, 1.0],
                         'delay': ['Delay Time', 0, 0, 1.0],
                         'hold': ['Hold Time', 0, 0, 1.0],
                         'release': ['Release Time', 0, 0, 1.0],
                         'sustain': ['Sustain Level', 1, 0, 1]},
            'description': 'A delay attack hold decay sustain release envelope generator',
        'category': 2,
            'inputs': {'gate': ['Gate', 'CVPort'],
                       'trigger': ['Trigger', 'CVPort'],
                       'attack': ['Attack Time', 'CVPort'],
                       'decay': ['Decay Time', 'CVPort'],
                       'delay': ['Delay Time', 'CVPort'],
                       'hold': ['Hold Time', 'CVPort'],
                       'release': ['Release Time', 'CVPort'],
                       'sustain': ['Sustain Level', 'CVPort'],
                       },
            'outputs': {'out': ['Envelope Out', 'CVPort']}},
 'sample_hold': {'controls': {'triggerlevel': ['Trigger Level', 0.5, 0, 10]},
                 'description': 'sample and hold a CV value when a trigger goes high',
        'category': 2,
                 'inputs': {'input': ['Input', 'CVPort'],
                            'trigger': ['Trigger', 'CVPort']},
                 'outputs': {'gate': ['Gate', 'CVPort'],
                             'output': ['Output', 'CVPort']}},
 'drum_patterns': {'controls': {'bd_dens': ['bass drum density', 0.5, 0.0, 1.0],
                                'chaos': ['chaos', 0.0, 0.0, 1.0],
                                'hh_dens': ['hihat density', 0.5, 0.0, 1.0],
                                'mapx': ['Map x', 0.0, 0.0, 1.0],
                                'mapy': ['map y', 0.5, 0.0, 1.0],
                                'reset_button': ['reset button', 0, 0.0, 1.0, "bool"],
                                'run_button': ['run button', 0.0, 0.0, 1.0, "bool"],
                                'sn_dens': ['snare density', 0.5, 0.0, 1.0],
                                'swing': ['swing', 0.0, 0.0, 0.9],
                                'tempo': ['tempo', 120.0, 37.0, 240.0]},
                   'description': 'drum trigger explorer',
        'category': 2,
                   'inputs': {'bd_fill_cv': ['bd_fill_cv', 'CVPort'],
                              'chaos_cv': ['chaos cv', 'CVPort'],
                              'clock': ['clock', 'CVPort'],
                              'hh_fill_cv': ['hh fill cv', 'CVPort'],
                              'mapx_cv': ['map x cv', 'CVPort'],
                              'mapy_cv': ['map y cv', 'CVPort'],
                              'reset': ['reset', 'CVPort'],
                              'run_input': ['run', 'CVPort'],
                              'sn_fill_cv': ['sn fill cv', 'CVPort'],
                              'swing_cv': ['swing cv', 'CVPort'],
                              'tempo': ['BPM', 'ControlPort'],
                              },
                   'outputs': {'bd_acc_output': ['bass drum accent',
                                                 'CVPort'],
                               'bd_output': ['bass drum trigger', 'CVPort'],
                               'hh_acc_output': ['hihat accent', 'CVPort'],
                               'hh_output': ['hihat trigger', 'CVPort'],
                               'sn_acc_output': ['snare accent', 'CVPort'],
                               'sn_output': ['snare trigger', 'CVPort']}},
        'wet_dry': {'controls': {'level': ['level', 1.0, 0.0, 1.0],
                          #'mode': ['Mode', 0, 0, 1],
                          'shape': ['Shape', 0.0, 0.0, 1.0],
                          'xfade': ['Wet Dry', 0.0, -1.0, 1.0]},
             'description': 'blend between two inputs',
             'category': 0,
             'inputs': {'dry': ['Dry', 'AudioPort'],
                        'wet': ['Wet', 'AudioPort'],
                        'xfade': ['Wet Dry Blend', 'CVPort'],
                        'level': ['Level', 'CVPort'],
                        },
             'outputs': {'out': ['Out', 'AudioPort']}},
        'wet_dry_stereo': {'controls': {'level': ['level', 1.0, 0.0, 1.0],
                                 #'mode': ['Mode', 0, 0, 1],
                                 'shape': ['Shape', 0.0, 0.0, 1.0],
                                 'xfade': ['signal a/b', 0.0, -1.0, 1.0]},
                    'description': 'blend stereo inputs to stereo out',
                    'category': 0,
                    'inputs': {'dry_l': ['Dry L', 'AudioPort'],
                               'dry_r': ['Dry R', 'AudioPort'],
                               'wet_l': ['Wet L', 'AudioPort'],
                               'wet_r': ['Wet R', 'AudioPort'],
                               'xfade': ['Wet Dry Blend', 'CVPort'],
                               'level': ['Level', 'CVPort'],
                               },
                    'outputs': {'out_l': ['Out L', 'AudioPort'],
                                'out_r': ['Out R', 'AudioPort']}},
        'ad_env_level': {'controls': {'attack': ['Attack Time', 0.5, 0, 5],
                                       'attack_level': ['Attack to Level', 1, 0, 1],
                                       'decay': ['Decay Time', 0.5, 0, 5],
                                       'decay_level': ['Decay to Level', 0, 0, 1],
                                       'init_level': ['Initial Level', 0, 0, 1]},
                          'description': 'A attack decay envelope generator with start and end levels. Works with a trigger.',
                          'category': 2,
                          'inputs': {'gate': ['Gate', 'CVPort'],
                                     'reset_level': ['Reset Level', 'CVPort'],
                                     'trigger': ['Trigger', 'CVPort']},
                          'outputs': {'out': ['Envelope Out', 'CVPort']}},
         'ad_envelope': {'controls': {'attack': ['Attack Time', 0.5, 0, 5],
                                      'decay': ['Decay Time', 0.5, 0, 5]},
                          'description': 'A attack decay envelope generator. Works with a trigger.',
                          'category': 2,
                         'inputs': {'port0': ['Gate', 'CVPort'],
                                    'trigger': ['Trigger', 'CVPort']},
                         'outputs': {'out': ['Envelope Out', 'CVPort']}},
    'poly_note_to_cv': {'controls': {'Cent': ['Cent', 0, -100, 100, "int"],
                                      'Octave': ['Octave', 0, -4, 4, "int"],
                                      'Panic': ['Panic', 0, 0, 1, "bool"],
                                      'Semitone': ['Semitone', 0, -12, 12, "int"],
                                      'channel': ['Channel', 1, 1, 16, "int"]},
        'description': 'convert poly MIDI notes to v per octave pitch CVs',
            'category': 1,
                         'inputs': {'MIDIIn': ['MIDI Input', 'AtomPort']},
                         'outputs': {'Gate1': ['Gate 1', 'CVPort'],
                                     'Gate2': ['Gate 2', 'CVPort'],
                                     'Gate3': ['Gate 3', 'CVPort'],
                                     'Gate4': ['Gate 4', 'CVPort'],
                                     'Pitch1': ['Pitch 1', 'CVPort'],
                                     'Pitch2': ['Pitch 2', 'CVPort'],
                                     'Pitch3': ['Pitch 3', 'CVPort'],
                                     'Pitch4': ['Pitch 4', 'CVPort'],
                                     'vel': ['Velocity', 'CVPort']}},

    'beat_repeat': {'controls': {'blend_param': ['Slice Probability',
                                                  0.78,
                                                  0.0,
                                                  1.0],
                                  'density_param': ['Size Mod', 0.27, 0.0, 1.0],
                                  'feedback_param': ['Pitch Mod', 0.55, 0.0, 1.0],
                                  'freeze_param': ['freeze', 0.0, 0.0, 1.0],
                                  'in_gain_param': ['Gain', 0.5, 0.0, 1.0],
                                  'pitch_param': ['Pitch', 0.1, -48.0, 48.0],
                                  'position_param': ['Loop Start', 0.24, 0.0, 1.0],
                                  'reverb_param': ['Feedback', 0.6, 0.0, 1.0],
                                  'reverse_param': ['reverse', 0.0, 0.0, 1.0],
                                  'size_param': ['Loop Size', 0.69, 0.0, 1.0],
                                  'spread_param': ['Clock Divider', 0.7, 0.0, 1.0],
                                  'texture_param': ['Slice Step', 0.73, 0.0, 1.0]},
                     'description': 'A modular beat slicer, needs clock in trigger input',
                     'category': 3,
                     'inputs': {'Feedback': ['Pitch Mod', 'CVPort'],
                                'blend': ['Slice Probability', 'CVPort'],
                                'density': ['Size Mod', 'CVPort'],
                                'freeze': ['Freeze', 'CVPort'],
                                'l_in': ['L in', 'AudioPort'],
                                'pitch': ['Pitch', 'CVPort'],
                                'position': ['Loop Start', 'CVPort'],
                                'r_in': ['R in', 'AudioPort'],
                                'reverb': ['Feedback', 'CVPort'],
                                'reverse': ['Reverse', 'CVPort'],
                                'size': ['Loop Size', 'CVPort'],
                                'spread': ['Clock Divider', 'CVPort'],
                                'texture': ['Slice Select', 'CVPort'],
                                'trig': ['Trigger', 'CVPort']},
                     'outputs': {'l_out': ['L Out', 'AudioPort'],
                                 'r_out': ['R Out', 'AudioPort']}},
    'tempo_ratio': {'controls': {'a': ['a', 1, 1, 16, "int"],
                                  'b': ['b', 1, 1, 16, "int"]}, #,
                                  #'input_tempo': ['Input Tempo', 120, 30, 300]},
                     'category': 2,
                     'description': 'ratio between a tempo, like 3/4 to input tempo',
                     'inputs': {
                        'input_tempo': ['Input Tempo', 'ControlPort'],
                         },
                     'outputs': {'out_tempo': ['Output Tempo', 'ControlPort']}},
    'toggle': {'controls': {},
                'description': 'toggles the output value on every trigger',
                'category': 2,
                'inputs': {'trigger': ['Trigger', 'CVPort']},
                'outputs': {'out': ['Out Gate', 'CVPort']}},
    'phaser_ext': {'controls': {'color': ['Color', 1, 0, 1, "bool"],
                             'feedback_depth': ['Feedback depth', 75, 0, 99],
                             'feedback_hpf_cutoff': ['Feedback bass cut',
                                                     500.0,
                                                     10.0,
                                                     5000.0],
                             #'lv2_enabled': ['Enabled', 1, 0, 1],
                             'mix': ['Dry/wet mix', 50, 0, 100]},
                'description': 'Mono phaser controlled by CV input',
                'category': 0,
                'inputs': {'lv2_audio_in_1': ['Audio Input 1', 'AudioPort'],
                           'lv2_audio_in_2': ['LFO CV', 'CVPort']},
                'outputs': {'lv2_audio_out_1': ['Audio Output 1',
                                                'AudioPort']}},
    'phaser_stereo_ext': {'controls': {'color': ['Color', 1, 0, 1],
                                    'feedback_depth': ['Feedback depth',
                                                       75,
                                                       0,
                                                       99],
                                    'feedback_hpf_cutoff': ['Feedback bass cut',
                                                            500.0,
                                                            10.0,
                                                            5000.0],
                                    #'lv2_enabled': ['Enabled', 1, 0, 1],
                                    'mix': ['Dry/wet mix', 50, 0, 100],
                                    'stereo_phase': ['Stereo phase',
                                                     0,
                                                     -180,
                                                     180]},
                        'description': 'Stereo phaser controlled by CV input',
                        'category': 0,
                       'inputs': {'lv2_audio_in_1': ['Audio Input 1',
                                                     'AudioPort'],
                                  'lv2_audio_in_2': ['Audio Input 2',
                                                     'AudioPort'],
                                  'lv2_audio_in_3': ['LFO CV', 'CVPort']},
                       'outputs': {'lv2_audio_out_1': ['Audio Output 1',
                                                       'AudioPort'],
                                   'lv2_audio_out_2': ['Audio Output 2',
                                                       'AudioPort']}}, 
    'harmonic_tremolo': {'controls': {'BPM_0': ['BPM', 120, 15, 300],
                                   'CrossoverFreq_1': ['Crossover Freq',
                                                       800,
                                                       20,
                                                       10000],
                                   'depth_2': ['Depth', 0.1, 0, 1]},
                      'description': 'harmonic tremolo with internal LFO',
                      'category': 0,
                      'inputs': {'in0': ['in', 'AudioPort'],
                              'BPM_0': ['BPM', 'ControlPort'],
                          },
                      'outputs': {'out0': ['out', 'AudioPort']}},
    'harmonic_trem_ext': {'controls': {'CrossoverFreq_0': ['CrossoverFreq',
                                                        800,
                                                        20,
                                                        10000],
                                    'depth_1': ['depth', 0.1, 0, 1]},
                       'description': 'harmonic tremolo CV LFO input',
                       'category': 0,
                       'inputs': {'in0': ['in', 'AudioPort'],
                                  'lfo_in1': ['LFO CV', 'CVPort']},
                       'outputs': {'out0': ['out', 'AudioPort']}},
    'chorus_d': {'controls': {'BPM_1': ['BPM', 30, 10.01, 420],
                               'Delay_0': ['Delay', 0.5, 0, 1],
                               'Depth_3': ['Depth', 0.5, 0, 1],
                               'Deviation_4': ['Deviation', 0.5, 0, 1],
                               # 'Enable_2': ['Enable', 0, 0, 1],
                               },
                  'description': '8 voice multi dimensional chorus',
                  'category': 0,
                  'inputs': {'in0': ['in', 'AudioPort'],
                             'BPM_1': ['BPM', 'ControlPort'],
                      },
                  'outputs': {'out0': ['out L', 'AudioPort'],
                              'out1': ['out R', 'AudioPort']}},
    'chorus_d_ext': {'controls': {'Delay_0': ['Delay', 0.5, 0, 1],
                                   'Depth_1': ['Depth', 0.5, 0, 1],
                                   'Deviation_2': ['Deviation', 0.5, 0, 1]},
                      'description': '8 voice multi dimensional chorus CV LFO',
                      'category': 0,
                      'inputs': {'in0': ['in', 'AudioPort'],
                                 'in1': ['LFO CV', 'CVPort']},
                      'outputs': {'out0': ['out L', 'AudioPort'],
                                  'out1': ['out R', 'AudioPort']}},
    'flanger': {'category': 0,
                 'controls': {'BPM_1': ['BPM', 30, 5, 300],
                              'Delay_0': ['Delay', 0.22, 0, 1],
                              'Depth_2': ['Depth', 0.75, 0, 1],
                              'Feedback_4': ['Feedback', 0, -0.995, 0.99],
                              'Invert_3': ['Invert', 0, 0, 1, "bool"],
                              'Waveshape_5': ['Waveshape', 0, 0, 1]},
                 'description': 'flanger with internal LFO',
                 'inputs': {'in0': ['in', 'AudioPort'],
                            'BPM_1': ['BPM', 'ControlPort'],
                     },
                 'outputs': {'out0': ['out0', 'AudioPort']}},
     'flanger_ext': {'category': 0,
                     'controls': {'Delay_0': ['Delay', 0.22, 0, 1],
                                  'Depth_1': ['Depth', 0.75, 0, 1],
                                  'Feedback_3': ['Feedback', 0, -0.995, 0.99],
                                  'Invert_2': ['Invert', 0, 0, 1, "bool"]},
                     'description': 'flanger with CV for LFO',
                     'inputs': {'in1': ['in', 'AudioPort'],
                                'lfo_cv': ['LFO CV', 'CVPort']},
                     'outputs': {'out0': ['out0', 'AudioPort']}},
    'vibrato': {'category': 0,
                 'controls': {'BPM_9': ['BPM', 30, 4, 300],
                              'Feedback_Gain_3': ['Feedback Gain',
                                                  0,
                                                  -0.999,
                                                  0.999],
                              'Invert_Internal_Phaser_Sum_0': ['Invert',
                                                               0.0,
                                                               0.0,
                                                               1.0, "bool"],
                              'Max_Notch1_Freq_7': ['Max Notch1 Freq',
                                                    800,
                                                    20,
                                                    10000],
                              'Min_Notch1_Freq_6': ['Min Notch1 Freq',
                                                    100,
                                                    20,
                                                    5000],
                              'Notch_Depth__Intensity__2': ['Notch Depth', 1, 0, 1],
                              'Notch_Freq_Ratio_8': ['Notch Freq Ratio',
                                                     1.5,
                                                     1.1,
                                                     4],
                              'Notch_width_5': ['Notch width', 1000, 10, 5000],
                              'Phase_4': ['Phase', 0, 0, 1],
                              'Vibrato_Mode_1': ['Vibrato Mode', 1.0, 0.0, 1.0, "bool"]},
                 'description': 'vibrato with internal LFO',
                 'inputs': {'in0': ['in', 'AudioPort'], 
                            'BPM_9': ['BPM', 'ControlPort'],
                     },
                 'outputs': {'out0': ['out', 'AudioPort']}},
     'vibrato_ext': {'category': 0,
                     'controls': {'Feedback_Gain_3': ['Feedback Gain',
                                                      0,
                                                      -0.999,
                                                      0.999],
                                  'Invert_Internal_Phaser_Sum_0': ['Invert',
                                                                   0.0,
                                                                   0.0,
                                                                   1.0, "bool"],
                                  'Max_Notch1_Freq_6': ['Max Notch1 Freq',
                                                        800,
                                                        20,
                                                        10000],
                                  'Min_Notch1_Freq_5': ['Min Notch1 Freq',
                                                        100,
                                                        20,
                                                        5000],
                                  'Notch_Depth__Intensity__2': ['Notch Depth',
                                                                1,
                                                                0,
                                                                1],
                                  'Notch_Freq_Ratio_7': ['Notch Freq Ratio',
                                                         1.5,
                                                         1.1,
                                                         4],
                                  'Notch_width_4': ['Notch width', 1000, 10, 5000],
                                  'Vibrato_Mode_1': ['Vibrato Mode',
                                                     0.0,
                                                     0.0,
                                                     1.0, "bool"]},
                     'description': 'vibrato with CV LFO',
                     'inputs': {'in1': ['in', 'AudioPort'],
                                'lfo_cv': ['LFO CV', 'CVPort']},
                     'outputs': {'out0': ['out', 'AudioPort']}},
    'step_sequencer': {'category': 2,
                    'controls': {'bpm': ['BPM', 120, 20, 320],
                                 'glide': ['Glide', 0.5, 0.0, 1.0],
                                 'note_length': ['Note Length',
                                                 0.125,
                                                 0.03125,
                                                 1],
                                 'steps': ['Loop Steps', 16, 1, 16],
                                 'play': ['play', 0.0, 0.0, 1.0],
                                 'back_gate': ['back', 0.0, 0.0, 1.0],
                                 'val0': ['Value 0', 0.5, 0.0, 1.0],
                                 'val0': ['Value 0', 0.5, 0.0, 1.0],
                                 'val1': ['Value 1', 0.5, 0.0, 1.0],
                                 'val2': ['Value 2', 0.5, 0.0, 1.0],
                                 'val3': ['Value 3', 0.5, 0.0, 1.0],
                                 'val4': ['Value 4', 0.5, 0.0, 1.0],
                                 'val5': ['Value 5', 0.5, 0.0, 1.0],
                                 'val6': ['Value 6', 0.5, 0.0, 1.0],
                                 'val7': ['Value 7', 0.5, 0.0, 1.0],
                                 'val8': ['Value 8', 0.5, 0.0, 1.0],
                                 'val9': ['Value 9', 0.5, 0.0, 1.0],
                                 'val10': ['Value 10', 0.5, 0.0, 1.0],
                                 'val11': ['Value 11', 0.5, 0.0, 1.0],
                                 'val12': ['Value 12', 0.5, 0.0, 1.0],
                                 'val13': ['Value 13', 0.5, 0.0, 1.0],
                                 'val14': ['Value 14', 0.5, 0.0, 1.0],
                                 'val15': ['Value 15', 0.5, 0.0, 1.0]},
                    'description': '16 Step sequencer with internal clock',
                    'inputs': {'back_gate': ['Back Gate', 'CVPort'],
                               'reset': ['Reset Trigger', 'CVPort'],
                               'play': ['Play', 'CVPort'],
                               'bpm': ['BPM', 'ControlPort'],
                               },
                    'broadcast_ports': {'current_step_out': ['current step out', 0, 0, 16]},
                    'outputs': {'out': ['Value Out', 'CVPort']}},
    'step_sequencer_ext': {'category': 2,
                    'controls': {'glide': ['Glide', 0.5, 0.0, 1.0],
                                 'steps': ['Loop Steps', 16, 1, 16],
                                 'val0': ['Value 0', 0.5, 0.0, 1.0],
                                 'val1': ['Value 1', 0.5, 0.0, 1.0],
                                 'val2': ['Value 2', 0.5, 0.0, 1.0],
                                 'val3': ['Value 3', 0.5, 0.0, 1.0],
                                 'val4': ['Value 4', 0.5, 0.0, 1.0],
                                 'val5': ['Value 5', 0.5, 0.0, 1.0],
                                 'val6': ['Value 6', 0.5, 0.0, 1.0],
                                 'val7': ['Value 7', 0.5, 0.0, 1.0],
                                 'val8': ['Value 8', 0.5, 0.0, 1.0],
                                 'val9': ['Value 9', 0.5, 0.0, 1.0],
                                 'val10': ['Value 10', 0.5, 0.0, 1.0],
                                 'val11': ['Value 11', 0.5, 0.0, 1.0],
                                 'val12': ['Value 12', 0.5, 0.0, 1.0],
                                 'val13': ['Value 13', 0.5, 0.0, 1.0],
                                 'val14': ['Value 14', 0.5, 0.0, 1.0],
                                 'val15': ['Value 15', 0.5, 0.0, 1.0]},
                    'description': '16 Step sequencer that takes in a trigger for next or previous',
                    'inputs': {'back_trigger': ['Back Trigger', 'CVPort'],
                               'reset': ['Reset Trigger', 'CVPort'],
                               'trigger': ['Step Trigger', 'CVPort']},
                    'broadcast_ports': {'current_step_out': ['current step out', 0, 0, 16]},
                    'outputs': {'out': ['Value Out', 'CVPort']}},
                     }


for k, v in effect_prototypes_models_all.items():
    n = 0
    for p in v["inputs"].values():
        if p[1] == "CVPort":
            n = n + 1
    effect_prototypes_models_all[k]["num_cv_in"] = n


effect_prototypes_models = {"digit": {k:effect_prototypes_models_all[k] for k in effect_type_maps["digit"].keys()},
    "beebo": {k:effect_prototypes_models_all[k] for k in effect_type_maps["beebo"].keys()},
    }



for k in effect_prototypes_models.keys():
    effect_prototypes_models[k]["input"] = {"inputs": {},
            "outputs": {"output": ["in", "AudioPort"]},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["output"] = {"inputs": {"input": ["out", "AudioPort"]},
            "outputs": {},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["midi_input"] = {"inputs": {},
            "outputs": {"output": ["in", "AtomPort"]},
            "num_cv_in": 0,
            "controls": {}}
    effect_prototypes_models[k]["midi_output"] = {"inputs": {"input": ["out", "AtomPort"]},
            "outputs": {},
            "num_cv_in": 0,
            "controls": {}}

bare_ports = ["input", "output", "midi_input", "midi_output"]


def clamp(v, min_value, max_value):
    return max(min(v, max_value), min_value)

def insert_row(model, row):
    j = len(model.stringList())
    model.insertRows(j, 1)
    model.setData(model.index(j), row)

def remove_row(model, row):
    i = model.stringList().index(row)
    model.removeRows(i, 1)

preset_list = []
preset_list_model = QStringListModel(preset_list)
hardware_info = {}
def load_preset_list():
    global preset_list
    try:
        with open("/mnt/pedal_state/"+current_pedal_model.name+"_preset_list.json") as f:
            preset_list = json.load(f)
    except:
        if current_pedal_model.name == "digit":
            preset_list = ["file:///mnt/presets/digit/Default_Preset.ingen"]
        elif current_pedal_model.name == "beebo":
            preset_list = ["file:///mnt/presets/beebo/Empty.ingen"]
    preset_list_model.setStringList(preset_list)

try:
    with open("/pedal_state/hardware_info.json") as f:
        hardware_info = json.load(f)
    hardware_info["revision"]
except:
    hardware_info = {"revision": 10, "pedal": "digit"}

class MyEmitter(QObject):
    # setting up custom signal
    done = Signal(int)

class MyWorker(QRunnable):

    def __init__(self, command, after=None):
        super(MyWorker, self).__init__()
        self.command = command
        self.after = after
        self.emitter = MyEmitter()

    def run(self):
        # run subprocesses, grab output
        ret_var = subprocess.call(self.command, shell=True)
        if self.after is not None:
            self.after()
        self.emitter.done.emit(ret_var)

class MyTask(QRunnable):

    def __init__(self, delay, command):
        super(MyTask, self).__init__()
        self.command = command
        self.delay = delay
        self.emitter = MyEmitter()

    def run(self):
        # run subprocesses, grab output
        time.sleep(self.delay)
        ret_var = self.command()
        self.emitter.done.emit(ret_var)

class PolyBool(QObject):
    # name, min, max, value
    def __init__(self, startval=False):
        QObject.__init__(self)
        self.valueval = startval

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        self.valueval = val
        self.value_changed.emit()

    @Signal
    def value_changed(self):
        pass

    value = Property(bool, readValue, setValue, notify=value_changed)

class PolyStr(QObject):
    # name, min, max, value
    def __init__(self, startval=False):
        QObject.__init__(self)
        self.valueval = startval

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        self.valueval = val
        self.value_changed.emit()

    @Signal
    def value_changed(self):
        pass

    value = Property(str, readValue, setValue, notify=value_changed)

class PatchBayNotify(QObject):

    def __init__(self):
        QObject.__init__(self)

    add_module = Signal(str)
    remove_module = Signal(str)
    loading_preset = Signal(bool)


# class PolyEncoder(QObject):
#     # name, min, max, value
#     def __init__(self, starteffect="", startparameter=""):
#         QObject.__init__(self)
#         self.effectval = starteffect
#         self.parameterval = startparameter
#         self.speed = 1
#         self.value = 1

#     def readEffect(self):
#         return self.effectval

#     def setEffect(self,val):
#         self.effectval = val
#         self.effect_changed.emit()

#     @Signal
#     def effect_changed(self):
#         pass

#     effect = Property(str, readEffect, setEffect, notify=effect_changed)

#     def readParameter(self):
#         return self.parameterval

#     def setParameter(self,val):
#         self.parameterval = val
#         self.parameter_changed.emit()

#     @Signal
#     def parameter_changed(self):
#         pass

#     parameter = Property(str, readParameter, setParameter, notify=parameter_changed)

class PolyValue(QObject):
    # name, min, max, value
    def __init__(self, startname="", startval=0, startmin=0, startmax=1, v_type="float", curve_type="lin", startcc=-1):
        QObject.__init__(self)
        self.nameval = startname
        self.valueval = startval
        self.defaultval = startval
        self.rminval = startmin
        self.rmax = startmax
        self.ccval = startcc

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        # clamp values
        self.valueval = clamp(val, self.rmin, self.rmax)
        self.value_changed.emit()
        # debug_print("setting value", val)

    @Signal
    def value_changed(self):
        pass

    value = Property(float, readValue, setValue, notify=value_changed)

    def readDefaultValue(self):
        return self.defaultval

    def setDefaultValue(self,val):
        # clamp values
        self.defaultval = clamp(val, self.rmin, self.rmax)
        self.default_value_changed.emit()
        # debug_print("setting value", val)

    @Signal
    def default_value_changed(self):
        pass

    default_value = Property(float, readDefaultValue, setDefaultValue, notify=default_value_changed)

    def readCC(self):
        return self.ccval

    def setCC(self,val):
        self.ccval = val
        self.cc_changed.emit()
        # debug_print("setting value", val)

    @Signal
    def cc_changed(self):
        pass

    cc = Property(float, readCC, setCC, notify=cc_changed)

    def readName(self):
        return self.nameval

    def setName(self,val):
        self.nameval = val
        self.name_changed.emit()

    @Signal
    def name_changed(self):
        pass

    name = Property(str, readName, setName, notify=name_changed)

    def readRMin(self):
        return self.rminval

    def setRMin(self,val):
        self.rminval = val
        self.rmin_changed.emit()

    @Signal
    def rmin_changed(self):
        pass

    rmin = Property(float, readRMin, setRMin, notify=rmin_changed)

    def readRMax(self):
        return self.rmaxval

    def setRMax(self,val):
        self.rmaxval = val
        self.rmax_changed.emit()

    @Signal
    def rmax_changed(self):
        pass

    rmax = Property(float, readRMax, setRMax, notify=rmax_changed)

def jump_to_preset(is_inc, num):

    if is_loading.value == True:
        return
    # need to call frontend function to jump to home page
    p_list = preset_list_model.stringList()
    if is_inc:
        current_preset.value = (current_preset.value + num) % len(p_list)
    else:
        if num < len(p_list):
            current_preset.value = num
        else:
            return
    debug_print("jumping to preset ", p_list[current_preset.value], "num is", num)
    knobs.ui_load_preset_by_name(p_list[current_preset.value])

def write_pedal_state():
    if platform.system() != "Linux":
        return
    with open("/mnt/pedal_state/state.json", "w") as f:
        json.dump(pedal_state, f)
    os.sync()

def write_preset_meta_cache():
    with open("/mnt/pedal_state/preset_meta.json", "w") as f:
        json.dump(preset_meta_data, f)
    os.sync()

def load_preset_meta_cache():
    global preset_meta_data
    try:
        with open("/mnt/pedal_state/preset_meta.json") as f:
            preset_meta_data = json.load(f)
    except:
        try:
            get_meta_from_files(True)
        except:
            preset_meta_data = {}

def write_favourites_data():
    with open("/mnt/pedal_state/favourites.json", "w") as f:
        json.dump(favourites, f)
    os.sync()

def load_favourites_data():
    global favourites
    try:
        with open("/mnt/pedal_state/favourites.json") as f:
            favourites = json.load(f)
    except:
        favourites = {"modules":{}, "presets":{}}


def load_pedal_state():
    global pedal_state
    try:
        with open("/mnt/pedal_state/state.json") as f:
            pedal_state = json.load(f)
            if "input_level" not in pedal_state:
                pedal_state["input_level"] = 0
            if "midi_channel" not in pedal_state:
                pedal_state["midi_channel"] = 1
            if "author" not in pedal_state:
                pedal_state["author"] = "poly player"
            if "model" not in pedal_state:
                pedal_state["model"] = "digit"
            if "thru" not in pedal_state:
                pedal_state["thru"] = True
    except:
        pedal_state = {"input_level": 0, "midi_channel": 1, "author": "poly player", "model": "digit", "thru": True}


selected_source_effect_ports = QStringListModel()
selected_source_effect_ports.setStringList(["val1", "val2"])
selected_dest_effect_ports = QStringListModel()
selected_dest_effect_ports.setStringList(["val1", "val2"])
seq_num = 10

sub_graph_suffix = 0
def add_inc_sub_graph(actually_add=True):
    global sub_graph_suffix
    sub_graph_suffix = sub_graph_suffix + 1
    name = "/main/sub"+str(sub_graph_suffix)+"/"
    global current_sub_graph
    current_sub_graph = name
    sub_graphs.add(name.rstrip("/"))
    if actually_add:
        add_sub_graph(name)
    return name

def add_sub_graph(name):
    ingen_wrapper.add_sub_graph(name.rstrip("/"))
    global current_sub_graph
    current_sub_graph = name
    sub_graphs.add(name.rstrip("/"))

def delete_sub_graph(name):
    name = name.rstrip("/")
    if name in sub_graphs:
        ingen_wrapper.remove_plugin(name)
        sub_graphs.remove(name)

def load_preset(name, initial=False, force=False):
    if is_loading.value == True and not force:
        return
    is_loading.value = True
    global preset_started_loading_time
    preset_started_loading_time = time.perf_counter()
    # is_loading.value = True
    # delete existing blocks
    port_connections.clear()
    reset_footswitch_assignments()
    to_delete = list(current_effects.keys())
    for effect_id in to_delete:
        if effect_id in ["/main/out_1", "/main/out_2", "/main/out_3", "/main/out_4", "/main/in_1", "/main/in_2", "/main/in_3", "/main/in_4"]:
            pass
        else:
            patch_bay_notify.remove_module.emit(effect_id)
            current_effects.pop(effect_id)
    if not initial:
        # debug_print("deleting sub graph", current_sub_graph)
        delete_sub_graph(current_sub_graph)
    add_inc_sub_graph(False)
    # debug_print("adding inc sub graph", current_sub_graph)
    ingen_wrapper.load_pedalboard(name, current_sub_graph.rstrip("/"))
    context.setContextProperty("currentEffects", current_effects) # might be slow
    context.setContextProperty("portConnections", port_connections)
    time.sleep(0.1)
    ingen_wrapper.get_state("/engine")

def from_backend_new_effect(effect_name, effect_type, x=20, y=30):
    # called by engine code when new effect is created
    # debug_print("from backend new effect", effect_name, effect_type)
    if effect_type in effect_prototypes:
        broadcast_ports = {}
        if "broadcast_ports" in effect_prototypes[effect_type]:
            broadcast_ports = {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["broadcast_ports"].items()}
        current_effects[effect_name] = {"x": x, "y": y, "effect_type": effect_type,
                "controls": {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["controls"].items()},
                "assigned_footswitch": PolyStr(""),
                "broadcast_ports" : broadcast_ports,
                "highlight": PolyBool(False), "enabled": PolyBool(True)}
        # insert in context or model? 
        # emit add signal
        context.setContextProperty("currentEffects", current_effects) # might be slow
        patch_bay_notify.add_module.emit(effect_name)
        # if effect_type == "midi_clock_in":
        #     # set broadcast on port
        #     ingen_wrapper.set_broadcast(effect_name+"/bpm", True)
    else:
        debug_print("### backend tried to add an unknown effect!")

def from_backend_remove_effect(effect_name):
    # called by engine code when effect is removed
    if effect_name not in current_effects:
        return
    # debug_print("### from backend removing effect")
    # emit remove signal
    for source_port, targets in list(port_connections.items()):
        s_effect, s_port = source_port.rsplit("/", 1)
        if s_effect == effect_name:
            del port_connections[source_port]
        else:
            port_connections[source_port] = [[e, p] for e, p in port_connections[source_port] if e != effect_name]
    patch_bay_notify.remove_module.emit(effect_name)
    for k in footswitch_assignments.keys(): # if this module has a foot switch assigned to it
        footswitch_assignments[k].discard(effect_name)
    # current_effects.pop(effect_name)
    context.setContextProperty("currentEffects", current_effects) # might be slow
    context.setContextProperty("portConnections", port_connections)
    ingen_wrapper.get_state("/engine")
    # debug_print("### from backend removing effect setting portConnections")
    update_counter.value+=1

def from_backend_add_connection(head, tail):
    # debug_print("head ", head, "tail", tail)
    current_source_port = head
    if current_source_port.rsplit("/", 1)[0] in sub_graphs:
        s_effect = current_source_port
        # debug_print("## s_effect", s_effect)
        if s_effect not in current_effects:
            return
        s_effect_type = current_effects[s_effect]["effect_type"]
        if s_effect_type in ("output", "midi_output"):
            s_port = "input"
        elif s_effect_type in ("input", "midi_input"):
            s_port = "output"
        current_source_port = s_effect + "/" + s_port
        # debug_print("## current_source_port", current_source_port)
    else:
        if current_source_port.rsplit("/", 1)[0] == "/main":
            return
        # debug_print("## current_source_port not in sub graph", current_source_port, sub_graphs)


    effect_id_port_name = tail.rsplit("/", 1)
    if effect_id_port_name[0] in sub_graphs :
        t_effect = tail
        if t_effect not in current_effects:
            return
        t_effect_type = current_effects[t_effect]["effect_type"]
        t_port = None
        if t_effect_type in ("output", "midi_output"):
            t_port = "input"
        elif t_effect_type in ("input", "midi_input"):
            t_port = "output"
        # debug_print("## tail in sub_graph", tail, t_effect, t_port)
        if t_port is None:
            return
    else:
        if effect_id_port_name[0] == "/main":
            return
        print("effect_id_port_name", effect_id_port_name)
        t_effect, t_port = effect_id_port_name
        # debug_print("## tail not in sub_graph", tail, t_effect, t_port, sub_graphs)
        if t_effect not in current_effects:
            return

    if current_source_port not in port_connections:
        port_connections[current_source_port] = []
    if [t_effect, t_port] not in port_connections[current_source_port]:
        port_connections[current_source_port].append([t_effect, t_port])

    # debug_print("port_connections is", port_connections)
    # global context
    context.setContextProperty("portConnections", port_connections)
    update_counter.value+=1


def from_backend_disconnect(head, tail):
    # debug_print("head ", head, "tail", tail)
    current_source_port = head
    if current_source_port.rsplit("/", 1)[0] in sub_graphs:
        s_effect = current_source_port
        s_effect_type = current_effects[s_effect]["effect_type"]
        if s_effect_type in ("output", "midi_output"):
            s_port = "input"
        elif s_effect_type in ("input", "midi_input"):
            s_port = "output"
        current_source_port = s_effect + "/" + s_port

    effect_id_port_name = tail.rsplit("/", 1)
    if effect_id_port_name[0] in sub_graphs:
        t_effect = tail
        t_effect_type = current_effects[t_effect]["effect_type"]
        if t_effect_type in ("output", "midi_output"):
            t_port = "input"
        elif t_effect_type in ("input", "midi_input"):
            t_port = "output"
    else:
        t_effect, t_port = effect_id_port_name

    # debug_print("before port_connections is", port_connections)
    if current_source_port in port_connections and [t_effect, t_port] in port_connections[current_source_port]:
        port_connections[current_source_port].pop(port_connections[current_source_port].index([t_effect, t_port]))
    # debug_print("after port_connections is", port_connections)
    # global context
    context.setContextProperty("portConnections", port_connections)
    update_counter.value+=1

def get_meta_from_files(initial=False):
    r_dict = {}
    def get_rdf_element_from_files(rdf_name="rdfs:comment", element_name="description"):
        command =  'grep -ir "'+ rdf_name +'" /mnt/presets'
        # command =  ['grep' , '-ir',  '"'+ element_name +'"',  '/mnt/presets']
        ret_obj = subprocess.run(command, capture_output=True, shell=True)
        for a in ret_obj.stdout.splitlines():
            b = a.decode().split(":", 1)
            v = b[1].split('"')[1]
            preset_name = b[0].rsplit("/", 1)[0]
            if preset_name not in r_dict:
                r_dict[preset_name] = {}
            r_dict[preset_name][element_name] = v
    get_rdf_element_from_files("rdfs:comment", "description")
    get_rdf_element_from_files("doap:maintainer", "author")
    get_rdf_element_from_files("doap:category", "tags")
    global preset_meta_data
    preset_meta_data = r_dict
    if not initial:
        context.setContextProperty("presetMeta", preset_meta_data)
    # flush to file
    write_preset_meta_cache()

class Knobs(QObject):
    @Slot(bool, str, str)
    def set_current_port(self, is_source, effect_id, port_name):
        # debug_print("port name is", port_name, "effect id", effect_id)
        # if source highlight targets
        if is_source:
            # set current source port
            # effect_id, port_name
            # highlight effects given source port
            global current_source_port
            current_source_port = "/".join((effect_id, port_name))
            connect_source_port.name = current_source_port
            try:
                out_port_type = effect_prototypes[current_effects[effect_id]["effect_type"]]["outputs"][port_name][1]
            except KeyError:
                return
            for id, effect in current_effects.items():
                effect["highlight"].value = False
                if id != effect_id:
                    # if out_port_type in ["CVPort", "ControlPort"]: # looking for controls
                    #     if len(current_effects[id]["controls"]) > 0:
                    #         effect["highlight"] = True
                    # else:
                    for input_port, style in effect_prototypes[effect["effect_type"]]["inputs"].items():
                        if style[1] == out_port_type:
                            # highlight and break
                            # qWarning("port highlighted")
                            effect["highlight"].value = True
                            break
        else:
            # if target disable highlight
            for id, effect in current_effects.items():
                effect["highlight"].value = False
            # add connection between source and target
            # or just wait until it's automatically created from engine? 
            # if current_source_port not in port_connections:
            #     port_connections[current_source_port] = []
            # if [effect_id, port_name] not in port_connections[current_source_port]:
            #     port_connections[current_source_port].append([effect_id, port_name])


            s_effect, s_port = current_source_port.rsplit("/", 1)
            s_effect_type = current_effects[s_effect]["effect_type"]
            t_effect_type = current_effects[effect_id]["effect_type"]
            if t_effect_type in bare_ports:
                if s_effect_type in bare_ports:
                    ingen_wrapper.connect_port(s_effect, effect_id)
                else:
                    ingen_wrapper.connect_port(current_source_port, effect_id)
            else:
                if s_effect_type in bare_ports:
                    ingen_wrapper.connect_port(s_effect, effect_id+"/"+port_name)
                else:
                    ingen_wrapper.connect_port(current_source_port, effect_id+"/"+port_name)


            # if [effect_id, port_name] not in inv_port_connections:
            #     inv_port_connections[[effect_id, port_name]] = []
            # if current_source_port not in inv_port_connections[[effect_id, port_name]]:
            #     inv_port_connections[[effect_id, port_name]].append(current_source_port)

            # debug_print("port_connections is", port_connections)
            # global context
            # context.setContextProperty("portConnections", port_connections)


    @Slot(bool, str, bool)
    def select_effect(self, is_source, effect_id, restrict_port_types=True):
        effect_type = current_effects[effect_id]["effect_type"]
        # debug_print("selecting effect type", effect_type)
        if is_source:
            ports = [k+'|'+v[0] for k,v in effect_prototypes[effect_type]["outputs"].items()]
            selected_source_effect_ports.setStringList(ports)
        else:
            s_effect_id, s_port = connect_source_port.name.rsplit("/", 1)
            source_port_type = effect_prototypes[current_effects[s_effect_id]["effect_type"]]["outputs"][s_port][1]
            if restrict_port_types or source_port_type == "AtomPort":
                ports = [k+'|'+v[0] for k,v in effect_prototypes[effect_type]["inputs"].items() if v[1] == source_port_type]
            else:
                ports = [k+'|'+v[0] for k,v in effect_prototypes[effect_type]["inputs"].items() if v[1] != "AtomPort"]
            selected_dest_effect_ports.setStringList(ports)

    @Slot(str)
    def list_connected(self, effect_id):
        ports = []
        for source_port, connected in port_connections.items():
            s_effect, s_port = source_port.rsplit("/", 1)
            display_s_port = effect_prototypes[current_effects[s_effect]["effect_type"]]["inputs"][s_port][0]
            # connections where we are target
            for c_effect, c_port in connected:
                display_c_port = effect_prototypes[current_effects[c_effect]["effect_type"]]["outputs"][c_port][0]
                if c_effect == effect_id:
                    ports.append("output==="+display_c_port+" connect to "+s_effect.rsplit("/", 1)[1]+" "+ display_s_port +"==="+s_effect+"/"+s_port+"---"+c_effect+"/"+c_port)
                elif s_effect == effect_id:
                    ports.append("input==="+c_effect.rsplit("/", 1)[1]+ " "+display_c_port+" connected to "+display_s_port+"==="+s_effect+"/"+s_port+"---"+c_effect+"/"+c_port)
        # debug_print("connected ports:", ports, effect_id)
        # qWarning("connected Ports "+ str(ports) + " " + effect_id)
        ports.sort()
        selected_source_effect_ports.setStringList(ports)

    @Slot(str)
    def disconnect_port(self, port_pair):
        target_pair, source_pair = port_pair.split("---")
        t_effect, t_port = target_pair.rsplit("/", 1)
        # debug_print("### disconnect, port pair", port_pair)

        s_effect, s_port = source_pair.rsplit("/", 1)
        s_effect_type = current_effects[s_effect]["effect_type"]
        t_effect_type = current_effects[t_effect]["effect_type"]
        if t_effect_type in bare_ports:
            if s_effect_type in bare_ports:
                ingen_wrapper.disconnect_port(s_effect, t_effect)
            else:
                ingen_wrapper.disconnect_port(source_pair, t_effect)
        else:
            if s_effect_type in bare_ports:
                ingen_wrapper.disconnect_port(s_effect, target_pair)
            else:
                ingen_wrapper.disconnect_port(source_pair, target_pair)

    @Slot(str)
    def add_new_effect(self, effect_type):
        # calls backend to add effect
        global seq_num
        seq_num = seq_num + 1
        # debug_print("add new effect", effect_type)
        # if there's existing effects of this type, increment the ID
        effect_name = current_sub_graph+effect_type+str(1)
        for i in range(1, 1000):
            if current_sub_graph+effect_type+str(i) not in current_effects:
                effect_name = current_sub_graph+effect_type+str(i)
                break
        ingen_wrapper.add_plugin(effect_name, effect_type_map[effect_type])
        # from_backend_new_effect(effect_name, effect_type)


    @Slot(str, bool)
    def set_bypass(self, effect_name, is_active):
        # check if were kill dry, if so, set enabled value, else just call default ingen:enabled
        effect_type = current_effects[effect_name]["effect_type"]
        if "kill_dry" in effect_prototypes[effect_type]:
            v = 1.0 - (current_effects[effect_name]["controls"]["enabled"].value)
            knobs.ui_knob_change(effect_name, "enabled", v)
            current_effects[effect_name]["enabled"].value = bool(v)
        else:
            ingen_wrapper.set_bypass(effect_name, is_active)

    @Slot(str)
    def set_description(self, description):
        ingen_wrapper.set_description(current_sub_graph.rstrip("/"), description)
        preset_description.name = description

    @Slot(str, int, int)
    def move_effect(self, effect_name, x, y):
        current_effects[effect_name]["x"] = x
        current_effects[effect_name]["y"] = y
        ingen_wrapper.set_plugin_position(effect_name, x, y)

    @Slot(str)
    def remove_effect(self, effect_id):
        # calls backend to remove effect
        # debug_print("remove effect", effect_id)
        ingen_wrapper.remove_plugin(effect_id)

    @Slot(str, str, 'double')
    def ui_knob_change(self, effect_name, parameter, value):
        # debug_print(x, y, z)
        if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
            current_effects[effect_name]["controls"][parameter].value = value
            # clamping here to make it a bit more obvious
            value = clamp(value, current_effects[effect_name]["controls"][parameter].rmin, current_effects[effect_name]["controls"][parameter].rmax)
            # bit sketch but check if BPM here? XXX
            if parameter == "bpm":
                set_bpm(value)

            ingen_wrapper.set_parameter_value(effect_name+"/"+parameter, value)
        else:
            debug_print("effect not found", effect_name, parameter, value, effect_name in current_effects)

    @Slot(str, str)
    def update_ir(self, effect_id, ir_file):
        is_cab = True
        effect_type = current_effects[effect_id]["effect_type"]
        if effect_type in ["mono_reverb", "stereo_reverb", "quad_ir_reverb"]:
            is_cab = False
        current_effects[effect_id]["controls"]["ir"].name = ir_file
        ingen_wrapper.set_file(effect_id, ir_file, is_cab)

    @Slot()
    def ui_load_empty_preset(self):
        if current_pedal_model.name == "digit":
            knobs.ui_load_preset_by_name("file:///mnt/presets/digit/Empty.ingen")
        elif current_pedal_model.name == "beebo":
            knobs.ui_load_preset_by_name("file:///mnt/presets/beebo/Empty.ingen")

    @Slot(str)
    def ui_load_preset_by_name(self, preset_file):
        if is_loading.value == True:
            return

        patch_bay_notify.loading_preset.emit(True)
        # debug_print("loading", preset_file)
        # outfile = preset_file[7:] # strip file:// prefix
        load_preset(preset_file+"/main.ttl")
        current_preset.name = preset_file.strip("/").split("/")[-1][:-6]
        global current_preset_filename
        current_preset_filename = preset_file[7:]
        update_counter.value+=1

    @Slot(str)
    def ui_load_qa_preset_by_name(self, preset_file):
        if is_loading.value == True:
            return

        # debug_print("loading", preset_file)
        # outfile = preset_file[7:] # strip file:// prefix
        load_preset(preset_file+"/main.ttl")
        current_preset.name = preset_file.strip("/").split("/")[-1][:-6]
        global current_preset_filename
        current_preset_filename = preset_file[7:]
        update_counter.value+=1

    @Slot(str)
    def ui_save_pedalboard(self, pedalboard_name):
        # debug_print("saving", preset_name)
        # TODO add folders
        current_preset.name = pedalboard_name
        ingen_wrapper.set_author(current_sub_graph.rstrip("/"), pedal_state["author"])
        ingen_wrapper.save_pedalboard(current_pedal_model.name, pedalboard_name, current_sub_graph.rstrip("/"))
        self.launch_task(2, os.sync) # wait 2 seconds then sync to drive
        # update preset meta
        clean_filename = ingen_wrapper.get_valid_filename(pedalboard_name)
        if len(clean_filename) > 0:
            filename = "/mnt/presets/"+current_pedal_model.name+"/"+clean_filename+".ingen"
            global current_preset_filename
            current_preset_filename = filename
            if filename in preset_meta_data:
                preset_meta_data[filename]["author"] = pedal_state["author"]
                preset_meta_data[filename]["description"] = preset_description.name
            else:
                preset_meta_data[filename] = {"author": pedal_state["author"], "description": preset_description.name}

            context.setContextProperty("presetMeta", preset_meta_data)
            # flush to file
            write_preset_meta_cache()

    @Slot(str)
    def toggle_favourite(self, preset_file):
        p_f = preset_file[7:]
        if p_f in favourites["presets"]:
            favourites["presets"][p_f] = not favourites["presets"][p_f]
        elif p_f in preset_meta_data:
            favourites["presets"][p_f] = True
        else:
            return
        context.setContextProperty("favourites", favourites)
        # flush to file
        write_favourites_data()

    @Slot()
    def ui_copy_irs(self):
        # debug_print("copy irs from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        # remount RW 
        command = """ sudo mount -o remount,rw /dev/mmcblk0p2 /mnt; if [ -d /usb_flash/reverbs ]; then cd /usb_flash/reverbs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/mnt/audio/reverbs --parents; fi;
        if [ -d /usb_flash/cabs ]; then cd /usb_flash/cabs; find . -iname "*.wav" -type f -exec sh -c 'test $(soxi -r "$0") = "48000"' {} \; -print0 | xargs -0 cp --target-directory=/mnt/audio/cabs --parents; fi; sudo mount -o remount,ro /dev/mmcblk0p2 /mnt;"""
        # copy all wavs in /usb/reverbs and /usr/cabs to /audio/reverbs and /audio/cabs
        command_status[0].value = -1
        self.launch_subprocess(command)
        # remount RO 

    @Slot()
    def import_presets(self):
        # debug_print("copy presets from USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """cd /usb_flash/presets; find . -iname "*.ingen" -type d -print0 | xargs -0 cp -r --target-directory=/mnt/presets --parents"""
        command_status[0].value = -1
        self.launch_subprocess(command, after=get_meta_from_files)
        # after presets have copied we need to parse all the tags / author and update cache

    @Slot()
    def export_presets(self):
        # debug_print("copy presets to USB")
        command = """cd /mnt/presets; mkdir -p /usb_flash/presets; find . -iname "*.ingen" -type d -print0 | xargs -0 cp -r --target-directory=/usb_flash/presets --parents;sudo umount /usb_flash"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def export_current_preset(self):
        # debug_print("copy current preset to USB")
        i = current_preset_filename.find("presets")+len("presets")+1
        out_file = current_preset_filename[i:] # strip starting folders
        command = """cd /mnt/presets; mkdir -p /usb_flash/presets; cp -r --target-directory=/usb_flash/presets --parents """+out_file+""";sudo umount /usb_flash"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def copy_logs(self):
        # debug_print("copy presets to USB")
        # could convert any that aren't 48khz.
        # instead we just only copy ones that are
        command = """mkdir -p /usb_flash/logs; sudo cp /var/log/syslog /usb_flash/logs/;sudo umount /usb_flash"""
        command_status[0].value = -1
        self.launch_subprocess(command)

    @Slot()
    def ui_update_firmware(self):
        # debug_print("Updating firmware")
        # dpkg the debs in the folder
        if len(glob.glob("/usb_flash/*.deb")) > 0:
            command = """sudo /usr/bin/polyoverlayroot-chroot dpkg -i /usb_flash/*.deb && sudo shutdown -h 'now'"""
            command_status[0].value = -1
            self.launch_subprocess(command)
        else:
            command_status[0].value = 1


    @Slot(int)
    def set_input_level(self, level, write=True):
        if platform.system() != "Linux":
            return
        command = "amixer -- sset ADC1 "+str(level)+"db; amixer -- sset ADC2 "+str(level)+"db"
        command_status[0].value = subprocess.call(command, shell=True)
        if hardware_info["revision"] <= 10:
            command = "amixer -- sset 'ADC1 Invert' off,on; amixer -- sset 'ADC2 Invert' on,on"
        else:
            command = "amixer -- sset 'ADC1 Invert' off,off; amixer -- sset 'ADC2 Invert' off,off"
        command_status[0].value = subprocess.call(command, shell=True)
        input_level.value = level
        if write:
            pedal_state["input_level"] = level
            write_pedal_state()

    @Slot(int)
    def set_channel(self, channel):
        midi_channel.value = channel
        pedal_state["midi_channel"] = channel
        write_pedal_state()

    @Slot(bool)
    def set_thru_enabled(self, thru_on):
        pedal_state["thru"] = thru_on
        context.setContextProperty("pedalState", pedal_state)
        write_pedal_state()
        try:
            if thru_on:
                command = ["/usr/bin/jack_connect",  "ttymidi:MIDI_in", "ttymidi:MIDI_out"]
                ret_var = subprocess.run(command)
            else:
                command = ["/usr/bin/jack_disconnect",  "ttymidi:MIDI_in", "ttymidi:MIDI_out"]
                ret_var = subprocess.run(command)
        except:
            pass

    @Slot(int)
    def set_preset_list_length(self, v):
        if v > len(preset_list_model.stringList()):
            # debug_print("inserting new row in preset list", v)
            if current_pedal_model.name == "digit":
                insert_row(preset_list_model, "file:///mnt/presets/digit/Default_Preset.ingen")
            elif current_pedal_model.name == "beebo":
                insert_row(preset_list_model, "file:///mnt/presets/beebo/Empty.ingen")
        else:
            # debug_print("removing row in preset list", v)
            preset_list_model.removeRows(v, 1)

    @Slot(int, str)
    def map_preset(self, v, name):
        preset_list_model.setData(preset_list_model.index(v), name)

    @Slot()
    def save_preset_list(self):
        # debug_print("saving preset list")
        with open("/mnt/pedal_state/"+current_pedal_model.name+"_preset_list.json", "w") as f:
            json.dump(preset_list_model.stringList(), f)
        os.sync()

    @Slot(int)
    def on_worker_done(self, ret_var):
        # debug_print("updating UI")
        command_status[0].value = ret_var

    @Slot(int)
    def on_task_done(self, ret_var):
        # debug_print("updating UI")
        command_status[0].value = ret_var

    def launch_subprocess(self, command, after=None):
        # debug_print("launch_threadpool")
        worker = MyWorker(command, after)
        worker.emitter.done.connect(self.on_worker_done)
        worker_pool.start(worker)

    def launch_task(self, delay, command):
        # debug_print("launch_threadpool")
        worker = MyTask(delay, command)
        # worker.emitter.done.connect(self.on_worker_done)
        worker_pool.start(worker)

    @Slot(str, str)
    def set_knob_current_effect(self, effect_id, parameter):
        # get current value and update encoder / cache.
        # qDebug("setting knob current effect" + parameter)
        knob = "left"
        if not (knob_map[knob].effect == effect_id and knob_map[knob].parameter == parameter):
            knob_map[knob].effect = effect_id
            knob_map[knob].parameter = parameter
            knob_map[knob].rmin = current_effects[effect_id]["controls"][parameter].rmin
            knob_map[knob].rmax = current_effects[effect_id]["controls"][parameter].rmax

    @Slot(str)
    def set_pedal_model(self, pedal_model):
        if is_loading.value == True:
            return
        pedal_state["model"] = pedal_model
        write_pedal_state()
        change_pedal_model(pedal_model)

    @Slot(str)
    def delete_ir(self, ir):
        # debug_print("delete: ir files is ", ir)
        ir = ir[len("file://"):]
        # can be a directory or file
        # check if it isn't a base dir. 
        if "imported" not in ir or ir in ["/audio/cabs/imported", "/audio/reverbs/imported"]:
            return
        # delete
        # remount as RW
        command = "sudo mount -o remount,rw /dev/mmcblk0p2 /mnt"
        ret_var = subprocess.call(command, shell=True)
        try:
            os.remove(ir)
        except IsADirectoryError:
            shutil.rmtree(ir)
        os.sync()
        # remount as RO
        command = "sudo mount -o remount,ro /dev/mmcblk0p2 /mnt"
        ret_var = subprocess.call(command, shell=True)

    @Slot(str)
    def delete_preset(self, in_preset_file):
        preset_file = in_preset_file[len("file://"):]
        debug_print("delete: preset_file files is ", preset_file)
        # is always a directory
        # empty / default
        if ".ingen" not in preset_file or preset_file in ["/mnt/presets/digit/Default_Preset.ingen", "/mnt/presets/beebo/Empty.ingen", "/mnt/presets/digit/Empty.ingen"]:
            return
        # delete
        shutil.rmtree(preset_file)
        # remove from set list.
        preset_list = preset_list_model.stringList()
        debug_print("preset list is", preset_list)
        if in_preset_file in preset_list:
            preset_list = [v for v in preset_list if v != in_preset_file]
            preset_list_model.setStringList(preset_list)
            self.save_preset_list()
        os.sync()

    @Slot()
    def save_preset_list(self):
        debug_print("saving preset list")
        with open("/mnt/pedal_state/"+current_pedal_model.name+"_preset_list.json", "w") as f:
            json.dump(preset_list_model.stringList(), f)
        os.sync()
    preset_list_model.setStringList(preset_list)


    @Slot(str)
    def set_pedal_author(self, author):
        pedal_state["author"] = author
        write_pedal_state()
        context.setContextProperty("pedalState", pedal_state)

    @Slot(int, str)
    def set_current_mode(self, mode, effect_name):
        # debug_print("updating UI")
        global current_patchbay_mode
        global current_selected_effect
        current_patchbay_mode = mode
        current_selected_effect = effect_name

    @Slot()
    def get_ip(self):
        ret_obj = subprocess.run("hostname -I", capture_output=True, shell=True)
        current_ip.name = ret_obj.stdout.decode()

    @Slot(str, bool)
    def set_broadcast(self, effect_name, is_broadcast):
        # debug_print(x, y, z)
        if (effect_name in current_effects) and ("broadcast_ports" in current_effects[effect_name]):
            for parameter in current_effects[effect_name]["broadcast_ports"].keys():
                ingen_wrapper.set_broadcast(effect_name+"/"+parameter, is_broadcast)
        else:
            debug_print("effect not found", effect_name, effect_name in current_effects)

    @Slot(str, str)
    def midi_learn(self, effect_name, parameter):
        # this toggles, if we're already learned, forget. No way to currently cancel waiting for midi
        if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
            if current_effects[effect_name]["controls"][parameter].cc > -1:
                # have current, forget
                ingen_wrapper.midi_forget(effect_name+"/"+parameter)
            else:
                ingen_wrapper.midi_learn(effect_name+"/"+parameter)
        else:
            debug_print("effect not found", effect_name, parameter, value, effect_name in current_effects)

def io_new_effect(effect_name, effect_type, x=20, y=30):
    # called by engine code when new effect is created
    # debug_print("from backend new effect", effect_name, effect_type)
    if effect_type in effect_prototypes:
        current_effects[effect_name] = {"x": x, "y": y, "effect_type": effect_type,
                "controls": {},
                "highlight": PolyBool(False)}

def add_io():
    for i in range(1,5):
        ingen_wrapper.add_input("/main/in_"+str(i), x=1192, y=(80*i))
    for i in range(1,5):
        ingen_wrapper.add_output("/main/out_"+str(i), x=-20, y=(80 * i))
    ingen_wrapper.add_midi_input("/main/midi_in", x=1192, y=(80 * 5))
    ingen_wrapper.add_midi_output("/main/midi_out", x=-20, y=(80 * 5))

class Encoder():
    # name, min, max, value
    def __init__(self, starteffect="", startparameter="", s_speed=1):
        self.effect = starteffect
        self.parameter = startparameter
        self.speed = s_speed
        self.rmin = 0
        self.rmax = 1

knob_map = {"left": Encoder(s_speed=0.05), "right": Encoder(s_speed=1)}

def handle_encoder_change(is_left, change):
    # debug_print(is_left, change)
    # qDebug("encoder change "+ str(is_left) + str(change))
    # increase or decrease the current knob value depending on knob speed
    # knob_value = knob_value + (change * knob_speed)
    normal_speed = 24.0
    knob = "left"
    knob_effect = knob_map[knob].effect
    knob_parameter = knob_map[knob].parameter
    if True: # qa_view:
        if is_left:
            qa_k = "left"
        else:
            qa_k = "right"
        value = encoder_qa[qa_k].value
        base_speed = 1 / normal_speed
        knob_speed = 5
        value = value + (change * knob_speed * base_speed)
        encoder_qa[qa_k].value = value

    if not knob_effect or knob_effect not in current_effects:
        return
    value = current_effects[knob_effect]["controls"][knob_parameter].value
    if is_left:
        knob_speed = knob_map["left"].speed
    else:
        knob_speed = knob_map["right"].speed
    # base speed * speed multiplier
    base_speed = (abs(knob_map[knob].rmin) + abs(knob_map[knob].rmax)) / normal_speed
    value = value + (change * knob_speed * base_speed)

    # debug_print("knob value is", value)
    # knob change handles clamping
    knobs.ui_knob_change(knob_effect, knob_parameter, value)

def set_bpm(bpm):
    current_bpm.value = bpm
    # host.transport_bpm(bpm)
    # send_ui_message("bpm_change", (bpm, ))
    # debug_print("setting tempo", bpm)

### Assignable actions
# 

Actions = Enum("Actions", """set_value
set_value_down
tap
set_tempo
toggle_pedal
select_preset
next_preset
previous_preset
next_action_group previous_action_group
toggle_effect
""")
foot_action_groups = [{"tap_up":[Actions.set_value] , "step_up": [Actions.set_value], "bypass_up":[Actions.set_value],
    "tap_down":[Actions.set_value_down] , "step_down": [Actions.set_value_down], "bypass_down":[Actions.set_value_down],
    "tap_step_up": [Actions.previous_preset], "step_bypass_up": [Actions.next_preset]}]
current_action_group = 0

def handle_bypass():
    # global bypass
    pedal_bypassed.value = not pedal_bypassed.value
    if pedal_bypassed.value:
        pedal_hardware.effect_off()
    else:
        pedal_hardware.effect_on()

def hide_foot_switch_warning():
    foot_switch_warning.value = False

def send_to_footswitch_blocks(timestamp, switch_name, value=0):
    # send to all foot switch blocks
    # qDebug("sending to switch_name "+str(switch_name) + "value" + str(value))
    if "tap" in switch_name:
        foot_switch_name = "foot_switch_a"
    if "step" in switch_name:
        foot_switch_name = "foot_switch_b"
    if "bypass" in switch_name:
        foot_switch_name = "foot_switch_c"

    trimmed_name = foot_switch_name[-1]
    # if we're in hold mode then we're assigning something to a foot switch
    if value == 0 and current_patchbay_mode == PatchMode.HOLD:
        # set this foot swtich to the currently held effect
        if current_selected_effect != "":
            if current_effects[current_selected_effect]["assigned_footswitch"].value == trimmed_name:
                ingen_wrapper.set_footswitch_control(current_selected_effect, "")
            else:
                ingen_wrapper.set_footswitch_control(current_selected_effect, foot_switch_name[-1])
            return

    if True: # qa_view
        foot_switch_qa[foot_switch_name[-1]].value = value

    found_effect = False
    bpm = None
    if value == 1:
        bpm = handle_tap(foot_switch_name, timestamp)

    # toggle all assigned effects
    if value == 0:
        for effect_id in footswitch_assignments[trimmed_name]:
            enabled = current_effects[effect_id]["enabled"].value
            knobs.set_bypass(effect_id, not enabled) # toggle
            found_effect = True

    for effect_id, effect in current_effects.items():
        if "foot_switch" in effect["effect_type"]:
            if foot_switch_name in effect_id:
                if bpm is not None:
                    # qDebug("sending knob change from foot switch "+effect_id + "bpm" + str(float(bpm)))
                    knobs.ui_knob_change(effect_id, "bpm", float(bpm))
                # qDebug("sending knob change from foot switch "+effect_id + "value" + str(float(value)))
                if effect["controls"]["latching"].value < 0.9:
                    effect["controls"]["cur_out"].value = float(value)
                else:
                    if value > 0:
                        effect["controls"]["cur_out"].value = 1.0 - effect["controls"]["cur_out"].value
                knobs.ui_knob_change(effect_id, "value", float(value))
                found_effect = True

    if not found_effect and value == 0:
        if foot_switch_name == "foot_switch_c":
            handle_bypass()
        else:
            # show you're pressing a footswitch that isn't connected to anything
            foot_switch_warning.value = True
            QTimer.singleShot(2500, hide_foot_switch_warning)


def next_preset():
    jump_to_preset(True, 1)

def previous_preset():
    jump_to_preset(True, -1)

def handle_foot_change(switch_name, timestamp):
    # debug_print(switch_name, timestamp)
    # qDebug("foot change "+ str(switch_name) + str(timestamp))
    action = foot_action_groups[current_action_group][switch_name][0]
    params = None
    if len(foot_action_groups[current_action_group][switch_name]) > 1:
        params = foot_action_groups[current_action_group][switch_name][1:]
    if action is Actions.tap:
        pass
    elif action is Actions.toggle_pedal:
        handle_bypass()

    elif action is Actions.set_value:
        send_to_footswitch_blocks(timestamp, switch_name, 0)
    elif action is Actions.set_value_down:
        send_to_footswitch_blocks(timestamp, switch_name, 1)
    elif action is Actions.select_preset:
        pass

    elif action is Actions.next_preset:
        next_preset()

    elif action is Actions.previous_preset:
        previous_preset()

    elif action is Actions.toggle_effect:
        pass

start_tap_time = {"foot_switch_a":None, "foot_switch_b":None, "foot_switch_c":None}
## tap callback is called by hardware button from the GPIO checking thread
def handle_tap(footswitch, timestamp):
    current_tap = timestamp
    bpm = None
    if start_tap_time[footswitch] is not None:
        # just use this and previous to calculate BPM
        # BPM must be in range 30-250
        d = current_tap - start_tap_time[footswitch]
        # 120 bpm, 0.5 seconds per tap
        bpm = 60 / d
        if bpm > 30 and bpm < 350:
            # set host BPM
            pass
        else:
            bpm = None

    # record start time
    start_tap_time[footswitch] = current_tap
    return bpm

def process_ui_messages():
    # pop from queue
    try:
        while not EXIT_PROCESS[0]:
            m = ui_messages.get(block=False)
            # debug_print("got ui message", m)
            if m[0] == "value_change":
                # debug_print("got value change in process_ui")
                effect_name_parameter, value = m[1:]
                effect_name, parameter = effect_name_parameter.rsplit("/", 1)
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
                        effect_type = current_effects[effect_name]["effect_type"]
                        # debug_print("value set", value, effect_type, parameter )
                        if "kill_dry" in effect_prototypes[effect_type] and parameter == "enabled":
                            # debug_print("kill dry value set", value)
                            current_effects[effect_name]["enabled"].value = bool(float(value))
                        current_effects[effect_name]["controls"][parameter].value = float(value)
                except ValueError:
                    pass

            elif m[0] == "bpm_change":
                current_bpm.value = m[1][0]
            elif m[0] == "set_plugin_state":
                pass
                # plugin_state[m[1][0]].value = m[1][1]
            elif m[0] == "add_connection":
                head, tail = m[1:]
                from_backend_add_connection(head, tail)
            elif m[0] == "remove_connection":
                head, tail = m[1:]
                from_backend_disconnect(head, tail)
            elif m[0] == "add_plugin":
                effect_name, effect_type, x, y = m[1:5]
                # debug_print("got add", m)
                if (effect_name not in current_effects and (effect_type in inv_effect_type_map or effect_type in bare_ports)):
                    # debug_print("adding ", m)
                    if effect_type == "http://polyeffects.com/lv2/polyfoot":
                        mapped_type = effect_name.rsplit("/", 1)[1].rstrip("123456789")
                        if mapped_type in effect_type_map:
                            from_backend_new_effect(effect_name, mapped_type, x, y)
                    elif effect_type in bare_ports:
                        from_backend_new_effect(effect_name, effect_type, x, y)
                    else:
                        from_backend_new_effect(effect_name, inv_effect_type_map[effect_type], x, y)
                        ingen_wrapper.get_state("/engine")
            elif m[0] == "remove_plugin":
                effect_name = m[1]
                if (effect_name in current_effects):
                    from_backend_remove_effect(effect_name)
            elif m[0] == "enabled_change":
                effect_name, is_enabled = m[1:]
                # debug_print("enabled changed ", m)
                if (effect_name in current_effects):
                    # debug_print("adding ", m)
                    current_effects[effect_name]["enabled"].value = bool(is_enabled)
            elif m[0] == "pedalboard_loaded":
                subgraph, file_name = m[1:]
                # disable loading sign
                print ("pedalboard loaded", subgraph, file_name, current_sub_graph)
                if subgraph == current_sub_graph.rstrip("/"):
                    is_loading.value = False
                    done_loading_time = time.perf_counter()
                    # check if we've got MIDI IO, if not add them
                    print("### preset loaded in ", done_loading_time - preset_started_loading_time)
                    debug_print("checking if MIDI exists")
                    if not (current_sub_graph+"midi_in" in current_effects):
                        ingen_wrapper.add_midi_input(current_sub_graph+"midi_in", x=1192, y=(80 * 5))
                        debug_print("adding MIDI")
                    if not (current_sub_graph+"midi_out" in current_effects):
                        ingen_wrapper.add_midi_output(current_sub_graph+"midi_out", x=-20, y=(80 * 5))

            elif m[0] == "dsp_load":
                max_load, mean_load, min_load = m[1:]
                dsp_load.rmin = min_load
                dsp_load.rmax = max_load
                dsp_load.value = mean_load + 0.25
            elif m[0] == "set_comment":
                description, subject = m[1:]
                preset_description.name = description
            elif m[0] == "assign_footswitch":
                footswitch, effect_name = m[1:]
                if effect_name in current_effects:
                    current_effects[effect_name]["assigned_footswitch"].value = footswitch
                    # remove existing assignment if any
                    for k in footswitch_assignments.keys():
                        footswitch_assignments[k].discard(effect_name)
                    if footswitch in footswitch_assignments:
                        footswitch_assignments[footswitch].add(effect_name)
            elif m[0] == "midi_pc":
                program = m[1]
                jump_to_preset(False, program)
            elif m[0] == "add_port":
                pass
            elif m[0] == "set_file":
                effect_name, ir_file = m[1:]
                try:
                    if (effect_name in current_effects) and ("ir" in current_effects[effect_name]["controls"]):
                        if current_effects[effect_name]["controls"]["ir"].name != ir_file:
                            current_effects[effect_name]["controls"]["ir"].name = ir_file
                            effect_type = current_effects[effect_name]["effect_type"]
                            if effect_type in ["mono_reverb", "stereo_reverb", "quad_ir_reverb"]:
                                # debug_print("setting reverb file", urllib.parse.unquote(ir_file))
                                knobs.update_ir(effect_name, urllib.parse.unquote(ir_file))
                            elif effect_type in ["mono_cab", "stereo_cab", "quad_ir_cab"]:
                                knobs.update_ir(effect_name, urllib.parse.unquote(ir_file))
                                # debug_print("setting cab file", urllib.parse.unquote(ir_file))
                        # qDebug("setting knob file " + ir_file)
                except ValueError:
                    pass
            elif m[0] == "remove_port":
                pass
            elif m[0] == "exit":
                # global EXIT_PROCESS
                EXIT_PROCESS[0] = True
            elif m[0] == "broadcast_update":
                # debug_print("got value change in process_ui")
                effect_name_parameter, value = m[1:]
                effect_name, parameter = effect_name_parameter.rsplit("/", 1)

                if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
                    effect_type = current_effects[effect_name]["effect_type"]
                    # debug_print("value set", value, effect_type, parameter )
                    if "kill_dry" in effect_prototypes[effect_type] and parameter == "enabled":
                        # debug_print("kill dry value set", value)
                        current_effects[effect_name]["enabled"].value = bool(float(value))
                    current_effects[effect_name]["controls"][parameter].value = float(value)
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["broadcast_ports"]):
                        current_effects[effect_name]["broadcast_ports"][parameter].value = float(value)
                        # print("updated ", effect_name, parameter, value)
                except ValueError:
                    pass
            elif m[0] == "midi_learn":
                debug_print("got midi_learn in process_ui")
                effect_name_parameter, value = m[1:]
                effect_name, parameter = effect_name_parameter.rsplit("/", 1)
                try:
                    if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
                        current_effects[effect_name]["controls"][parameter].cc = int(value)
                        # print("updated ", effect_name, parameter, value)
                except ValueError:
                    pass
    except queue.Empty:
        pass




effect_type_map = {}
effect_prototypes = {}
inv_effect_type_map = {}


def set_available_effects():
    hidden_effects = ["mix_vca"]
    # add list is effect_category:effect_name
    effects = set(effect_type_map.keys()) - set(hidden_effects)
    cat_effects = [[], [], [], []]
    for e in effects:
        cat_effects[effect_prototypes[e]["category"]].append(e)
    #     print(e)
    #     # qDebug(e)
    #     if "category" not in effect_prototypes[e]:
    #         print(e)
    #         qDebug("MISSING")
    #         qDebug(e)
        # print(e, str(effect_prototypes[e]["category"]))
    # cat_effects = sorted([str(effect_prototypes[e]["category"])+":"+e for e in effects])
    for i, a in enumerate(cat_effects):
        available_effects[i].setStringList(sorted(a))
    # available_effects.setStringList(list(effects))

def change_pedal_model(name, initial=False):
    global inv_effect_type_map
    global effect_type_map
    global effect_prototypes
    effect_type_map = effect_type_maps[name]
    effect_prototypes = effect_prototypes_models[name]

    set_available_effects()
    context.setContextProperty("effectPrototypes", effect_prototypes)
    accent_color_models = {"beebo": "#8BB8E8", "digit": "#FF75D0"}
    accent_color.name = accent_color_models[name]

    inv_effect_type_map = {v:k for k, v in effect_type_map.items()}
    current_pedal_model.name = name
    load_preset_list()
    # if not initial:
    if True:
        if current_pedal_model.name == "digit":
            jump_to_preset(False, 0)
            # knobs.ui_load_preset_by_name("file:///mnt/presets/digit/Default_Preset.ingen")
        elif current_pedal_model.name == "beebo":
            jump_to_preset(False, 0)
            # knobs.ui_load_preset_by_name("file:///mnt/presets/beebo/Empty.ingen")

def handle_MIDI_program_change():
    # This is pretty dodgy... but I don't want to depend on jack in the main process as it'll slow down startup
    # we need to wait here for ttymidi to be up
    ttymidi_found = False
    if platform.system() != "Linux":
        return
    while not ttymidi_found:
        a = subprocess.run(["jack_lsp", "ttymidi"], capture_output=True)
        if b"ttymidi" in a.stdout:
            ttymidi_found = True
        time.sleep(1)
    p = subprocess.Popen('jack_midi_dump', stdout=subprocess.PIPE)
    # Grab stdout line by line as it becomes available.  This will loop until 
    time.sleep(2)
    try:
        command = ["/usr/bin/jack_connect",  "ttymidi:MIDI_in", "midi-monitor:input"]
        ret_var = subprocess.run(command)
        # check if MIDI thru is needed
        if pedal_state["thru"] == True:
            command = ["/usr/bin/jack_connect",  "ttymidi:MIDI_in", "ttymidi:MIDI_out"]
            ret_var = subprocess.run(command)
    except:
        pass
    # p terminates.
    while p.poll() is None:
        l = p.stdout.readline() # This blocks until it receives a newline.
        if len(l) > 8 and l[6] == b'c'[0]:
            b = l.decode()
            ig, b1, b2 = b.split()
            channel = int("0x"+b1, 16) - 0xC0
            program = int("0x"+b2, 16)
            # debug_print(channel, program)
            if channel == midi_channel.value - 1: # our channel
                # put this in the queue
                ui_messages.put(("midi_pc", program))
    # When the subprocess terminates there might be unconsumed output 
    # that still needs to be processed.
    ignored = p.stdout.read()

if __name__ == "__main__":

    debug_print("in Main")
    app = QGuiApplication(sys.argv)
    QIcon.setThemeName("digit")

    # preset might not have been copied on an update, as file system might not have been supported
    if not os.path.isfile("/mnt/presets/digit/Default_Preset.ingen/main.ttl"):
        # rsync
        command = "sudo rsync -a /to_nor_flash/ /nor_flash"
        ret_var = subprocess.call(command, shell=True)


    # Instantiate the Python object.
    knobs = Knobs()


    update_counter = PolyValue("update counter", 0, 0, 500000)
    # read persistant state
    pedal_state = {}
    load_pedal_state()
    current_bpm = PolyValue("BPM", 120, 30, 250) # bit of a hack
    current_preset = PolyValue("Default Preset", 0, 0, 127)
    current_preset_filename = ""
    update_counter = PolyValue("update counter", 0, 0, 500000)
    command_status = [PolyValue("command status", -1, -10, 100000), PolyValue("command status", -1, -10, 100000)]
    delay_num_bars = PolyValue("Num bars", 1, 1, 16)
    dsp_load = PolyValue("DSP Load", 0, 0, 0.3)
    foot_switch_qa = {"a":PolyValue("a", 0, 0, 1), "b":PolyValue("b", 0, 0, 1), "c":PolyValue("c", 0, 0, 1)}
    encoder_qa = {"left":PolyValue("a", 0, 0, 1), "right":PolyValue("b", 0, 0, 1)}
    connect_source_port = PolyValue("", 1, 1, 16) # for sharing what type the selected source is
    midi_channel = PolyValue("channel", pedal_state["midi_channel"], 1, 16)
    input_level = PolyValue("input level", pedal_state["input_level"], -80, 10)
    preset_description = PolyValue("tap to write description", 0, 0, 1)
    debug_print("### Input level is", input_level.value)
    knobs.set_input_level(pedal_state["input_level"], write=False)
    pedal_bypassed = PolyBool(False)
    is_loading = PolyBool(False)
    foot_switch_warning = PolyBool(False)
    preset_meta_data = {}
    favourites = {}
    load_preset_meta_cache()
    load_favourites_data()

    patch_bay_notify = PatchBayNotify()

    available_effects = [QStringListModel() for i in range(4)]
    set_available_effects()
    engine = QQmlApplicationEngine()
    current_pedal_model = PolyValue(pedal_state["model"], 0, -1, 1)
    # accent_color = PolyValue("#8BB8E8", 0, -1, 1)
    accent_color = PolyValue("#FF75D0", 0, -1, 1)
    current_ip = PolyValue("", 0, -1, 1)

    # Expose the object to QML.
    # global context
    context = engine.rootContext()
    context.setContextProperty("knobs", knobs)
    change_pedal_model(pedal_state["model"], True)
    context.setContextProperty("available_effects", available_effects)
    context.setContextProperty("selectedSourceEffectPorts", selected_source_effect_ports)
    context.setContextProperty("selectedDestEffectPorts", selected_dest_effect_ports)
    context.setContextProperty("portConnections", port_connections)
    context.setContextProperty("effectPrototypes", effect_prototypes)
    context.setContextProperty("updateCounter", update_counter)
    context.setContextProperty("currentBPM", current_bpm)
    context.setContextProperty("dspLoad", dsp_load)
    context.setContextProperty("isPedalBypassed", pedal_bypassed)
    context.setContextProperty("currentPreset", current_preset)
    context.setContextProperty("commandStatus", command_status)
    context.setContextProperty("delayNumBars", delay_num_bars)
    context.setContextProperty("connectSourcePort", connect_source_port)
    context.setContextProperty("midiChannel", midi_channel)
    context.setContextProperty("isLoading", is_loading)
    context.setContextProperty("inputLevel", input_level)
    context.setContextProperty("currentPedalModel", current_pedal_model)
    context.setContextProperty("accent_color", accent_color)
    context.setContextProperty("presetList", preset_list_model)
    context.setContextProperty("footSwitchQA", foot_switch_qa)
    context.setContextProperty("encoderQA", encoder_qa)
    context.setContextProperty("footSwitchWarning", foot_switch_warning)
    context.setContextProperty("pedalboardDescription", preset_description)
    context.setContextProperty("patchBayNotify", patch_bay_notify)
    context.setContextProperty("presetMeta", preset_meta_data)
    context.setContextProperty("favourites", favourites)
    context.setContextProperty("pedalState", pedal_state)
    context.setContextProperty("currentIP", current_ip)
    engine.load(QUrl("qml/TopLevelWindow.qml"))
    debug_print("starting send thread")
    ingen_wrapper.start_send_thread()
    debug_print("starting recv thread")
    ingen_wrapper.start_recv_thread(ui_messages)

    pedal_hardware.foot_callback = handle_foot_change
    pedal_hardware.encoder_change_callback = handle_encoder_change
    pedal_hardware.add_hardware_listeners()
    knobs.launch_task(0.5, handle_MIDI_program_change)

    # qWarning("logging with qwarning")
    try:
        add_io()
    except Exception as e:
        debug_print("########## e1 is:", e)
        ex_type, ex_value, tb = sys.exc_info()
        error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
        debug_print("EXception is:", error)
        sys.exit()

    sys._excepthook = sys.excepthook
    def exception_hook(exctype, value, tb):
        debug_print("except hook got a thing!")
        traceback.print_exception(exctype, value, tb)
        sys._excepthook(exctype, value, tb)
        # sys.exit(1)
    sys.excepthook = exception_hook
    # try:
    # crash_here
    # except:
    #     debug_print("caught crash")
    # timer = QTimer()
    # timer.timeout.connect(tick)
    # timer.start(1000)

    def signalHandler(sig, frame):
        if sig in (SIGINT, SIGTERM):
            qWarning("frontend got signal")
            # global EXIT_PROCESS
            EXIT_PROCESS[0] = True
            ingen_wrapper._FINISH = True
            ingen_wrapper.ingen._FINISH = True
            pedal_hardware.EXIT_THREADS = True
            ingen_wrapper.ingen.sock.close()
    signal(SIGINT,  signalHandler)
    signal(SIGTERM, signalHandler)
    initial_preset = False
    debug_print("starting UI")
    # if current_pedal_model.name == "digit":
    #     load_preset("file:///mnt/presets/digit/Default_Preset.ingen/main.ttl", True, True)
    # elif current_pedal_model.name == "beebo":
    #     load_preset("file:///mnt/presets/beebo/Empty.ingen/main.ttl", True, True)
    time.sleep(0.2)
    ingen_wrapper.get_state("/main")
    # load_preset("file:///mnt/presets/Default_Preset.ingen/main.ttl", False)
    # ingen_wrapper._FINISH = True
    while not EXIT_PROCESS[0]:
        # debug_print("processing events")
        try:
            app.processEvents()
            # debug_print("processing ui messages")
            process_ui_messages()
            pedal_hardware.process_input()
        except Exception as e:
            qCritical("########## e2 is:"+ str(e))
            ex_type, ex_value, tb = sys.exc_info()
            error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
            debug_print("EXception is:", error)
            qCritical("########## exception is:"+ str(error))
            sys.exit()
        sleep(0.01)

    qWarning("mainloop exited")
    ingen_wrapper.s_thread.join()
    qWarning("s_thread exited")
    if pedal_hardware.hw_thread is not None:
        qWarning("hw_thread joining")
        pedal_hardware.hw_thread.join()
        qWarning("hw_thread exited")
    ingen_wrapper.r_thread.join()
    qWarning("r_thread exited")
    app.exit()
    sys.exit()
    qWarning("sys exit called")
        # if not initial_preset:
        #     load_preset("/presets/Default Preset.json")
        #     update_counter.value+=1
        #     initial_preset = True
