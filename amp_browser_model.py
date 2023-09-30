# import sys
# import psutil
import glob, json, math, itertools
import os
import os.path

from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide2.QtCore import QUrl, QTimer, QAbstractListModel, QModelIndex

from PySide2.QtCore import QObject, Signal, Slot, Property, Qt


"""
amp info for browsing

needs: title, description, long_description, tags
"""
amp_browser_singleton = None
current_filters = set()
current_search = ""
# start_path = "/git_repos/capture_to_pedal"
start_path = "/mnt/audio/amp_nam"
amp_folders  = None #glob.glob(start_path+"/*/metadata.json", recursive=True)
filtered_amps = None #amp_folders.copy()
favourites = {}
master_amp_metadata = {}

def combine_metadata():
    metadatas = glob.glob(start_path+"/*/metadata.json")
    for m in metadatas:
        a = json.load(open(m))
        # default controls  are the first 1 if there's only 2, middle one if more than 2
        a["selected_controls"] = {}
        for i, control_name in enumerate(a["control_names"]):
            if len(a["controls"][i]) > 2:
                # choose mid
                n = math.floor(len(a["controls"][i]) / 2)
                a["selected_controls"][control_name] = a["controls"][i][n]
            else:
                # choose first
                a["selected_controls"][control_name] = a["controls"][i][0]

        master_amp_metadata[os.path.relpath(os.path.dirname(m), start_path)] = a

    global amp_folders
    global filtered_amps
    amp_folders  = sorted(list(master_amp_metadata.keys()), key=lambda v: v.upper())
    filtered_amps = amp_folders.copy()

combine_metadata()

# amp_folders  = glob.glob(start_path+"/**/*.jpg", recursive=True)
knobs = None

