import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.2
import QtQuick.Controls.Material 2.3

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
                height:500
                spacing: 200
                Column {
                    width:350
                    x: 50
                    // anchors.left: parent.left
                    spacing: 30
                    // height:parent.height
                    GlowingLabel {
                        // color: "#ffffff"
                        text: qsTr("DIGIT FIRMWARE 1.4")
                    }

                    Button {
                        text: "Copy IRs"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: settingsStack.push(copyIRInfo)
                        flat: true
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
                        flat: true
                        text: "SET CHANNEL"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: knobs.set_channel(midi_channel_spin.value)
                    }
                    GlowingLabel {
                        // color: "#ffffff"
                        text: qsTr("BYPASS TYPE")
                    }
                    PolyCombo {
                        flat: true
                        // width: 140
                        model: ["relay", "1 to all"]
                        onActivated: {
                            // console.debug(model[index]);
                            knobs.set_bypass_type(model[index]);
                        }
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
                        flat: true
                        font.pixelSize: baseFontSize
                        text: "FIRMWARE UPDATE"
                        onClicked: settingsStack.push(updateFirmware)
                        // show screen explaining to put USB flash drive in
                    }

                    Button {
                        flat: true
                        font.pixelSize: baseFontSize
                        text: "EXPORT PRESETS"
                        // show screen explaining to put USB flash drive in
                        onClicked: settingsStack.push(exportPresets)
                    }
                    Button {
                        flat: true
                        font.pixelSize: baseFontSize
                        text: "IMPORT PRESETS"
                        // show screen explaining to put USB flash drive in
                        onClicked: settingsStack.push(importPresets)
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
                        value: -8
                    }

                    Button {
                        flat: true
                        text: "SET INPUT LEVEL"
                        font.pixelSize: baseFontSize
                        // show screen explaining to put USB flash drive in
                        onClicked: knobs.set_input_level(input_level_spin.value)
                    }

                }
            }
            Button {
                flat: true
                font.pixelSize: baseFontSize
                text: "BACK"
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.topMargin: 10
                width: 100
                height: 100
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
                    flat: true
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "COPY IRs"
                    width: 300
                    onClicked: { 
                        knobs.ui_copy_irs();
                        settingsStack.push(irCopyView)
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
                    flat: true
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "Export Presets"
                    width: 300
                    onClicked: { // save preset and close browser
                        knobs.export_presets();
                        settingsStack.push(presetCopyView)
                    }
                }
            }
            Button {
                flat: true
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
                    flat: true
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "Import Presets"
                    width: 300
                    onClicked: { // save preset and close browser
                        knobs.import_presets();
                        settingsStack.push(presetCopyView)
                    }
                }
            }
            Button {
                flat: true
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
                    flat: true
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "Update firmware"
                    width: 300
                    onClicked: { // save preset and close browser
                        knobs.ui_update_firmware();
                        settingsStack.push(firmwareUpdateView)
                    }
                }
            }
            Button {
                flat: true
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
                flat: true
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
                flat: true
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
                    visible: (commandStatus[0].value == 0 || commandStatus[1].value == 0) && (commandStatus[0].value >= 0 && commandStatus[1].value >= 0)
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
                    visible: commandStatus[0].value > 0 && commandStatus[1].value > 0 
                }

                BusyIndicator {
                    running: commandStatus[0].value < 0 || commandStatus[1].value < 0 
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
                    visible: commandStatus[0].value < 0 || commandStatus[1].value < 0 
                }

            }
            Button {
                flat: true
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
    StackView {
        id: settingsStack
        initialItem: mainSettings
    }
}
