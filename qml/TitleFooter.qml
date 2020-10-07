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
    property string title_text: ""
    property int category_index: 0

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
                patchStack.pop(null)
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
        text: "You are pressing a footswitch that isn't connected to anything.\nAdd a footswitch module."
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 40
        // opacity: 0.9
        color: "white"
        visible: footSwitchWarning.value
        z: 1
        anchors.centerIn: parent
    }

    Rectangle {
        z: 4
        anchors.fill: parent
        color: "#60000000"
        visible: isLoading.value
        MouseArea {
            height: parent.height
            width: parent.width - 80
            x: 0
            onClicked: {}
        }
        Label {
            text: "LOADING"
            font.pixelSize: 90
            // opacity: 0.8
            color: "white"
            visible: isLoading.value
            anchors.centerIn: parent
        }
    }

    Rectangle {
        color: accent_color.name
        x: 0
        y: 0
        width: 1280
        height: 86
    
        Image {
            x: 10
            y: 9
            source: currentPedalModel.name == "beebo" ? "../icons/digit/Beebo.png" : "../icons/digit/Digit.png" 
        }

        Label {
            // color: "#ffffff"
            text: patch_single.currentMode != PatchBay.Details ? currentPreset.name.replace(/_/g, " ") : title_text
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

        // Rectangle {
        //     x: 1147
        //     y: 15
        //     width: 115
        //     height: 60
        //     radius: 10
        //     color: "white"
        //     Label {
        //         // color: "#ffffff"
        //         x: 5
        //         y: 3 
        //         text: currentBPM.value.toFixed(0) + "\nBPM" 
        //         horizontalAlignment: Text.AlignHCenter
        //         width: 54
        //         height: 54
        //         z: 1
        //         color: Constants.background_color
        //         font {
        //             pixelSize: 20
        //             capitalization: Font.AllUppercase
        //         }
        //         // MouseArea {
        //         //     anchors.fill: parent
        //         //     onClicked: {
        //         //         mainStack.push("PresetSave.qml")
        //         //     }
        //         // }
        //     }

        //     Rectangle {
        //         x: 65
        //         y: 13
        //         id: beat1
        //         width: 15
        //         height: 15
        //         radius: 7.5
        //         color: accent_color.name
        //     }
        //     Rectangle {
        //         x: 86
        //         y: 13
        //         id: beat2
        //         width: 15
        //         height: 15
        //         radius: 7.5
        //         color: accent_color.name
        //     }
        //     Rectangle {
        //         x: 86
        //         y: 34
        //         id: beat3
        //         width: 15
        //         height: 15
        //         radius: 7.5
        //         color: accent_color.name
        //     }
        //     Rectangle {
        //         x: 65
        //         y: 34
        //         id: beat4
        //         width: 15
        //         height: 15
        //         radius: 7.5
        //         color: accent_color.name
        //     }

        //     SequentialAnimation {
        //         running: true
        //         loops: Animation.Infinite
        //         PropertyAction { target: beat1; property: "opacity"; value: 1 }
        //         PauseAnimation { duration: beat_msec }
        //         PropertyAction { target: beat2; property: "opacity"; value: 1 }
        //         PauseAnimation { duration: beat_msec }
        //         PropertyAction { target: beat3; property: "opacity"; value: 1 }
        //         PauseAnimation { duration: beat_msec }
        //         PropertyAction { target: beat4; property: "opacity"; value: 1 }
        //         PauseAnimation { duration: beat_msec / 2 }
        //         PropertyAction { target: beat1; property: "opacity"; value: 0 }
        //         PropertyAction { target: beat2; property: "opacity"; value: 0 }
        //         PropertyAction { target: beat3; property: "opacity"; value: 0 }
        //         PropertyAction { target: beat4; property: "opacity"; value: 0 }
        //         PauseAnimation { duration: beat_msec / 2 }
        //     }
        // }
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
            visible: patch_single.currentMode != PatchBay.Select && patch_single.currentMode != PatchBay.Hold  
            onClicked: {
                // mainStack.push("Settings.qml")
				patch_single.selected_effect.back_action();
            }
        }

        IconButton {
            visible: patch_single.currentMode == PatchBay.Hold && !(patch_single.selected_effect.is_io)
            x: 32 
            y: 8
            width: 70
            height: 70
            icon.width: 70
            icon.height: 70
            // flat: false
            icon.source: "../icons/digit/bottom_menu/Delete.png"
            Material.background: Constants.background_color
            onClicked: {
                patch_single.selected_effect.delete_clicked();
            }
            HelpLabel {
                text: "Delete"
            }
        }

        Label {
            x: patch_single.currentMode != PatchBay.Select ? 170 : 34
            y: 12
            width: 400
            height: 62
            visible: !show_footer_value
            // anchors.centerIn: parent
            text: patch_single.current_help_text
            // height: 15
            color: "white"
			wrapMode: Text.Wrap
            lineHeight: 0.9
            verticalAlignment: Text.AlignVCenter
            font {
                // pixelSize: fontSizeMedium
                pixelSize: 24
                letterSpacing: 0
                // family: docFont.name
                family: docFont.name
                weight: Font.Normal
                // capitalization: Font.AllUppercase
            }
        }

        IconButton {
            id: connectMode
            icon.source: "../icons/digit/clouds/Connect.png"
            visible: patch_single.currentMode == PatchBay.Connect
            width: 70
            height: 70
            x: 584
            y: 12
            onClicked: {
                patch_single.selected_effect.hide_sliders(true);
            }
            // Material.background: "white"
            Material.foreground: "white"
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
            icon.source: "../icons/digit/clouds/Move.png"
            width: 76
            height: 76
            icon.width: 70
            icon.height: 70
            x: 584
            y: 5
            onClicked: {
                patch_single.selected_effect.hide_sliders(true);
            }
            // Material.background: "white"
            Material.foreground: "white"
            radius: 28
            HelpLabel {
                text: "move"
            }
        }

        IconButton {
            visible: patch_single.currentMode == PatchBay.Hold && !(patch_single.selected_effect.is_io)
            x: 584 
            y: 5
            width: 76
            height: 76
            icon.width: 70
            icon.height: 70
            icon.source: "../icons/digit/bottom_menu/Duplicate.png"
            Material.background: Constants.background_color
            Material.foreground: accent_color.name
            onClicked: {
                knobs.add_new_effect(patch_single.selected_effect.effect_type)
            }
            HelpLabel {
                text: "Duplicate"
            }
        }

        IconButton {
            visible: patch_single.currentMode == PatchBay.Hold
            x: 696 
            y: 5
            width: 76
            height: 76
            icon.width: 70
            icon.height: 70
            icon.source: "../icons/digit/bottom_menu/Disconnect.png"
            Material.background: Constants.background_color
            Material.foreground: accent_color.name
            onClicked: {
                patch_single.selected_effect.disconnect_clicked()
            }
            HelpLabel {
                text: "Disconnect"
            }
        }


        IconButton {
            visible: patch_single.currentMode == PatchBay.Select
            x: 961 
            y: 12
            width: 62
            height: 62
            flat: false
            icon.source: "../icons/digit/bottom_menu/Add.png"
            Material.background: accent_color.name
            onClicked: {
                mainStack.push(addEffectCat);
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
            icon.source: "../icons/digit/bottom_menu/Presets.png"
            Material.background: accent_color.name
            onClicked: {
                mainStack.push("PresetSave.qml")
            }
            HelpLabel {
                text: "presets"
            }
        }



        IconButton {
            visible: patch_single.currentMode != PatchBay.Hold
            x: 1121 
            y: 12
            width: 62
            height: 62
            flat: false
            icon.source: "../icons/digit/bottom_menu/Help.png"
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
            visible: patch_single.currentMode != PatchBay.Hold
            x: 1201 
            y: 12
            width: 62
            height: 62
            flat: false
            icon.source: "../icons/digit/bottom_menu/Settings.png"
            Material.background: accent_color.name
            onClicked: {
                mainStack.push("Settings.qml")
            }
            HelpLabel {
                text: "settings"
            }
        }
    }

    // categories effect 0, IO 1, control 2, synth 3, 
    //
    Component {
        id: sectionHeading
        Rectangle {
            width: 1280
            height: 90
            color: accent_color.name

            Text {
                x: 20
                y: 15
                // anchors.horizontalCenter: parent.horizontalCenter
                // anchors.top: parent.top
                // anchors.bottom: parent.bottom
                text: {"0": "Effects", "1": "Input/Output", "2":"Controls", "3": "Synthesis/Weirder" }[section]
                font.bold: true
                font.capitalization: Font.AllUppercase
                font.pixelSize: fontSizeLarge * 0.95
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Component {
        id: addEffectCat
        Item {
            height:700
            width:1280
            Label {
                y: 28
                color: accent_color.name
                text: "Add Module"
                font {
                    pixelSize: 36
                    capitalization: Font.AllUppercase
                }
                // anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Column {
                anchors.centerIn: parent
                spacing: 57

                Row {
                    spacing: 100
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button {
                        text: "EFFECTS"
                        Material.foreground: Constants.poly_pink
                        // anchors.horizontalCenter:  parent.horizontalCenter
                        width: 320
                        height: 59
                        // height: 500
                        onClicked: {
                            category_index = 0;
                            mainStack.push(addEffect);
                        }
                        font {
                            pixelSize: 36
                            capitalization: Font.AllUppercase
                        }
                    }

                    Button {
                        text: "INPUT/OUTPUT"
                        Material.foreground: Constants.poly_green
                        // anchors.horizontalCenter:  parent.horizontalCenter
                        width: 320
                        height: 59
                        // height: 500
                        onClicked: {
                            category_index = 1;
                            mainStack.push(addEffect);
                        }
                        font {
                            pixelSize: 36
                            capitalization: Font.AllUppercase
                        }
                    }
                }
                Row {
                    spacing: 100
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button {
                        text: "CONTROLS"
                        Material.foreground: Constants.poly_blue
                        // anchors.horizontalCenter:  parent.horizontalCenter
                        width: 320
                        height: 59
                        // height: 500
                        onClicked: {
                            category_index = 2;
                            mainStack.push(addEffect);
                        }
                        font {
                            pixelSize: 36
                            capitalization: Font.AllUppercase
                        }
                    }

                    Button {
                        text: "synthesis/weird"
                        Material.foreground: Constants.poly_yellow
                        // anchors.horizontalCenter:  parent.horizontalCenter
                        width: 320
                        height: 59
                        // height: 500
                        onClicked: {
                            category_index = 3;
                            mainStack.push(addEffect);
                        }
                        font {
                            pixelSize: 36
                            capitalization: Font.AllUppercase
                        }
                    }
                }

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
            }
        }
    }

    Component {
        id: addEffect
        
        Item {
            id: addEffectCon
            height:700
            width:1280

            Label {
                y: 28
                color: accent_color.name
                text: "Add Module"
                font {
                    pixelSize: 36
                    capitalization: Font.AllUppercase
                }
                // anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ListView {
                width: 1280
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 120
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 80
                clip: true
                delegate: Item {
                    property string l_effect: edit //.split(":")[1]
                    width: parent.width
                    height: 90
                    Label {
                        x: 34
                        height: 80
                        width: 200
                        text: l_effect.replace(/_/g, " ")
                        anchors.top: parent.top
                        font {
                            pixelSize: fontSizeLarge * 0.85
                            family: mainFont.name
                            weight: Font.DemiBold
                            capitalization: Font.AllUppercase
                        }
                    }
                    Label {
                        x: 334
                        width: 945
                        height: 80
                        text: effectPrototypes[l_effect]["description"]
                        wrapMode: Text.Wrap
                        anchors.top: parent.top
                        font {
                            pixelSize: fontSizeLarge  * 0.8
                            family: docFont.name
                            weight: Font.Normal
                            // capitalization: Font.AllUppercase
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            knobs.add_new_effect(l_effect)
                            // knobs.ui_add_effect(l_effect)
                            mainStack.pop(null)
                            // patch_single.currentMode = PatchBay.Move;
                            patch_single.current_help_text = Constants.help["move"];

                        }
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator {
                    anchors.top: parent.top
                    parent: addEffectCon
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    anchors.bottom: parent.bottom
                }
                model: available_effects[category_index]

                // section.property: "edit"
                // section.criteria: ViewSection.FirstCharacter
                // section.delegate: sectionHeading
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
            }
        }
    }

}

