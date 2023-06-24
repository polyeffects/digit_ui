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
        property string effect: "strum1"
        property string effect_type: "strum" // _ext"
        property int selected_point: currentEffects[effect]["controls"]["touched_notes"].value
        property int step_height: 38
        property int chord: currentEffects[effect]["controls"]["chord_type"].value
        property int note: currentEffects[effect]["controls"]["chord_root"].value
        property int octave: currentEffects[effect]["controls"]["octave"].value
        property int octave_offset: 3
        // q is 0-4 gain is +-18 db
        // property var Constants.longer_rainbow: ['#AC8EFF', '#53A2FD', '#5CE2FF', '#20FF79']
        // Row {
        //
        // ActionIcons {

        // }
		// Component.onDestruction: {
		// 	// if we're not visable, turn off broadcast
		// 	// console.log("setting broadcast false in step");
		// 	knobs.set_broadcast(effect, false);
		// }
		// Component.onCompleted: {
		// 	// console.log("setting broadcast true in step");
		// 	knobs.set_broadcast(effect, true);
		// }

		Item {
			x: 30
			y: 47
			width: 145
			height: 548
			IconButton {
				y: 8
				icon.source: "../icons/digit/up.png" 
				rightPadding: 0
				leftPadding: 0
				width: 120
				height: 210
				onClicked: {
                    var v = currentEffects[effect]["controls"]["octave"].value + 1;
                    v = v > 2 ? 2 : v;
					knobs.ui_knob_change(effect, "octave", v);
				}
				Material.background: Constants.poly_dark_grey
				Material.foreground: Constants.longer_rainbow[octave + octave_offset + 1]
				Material.accent: Constants.poly_pink 
				radius: 11
                enabled: octave < 2
			}

			IconButton {
				y: 260
				icon.source: "../icons/digit/down.png" 
				rightPadding: 0
				leftPadding: 0
				width: 120
				height: 210
				onClicked: {
                    var v = currentEffects[effect]["controls"]["octave"].value - 1;
                    v = v < -3 ? -3 : v;
					knobs.ui_knob_change(effect, "octave", v);
				}
				Material.foreground: Constants.longer_rainbow[octave + octave_offset - 1]
				// Material.foreground: local_val == 0 ? Constants.poly_yellow : "black"
				Material.background: Constants.poly_dark_grey
				Material.accent: Constants.poly_pink 
				radius: 11
                enabled: octave > -3
			}

		}

		// note names
		Grid {
			x: 180
			y: 47
			width: 813
			height: 541
			spacing: 30

			Repeater {
				model: Constants.note_names.slice(0, -1)
				
				Button {
					height: 120
					width: 180
					text: modelData

					onClicked: {
                        knobs.ui_knob_change(effect, "chord_root", index);
					}

					contentItem: Text {
						text: modelData
						color:  note == index ? Constants.background_color : "white"
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						// elide: Text.ElideRight
						height: parent.height
						wrapMode: Text.WordWrap
						width: parent.width
						font {
							pixelSize: 52
							capitalization: Font.AllUppercase
						}
					}

					background: Rectangle {
						width: parent.width
						height: parent.height
						color: note == index ? Constants.longer_rainbow[octave + octave_offset] : Constants.poly_dark_grey  
						border.width: 5
						border.color: note == index ? Constants.longer_rainbow[octave + octave_offset] : Constants.outline_color  
						radius: 16
					}
				}
			}

			Repeater {
				model: ["major", "minor", "m7", "7th"]
				Button {
					height: 120
					width: 180
					text: modelData
					onClicked: {
                        knobs.ui_knob_change(effect, "chord_type", index);
					}

					contentItem: Text {
						text: modelData
						color:  chord == index ? Constants.background_color : "white"
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						// elide: Text.ElideRight
						height: parent.height
						wrapMode: Text.WordWrap
						width: parent.width
						font {
							pixelSize: 52
							capitalization: Font.AllUppercase
						}
					}

					background: Rectangle {
						width: parent.width
						height: parent.height
						color: chord == index ? Constants.longer_rainbow[octave + octave_offset] : Constants.poly_dark_grey  
						border.width: 0
						radius: 20
					}
				}
			}
		}

		// strum lines
		Item {
			x: 1024
			y: 0
			width: 280
			height: 720
			id: stepCol

            MultiPointTouchArea {
                id: mouseArea
                anchors.fill: parent
                minimumTouchPoints: 1
                maximumTouchPoints: 1

				onTouchUpdated: {
					// console.log("selected_point", time_scale.selected_point );
					var point = touchPoints[0];
					// console.log("position is", point.y);
					if (point == undefined){
                        knobs.ui_knob_change(effect, "touched_notes", -1);
						return;
					}
					var c = stepCol.childAt(50, point.y) // ignore vertical point.y)

					// var f = ( time_scale.step_height - point.y + 15) / time_scale.step_height;
					if (!c || typeof(c.step_id) == "undefined"){
                        knobs.ui_knob_change(effect, "touched_notes", -1);
						return;
					}
					knobs.ui_knob_change(effect, "touched_notes", c.step_id);
                    // console.log("step id is", c.step_id, "point y is", point.y);
				}
            }
			
			Repeater {
				model: 16

				Rectangle {
                    id: strum_line
                    x: 0 
                    y: 20 + (time_scale.step_height * index)
					width: 260
					height: 18
					color: time_scale.selected_point == index ? "white": Constants.longer_rainbow[Math.floor(index / 4)+octave+octave_offset]
                    property bool is_touched: false
                    property int step_id: index
					border.width: 0
					radius: 8
                    visible: (index % 4 < 3) || time_scale.chord > 1
				}

			}
		}
        Rectangle {
            width: 1280
            x: 0
            y: 720
            height: 2
            color: Constants.longer_rainbow[Math.floor(1 / 4)]
            border.width: 0
            radius: 1
        }
    }

