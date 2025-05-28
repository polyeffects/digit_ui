import "controls" as PolyControls
import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3  

import "polyconst.js" as Constants
// Component {
            Item {
				id: performanceView
                width: 1280//Screen.height
                height: 720//Screen.width

            Label {
                // color: "#ffffff"
                text: currentPreset.name
                elide: Text.ElideRight
                // anchors.bottom: parent.bottom
                // anchors.bottomMargin: 25 
                horizontalAlignment: Text.AlignCenter
                // anchors.rightMargin: 190
                // anchors.right: parent.right
				anchors.centerIn: parent
                width: 800
                height: 70
                // horizontalAlignment: Text.AlignLeft
                z: 1
                font {
                    pixelSize: fontSizeLarge * 2
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mainStack.push("PresetSave.qml")
                    }
                }
            }

            //PolyControls.Button {
            //     anchors.bottom: parent.bottom
            //     anchors.right: parent.right
            //     anchors.rightMargin: 100
            //     anchors.bottomMargin: 2
            //     icon.width: 70
            //     icon.height: 70
            //     width: 70
            //     height: 70
            //     flat: true
            //     icon.name: "settings"
            //     onClicked: {
            //         mainStack.push("Settings.qml")
            //     }
            // }


            // RectangleLoader { 
            //     width:70
            //     height: 70
            //     x: 650
            //     y: -6
            //     // width: 145
            //     // height: 35
            //     // text: currentBPM.value.toFixed(0) + " BPM"
            //     anchors.bottom: parent.bottom
            //     anchors.bottomMargin: 0
            //     // horizontalAlignment: Text.AlignRight
            //     anchors.rightMargin: 5
            //     anchors.right: parent.right
            //     beat_msec: 60 / currentBPM.value * 1000
            //     // color: Material.color(Material.accent, Material.Shade200)
            // }
            GlowingLabel {
            //     SequentialAnimation on color {
            //         id: anim
            //         // loops: Animation.Infinite
            //         ColorAnimation { to: "white";
            //             duration: (60.0 / currentBPM.value) * 500.0
            //             // onDurationChanged: {
            //             //     anim.restart()
            //             // }
            //         }
            //         ColorAnimation { to: "green";
            //             duration: (60.0 / currentBPM.value) * 500.0
            //             // onDurationChanged: {
            //             //     anim.restart()
            //             // }
            //         }
            //         onStopped: { anim.restart (); }
            //     }
            //     // onTextChanged: {
            //     //     anim.restart()
            //     // }

                // x: 600
                // y: -28
                width: 145
                height: 35
                color: "#EEEEEE"//..Material.color(Material.Grey)
                text: currentBPM.value.toFixed(0) // + " BPM"
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 120 
                horizontalAlignment: Text.AlignRight
                anchors.rightMargin: 15
                anchors.right: parent.right
                font {
                    pixelSize: fontSizeLarge*3
                }
                z: 1
            }
            Label {
                // color: "#ffffff"
                // text: presetList[(currentPreset.value+1) % presetList.length].edit
				text: presetList.data(presetList.index((currentPreset.value+1) % presetList.rowCount(), 0))
                elide: Text.ElideRight
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30 
                horizontalAlignment: Text.AlignRight
                anchors.rightMargin: 230
                anchors.right: parent.right
                width: 300
                height: 50
                // horizontalAlignment: Text.AlignLeft
                z: 1
                font {
                    pixelSize: fontSizeLarge*1.5 
                }
            }

            IconButton {
                x: 14 
                y: 646
                icon.width: 15
                icon.height: 25
                width: 62
                height: 62
                flat: false
                icon.name: "back"
                Material.background: "white"
                Material.foreground: Constants.outline_color
                onClicked: mainStack.pop()
            }
            // Label {
            //     // color: "#ffffff"
            //     // text: presetList[(currentPreset.value+1) % presetList.length].edit
				// text: presetList.data(presetList.index((currentPreset.value-1) % presetList.rowCount(), 0))
            //     elide: Text.ElideRight
            //     anchors.bottom: parent.bottom
            //     anchors.bottomMargin: 60 
            //     horizontalAlignment: Text.AlignRight
            //     anchors.rightMargin: 45
            //     anchors.left: parent.left
            //     width: 300
            //     height: 50
            //     // horizontalAlignment: Text.AlignLeft
            //     z: 1
            //     font {
            //         pixelSize: fontSizeLarge 
            //     }
            // }
        }
    // }

