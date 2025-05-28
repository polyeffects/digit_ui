import "controls" as PolyControls
import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2

import "polyconst.js" as Constants
PatchBayEffect {
    id:root
    width: 58
    height: 128
    radius: 0
    // effect_id: port_name
    color: Constants.background_color
    border { width:1; color: "white"}

    Label {
        // color: "#ffffff"
        text: effect_id.slice(-1,)
        x:21
        y:26
        width:16
        horizontalAlignment: Text.AlignHCenter
        z: 1
        color: "white"
        font {
            pixelSize: 36
            capitalization: Font.AllUppercase
        }
    }
    Rectangle {
        color: Constants.audio_color
        x: 21
        y: 79
        width: 16
        height: 16
        radius: 8
    }

        // MouseArea {
        //     id: mouseArea
        //     z: -1
        //     anchors.fill: parent
        //     // drag.target: patch_bay.current_mode == PatchBay.Move ? parent : undefined
        //     onPressed: {
        //         // check mode: move, delete, connect, open
        //         if (patch_bay.currentMode == PatchBay.Connect){
        //             connect_clicked();
        //         }
        //     }

        // }
        //
        // Component.onCompleted: {
        //     patch_bay.effect_map[effect_id] = root;
        // }
}
