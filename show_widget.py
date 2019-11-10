import sys, os
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

from patch_bay_model import PatchBayModel

# def insert_row(model, row):
#     j = len(model.stringList())
#     model.insertRows(j, 1)
#     model.setData(model.index(j), row)

# class Knobs(QObject):
#     """Output stuff on the console."""

#     @Slot(str, str, 'double')
#     def ui_knob_change(self, x, y, z):
#         obj["delay1"].value = z
#         print(x, y, z)

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
    # knobs = Knobs()

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

    qmlRegisterType(PatchBayModel, 'Poly', 1, 0, 'PatchBayModel')
    # Expose the object to QML.
    context = engine.rootContext()
    # context.setContextProperty("knobs", knobs)
    # context.setContextProperty("param_vals", obj)
    # context.setContextProperty("delay1_Left_Out_AvailablePorts", model)
    context.setContextProperty("available_effects", available_effects)
    # engine.load(QUrl("qrc:/qml/digit.qml"))
    engine.load(QUrl("qml/TestWrapper.qml"))

    # timer = QTimer()
    # timer.timeout.connect(tick)
    # timer.start(1000)

    app.exec_()
