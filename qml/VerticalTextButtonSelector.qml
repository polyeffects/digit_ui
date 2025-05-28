import "controls" as PolyControls
import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "polyconst.js" as Constants

Item {
	id: textSelector
    property string current_effect
    property string row_param: "range_param"
    property var labels: ['1/8 Hz', '2 Hz', '130.8 Hz']
    property var sub_labels: ['movements', 'rhythms &\n modulations', 'audible tones']
	property int value_offset: 0
	property int pixel_size: 25
	property int button_height: 120
	property int button_width: 160
	property int button_spacing: 46
	property int label_offset: 30
    property color color: Constants.poly_purple 
	property bool center: false
	property var centerTarget: textSelector
    z: 3
    height:300
    width: button_width

    Column {
		width: parent.width
		height: parent.height
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
                text: modelData + '\n' + sub_labels[index]
                font {
                    pixelSize: pixel_size
                    capitalization: Font.AllUppercase
                }
            }
        }

    }
}
