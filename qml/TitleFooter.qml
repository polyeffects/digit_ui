import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2

import "polyconst.js" as Constants

Item {
    id: title_footer
    property PatchBay patch_single
    property bool show_help: false
    property real beat_msec: 60 / currentBPM.value * 1000
    property real current_footer_value: 0
    property bool show_footer_value: false
    property real currentPresetNum: currentPreset.value

    onCurrentPresetNumChanged: {
        console.log("presetnumchanged", currentPreset.value);
        if (patch_single.currentMode != PatchBay.Select){
            console.log("hiding sliders");
            if (patchStack.currentItem instanceof PatchBay) 
            {
                // patch_single.selected_effect.hide_sliders(true);
            }
            else {
                // console.log("not instance of patchbay");
                // patch_single.selected_effect.hide_sliders(true);
                patchStack.pop()
            }
        }
    }

    width: 1280
    height: 720
    Label {
        // width: 1280
        // height: 720
        text: "BYPASSED"
        font.pixelSize: 95
        opacity: 0.4
        color: "grey"
        visible: isPedalBypassed.value
        z: 1
        anchors.centerIn: parent
    }
    Label {
        // width: 1280
        // height: 720
        text: "LOADING"
        font.pixelSize: 60
        opacity: 0.3
        color: "grey"
        visible: isLoading.value
        z: 1
        anchors.centerIn: parent
    }

    Rectangle {
        color: accent_color.name
        x: 0
        y: 0
        width: 1280
        height: 86

        Label {
            // color: "#ffffff"
            text: currentPreset.name
            elide: Text.ElideRight
            anchors.centerIn: parent
            anchors.bottomMargin: 25 
            horizontalAlignment: Text.AlignHCenter
            width: 1000
            height: 60
            z: 1
            color: Constants.background_color
            font {
                pixelSize: fontSizeLarge
                capitalization: Font.AllUppercase
            }
            // MouseArea {
            //     anchors.fill: parent
            //     onClicked: {

            //         if (patch_single.currentMode == PatchBay.Select){
            //             mainStack.push("PresetSave.qml")
            //         }
            //     }
            // }
        }


        Rectangle {
            x: 995
            y: 15
            width: 115
            height: 60
            radius: 10
            visible: dspLoad.value > 0.60
            color: "white"
            Label {
                // color: "#ffffff"
                visible: dspLoad.value > 0.97
                x: 31 
                y: 1
                text: "URGENT"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                width: 45
                height: 20
                z: 1
                color: "#D70000"
                font {
                    pixelSize: 12
                    capitalization: Font.AllUppercase
                }
            }
            Label {
                // color: "#ffffff"
                x: 7 
                y: 15
                text: "DSP usage\n" + (dspLoad.value * 100).toFixed(0) + "%"
                horizontalAlignment: Text.AlignLeft
                lineHeight: 0.65
                width: 80
                height: 33
                z: 1
                color: Constants.background_color
                font {
                    pixelSize: 16
                    capitalization: Font.AllUppercase
                }
            }
        }

        Rectangle {
            x: 1147
            y: 15
            width: 115
            height: 60
            radius: 10
            color: "white"
            Label {
                // color: "#ffffff"
                x: 5
                y: 3 
                text: currentBPM.value.toFixed(0) + "\nBPM" 
                horizontalAlignment: Text.AlignHCenter
                width: 54
                height: 54
                z: 1
                color: Constants.background_color
                font {
                    pixelSize: 20
                    capitalization: Font.AllUppercase
                }
                // MouseArea {
                //     anchors.fill: parent
                //     onClicked: {
                //         mainStack.push("PresetSave.qml")
                //     }
                // }
            }

            Rectangle {
                x: 65
                y: 13
                id: beat1
                width: 15
                height: 15
                radius: 7.5
                color: accent_color.name
            }
            Rectangle {
                x: 86
                y: 13
                id: beat2
                width: 15
                height: 15
                radius: 7.5
                color: accent_color.name
            }
            Rectangle {
                x: 86
                y: 34
                id: beat3
                width: 15
                height: 15
                radius: 7.5
                color: accent_color.name
            }
            Rectangle {
                x: 65
                y: 34
                id: beat4
                width: 15
                height: 15
                radius: 7.5
                color: accent_color.name
            }

            SequentialAnimation {
                running: true
                loops: Animation.Infinite
                PropertyAction { target: beat1; property: "opacity"; value: 1 }
                PauseAnimation { duration: beat_msec }
                PropertyAction { target: beat2; property: "opacity"; value: 1 }
                PauseAnimation { duration: beat_msec }
                PropertyAction { target: beat3; property: "opacity"; value: 1 }
                PauseAnimation { duration: beat_msec }
                PropertyAction { target: beat4; property: "opacity"; value: 1 }
                PauseAnimation { duration: beat_msec / 2 }
                PropertyAction { target: beat1; property: "opacity"; value: 0 }
                PropertyAction { target: beat2; property: "opacity"; value: 0 }
                PropertyAction { target: beat3; property: "opacity"; value: 0 }
                PropertyAction { target: beat4; property: "opacity"; value: 0 }
                PauseAnimation { duration: beat_msec / 2 }
            }
        }
    }

    StackView {
        id: patchStack
        x: 0
        y: 86
        initialItem: PatchBay {
        }
    }
    Rectangle {
        color: "white" //Constants.background_color
        x: 0
        // y: 86
        y: 633
        height:1
        width: 1280
        // height: 720-86-86
        // border { width:1; color: "white"}
    }
    Item {
        // color: Constants.background_color
        x: 0
        y: 634
        width: 1280
        height: 86
        // border { width:2; color: "white"}

        IconButton {
            x: 34 
            y: 12
            icon.width: 15
            icon.height: 25
            width: 119
            height: 62
            text: "BACK"
            font {
                pixelSize: 24
            }
            flat: false
            icon.name: "back"
            Material.background: "white"
            Material.foreground: Constants.outline_color
            visible: patch_single.currentMode != PatchBay.Select
            HelpLabel {
                text: "back"
            }
            onClicked: {
                // mainStack.push("Settings.qml")
                if (patchStack.currentItem instanceof PatchBay) 
                {
                    patch_single.selected_effect.hide_sliders(true);
                }
                else {
                    // console.log("not instance of patchbay");
                    patch_single.selected_effect.hide_sliders(true);
                    patchStack.pop()
                }
            }
        }


        IconButton {
            id: connectMode
            icon.name: "connect"
            visible: patch_single.currentMode == PatchBay.Connect
            width: 56
            height: 56
            x: 584
            y: 12
            onClicked: {
                patch_single.selected_effect.hide_sliders(true);
            }
            Material.background: "white"
            Material.foreground: accent_color.name
            radius: 28
            HelpLabel {
                text: "connect"
            }
        }

        Label {
            visible: show_footer_value
            anchors.centerIn: parent
            text: current_footer_value.toFixed(3)
            // height: 15
            color: "white"
            font {
                // pixelSize: fontSizeMedium
                pixelSize: 48
                capitalization: Font.AllUppercase
            }
        }

        IconButton {
            id: moveMode
            visible: patch_single.currentMode == PatchBay.Move
            icon.name: "move"
            width: 56
            height: 56
            x: 584
            y: 12
            onClicked: {
                patch_single.selected_effect.hide_sliders(true);
            }
            Material.background: "white"
            Material.foreground: accent_color.name
            radius: 28
            HelpLabel {
                text: "move"
            }
        }


        IconButton {
            visible: patch_single.currentMode == PatchBay.Select
            x: 961 
            y: 12
            width: 62
            height: 62
            flat: false
            icon.name: "add"
            Material.background: accent_color.name
            onClicked: {
                mainStack.push(addEffect);
            }
            HelpLabel {
                text: "add"
            }
        }

        IconButton {
            visible: patch_single.currentMode == PatchBay.Select
            x: 1041 
            y: 12
            width: 62
            height: 62
            flat: false
            icon.name: "save"
            Material.background: accent_color.name
            onClicked: {
                mainStack.push("PresetSave.qml")
            }
            HelpLabel {
                text: "presets"
            }
        }

        IconButton {
            x: 1121 
            y: 12
            width: 62
            height: 62
            flat: false
            icon.name: "help-circle"
            Material.background: accent_color.name
            onClicked: {
                title_footer.show_help = !title_footer.show_help
            }
            highlighted: show_help
            HelpLabel {
                text: "help"
            }
        }

        IconButton {
            x: 1201 
            y: 12
            width: 62
            height: 62
            flat: false
            icon.name: "settings"
            Material.background: accent_color.name
            onClicked: {
                mainStack.push("Settings.qml")
            }
            HelpLabel {
                text: "settings"
            }
        }
    }

    Component {
        id: addEffect
        Item {
            id: addEffectCon
            height:700
            width:1280

            GlowingLabel {
                color: "#ffffff"
                text: "Add Effect"
                font {
                    pixelSize: fontSizeLarge * 1.2
                    capitalization: Font.AllUppercase
                }
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ListView {
                width: 400
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 75
                anchors.bottom: parent.bottom
                clip: true
                delegate: ItemDelegate {
                    width: parent.width
                    height: 75
                    text: edit.replace(/_/g, " ")
                    bottomPadding: 0
                    font.pixelSize: fontSizeLarge
                    font.capitalization: Font.AllUppercase
                    topPadding: 0
                    onClicked: {
                        knobs.add_new_effect(edit)
                        // knobs.ui_add_effect(edit)
                        mainStack.pop()
                        patch_single.currentMode = PatchBay.Move;
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator {
                    anchors.top: parent.top
                    parent: addEffectCon
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    anchors.bottom: parent.bottom
                }
                model: available_effects
            }

            IconButton {
                x: 34 
                y: 646
                icon.width: 15
                icon.height: 25
                width: 119
                height: 62
                text: "BACK"
                font {
                    pixelSize: 24
                }
                flat: false
                icon.name: "back"
                Material.background: "white"
                Material.foreground: Constants.outline_color
                onClicked: mainStack.pop()
                HelpLabel {
                    text: "Back"
                }
            }
        }
    }

}

