preset_list = []
try:
    with open("/pedal_state/preset_list.json") as f:
        preset_list = json.load(f)
except:
    preset_list = ["Akg eq ed", "Back at u"]
preset_list_model = QStringListModel(preset_list)

def set_knob_current_effect(knob, effect, parameter):
    # get current value and update encoder / cache.
    knob_map[knob].effect = effect
    knob_map[knob].parameter = parameter


# preset map number to filename
# playlists
# add number + filename




def write_pedal_state():
    with open("/pedal_state/state.json", "w") as f:
        json.dump(pedal_state, f)

knob_map = {"left": PolyEncoder("delay1", "Delay_1"), "right": PolyEncoder("delay1", "Amp_5")}
plugin_state["global"] = PolyBool(True)

# Instantiate the Python object.
knobs = Knobs()
# global ui_messages, core_messages
ui_messages = ui_mess
core_messages = core_mess
app = QGuiApplication(sys.argv)
QIcon.setThemeName("digit")
qmlEngine = QQmlApplicationEngine()
# Expose the object to QML.
context = qmlEngine.rootContext()
context.setContextProperty("knobs", knobs)

# engine.load(QUrl("qrc:/qml/digit.qml"))
print("loading qml engine")
qmlEngine.load(QUrl("qml/digit.qml"))
######### UI is setup


print("exiting frontend")
exit(1)
