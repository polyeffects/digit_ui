import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "polyconst.js" as Constants

Item { 
    // property PatchBayEffect selected_effect: patch_single.selected_effect
    width: Constants.left_col + 10
    height: 546

    Column {
        width: 100
        // visible: patch_single.currentMode == PatchBay.Sliders
        // y: 98
        anchors.top: parent.top
        anchors.topMargin: patch_single.selected_effect && (patch_single.selected_effect.has_ui) ? 0 : 50
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        x: 30
        id: action_icons
        z: 6
        spacing: 0

        IconButton {
            icon.source: patch_single.selected_effect && currentEffects[patch_single.selected_effect.effect_id]["enabled"].value ? "../icons/digit/clouds/ON.png" : "../icons/digit/clouds/OFF.png"
            rightPadding: 20
            leftPadding: 0
            visible: patch_single.selected_effect && !(patch_single.selected_effect.is_io)
            width: 110
            height: 90
            onClicked: {
                knobs.set_bypass(patch_single.selected_effect.effect_id, !currentEffects[patch_single.selected_effect.effect_id]["enabled"].value)
            }
            // Material.background: "white"
            Material.foreground: "transparent" 
            radius: 30

            SideHelpLabel {
                text: "enable"
            }
        }

        IconButton {
            icon.source: "../icons/digit/clouds/Connect.png"
            rightPadding: 20
            leftPadding: 0
            visible: patch_single.selected_effect && (patch_single.selected_effect.effect_type != "output")
            width: 110
            height: 90
            onClicked: {
                patch_single.selected_effect.connect_clicked();
                patch_single.currentMode = PatchBay.Connect;
                patch_single.current_help_text = Constants.help["connect_to"];
            }
            Material.foreground: "white"
            radius: 30

            SideHelpLabel {
                text: "connect"
            }
        }
        IconButton {
            id: disconnectMode
            icon.source: "../icons/digit/clouds/Disconnect.png"
            rightPadding: 20
            leftPadding: 0
            width: 110
            height: 90
            onClicked: {
                patch_single.selected_effect.disconnect_clicked()
            }
            Material.foreground: "white"
            radius: 30

            SideHelpLabel {
                text: "disconnect"
            }
        }
        IconButton {
            icon.source: "../icons/digit/clouds/Move.png"
            rightPadding: 20
            leftPadding: 0
            visible: patch_single.selected_effect && !(patch_single.selected_effect.is_io)
            width: 110
            height: 90
            onClicked: {
                patch_single.currentMode = PatchBay.Move;
                patch_single.current_help_text = Constants.help["move"];
                patch_single.selected_effect.hide_sliders(false);
            }
            Material.foreground: "white"
            radius: 30
            SideHelpLabel {
                text: "move"
            }
        }

        IconButton {
            visible: patch_single.selected_effect && (patch_single.selected_effect.effect_type != "input" && patch_single.selected_effect.effect_type != "output")
            id: deleteMode
            icon.source: "../icons/digit/clouds/Bin.png"
            rightPadding: 20
            leftPadding: 0
            width: 110
            height: 90
            onClicked: {
                patch_single.selected_effect.delete_clicked()
            }
            Material.foreground: "white"
            radius: 30
            SideHelpLabel {
                text: "delete"
            }
        }

        IconButton {
            id: expandMode
            visible: patch_single.selected_effect && (patch_single.selected_effect.has_ui)
            icon.source: "../icons/digit/clouds/Shapes.png"
            rightPadding: 20
            leftPadding: 0
            width: 110
            height: 90
            onClicked: {
                patch_single.selected_effect.show_advanced_special_clicked();
            }
            radius: 30
            SideHelpLabel {
                text: "Mode"
            }
        }
    }
    Rectangle {
        z: 3
        y: 0
        x: Constants.left_col
        width:2
        height: 546

        color: "white"
    }
}