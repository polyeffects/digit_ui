import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import "../qml/polyconst.js" as Constants

Item {
    height:720
    width:1280
    id: control
    property string effect_type


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
            height: 174
            color: Constants.background_color
            border.width: 2
            border.color: Constants.poly_dark_grey  
            radius: 7

            Text {
                x: 3
                y: 7
                text: preset_description.name
                color: "white"  
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                elide: Text.ElideRight
                height: 165
                wrapMode: Text.WordWrap
                width: 595
                lineHeight: 0.9
                font {
                    pixelSize: 20
                    family: docFont.name
                    weight: Font.Medium
                }
            }
        }

        Rectangle {
            width: 604
            height: 300
            color: Constants.background_color
            border.width: 2
            border.color: Constants.poly_dark_grey  
            radius: 7

            Text {
                x: 3
                y: 7
                text: "Hold the left or right buttons and then slider will change to knob speed to modify knob speed. You can assign either knob to have it always mapped to that control, otherwise knobs will be mapped to the slider you touch in a module."
                color: "white"  
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                elide: Text.ElideRight
                height: 165
                wrapMode: Text.WordWrap
                width: 595
                lineHeight: 0.9
                font {
                    pixelSize: 20
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
            height: 300
            color: Constants.background_color
            border.width: 2
            border.color: Constants.poly_dark_grey  
            radius: 7

            Text {
                x: 3
                y: 7
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
                    pixelSize: 20
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
}
