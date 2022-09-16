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
		property int current_offset: Math.abs(cent) / 3.847 // 13 colours for 50 cents, 3.8 cents per colour
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
			knobs.set_bypass(effect, false);
			knobs.set_broadcast(effect, false);
		}
		Component.onCompleted: {
			// console.log("setting broadcast true in step");
			knobs.set_bypass(effect, true);
			knobs.set_broadcast(effect, true);
		}


        Image {
            x: 51
            y: 55
            source: "../icons/digit/tuner/cross.png"
            visible: Math.abs(cent) > 7
        }

        Image {
            x: 176
            y: 48
            width: 81
            height: 92
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles_rev.png"
                icon.width: 81
                icon.height: 92
                icon.color: cent < 0 ? tuner_rainbow[current_offset + 3] : current_offset < 3 ? tuner_rainbow[3 - current_offset] : tuner_rainbow[current_offset-3]
                enabled: false
            }
        }
        Item {
            x: 278
            y: 48
            width: 81
            height: 92
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles_rev.png"
                icon.width: 81
                icon.height: 92
                icon.color: cent < 0 ? tuner_rainbow[current_offset + 2] : current_offset < 2 ? tuner_rainbow[2 - current_offset] : tuner_rainbow[current_offset-2]
                enabled: false
            }
        }

        Item {
            x: 381
            y: 48
            width: 81
            height: 92
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles_rev.png"
                icon.width: 81
                icon.height: 92
                icon.color: cent < 0 ? tuner_rainbow[current_offset + 1] : current_offset < 1 ? tuner_rainbow[1 - current_offset] : tuner_rainbow[current_offset-1]
                enabled: false
            }
        }

        Text {
            x: 547
            y: 0
            text: Constants.note_names[note]
            color: tuner_rainbow[current_offset];
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            // elide: Text.ElideRight
            height: 180
            width: 169
            font {
                pixelSize: 200
                // capitalization: Font.AllUppercase
            }
        }

        Item {
            x: 798
            y: 48
            z: 2
            width: 81
            height: 92
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles.png"
                icon.width: 81
                icon.height: 92
                icon.color: cent > 0 ? tuner_rainbow[current_offset + 1] : current_offset < 1 ? tuner_rainbow[1 + current_offset] : tuner_rainbow[current_offset-1]
                enabled: false
            }
        }

        Item {
            x: 895
            y: 48
            z: 1
            width: 81
            height: 92
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles.png"
                icon.width: 81
                icon.height: 92
                icon.color: cent > 0 ? tuner_rainbow[current_offset + 2] : current_offset < 2 ? tuner_rainbow[2 - current_offset] : tuner_rainbow[current_offset-2]
                enabled: false
            }
        }
        Item {
            x: 997
            y: 48
            z: 0
            width: 81
            height: 92
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_triangles.png"
                icon.width: 81
                icon.height: 92
                icon.color: cent > 0 ? tuner_rainbow[current_offset + 3] : current_offset < 3 ? tuner_rainbow[3 - current_offset] : tuner_rainbow[current_offset-3]
                // icon.color: cent < 0 ? tuner_rainbow[current_offset + 3] : current_offset < 3 ? tuner_rainbow[3 - current_offset] : tuner_rainbow[current_offset-3]
                enabled: false
            }
        }

        Image {
            x: 1145
            y: 55
            source: "../icons/digit/tuner/tick.png"
            visible: Math.abs(cent) <= 7
        }

        Text {
            x: 549
            y: 170
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
            x: 48
            y: 290
            source: "../icons/digit/tuner/tuner_rainbow_lines.png"
        }

        Item {
            x: 619 + (cent * 11.1) // cent per pixel width / 50
            y: 245
            z: 2
            width: 44
            height: 334
            Button {
                // x:0
                // y:0
                anchors.centerIn: parent
                background: Item { }
                icon.source: "../icons/digit/tuner/indicator_line.png"
                icon.width: 44
                icon.height: 334
                icon.color: tuner_rainbow[current_offset];
                enabled: false
            }
        }

        // Rectangle {
        //     x:  1280
        //     y: 0
        //     width: 2
        //     z: 3
        //     height: parent.height
        //     color: Constants.poly_grey
        // }

        // Rectangle {
        //     x:  640
        //     y: 0
        //     width: 2
        //     z: 3
        //     height: parent.height
        //     color: Constants.poly_grey
        // }

    }

