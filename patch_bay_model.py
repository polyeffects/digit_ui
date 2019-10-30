# import sys
# import psutil

from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import QUrl, QTimer, QAbstractListModel

from PySide2.QtCore import QObject, Signal, Slot, Property, Qt

class PatchBayModel(QAbstractListModel):
    def __init__(self):
        QAbstractListModel.__init__(self)

        self.__effects_count = 3
        self.__effect_ids = [11, 22, 33, 44]

        # self.__update_timer = QTimer(self)
        # self.__update_timer.setInterval(1000)
        # self.__update_timer.timeout.connect(self.__update)
        # self.__update_timer.start()

        # The first call returns invalid data
        # psutil.cpu_percent(percpu=True)

    def __update(self):
        # self.__cpu_load = psutil.cpu_percent(percpu=True)
        self.dataChanged.emit(self.index(0,0), self.index(self.__effects_count-1, 0))

    def rowCount(self, parent):
        return self.__effects_count

    def data(self, index, role):
        if (role == Qt.DisplayRole and
            index.row() >= 0 and
            index.row() < len(self.__effect_ids) and
            index.column() == 0):
            return self.__effect_ids[index.row()]
        else:
            return None

