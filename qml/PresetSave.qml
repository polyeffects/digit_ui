import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.2
// import QtQuick.Controls.Material 2.3

// ApplicationWindow {
//     visible: true
//     width: 400
//     height: 480
//     title: qsTr("Hello World")

//     Material.theme: Material.Dark
//     Material.primary: Material.Green
//     Material.accent: Material.Pink


    Item {
        id: preset_widget
        property url current_selected: "file:///none.wav"

        // if we've got a user preset loaded, 
        // give option tosave as new or update existing

        Component {
            id: choosePresetFolder
            // height:parent.height
            // Column {
                // width:300
                // spacing: 20
                // height:parent.height
                Item {
                    height:parent.height
                    GlowingLabel {
                        // color: "#ffffff"
                        text: qsTr("Choose Folder")
                    }

                    FolderBrowser {
                        y: 60
                        // Layout.fillHeight: true
                        height: 400
                        width: 300
                    }
                    // create new folder

                    Button {
                        y: 460
                        text: "NEXT"
                        onClicked: presetStack.push(setPresetName)
                    }
                }
            // }
        }

        Component {
            id: setPresetName
            Item {
                Column {
                    width:300
                    spacing: 20
                    height:parent.height
                    GlowingLabel {
                        // color: "#ffffff"
                        text: qsTr("Enter Preset Name")
                    }

                    TextField {
                        placeholderText: qsTr("Preset Name")    
                    }

                    Button {
                        text: "SAVE"
                    }
                }
            }
        }

        StackView {
            id: presetStack
            initialItem: choosePresetFolder
        }

    }
// }
