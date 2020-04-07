import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "polyconst.js" as Constants

Item {
    property string effect_id
    property string row_param: "int_osc"
    property var icons: ["OFF.png", "Sine.png", "Sawtooth.png", "Triangle.png"]
    z: 3
    height:540
    width:1280

    function remove_suffix(x)
    {
        return x.replace(/\.[^/.]+$/, "") 
    }

    Row {
        anchors.centerIn: parent
        spacing: 50

        Repeater {
            model: icons
            IconButton {
                icon.source: "../icons/digit/warps/"+modelData
                width: 180
                height: 300
                icon.width: 100
                icon.height: 100
                checked: index == Math.floor(currentEffects[effect_id]["controls"][row_param].value)
                onClicked: {
                    knobs.ui_knob_change(effect_id, row_param, index);
                }
                // Material.background: "white"
                Material.foreground: "transparent"
                Material.accent: "white"
                radius: 10
                Label {
                    x: 0
                    y: 30 
                    text: remove_suffix(modelData)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    width: 180
                    height: 22
                    z: 1
                    color: "white"
                    font {
                        pixelSize: 18
                        capitalization: Font.AllUppercase
                    }
                }
            }
        }

    }
}
