import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

import "polyconst.js" as Constants


IconButton {
	property string row_param: "Amp_5"
	property string current_effect 
	property string icon_source 
	icon.source: "../icons/digit/"+icon_source
	width: 70
	height: 70
	icon.width: 60
	checked: currentEffects[current_effect]["controls"][row_param].value >= 1
	onClicked: {
		knobs.ui_knob_change(current_effect, row_param, Number(!(currentEffects[current_effect]["controls"][row_param].value >= 1)));
	}
	// Material.background: "white"
	Material.foreground: accent_color.name
	radius: 30
	// Label {
	//     visible: title_footer.show_help 
	//     x: 0
	//     y: 20 
	//     text: modelData
	//     horizontalAlignment: Text.AlignHCenter
	//     width: 180
	//     height: 22
	//     z: 1
	//     color: accent_color.name
	//     font {
	//         pixelSize: 18
	//         capitalization: Font.AllUppercase
	//     }
	// }
	//
}
