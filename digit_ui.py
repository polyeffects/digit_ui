import sys, os
# import random
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal, QTimer
from PySide2.QtQml import QQmlApplicationEngine, QQmlDebuggingEnabler
from PySide2.QtGui import QIcon
# compiled QML files, compile with pyside2-rcc
import qml.qml
import icons.icons
#, imagine_assets
import resource_rc
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"

def insert_row(model, row):
    j = len(model.stringList())
    model.insertRows(j, 1)
    model.setData(model.index(j), row)

class Knobs(QObject):
    """Output stuff on the console."""
    def __init__(self):
        QObject.__init__(self)
        self.waitingval = ""

    @Slot(str, str, 'double')
    def ui_knob_change(self, effect_name, parameter, value):
        print("knob change")
        effect_parameter_data[effect_name][parameter].value = value

    @Slot(str)
    def ui_add_connection(self, x):
        i = model.stringList().index(x)
        model.removeRows(i, 1)
        j = len(model2.stringList())
        model2.insertRows(j, 1)
        model2.setData(model2.index(j), x)
        print(x)

    @Slot(str)
    def ui_remove_connection(self, x):
        i = model.stringList().index(x)
        model.removeRows(i, 1)
        print(x)

    @Slot(str)
    def toggle_enabled(self, x):
        print(x)

    @Slot(str, str)
    def map_parameter(self, effect_name, parameter):
        # set_knob_current_effect(self.waiting, effect_name, parameter)
        self.waiting = ""

    @Slot(str)
    def set_waiting(self, knob):
        print("waiting", knob)
        self.waiting = knob

    def readWaiting(self):
        return self.waitingval

    def setWaiting(self,val):
        self.waitingval = val
        self.waiting_changed.emit()

    @Signal
    def waiting_changed(self):
        pass

    waiting = Property(str, readWaiting, setWaiting, notify=waiting_changed)


class PolyValue(QObject):
    # name, min, max, value
    def __init__(self, startname="", startval=0, startmin=0, startmax=1, curve_type="lin"):
        QObject.__init__(self)
        self.nameval = startname
        self.valueval = startval
        self.rminval = startmin
        self.rmax = startmax

    def readValue(self):
        return self.valueval

    def setValue(self,val):
        self.valueval = val
        self.value_changed.emit()
        print("setting value", val)

    @Signal
    def value_changed(self):
        pass

    value = Property(float, readValue, setValue, notify=value_changed)

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

obj = {"delay1": PolyValue()}
obj["delay1"].value = 47

print(obj["delay1"].value)

model = QStringListModel()
model2 = QStringListModel()

def tick():
    print("tick")
    # app.quit()
    if obj["delay1"].value < 100:
        obj["delay1"].value += 1
    else:
        obj["delay1"].value = 0

lfos = []

for n in range(4):
    lfos.append({})
    lfos[n]["num_points"] = PolyValue("num_points", 1, 1, 16)
    lfos[n]["channel"] = PolyValue("channel", 1, 1, 16)
    lfos[n]["cc_num"] = PolyValue("cc_num", 102+n, 0, 127)
    for i in range(1,17):
        lfos[n]["time"+str(i)] = PolyValue("time"+str(i), 0, 0, 1)
        lfos[n]["value"+str(i)] = PolyValue("value"+str(i), 0, 0, 1)
        lfos[n]["style"+str(i)] = PolyValue("style"+str(i), 0, 0, 5)

