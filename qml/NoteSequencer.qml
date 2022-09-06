import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "../qml/polyconst.js" as Constants

// ApplicationWindow {

//     Material.theme: Material.Dark
//     Material.primary: Material.Green
//     Material.accent: Material.Pink

//     readonly property int baseFontSize: 20 
//     readonly property int tabHeight: 60 
//     readonly property int fontSizeExtraSmall: baseFontSize * 0.8
//     readonly property int fontSizeMedium: baseFontSize * 1.5
//     readonly property int fontSizeLarge: baseFontSize * 2
//     readonly property int fontSizeExtraLarge: baseFontSize * 5
//     width: 800
//     height: 580
//     title: "Drag & drop example"
//     visible: true

    Item {
        x: 0
        id: time_scale
        width: 1280
        height: 620
        property string effect: "note1"
        property string effect_type: "note_sequencer" // _ext"
        property bool is_bpm_type: effect_type == "note_sequencer"
        property int selected_point: -1
        property int point_updated: 1
        property int num_steps: currentEffects[effect]["controls"]["steps"].value
        property int step_height: 354

        // q is 0-4 gain is +-18 db
        property var step_values: [0.2, 1, 0.5, 0.2, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0 ]
        property var step_triggers: [1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0 ]
        
		property int current_step: currentEffects[effect]["broadcast_ports"]["current_step_out"].value
        // Row {
        //
        // ActionIcons {

        // }
		Component.onDestruction: {
			// if we're not visable, turn off broadcast
			// console.log("setting broadcast false in step");
			knobs.set_broadcast(effect, false);
		}
		Component.onCompleted: {
			// console.log("setting broadcast true in step");
			knobs.set_broadcast(effect, true);
		}

		Item {
			x: 24
			y: 0
			width: 145
			height: 548
			IconButton {
				property real local_val: currentEffects[effect]["controls"]["play"].value
				y: 120
				icon.source: "../icons/digit/step_sequencer/play icon.png" 
				rightPadding: 0
				leftPadding: 0
				visible: is_bpm_type
				checked: currentEffects[effect]["controls"]["play"].value == 0 
				width: 100
				height: 70
				onClicked: {
					knobs.ui_knob_change(effect, "play", 1.0 - currentEffects[effect]["controls"]["play"].value);
					if (currentEffects[effect]["controls"]["back_gate"].value == 1){
						knobs.ui_knob_change(effect, "back_gate", 0);
					}
				}
				Material.background: is_bpm_type && currentEffects[effect]["controls"]["play"].value ? Constants.poly_pink : "transparent"
				Material.foreground: local_val == 0 ? Constants.poly_pink : "black"
				Material.accent: Constants.poly_pink 
				radius: 11
			}

			IconButton {
				property real local_val: currentEffects[effect]["controls"]["back_gate"].value
				y: 237
				icon.source: "../icons/digit/step_sequencer/reverse-play-icon.png" 
				rightPadding: 0
				leftPadding: 0
				visible: is_bpm_type
				checked: currentEffects[effect]["controls"]["back_gate"].value == 0 
				width: 100
				height: 70
				onClicked: {
					knobs.ui_knob_change(effect, "back_gate", 1.0 - currentEffects[effect]["controls"]["back_gate"].value);
					if (currentEffects[effect]["controls"]["play"].value == 1){
						knobs.ui_knob_change(effect, "play", 0);
					}
				}
				Material.background: is_bpm_type && currentEffects[effect]["controls"]["back_gate"].value ? Constants.poly_pink : "transparent"
				Material.foreground: local_val == 0 ? Constants.poly_pink : "black"
				Material.accent: Constants.poly_pink 
				radius: 11
			}

		}

		Rectangle {
			x: 145
			y: 0
			width: 1135
			height: 80

			color: Qt.rgba(0, 0, 0, 0)
			border { 
				width:1; 
				color: Constants.outline_color
			}

			Text {
				x: 18
				anchors.verticalCenter: parent.verticalCenter
				text: "STEPS"
				color: "white"
				font.pixelSize: 24
			}

			SpinBox {
				width: 180
				height: 60
				x: 96
				anchors.verticalCenter: parent.verticalCenter
				font.pixelSize: 24
				from: 1
				to: 16
				Material.foreground: Constants.poly_pink
				value: currentEffects[effect]["controls"]["steps"].value
				onValueModified: {
					knobs.ui_knob_change(effect, "steps", Number(value));
				}

			}

			Text {
				x: 309
				anchors.verticalCenter: parent.verticalCenter
				text: "BPM"
				visible: is_bpm_type
				color: "white"
				font.pixelSize: 24
			}

			SpinBox {
				width: 180
				height: 60
				x: 379
				y: 0
				visible: is_bpm_type
				anchors.verticalCenter: parent.verticalCenter
				font.pixelSize: 24
				from: 20
				to: 320
				Material.foreground: Constants.poly_pink
				value: is_bpm_type ? currentEffects[effect]["controls"]["bpm"].value : 20
				onValueModified: {
					knobs.ui_knob_change(effect, "bpm", Number(value));
				}

			}

			Text {
				x: 590
				anchors.verticalCenter: parent.verticalCenter
				text: "OCTAVE"
				color: "white"
				font.pixelSize: 24
			}

			SpinBox {
				width: 180
				height: 60
				x: 690
				y: 0
				anchors.verticalCenter: parent.verticalCenter
				font.pixelSize: 24
				from: -4
				to: 4
				Material.foreground: Constants.poly_pink
				value: currentEffects[effect]["controls"]["octave"].value 
				onValueModified: {
					knobs.ui_knob_change(effect, "octave", Number(value));
				}

			}
		}
        
        Rectangle {
            x: 145
			y: 80
            width: 995
            height: 468 
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
                        time_scale.selected_point = -1;
						return;
					}
					var c = stepCol.childAt(point.x, 150) // ignore vertical point.y)

					var f = ( time_scale.step_height - point.y + 15) / time_scale.step_height;
					if (!c || !(c.children[0]) || typeof(c.children[0].step_id) == "undefined"){
						return;
					}
                    time_scale.selected_point = c.children[0].step_id;
					// console.log("step child is", c.children[0].step_id, "point y is", point.y);
					// time_scale.step_valuesChanged();
					knobs.ui_knob_change(effect, "val"+c.children[0].step_id, Math.round(f*12));
				}

			}

			color: Qt.rgba(0, 0, 0, 0)
			border { 
				width:1; 
				color: Constants.outline_color
			}


                Repeater {
                    model: time_scale.num_steps
                    Item {
						y: 18
						x: 20+(60*index)
                        // spacing: 15
						height: parent.height
						width: 995
                    
                        Rectangle {
                            x: 0
                            y: 0
							property int step_id: index
                            id: rect
                            width:52
                            height: time_scale.step_height
                            color: Qt.rgba(0.0,0.0,0.0,0.0)
                            Rectangle {
                                x: 0
                                y: (time_scale.step_height - time_scale.step_height * (currentEffects[effect]["controls"]["val"+index].value / 12)) - 15
                                width: parent.width
								height: 44 //
                                color: index == time_scale.current_step ? Constants.rainbow[index] : Qt.rgba(0, 0, 0, 0)
                                radius: 7
                                border { 
                                    width:2; 
                                    color: Constants.rainbow[index]
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: Constants.note_names[Math.floor(currentEffects[effect]["controls"]["val"+index].value)]
                                    color: index != time_scale.current_step ? Constants.rainbow[index] : Qt.rgba(0, 0, 0, 1)
                                    font.pixelSize: 20
                                }
                            }
                            // color: time_scale.eq_data[index]["enabled"] ? Material.color(Material.Indigo, Material.Shade200) : Material.color(Material.Grey, Material.Shade200)  
                            // border { width:1; color: Material.color(Material.Grey, Material.Shade100)}

                            // Text {
                            //     anchors.centerIn: parent
                            //     text: index+1
                            //     color: "white"
                            //     font.pixelSize: fontSizeMedium
                            // }
                        }

                        Rectangle {
                            x: 0
                            y: time_scale.step_height + 30
                            width:52
                            height: 52 
                            color: Qt.rgba(0, 0, 0, 0)
                            radius: 7
                            border { 
                                width:2; 
                                color: Constants.rainbow[index]
                            }
                            Text {
                                anchors.centerIn: parent
                                text: index == time_scale.selected_point ? Constants.note_names[Math.floor(currentEffects[effect]["controls"]["val"+index].value)] : index+1
                                color: Constants.rainbow[index]
                                font.pixelSize: 20
                            }
                        }
                    }
                }
            }


		Rectangle {
			x: 1140
			y: 80
            width: 140
            height: 468 


			// Slider {
			// 	y: 22
			// 	anchors.horizontalCenter: parent.horizontalCenter
			// 	width: 60 
			// 	height: 300
			// 	orientation: Qt.Vertical
			// 	title: "GLIDE"
			// 	value: currentEffects[effect]["controls"]["glide"].value
			// 	from: 0.0
			// 	to: 1
			// 	stepSize: 0.01
			// 	onMoved: {
			// 		knobs.ui_knob_change(effect, "glide", value);
			// 	}
			// 	Material.foreground: Constants.rainbow[7]
			// 	onPressedChanged: {
			// 		if (pressed){
			// 			knobs.set_knob_current_effect(effect, "glide");
			// 		}
			// 	}
			// }

			color: Qt.rgba(0, 0, 0, 0)
			border { 
				width:1; 
				color: Constants.outline_color
			}
		}

    }

