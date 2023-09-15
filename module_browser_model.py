# import sys
# import psutil

from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import QUrl, QTimer, QAbstractListModel, QModelIndex

from PySide2.QtCore import QObject, Signal, Slot, Property, Qt

import module_info

"""
module info for browsing

needs: title, description, long_description, tags
"""
module_browser_singleton = None
current_filters = set()
current_search = ""
showing_favourite = False
effect_prototypes  = {k:module_info.effect_prototypes_models_all[k] for k in sorted(module_info.effect_prototypes_models_all) if k in module_info.effect_type_maps["beebo"]}
filtered_modules = effect_prototypes
favourites = {}

class ModuleBrowserModel(QAbstractListModel):

    EffectType = Qt.UserRole + 0
    Description = Qt.UserRole + 1
    LongDescription = Qt.UserRole + 2
    Tags = Qt.UserRole + 3
    Favourite = Qt.UserRole + 4

    def __init__(self, l_favourites):
        QAbstractListModel.__init__(self)

        # self.__effects_count = 3
        self.__effect_types = filtered_modules.keys()
        self.__order = dict(enumerate(filtered_modules.keys()))
        global module_browser_singleton
        global favourites
        favourites = l_favourites
        module_browser_singleton = self


    def startInsert(self):
        # print("start insert")
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())

    def endInsert(self):
        # print("end insert")
        self.__order = dict(enumerate(filtered_modules.keys()))
        self.endInsertRows()

    def startRemove(self, effect_id):
        current_row = list(filtered_modules.keys()).index(effect_id)
        self.beginRemoveRows(QModelIndex(), current_row, current_row)
        # print(effect_id, " removing.")

    def endRemove(self):
        self.endRemoveRows()

    @Slot()
    def clear_filter(self):
        global current_search
        current_search = ""
        current_filters.clear()

        self.beginResetModel()
        global filtered_modules

        filtered_modules = effect_prototypes
        self.__order = dict(enumerate(filtered_modules.keys()))
        self.endResetModel()

    @Slot(bool)
    def show_favourites(self, v):
        global showing_favourite
        showing_favourite = v
        self.add_filter(current_search)

    @Slot(str)
    def add_filter(self, tag=""):
        global current_search
        current_search = tag

        self.beginResetModel()
        global filtered_modules

        # print("before len filtered modules", len(filtered_modules))
        if showing_favourite:
            filtered_modules = {k:v for (k,v) in effect_prototypes.items() if k in favourites["modules"]}
        else:
            filtered_modules = effect_prototypes
        if current_search != "":
            filtered_modules = {k:v for (k,v) in filtered_modules.items() if (current_search.lower() in k.lower()) or (current_search.lower() in v["description"].lower())}

            # print("len filtered modules", len(filtered_modules))
        self.__order = dict(enumerate(filtered_modules.keys()))
        self.endResetModel()

    @Slot()
    def items_changed(self):
        self.dataChanged.emit(self.index(0,0), self.index(len(filtered_modules)-1, 0))

    @Slot()
    def item_changed(self, effect_id):
        current_row = list(filtered_modules.keys()).index(effect_id)
        # self.__cpu_load = psutil.cpu_percent(percpu=True)
        self.dataChanged.emit(self.index(current_row,0), self.index(current_row, 0))

    def rowCount(self, parent=None):
        # return self.__effects_count
        # print("getting rowcount", len(filtered_modules))
        return len(filtered_modules)

    def data(self, index, role):
        if not index.isValid():
            return QVariant()
        row = index.row()
        if 0 <= row < self.rowCount():
            # print("getting role", role, filtered_modules)
            if role == ModuleBrowserModel.EffectType:
                # print("getting effectID", filtered_modules[self.__order[index.row()]])
                return self.__order[index.row()]
            elif role == ModuleBrowserModel.Description:
                # print("getting effectType")
                return filtered_modules[self.__order[index.row()]]["description"]
            elif role == ModuleBrowserModel.LongDescription:
                return filtered_modules[self.__order[index.row()]]["long_description"]
            elif role == ModuleBrowserModel.Tags:
                # print("getting tags", filtered_modules[self.__order[index.row()]]["tags"])
                return list(filtered_modules[self.__order[index.row()]]["tags"])
            elif role == ModuleBrowserModel.Favourite:
                return self.__order[index.row()] in favourites["modules"]
        return QVariant()

    def roleNames(self):
        return {
            ModuleBrowserModel.EffectType: b"l_effect_type",
            ModuleBrowserModel.Description: b"description",
            ModuleBrowserModel.LongDescription: b"long_description",
            ModuleBrowserModel.Tags: b"tags",
            ModuleBrowserModel.Favourite: b"is_favourite",
        }

