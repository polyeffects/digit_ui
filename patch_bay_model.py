# import sys
# import psutil

from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import QUrl, QTimer, QAbstractListModel, QModelIndex

from PySide2.QtCore import QObject, Signal, Slot, Property, Qt

"""
connections and nodes.
"""

class PatchBayModel(QAbstractListModel):
    def __init__(self):
        QAbstractListModel.__init__(self)

        # self.__effects_count = 3
        self.__effect_ids = [11, 22, 33, 44]

        # self.__update_timer = QTimer(self)
        # self.__update_timer.setInterval(1000)
        # self.__update_timer.timeout.connect(self.__update)
        # self.__update_timer.start()

        # The first call returns invalid data
        # psutil.cpu_percent(percpu=True)

    @Slot(str)
    def add_effect(self, effect_name):
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
        self.__effect_ids.append(self.__effect_ids[-1]+1) # temp get real IDs
        print(effect_name, " added.")
        self.endInsertRows()

    @Slot(int)
    def remove_effect(self, effect_id):
        current_row = self.__effect_ids.index(effect_id)
        self.beginRemoveRows(QModelIndex(), current_row, current_row)
        self.__effect_ids.pop(current_row)
        self.endRemoveRows()
        print(effect_id, " removed.")

    def __update(self):
        # self.__cpu_load = psutil.cpu_percent(percpu=True)
        self.dataChanged.emit(self.index(0,0), self.index(len(self.__effect_ids)-1, 0))

    def rowCount(self, parent=None):
        # return self.__effects_count
        return len(self.__effect_ids)

    def data(self, index, role):
        if (role == Qt.DisplayRole and
            index.row() >= 0 and
            index.row() < len(self.__effect_ids) and
            index.column() == 0):
            print("getting data", index, role)
            return self.__effect_ids[index.row()]
        else:
            print("getting data", index, role)
            return None

