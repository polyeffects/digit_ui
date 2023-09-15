from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import QUrl, QTimer, QAbstractListModel, QModelIndex

from PySide2.QtCore import QObject, Signal, Slot, Property, Qt

"""
preset info for browsing

needs: title, description, long_description, tags
"""
preset_browser_singleton = None
current_search = ""
showing_favourite = False
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
        global preset_meta
        preset_meta = {k:l_preset_meta[k] for k in sorted(l_preset_meta)}
        self.add_filter("")

    @Slot()
    def clear_filter(self):
        global current_search
        current_search = ""

        self.beginResetModel()
        global filtered_presets

        filtered_presets = preset_meta
        self.__order = dict(enumerate(filtered_presets.keys()))
        self.endResetModel()

    @Slot(bool)
    def show_favourites(self, v):
        global showing_favourite
        showing_favourite = v
        self.add_filter(current_search)

    # pass in "" to just rerun with no changes
    @Slot(str)
    def add_filter(self, tag=""):
        global current_search
        current_search = tag

        self.beginResetModel()
        global filtered_presets

        if showing_favourite:
            filtered_presets = preset_meta
            filtered_presets = {k:v for (k,v) in filtered_presets.items() if k in favourites["presets"]}
        else:
            filtered_presets = preset_meta

        if current_search != "":
            filtered_presets = {k:v for (k,v) in filtered_presets.items() if current_search.lower() in k.strip("/").split("/")[-1][:-6].lower()}

        # print("len filtered preset is", len(filtered_presets))
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

