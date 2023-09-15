import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "../qml/polyconst.js" as Constants
import QtQuick.VirtualKeyboard 2.1

Item {
    id: control
    height: 720
    width:1280
    property var after_file_selected: (function(name) { return null; })
    property bool hold_delete: false
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
                preset_browser_model.add_filter(amp_search.text)
            
            }
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
                preset_browser_model.add_filter(amp_search.text)
            }
        }
    
    }

    PolyButton {
        x:935
        y: 21
        height: 69
        width: 295
        // text: modelData
        onClicked: {
            showing_fav = !showing_fav;
            preset_browser_model.show_favourites(showing_fav);
        }

        contentItem: Item { 
            Image {
                x: 20
                y: 16
                source: showing_fav ? "../icons/digit/fav.png" : "../icons/digit/not_fav.png" 
            }

            Text {
                x: 108
                y: 16
                text: "favourites"
                color: Constants.poly_pink
                height: 22
                font {
                    pixelSize: 22
                    capitalization: Font.AllUppercase
                }
            }
        } 
    }

    Item {
        y: 50

        ListView {
            width: 1200
            x: 22
            y: 76
            height: 460
            spacing: 12
            clip: true
            delegate: Item {
                id: p_item
                property bool is_pressed: false
                width: 1200
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
                    width: 1000
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
                        width: 798
                        height: 30
                        text: description +"\nby "  + author 
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
                    x: 1110
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
            text: "LOAD PRESET"
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

        IconButton {
            x: 1100 
            y: -10
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
