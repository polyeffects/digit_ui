# import sys
# # import random
# from PySide2.QtGui import QGuiApplication
# from PySide2.QtQuick import QQuickView
# from PySide2.QtCore import QObject, QUrl, Slot
# from PySide2.QtQml import QQmlApplicationEngine
# from PySide2.QtGui import QIcon
# # compiled QML files, compile with pyside2-rcc
# import qml.qml
# import icons.icons, imagine_assets
# import resource_rc



# class Knobs(QObject):
#     """Output stuff on the console."""

#     @Slot(str, 'double')
#     def ui_knob_change(self, x, y):
#         print(x, y)

# if __name__ == "__main__":

#     app = QGuiApplication([])
#     QIcon.setThemeName("digit")
#     # Instantiate the Python object.
#     knobs = Knobs()

#     engine = QQmlApplicationEngine()
#     # Expose the object to QML.
#     context = engine.rootContext()
#     context.setContextProperty("knobs", knobs)
#     # engine.load(QUrl("qrc:/qml/digit.qml"))
#     engine.load(QUrl("qml/digit.qml"))
#     app.exec_()
import sys

from PyQt5.QtCore import pyqtProperty, QCoreApplication, QObject, QUrl, pyqtSlot
from PyQt5.QtGui import QGuiApplication, QIcon

from PyQt5.QtQml import qmlRegisterType, QQmlComponent, QQmlEngine, QQmlApplicationEngine
import sys
# compiled QML files, compile with 
import qml.qml
import icons.icons, imagine_assets
import resource_rc



class Knobs(QObject):
    """Output stuff on the console."""

    # @Slot(str, 'double')
    @pyqtSlot(str, float)
    def ui_knob_change(self, x, y):
        print(x, y)

if __name__ == "__main__":

    app = QGuiApplication([])
    # app = QCoreApplication(sys.argv)
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


from PyQt5.QtWidgets import QApplication, QLabel
import sys
app = QApplication(sys.argv)
label = QLabel('Hello World!')
label.show()
app.exec_()

import sys
from PyQt5 import QtCore, QtWidgets
from PyQt5.QtWidgets import QMainWindow, QLabel, QGridLayout, QWidget
from PyQt5.QtCore import QSize    

class HelloWindow(QMainWindow):
    def __init__(self):
        QMainWindow.__init__(self)
        self.setMinimumSize(QSize(200, 200))    
        self.setWindowTitle("Hello world") 
        centralWidget = QWidget(self)          
        self.setCentralWidget(centralWidget)   
        gridLayout = QGridLayout(self)     
        centralWidget.setLayout(gridLayout)  
        title = QLabel("Hello World from PyQt", self) 
        title.setAlignment(QtCore.Qt.AlignCenter) 
        gridLayout.addWidget(title, 0, 0)

app = QtWidgets.QApplication(sys.argv)
mainWin = HelloWindow()
mainWin.show()
sys.exit( app.exec_() )
