# import sys
# import psutil

from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import QUrl, QTimer, QAbstractListModel, QModelIndex

from PySide2.QtCore import QObject, Signal, Slot, Property, Qt

"""
connections and nodes.

needs: effect type, effect_id, is_highlighted, x, y
"""
local_effects = None
patch_bay_singleton = None

class PatchBayModel(QAbstractListModel):

    EffectID = Qt.UserRole + 0
    EffectType = Qt.UserRole + 1
    IsHighlighted = Qt.UserRole + 2
    X = Qt.UserRole + 3
    Y = Qt.UserRole + 4

    def __init__(self):
        QAbstractListModel.__init__(self)

        # self.__effects_count = 3
        self.__effect_ids = local_effects.keys()
        self.__order = dict(enumerate(local_effects.keys()))
        global patch_bay_singleton
        patch_bay_singleton = self

        # self.__update_timer = QTimer(self)
        # self.__update_timer.setInterval(1000)
        # self.__update_timer.timeout.connect(self.__update)
        # self.__update_timer.start()

        # The first call returns invalid data
        # psutil.cpu_percent(percpu=True)

    def startInsert(self):
        print("start insert")
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())

    def endInsert(self):
        print("end insert")
        self.__order = dict(enumerate(local_effects.keys()))
        self.endInsertRows()

    def startRemove(self, effect_id):
        current_row = list(local_effects.keys()).index(effect_id)
        self.beginRemoveRows(QModelIndex(), current_row, current_row)
        print(effect_id, " removing.")

    def endRemove(self):
        self.endRemoveRows()

    @Slot()
    def items_changed(self):
        # self.__cpu_load = psutil.cpu_percent(percpu=True)
        self.dataChanged.emit(self.index(0,0), self.index(len(local_effects)-1, 0))

    @Slot()
    def item_changed(self, effect_id):
        current_row = list(local_effects.keys()).index(effect_id)
        # self.__cpu_load = psutil.cpu_percent(percpu=True)
        self.dataChanged.emit(self.index(current_row,0), self.index(current_row, 0))

    def rowCount(self, parent=None):
        # return self.__effects_count
        return len(local_effects)

    def data(self, index, role):
        if not index.isValid():
            return QVariant()
        row = index.row()
        if 0 <= row < self.rowCount():
            # print("getting role", role, local_effects)
            if role == PatchBayModel.EffectID:
                # print("getting effectID", local_effects[self.__order[index.row()]])
                return self.__order[index.row()]
            elif role == PatchBayModel.EffectType:
                # print("getting effectType")
                return local_effects[self.__order[index.row()]]["effect_type"]
            elif role == PatchBayModel.IsHighlighted:
                return local_effects[self.__order[index.row()]]["highlight"]
            elif role == PatchBayModel.X:
                return local_effects[self.__order[index.row()]]["x"]
            elif role == PatchBayModel.Y:
                return local_effects[self.__order[index.row()]]["y"]
        return QVariant()

    def roleNames(self):
        return {
            PatchBayModel.EffectID: b"l_effect_id",
            PatchBayModel.EffectType: b"l_effect_type",
            PatchBayModel.IsHighlighted: b"l_highlight",
            PatchBayModel.X: b"cur_x",
            PatchBayModel.Y: b"cur_y"
        }

