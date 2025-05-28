import "controls" as PolyControls
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import "../qml/polyconst.js" as Constants
import QtQuick.VirtualKeyboard 2.1

Item {
    height:720
    width:1280
    id: control


    // Rectangle {
    //     color: accent_color.name
    //     x: 0
    //     y: 0
    //     width: 1280
    //     height: 100
    
    //     Image {
    //         x: 10
    //         y: 9
    //         source: currentPedalModel.name == "beebo" ? "../icons/digit/Beebo.png" : "../icons/digit/Hector.png" 
    //     }

    //     Label {
    //         // color: "#ffffff"
    //         text: "Spotlight"
    //         elide: Text.ElideRight
    //         anchors.centerIn: parent
    //         anchors.bottomMargin: 25 
    //         horizontalAlignment: Text.AlignHCenter
    //         width: 1000
    //         height: 60
    //         z: 1
    //         color: Constants.background_color
    //         font {
    //             pixelSize: 36
    //             capitalization: Font.AllUppercase
    //         }
    //     }
    // }
	Column {
		x: 29
		y: 29
        width: 604
		spacing: 30

        Rectangle {
            width: 604
            height: 300
            color: Constants.background_color
            border.width: 2
            border.color: Constants.poly_dark_grey  
            radius: 7

            Text {
                x: 22
                y: 15
                text:  "preset description"
                color: "white"  
                horizontalAlignment: text.AlignLeft
                verticalAlignment: text.AlignTop
                height: 30
                width: 580
                font {
                    pixelSize: 24
                    family: docFont.name
                    weight: Font.Medium
                    capitalization: Font.AllUppercase
                }
            }

            Text {
                x: 22
                y: 55
                text: preset_description.name
                color: "white"  
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                elide: Text.ElideRight
                height: 265
                wrapMode: Text.WordWrap
                width: 580
                lineHeight: 0.9
                font {
                    pixelSize: 24
                    family: docFont.name
                    weight: Font.Medium
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: { 
                    patchStack.push(enterDescription);
                }
            }
        }

        Rectangle {
            width: 604
            height: 200
            color: Constants.background_color
            border.width: 2
            border.color: Constants.poly_dark_grey  
            radius: 7

            Text {
                x: 22 
                y: 15
                // text: "Hold the left or right buttons and then slider will change to knob speed to modify knob speed. You can assign either knob to have it always mapped to that control, otherwise knobs will be mapped to the slider you touch in a module. Touch the preset description to edit it."
                text: "You can assign either knob to have it always mapped to that control, otherwise knobs will be mapped to the slider you touch in a module. Touch the preset description to edit it."
                color: "white"  
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                elide: Text.ElideRight
                height: 165
                wrapMode: Text.WordWrap
                width: 580
                lineHeight: 0.9
                font {
                    pixelSize: 24
                    family: docFont.name
                    weight: Font.Medium
                }
            }
        }
    }

	Column {
		x: 657
		y: 29
        width: 604
		spacing: 30

        Rectangle {
            width: 604
            height: 400
            color: Constants.background_color
            border.width: 2
            border.color: Constants.poly_dark_grey  
            radius: 7

            Text {
                x: 22
                y: 15
                text:  "MIDI Assignments"
                color: "white"  
                horizontalAlignment: text.AlignLeft
                verticalAlignment: text.AlignTop
                height: 30
                width: 580
                font {
                    pixelSize: 24
                    weight: Font.DemiBold
                    family: mainFont.name
                    capitalization: Font.AllUppercase
                }
            }

            Text {
                x: 22
                y: 50
                text: knobs.get_midi_assignments()
                color: "white"  
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                elide: Text.ElideRight
                height: 165
                wrapMode: Text.WordWrap
                width: 595
                lineHeight: 0.9
                font {
                    pixelSize: 22
                    family: docFont.name
                    weight: Font.Medium
                }
            }
        }

	}

    // MoreButton {
    //     l_effect_type: "no_effect"
    //     module_more: false
    //     alt_module_more: (function(l_effect_type) { 
    //         patchStack.push("SpotlightDetail.qml", {"effect_type": l_effect_type});
    //     })
    // }

    // IconButton {

    //     x: 34 
    //     y: 650
    //     icon.width: 15
    //     icon.height: 25
    //     width: 119
    //     height: 62
    //     text: "BACK"
    //     font {
    //         pixelSize: 24
    //     }
    //     flat: false
    //     icon.name: "back"
    //     Material.background: Constants.background_color
    //     Material.foreground: "white" // Constants.outline_color
    //     onClicked: patchStack.pop()
    // }
    Component {
        id: enterDescription
        Item {
            y: 100
            height:700
            width:1280
            Column {
                x: 0
                height:600
                width:1280
                Label {
                    color: accent_color.name
                    text: "Preset Description"
                    font {
                        pixelSize: fontSizeLarge * 1.2
                        capitalization: Font.AllUppercase
                    }
                    // anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                TextArea {
                    font {
                        pixelSize: fontSizeMedium
                        family: docFont.name
                        weight: Font.Normal
                        // capitalization: Font.AllUppercase
                    }
                    horizontalAlignment: TextEdit.AlignHCenter
                    width: 800
                    height: 400
                    text: preset_description.name
                    anchors.horizontalCenter: parent.horizontalCenter
                    // inputMethodHints: Qt.ImhUppercaseOnly
                    onEditingFinished: {
                        knobs.set_description(text)
                    }
                }

                InputPanel {
                    // parent:mainWindow.contentItem
                    z: 1000002
                    // anchors.bottom:parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 200
                    width: 1000
                    visible: Qt.inputMethod.visible
                }
            }

            IconButton {
                x: 34 
                y: 596
                icon.width: 15
                icon.height: 25
                width: 119
                height: 62
                text: "DONE"
                font {
                    pixelSize: 24
                }
                flat: false
                icon.name: "back"
                Material.background: "white"
                Material.foreground: Constants.outline_color

                onClicked: patchStack.pop()
            }
        }
    }
}
