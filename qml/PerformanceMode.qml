import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3  
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

            ProgressBar {
                id: leftEncoderVal
                x: 0
                y: 0
                width: 300
                height: 140
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // set map encoder on
                        // python variable in qml context
                        // console.warn("waiting for knob mapping")
                        knobs.set_waiting("left")
                    }
                }
                from: polyValues[knobMap.left.effect][knobMap.left.parameter].rmin
                to: polyValues[knobMap.left.effect][knobMap.left.parameter].rmax
                value: polyValues[knobMap.left.effect][knobMap.left.parameter].value
                background: Rectangle {
                    // implicitWidth: 200
                    // implicitHeight: 6
                    // color: "#22e6e6e6"
                    color: "#00222222"
                    border {
                        // color: Material.color(Material.Grey, Material.Shade200);
                        color: "#666666"
                        width: 1
                    }
                }
                contentItem: Item {
                    implicitWidth: parent.width
                    implicitHeight: parent.height
                    // width: parent.width
                    // height: parent.height
                    Rectangle {
                        width: leftEncoderVal.visualPosition * parent.width
                        height: parent.height
                        // radius: 2
                        color: setColorAlpha(Material.color(Material.Pink, Material.Shade200), 0.5)
                        border {
                            color: Material.color(Material.Pink, Material.Shade200);
                            width: 1
                        }
                    }
                }
            }
            GlowingLabel {
                elide: Text.ElideRight
                color: "#ffffff"
                text: polyValues[knobMap.left.effect][knobMap.left.parameter].name
                x: 5
                y: 5
                width: 200
                height: 41
                horizontalAlignment: Text.AlignLeft
                z: 1
                font {
                    pixelSize: fontSizeLarge * 1.5
                }
            }

            ProgressBar {
                id: rightEncoderVal
                width: 300
                height: 140
                anchors.top: parent.top
                anchors.topMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                from: polyValues[knobMap.right.effect][knobMap.right.parameter].rmin
                to: polyValues[knobMap.right.effect][knobMap.right.parameter].rmax
                value: polyValues[knobMap.right.effect][knobMap.right.parameter].value
                // from: 0
                // to: 1
                // value: 0.7
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // set map encoder on
                        // python variable in qml context
                        // console.warn("waiting for knob mapping")
                        knobs.set_waiting("right")
                    }
                }
                background: Rectangle {
                    // implicitWidth: 200
                    // implicitHeight: 6
                    // color: "#22e6e6e6"
                    color: "#00222222"
                    border {
                        // color: Material.color(Material.Grey, Material.Shade200);
                        color: "#666666"
                        width: 1
                    }
                }
                contentItem: Item {
                    implicitWidth: parent.width
                    implicitHeight: parent.height
                    // width: parent.width
                    // height: parent.height
                    Rectangle {
                        width: rightEncoderVal.visualPosition * parent.width
                        height: parent.height
                        // radius: 2
                        color: setColorAlpha(Material.color(Material.Pink, Material.Shade200), 0.5)
                        border {
                            color: Material.color(Material.Pink, Material.Shade200);
                            width: 1
                        }
                    }
                }
            }
            GlowingLabel {
                elide: Text.ElideRight
                color: "#ffffff"
                text: polyValues[knobMap.right.effect][knobMap.right.parameter].name
                horizontalAlignment: Text.AlignRight
                width: 200
                height: 41
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.topMargin: 5
                z: 1
                font {
                    pixelSize: fontSizeLarge * 1.5  
                }
            }
            // Button {
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

            Button {
                flat: true
                font.pixelSize: baseFontSize
                text: "BACK"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.rightMargin: 10
                anchors.bottomMargin: 10
                width: 100
                height: 100
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

