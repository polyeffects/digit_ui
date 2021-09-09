import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import "../qml/polyconst.js" as Constants
import "module_info.js" as ModuleInfo

Item { 
	id: control
	width: 465
	height: 462
	property string current_effect 
	property var params: ['blend_param', 'feedback_param', 'position_param', 
				'pitch_param', 'reverb_param', 'spread_param']
	property string selected_parameter: "blend_param"

	Row {
		x: 29
		y: 31
		spacing: 30


		Grid {
			spacing: 21 
			height: 462
			width: 308
			rows: 3

			Repeater {
				model: params 

				ValueButton {
					width: 154
					height: 140
					// checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
					checked: control.selected_parameter == modelData
					onClicked: {
						 control.selected_parameter = modelData
						 slider.Material.foreground = Constants.rainbow[index]
						 slider.force_update = !(slider.force_update)
					}
                    onPressedChanged: {
                        if (pressed){
                            knobs.set_knob_current_effect(current_effect, modelData);
                            if (patch_single.more_hold){
                                patch_single.more_hold = false;
                                patchStack.push("More.qml", {"current_effect": current_effect, "row_param": modelData});
                            }
                        }
                    }
					Material.foreground: Constants.rainbow[index]
					text: currentEffects[current_effect]["controls"][modelData].name
					value: currentEffects[current_effect]["controls"][modelData].value.toFixed(2)
				}
			}
		}

		Slider {
			id: slider
			height: control.height
			width: 70 
			leftPadding: 30
			show_labels: false
			property string v_type: ModuleInfo.effectPrototypes[effect_type]["controls"][selected_parameter].length > 4 ? ModuleInfo.effectPrototypes[effect_type]["controls"][selected_parameter][4] : "float"
			property bool is_log: false
			property bool force_update: false
			snapMode: Slider.SnapAlways
			stepSize: v_type == "int" ? 1.0 : 0.0
			from: is_log ? 20 : currentEffects[current_effect]["controls"][selected_parameter].rmin
			to: is_log ? 20000 : currentEffects[current_effect]["controls"][selected_parameter].rmax
			title: currentEffects[current_effect]["controls"][selected_parameter].name
			orientation: Qt.Vertical
			Material.foreground: Constants.rainbow[0]
			value: slider.force_update, currentEffects[current_effect]["controls"][selected_parameter].value

			function logslider(position) {
				// linear in to log out
				// input position will be between 0 and 1
				var minp = 0;
				var maxp = 1;

				// The output result should be between 20 an 20000
				var minv = Math.log(20);
				var maxv = Math.log(20000);

				// calculate adjustment factor
				var scale = (maxv-minv) / (maxp-minp);

				return Math.exp(minv + scale*(position-minp));
			}

			function logposition(value) {
				// log in to linear out
				// input position will be between 0 and 1
				var minp = 0;
				var maxp = 1;

				// The output result should be between 20 an 200000
				var minv = Math.log(20);
				var maxv = Math.log(20000);

				// calculate adjustment factor
				var scale = (maxv-minv) / (maxp-minp);

				return (Math.log(value)-minv) / scale + minp;
			}


			onMoved: {
				if (is_log){
					knobs.ui_knob_change(current_effect, selected_parameter, logposition(value));
				} else {
					knobs.ui_knob_change(current_effect, selected_parameter, value);
				}
			}
			onPressedChanged: {
				if (pressed){
					knobs.set_knob_current_effect(current_effect, selected_parameter);
                    if (patch_single.more_hold){
                        patch_single.more_hold = false;
                        patchStack.push("More.qml", {"current_effect": current_effect, "row_param": selected_parameter});
                    }
				}
			}
		}
	}
}
