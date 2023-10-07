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
ir info for browsing

needs: title, description, location, files
"""
ir_browser_singleton = None
# metadata_start_path = "/home/loki/shared/cabs_and_reverbs/" # reverbs and cabs
metadata_start_path = "/audio/" # reverbs and cabs
ir_folders  = {True: [], False: []}
# favourites = {}
reverse_files  = {True: {}, False: {}}
master_ir_metadata = {} # is cab True / False

def gen_meta(prefix, description, display_name):
    wavs = glob.glob(os.path.join(prefix, "*.wav"))
    f_i = glob.glob(os.path.join(prefix,  "*.jp*g"))
    # name = Path(f_i[0]).stem
    # with open(f"{name}.json", "w") as f:
    obj = {"image": f_i[0] if len(f_i) > 0 else "", "files": sorted(wavs), "description": description, "display_name":display_name}
    obj["category"] = "imported"
    return obj

def gen_imported_meta(is_cab):
    if is_cab:
        base_dir_prefix = os.path.join(metadata_start_path, "cabs")
    else:
        base_dir_prefix = os.path.join(metadata_start_path, "reverbs")
    base_dir = os.path.join(base_dir_prefix, "imported")
    ir_dirs = [x[0] for x in os.walk(base_dir)]
    imported = {}

    for i_d in ir_dirs:
        ir_name = os.path.relpath(i_d, base_dir_prefix).replace("/", "-")
        if ir_name == ".":
            ir_name = "imported"
        imported[ir_name] = gen_meta(i_d, "imported IRs", ir_name)
    return imported


with open(os.path.join(metadata_start_path, "reverbs", "reverb_meta.json")) as f:
    master_ir_metadata[False] = json.load(f)
# merge in for imported amps, if doesn't exist, create
with open(os.path.join(metadata_start_path, "cabs", "cab_meta.json")) as f:
    master_ir_metadata[True] = json.load(f)



def combine_metadata():
    global ir_folders
    global reverse_files

    # find imported IR metadata, could cache this
    import_reverbs = gen_imported_meta(False)
    master_ir_metadata[False].update(import_reverbs)
    import_cabs = gen_imported_meta(True)
    master_ir_metadata[True].update(import_cabs)
    ir_folders = {True: sorted(list(master_ir_metadata[True].keys())), False: sorted(list(master_ir_metadata[False].keys()))}
    reverse_files  = {True: {}, False: {}}

    for m_k, m_v in master_ir_metadata.items():
        for k,v in m_v.items():
            for f in v["files"]:
                reverse_files[m_k][f] = k

combine_metadata()

# ir_folders  = glob.glob(start_path+"/**/*.jpg", recursive=True)
knobs = None

class irBrowserModel(QAbstractListModel):

    irName = Qt.UserRole + 0
    irImage = Qt.UserRole + 1
    Description = Qt.UserRole + 2
    Favourite = Qt.UserRole + 3
    irFiles = Qt.UserRole + 4
    irNumCaptures = Qt.UserRole + 5
    irLocation = Qt.UserRole + 6
    irCategory = Qt.UserRole + 7
    irDisplayName = Qt.UserRole + 8
    irIsSelected = Qt.UserRole + 9

    current_search = ""
    reverse_name = ""
    filtered_irs = None#ir_folders.copy()
    is_cab = False
    start_path = ""

    def __init__(self, parent=None):
        QAbstractListModel.__init__(self)

        self.filtered_irs = ir_folders[self.is_cab].copy()
        self.__order = dict(enumerate(self.filtered_irs))
        global ir_browser_singleton
        # global favourites
        # favourites = l_favourites
        ir_browser_singleton = self

    def startInsert(self):
        # print("start insert")
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())

    def endInsert(self):
        # print("end insert")
        self.__order = dict(enumerate(self.filtered_irs))
        self.endInsertRows()

    def startRemove(self, effect_id):
        current_row = list(self.filtered_irs).index(effect_id)
        self.beginRemoveRows(QModelIndex(), current_row, current_row)
        # print(effect_id, " removing.")

    def endRemove(self):
        self.endRemoveRows()

    def external_update_reset(self):
        combine_metadata()
        self.clear_filter()


    @Slot(QObject, str, bool)
    def set_knobs(self, l_knobs, start_path, is_cab):
        global knobs
        knobs = l_knobs
        self.start_path = start_path
        self.is_cab = is_cab
        self.clear_filter()

    @Slot(str, result=str)
    def external_ir_set(self, ir_name):
        # find reverse
        print("external ir set ", ir_name, "reverse files", ir_name[len(self.start_path)+7:])#reverse_files[self.is_cab])
        try:
            self.reverse_name = reverse_files[self.is_cab][ir_name[len(self.start_path)+7:]]
            # print("reverse name is ", self.reverse_name)
        except:
            self.reverse_name = "" # need to cope with restoring being a different file
        return self.reverse_name
        # self.add_filter(self.current_search) # refresh list

    @Slot()
    def clear_filter(self):
        self.current_search = ""

        self.beginResetModel()

        self.filtered_irs = ir_folders[self.is_cab]
        # print("##############################")
        # print("clear filter", self.filtered_irs, "is cab", self.is_cab)
        self.__order = dict(enumerate(self.filtered_irs))
        self.endResetModel()

    @Slot(str)
    def add_filter(self, tag=""):
        self.current_search = tag

        self.beginResetModel()

        print("before len filtered modules, self.current_search", self.current_search, len(self.filtered_irs), len(self.current_search), ir_folders[self.is_cab])
        if len(self.current_search) == 0:
            self.filtered_irs = ir_folders[self.is_cab]
        # else:
        #     for e in ir_folders.items():
        #         if "tags" not in e[1]:
        #             print("no tags", e)
        #     filtered_irs = {k:v for (k,v) in ir_folders.items() if (current_filters - set(["favourites"])).issubset(v["tags"])}
        #     if "favourites" in current_filters:
        #         filtered_irs = {k:v for (k,v) in filtered_irs.items() if k in favourites["modules"]}
        if self.current_search != "":
            self.filtered_irs = [k for k in ir_folders[self.is_cab] if (self.current_search.lower() in master_ir_metadata[self.is_cab][k]["display_name"].lower()) or (self.current_search.lower() in
                master_ir_metadata[self.is_cab][k]["category"].lower()) ]

            # print("len filtered modules", len(filtered_irs))
        self.__order = dict(enumerate(self.filtered_irs))
        self.endResetModel()

    @Slot(str, str)
    def set_ir_file(self, effect_id, ir_path):
        # if ir_path != "":

        ir_path = os.path.join(self.start_path, ir_path)
        # print("nam path is ", nam_path)
        knobs.update_ir(effect_id, ir_path)

    @Slot()
    def items_changed(self):
        self.dataChanged.emit(self.index(0,0), self.index(len(self.filtered_irs)-1, 0))

    @Slot()
    def item_changed(self, effect_id):
        current_row = list(self.filtered_irs).index(effect_id)
        # self.__cpu_load = psutil.cpu_percent(percpu=True)
        self.dataChanged.emit(self.index(current_row,0), self.index(current_row, 0))

    def rowCount(self, parent=None):
        # return self.__effects_count
        # print("getting rowcount", len(filtered_irs))
        return len(self.filtered_irs)

    def data(self, index, role):
        if not index.isValid():
            return QVariant()
        row = index.row()
        if 0 <= row < self.rowCount():
            k = self.__order[index.row()]
            # print("getting role", role, filtered_irs)
            if role == irBrowserModel.irName:
                # print("getting irName", self.__order[index.row()])
                return k
            if role == irBrowserModel.irImage:
                return master_ir_metadata[self.is_cab][k]["image"]
                # print("getting effectID", filtered_irs[self.__order[index.row()]])
            elif role == irBrowserModel.Description:
                # return filtered_irs[self.__order[index.row()]]["long_description"]
                return master_ir_metadata[self.is_cab][k]["description"]
            elif role == irBrowserModel.Favourite:
                return False
                # return self.__order[index.row()] in favourites["modules"]
            elif role == irBrowserModel.irFiles:
                # return  ["bright", "overdrive", "crunch", "overdrive_knob"]
                return master_ir_metadata[self.is_cab][k]["files"]
            elif role == irBrowserModel.irNumCaptures:
                # return  [['on', 'off'], ['on', 'off'], ['on', 'off'], ['low', 'mid', 'high', 'seriously over the top']]
                return len(master_ir_metadata[self.is_cab][k]["files"])
            elif role == irBrowserModel.irLocation:
                try:
                    return master_ir_metadata[self.is_cab][k]["location"]
                except:
                    return ""
            elif role == irBrowserModel.irCategory:
                try:
                    return master_ir_metadata[self.is_cab][k]["category"]
                except:
                    return ""
            elif role == irBrowserModel.irDisplayName:
                try:
                    return master_ir_metadata[self.is_cab][k]["display_name"]
                except:
                    return k
            elif role == irBrowserModel.irIsSelected:
                # print("irIsSelected", reverse_name, k, reverse_name == k)
                return self.reverse_name == k # need to look up in reverse
        return QVariant()

    def roleNames(self):
        return {
            irBrowserModel.irName: b"ir_name",
            irBrowserModel.irImage: b"ir_image",
            irBrowserModel.Description: b"description",
            irBrowserModel.Favourite: b"is_favourite",
            irBrowserModel.irFiles: b"ir_files",
            irBrowserModel.irNumCaptures: b"ir_num_captures",
            irBrowserModel.irLocation: b"ir_location",
            irBrowserModel.irCategory: b"ir_category",
            irBrowserModel.irDisplayName: b"ir_display_name",
            irBrowserModel.irIsSelected: b"ir_is_selected",
        }

