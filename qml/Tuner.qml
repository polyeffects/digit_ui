import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "../qml/polyconst.js" as Constants

    Item {
        x: 0
        id: tuner_obj
        width: 1280
        height: 620
        property string effect: "tuner1"
        property string effect_type: "tuner" 
        property real tuning: currentEffects[effect]["controls"]["tuning"].value

        // property var step_values: [0.2, 1, 0.5, 0.2, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0 ]
        // property var step_triggers: [1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0 ]
        
		property real cent: currentEffects[effect]["broadcast_ports"]["cent"].value
		property real freq_out: currentEffects[effect]["broadcast_ports"]["freq_out"].value
		property int note: currentEffects[effect]["broadcast_ports"]["note"].value
		property int current_offset: Math.abs(cent) / 3.8 // 13 colours for 50 cents, 3.8 cents per colour
		// property int octave: currentEffects[effect]["broadcast_ports"]["octave"].value
		// property int accuracy: currentEffects[effect]["broadcast_ports"]["accuracy"].value
		// property int strobe: currentEffects[effect]["broadcast_ports"]["strobetoui"].value
		property real rms: currentEffects[effect]["broadcast_ports"]["rms"].value
        property var tuner_rainbow: ['#20FF79', '#C3FF76', '#FFFA77', '#FFD645', '#FFB039', '#FF8540', '#FF6464', '#FF2C6B', '#FF2BB7', '#FF75D0', '#E680FF', '#AC8EFF', '#2077EE', '#2077EE', '#2077EE', '#2077EE']
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


        Image {
            x: 51
            y: 80
            source: "../icons/digit/tuner/cross.png"
            visible: cent > 10
        }

        Image {
            x: 176
            y: 48
            width: 121
            height: 136
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles.png"
                icon.width: 121
                icon.height: 136
                icon.color: cent < 0 ? tuner_rainbow[current_offset + 3] : current_offset < 3 ? tuner_rainbow[3 - current_offset] : tuner_rainbow[current_offset-3]
                enabled: false
            }
        }
        Item {
            x: 278
            y: 48
            width: 121
            height: 136
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles.png"
                icon.width: 121
                icon.height: 136
                icon.color: cent < 0 ? tuner_rainbow[current_offset + 2] : current_offset < 2 ? tuner_rainbow[2 - current_offset] : tuner_rainbow[current_offset-2]
                enabled: false
            }
        }

        Item {
            x: 381
            y: 48
            width: 121
            height: 136
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles.png"
                icon.width: 121
                icon.height: 136
                icon.color: cent < 0 ? tuner_rainbow[current_offset + 1] : current_offset < 1 ? tuner_rainbow[1 - current_offset] : tuner_rainbow[current_offset-1]
                enabled: false
            }
        }

        Text {
            x: 547
            y: 10
            text: Constants.note_names[note]
            color: tuner_rainbow[current_offset];
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            // elide: Text.ElideRight
            height: 200
            width: 169
            font {
                pixelSize: 200
                // capitalization: Font.AllUppercase
            }
        }

        Item {
            x: 748
            y: 48
            z: 2
            width: 121
            height: 136
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles_rev.png"
                icon.width: 121
                icon.height: 136
                icon.color: cent > 0 ? tuner_rainbow[current_offset + 1] : current_offset < 1 ? tuner_rainbow[1 + current_offset] : tuner_rainbow[current_offset-1]
                enabled: false
            }
        }

        Item {
            x: 845
            y: 48
            z: 1
            width: 121
            height: 136
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles_rev.png"
                icon.width: 121
                icon.height: 136
                icon.color: cent > 0 ? tuner_rainbow[current_offset + 2] : current_offset < 2 ? tuner_rainbow[2 - current_offset] : tuner_rainbow[current_offset-2]
                enabled: false
            }
        }
        Item {
            x: 947
            y: 48
            z: 0
            width: 121
            height: 136
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles_rev.png"
                icon.width: 121
                icon.height: 136
                icon.color: cent > 0 ? tuner_rainbow[current_offset + 3] : current_offset < 3 ? tuner_rainbow[3 - current_offset] : tuner_rainbow[current_offset-3]
                // icon.color: cent < 0 ? tuner_rainbow[current_offset + 3] : current_offset < 3 ? tuner_rainbow[3 - current_offset] : tuner_rainbow[current_offset-3]
                enabled: false
            }
        }

        Image {
            x: 1145
            y: 80
            source: "../icons/digit/tuner/tick.png"
            visible: cent < 10
        }

        Text {
            x: 549
            y: 231
            text: freq_out > 0 ? Math.floor(freq_out)+" Hz" : "NO SIGNAL"
            color: "white" // Constants.poly_grey // checked ? Constants.background_color : "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            // elide: Text.ElideRight
            height: 73
            width: 188
            font {
                pixelSize: 36
                capitalization: Font.AllUppercase
            }
        }

        Image {
            x: 19
            y: 325
            source: "../icons/digit/tuner/tuner_rainbow_lines.png"
        }

        Item {
            x: 624 + (cent * 12.6) // cent per pixel width / 50
            y: 300
            z: 2
            width: 34
            height: 260
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_line.png"
                icon.width: 34
                icon.height: 260
                icon.color: tuner_rainbow[current_offset];
                enabled: false
            }
        }

		// Item {
		// 	x: 24
		// 	y: 0
		// 	width: 145
		// 	height: 548
		// 	IconButton {
		// 		property real local_val: currentEffects[effect]["controls"]["play"].value
		// 		y: 120
		// 		icon.source: "../icons/digit/step_sequencer/play icon.png" 
		// 		rightPadding: 0
		// 		leftPadding: 0
		// 		visible: is_bpm_type
		// 		checked: currentEffects[effect]["controls"]["play"].value == 0 
		// 		width: 100
		// 		height: 70
		// 		onClicked: {
		// 			knobs.ui_knob_change(effect, "play", 1.0 - currentEffects[effect]["controls"]["play"].value);
		// 			if (currentEffects[effect]["controls"]["back_gate"].value == 1){
		// 				knobs.ui_knob_change(effect, "back_gate", 0);
		// 			}
		// 		}
		// 		Material.background: is_bpm_type && currentEffects[effect]["controls"]["play"].value ? Constants.poly_pink : "transparent"
		// 		Material.foreground: local_val == 0 ? Constants.poly_pink : "black"
		// 		Material.accent: Constants.poly_pink 
		// 		radius: 11
		// 	}

		// 	IconButton {
		// 		property real local_val: currentEffects[effect]["controls"]["back_gate"].value
		// 		y: 237
		// 		icon.source: "../icons/digit/step_sequencer/reverse-play-icon.png" 
		// 		rightPadding: 0
		// 		leftPadding: 0
		// 		visible: is_bpm_type
		// 		checked: currentEffects[effect]["controls"]["back_gate"].value == 0 
		// 		width: 100
		// 		height: 70
		// 		onClicked: {
		// 			knobs.ui_knob_change(effect, "back_gate", 1.0 - currentEffects[effect]["controls"]["back_gate"].value);
		// 			if (currentEffects[effect]["controls"]["play"].value == 1){
		// 				knobs.ui_knob_change(effect, "play", 0);
		// 			}
		// 		}
		// 		Material.background: is_bpm_type && currentEffects[effect]["controls"]["back_gate"].value ? Constants.poly_pink : "transparent"
		// 		Material.foreground: local_val == 0 ? Constants.poly_pink : "black"
		// 		Material.accent: Constants.poly_pink 
		// 		radius: 11
		// 	}

		// }

		// Rectangle {
		// 	x: 145
		// 	y: 0
		// 	width: 1135
		// 	height: 80

		// 	color: Qt.rgba(0, 0, 0, 0)
		// 	border { 
		// 		width:1; 
		// 		color: Constants.outline_color
		// 	}

		// 	Text {
		// 		x: 18
		// 		anchors.verticalCenter: parent.verticalCenter
		// 		text: "STEPS"
		// 		color: "white"
		// 		font.pixelSize: 24
		// 	}

		// 	SpinBox {
		// 		width: 180
		// 		height: 60
		// 		x: 96
		// 		anchors.verticalCenter: parent.verticalCenter
		// 		font.pixelSize: 24
		// 		from: 1
		// 		to: 16
		// 		Material.foreground: Constants.poly_pink
		// 		value: currentEffects[effect]["controls"]["steps"].value
		// 		onValueModified: {
		// 			knobs.ui_knob_change(effect, "steps", Number(value));
		// 		}

		// 	}

		// 	Text {
		// 		x: 309
		// 		anchors.verticalCenter: parent.verticalCenter
		// 		text: "BPM"
		// 		visible: is_bpm_type
		// 		color: "white"
		// 		font.pixelSize: 24
		// 	}

		// 	SpinBox {
		// 		width: 180
		// 		height: 60
		// 		x: 379
		// 		y: 0
		// 		visible: is_bpm_type
		// 		anchors.verticalCenter: parent.verticalCenter
		// 		font.pixelSize: 24
		// 		from: 20
		// 		to: 320
		// 		Material.foreground: Constants.poly_pink
		// 		value: is_bpm_type ? currentEffects[effect]["controls"]["bpm"].value : 20
		// 		onValueModified: {
		// 			knobs.ui_knob_change(effect, "bpm", Number(value));
		// 		}

		// 	}

		// 	Text {
		// 		x: 590
		// 		anchors.verticalCenter: parent.verticalCenter
		// 		text: "OCTAVE"
		// 		color: "white"
		// 		font.pixelSize: 24
		// 	}

		// 	SpinBox {
		// 		width: 180
		// 		height: 60
		// 		x: 690
		// 		y: 0
		// 		anchors.verticalCenter: parent.verticalCenter
		// 		font.pixelSize: 24
		// 		from: -4
		// 		to: 4
		// 		Material.foreground: Constants.poly_pink
		// 		value: currentEffects[effect]["controls"]["octave"].value 
		// 		onValueModified: {
		// 			knobs.ui_knob_change(effect, "octave", Number(value));
		// 		}

		// 	}
		// }
        
        // Rectangle {
        //     x: 145
			// y: 80
        //     width: 995
        //     height: 468 
			// id: stepCol

			// MultiPointTouchArea {
				// id: mouseArea
				// anchors.fill: parent
				// minimumTouchPoints: 1
				// maximumTouchPoints: 1
				// // hoverEnabled: true
				// onTouchUpdated: {
					// var point = touchPoints[0];
					// // console.log("position is", point.y);
					// if (point == undefined){
        //                 time_scale.selected_point = -1;
						// return;
					// }
					// var c = stepCol.childAt(point.x, 150) // ignore vertical point.y)

					// var f = ( time_scale.step_height - point.y + 15) / time_scale.step_height;
					// if (!c || !(c.children[0]) || typeof(c.children[0].step_id) == "undefined"){
						// return;
					// }
        //             time_scale.selected_point = c.children[0].step_id;
					// // console.log("step child is", c.children[0].step_id, "point y is", point.y);
					// // time_scale.step_valuesChanged();
					// knobs.ui_knob_change(effect, "val"+c.children[0].step_id, Math.round(f*12));
				// }

			// }

			// color: Qt.rgba(0, 0, 0, 0)
			// border { 
				// width:1; 
				// color: Constants.outline_color
			// }


        //         Repeater {
        //             model: time_scale.num_steps
        //             Item {
						// y: 18
						// x: 20+(60*index)
        //                 // spacing: 15
						// height: parent.height
						// width: 995
                    
        //                 Rectangle {
        //                     x: 0
        //                     y: 0
							// property int step_id: index
        //                     id: rect
        //                     width:52
        //                     height: time_scale.step_height
        //                     color: Qt.rgba(0.0,0.0,0.0,0.0)
        //                     Rectangle {
        //                         x: 0
        //                         y: (time_scale.step_height - time_scale.step_height * (currentEffects[effect]["controls"]["val"+index].value / 12)) - 15
        //                         width: parent.width
								// height: 44 //
        //                         color: index == time_scale.current_step ? Constants.rainbow[index] : Qt.rgba(0, 0, 0, 0)
        //                         radius: 7
        //                         border { 
        //                             width:2; 
        //                             color: Constants.rainbow[index]
        //                         }
                                
        //                         Text {
        //                             anchors.centerIn: parent
        //                             text: Constants.note_names[Math.floor(currentEffects[effect]["controls"]["val"+index].value)]
        //                             color: index != time_scale.current_step ? Constants.rainbow[index] : Qt.rgba(0, 0, 0, 1)
        //                             font.pixelSize: 20
        //                         }
        //                     }
        //                     // color: time_scale.eq_data[index]["enabled"] ? Material.color(Material.Indigo, Material.Shade200) : Material.color(Material.Grey, Material.Shade200)  
        //                     // border { width:1; color: Material.color(Material.Grey, Material.Shade100)}

        //                     // Text {
        //                     //     anchors.centerIn: parent
        //                     //     text: index+1
        //                     //     color: "white"
        //                     //     font.pixelSize: fontSizeMedium
        //                     // }
        //                 }

        //                 Rectangle {
        //                     x: 0
        //                     y: time_scale.step_height + 30
        //                     width:52
        //                     height: 52 
        //                     color: Qt.rgba(0, 0, 0, 0)
        //                     radius: 7
        //                     border { 
        //                         width:2; 
        //                         color: Constants.rainbow[index]
        //                     }
        //                     Text {
        //                         anchors.centerIn: parent
        //                         text: index == time_scale.selected_point ? Constants.note_names[Math.floor(currentEffects[effect]["controls"]["val"+index].value)] : index+1
        //                         color: Constants.rainbow[index]
        //                         font.pixelSize: 20
        //                     }
        //                 }
        //             }
        //         }
        //     }


		// Rectangle {
		// 	x: 1140
		// 	y: 80
            // width: 140
            // height: 468 


		// 	// Slider {
		// 	// 	y: 22
		// 	// 	anchors.horizontalCenter: parent.horizontalCenter
		// 	// 	width: 60 
		// 	// 	height: 300
		// 	// 	orientation: Qt.Vertical
		// 	// 	title: "GLIDE"
		// 	// 	value: currentEffects[effect]["controls"]["glide"].value
		// 	// 	from: 0.0
		// 	// 	to: 1
		// 	// 	stepSize: 0.01
		// 	// 	onMoved: {
		// 	// 		knobs.ui_knob_change(effect, "glide", value);
		// 	// 	}
		// 	// 	Material.foreground: Constants.rainbow[7]
		// 	// 	onPressedChanged: {
		// 	// 		if (pressed){
		// 	// 			knobs.set_knob_current_effect(effect, "glide");
		// 	// 		}
		// 	// 	}
		// 	// }

		// 	color: Qt.rgba(0, 0, 0, 0)
		// 	border { 
		// 		width:1; 
		// 		color: Constants.outline_color
		// 	}
		// }
        Rectangle {
            x:  1280
            y: 0
            width: 2
            z: 3
            height: parent.height
            color: Constants.poly_grey
        }

        Rectangle {
            x:  640
            y: 0
            width: 2
            z: 3
            height: parent.height
            color: Constants.poly_grey
        }

    }

