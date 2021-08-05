# import sys
# import psutil

from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import QUrl, QTimer, QAbstractListModel, QModelIndex

from PySide2.QtCore import QObject, Signal, Slot, Property, Qt

"""
preset info for browsing

needs: title, description, long_description, tags
"""
preset_browser_singleton = None
current_filters = set()
current_letter = ""
preset_meta  = {}
filtered_presets = {}
author = ""
favourites = {}

class PresetBrowserModel(QAbstractListModel):

    Title = Qt.UserRole + 0
    Description = Qt.UserRole + 1
    Author = Qt.UserRole + 2
    Filename = Qt.UserRole + 3
    Tags = Qt.UserRole + 4
    Favourite = Qt.UserRole + 5

    def __init__(self, l_preset_meta, l_favourites, l_author):
        QAbstractListModel.__init__(self)

        # self.__effects_count = 3

        global filtered_presets
        global preset_meta
        global author
        global favourites
        preset_meta = {k:l_preset_meta[k] for k in sorted(l_preset_meta)}
        filtered_presets = preset_meta
        author = l_author
        favourites = l_favourites
        self.__effect_types = filtered_presets.keys()
        self.__order = dict(enumerate(filtered_presets.keys()))
        global preset_browser_singleton
        preset_browser_singleton = self


    def startInsert(self):
        # print("start insert")
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())

    def endInsert(self):
        # print("end insert")
        self.__order = dict(enumerate(filtered_presets.keys()))
        self.endInsertRows()

    def startRemove(self, effect_id):
        current_row = list(filtered_presets.keys()).index(effect_id)
        self.beginRemoveRows(QModelIndex(), current_row, current_row)
        # print(effect_id, " removing.")

    def endRemove(self):
        self.endRemoveRows()

    def update_preset_meta(self, l_preset_meta):
        preset_meta = {k:l_preset_meta[k] for k in sorted(l_preset_meta)}
        self.items_changed()

    @Slot()
    def clear_filter(self):
        global current_letter
        current_letter = ""
        current_filters.clear()

        self.beginResetModel()
        global filtered_presets

        filtered_presets = preset_meta
        self.__order = dict(enumerate(filtered_presets.keys()))
        self.endResetModel()

    @Slot(str)
    def add_filter(self, tag):
        global current_letter
        if len(tag) == 1:
            if tag == current_letter:
                current_letter = ""
            else:
                current_letter = tag
        else:
            if tag in current_filters:
                current_filters.remove(tag)
            else:
                current_filters.add(tag)

        self.beginResetModel()
        global filtered_presets

        print("in before len filtered preset", len(filtered_presets), "current filters", current_filters)
        if len(current_filters) == 0:
            filtered_presets = preset_meta
        else:
            filtered_presets = preset_meta
            # for e in preset_meta.items():
                # if "tags" not in e[1]:
                #     print("no tags", e)
            if "favourites" in current_filters:
                filtered_presets = {k:v for (k,v) in filtered_presets.items() if k in favourites["presets"]}
            if "mine" in current_filters:
                filtered_presets = {k:v for (k,v) in filtered_presets.items() if v["author"] == author}
        if current_letter != "":
            filtered_presets = {k:v for (k,v) in filtered_presets.items() if k.strip("/").split("/")[-1][:-6].lower().startswith(current_letter)}

        print("len filtered preset is", len(filtered_presets))
        self.__order = dict(enumerate(filtered_presets.keys()))
        self.endResetModel()

    @Slot()
    def items_changed(self):
        self.dataChanged.emit(self.index(0,0), self.index(len(filtered_presets)-1, 0))

    @Slot()
    def item_changed(self, effect_id):
        current_row = list(filtered_presets.keys()).index(effect_id)
        # self.__cpu_load = psutil.cpu_percent(percpu=True)
        self.dataChanged.emit(self.index(current_row,0), self.index(current_row, 0))

    def rowCount(self, parent=None):
        # return self.__effects_count
        # print("getting rowcount", len(filtered_presets))
        return len(filtered_presets)

    def data(self, index, role):
        if not index.isValid():
            return QVariant()
        row = index.row()
        if 0 <= row < self.rowCount():
            # print("getting role", role, filtered_presets)
            if role == PresetBrowserModel.Title:
                # print("getting effectID", filtered_presets[self.__order[index.row()]])
                return self.__order[index.row()].strip("/").split("/")[-1][:-6].replace("_", " ")
            elif role == PresetBrowserModel.Description:
                # print("getting effectType")
                if "description" in filtered_presets[self.__order[index.row()]]:
                    return filtered_presets[self.__order[index.row()]]["description"]
                else:
                    return ""
            elif role == PresetBrowserModel.Author:
                return filtered_presets[self.__order[index.row()]]["author"]
            elif role == PresetBrowserModel.Filename:
                return self.__order[index.row()]
            elif role == PresetBrowserModel.Tags:
                # print("getting tags", filtered_presets[self.__order[index.row()]]["tags"])
                # return list(filtered_presets[self.__order[index.row()]]["tags"])
                if filtered_presets[self.__order[index.row()]]["author"] == author:
                    return ["mine" ] #filtered_presets[self.__order[index.row()]]["tags"])
                else:
                    return []
            elif role == PresetBrowserModel.Favourite:
                return self.__order[index.row()] in favourites["presets"]
        return QVariant()

    def roleNames(self):
        return {
            PresetBrowserModel.Title: b"title",
            PresetBrowserModel.Description: b"description",
            PresetBrowserModel.Author: b"author",
            PresetBrowserModel.Filename: b"filename",
            PresetBrowserModel.Tags: b"tags",
            PresetBrowserModel.Favourite: b"is_favourite",
        }

