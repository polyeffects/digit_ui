import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "../qml/polyconst.js" as Constants

Item {
    id: control
    height: 720
    width:1280
    property var after_file_selected: (function(name) { return null; })
    property bool hold_delete: false

    Rectangle {
        color: accent_color.name
        x: 0
        y: 0
        width: 1280
        height: 100
    
        Image {
            x: 10
            y: 9
            source: currentPedalModel.name == "beebo" ? "../icons/digit/Beebo.png" : "../icons/digit/Hector.png" 
        }

        Label {
            // color: "#ffffff"
            text: "Load Preset"
            elide: Text.ElideRight
            anchors.centerIn: parent
            anchors.bottomMargin: 25 
            horizontalAlignment: Text.AlignHCenter
            width: 1000
            height: 60
            z: 1
            color: Constants.background_color
            font {
                pixelSize: 36
                capitalization: Font.AllUppercase
            }
        }
    }
    Item {
        y: 100

        Row {
            id: alphabet_filter
            x: 22
            y: 12
            property string selected_letter: "none"
            spacing: 15
            width: 1258
            Repeater {
                model: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w']
                PolyButton {
                    width: 42
                    height: 40
                    topPadding: 5
                    checked: alphabet_filter.selected_letter == modelData 
                    // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                    onClicked: {
                        preset_browser_model.add_filter(modelData)
                        if (alphabet_filter.selected_letter == modelData){
                            alphabet_filter.selected_letter = "";
                        } else {
                            alphabet_filter.selected_letter = modelData;
                        }
                    }
                    Material.foreground: Constants.poly_pink
                    border_color: Constants.poly_pink
                    Material.background: Constants.background_color
                    text: modelData
                    font {
                        pixelSize: 20
                        capitalization: Font.AllUppercase
                    }
                }
            }
        }

        Flow {
            x: 851
            y: 76
            property string selected_letter: "none"
            spacing: 12
            width: 420
            Repeater {
                model: ['mine', 'favourites']

                PolyButton {
                    height: 75
                    topPadding: 5
                    leftPadding: 15
                    rightPadding: 15
                    checked: b_status
                    // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                    onClicked: {
                        preset_browser_model.add_filter(modelData);
                        b_status = !b_status;
                    }
                    Material.foreground: Constants.rainbow[index % 17]
                    border_color: Constants.background_color
                    background_color: Constants.poly_grey
                    text: modelData
                    radius: 10
                    font_size: 22
                }
            }
        }


        ListView {
            width: 809
            x: 22
            y: 76
            height: 460
            spacing: 12
            clip: true
            delegate: Item {
                id: p_item
                property bool is_pressed: false
                width: 809
                height: 198

                Rectangle {
                    width: parent.width
                    height: parent.height
                    color: Constants.background_color  
                    border.width: 2
                    border.color: is_pressed ? Constants.poly_pink: Constants.poly_dark_grey  
                    radius: 12
                }

                Item {
                    width: 709
                    height: 198

                    Label {
                        x: 31
                        y: 17
                        height: 30
                        width: 598
                        text: title
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
                        width: 598
                        height: 30
                        text: description +"\nby "  + author // effectPrototypes[l_effect]["description"]
                        wrapMode: Text.Wrap
                        // anchors.top: parent.top
                        font {
                            pixelSize: 24
                            family: docFont.name
                            weight: Font.Normal
                            // capitalization: Font.AllUppercase
                        }
                    }

                    Row {
                        x: 31
                        y: 150
                        spacing: 12
                        width: 1258
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
                        // fill everything apart from favourite button
                        anchors.fill: parent
                        onClicked: {
                            // patch_single.current_help_text = Constants.help["move"];
                            // presetBrowserIndex = index;
                            p_item.is_pressed = true; 
                            if (control.hold_delete){
                                knobs.delete_preset("file://"+filename);
                                // mainStack.pop(null)
                            }
                            else {
                                control.after_file_selected("file://"+filename)
                            }
                            p_item.is_pressed = false; 
                        }
                    }
                }
                Item {
                    x: 709
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
                            knobs.toggle_favourite("file://"+filename);
                        }
                    }
                }

            }
            ScrollIndicator.vertical: ScrollIndicator {
                anchors.top: parent.top
                parent: control
                anchors.right: parent.right
                anchors.rightMargin: 1
                anchors.bottom: parent.bottom
            }
            model: preset_browser_model 

            // section.property: "edit"
            // section.criteria: ViewSection.FirstCharacter
            // section.delegate: sectionHeading
        }

        IconButton {
            x: 34 
            y: 560
            icon.width: 15
            icon.height: 25
            width: 119
            height: 62
            text: "BACK"
            font {
                pixelSize: 24
            }
            flat: false
            icon.name: "back"
            Material.background: Constants.background_color
            Material.foreground: "white" // Constants.outline_color
            onClicked: mainStack.pop()
        }

        IconButton {
            x: 584 
            y: 550
            width: 76
            height: 76
            icon.width: 70
            icon.height: 70
            icon.source: "../icons/digit/bottom_menu/Delete.png"
            Material.background: control.hold_delete ? Constants.poly_dark_grey: Constants.background_color
            Material.foreground: accent_color.name
            onPressed: {
                control.hold_delete = true;
            }
            onReleased: {
                control.hold_delete = false;
            }
        }
    }


}
        
        

                // delegate: SwipeDelegate {
                //     id: swipeDelegate
                //     width: parent.width
                //     swipe.enabled: mainRect.swipeable
                //     visible: preset_filter(fileURL.toString())
                //     enabled : visible
                //     height: visible ? 95 : 0

                //     text: "<b>"+remove_suffix(fileName).replace(/_/g, " ")+ '</b> '+ get_preset_author(fileURL.toString()) + get_preset_description(fileURL.toString())
                //     font {
                //         bold: fileIsDir && !fileURL.toString().endsWith(".ingen") ? true : false
                //         pixelSize: 24
                //         family: mainFont.name
                //         capitalization: Font.AllUppercase
                //     }
                //     icon.name: fileIsDir && !fileURL.toString().endsWith(".ingen") ? "md-folder-open" : false // or md-folder
                //     onClicked: {
                //     }
                //     // background: Rectangle {
                //     // color: fileIsDir ? "orange" : "gray"
                //     // border.color: "black"
                //     // }
                //     ListView.onRemove: SequentialAnimation {
                //         PropertyAction {
                //             target: swipeDelegate
                //             property: "ListView.delayRemove"
                //             value: true
                //         }
                //         NumberAnimation {
                //             target: swipeDelegate
                //             property: "height"
                //             to: 0
                //             easing.type: Easing.InOutQuad
                //         }
                //         PropertyAction {
                //             target: swipeDelegate
                //             property: "ListView.delayRemove"
                //             value: false
                //         }
                //     }

                //     swipe.left: IconButton {
                //         icon.source: "../icons/digit/favourite.png"
                //         width: 100
                //         height: 90
                //         icon.width: 60
                //         checked: is_favourite(fileURL.toString());
                //         onClicked: {
                //             knobs.toggle_favourite(fileURL.toString());
                //         }
                //         Material.foreground: "pink"
                //         Material.accent: "white"
                //         radius: 10
                //     }


                //     swipe.right: Label {
                //         id: deleteLabel
                //         text: qsTr("Delete")
                //         color: "white"
                //         verticalAlignment: Label.AlignVCenter
                //         padding: 30
                //         height: parent.height
                //         anchors.right: parent.right


                //         background: Rectangle {
                //             color: deleteLabel.SwipeDelegate.pressed ? Qt.darker("tomato", 1.1) : "tomato"
                //         }
                //         MouseArea {
                //             id: mouseArea
                //             anchors.fill: parent
                //             onClicked: { 
                //                 console.log("delete clicked");
                //                 knobs.delete_preset(fileURL.toString());
                //             }
                //         }
                //     }
                // }
            // }
        // }
    // }
