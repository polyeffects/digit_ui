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
    property real loadCounter: presetCounter.value
    property string title_text: ""
    property int category_index: 0

    onLoadCounterChanged: {
        // console.log("load_counter_changed", presetCounter.value);
        if (patch_single.currentMode != PatchBay.Select){
            // console.log("load_counter_changed patchbay not select");
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

    Label {
        // width: 1280
        // height: 720
        text: "You are in advanced connect mode. You should be using multi touch hold and tap instead, \n unless you want to interconnect control and audio signals."
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 40
        opacity: 0.5
        color: "grey"
		visible: patch_single.currentMode == PatchBay.Connect
        z: 1
        anchors.centerIn: parent
    }

    Rectangle {
        z: 4
        anchors.fill: parent
        color: "#60000000"
        visible: isLoading.value
        MouseArea {
            height: parent.height - 80
            width: parent.width 
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
        color:  currentPedalModel.name == "beebo" || patch_single.currentMode == PatchBay.Details ? accent_color.name : "transparent"
        x: 0
        y: 0
        z: 3
        width: 1280
        height: 86
        visible: patch_single.currentMode != PatchBay.Details
    
        Image {
            x: 10
            y: 9
            source: currentPedalModel.name == "beebo" ? "../icons/digit/Beebo.png" : "../icons/digit/Hector.png"
            visible: currentPedalModel.name == "beebo" || patch_single.currentMode == PatchBay.Details
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
            z: 5
            color:  currentPedalModel.name == "beebo" || patch_single.currentMode == PatchBay.Details ?  Constants.background_color : accent_color.name
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
            x: 945
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
        y: currentPedalModel.name == "beebo" && patch_single.currentMode != PatchBay.Details ?  86 : 0
        initialItem: PatchBay {
        }
    }
    // Rectangle {
    //     color: Constants.poly_dark_grey //Constants.background_color
    //     x: 0
    //     // y: 86
    //     y: 633
    //     height:1
    //     width: 1280
    //     // height: 720-86-86
    //     // border { width:1; color: "white"}
    // }
    Item {
        // color: Constants.background_color
        x: 0
        y: 645
        width: 1280
        height: 80
        visible: !Qt.inputMethod.visible
        // border { width:2; color: "white"}
        IconButton {

            x: 31 
            y: -10
            width: 120
            height: 70
            icon.width: 120
            icon.height: 70
            // flat: false
            icon.source: "../icons/digit/bottom_menu/back.png"
            // Material.background: Constants.background_color
            Material.foreground: Constants.background_color
            Material.background: "white"
            visible: patch_single.currentMode != PatchBay.Select && patch_single.currentMode != PatchBay.Hold  
            onClicked: {
                if(patch_single.in_spotlight){
                    patchStack.pop()
                    if (patchStack.currentItem instanceof PatchBay){
                        patch_single.in_spotlight = false;
                        patch_single.currentMode = PatchBay.Select;
                        patch_single.selected_effect = null;
                        patch_single.current_help_text = Constants.help["select"];
                    }
                } else {
                    patch_single.selected_effect.back_action();
                }
            }
            // HelpLabel {
            //     text: "Global"
            // }
        }

        Label {
            // color: "#ffffff"
            text: patch_single.currentMode != PatchBay.Details ? currentPreset.name.replace(/_/g, " ") : title_text
            elide: Text.ElideRight
            visible:patch_single.currentMode == PatchBay.Details  
            anchors.horizontalCenter: parent.horizontalCenter
            y: -10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            // width: 1000
            height: 70
            leftPadding: 10
            rightPadding: 10

            color:  Constants.background_color
            font {
                pixelSize: 36
                capitalization: Font.AllUppercase
            }
            background: Rectangle {
                color: "white"
                radius: 4
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

        // IconButton {
        //     x: 34 
        //     y: 12
        //     icon.width: 15
        //     icon.height: 25
        //     width: 119
        //     height: 62
        //     text: "BACK"
        //     font {
        //         pixelSize: 24
        //     }
        //     flat: false
        //     icon.name: "back"
        //     Material.background: "white"
        //     Material.foreground: Constants.outline_color
        //     visible: patch_single.currentMode != PatchBay.Select && patch_single.currentMode != PatchBay.Hold  
        //     onClicked: {
        //         // mainStack.push("Settings.qml")
				// patch_single.selected_effect.back_action();
        //     }
        // }

        IconButton {
            visible: patch_single.currentMode == PatchBay.Hold && !(patch_single.selected_effect.is_io)
            x: 120 
            y: 8
            width: 70
            height: 70
            icon.width: 70
            icon.height: 70
            // flat: false
            icon.source: "../icons/digit/bottom_menu/Delete.png"
            Material.background: Constants.background_color
            onClicked: {
                patch_single.cancel_expand = true;
                patch_single.selected_effect.delete_clicked();
            }
            HelpLabel {
                text: "Delete"
            }
        }

        Label {
            x: patch_single.currentMode != PatchBay.Select ? 860 : 860
            y: 12
            width: 350
            height: 62
            visible: !show_footer_value && patch_single.currentMode != PatchBay.Details
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

        Label {
            visible: show_footer_value
            y: 10
            x: 300
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
                patch_single.cancel_expand = true;
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
                patch_single.cancel_expand = true;
                patch_single.selected_effect.is_pressed = false
                patch_single.selected_effect.disconnect_clicked()
            }
            HelpLabel {
                text: "Disconnect"
            }
        }


        IconButton {
            visible: patch_single.currentMode == PatchBay.Select
            x: 765 
            y: 12
            width: 62
            height: 62
            icon.source: "../icons/digit/bottom_menu/Add.png"
            Material.background: Constants.background_color
            onClicked: {
                module_browser_model.clear_filter();
                mainStack.push("ModuleBrowser.qml");
            }
            HelpLabel {
                text: "add"
            }
        }

        IconButton {
            visible: patch_single.currentMode == PatchBay.Select
            x: 315 
            y: 12
            width: 62
            height: 62
            icon.source: "../icons/digit/bottom_menu/spotlight.png"
            Material.background: Constants.background_color
            onClicked: {
                patch_single.in_spotlight = true;
                patch_single.currentMode = PatchBay.Details;
                title_text = currentPreset.name.replace(/_/g, " ") + " : SPOTLIGHT"
                patch_single.current_help_text = ""
                patchStack.push("Spotlight.qml")
            }
            HelpLabel {
                text: "spotlight"
            }
        }

        IconButton {
            visible: patch_single.currentMode == PatchBay.Select
            x: 465 
            y: 12
            width: 62
            height: 62
            icon.source: "../icons/digit/bottom_menu/patch.png"
            Material.background: Constants.background_color
            onClicked: {
                preset_browser_model.clear_filter();
                mainStack.push("PresetSave.qml")
            }
            HelpLabel {
                text: "presets"
            }
        }

        IconButton {
            visible: patch_single.currentMode == PatchBay.Select
            x: 615 
            y: 12
            width: 62
            icon.width: 60
            height: 62
            icon.source: "../icons/digit/bottom_menu/Settings.png"
            Material.background: Constants.background_color
            onClicked: {
                mainStack.push("Settings.qml")
            }
            HelpLabel {
                text: "settings"
            }
        }
    }

}

