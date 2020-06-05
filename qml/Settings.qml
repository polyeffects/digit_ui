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
                        // color: "#ffffff"
                        text: currentPedalModel.name+" FIRMWARE 2.33a"
                        color: accent_color.name
                    }

                    Button {
                        text: "Copy IRs"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: settingsStack.push(copyIRInfo)
                        flat: false
                        Material.foreground: "white"
                        Material.background: Constants.outline_color
                    }

                    GlowingLabel {
                        // color: "#ffffff"
                        text: qsTr("MIDI CHANNEL")
                    }

                    SpinBox {
                        id: midi_channel_spin
                        font.pixelSize: baseFontSize
                        from: 1
                        to: 16
                        value: midiChannel.value
                    }

                    Button {
                        flat: false
                        text: "SET CHANNEL"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: knobs.set_channel(midi_channel_spin.value)
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
                    Button {
                        flat: false
                        text: "COPY LOGS"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: knobs.copy_logs()
                    }

                    Button {
                        flat: false
                        text: currentPedalModel.name == "beebo" ? "Change to Digit" : "Change to Beebo"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
						onClicked: {
							if(currentPedalModel.name == "beebo"){
								knobs.set_pedal_model("digit");
							} else {
								knobs.set_pedal_model("beebo");
							}
						}

                    }

                    Button {
                        flat: false
                        text: "SET AUTHOR"
                        font.pixelSize: baseFontSize
                        onClicked: settingsStack.push(setAuthor)
                    }


                    // Switch {
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

                    // Switch {
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
                    spacing: 20
                    // height:parent.height

                    Button {
                        flat: false
                        font.pixelSize: baseFontSize
                        text: "FIRMWARE UPDATE"
                        onClicked: settingsStack.push(updateFirmware)
                        // show screen explaining to put USB flash drive in
                    }

                    // Switch {
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
                    // Switch {
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
                    // Switch {
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
                    // Switch {
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
                        // color: "#ffffff"
                        text: qsTr("INPUT LEVEL")
                    }
                    // FIXME
                    SpinBox {
                        id: input_level_spin
                        font.pixelSize: baseFontSize
                        from: -80
                        to: 10
                        value: inputLevel.value
                    }

                    Button {
                        flat: false
                        text: "SET INPUT LEVEL"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: knobs.set_input_level(input_level_spin.value)
                    }

                    // Button {
                    //     flat: false
                    //     text: "STAGE VIEW"
                    //     font.pixelSize: baseFontSize
                    //     // show screen explaining to put USB flash drive in
                    //     onClicked: mainStack.push("PerformanceMode.qml")
                    // }

                    Button {
                        flat: false
                        text: "QA Check"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: mainStack.push("QATest.qml")
                    }

                }
            }

            IconButton {
                x: 34 
                y: 646
                icon.width: 15
                icon.height: 25
                width: 62
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
            Row {
                spacing: 100
                anchors.centerIn: parent

                Text {
                    font {
                        pixelSize: fontSizeMedium
                    }
                    color: Material.foreground
                    text: "Please put a USB key into the USB port with the IRs in a folder called <b>reverbs</b> for reverbs and <b>cabs</b> for cabs.<p> This will overwrite any with the same name.</p><p> Only 48kHz WAV supported. </p>"
                    width: 300
                    wrapMode: Text.WordWrap
                    textFormat: Text.StyledText
                }

                Button {
                    flat: false
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "COPY IRs"
                    width: 300
                    onClicked: { 
                        settingsStack.push(irCopyView)
                        knobs.ui_copy_irs();
                    }
                }
            }
            Button {
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

                Button {
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
                    text: "Firmware update failed. Please make sure file is in the right location and watch the tutorial video. If that doesn't work, please contact Loki@polyeffects.com"
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
                    text: "Updating. Please wait."
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
                    text: "IRs copied sucessfully"
                    width: 300
                    wrapMode: Text.WordWrap
                    visible: (commandStatus[0].value == 0)
                }

                Text {
                    font {
                        pixelSize: fontSizeMedium
                    }
                    color: Material.foreground
                    text: "IR copy failed. Please make sure flash drive is plugged in, they are in the right folder and watch the tutorial video. If that doesn't work, please contact Loki@polyeffects.com"
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
                    placeholderText: qsTr("Preset Author")    
                }

                Button {
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
