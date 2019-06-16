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
    height:580
    width:1280
    Row {
        anchors.centerIn: parent
        height:480
        spacing: 200
    Column {
        width:300
        x: 100
        // anchors.left: parent.left
        spacing: 20
        // height:parent.height

        Button {
            text: "Copy reverb IRs"
            // show screen explaining to put USB flash drive in
        }

        Button {
            text: "Copy cab IRs"
            // show screen explaining to put USB flash drive in
        }
        GlowingLabel {
            // color: "#ffffff"
            text: qsTr("MIDI CHANNEL")
        }

        SpinBox {
            from: 1
            to: 16
            value: 1
        }

        Switch {
            text: qsTr("SEND MIDI CLOCK")
            // bottomPadding: 0
            width: 200
            // leftPadding: 0
            // topPadding: 0
            // rightPadding: 0
            checked: true
            // onClicked: {
            //     lfo_control.snapping = checked
            // }
        }

        Switch {
            text: qsTr("ENABLE LINK")
            // bottomPadding: 0
            width: 200
            // leftPadding: 0
            // topPadding: 0
            // rightPadding: 0
            checked: true
            // onClicked: {
            //     lfo_control.snapping = checked
            // }
        }

    }
    Column {
        width:300
        x: 500
        // anchors.centerIn: parent
        // anchors.right: parent.right
        spacing: 20
        // height:parent.height

        Button {
            text: "FIRMWARE UPDATE"
            // show screen explaining to put USB flash drive in
        }

        Button {
            text: "EXPORT PRESETS"
            // show screen explaining to put USB flash drive in
        }
        Button {
            text: "LOAD PRESETS"
            // show screen explaining to put USB flash drive in
        }
        Switch {
            text: qsTr("IN 1/2 BALANCED")
            // bottomPadding: 0
            width: 200
            // leftPadding: 0
            // topPadding: 0
            // rightPadding: 0
            checked: false
            // onClicked: {
            //     lfo_control.snapping = checked
            // }
        }
        Switch {
            text: qsTr("IN 3/4 BALANCED")
            // bottomPadding: 0
            width: 200
            // leftPadding: 0
            // topPadding: 0
            // rightPadding: 0
            checked: false
            // onClicked: {
            //     lfo_control.snapping = checked
            // }
        }
        Switch {
            text: qsTr("OUT 1/2 BALANCED")
            // bottomPadding: 0
            width: 200
            // leftPadding: 0
            // topPadding: 0
            // rightPadding: 0
            checked: false
            // onClicked: {
            //     lfo_control.snapping = checked
            // }
        }
        Switch {
            text: qsTr("OUT 3/4 BALANCED")
            // bottomPadding: 0
            width: 200
            // leftPadding: 0
            // topPadding: 0
            // rightPadding: 0
            checked: false
            // onClicked: {
            //     lfo_control.snapping = checked
            // }
        }

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

