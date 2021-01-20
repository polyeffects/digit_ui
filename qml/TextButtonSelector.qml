import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "polyconst.js" as Constants

Item {
	id: textSelector
    property string current_effect
    property string row_param: "t_range_param"
    property var labels: ['/4', 'x1', 'x4']
	property int value_offset: 0
	property int pixel_size: 36
	property int button_height: 100
	property int button_width: 120
	property int button_spacing: 46
	property int label_offset: 30
    property color color: Constants.poly_purple 
	property bool center: false
	property var centerTarget: textSelector
    z: 3
    height: button_height
    width: 589

    Row {
		anchors.centerIn: center ? centerTarget : undefined
        spacing: button_spacing

        Repeater {
            model: labels
            RoundButton {
                width: button_width
                height: button_height
                checked: index+value_offset == Math.floor(currentEffects[current_effect]["controls"][row_param].value)
                onClicked: {
                    knobs.ui_knob_change(current_effect, row_param, index+value_offset);
                }
                // Material.background: "white"
                Material.accent: Constants.poly_dark_grey
				Material.background: checked ? color : "transparent"
				Material.foreground: !checked ? color : "black"
                radius: 10
                text: modelData
                font {
                    pixelSize: pixel_size
                    capitalization: Font.AllUppercase
                }
            }
        }

    }
}
