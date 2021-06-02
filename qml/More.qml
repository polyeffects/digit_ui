import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.VirtualKeyboard 2.1
import "../qml/polyconst.js" as Constants

Item {
    FocusScope {
    z: 3
    height:540
    width:1280
    focus: true

    Row {
        x: 20
        y: 50
        spacing: 20

        TextField {
            focus: true
            id: input_field
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator{bottom: 0; top: 32000;}
            width: 121
            height: 60
            // text: (60.0 / currentEffects[effect_id]["controls"]["BPM_0"].value * currentEffects[effect_id]["controls"]["Delay_1"].value * 1000).toFixed(0) // + " ms"
            color: focus ? "red" : "white" 
            text: "111"
            font {
                // pixelSize: fontSizeMedium
                family: mainFont.name
                pixelSize: 28
                capitalization: Font.AllUppercase
                letterSpacing: 0
            }
            onTextEdited: {
                if (Number(text) > 0 && Number(text) < 32000){
                    // knobs.ui_knob_change(effect_id, "Delay_1", text * currentEffects[effect_id]["controls"]["BPM_0"].value / ( 1000 * 60)) ;
                }
            }

            Component.onCompleted: {
                input_field.forceActiveFocus();
                // console.log("setting broadcast true in step");
                // input_field.cursorPosition = 0
                // input_field.pressed(Qt.MouseEvent);
                // Qt.inputMethod.update(Qt.ImQueryInput)
                focus = true
            }

            onActiveFocusChanged: {
                console.log("focus changed")
                if(activeFocus) {
                    console.log("focus active")
                    Qt.inputMethod.update(Qt.ImQueryInput)
                }
            }
        }

        InputPanel {
            id: inputPanel
            // x: 150
            // y: 0
            width: 473
            // height: 473
        }

    }
}
}
