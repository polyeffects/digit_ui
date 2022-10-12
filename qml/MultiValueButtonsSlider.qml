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
	property string param_base: 'mix'
	property int selected_parameter: 1
	property int num_row: 3
	property int num_col: 4
    property bool force_update: false
    property var titles: ["left", "right", "send"]

	Row {
		x: 29
		y: 31
		spacing: 30


		Grid {
			spacing: 21 
			height: 650
			width: 187
			rows: 3

			Repeater {
				model: titles 


                Button {
                    height: 145
                    width: 140
                    text: modelData
                    checked: control.selected_parameter == (index + 1)
                    onClicked: {
                        control.selected_parameter = index+1
                        // slider.Material.foreground = Constants.rainbow[index]
                        control.force_update = !(control.force_update)
                    }

                    contentItem: Text {
                        text: modelData
                        color:  checked ? Constants.background_color : "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        // elide: Text.ElideRight
                        height: parent.height
                        wrapMode: Text.WordWrap
                        width: parent.width
                        font {
                            pixelSize: 24
                            capitalization: Font.AllUppercase
                        }
                    }

                    background: Rectangle {
                        width: parent.width
                        height: parent.height
                        color: checked ? Constants.short_rainbow[index+1] : Constants.poly_dark_grey  
                        border.width: 0
                        radius: 20
                    }
                }
			}
		}

        Repeater {
            model: num_col 
            Slider {
                id: slider
                height: control.height - 20
                width: (837 / num_col) - 15
                leftPadding: 30
                show_labels: true
                property bool is_log: false
                property string slider_param: control.param_base+"_"+(index+1)+"_"+control.selected_parameter
                // property string v_type: ModuleInfo.effectPrototypes[effect_type]["controls"][slider_param].length > 4 ? ModuleInfo.effectPrototypes[effect_type]["controls"][slider_param][4] : "float"
                snapMode: Slider.SnapAlways
                // stepSize: v_type == "int" ? 1.0 : 0.0
                from: is_log ? 20 : currentEffects[current_effect]["controls"][slider_param].rmin
                to: is_log ? 20000 : currentEffects[current_effect]["controls"][slider_param].rmax
                title: currentEffects[current_effect]["controls"][slider_param].name
                orientation: Qt.Vertical
                Material.foreground: Constants.short_rainbow[selected_parameter]
                value: control.force_update, currentEffects[current_effect]["controls"][slider_param].value

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
                        knobs.ui_knob_change(current_effect, slider_param, logposition(value));
                    } else {
                        // console.log("slider_param is", slider_param);
                        knobs.ui_knob_change(current_effect, slider_param, value);
                    }
                }
                onPressedChanged: {
                    if (pressed){
                        knobs.set_knob_current_effect(current_effect, slider_param);
                        if (patch_single.more_hold){
                            patch_single.more_hold = false;
                            patchStack.push("More.qml", {"current_effect": current_effect, "row_param": slider_param});
                        }
                    }
                }
            }
        }
	}
}
