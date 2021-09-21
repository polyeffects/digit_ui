import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import "../qml/polyconst.js" as Constants

Item {
    height:540
    width:1280
    id: control
    property string row_param: "Amp_5"
    property string current_effect 
    property double actualValue : currentEffects[current_effect]["controls"][row_param].value
    property double midiCC : currentEffects[current_effect]["controls"][row_param].cc
    property string current_value: parseFloat(actualValue.toFixed(3)).toString()
    property bool learning: false
    property bool v_type: "float"

    onActualValueChanged: {
        current_value = parseFloat(actualValue.toFixed(3)).toString()
    }

    onMidiCCChanged: {
        if (learning){
            learning = false;
        } 
    }

    Row {
        y: 20
        width:1280
        spacing: 20
        Column {
            spacing: 20
        
            IconButton {
                id: midiButton
                icon.source: (currentEffects[current_effect]["controls"][row_param].cc == -1) ?  "../icons/digit/midi_inactive.png" : "../icons/digit/midi_active.png"  
                width: 195
                height: 201
                topPadding: -70
                icon.width: 60
                icon.height: 60
                has_border: true
                checked: false
                onClicked: {
                    knobs.midi_learn(current_effect, row_param);
                    learning = !learning;
                }
                onPressed: {
                    checked = true;
                
                }
                onReleased: {
                    checked = false;
                
                }
                Material.background: "transparent"
                Material.foreground: "transparent"
                Material.accent: Constants.poly_pink
                radius: 3
                Label {
                    x: 0
                    y: 90 
                    text: midiCC > -1 ? "MIDI\nCC:"+midiCC : "MIDI"
                    horizontalAlignment: Text.AlignHCenter
                    width: 195
                    height: 22
                    z: 1
                    color: midiButton.checked || learning ? "black" : "white"
                    font {
                        pixelSize: 26
                        capitalization: Font.AllUppercase
                    }
                }
                SequentialAnimation {
                    id: blinkLearn;
                    loops: Animation.Infinite;
                    alwaysRunToEnd: true;
                    running: currentEffects[current_effect]["controls"][row_param].cc == -1 && control.learning;
                    ColorAnimation { target: midiButton; property: "Material.background"; from: midiButton.Material.foreground; to: Constants.poly_pink; duration: 1000 }
                    ColorAnimation { target: midiButton; property: "Material.background"; to: midiButton.Material.foreground; from: Constants.poly_pink; duration: 1000 }
                }
            }
            IconButton {
                icon.source: checked ?  "../icons/digit/loopler/commands/active/undo.png" : "../icons/digit/loopler/commands/inactive/undo.png"  
                width: 195
                height: 201
                topPadding: -70
                icon.width: 60
                icon.height: 60
                has_border: true
                checked: false
                onClicked: {
                    knobs.ui_knob_change(current_effect, row_param, currentEffects[current_effect]["controls"][row_param].default_value);
                }
                onPressed: {
                    checked = true;
                
                }
                onReleased: {
                    checked = false;
                }
                Material.background: checked ? Constants.poly_pink : "transparent"
                Material.foreground: "transparent"
                Material.accent: Constants.poly_pink
                radius: 3
                Label {
                    x: 0
                    y: 90 
                    text: "Reset to\ndefault"
                    horizontalAlignment: Text.AlignHCenter
                    width: 195
                    height: 22
                    z: 1
                    color: parent.checked ? "black" : "white"
                    font {
                        pixelSize: 26
                        capitalization: Font.AllUppercase
                    }
                }
            }

        }

        Rectangle {
            width: 2
            height: 520
            color: Constants.poly_dark_grey
        }

        Row {
            width: 571
            height: parent.height
            spacing : 20

            Column  {
                width: 150
                spacing : 20
                height: parent.height
                PolyButton {
                    height: 95
                    width: 150
                    // text: modeldata
                    onClicked: {
                        knobs.ui_knob_inc(current_effect, row_param, true);
                    }
                    text: "+"
                    Material.foreground: Constants.poly_pink
                    border_color: Constants.poly_pink
                    Material.background: Constants.background_color
                    font_size: 60

                }
                
                PolyButton {
                    height: 109
                    width: 150
                    // text: modeldata
                    text: control.current_value
                    Material.foreground: Constants.background_color
                    border_color: Constants.poly_pink
                    Material.background: Constants.poly_pink
                    background_color: Constants.poly_pink
                    font_size: 28

                }
                PolyButton {
                    height: 95
                    width: 150
                    // text: modeldata
                    onClicked: {
                        knobs.ui_knob_inc(current_effect, row_param, false);
                    }
                    text: "-"
                    Material.foreground: Constants.poly_pink
                    border_color: Constants.poly_pink
                    Material.background: Constants.background_color
                    font_size: 60

                }
            
            }
            Column {
                visible: v_type != "bool"
                spacing: 120
                Grid {
                    width: 650
                    height: 320
                    columns: 3
                    rows: 4
                    spacing : 40
                    Repeater {
                        model: [1, 2, 3, 4, 5, 6, 7, 8, 9, "⌫", 0, '.']
                        PolyButton {
                            height: 70
                            width: 100
                            text: modelData
                            onClicked: {
                                if (modelData == "⌫"){
                                    control.current_value = control.current_value.slice(0, -1);
                                }
                                else if (modelData == "."){
                                    if (!control.current_value.includes(".")){
                                        control.current_value = control.current_value + modelData
                                    }

                                } else {
                                    control.current_value = control.current_value + modelData
                                }
                            }

                            Material.foreground: Constants.poly_pink
                            border_color: Constants.poly_pink
                            Material.background: Constants.background_color
                            font {
                                pixelSize: 20
                                capitalization: Font.AllUppercase
                            }
                        }

                    }

                }
                PolyButton {
                    height: 64
                    width: 380
                    text: "submit"
                    onClicked: {
                        knobs.ui_knob_change(current_effect, row_param, control.current_value);
                    }

                    Material.foreground: Constants.poly_pink
                    border_color: Constants.poly_pink
                    Material.background: Constants.background_color
                    font {
                        pixelSize: 20
                        capitalization: Font.AllUppercase
                    }
                }
            }
        }
        PolyButton {
            function isItemInArray(array, item) {
                for (var i = 0; i < array.length; i++) {
                    // This if statement depends on the format of your array
                    if (array[i][0] == item[0] && array[i][1] == item[1]) {
                        return true;   // Found it
                    }
                }
                return false;   // Not found
            }

            height: 80
            width: 350
            text: isItemInArray(knobs.spotlight_entries, [current_effect, row_param]) ? "REMOVE\nFROM SPOTLIGHT" : "EXPOSE\nIN SPOTLIGHT"
            onClicked: {
                knobs.expose_spotlight(current_effect, row_param);
            }

            Material.foreground: Constants.poly_pink
            border_color: Constants.poly_pink
            Material.background: Constants.background_color
            font {
                pixelSize: 20
                capitalization: Font.AllUppercase
            }
        }

    }
}
