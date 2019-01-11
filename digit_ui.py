import sys
# import random
from PySide2.QtGui import QGuiApplication
from PySide2.QtCore import QObject, QUrl, Slot
from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtGui import QIcon
# compiled QML files, compile with pyside2-rcc
import qml.qml
import icons.icons, imagine_assets
import resource_rc



class Knobs(QObject):
    """Output stuff on the console."""

    @Slot(str, str, 'double')
    def ui_knob_change(self, x, y, z):
        print(x, y, z)

if __name__ == "__main__":

    app = QGuiApplication(sys.argv)
    QIcon.setThemeName("digit")
    # Instantiate the Python object.
    knobs = Knobs()

    engine = QQmlApplicationEngine()
    # Expose the object to QML.
    context = engine.rootContext()
    context.setContextProperty("knobs", knobs)
    # engine.load(QUrl("qrc:/qml/digit.qml"))
    engine.load(QUrl("qml/digit.qml"))
    app.exec_()
