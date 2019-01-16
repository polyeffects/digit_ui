import sys
# import random
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot, QStringListModel
from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtGui import QIcon
# compiled QML files, compile with pyside2-rcc
import qml.qml
import icons.icons
#, imagine_assets
import resource_rc

def insert_row(model, row):
    j = len(model.stringList())
    model.insertRows(j, 1)
    model.setData(model.index(j), row)

class Knobs(QObject):
    """Output stuff on the console."""

    @Slot(str, str, 'double')
    def ui_knob_change(self, x, y, z):
        print(x, y, z)

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

model = QStringListModel()
model2 = QStringListModel()
if __name__ == "__main__":

    app = QGuiApplication(sys.argv)
    QIcon.setThemeName("digit")
    # Instantiate the Python object.
    knobs = Knobs()

    # t_list = QStringList()
    # t_list.append("a")
    # t_list.append("b")
    # t_list.append("c")
    model.setStringList(["aasdfasdf", "b", "c"])
    model2.setStringList(["fff", "ddd" "c"])

    engine = QQmlApplicationEngine()
    # Expose the object to QML.
    context = engine.rootContext()
    context.setContextProperty("knobs", knobs)
    context.setContextProperty("delay1_Left_Out_AvailablePorts", model)
    context.setContextProperty("delay1_Left_Out_UsedPorts", model2)
    # engine.load(QUrl("qrc:/qml/digit.qml"))
    engine.load(QUrl("qml/digit.qml"))
    app.exec_()
