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
        property bool is_system_preset: false

		// save or load
        Component {
            id: loadOrSave
            Item {
				height:580
				width:1280
                Row {
                    spacing: 100
					anchors.centerIn: parent

                    Button {
                        text: "LOAD"
						width: 300
						height: 500
                        onClicked: presetStack.push(loadPresetWidget)
                    }

                    Button {
                        text: "SAVE"
						width: 300
						height: 500
                        onClicked: is_system_preset ? presetStack.push(choosePresetFolder) : presetStack.push(newOrOverwrite) 
                    }
                }

				Button {
					text: "BACK"
					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.topMargin: 10
					width: 100
					height: 100
					// onClicked: is_system_preset ? presetStack.push(choosePresetFolder) : presetStack.push(newOrOverwrite) 
				}
            }
        }

        Component {
            id: loadPresetWidget
            // height:parent.height
            // Column {
                // width:300
                // spacing: 20
                // height:parent.height
                Item {
					height:580
					width:1280

					// anchors.centerIn: parent
                    GlowingLabel {
                        // color: "#ffffff"
						x: 400
                        text: qsTr("Select Preset")
                    }

                    FolderBrowser {
                        y: 60
						x: 400
                        // Layout.fillHeight: true
                        height: 400
                        width: 500
                    } // preset loaded on click on preset

                    // Button {
                    //     y: 460
						// x: 400
                    //     width: 500
                    //     height: 60
                    //     text: "LOAD"
                    //     onClicked: presetStack.push(setPresetName) // load preset and close
                    // }
					Button {
						text: "BACK"
						anchors.right: parent.right
						anchors.rightMargin: 10
						anchors.topMargin: 10
						width: 100
						height: 100
                        onClicked: presetStack.pop()
					}
                }
            // }
        }

        // if we've got a user preset loaded, 
        // give option to save as new or update existing
        Component {
            id: newOrOverwrite
            Item {
				height:580
				width:1280
                Row {
                    spacing: 100
					anchors.centerIn: parent

                    Button {
                        text: "OVERWRITE"
						width: 300
						height: 500
                        // onClicked: // save preset and close browser
                    }

                    Button {
                        text: "CREATE NEW"
						width: 300
						height: 500
                        onClicked: presetStack.push(choosePresetFolder)
                    }
                }
				Button {
					text: "BACK"
					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.topMargin: 10
					width: 100
					height: 100
					onClicked: presetStack.pop()
				}
            }
        }


        Component {
            id: choosePresetFolder
            // height:parent.height
            // Column {
                // width:300
                // spacing: 20
                // height:parent.height
                Item {
					height:580
					width:1280
                    // height:parent.height
                    GlowingLabel {
                        // color: "#ffffff"
						y: 30
						x: 400
                        text: qsTr("Choose Folder")
                    }

                    FolderBrowser {
                        y: 70
						x: 400
                        // Layout.fillHeight: true
                        height: 400
                        width: 500
                    }
                    // create new folder

                    Button {
                        y: 490
						x: 400
                        text: "NEXT"
                        height: 80
                        width: 500
                        onClicked: presetStack.push(setPresetName)
                    }
					Button {
						text: "BACK"
						anchors.right: parent.right
						anchors.rightMargin: 10
						anchors.topMargin: 10
						width: 100
						height: 100
						onClicked: presetStack.pop()
					}
                }
            // }
        }

        Component {
            id: setPresetName

            Item {
				height:580
				width:1280
                Column {
                    width:300
					x: 400
					anchors.centerIn: parent
                    spacing: 20
                    // height:parent.height
                    GlowingLabel {
                        // color: "#ffffff"
                        text: qsTr("Enter Preset Name")
                    }

                    TextField {
						width: 250
						height: 100
                        placeholderText: qsTr("Preset Name")    
                    }

                    Button {
						width: 250
						height: 100
                        text: "SAVE"
                    }
                }
				Button {
					text: "BACK"
					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.topMargin: 10
					width: 100
					height: 100
					onClicked: presetStack.pop()
				}
            }
        }

        StackView {
            id: presetStack
            initialItem: loadOrSave
        }

    }
// }
