import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "polyconst.js" as Constants

Item {
    property string current_effect
    property string row_param: "int_osc"
    property var icons: ["OFF.png", "Sine.png", "Sawtooth.png", "Triangle.png"]
	property string icon_prefix: "../icons/digit/warps/" 
	property int value_offset: 0
	property int icon_size: 100
	property int button_height: 300
	property int button_width: 180
	property int button_spacing: 50
	property int label_offset: 30
    z: 3
    height:540
    width:1280

    function remove_suffix(x)
    {
        return x.replace(/\.[^/.]+$/, "") 
    }

    Row {
        anchors.centerIn: parent
        spacing: button_spacing

        Repeater {
            model: icons
            IconButton {
                icon.source: icon_prefix+modelData
                width: button_width
                height: button_height
                icon.width: icon_size
                icon.height: icon_size
                checked: index+value_offset == Math.floor(currentEffects[current_effect]["controls"][row_param].value)
                onClicked: {
                    knobs.ui_knob_change(current_effect, row_param, index+value_offset);
                }
                // Material.background: "white"
                Material.foreground: "transparent"
                Material.accent: "white"
                radius: 10
                Label {
                    x: 0
                    y: label_offset 
                    text: remove_suffix(modelData)
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    width: button_width
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