effect_parameter_data = {"delay1": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
        "Delay_1" : PolyValue("Delay_1", 0.500000, 0.001000, 16.000000),
        "Warp_2" : PolyValue("Warp_2", 0.000000, -1.000000, 1.000000),
        "DelayT60_3" : PolyValue("DelayT60_3", 0.500000, 0.000000, 100.000000),
        "Feedback_4" : PolyValue("Feedback_4", 0.300000, 0.000000, 1.000000),
        "Amp_5" : PolyValue("Amp_5", 0.500000, 0.000000, 1.000000),
        "FeedbackSm_6" : PolyValue("FeedbackSm_6", 0.000000, 0.000000, 1.000000),
        "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
        "carla_level": PolyValue("level", 1, 0, 1)},
    "delay2": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
            "Delay_1" : PolyValue("Delay_1", 0.500000, 0.001000, 16.000000),
            "Warp_2" : PolyValue("Warp_2", 0.000000, -1.000000, 1.000000),
            "DelayT60_3" : PolyValue("DelayT60_3", 0.500000, 0.000000, 100.000000),
            "Feedback_4" : PolyValue("Feedback_4", 0.300000, 0.000000, 1.000000),
            "Amp_5" : PolyValue("Amp_5", 0.500000, 0.000000, 1.000000),
            "FeedbackSm_6" : PolyValue("FeedbackSm_6", 0.000000, 0.000000, 1.000000),
            "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
            "carla_level": PolyValue("level", 1, 0, 1)},
    "delay3": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
            "Delay_1" : PolyValue("Delay_1", 0.500000, 0.001000, 16.000000),
            "Warp_2" : PolyValue("Warp_2", 0.000000, -1.000000, 1.000000),
            "DelayT60_3" : PolyValue("DelayT60_3", 0.500000, 0.000000, 100.000000),
            "Feedback_4" : PolyValue("Feedback_4", 0.300000, 0.000000, 1.000000),
            "Amp_5" : PolyValue("Amp_5", 0.500000, 0.000000, 1.000000),
            "FeedbackSm_6" : PolyValue("FeedbackSm_6", 0.000000, 0.000000, 1.000000),
            "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
            "carla_level": PolyValue("level", 1, 0, 1)},
    "delay4": {"BPM_0" : PolyValue("BPM_0", 120.000000, 30.000000, 300.000000),
            "Delay_1" : PolyValue("Delay_1", 0.500000, 0.001000, 16.000000),
            "Warp_2" : PolyValue("Warp_2", 0.000000, -1.000000, 1.000000),
            "DelayT60_3" : PolyValue("DelayT60_3", 0.500000, 0.000000, 100.000000),
            "Feedback_4" : PolyValue("Feedback_4", 0.300000, 0.000000, 1.000000),
            "Amp_5" : PolyValue("Amp_5", 0.500000, 0.000000, 1.000000),
            "FeedbackSm_6" : PolyValue("FeedbackSm_6", 0.000000, 0.000000, 1.000000),
            "EnableEcho_7" : PolyValue("EnableEcho_7", 1.000000, 0.000000, 1.000000),
            "carla_level": PolyValue("level", 1, 0, 1)},
    "reverb": {"gain": PolyValue("mix", 0, -24, 24), "ir": PolyValue("/audio/reverbs/emt_140_dark_1.wav", 0, 0, 1),
        "carla_level": PolyValue("level", 1, 0, 1)},
    "mixer": {"mix_1_1": PolyValue("mix 1,1", 0, 0, 1), "mix_1_2": PolyValue("mix 1,2", 0, 0, 1),
        "mix_1_3": PolyValue("mix 1,3", 0, 0, 1),"mix_1_4": PolyValue("mix 1,4", 0, 0, 1),
        "mix_2_1": PolyValue("mix 2,1", 0, 0, 1),"mix_2_2": PolyValue("mix 2,2", 0, 0, 1),
        "mix_2_3": PolyValue("mix 2,3", 0, 0, 1),"mix_2_4": PolyValue("mix 2,4", 0, 0, 1),
        "mix_3_1": PolyValue("mix 3,1", 0, 0, 1),"mix_3_2": PolyValue("mix 3,2", 0, 0, 1),
        "mix_3_3": PolyValue("mix 3,3", 0, 0, 1),"mix_3_4": PolyValue("mix 3,4", 0, 0, 1),
        "mix_4_1": PolyValue("mix 4,1", 0, 0, 1),"mix_4_2": PolyValue("mix 4,2", 0, 0, 1),
        "mix_4_3": PolyValue("mix 4,3", 0, 0, 1),"mix_4_4": PolyValue("mix 4,4", 0, 0, 1)
        },
    "tape1": {"drive": PolyValue("drive", 5, 0, 10), "blend": PolyValue("tape vs tube", 10, -10, 10)},
    "filter1": {"freq": PolyValue("cutoff", 440, 20, 15000, "log"), "res": PolyValue("resonance", 0, 0, 0.8)},
    "sigmoid1": {"Pregain": PolyValue("pre gain", 0, -90, 20), "Postgain": PolyValue("post gain", 0, -90, 20)},
    "reverse1": {"fragment": PolyValue("fragment", 1000, 100, 1600),
        "wet": PolyValue("wet", 0, -90, 20),
        "dry": PolyValue("dry", 0, -90, 20)},
    "reverse2": {"fragment": PolyValue("fragment", 1000, 100, 1600),
        "wet": PolyValue("wet", 0, -90, 20),
        "dry": PolyValue("dry", 0, -90, 20)},
    "eq2": {
        "enable": PolyValue("Enable", 1.000000, 0.000000, 1.0),
        "gain": PolyValue("Gain", 0.000000, -18.000000, 18.000000),
        "HighPass": PolyValue("Highpass", 0.000000, 0.000000, 1.000000),
        "HPfreq": PolyValue("Highpass Frequency", 20.000000, 5.000000, 1250.000000),
        "HPQ": PolyValue("HighPass Resonance", 0.700000, 0.000000, 1.400000),
        "LowPass": PolyValue("Lowpass", 0.000000, 0.000000, 1.000000),
        "LPfreq": PolyValue("Lowpass Frequency", 20000.000000, 500.000000, 20000.000000),
        "LPQ": PolyValue("LowPass Resonance", 1.000000, 0.000000, 1.400000),
        "LSsec": PolyValue("Lowshelf", 1.000000, 0.000000, 1.000000),
        "LSfreq": PolyValue("Lowshelf Frequency", 80.000000, 25.000000, 400.000000),
        "LSq": PolyValue("Lowshelf Bandwidth", 1.000000, 0.062500, 4.000000),
        "LSgain": PolyValue("Lowshelf Gain", 0.000000, -18.000000, 18.000000),
        "sec1": PolyValue("Section 1", 1.000000, 0.000000, 1.000000),
        "freq1": PolyValue("Frequency 1", 160.000000, 20.000000, 2000.000000),
        "q1": PolyValue("Bandwidth 1", 0.600000, 0.062500, 4.000000),
        "gain1": PolyValue("Gain 1", 0.000000, -18.000000, 18.000000),
        "sec2": PolyValue("Section 2", 1.000000, 0.000000, 1.000000),
        "freq2": PolyValue("Frequency 2", 397.000000, 40.000000, 4000.000000),
        "q2": PolyValue("Bandwidth 2", 0.600000, 0.062500, 4.000000),
        "gain2": PolyValue("Gain 2", 0.000000, -18.000000, 18.000000),
        "sec3": PolyValue("Section 3", 1.000000, 0.000000, 1.000000),
        "freq3": PolyValue("Frequency 3", 1250.000000, 100.000000, 10000.000000),
        "q3": PolyValue("Bandwidth 3", 0.600000, 0.062500, 4.000000),
        "gain3": PolyValue("Gain 3", 0.000000, -18.000000, 18.000000),
        "sec4": PolyValue("Section 4", 1.000000, 0.000000, 1.000000),
        "freq4": PolyValue("Frequency 4", 2500.000000, 200.000000, 20000.000000),
        "q4": PolyValue("Bandwidth 4", 0.600000, 0.062500, 4.000000),
        "gain4": PolyValue("Gain 4", 0.000000, -18.000000, 18.000000),
        "HSsec": PolyValue("Highshelf", 1.000000, 0.000000, 1.000000),
        "HSfreq": PolyValue("Highshelf Frequency", 8000.000000, 1000.000000, 16000.000000),
        "HSq": PolyValue("Highshelf Bandwidth", 1.000000, 0.062500, 4.000000),
        "HSgain": PolyValue("Highshelf Gain", 0.000000, -18.000000, 18.000000)},
    "cab": {"gain": PolyValue("gain", 0, -24, 24), "ir": PolyValue("/audio/cabs/1x12cab.wav", 0, 0, 1),
        "carla_level": PolyValue("level", 1, 0, 1)},
    "lfo1": lfos[0],
    "lfo2": lfos[1],
    "lfo3": lfos[2],
    "lfo4": lfos[3]
    }

