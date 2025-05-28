import "controls" as PolyControls
import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "polyconst.js" as Constants

Item {
    property string current_effect
    property string row_param: "t_mode_param"
    property var icons: ['Coin Toss.png', 'Random Ratio.png', 'Percussive triggers.png']
	property string icon_prefix: "../icons/digit/marbles/gate/Gate Control icons/" 
	property int value_offset: 0
	property int icon_size: 60
	property int button_height: 128
	property int button_width: 296
	property int button_spacing: 9
	property int label_offset: 90
    z: 3
    height:422
    width:296

    function remove_suffix(x)
    {
        return x.replace(/\.[^/.]+$/, "").replace(/_/g, " ")
    }

    Column {
        anchors.centerIn: parent
        spacing: button_spacing

        Repeater {
            model: icons
            IconButton {
                has_border: true
                icon.source: icon_prefix+modelData
                width: button_width
                height: button_height
                icon.width: icon_size
                icon.height: icon_size
                checked: index+value_offset == Math.floor(currentEffects[current_effect]["controls"][row_param].value)
                onClicked: {
                    knobs.ui_knob_change(current_effect, row_param, index+value_offset);
                }
				Material.background: checked ? Constants.poly_pink : "transparent"
				Material.foreground: !checked ? Constants.poly_pink : "black"
				Material.accent: Constants.poly_pink 
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
                    // color: "white"
                    font {
                        pixelSize: 18
                        capitalization: Font.AllUppercase
                    }
                }
            }
        }

    }
}
