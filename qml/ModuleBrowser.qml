import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "../qml/polyconst.js" as Constants
import QtQuick.VirtualKeyboard 2.1

Item {
    id: addEffectCon
    height: 720
    width:1280
    property bool showing_fav: false

    Rectangle {
        x: 21
        y: 21
        width: 900
        height: 70
        color: Constants.background_color  
        radius: 12
        border.width: 2
        border.color: "white"
        TextField {
            x:20
            y:0
            // validator: RegExpValidator { regExp: /^[0-9a-zA-Z ]+$/}
            id: amp_search
            width: 870
            height: 70
            font {
                pixelSize: 24
            }
            placeholderText: qsTr("SEARCH")    
            onEditingFinished: {
                module_browser_model.add_filter(amp_search.text)
            
            }
        }
        Component.onCompleted: {
            module_browser_model.show_favourites(showing_fav);
            module_browser_model.clear_tags();
        }
    }

    InputPanel {
        id: inputPanel
        z: 1000002
        anchors.bottom:parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        width: 1000

        visible: Qt.inputMethod.visible
    }

	Connections {
		target: Qt.inputMethod
		onVisibleChanged: {
			if (Qt.inputMethod.visible != true){
				// console.log("keyboard show / hide" + Qt.inputMethod.visible)
				module_browser_model.add_filter(amp_search.text)
			}
		}
	
	}



    Flow {
        x: 935
        y: 21
        spacing: 6
        width: 300

        PolyButton {
            height: 56
            width: 295
            // text: modelData
            checked: b_status
            onClicked: {
                showing_fav = !showing_fav;
                module_browser_model.show_favourites(showing_fav);
                b_status = !b_status;
            }

            Material.foreground: Constants.poly_pink
            border_color: Constants.poly_pink
            radius: 10
            topPadding: 0
            leftPadding: 0
            rightPadding: 0

            contentItem: Item { 
                width: 295
                height:56
                Image {
                    x: 20
                    y: 16
                    source: showing_fav ? "../icons/digit/fav.png" : "../icons/digit/not_fav.png" 
                }

                Text {
                    x: 79
                    y: 8
                    text: "favourites"
                    color: showing_fav ? Constants.background_color : Constants.poly_pink
                    height: 32
                    font {
                        pixelSize: 32
                        capitalization: Font.AllUppercase
                    }
                }
            } 
        }
        Repeater {
            model: [['mod effects', "phaser, flanger, chorus..."], ['time effects', 'reverb, delay, looping, freeze...'], ['pitch + synth', 'filters, pitch shift, strum, oscillators...'], ['utilites', 'foot switch, maths, tempo...'], ['level + dynamics', 'vca, compressor, eq, mixer, wet/dry...'],  ['cv generators', 'lfo, envelopes, sequencers, clocks...'], ['amps, cabs + gain', 'nam amps, cabs, wavefolder, bitcrusher...'], ['midi', 'midi io, utilities'], ['ported', 'ports of eurorack modules']]

            PolyButton {
                height: 56
                topPadding: 0
                leftPadding: 0
                rightPadding: 0
                checked: b_status
                // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                onClicked: {
                    b_status = !b_status;
                    module_browser_model.show_hide_tag(modelData[0], b_status);
                }
                Material.foreground: Constants.longer_rainbow[index % 10]
                border_color: Constants.longer_rainbow[index % 10]
                // background_color: Constants.poly_grey
                text: modelData[0]
                width: 300
                radius: 10
                font_size: 32

                contentItem: Item { 
                    width: 295
                    height:56

                    Text {
                        x: 0
                        y: 2
                        width: 295
                        text: modelData[0]
                        color: checked ? Constants.background_color : Constants.longer_rainbow[index % 10]
                        height: 35
                        horizontalAlignment: Text.AlignHCenter
                        font {
                            pixelSize: 32
                            capitalization: Font.AllUppercase
                        }
                    }

                    Text {
                        x: 0
                        y: 35
                        width: 295
                        text: modelData[1]
                        color: checked ? Constants.background_color : Constants.longer_rainbow[index % 10]
                        height: 20
                        horizontalAlignment: Text.AlignHCenter
                        font {
                            pixelSize: 14
                            capitalization: Font.AllUppercase
                        }
                    }
                }
            }
        }

    }
    Item {
        y: 50
        ListView {
            width: 900
            x: 22
            y: 76
            height: 490
            spacing: 12
            clip: true
            delegate: Item {
                property string l_effect: l_effect_type //.split(":")[1]
                width: 900
                height: 198

                Rectangle {
                    width: parent.width
                    height: parent.height
                    color: Constants.background_color  
                    border.width: 2
                    border.color: Constants.poly_dark_grey  
                    radius: 12
                }

                Item {
                    width: 830
                    height: 198

                    Label {
                        x: 31
                        y: 17
                        height: 30
                        width: 598
                        text: l_effect.replace(/_/g, " ")
                        // anchors.top: parent.top
                        font {
                            pixelSize: 30
                            family: mainFont.name
                            weight: Font.DemiBold
                            capitalization: Font.AllUppercase
                        }
                    }
                    Label {
                        x: 31
                        y: 55
                        width: 750
                        height: 30
                        text: description 
                        wrapMode: Text.Wrap
                        // anchors.top: parent.top
                        font {
                            pixelSize: 26
                            family: docFont.name
                            weight: Font.Normal
                            // capitalization: Font.AllUppercase
                        }
                    }

                    Row {
                        x: 31
                        y: 153
                        spacing: 12
                        width: 750
                        Repeater {
                            model: tags

                            PolyButton {
                                height: 36
                                topPadding: 5
                                leftPadding: 15
                                rightPadding: 15
                                radius: 25
                                Material.foreground: Constants.background_color
                                border_color: Constants.poly_yellow
                                background_color: Constants.poly_yellow
                                text: modelData
                                font_size: 18
                            }
                        }
                    }


                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            knobs.add_new_effect(l_effect)
                            // knobs.ui_add_effect(l_effect)
                            mainStack.pop(null)
                            // patch_single.currentMode = PatchBay.Move;
                            patch_single.current_help_text = Constants.help["move"];

                        }
                    }
                }

                Item {
                    x: 840
                    y: 0
                    width: 109
                    height: 198

                    Image {
                        x: 10
                        y: 90
                        source: is_favourite ? "../icons/digit/fav.png" : "../icons/digit/not_fav.png" 
                    }
                    MouseArea {
                        // fill everything apart from favourite button
                        anchors.fill: parent
                        onClicked: {
                            knobs.toggle_module_favourite(l_effect);
                        }
                    }
                }
            }
            ScrollIndicator.vertical: ScrollIndicator {
                anchors.top: parent.top
                parent: addEffectCon
                anchors.right: parent.right
                anchors.rightMargin: 1
                anchors.bottom: parent.bottom
            }
            model: module_browser_model 

            // section.property: "edit"
            // section.criteria: ViewSection.FirstCharacter
            // section.delegate: sectionHeading
        }

    }

    Item {
        // color: Constants.background_color
        x: 0
        y: 645
        width: 1280
        height: 80
        visible: !Qt.inputMethod.visible
        // border { width:2; color: "white"}
        IconButton {

            x: 31 
            y: -10
            width: 120
            height: 70
            icon.width: 120
            icon.height: 70
            // flat: false
            icon.source: "../icons/digit/bottom_menu/back.png"
            // Material.background: Constants.background_color
            Material.foreground: Constants.background_color
            Material.background: "white"
            visible: patch_single.currentMode != PatchBay.Select && patch_single.currentMode != PatchBay.Hold  
            onClicked: mainStack.pop()
        }

        Label {
            // color: "#ffffff"
            text: "ADD MODULE"
            elide: Text.ElideRight
            visible:patch_single.currentMode == PatchBay.Details  
            anchors.horizontalCenter: parent.horizontalCenter
            y: -10
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            // width: 1000
            height: 70
            leftPadding: 10
            rightPadding: 10

            color:  Constants.background_color
            font {
                pixelSize: 36
                capitalization: Font.AllUppercase
            }
            background: Rectangle {
                color: "white"
                radius: 4
            }
            // MouseArea {
            //     anchors.fill: parent
            //     onClicked: {

            //         if (patch_single.currentMode == PatchBay.Select){
            //             mainStack.push("PresetSave.qml")
            //         }
            //     }
            // }
        }
    }

}
