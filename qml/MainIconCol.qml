import "controls" as PolyControls
import QtQuick 2.4
import QtQuick.Controls 2.3
Column {
    height: 546
    width:  100
    // id: action_icons
    z: 6
    spacing: 25
    IconButton {
        icon.name: "connect"
        visible: selected_effect && (selected_effect.effect_type != "output")
        width: 60
        height: 60
        onClicked: {
            selected_effect.connect_clicked();
            currentMode = PatchBay.Connect;
            current_help_text = Constants.help["connect_to"];
        }
        Material.background: "white"
        Material.foreground: accent_color.name
        radius: 28

        Label {
            visible: title_footer.show_help 
            x: -92
            y: 19 
            text: "connect"
            horizontalAlignment: Text.AlignRight
            width: 82
            height: 9
            z: 1
            color: "white"
            font {
                pixelSize: 14
                capitalization: Font.AllUppercase
            }
        }
    }
    IconButton {
        id: disconnectMode
        icon.name: "disconnect"
        width: 60
        height: 60
        onClicked: {
            selected_effect.disconnect_clicked()
        }
        Material.background: "white"
        Material.foreground: accent_color.name
        radius: 28

        Label {
            visible: title_footer.show_help 
            x: -92
            y: 19 
            text: "disconnect"
            horizontalAlignment: Text.AlignRight
            width: 82
            height: 9
            z: 1
            color: "white"
            font {
                pixelSize: 14
                capitalization: Font.AllUppercase
            }
        }
    }
    IconButton {
        icon.name: "move"
        visible: selected_effect && !(selected_effect.is_io)
        width: 60
        height: 60
        onClicked: {
            currentMode = PatchBay.Move;
            current_help_text = Constants.help["move"];
            selected_effect.hide_sliders(false);
        }
        Material.background: "white"
        Material.foreground: accent_color.name
        radius: 28
        Label {
            visible: title_footer.show_help 
            x: -92
            y: 19 
            text: "move"
            horizontalAlignment: Text.AlignRight
            width: 82
            height: 9
            z: 1
            color: "white"
            font {
                pixelSize: 14
                capitalization: Font.AllUppercase
            }
        }
    }
    IconButton {
        visible: selected_effect && (selected_effect.effect_type != "input" && selected_effect.effect_type != "output")
        id: deleteMode
        icon.name: "delete"
        width: 60
        height: 60
        onClicked: {
            selected_effect.delete_clicked()
        }
        Material.background: "white"
        Material.foreground: accent_color.name
        radius: 28
        Label {
            visible: title_footer.show_help 
            x: -92
            y: 19 
            text: "delete"
            horizontalAlignment: Text.AlignRight
            width: 82
            height: 9
            z: 1
            color: "white"
            font {
                pixelSize: 14
                capitalization: Font.AllUppercase
            }
        }
    }
    // IconButton {
    //     id: expandMode
    //     visible: selected_effect && (selected_effect.has_ui)
    //     icon.name: "view"
    //     width: 60
    //     height: 60
    //     onClicked: {
    //         selected_effect.hide_sliders(false);
    //         selected_effect.expand_clicked();
    //     }
    //     Material.background: "white"
    //     Material.foreground: accent_color.name
    //     radius: 28
    //     Label {
    //         visible: title_footer.show_help 
    //         x: -92
    //         y: 19 
    //         text: "main controls"
    //         horizontalAlignment: Text.AlignRight
    //         width: 82
    //         height: 9
    //         z: 1
    //         color: "white"
    //         font {
    //             pixelSize: 14
    //             capitalization: Font.AllUppercase
    //         }
    //     }
    // }
}
