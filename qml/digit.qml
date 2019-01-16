/* DIGIT UI ****************************************************************************/

import QtQuick 2.9
//import QtQuick.Layouts 1.12
//import QtQuick.Controls 2.12
//import QtQuick.Controls.Imagine 2.12
//import QtQuick.Window 2.0
// import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
// import QtQuick.Controls.Imagine 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Window 2.0

ApplicationWindow {
    id: window
    // width: 480
    // height: 800
    // minimumHeight: 800
    // minimumWidth: 480
    // maximumHeight: 800
    // maximumWidth: 480
    visible: true
    title: "Digit"
    width: 800//Screen.height dev settings
    height: 480//Screen.width

    Material.theme: Material.Dark

    Material.accent: Material.Pink

    readonly property color colorGlow: "#1d6d64"
    readonly property color colorWarning: "#d5232f"
    readonly property color colorMain: "#6affcd"
    readonly property color colorBright: "#ffffff"
    readonly property color colorLightGrey: "#888"
    readonly property color colorDarkGrey: "#333"

    readonly property int fontSizeExtraSmall: Qt.application.font.pixelSize * 0.8
    readonly property int fontSizeMedium: Qt.application.font.pixelSize * 1.5
    readonly property int fontSizeLarge: Qt.application.font.pixelSize * 2
    readonly property int fontSizeExtraLarge: Qt.application.font.pixelSize * 5

    Item {
        // transform: Rotation {
        //     angle: -90
        //     /* origin.x: Screen.height / 2 */
        //     /* origin.x: Screen.height / 2 */
        //     // origin.x: 480 / 2
        //     // origin.y: 480 / 2
        //     origin.x: 800 / 2
        //     origin.y: 800 / 2
        // }
        id: root
        width: 800//Screen.height
        height: 480//Screen.width

        StackLayout {
            id: stackLayout
            currentIndex: topLevelBar.currentIndex
            // currentIndex: topLevelTabs.currentIndex
            anchors.fill: parent

            Frame {
                id: delayFrame
                Layout.fillWidth: true
                z: -1
                StackLayout {
                    id: delayStack1
                    anchors.bottomMargin: 40
                    anchors.rightMargin: 0
                    anchors.topMargin: 27
                    currentIndex: delayTabs.currentIndex
                    anchors.fill: parent
                    Frame {
                        id: reverbFrame3
                        width: 800
                        height: 480
                        z: -1
                        Column {
                            id: column2
                            x: 0
                            y: 42
                            width: 120
                            height: 258
                        }

                        Column {
                            id: column3
                            x: 650
                            y: 58
                            width: 102
                            height: 271
                            spacing: 10
                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("TIME")
                                font.pixelSize: fontSizeMedium
                            }

                            MixerDial {
                                effect: "delay1"
                                param: "l_delay"
                                value: 0.5
                                to: 1
                                width: 100
                                height: 100
                            }

                            GlowingLabel {
                                color: "#ffffff"
                                text: "FEEDBACK"
                                font.pixelSize: fontSizeMedium
                            }

                            MixerDial {
                                effect: "delay1"
                                param: "feedback"
                                value: 0.7
                                to: 1
                                width: 100
                                height: 100
                            }
                        }
                    }

                    Frame {
                        id: effects
                        width: 800
                        height: 480
                        z: -1

                        Column {
                            spacing: 8
                            width: parent.width
                            anchors.fill: parent
                            GroupBox {
                                width: parent.width
                                anchors.left: parent.left
                                anchors.right: parent.right
                                title: qsTr("Tape / Tube")

                                Row {
                                    width: 800
                                    height: 35
                                    anchors.top: parent.top
                                    // anchors.topMargin: 10

                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("DRIVE")
                                        font.pixelSize: fontSizeMedium
                                    }
                                    MixerDial {
                                        effect: "tape1"
                                        param: "drive"
                                        value: 5
                                        to: 10
                                    }
                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("Tape vs Tube")
                                        font.pixelSize: fontSizeMedium
                                    }
                                    MixerDial {
                                        effect: "tape1"
                                        param: "blend"
                                        value: 10
                                        from: -10
                                        to: 10
                                    }
                                    SwitchDelegate {
                                        text: qsTr("Enabled")
                                        bottomPadding: 0
                                        Layout.fillWidth: true
                                        leftPadding: 0
                                        topPadding: 0
                                        rightPadding: 0
                                    }
                                    spacing: 35
                                }
                            }
                            GroupBox {
                                width: parent.width
                                anchors.left: parent.left
                                anchors.right: parent.right
                                title: qsTr("Lowpass Filter")

                                Row {
                                    width: 800
                                    height: 35
                                    anchors.top: parent.top
                                    // anchors.topMargin: 10

                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("CUTOFF")
                                        font.pixelSize: fontSizeMedium
                                    }
                                    MixerDial {
                                        effect: "filter1"
                                        param: "freq"
                                        value: 1
                                        from: 20
                                        to: 20000
                                        stepSize: 10
                                    }
                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("RESONANCE")
                                        font.pixelSize: fontSizeMedium
                                    }
                                    MixerDial {
                                        effect: "filter1"
                                        param: "res"
                                        value: 0
                                        from: 0
                                        to: 0.8
                                    }
                                    SwitchDelegate {
                                        text: qsTr("Enabled")
                                        bottomPadding: 0
                                        Layout.fillWidth: true
                                        leftPadding: 0
                                        topPadding: 0
                                        rightPadding: 0
                                    }
                                    spacing: 35
                                }
                            }

                            GroupBox {
                                width: parent.width
                                anchors.left: parent.left
                                anchors.right: parent.right
                                title: qsTr("Compression Boost")

                                Row {
                                    width: 800
                                    height: 35
                                    anchors.top: parent.top
                                    // anchors.topMargin: 10

                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("PRE GAIN")
                                        font.pixelSize: fontSizeMedium
                                    }
                                    MixerDial {
                                        effect: "sigmoid1"
                                        param: "Pregain"
                                        value: 0
                                        from: -90
                                        to: 20
                                    }
                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("POST GAIN")
                                        font.pixelSize: fontSizeMedium
                                    }
                                    MixerDial {
                                        effect: "sigmoid1"
                                        param: "Postgain"
                                        value: 0
                                        from: -90
                                        to: 20
                                    }
                                    SwitchDelegate {
                                        text: qsTr("Enabled")
                                        bottomPadding: 0
                                        Layout.fillWidth: true
                                        leftPadding: 0
                                        topPadding: 0
                                        rightPadding: 0
                                    }
                                    spacing: 35
                                }
                            }
                        }
                    }

                    Frame {
                        id: bus
                        width: parent.width
                        height:parent.height
                        z: -1

                        PolyBus {
                            id: polyBus
                            width: 800
                            height: 394
                            availablePorts: delay1_Left_OutAvailablePorts
                            usedPorts: delay1_Left_OutUsedPorts
                            effect: "delay1"
                            sourcePort: "Left Out"
                        }
                    }
                }

                TabBar {
                    id: delayTabs
                    width: 376
                    height: 38
                    spacing: 0
                    currentIndex: 2
                    anchors.bottom: parent.bottom
                    TabButton {
                        id: tabButton7
                        text: qsTr("Main")
                    }

                    TabButton {
                        id: tabButton8
                        text: qsTr("Effects")
                    }

                    TabButton {
                        id: tabButton9
                        text: qsTr("Bus")
                    }
                    anchors.bottomMargin: 0
                }
                Layout.fillHeight: true
            }

            Frame {
                id: reverbFrame1
                Layout.fillWidth: true
                Layout.fillHeight: true
                z: -1

                StackLayout {
                    id: reverbStack
                    anchors.fill: parent
                    currentIndex: reverbTabs.currentIndex


                    Frame {
                        id: reverbFrame
                        width: 800
                        height: 480
                        z: -1


                        ColumnLayout {
                            x: 191
                            y: 66
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            Image {
                                x: 0
                                Layout.fillHeight: false
                                source: "qrc:/icons/reverb_cube.png"
                                fillMode: Image.PreserveAspectFit
                            }
                            Layout.preferredWidth: 350
                        }


                        Column {
                            id: column1
                            x: 625
                            y: 66
                            width: 102
                            height: 271
                            spacing: 10
                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("MIX")
                                font.pixelSize: fontSizeMedium
                            }

                            MixerDial {
                                effect: "reverb"
                                param: "dry_wet"
                                value: 50
                                to: 100
                                width: 100
                                height: 100
                            }

                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("SIZE")
                                font.pixelSize: fontSizeMedium
                            }

                            MixerDial {
                                effect: "reverb"
                                param: "roomsize"
                                value: 0.5
                                to: 1
                                width: 100
                                height: 100
                            }
                        }
                    }

                    Frame {
                        id: bus2
                        width: 800
                        height: 480

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height
                            GroupBox {
                                title: qsTr("Left")
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 0.5 * parent.width
                                PolyBus {
                                    id: polyBusRL
                                    availablePorts: reverb_OutAvailablePorts
                                    usedPorts: reverb_OutUsedPorts
                                    effect: "reverb"
                                    sourcePort: "Out"
                                }
                            }
                            GroupBox {
                                title: qsTr("Right")
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 0.5 * parent.width
                                PolyBus {
                                    id: polyBusRR
                                    availablePorts: reverb_Out1AvailablePorts
                                    usedPorts: reverb_Out1UsedPorts
                                    effect: "reverb"
                                    sourcePort: "Out1"
                                }
                            }
                        }
                        z: -1
                    }
                }

                TabBar {
                    id: reverbTabs
                    width: 376
                    height: 38
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 0
                    TabButton {
                        id: tabButton4
                        text: qsTr("Main")
                    }

                    TabButton {
                        id: tabButton5
                        text: qsTr("Effects")
                    }

                    TabButton {
                        id: tabButton6
                        text: qsTr("Bus")
                    }
                }
            }

            Frame {
                id: mixerFrame
                z: -1
                Layout.fillWidth: true

                StackLayout {
                    id: delayStack2

                    Frame {
                        id: reverbFrame4
                        width: 800
                        height: 439
                        z: -1
                        Column {
                            x: 50
                            y: 5
                            width: 150
                            height: 405
                            spacing: 10
                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("IN 1")
                                font.pixelSize: fontSizeMedium
                            }

                            MixerDial {
                                param: "mix_1_1"
                            }
                            MixerDial {
                                param: "mix_1_2"
                            }
                            MixerDial {
                                param: "mix_1_3"
                            }
                            MixerDial {
                                param: "mix_1_4"
                            }

                        }
                        Column {
                            x: 200
                            y: 5
                            width: 150
                            height: 405
                            spacing: 10
                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("IN 2")
                                font.pixelSize: fontSizeMedium
                            }

                            MixerDial {
                                param: "mix_2_1"
                            }
                            MixerDial {
                                param: "mix_2_2"
                            }
                            MixerDial {
                                param: "mix_2_3"
                            }
                            MixerDial {
                                param: "mix_2_4"
                            }

                        }
                        Column {
                            x: 350
                            y: 5
                            width: 150
                            height: 405
                            spacing: 10
                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("IN 3")
                                font.pixelSize: fontSizeMedium
                            }

                            MixerDial {
                                param: "mix_3_1"
                            }
                            MixerDial {
                                param: "mix_3_2"
                            }
                            MixerDial {
                                param: "mix_3_3"
                            }
                            MixerDial {
                                param: "mix_3_4"
                            }

                        }
                        Column {
                            x: 500
                            y: 5
                            width: 150
                            height: 405
                            spacing: 10
                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("IN 4")
                                font.pixelSize: fontSizeMedium
                            }

                            MixerDial {
                                param: "mix_4_1"
                            }
                            MixerDial {
                                param: "mix_4_2"
                            }
                            MixerDial {
                                param: "mix_4_3"
                            }
                            MixerDial {
                                param: "mix_4_4"
                            }

                        }

                    }

                    Frame {
                        id: bus1
                        width: 800
                        height: 480
                        z: -1

                        Column {
                            id: columnMixer1
                            anchors.fill: parent

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 0.5 * parent.height
                                GroupBox {
                                    id: groupBox3
                                    title: qsTr("Input 1")
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 0.5 * parent.width
                                    PolyBus {
                                        id: polyBus3
                                        availablePorts: system_capture_1AvailablePorts
                                        usedPorts: system_capture_1UsedPorts
                                        sourcePort: "capture_1"
                                        effect: "system"
                                    }
                                }
                                GroupBox {
                                    id: groupBox4
                                    title: qsTr("Input 2")
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 0.5 * parent.width
                                    PolyBus {
                                        id: polyBus4
                                        availablePorts: system_capture_2AvailablePorts
                                        usedPorts: system_capture_2UsedPorts
                                        sourcePort: "capture_2"
                                        effect: "system"
                                    }
                                }
                            }
                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 0.5 * parent.height
                                GroupBox {
                                    title: qsTr("Input 3")
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 0.5 * parent.width
                                    PolyBus {
                                        id: polyBusMix4
                                        availablePorts: system_capture_3AvailablePorts
                                        usedPorts: system_capture_3UsedPorts
                                        sourcePort: "capture_3"
                                        effect: "system"
                                    }
                                }
                                GroupBox {
                                    title: qsTr("Input 4")
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 0.5 * parent.width
                                    PolyBus {
                                        id: polyBusMix5
                                        availablePorts: system_capture_4AvailablePorts
                                        usedPorts: system_capture_4UsedPorts
                                        sourcePort: "capture_4"
                                        effect: "system"
                                    }
                                }
                            }

                        }
                    }

                    currentIndex: delayTabs1.currentIndex
                    anchors.topMargin: 27
                    anchors.fill: parent
                    anchors.rightMargin: 0
                }

                TabBar {
                    id: delayTabs1
                    x: -5
                    y: -5
                    width: 376
                    height: 38
                    currentIndex: 1
                    anchors.bottomMargin: 0
                    spacing: 0
                    TabButton {
                        id: tabButton10
                        text: qsTr("Main")
                    }

                    TabButton {
                        id: tabButton12
                        text: qsTr("Bus")
                    }
                    anchors.bottom: parent.bottom
                }

                Layout.fillHeight: true
            }

            Frame {
                id: cabFrame
                width: 800
                height: 480
                anchors.rightMargin: 0
                anchors.bottomMargin: 0
                anchors.leftMargin: 0
                anchors.topMargin: 0
                contentHeight: 480
                contentWidth: 800
                Label {
                    color: "#ffffff"
                    text: qsTr("CAB")
                    z: 1
                    anchors.fill: parent
                    font.pixelSize: fontSizeMedium * 5
                }
            }

        }

        TabBar {
            id: topLevelBar
            x: 94
            y: 0
            width: 613
            height: 41
            currentIndex: 3

            TabButton {
                id: tabButton
                text: qsTr("Delay")
                onPressAndHold: {
                    knobs.toggle_enabled("delay1")
                }
            }

            TabButton {
                id: tabButton1
                text: qsTr("Reverb")
                onPressAndHold: {
                    knobs.toggle_enabled("reverb")
                }
            }

            TabButton {
                id: tabButton2
                text: qsTr("Mixer")
            }

            TabButton {
                id: tabButton3
                text: qsTr("Cab")
            }
        }

        ProgressBar {
            id: leftEncoderVal
            x: 0
            y: 0
            width: 93
            height: 41
            GlowingLabel {
                color: "#ffffff"
                text: qsTr("SIZE")
                z: 1
                anchors.fill: parent
                font.pixelSize: fontSizeMedium
            }
            // TapHandler {
            //     onTapped: {
            //         // set map encoder on
            //         // python variable in qml context
            //         is_waiting_knob_mapping = "left"
            //     }
            // }
            value: 0.5
        }

        ProgressBar {
            id: rightEncoderVal
            width: 93
            height: 41
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            value: 0.5
            GlowingLabel {
                color: "#ffffff"
                text: qsTr("SIZE")
                z: 1
                font.pixelSize: fontSizeMedium
                anchors.fill: parent
            }
            // TapHandler {
            //     onTapped: {
            //         // set map encoder on
            //         // python variable in qml context
            //         is_waiting_knob_mapping = "right"
            //     }
            // }
        }





    }

}

























/*##^## Designer {
    D{i:213;anchors_height:41;anchors_width:93}D{i:462;anchors_height:41;anchors_width:93}
D{i:461;anchors_y:"-6"}
}
 ##^##*/