class AmpBrowserModel(QAbstractListModel):

    AmpName = Qt.UserRole + 0
    AmpImage = Qt.UserRole + 1
    Description = Qt.UserRole + 2
    LongDescription = Qt.UserRole + 3
    Tags = Qt.UserRole + 4
    Favourite = Qt.UserRole + 5
    AmpControlNames = Qt.UserRole + 6
    AmpControls = Qt.UserRole + 7
    AmpSelectedControls = Qt.UserRole + 8
    AmpBrand = Qt.UserRole + 9
    AmpModel = Qt.UserRole + 10
    AmpYear = Qt.UserRole + 11

    def __init__(self, l_favourites, l_knobs):
        QAbstractListModel.__init__(self)

        # self.__effects_count = 3
        # self.__effect_types = filtered_amps
        self.__order = dict(enumerate(filtered_amps))
        global amp_browser_singleton
        global favourites
        global knobs
        favourites = l_favourites
        amp_browser_singleton = self
        knobs = l_knobs

    def startInsert(self):
        # print("start insert")
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())

    def endInsert(self):
        # print("end insert")
        self.__order = dict(enumerate(filtered_amps))
        self.endInsertRows()

    def startRemove(self, effect_id):
        current_row = list(filtered_amps).index(effect_id)
        self.beginRemoveRows(QModelIndex(), current_row, current_row)
        # print(effect_id, " removing.")

    def endRemove(self):
        self.endRemoveRows()

    def external_update_reset(self):
        combine_metadata()
        self.clear_filter()

    @Slot()
    def clear_filter(self):
        global current_search
        current_search = ""
        current_filters.clear()

        self.beginResetModel()
        global filtered_amps

        filtered_amps = amp_folders
        self.__order = dict(enumerate(filtered_amps))
        self.endResetModel()

    @Slot(str)
    def add_filter(self, tag=""):
        global current_search
        # if tag != "":
        #     if len(tag) == 1:
                # else:
                #     current_search = tag
            # else:
                # if tag in current_filters:
                #     current_filters.remove(tag)
                # else:
                #     current_filters.add(tag)

        # if tag == current_search:
        #     current_search = ""
        current_search = tag

        self.beginResetModel()
        global filtered_amps

        print("before len filtered modules, current_search", len(filtered_amps), len(current_search))
        if len(current_search) == 0:
            filtered_amps = amp_folders
        # else:
        #     for e in amp_folders.items():
        #         if "tags" not in e[1]:
        #             print("no tags", e)
        #     filtered_amps = {k:v for (k,v) in amp_folders.items() if (current_filters - set(["favourites"])).issubset(v["tags"])}
        #     if "favourites" in current_filters:
        #         filtered_amps = {k:v for (k,v) in filtered_amps.items() if k in favourites["modules"]}
        if current_search != "":
            filtered_amps = [k for k in amp_folders if current_search.lower() in k.lower()]

            # print("len filtered modules", len(filtered_amps))
        self.__order = dict(enumerate(filtered_amps))
        self.endResetModel()

    @Slot(str, str, str, str)
    def set_amp_control(self, effect_id, amp_name, control_name, v):
        if control_name != "":
            master_amp_metadata[amp_name]["selected_controls"][control_name] = v

        # get list of all controls, so we can work out what number in the file list it is
        control_cap_names = [itertools.product(*[[v, ], master_amp_metadata[amp_name]["controls"][i]]) for i,v in enumerate(master_amp_metadata[amp_name]["control_names"])]
        controls = list(itertools.product(*control_cap_names))
        selected = tuple((v, master_amp_metadata[amp_name]["selected_controls"][v]) for v in master_amp_metadata[amp_name]["control_names"])
        selected_i = controls.index(selected) # index of the current params in the file list
        # now set set file
        nam_path = ""
        # print("select controls", master_amp_metadata[amp_name]["selected_controls"], controls, selected, selected_i)
        nam_path = os.path.join(start_path, amp_name, master_amp_metadata[amp_name]["file_names"][selected_i])
        # print("nam path is ", nam_path)
        knobs.update_json(effect_id, nam_path)

    @Slot()
    def items_changed(self):
        self.dataChanged.emit(self.index(0,0), self.index(len(filtered_amps)-1, 0))

    @Slot()
    def item_changed(self, effect_id):
        current_row = list(filtered_amps).index(effect_id)
        # self.__cpu_load = psutil.cpu_percent(percpu=True)
        self.dataChanged.emit(self.index(current_row,0), self.index(current_row, 0))

    def rowCount(self, parent=None):
        # return self.__effects_count
        # print("getting rowcount", len(filtered_amps))
        return len(filtered_amps)

    def data(self, index, role):
        if not index.isValid():
            return QVariant()
        row = index.row()
        if 0 <= row < self.rowCount():
            k = self.__order[index.row()]
            # print("getting role", role, filtered_amps)
            if role == AmpBrowserModel.AmpName:
                print("getting AmpName", self.__order[index.row()])
                return k
            if role == AmpBrowserModel.AmpImage:
                image_path  = glob.glob(start_path+"/"+k+"/*.jp*g")[0]
                return image_path
                # print("getting effectID", filtered_amps[self.__order[index.row()]])
            elif role == AmpBrowserModel.Description:
                # print("getting effectType")
                # return filtered_amps[self.__order[index.row()]]["description"]
                return ""
            elif role == AmpBrowserModel.LongDescription:
                # return filtered_amps[self.__order[index.row()]]["long_description"]
                return master_amp_metadata[k]["long_description"]
            elif role == AmpBrowserModel.Tags:
                # print("getting tags", filtered_amps[self.__order[index.row()]]["tags"])
                # return list(["guitar", "classic"])
                return master_amp_metadata[k]["tags"][:3]
                # return list(filtered_amps[self.__order[index.row()]]["tags"])
            elif role == AmpBrowserModel.Favourite:
                return False
                # return self.__order[index.row()] in favourites["modules"]
            elif role == AmpBrowserModel.AmpControlNames:
                # return  ["bright", "overdrive", "crunch", "overdrive_knob"]
                return master_amp_metadata[k]["control_names"]
            elif role == AmpBrowserModel.AmpControls:
                # return  [['on', 'off'], ['on', 'off'], ['on', 'off'], ['low', 'mid', 'high', 'seriously over the top']]
                return master_amp_metadata[k]["controls"]
            elif role == AmpBrowserModel.AmpSelectedControls:
                # currently seleted controls translate to a particular file name    
                return master_amp_metadata[k]["selected_controls"]
            elif role == AmpBrowserModel.AmpBrand:
                # return filtered_amps[self.__order[index.row()]]["long_description"]
                return master_amp_metadata[k]["amp_brand"]
            elif role == AmpBrowserModel.AmpModel:
                # return filtered_amps[self.__order[index.row()]]["long_description"]
                return master_amp_metadata[k]["amp_model"]
            elif role == AmpBrowserModel.AmpYear:
                # return filtered_amps[self.__order[index.row()]]["long_description"]
                return master_amp_metadata[k]["amp_year"]
        return QVariant()

    def roleNames(self):
        return {
            AmpBrowserModel.AmpName: b"amp_name",
            AmpBrowserModel.AmpImage: b"amp_image",
            AmpBrowserModel.Description: b"description",
            AmpBrowserModel.LongDescription: b"long_description",
            AmpBrowserModel.Tags: b"tags",
            AmpBrowserModel.Favourite: b"is_favourite",
            AmpBrowserModel.AmpControlNames: b"amp_control_names",
            AmpBrowserModel.AmpControls: b"amp_controls",
            AmpBrowserModel.AmpSelectedControls: b"amp_selected_controls",
            AmpBrowserModel.AmpBrand: b"amp_brand",
            AmpBrowserModel.AmpModel: b"amp_model",
            AmpBrowserModel.AmpYear: b"amp_year",
        }