app = QGuiApplication(sys.argv)
def main_ui():
    # d = QQmlDebuggingEnabler()
    # d.startTcpDebugServer(3768)
    QIcon.setThemeName("digit")
    # Instantiate the Python object.
    knobs = Knobs()
    current_bpm = PolyValue("BPM", 120, 30, 250) # bit of a hack
    current_preset = PolyValue("Default Preset", 0, 0, 1)
    update_counter = PolyValue("update counter", 0, 0, 100000)
    delay_num_bars = PolyValue("Num bars", 1, 1, 16)

    # t_list = QStringList()
    # t_list.append("a")
    # t_list.append("b")
    # t_list.append("c")
    # model.setStringList(["aasdfasdf", "b", "c"])
    # model2.setStringList(["fff", "ddd" "c"])

    engine = QQmlApplicationEngine()
    # Expose the object to QML.
    context = engine.rootContext()
    context.setContextProperty("knobs", knobs)
    context.setContextProperty("param_vals", obj)
    context.setContextProperty("delay1_Left_Out_AvailablePorts", model)
    context.setContextProperty("delay1_Left_Out_UsedPorts", model2)
    context.setContextProperty("currentBPM", current_bpm)
    context.setContextProperty("currentPreset", current_preset)
    context.setContextProperty("polyValues", effect_parameter_data)
    context.setContextProperty("updateCounter", update_counter)
    context.setContextProperty("delayNumBars", delay_num_bars)
    # engine.load(QUrl("qrc:/qml/digit.qml"))
    engine.load(QUrl("qml/digit.qml"))

    timer = QTimer()
    timer.timeout.connect(tick)
    timer.start(2000)

    app.exec_()

if __name__ == "__main__":
    # import cProfile
    # cProfile.run('main_ui()')
    main_ui()
