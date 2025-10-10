import "controls" as PolyControls
import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.2
import QtQuick.Controls.Material 2.3
import "polyconst.js" as Constants
import QtQuick.VirtualKeyboard 2.1

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
    height:700
    width:1280
    Component {
        id: mainSettings
        Item {
            height:720
            width:1280
			y: 30
            Row {
                anchors.centerIn: parent
                height:650
                spacing: 200
                Column {
                    width:350
                    x: 50
                    // anchors.left: parent.left
                    spacing: 30
                    // height:parent.height
                    GlowingLabel {
						width: 400
                        // color: "#ffffff"
                        text: currentPedalModel.name+" FIRMWARE 403"
                        color: accent_color.name
						font {
							pixelSize: 35
							capitalization: Font.AllUppercase
							family: mainFont.name
						}
                    }

                   PolyControls.Button {
						width: 300
                        text: "COPY IRS / AMPS"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: settingsStack.push(copyIRInfo)
                        flat: false
                        Material.foreground: "white"
                        Material.background: Constants.outline_color
                    }

                   PolyControls.Button {
						width: 300
                        text: "DELETE ALL IRS"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: settingsStack.push(deleteIRInfo)
                        flat: false
                        Material.foreground: "white"
                        Material.background: Constants.outline_color
                    }

                    GlowingLabel {
						width: 300
                        // color: "#ffffff"
                        text: qsTr("MIDI CHANNEL")
                    }

                   PolyControls.SpinBox {
						width: 300
                        id: midi_channel_spin
                        font.pixelSize: baseFontSize
                        from: 1
                        to: 16
                        value: midiChannel.value
                        up.onPressedChanged: {
                            if (!(up.pressed)){
                                knobs.set_channel(value+1);
                            }
                        }
                        down.onPressedChanged: {
                            if (!(down.pressed)){
                                knobs.set_channel(value-1);
                            }
                        }

                        Component.onCompleted: value = midiChannel.value 
                    }



					Switch {
						text: "left to right"
						width: 300
						checked: Boolean(pedalState["l_to_r"])
						onToggled: {
							knobs.set_l_to_r(!pedalState["l_to_r"]);
                            knobs.ui_load_empty_preset();
						}
						font {
							pixelSize: 24
							capitalization: Font.AllUppercase
							family: mainFont.name
						}
						Material.foreground: Constants.rainbow[8]

					}
                    // GlowingLabel {
                    //     // color: "#ffffff"
                    //     text: qsTr("BYPASS TYPE")
                    // }
                    // PolyCombo {
                    //     flat: false
                    //     // width: 140
                    //     model: ["relay", "1 to all"]
                    //     onActivated: {
                    //         // console.debug(model[index]);
                    //         knobs.set_bypass_type(model[index]);
                    //     }
                    // }
                    Row {
                        width: 300
                        spacing: 10
                       PolyControls.Button {
                            flat: false
                            width: 140
                            text: "COPY LOGS"
                            font.pixelSize: baseFontSize
                            // show screen explaining to put USB flash drive in
                            onClicked: knobs.copy_logs()
                        }

                       PolyControls.Button {
                            flat: false
                            width: 140
                            text: "RESET SET LIST"
                            font.pixelSize: baseFontSize
                            onClicked: knobs.reset_preset_list()
                        }
                    }

					Switch {
						text: "D is tuner"
						width: 300
						checked: Boolean(pedalState["d_is_tuner"])
						onToggled: {
							knobs.set_d_is_tuner(!pedalState["d_is_tuner"]);
						}
						font {
							pixelSize: 24
							capitalization: Font.AllUppercase
							family: mainFont.name
						}
						Material.foreground: Constants.rainbow[8]

					}


                    //PolyControls.Switch {
                    //     font.pixelSize: baseFontSize
                    //     text: qsTr("SEND MIDI CLOCK")
                    //     // bottomPadding: 0
                    //     width: 300
                    //     // leftPadding: 0
                    //     // topPadding: 0
                    //     // rightPadding: 0
                    //     checked: true
                    //     // onClicked: {
                    //     //     lfo_control.snapping = checked
                    //     // }
                    // }

                    //PolyControls.Switch {
                    //     font.pixelSize: baseFontSize
                    //     text: qsTr("ENABLE LINK")
                    //     // bottomPadding: 0
                    //     width: 300
                    //     // leftPadding: 0
                    //     // topPadding: 0
                    //     // rightPadding: 0
                    //     checked: true
                    //     onClicked: {
                    //         knobs.enable_ableton_link(checked);
                    //     }
                    // }

                }
                Column {
                    width:350
                    x: 500
                    // anchors.centerIn: parent
                    // anchors.right: parent.right
                    spacing: 30
                    // height:parent.height

                   PolyControls.Button {
                        flat: false
						width: 300
                        font.pixelSize: baseFontSize
                        text: "FIRMWARE UPDATE"
                        onClicked: settingsStack.push(updateFirmware)
                        // show screen explaining to put USB flash drive in
                    }

                    //PolyControls.Switch {
                    //     font.pixelSize: baseFontSize
                    //     text: qsTr("IN 1/2 BALANCED")
                    //     // bottomPadding: 0
                    //     width: 300
                    //     // leftPadding: 0
                    //     // topPadding: 0
                    //     // rightPadding: 0
                    //     checked: false
                    //     // onClicked: {
                    //     //     lfo_control.snapping = checked
                    //     // }
                    // }
                    //PolyControls.Switch {
                    //     font.pixelSize: baseFontSize
                    //     text: qsTr("IN 3/4 BALANCED")
                    //     // bottomPadding: 0
                    //     width: 300
                    //     // leftPadding: 0
                    //     // topPadding: 0
                    //     // rightPadding: 0
                    //     checked: false
                    //     // onClicked: {
                    //     //     lfo_control.snapping = checked
                    //     // }
                    // }
                    //PolyControls.Switch {
                    //     font.pixelSize: baseFontSize
                    //     text: qsTr("OUT 1/2 BALANCED")
                    //     // bottomPadding: 0
                    //     width: 300
                    //     // leftPadding: 0
                    //     // topPadding: 0
                    //     // rightPadding: 0
                    //     checked: false
                    //     // onClicked: {
                    //     //     lfo_control.snapping = checked
                    //     // }
                    // }
                    //PolyControls.Switch {
                    //     font.pixelSize: baseFontSize
                    //     text: qsTr("OUT 3/4 BALANCED")
                    //     // bottomPadding: 0
                    //     width: 300
                    //     // leftPadding: 0
                    //     // topPadding: 0
                    //     // rightPadding: 0
                    //     checked: false
                    //     // onClicked: {
                    //     //     lfo_control.snapping = checked
                    //     // }
                    // }
                    GlowingLabel {
						width: 300
                        // color: "#ffffff"
                        text: qsTr("INPUT LEVEL")
                    }
                   PolyControls.SpinBox {
						width: 300
                        id: input_level_spin
                        font.pixelSize: baseFontSize
                        from: -80
                        to: 10

                        up.onPressedChanged: {
                            if (!(up.pressed)){
                                knobs.set_input_level(Number(value)+1);
                            }
                        }
                        down.onPressedChanged: {
                            if (!(down.pressed)){
                                knobs.set_input_level(Number(value)-1);
                            }
                        }
                        Component.onCompleted: value = inputLevel.value
                    }

                    //PolyControls.Button {
                    //     flat: false
                    //     text: "STAGE VIEW"
                    //     font.pixelSize: baseFontSize
                    //     // show screen explaining to put USB flash drive in
                    //     onClicked: mainStack.push("PerformanceMode.qml")
                    // }

                   PolyControls.Button {
                        flat: false
                        text: "QA CHECK"
						width: 300
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: mainStack.push("QATest.qml")
                    }

					Switch {
						text: "MIDI THRU"
						width: 300
						checked: Boolean(pedalState["thru"])
						onToggled: {
							knobs.set_thru_enabled(!pedalState["thru"]);
						}
						font {
							pixelSize: 24
							capitalization: Font.AllUppercase
							family: mainFont.name
						}
						Material.foreground: Constants.rainbow[0]

					}

                   PolyControls.Button {
                        flat: false
						width: 300
                        text: "SET AUTHOR"
                        font.pixelSize: baseFontSize
                        onClicked: settingsStack.push(setAuthor)
                    }

                   PolyControls.Button {
                        flat: false
						width: 300
                        text: "FLIP SCREEN"
                        font.pixelSize: baseFontSize
                        onClicked: knobs.flip_screen()
                    }


					Switch {
						text: "Interconnect"
						width: 300
						checked: interconnect
						onToggled: {
							interconnect = !(interconnect)
						}
						font {
							pixelSize: 24
							capitalization: Font.AllUppercase
							family: mainFont.name
						}
						Material.foreground: Constants.rainbow[1]

					}
                }
            }

            IconButton {
                x: 34 
                y: 610
                icon.width: 15
                icon.height: 25
                width: 120
                height: 62
                flat: false
                icon.name: "back"
                Material.background: "white"
                Material.foreground: Constants.outline_color
                onClicked: mainStack.pop()
            }
        }
    }

    Component {
        id: copyIRInfo
        Item {
            height:700
            width:1280
            property int update_counter
            Row {
                spacing: 100
                anchors.centerIn: parent

                Column {
                    width: 600
                    Text {
                        font {
                            pixelSize: fontSizeMedium
                        }
                        color: Material.foreground
                        text: "Please put a USB key into the USB port with the IRs in a folder called <b>reverbs</b> for reverbs,  <b>cabs</b> for cabs and amps for NAM amp captures.<p> Only 48kHz WAV IRs supported, NAM captures must be a zip, generated by the Poly Capture website.</p>"
                        width: 600
                        wrapMode: Text.WordWrap
                        textFormat: Text.StyledText
                    }

                    Text {
                        font {
                            pixelSize: fontSizeMedium
                        }
                        color: Material.foreground
                        text: update_counter, knobs.usb_information_text()
                        width: 600
                        wrapMode: Text.WordWrap
                        textFormat: Text.StyledText
                    }
                }

                Column {
                    y: 150
                    spacing: 100
                    width: 450
                   PolyControls.Button {
                        flat: false
                        font {
                            pixelSize: fontSizeMedium
                        }
                        text: "REFRESH USB INFO"
                        width: 400
                        onClicked: { 
                            update_counter++;
                        }
                    }

                   PolyControls.Button {
                        flat: false
                        font {
                            pixelSize: fontSizeMedium
                        }
                        text: "COPY IRs"
                        width: 400
                        onClicked: { 
                            settingsStack.push(irCopyView)
                            knobs.ui_copy_irs();
                        }
                    }

                   PolyControls.Button {
                        flat: false
                        font {
                            pixelSize: fontSizeMedium
                        }
                        text: "COPY AMPS"
                        width: 400
                        onClicked: { 
                            settingsStack.push(irCopyView)
                            knobs.ui_copy_amps();
                        }
                    }
                }

            }
           PolyControls.Button {
                font {
                    pixelSize: fontSizeMedium
                }
                text: "BACK"
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.topMargin: 10
                width: 100
                height: 100
                onClicked: settingsStack.pop()
            }
        }
    }

    Component {
        id: deleteIRInfo
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
                    text: "This will delete all imported IRs. Only do this if you want to remove everything and start fresh."
                    width: 300
                    wrapMode: Text.WordWrap
                    textFormat: Text.StyledText
                }

               PolyControls.Button {
                    flat: false
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "DELETE IRs"
                    width: 300
                    onClicked: { 
                        knobs.delete_all_irs();
                        settingsStack.pop()
                    }
                }
            }
           PolyControls.Button {
                font {
                    pixelSize: fontSizeMedium
                }
                text: "BACK"
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.topMargin: 10
                width: 100
                height: 100
                onClicked: settingsStack.pop()
            }
        }
    }


    Component {
        id: updateFirmware
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
                    text: "Please put a USB key into the USB port with the firmware update. It should not be in a sub folder. <p> Do not turn off the pedal while this is in progress.</p>"
                    width: 300
                    wrapMode: Text.WordWrap
                    textFormat: Text.StyledText
                }

               PolyControls.Button {
                    flat: false
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "Update firmware"
                    width: 300
                    onClicked: { // save preset and close browser
                        settingsStack.push(firmwareUpdateView)
                        knobs.ui_update_firmware();
                    }
                }
            }
           PolyControls.Button {
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
                onClicked: settingsStack.pop()
            }
        }
    }

    Component {
        id: firmwareUpdateView
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
                    text: "Firmware update successful. Please turn pedal off and on again."
                    width: 300
                    wrapMode: Text.WordWrap
                    visible: commandStatus[0].value == 0
                }

                Text {
                    font {
                        pixelSize: fontSizeMedium
                    }
                    color: Material.foreground
                    text: commandStatus[0].name + commandStatus[1].name
                    width: 300
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    visible: commandStatus[0].value > 0 && commandStatus[0].value != 16 
                }
				
                Text {
                    font {
                        pixelSize: fontSizeMedium
                    }
                    color: Material.foreground
                    text: "Need to restart and retry firmware update, as file system needed to be reorganised, please press shutdown, then when it's restarted come back and update again"
                    width: 300
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    visible: commandStatus[0].value == 16 
                }

               PolyControls.Button {
                    flat: false
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "Shutdown"
                    width: 300
                    onClicked: {
                        knobs.ui_shutdown();
                    }
                    visible: commandStatus[0].value == 16 
                }

                BusyIndicator {
                    running: commandStatus[0].value < 0 
                }

                Text {
                    font {
                        pixelSize: fontSizeMedium
                    }
                    color: Material.foreground
                    text: "Updating. Please wait."
                    width: 300
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                    visible: commandStatus[0].value < 0
                }

            }
           PolyControls.Button {
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
                visible: commandStatus[0].value > 0 
                onClicked: settingsStack.pop()
            }
        }
    }

    Component {
        id: irCopyView
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
                    text: "IRs / Amps copied sucessfully"
                    width: 300
                    wrapMode: Text.WordWrap
                    visible: (commandStatus[0].value == 0)
                }

                Text {
                    font {
                        pixelSize: fontSizeMedium
                    }
                    color: Material.foreground
                    text: "IR  / Amp copy failed. Please make sure flash drive is plugged in, they are in the right folder and watch the tutorial video. If that doesn't work, please contact Loki@polyeffects.com"
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
           PolyControls.Button {
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
                onClicked: settingsStack.pop(null)
            }
        }
    }

    Component {
        id: setAuthor

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
                    text: qsTr("Enter your name")
                }

                TextField {
                    validator: RegExpValidator { regExp: /^[0-9a-zA-Z ]+$/}
                    id: pedal_author
                    width: 250
                    height: 100
                    font {
                        pixelSize: fontSizeMedium
                    }
					text: pedalState["author"]
                    placeholderText: qsTr("Preset Author")    
                }

               PolyControls.Button {
                    font {
                        pixelSize: fontSizeMedium
                    }
                    width: 250
                    height: 100
                    text: "SAVE"
                    enabled: pedal_author.text.length > 0
                    onClicked: {
                        knobs.set_pedal_author(pedal_author.text);
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
                onClicked: settingsStack.pop()
            }
        }
    }

    StackView {
        id: settingsStack
        initialItem: mainSettings
    }
}
