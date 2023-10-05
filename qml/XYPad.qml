import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "../qml/polyconst.js" as Constants

    Item {
        x: 0
        id: time_scale
        width: 1280
        height: 620
        property int step_height: 354
        property string num_param: knobs.spotlight_entries.length


        Column {
            x: 15
            y: 20
            spacing: 26 
            height: 600
            width: 126
            visible: num_param > 0

            Repeater {
                id: left_rep
                model: knobs.spotlight_entries.slice(0, 5) 

                ValueButton {
                    width: 126
                    height: (590 - (26 * (Math.min(num_param, 5) - 1))) / Math.min(num_param, 5) 
                    // checked: control.selected_param == modelData[1] && control.selected_effect == modelData[0]
                    checked: true
                    onClicked: {
                        // control.selected_effect = modelData[0]
                        // control.selected_param = modelData[1]
                        // slider.Material.foreground = Constants.rainbow[index]
                        // slider.force_update = !(slider.force_update)
                        if (modelData[2].indexOf("x") >= 0){
                            knobs.spotlight_set_y_remove_x(modelData[0], modelData[1]);
                        } else if (modelData[2].indexOf("y") >= 0){
                            knobs.toggle_spotlight_binding(modelData[0], modelData[1], "y");
                        } else {
                            knobs.toggle_spotlight_binding(modelData[0], modelData[1], "x");
                        }
                    }
                    onPressedChanged: {
                        if (pressed){
                            // knobs.set_knob_current_effect(modelData[0], modelData[1]);
                            if (patch_single.more_hold){
                                patch_single.more_hold = false;
                                patchStack.push("More.qml", {"current_effect": modelData[0], "row_param": modelData[1]});
                            }
                        }
                    }
                    Material.foreground: Constants.rainbow[index]
                    text: currentEffects[modelData[0]]["controls"][modelData[1]].name.slice(0,6)
                    value: currentEffects[modelData[0]]["controls"][modelData[1]].value.toFixed(2)

                    PolyButton {
                        visible: modelData[2].indexOf("x") >= 0
                        x: 111
                        y: 19 
                        height: 26
                        width: 26
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: "white"
                        border_color: Constants.rainbow[index]
                        background_color: Constants.background_color
                        text: "X"
                        font_size: 24
                    }

                    PolyButton {
                        visible: modelData[2].indexOf("y") >= 0
                        x: 111 
                        y: 50
                        height: 26
                        width: 26
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: "white"
                        border_color: Constants.rainbow[index]
                        background_color: Constants.background_color
                        text: "Y"
                        font_size: 24
                    }
                }
            }
        }

        Rectangle {
            x: 164
			y: 20
            width: num_param > 5 ? 954 : 1097
            height: 600 
			id: stepCol

			MultiPointTouchArea {
				id: mouseArea
				anchors.fill: parent
				minimumTouchPoints: 1
				maximumTouchPoints: 1
				// hoverEnabled: true
				onTouchUpdated: {
					var point = touchPoints[0];
					// console.log("position is", point.y);
					if (point == undefined){
						return;
					}
					var x1 = point.x;
					var y1 = point.y;
                    touch_indicator.x = x1;
                    touch_indicator.y = y1;
					// console.log("step child is", c.children[0].step_id, "point y is", point.y);
					knobs.xy_pad_change(x1 / parent.width, y1 / parent.height);
				}

			}

			color: Qt.rgba(0, 0, 0, 0)
			border { 
				width:1; 
				color: Constants.outline_color
			}

            Rectangle {
                x: parent.width / 2
                y: 0
                width: 2
                height: parent.height 
				color: Constants.outline_color
            }

            Rectangle {
                x: 0
                y: parent.height / 2
                width: parent.width
                height: 2
				color: Constants.outline_color
            }

            Rectangle {
                id: touch_indicator
                x:parent.width / 2
                y: parent.height / 2
                width:62
                height: 62 
                color: Qt.rgba(0, 0, 0, 0)
                radius: 31
                border { 
                    width:2; 
                    color: Qt.rgba(0, 0, 0, 0)
                }

                Repeater {
                    model: knobs.spotlight_entries

                    Rectangle {
                        x: (-5*index)
                        y: (-5*index)
                        width:40 + (10*index)
                        height: 40 + (10*index)
                        color: Qt.rgba(0, 0, 0, 0)
                        radius: 20 + (5*index)
                        border { 
                            width:2; 
                            color: Constants.rainbow[index]
                        }
                        visible: modelData[2].indexOf("x") >= 0 || modelData[2].indexOf("y") >= 0
                    }
                }
            }

		}

        Column {
            x: 1140
            y: 20
            spacing: 26 
            height: 600
            width: 126
            visible: num_param > 5

            Repeater {
                id: right_rep
                model: knobs.spotlight_entries.slice(5, 10) 

                ValueButton {
                    width: 126
                    height: (590 - (26 * (Math.min(num_param, 5) - 1))) / Math.min(num_param, 5) 
                    // checked: control.selected_param == modelData[1] && control.selected_effect == modelData[0]
                    checked: true
                    onClicked: {
                        // control.selected_effect = modelData[0]
                        // control.selected_param = modelData[1]
                        // slider.Material.foreground = Constants.rainbow[index]
                        // slider.force_update = !(slider.force_update)
                        if (modelData[2].indexOf("x") >= 0){
                            knobs.spotlight_set_y_remove_x(modelData[0], modelData[1]);
                        } else if (modelData[2].indexOf("y") >= 0){
                            knobs.toggle_spotlight_binding(modelData[0], modelData[1], "y");
                        } else {
                            knobs.toggle_spotlight_binding(modelData[0], modelData[1], "x");
                        }
                    }
                    onPressedChanged: {
                        if (pressed){
                            // knobs.set_knob_current_effect(modelData[0], modelData[1]);
                            if (patch_single.more_hold){
                                patch_single.more_hold = false;
                                patchStack.push("More.qml", {"current_effect": modelData[0], "row_param": modelData[1]});
                            }
                        }
                    }
                    Material.foreground: Constants.rainbow[index+5]
                    text: currentEffects[modelData[0]]["controls"][modelData[1]].name.slice(0,6)
                    value: currentEffects[modelData[0]]["controls"][modelData[1]].value.toFixed(2)

                    PolyButton {
                        visible: modelData[2].indexOf("x") >= 0
                        x: -13
                        y: 19 
                        height: 26
                        width: 26
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: "white"
                        border_color: Constants.rainbow[index+5]
                        background_color: Constants.background_color
                        text: "X"
                        font_size: 24
                    }

                    PolyButton {
                        visible: modelData[2].indexOf("y") >= 0
                        x: -13
                        y: 50
                        height: 26
                        width: 26
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: "white"
                        border_color: Constants.rainbow[index+5]
                        background_color: Constants.background_color
                        text: "Y"
                        font_size: 24
                    }
                }
            }
        }

    }

