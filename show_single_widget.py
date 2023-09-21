import sys, time, json, os.path, os, subprocess, queue, threading, traceback
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
from signal import signal, SIGINT, SIGTERM
from time import sleep
from sys import exit
from collections import OrderedDict
# import random
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal, QTimer, QThreadPool, QRunnable
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtGui import QIcon, QFontDatabase, QFont
# # compiled QML files, compile with pyside2-rcc
# import qml.qml

os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
import icons.icons
# #, imagine_assets
import resource_rc
import module_info
import properties

#import loopler as loopler_lib

EXIT_PROCESS = [False]
import module_browser_model
import amp_browser_model
import ir_browser_model


current_source_port = None
# current_effects = OrderedDict()
port_connections = {} # key is port, value is list of ports

context = None

def clamp(v, min_value, max_value):
    return max(min(v, max_value), min_value)

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

def du(path):
    """disk usage in human readable format (e.g. '2,1GB')"""
    return subprocess.check_output(['du','-sh', path]).split()[0].decode('utf-8')

class Knobs(QObject, metaclass=properties.PropertyMeta):
    spotlight_entries = properties.Property(list)

    def __init__(self, parent=None):
        super().__init__(parent)
        self.spotlight_entries = []

    @Slot(str, str, 'double')
    def ui_knob_change(self, effect_name, parameter, value):
        # debug_print(x, y, z)
        if (effect_name in current_effects) and (parameter in current_effects[effect_name]["controls"]):
            current_effects[effect_name]["controls"][parameter].value = value
            # clamping here to make it a bit more obvious
            value = clamp(value, current_effects[effect_name]["controls"][parameter].rmin, current_effects[effect_name]["controls"][parameter].rmax)

    @Slot(str, result=str)
    def ui_usb_folder_size(self, folder):
        # return how large a USB folder is in mb, just du the folder, will give us an approx idea of what will be copied
        return du(folder)

    @Slot(result=str)
    def remaining_user_storage(self):
        # return how much space in mb is available
        return subprocess.check_output(['df','-h', '--output=avail', '/dev/mmcblk0p2']).split()[1].decode('utf-8')

current_effects = {}
# current_effects["delay1"] = {"x": 20, "y": 30, "effect_type": "delay", "controls": {}, "highlight": False}
effect_prototypes = module_info.effect_prototypes_models_all
effect_name = "strum1"
effect_type = "strum"
broadcast_ports = {}
if "broadcast_ports" in effect_prototypes[effect_type]:
    broadcast_ports = {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["broadcast_ports"].items()}
current_effects[effect_name] = {"x": 50, "y": 50, "effect_type": effect_type,
        "controls": {k : PolyValue(*v) for k,v in effect_prototypes[effect_type]["controls"].items()},
        "assigned_footswitch": PolyStr(""),
        "broadcast_ports" : broadcast_ports,
        "enabled": PolyBool(True)}

