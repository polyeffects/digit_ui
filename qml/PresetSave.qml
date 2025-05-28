import "controls" as PolyControls
import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.2
import QtQuick.VirtualKeyboard 2.1
import "polyconst.js" as Constants
import QtQuick.Controls.Material 2.3

// ApplicationWindow {
//     visible: true
//     width: 400
//     height: 480
//     title: qsTr("Hello World")

//     Material.theme: Material.Dark
//     Material.primary: Material.Green
//     Material.accent: Material.Pink
//
//     preset list
//     add item to list
//     remove item 
//     change preset mapped to number
//     
//     list of buttons,  + or - at top
//     each button opens select preset
//     save
//


    Item {
        id: preset_widget
        property bool is_system_preset: false
        property int map_index: 0
        property int button_font_size: 36

		// save or load
        Component {
            id: loadOrSave
            Item {
				height:720
				width:1280

				Column {
					anchors.centerIn: parent
					spacing: 57

						Button {
							text: "Load a preset"
							Material.foreground: Constants.poly_pink
							anchors.horizontalCenter:  parent.horizontalCenter
							width: 410
							height: 59
							// height: 500
							onClicked: presetStack.push(loadPresetWidget)
							font {
								pixelSize: button_font_size
								capitalization: Font.AllUppercase
							}
						}

						Button {
							text: "Save current preset"
							Material.foreground: Constants.poly_blue
							anchors.horizontalCenter:  parent.horizontalCenter
							width: 538
							height: 59
							// height: 500
							onClicked: is_system_preset ? presetStack.push(choosePresetFolder) : presetStack.push(newOrOverwrite) 
							font {
								pixelSize: button_font_size
								capitalization: Font.AllUppercase
							}
						}
					Row {
						spacing: 100
						anchors.horizontalCenter: parent.horizontalCenter


						Button {
							text: "EXPORT PRESETS"
							Material.foreground: Constants.poly_green
							width: 354
							height: 59
							// show screen explaining to put USB flash drive in
							onClicked: presetStack.push(exportPresets)
							font {
								pixelSize: button_font_size
							}
						}

						Button {
							text: "IMPORT PRESETS"
							Material.foreground: Constants.poly_green
							width: 354
							height: 59
							// show screen explaining to put USB flash drive in
							onClicked: presetStack.push(importPresets)
							font {
								pixelSize: button_font_size
							}
						}
					}

					Row {
						spacing: 100
						anchors.horizontalCenter: parent.horizontalCenter
						Button {
							text: "SET LIST"
							width: 320
							height: 59
							Material.foreground: Constants.poly_yellow
							// height: 500
							onClicked: presetStack.push(mapPresets)
							font {
								pixelSize: button_font_size
							}
						}

						Button {
							text: "EMPTY PRESET"
							width: 320
							height: 59
							Material.foreground: Constants.poly_yellow
							// height: 500
							onClicked: {
								knobs.ui_load_empty_preset();
								mainStack.pop();
							}
							font {
								pixelSize: button_font_size
							}
						}
					}
				}

                IconButton {
                    x: 34 
                    y: 646
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
                    Material.background: "white"
                    Material.foreground: Constants.outline_color
                    onClicked: mainStack.pop()
                }
            }
        }

		Component {
			id: exportPresets
			Item {
				height:700
				width:1280
				Row {
					spacing: 100
					anchors.centerIn: parent

					Text {
						font {
							pixelSize: fontSizeMedium
						}
						color: Material.foreground
						text: "Please put a USB key into the USB port.<p> This will overwrite any presets on the drive with the same name.</p>"
						width: 300
						wrapMode: Text.WordWrap
						textFormat: Text.StyledText
					}

					Button {
						flat: false
						font {
							pixelSize: fontSizeMedium
						}
						text: "Export Current"
						width: 300
						onClicked: { // save preset and close browser
							presetStack.push(presetCopyView)
							knobs.export_current_preset();
						}
					}
					Button {
						flat: false
						font {
							pixelSize: fontSizeMedium
						}
						text: "Export All"
						width: 300
						onClicked: { // save preset and close browser
							presetStack.push(presetCopyView)
							knobs.export_presets();
						}
					}
				}
				Button {
					flat: false
					font {
						pixelSize: fontSizeMedium
					}
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
			id: importPresets
			Item {
				height:700
				width:1280
				Row {
					spacing: 100
					anchors.centerIn: parent

					Text {
						font {
							pixelSize: fontSizeMedium
						}
						color: Material.foreground
						text: "Please put a USB key into the USB port.<p> Presets should be in a folder called presets. This will overwrite any presets with the same name.</p>"
						width: 300
						wrapMode: Text.WordWrap
						textFormat: Text.StyledText
					}

					Button {
						flat: false
						font {
							pixelSize: fontSizeMedium
						}
						text: "Import Presets"
						width: 300
						onClicked: { // save preset and close browser
							presetStack.push(presetCopyView)
							knobs.import_presets();
						}
					}
				}
				Button {
					flat: false
					font {
						pixelSize: fontSizeMedium
					}
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
			id: presetCopyView
			Item {
				height:700
				width:1280
				Row {
					spacing: 100
					anchors.centerIn: parent

					Text {
						font {
							pixelSize: fontSizeMedium
						}
						color: Material.foreground
						text: "Presets copied sucessfully"
						width: 300
						wrapMode: Text.WordWrap
						visible: commandStatus[0].value == 0
					}

					Text {
						font {
							pixelSize: fontSizeMedium
						}
						color: Material.foreground
						text: "Preset copy failed. Please make sure flash drive is plugged in and watch the tutorial video. If that doesn't work, please contact Loki@polyeffects.com"
						width: 300
						wrapMode: Text.WordWrap
						textFormat: Text.PlainText
						visible: commandStatus[0].value > 0
					}

					BusyIndicator {
						running: commandStatus[0].value < 0 
					}

					Text {
						font {
							pixelSize: fontSizeMedium
						}
						color: Material.foreground
						text: "Copying. Please wait."
						width: 300
						wrapMode: Text.WordWrap
						textFormat: Text.PlainText
						visible: commandStatus[0].value < 0
					}

				}
				Button {
					flat: false
					font {
						pixelSize: fontSizeMedium
					}
					text: "BACK"
					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.topMargin: 10
					width: 100
					height: 100
					visible: commandStatus[0].value >= 0 
					onClicked: presetStack.pop(null)
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
					height:720
					width:1280

                    PresetBrowser {
                        y: 0
						x: 0
						after_file_selected: (function(name) { 
							console.log("loading preset file");
							console.log("file  is", name.toString());
							knobs.ui_load_preset_by_name(name.toString());
                            mainStack.pop(null)
							// some way to handle errors also needed
						})
						
                    } // preset loaded on click on preset

                    //PolyControls.Button {
                    //     y: 460
						// x: 400
                    //     width: 500
                    //     height: 60
                    //     text: "LOAD"
                    //     onClicked: presetStack.push(setPresetName) // load preset and close
                    // }
                    // IconButton {
                    //     x: 34 
                    //     y: 646
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
                    //     Material.background: "white"
                    //     Material.foreground: Constants.outline_color
                    //     onClicked: presetStack.pop()
                    // }
                }
            // }
        }

        // if we've got a user preset loaded, 
        // give option to save as new or update existing
        Component {
            id: newOrOverwrite
            Item {
				height:700
				width:1280
                Row {
                    spacing: 100
					anchors.centerIn: parent

                   PolyControls.Button {
						font {
							pixelSize: fontSizeLarge
						}
                        text: "OVERWRITE"
						Material.foreground: Constants.poly_pink
						width: 300
                        onClicked: { // save preset and close browser
							knobs.ui_save_pedalboard(currentPreset.name);
							mainStack.pop()
						}
						visible: currentPreset.name != 'Empty'
                    }

                   PolyControls.Button {
						font {
							pixelSize: fontSizeLarge
						}
                        text: "SAVE AS NEW"
						Material.foreground: Constants.poly_blue
						width: 300
                        // onClicked: presetStack.push(choosePresetFolder)
                        onClicked: presetStack.push(setPresetName)
                    }
                }

                IconButton {
                    x: 34 
                    y: 646
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
                    Material.background: "white"
                    Material.foreground: Constants.outline_color
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
					height:700
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
						top_folder: "file:///mnt/presets"
                    }
                    // create new folder

                   PolyControls.Button {
						font {
							pixelSize: fontSizeLarge
						}
                        y: 490
						x: 400
                        text: "NEXT"
                        height: 80
                        width: 500
                        onClicked: presetStack.push(setPresetName)
                    }

                    IconButton {
                        x: 34 
                        y: 646
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
                        Material.background: "white"
                        Material.foreground: Constants.outline_color
                        onClicked: presetStack.pop()
                    }
                }
            // }
        }

        Component {
            id: setPresetName

            Item {
				height:720
				width:1280
                Column {
                    width:300
					x: 400
					y: 10
					anchors.horizontalCenter:  parent.horizontalCenter
                    spacing: 20
                    // height:parent.height
                    GlowingLabel {
                        // color: "#ffffff"
                        text: qsTr("Enter Preset Name")
                    }

                    TextField {
                        validator: RegExpValidator { regExp: /^[0-9a-zA-Z ]+$/}
						id: new_preset_name
						width: 250
						height: 100
						font {
							pixelSize: fontSizeMedium
						}
                        placeholderText: qsTr("Preset Name")    
                    }

                   PolyControls.Button {
						font {
							pixelSize: fontSizeMedium
						}
						width: 250
						height: 100
                        text: "SAVE"
                        enabled: new_preset_name.text.length > 0
						onClicked: {
							knobs.ui_save_pedalboard(new_preset_name.text);
							mainStack.pop()
						}
                    }
                }
				InputPanel {
					id: inputPanel
					// parent:mainWindow.contentItem
					z: 1000002
					anchors.bottom:parent.bottom
					anchors.left: parent.left
					anchors.right: parent.right
                    width: 1000

					visible: Qt.inputMethod.visible
				}

                IconButton {
                    x: 34 
                    y: 646
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
                    Material.background: "white"
                    Material.foreground: Constants.outline_color
                    onClicked: presetStack.pop()
                }
            }
        }

        Component {
            id: mapPresets
            Item {
                id: mapPresetsCont
				height:700
				width:1280


               PolyControls.SpinBox {
                    y: 80
                    x: 500
                    // width: 500
                    font.pixelSize: fontSizeMedium
                    from: 1
                    value: presetList.rowCount()
                    to: 127
                    onValueModified: {
                        knobs.set_preset_list_length(value);
                    }
                }
                ListView {
                    x: 500
                    y: 150
                    width: 600
                    height: 500
                    clip: true
                    delegate:PolyControls.ItemDelegate {
                        width: parent.width
                        height: 50
                        text: index + " " + edit.slice(20, -6) // trim .ingen and /mnt/preset
                        bottomPadding: 10
                        font.pixelSize: fontSizeMedium
                        topPadding: 10
                        onClicked: {
                            // knobs.ui_add_connection(effect, sourcePort, edit)
                            preset_widget.map_index = index;
                            presetStack.push(mapPresetBrowser)
                        }
                    }
                    ScrollIndicator.vertical: ScrollIndicator {
                        anchors.top: parent.top
                        parent: mapPresetsCont
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.bottom: parent.bottom
                    }
                    model: presetList
                }
                // Row {
                //     spacing: 100
					// anchors.centerIn: parent
                //    PolyControls.Button {
						// font {
							// pixelSize: fontSizeLarge
						// }
                //         text: "OVERWRITE"
						// width: 300
                //         onClicked: { // save preset and close browser
							// knobs.ui_save_preset(currentPreset.name);
							// mainStack.pop()
						// }
                //     }
                //    PolyControls.Button {
						// font {
							// pixelSize: fontSizeLarge
						// }
                //         text: "CREATE NEW"
						// width: 300
                //         onClicked: presetStack.push(choosePresetFolder)
                //     }
                // }
                IconButton {
                    x: 34 
                    y: 646
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
                    Material.background: "white"
                    Material.foreground: Constants.outline_color
                    onClicked: { 
                        knobs.save_preset_list();
                        presetStack.pop();
                    }
                }

            }
        }

        Component {
            id: mapPresetBrowser
            // height:parent.height
            // Column {
                // width:300
                // spacing: 20
                // height:parent.height
                Item {
					height:720
					width:1280

                    PresetBrowser {
                        y: 0
						x: 0
						after_file_selected: (function(name) { 
							console.log("mapping preset file");
							knobs.map_preset(preset_widget.map_index, name.toString());
                            presetStack.pop()
						})
						
                    } 

                }
            // }
        }

        StackView {
            id: presetStack
            initialItem: loadOrSave
        }

    }
// }
