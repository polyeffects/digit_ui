import sys, os
from collections import OrderedDict
# import random
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel, Property, Signal, QTimer
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtGui import QIcon
# # compiled QML files, compile with pyside2-rcc
# import qml.qml
os.environ["QT_IM_MODULE"] = "qtvirtualkeyboard"
import icons.icons
# #, imagine_assets
import resource_rc

import patch_bay_model

# def insert_row(model, row):
#     j = len(model.stringList())
#     model.insertRows(j, 1)
#     model.setData(model.index(j), row)
current_source_port = None
current_effects = OrderedDict()
current_effects["delay1"] = {"x": 20, "y": 30, "effect_type": "delay", "controls": {}, "highlight": False}
current_effects["delay2"] = {"x": 250, "y": 290, "effect_type": "delay", "controls": {}, "highlight": False}
port_connections = {} # key is port, value is list of ports

context = None

patch_bay_model.local_effects = current_effects
    # effect = {"parameters", "inputs", "outputs", "effect_type", "id", "x", "y"}
effect_prototypes ={"delay": {"inputs": {"in0": "AudioPort"},
    "outputs": {"out1": "AudioPort", "out2a": "AudioPort"},
    "controls": {"BPM_0" : ("BPM_0", 120.000000, 30.000000, 300.000000),
        "Delay_1" : ("Time", 0.500000, 0.001000, 4.000000),
        "Warp_2" : ("Warp", 0.000000, -1.000000, 1.000000),
        "DelayT60_3" : ("Glide", 0.500000, 0.000000, 100.000000),
        "Feedback_4" : ("Feedback", 0.300000, 0.000000, 1.000000),
        "Amp_5" : ("Level", 0.500000, 0.000000, 1.000000),
        "FeedbackSm_6" : ("Tone", 0.000000, 0.000000, 1.000000),
        "EnableEcho_7" : ("EnableEcho_7", 1.000000, 0.000000, 1.000000),
        "carla_level": ("level", 1, 0, 1)}
    },
}

selected_effect_ports = QStringListModel()
selected_effect_ports.setStringList(["val1", "val2"])

def add_new_effect(effect_name):
    # calls backend to actually add
    # add effect_parameter_data for all parameters / ports
    
    pass

def generate_current_arcs():
    # return x,y pairs for each arc and colour
    # for source in port_connections:
    #     a.
    pass

class Knobs(QObject):
    @Slot(bool, str, str)
    def set_current_port(self, is_source, effect_id, port_name):
        print("port name is", port_name)
        # if source highlight targets
        if is_source:
            # set current source port
            # effect_id, port_name
            # highlight effects given source port
            global current_source_port
            current_source_port = ":".join((effect_id, port_name))
            for id, effect in current_effects.items():
                effect["highlight"] = False
                if id != effect_id:
                    for input_port, style in effect_prototypes[effect["effect_type"]]["inputs"].items():
                        if style == effect_prototypes[current_effects[effect_id]["effect_type"]]["outputs"][port_name]:
                            # highlight and break
                            effect["highlight"] = True
                            break
        else:
            # if target disable highlight
            for id, effect in current_effects.items():
                effect["highlight"] = False
            # add connection between source and target
            # or just wait until it's automatically created from engine? 
            if current_source_port not in port_connections:
                port_connections[current_source_port] = []

            port_connections[current_source_port].append((effect_id, port_name))
            print("port_connections is", port_connections)
            # global context
            context.setContextProperty("portConnections", port_connections)


    @Slot(bool, str)
    def select_effect(self, is_source, effect_id):
        effect_type = current_effects[effect_id]["effect_type"]
        print("selecting effect type", effect_type)
        if is_source:
            selected_effect_ports.setStringList(list(effect_prototypes[effect_type]["outputs"].keys()))
        else:
            selected_effect_ports.setStringList(list(effect_prototypes[effect_type]["inputs"].keys()))

#     @Slot(str)
#     def ui_add_connection(self, x):
#         i = model.stringList().index(x)
#         model.removeRows(i, 1)
#         j = len(model2.stringList())
#         model2.insertRows(j, 1)
#         model2.setData(model2.index(j), x)
#         print(x)

#     @Slot(str)
#     def ui_remove_connection(self, x):
#         i = model.stringList().index(x)
#         model.removeRows(i, 1)
#         print(x)

#     @Slot(str)
#     def toggle_enabled(self, x):
#         print(x)


# class PolyValue(QObject):
#     # name, min, max, value
#     def __init__(self, startname="", startval=0, startmin=0, startmax=1, curve_type="lin"):
#         QObject.__init__(self)
#         self.nameval = startname
#         self.valueval = startval
#         self.rminval = startmin
#         self.rmax = startmax

#     def readValue(self):
#         return self.valueval

#     def setValue(self,val):
#         self.valueval = val
#         self.value_changed.emit()
#         print("setting value", val)

#     @Signal
#     def value_changed(self):
#         pass

#     value = Property(int, readValue, setValue, notify=value_changed)

#     def readName(self):
#         return self.nameval

#     def setName(self,val):
#         self.nameval = val
#         self.name_changed.emit()

#     @Signal
#     def name_changed(self):
#         pass

#     name = Property(str, readName, setName, notify=name_changed)

#     def readRMin(self):
#         return self.rminval

#     def setRMin(self,val):
#         self.rminval = val
#         self.rmin_changed.emit()

#     @Signal
#     def rmin_changed(self):
#         pass

#     rmin = Property(int, readRMin, setRMin, notify=rmin_changed)

#     def readRMax(self):
#         return self.rmaxval

#     def setRMax(self,val):
#         self.rmaxval = val
#         self.rmax_changed.emit()

#     @Signal
#     def rmax_changed(self):
#         pass

#     rmax = Property(int, readRMax, setRMax, notify=rmax_changed)

# obj = {"delay1": PolyValue()}
# obj["delay1"].value = 47

# print(obj["delay1"].value)

# model = QStringListModel()
# model2 = QStringListModel()

# def tick():
#     print("tick")
#     if obj["delay1"].value < 100:
#         obj["delay1"].value += 1
#     else:
#         obj["delay1"].value = 0

if __name__ == "__main__":

    app = QGuiApplication(sys.argv)
    QIcon.setThemeName("digit")
    # Instantiate the Python object.
    knobs = Knobs()

    # t_list = QStringList()
    # t_list.append("a")
    # t_list.append("b")
    # t_list.append("c")
    # model.setStringList(["aasdfasdf", "b", "c"])
    # model2.setStringList(["fff", "ddd" "c"])

    available_effects = QStringListModel()
    available_effects.setStringList(["delay", "mono reverb", "stereo reverb", "mono EQ", "stereo EQ", "cab", "reverse", 
        "filter", "compressor", "bit crusher", "tape/tube", "mixer"])
    engine = QQmlApplicationEngine()

    qmlRegisterType(patch_bay_model.PatchBayModel, 'Poly', 1, 0, 'PatchBayModel')
    # Expose the object to QML.
    # global context
    context = engine.rootContext()
    context.setContextProperty("knobs", knobs)
    # context.setContextProperty("param_vals", obj)
    # context.setContextProperty("delay1_Left_Out_AvailablePorts", model)
    context.setContextProperty("available_effects", available_effects)
    context.setContextProperty("selectedEffectPorts", selected_effect_ports)
    context.setContextProperty("portConnections", port_connections)
    # engine.load(QUrl("qrc:/qml/digit.qml"))
    engine.load(QUrl("qml/TestWrapper.qml"))

    # timer = QTimer()
    # timer.timeout.connect(tick)
    # timer.start(1000)

    app.exec_()