if __name__ == "__main__":

    print("in Main")
    app = QGuiApplication(sys.argv)
    QIcon.setThemeName("digit")
    QFontDatabase.addApplicationFont("qml/fonts/BarlowSemiCondensed-SemiBold.ttf")
    font = QFont("BarlowSemiCondensed", 20, QFont.DemiBold)
    app.setFont(font)
    # Instantiate the Python object.
    knobs = Knobs()
    module_browser_model_s = module_browser_model.ModuleBrowserModel({"modules": [], "presets": []})
    amp_browser_model_s = amp_browser_model.AmpBrowserModel({"nam": [], "amp": []}, knobs)
    # ir_browser_model_s = ir_browser_model.irBrowserModel({"reverbs": [], "cabs": []}, knobs)
    #loopler = loopler_lib.Loopler()
    #loopler.start_loopler()

    # update_counter = PolyValue("update counter", 0, 0, 500000)
    # read persistant state
    # pedal_state = {}
    # with open("/pedal_state/state.json") as f:
    #     pedal_state = json.load(f)
    # current_bpm = PolyValue("BPM", 120, 30, 250) # bit of a hack
    # current_preset = PolyValue("Default Preset", 0, 0, 127)
    # update_counter = PolyValue("update counter", 0, 0, 500000)
    # command_status = [PolyValue("command status", -1, -10, 100000), PolyValue("command status", -1, -10, 100000)]
    # delay_num_bars = PolyValue("Num bars", 1, 1, 16)
    # midi_channel = PolyValue("channel", pedal_state["midi_channel"], 1, 16)
    # input_level = PolyValue("input level", pedal_state["input_level"], -80, 10)
    # knobs.set_input_level(pedal_state["input_level"], write=False)

    # available_effects = QStringListModel()
    # available_effects.setStringList(list(effect_type_map.keys()))
    engine = QQmlApplicationEngine()

    # qmlRegisterType(patch_bay_model.PatchBayModel, 'Poly', 1, 0, 'PatchBayModel')
    # Expose the object to QML.
    # global context

    qmlRegisterType(ir_browser_model.irBrowserModel, "ir_browser_module", 1, 0, "IrBrowserModel")
    context = engine.rootContext()

    accent_color = PolyValue("#FFA0E0", 0, -1, 1)
    current_pedal_model = PolyValue("beebo", 0, -1, 1)
    # context.setContextProperty("loopler", loopler)
    context.setContextProperty("module_browser_model", module_browser_model_s)
    context.setContextProperty("amp_browser_model", amp_browser_model_s)
    # context.setContextProperty("ir_browser_model", ir_browser_model_s)
    context.setContextProperty("accent_color", accent_color)
    context.setContextProperty("currentPedalModel", current_pedal_model)
    context.setContextProperty("currentEffects", current_effects) 
    context.setContextProperty("knobs", knobs)
    # context.setContextProperty("available_effects", available_effects)
    # context.setContextProperty("selectedEffectPorts", selected_effect_ports)
    # context.setContextProperty("portConnections", port_connections)
    # context.setContextProperty("effectPrototypes", effect_prototypes)
    # context.setContextProperty("updateCounter", update_counter)
    # context.setContextProperty("currentBPM", current_bpm)
    # # context.setContextProperty("pluginState", plugin_state)
    # context.setContextProperty("currentPreset", current_preset)
    # context.setContextProperty("commandStatus", command_status)
    # context.setContextProperty("delayNumBars", delay_num_bars)
    # context.setContextProperty("midiChannel", midi_channel)
    # context.setContextProperty("isLoading", is_loading)
    # # context.setContextProperty("inputLevel", input_level)
    # context.setContextProperty("presetList", preset_list_model)
    # print("starting recv thread")
    engine.load(QUrl("qml/TestWrapper.qml"))
    # ingen_wrapper.start_recv_thread(ui_messages)
    # print("starting send thread")
    # ingen_wrapper.start_send_thread()
    # try:
    #     add_io()
    # except Exception as e:
    #     print("########## e is:", e)
    #     ex_type, ex_value, tb = sys.exc_info()
    #     error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
    #     print("EXception is:", error)
    #     sys.exit()

    # sys._excepthook = sys.excepthook
    # def exception_hook(exctype, value, traceback):
    #     print("except hook got a thing!")
    #     sys._excepthook(exctype, value, traceback)
    #     sys.exit(1)
    # sys.excepthook = exception_hook
    # try:
    # crash_here
    # except:
    #     print("caught crash")
    # timer = QTimer()
    # timer.timeout.connect(tick)
    # timer.start(1000)

    def signalHandler(sig, frame):
        if sig in (SIGINT, SIGTERM):
            # print("frontend got signal")
            # global EXIT_PROCESS
            EXIT_PROCESS[0] = True
            # ingen_wrapper._FINISH = True
    signal(SIGINT,  signalHandler)
    signal(SIGTERM, signalHandler)
    # initial_preset = False
    print("starting UI")
    while not EXIT_PROCESS[0]:
        # debug_print("processing events")
        try:
            app.processEvents()
            # debug_print("processing ui messages")
        except Exception as e:
            qCritical("########## e is:"+ str(e))
            ex_type, ex_value, tb = sys.exc_info()
            error = ex_type, ex_value, ''.join(traceback.format_tb(tb))
            # debug_print("EXception is:", error)
            sys.exit()
        sleep(0.01)

    qWarning("mainloop exited")
    # loopler.stop_loopler()
    app.exit()
    sys.exit()
    qWarning("sys exit called")

"""
from dooper import LooperThread
l_thread = LooperThread()
l_thread.start_server()
l_thread.verbose = True




path: </learn_midi_binding>
arg 0 's' "0 cc 0  set wet 0  0 1  gain 0 127"
arg 1 's' "exclusive"
arg 2 's' "osc.udp://127.0.0.1:11642/"
arg 3 's' "/recv_midi_bindings"

path: </learn_midi_binding>
arg 0 's' "0 cc 0  set feedback 0  0 1  norm 0 127"
arg 1 's' "exclusive"
arg 2 's' "osc.udp://127.0.0.1:11642/"
arg 3 's' "/recv_midi_bindings"

path: </learn_midi_binding>
arg 0 's' "0 n 2013629443  note overdub 0  0 1  norm 0 127"
arg 1 's' "exclusive"
arg 2 's' "osc.udp://127.0.0.1:11642/"
arg 3 's' "/recv_midi_bindings"

path: </learn_midi_binding>
arg 0 's' "0 n 2013573580  set rate 0  1 1  norm 0 127"
arg 1 's' "exclusive"
arg 2 's' "osc.udp://127.0.0.1:11642/"
arg 3 's' "/recv_midi_bindings"

path: </save_session>
arg 0 's' "/git_repos/PolyDigit/debugging/test1_sl.slsess"
arg 1 's' "osc.udp://127.0.0.1:18928/"
arg 2 's' "/error"

path: </load_session>
arg 0 's' "/git_repos/PolyDigit/debugging/test1_sl.slsess"
arg 1 's' "osc.udp://127.0.0.1:18928/"
arg 2 's' "/error"



"""

