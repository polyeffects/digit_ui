import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

Item {
    id: control
    height: 287
    width:  150
    property string row_param: "Amp_5"
    property string current_effect 
    property string title: currentEffects[current_effect]["controls"][row_param].name 
	Material.foreground: Constants.poly_pink


	Slider {
		width: parent.width 
		height: parent.height
		orientation: Qt.Vertical
        title: control.title
		value: currentEffects[current_effect]["controls"][row_param].value
        from: currentEffects[current_effect]["controls"][row_param].rmin
        to: currentEffects[current_effect]["controls"][row_param].rmax
		stepSize: 0.0
		onMoved: {
			knobs.ui_knob_change(current_effect, row_param, value);
		}
        onPressedChanged: {
            if (pressed){
                knobs.set_knob_current_effect(current_effect, row_param);
				if (patch_single.more_hold){
					patch_single.more_hold = false;
					patchStack.push("More.qml", {"current_effect": current_effect, "row_param": row_param});
				}
            }
        }
	}


}
