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
    width: 720
    height: 1280
    minimumHeight: 1280
    minimumWidth: 720
    maximumHeight: 1280
    maximumWidth: 720
    visible: true
    title: "DIGIT"
    // width: 1280//Screen.height dev settings
    // height: 720//Screen.width

    Material.theme: Material.Dark
    Material.primary: Material.Green
    Material.accent: Material.Pink
    contentOrientation: Qt.InvertedLandscapeOrientation

    readonly property color colorGlow: "#1d6d64"
    readonly property color colorWarning: "#d5232f"
    readonly property color colorMain: "#6affcd"
    readonly property color colorBright: "#ffffff"
    readonly property color colorLightGrey: "#888"
    readonly property color colorDarkGrey: "#333"

    readonly property int baseFontSize: 20 
    readonly property int tabHeight: 70 
    readonly property int fontSizeExtraSmall: baseFontSize * 0.8
    readonly property int fontSizeMedium: baseFontSize * 1.5
    readonly property int fontSizeLarge: baseFontSize * 2
    readonly property int fontSizeExtraLarge: baseFontSize * 5

    function setColorAlpha(color, alpha) {
        return Qt.hsla(color.hslHue, color.hslSaturation, color.hslLightness, alpha)
    }

    Item {
        transform: Rotation {
            angle: -90
            // origin.x: Screen.height / 2
            // origin.x: Screen.height / 2
            // origin.x: 720 / 2
            // origin.y: 720 / 2
            origin.x: 1280 / 2
            origin.y: 1280 / 2
        }
        id: root
        width: 1280//Screen.height
        height: 720//Screen.width
        Label {
            // width: 1280
            // height: 720
            text: "BYPASSED"
            font.pixelSize: 95
            opacity: 0.4
            color: "grey"
            visible: false // XXX !(pluginState.global.value)
            z: 1
            anchors.centerIn: parent
        }
        
        
        Component {
            id: mainView
            Item {
                width: 1280//Screen.height
                height: 720//Screen.width
            StackLayout {
                id: stackLayout
                currentIndex: topLevelBar.currentIndex
                // currentIndex: topLevelTabs.currentIndex
                anchors.fill: parent

                PolyFrame {
                    Layout.fillWidth: true
                    z: -1
                    StackLayout {
                        id: delayStack1
                        anchors.bottomMargin: 40
                        anchors.rightMargin: 0
                        anchors.topMargin: tabHeight  
                        currentIndex: delayTabs.currentIndex
                        anchors.fill: parent
                        PolyFrame {
                            id: reverbFrame3
                            DelayControl {
                                id: delayControl1
                            }
                        }
                        // PolyFrame {
                        //     id: reverbFrame3
                        //     width: 1280
                        //     height: 720
                        //     z: -1
                        //     Column {
                        //         id: column2
                        //         x: 500
                        //         y: 58
                        //         width: 102
                        //         height: 271
                        //         spacing: 10
                        //         GlowingLabel {
                        //             color: "#ffffff"
                        //             text: "LEVEL"
                        //         }

                        //         MixerDial {
                        //             effect: "delay1"
                        //             param: "carla_level"
                        //             value: polyValues.delay1.carla_level.value
                        //             to: 1
                        //             width: 100
                        //             height: 100
                        //         }
                        //     }

                        //     Column {
                        //         id: column3
                        //         x: 625
                        //         y: 58
                        //         width: 102
                        //         height: 271
                        //         spacing: 10
                        //         GlowingLabel {
                        //             color: "#ffffff"
                        //             text: qsTr("TIME")
                        //         }

                        //         MixerDial {
                        //             effect: "delay1"
                        //             param: "l_delay"
                        //             value: polyValues.delay1.l_delay.value
                        //             textOverride: {
                        //                 if (tempoSynced.delay1.value == 1)
                        //                 {
                        //                     return tempoSynced.delay1.name
                        //                 }
                        //                 else
                        //                 {
                        //                     return polyValues.delay1.l_delay.value.toFixed(1)
                        //                 }

                        //             }
                        //             to: 1
                        //             width: 100
                        //             height: 100
                        //         }

                        //         Switch {
                        //             text: qsTr("SYNC")
                        //             bottomPadding: 0
                        //             width: 100
                        //             leftPadding: 0
                        //             topPadding: 0
                        //             rightPadding: 0
                        //             onClicked: {
                        //                 knobs.toggle_synced("delay1")
                        //             }
                        //         }

                        //         GlowingLabel {
                        //             color: "#ffffff"
                        //             text: "FEEDBACK"
                        //         }

                        //         MixerDial {
                        //             effect: "delay1"
                        //             param: "feedback"
                        //             value: polyValues.delay1.feedback.value
                        //             to: 1
                        //             width: 100
                        //             height: 100
                        //         }

                        //     }
                        // }

                        PolyFrame {
                            id: effects
                            width: 1280
                            height: 350
                            z: -1

                                Column {
                                    spacing: 6
                                    width: parent.width
                                    anchors.fill: parent
                            // ScrollView { 
                            //     // width: parent.width
                                // anchors.fill: parent
                                // clip: true
                                // Layout.fillHeight: true
                                // Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                // Layout.fillWidth: true
                                    GroupBox {
                                        width: parent.width
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        title: qsTr("TAPE / TUBE")
                                        font.pixelSize: baseFontSize

                                        Row {
                                            width: 1280
                                            height: parent.height
                                            anchors.top: parent.top
                                            // anchors.topMargin: 10

                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("DRIVE")
                                            }
                                            MixerDial {
                                                effect: "tape1"
                                                param: "drive"
                                                value: polyValues.tape1.drive.value
                                                to: 10
                                            }
                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("TAPE VS TUBE")
                                            }
                                            MixerDial {
                                                effect: "tape1"
                                                param: "blend"
                                                value: polyValues.tape1.blend.value
                                                from: -10
                                                to: 10
                                            }
                                            Switch {
                                                text: qsTr("ENABLED")
                                                font.pixelSize: baseFontSize
                                                bottomPadding: 0
                                                Layout.fillWidth: true
                                                leftPadding: 0
                                                topPadding: 0
                                                rightPadding: 0
                                                onClicked: {
                                                    knobs.toggle_enabled("tape1")
                                                }
                                            }
                                            spacing: 35
                                        }
                                    }
                                    // GroupBox {
                                    //     width: parent.width
                                    //     anchors.left: parent.left
                                    //     anchors.right: parent.right
                                    //     title: qsTr("LOWPASS FILTER")

                                    //     Row {
                                    //         width: 1280
                                    //         height: parent.height
                                    //         anchors.top: parent.top
                                    //         // anchors.topMargin: 10

                                    //         GlowingLabel {
                                    //             color: "#ffffff"
                                    //             text: qsTr("CUTOFF")
                                    //         }
                                    //         MixerDial {
                                    //             effect: "filter1"
                                    //             param: "freq"
                                    //             value: polyValues.filter1.freq.value
                                    //             from: 20
                                    //             to: 20000
                                    //             stepSize: 10
                                    //         }
                                    //         GlowingLabel {
                                    //             color: "#ffffff"
                                    //             text: qsTr("RESONANCE")
                                    //         }
                                    //         MixerDial {
                                    //             effect: "filter1"
                                    //             param: "res"
                                    //             value: polyValues.filter1.res.value
                                    //             from: 0
                                    //             to: 0.8
                                    //         }
                                    //         Switch {
                                    //             text: qsTr("ENABLED")
                                    //             onClicked: {
                                    //                 knobs.toggle_enabled("filter1")
                                    //             }
                                    //             bottomPadding: 0
                                    //             Layout.fillWidth: true
                                    //             leftPadding: 0
                                    //             topPadding: 0
                                    //             rightPadding: 0
                                    //         }
                                    //         spacing: 35
                                    //     }
                                    // }

                                    GroupBox {
                                        width: parent.width
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        title: qsTr("COMPRESSION BOOST")
                                        font.pixelSize: baseFontSize

                                        Row {
                                            width: 1280
                                            height: parent.height
                                            anchors.top: parent.top
                                            // anchors.topMargin: 10

                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("PRE GAIN")
                                            }
                                            MixerDial {
                                                effect: "sigmoid1"
                                                param: "Pregain"
                                                value: polyValues.sigmoid1.Pregain.value
                                                from: -90
                                                to: 20
                                            }
                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("POST GAIN")
                                            }
                                            MixerDial {
                                                effect: "sigmoid1"
                                                param: "Postgain"
                                                value: polyValues.sigmoid1.Postgain.value
                                                from: -90
                                                to: 20
                                            }
                                            Switch {
                                                text: qsTr("ENABLED")
                                                font.pixelSize: baseFontSize
                                                onClicked: {
                                                    knobs.toggle_enabled("sigmoid1")
                                                }
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
                                        title: qsTr("REVERSE")
                                        font.pixelSize: baseFontSize

                                        Row {
                                            width: 1280
                                            height: parent.height
                                            anchors.top: parent.top
                                            // anchors.topMargin: 10

                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("FRAGMENT")
                                            }
                                            MixerDial {
                                                effect: "reverse1"
                                                param: "fragment"
                                                value: polyValues.reverse1.fragment.value
                                                from: 100
                                                to: 1600
                                            }
                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("WET")
                                            }
                                            MixerDial {
                                                effect: "reverse1"
                                                param: "wet"
                                                value: polyValues.reverse1.wet.value
                                                from: -90
                                                to: 20
                                            }
                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("DRY")
                                            }
                                            MixerDial {
                                                effect: "reverse1"
                                                param: "dry"
                                                value: polyValues.reverse1.dry.value
                                                from: -90
                                                to: 20
                                            }
                                            Switch {
                                                text: qsTr("ENABLED")
                                                font.pixelSize: baseFontSize
                                                bottomPadding: 0
                                                Layout.fillWidth: true
                                                leftPadding: 0
                                                topPadding: 0
                                                rightPadding: 0
                                                onClicked: {
                                                    knobs.toggle_enabled("reverse1")
                                                }
                                            }
                                            spacing: 35
                                        }
                                    }
                                // }
                            }
                        }

                        PolyFrame {
                            id: bus
                            width: parent.width
                            height:parent.height
                            z: -1

                            PolyBus {
                                id: polyBus
                                width: 1280
                                height: 394
                                availablePorts: sigmoid1_OutputAvailablePorts
                                usedPorts: sigmoid1_OutputUsedPorts
                                effect: "sigmoid1"
                                sourcePort: "Output"
                                // availablePorts: delay1_Left_OutAvailablePorts
                                // usedPorts: delay1_Left_OutUsedPorts
                                // effect: "delay1"
                                // sourcePort: "Left Out"
                            }
                        }
                    }

                    TabBar {
                        id: delayTabs
                        width: 376
                        spacing: 0
                        currentIndex: 1
                        anchors.bottom: parent.bottom
                        TabButton {
                            id: tabButton7
                            text: qsTr("MAIN")
                            font.pixelSize: baseFontSize
                        }

                        TabButton {
                            id: tabButton8
                            text: qsTr("EFFECTS")
                            font.pixelSize: baseFontSize
                        }

                        TabButton {
                            id: tabButton9
                            text: qsTr("BUS")
                            font.pixelSize: baseFontSize
                        }
                        anchors.bottomMargin: 0
                    }
                    Layout.fillHeight: true
                }

                PolyFrame {
                    id: reverbFrame1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    z: -1

                    StackLayout {
                        anchors.fill: parent
                        currentIndex: reverbTabs.currentIndex
                        anchors.bottomMargin: 40
                        anchors.rightMargin: 0
                        anchors.topMargin: tabHeight


                        PolyFrame {
                            id: reverbFrame
                            width: 1280
                            height: 720
                            z: -1


                            ColumnLayout {
                                x: 50
                                y: 25
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                FolderBrowser {
                                    x: 0
                                    // Layout.fillHeight: true
                                    height: 400
                                    width: 300
                                    current_selected: polyValues.reverb.ir.name
                                    top_folder: "file:///audio/reverbs/"
                                    after_file_selected: (function(name) { 
                                        console.log("got new reveb file");
                                        // update that we're setting reverb
                                        // cause file callback
                                        console.log("file  is", name.toString());
                                        knobs.update_ir(true, name.toString());
                                        // some way to handle errors also needed
                                    })
                                }
                                // Image {
                                //     x: 0
                                //     Layout.fillHeight: false
                                //     // source: "qrc:/icons/reverb_cube.png"
                                //     source: "qrc:/icons/reverb_plate.png"
                                //     // source: "qrc:/icons/reverb_spring.png"
                                //     fillMode: Image.PreserveAspectFit
                                // }
                                Layout.preferredWidth: 350
                            }

                            EQWidget {
                                x: 350
                            }


                            // Column {
                            //     id: column1
                            //     x: 1000
                            //     y: 66
                            //     width: 102
                            //     height: 271
                            //     spacing: 10
                            //     GlowingLabel {
                            //         color: "#ffffff"
                            //         text: qsTr("MIX")
                            //     }

                            //     MixerDial {
                            //         effect: "reverb"
                            //         param: "dry_wet"
                            //         value: polyValues.reverb.dry_wet.value
                            //         to: 100
                            //         width: 100
                            //         height: 100
                            //     }

                            //     GlowingLabel {
                            //         color: "#ffffff"
                            //         text: qsTr("TONE")
                            //     }

                            //     MixerDial {
                            //         effect: "reverb"
                            //         param: "roomsize"
                            //         value: polyValues.reverb.roomsize.value
                            //         to: 1
                            //         width: 100
                            //         height: 100
                            //     }
                            // }
                        }

                        PolyFrame {
                            id: reverb_effects
                            width: 1280
                            height: 350
                            z: -1

                                Column {
                                    spacing: 6
                                    width: parent.width
                                    anchors.fill: parent
                            // ScrollView { 
                            //     // width: parent.width
                                // anchors.fill: parent
                                // clip: true
                                // Layout.fillHeight: true
                                // Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                                // Layout.fillWidth: true
                                    GroupBox {
                                        width: parent.width
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        title: qsTr("LOWPASS FILTER")
                                        font.pixelSize: baseFontSize

                                        Row {
                                            width: 1280
                                            height: parent.height
                                            anchors.top: parent.top
                                            // anchors.topMargin: 10

                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("CUTOFF")
                                            }
                                            MixerDial {
                                                effect: "filter1"
                                                param: "freq"
                                                value: polyValues.filter1.freq.value
                                                from: 20
                                                to: 20000
                                                stepSize: 10
                                            }
                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("RESONANCE")
                                            }
                                            MixerDial {
                                                effect: "filter1"
                                                param: "res"
                                                value: polyValues.filter1.res.value
                                                from: 0
                                                to: 0.8
                                            }
                                            Switch {
                                                text: qsTr("ENABLED")
                                                font.pixelSize: baseFontSize
                                                onClicked: {
                                                    knobs.toggle_enabled("filter1")
                                                }
                                                bottomPadding: 0
                                                Layout.fillWidth: true
                                                leftPadding: 0
                                                topPadding: 0
                                                rightPadding: 0
                                                font {
                                                    pixelSize: fontSizeMedium
                                                }
                                            }
                                            spacing: 35
                                        }
                                    }

                                    GroupBox {
                                        width: parent.width
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        title: qsTr("REVERSE")
                                        font.pixelSize: baseFontSize

                                        Row {
                                            width: 1280
                                            height: parent.height
                                            anchors.top: parent.top
                                            // anchors.topMargin: 10

                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("FRAGMENT")
                                            }
                                            MixerDial {
                                                effect: "reverse2"
                                                param: "fragment"
                                                value: polyValues.reverse2.fragment.value
                                                from: 100
                                                to: 1600
                                            }
                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("WET")
                                            }
                                            MixerDial {
                                                effect: "reverse2"
                                                param: "wet"
                                                value: polyValues.reverse2.wet.value
                                                from: -90
                                                to: 20
                                            }
                                            GlowingLabel {
                                                color: "#ffffff"
                                                text: qsTr("DRY")
                                            }
                                            MixerDial {
                                                effect: "reverse2"
                                                param: "dry"
                                                value: polyValues.reverse2.dry.value
                                                from: -90
                                                to: 20
                                            }
                                            Switch {
                                                text: qsTr("ENABLED")
                                                font.pixelSize: baseFontSize
                                                bottomPadding: 0
                                                Layout.fillWidth: true
                                                leftPadding: 0
                                                topPadding: 0
                                                rightPadding: 0
                                                onClicked: {
                                                    knobs.toggle_enabled("reverse2")
                                                }
                                                font {
                                                    pixelSize: fontSizeMedium
                                                }
                                            }
                                            spacing: 35
                                        }
                                    }
                                // }
                            }
                        }
                        PolyFrame {
                            id: bus2
                            width: 1280
                            height: 720

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: parent.height
                                GroupBox {
                                    title: qsTr("LEFT")
                                    font.pixelSize: baseFontSize
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 0.5 * parent.width
                                    PolyBus {
                                        id: polyBusRL
                                        availablePorts: reverb_OutLAvailablePorts
                                        usedPorts: reverb_OutLUsedPorts
                                        effect: "reverb"
                                        sourcePort: "OutL"
                                    }
                                }
                                GroupBox {
                                    title: qsTr("RIGHT")
                                    font.pixelSize: baseFontSize
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 0.5 * parent.width
                                    PolyBus {
                                        id: polyBusRR
                                        availablePorts: reverb_OutRAvailablePorts
                                        usedPorts: reverb_OutRUsedPorts
                                        effect: "reverb"
                                        sourcePort: "OutR"
                                    }
                                }
                            }
                            z: -1
                        }
                    }

                    TabBar {
                        id: reverbTabs
                        width: 376
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        TabButton {
                            id: tabButton4
                            text: qsTr("MAIN")
                            font.pixelSize: baseFontSize
                        }

                        TabButton {
                            id: tabButton5
                            font.pixelSize: baseFontSize
                            text: qsTr("EFFECTS")
                        }

                        TabButton {
                            font.pixelSize: baseFontSize
                            id: tabButton6
                            text: qsTr("BUS")
                        }
                    }
                }

                PolyFrame {
                    id: mixerFrame
                    z: -1
                    Layout.fillWidth: true

                    StackLayout {
                        id: delayStack2
                        anchors.bottomMargin: 36
                        anchors.rightMargin: -12
                        anchors.topMargin: tabHeight
                        anchors.fill: parent

                        PolyFrame {
                            id: reverbFrame4
                            width: 1280
                            height: 439
                            z: -1
                            Column {
                                id: column
                                x: 400
                                y: 12
                                width: 150
                                height: 405
                                spacing: 30
                                GlowingLabel {
                                    color: "#ffffff"
                                    text: qsTr("IN 1")
                                    anchors.horizontalCenter: mixerDial.horizontalCenter

                                }

                                MixerDial {
                                    id: mixerDial
                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("OUT 1")
                                        anchors.left: parent.left
                                        anchors.leftMargin: -115
                                        anchors.top: parent.verticalCenter
                                        anchors.topMargin: -25
                                    }
                                    param: "mix_1_1"
                                }
                                MixerDial {
                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("OUT 1")
                                        anchors.left: parent.left
                                        anchors.leftMargin: -115
                                        anchors.top: parent.verticalCenter
                                        anchors.topMargin: -25
                                    }
                                    param: "mix_1_2"
                                }
                                MixerDial {
                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("OUT 1")
                                        anchors.left: parent.left
                                        anchors.leftMargin: -115
                                        anchors.top: parent.verticalCenter
                                        anchors.topMargin: -25
                                    }
                                    param: "mix_1_3"
                                }
                                MixerDial {
                                    GlowingLabel {
                                        color: "#ffffff"
                                        text: qsTr("OUT 1")
                                        anchors.left: parent.left
                                        anchors.leftMargin: -115
                                        anchors.top: parent.verticalCenter
                                        anchors.topMargin: -25
                                    }
                                    param: "mix_1_4"
                                }

                            }
                            Column {
                                x: 550
                                y: 12
                                width: 150
                                height: 405
                                spacing: 30
                                GlowingLabel {
                                    color: "#ffffff"
                                    text: qsTr("IN 2")
                                    anchors.horizontalCenter: mixerDial2.horizontalCenter
                                }

                                MixerDial {
                                    id: mixerDial2
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
                                x: 700
                                y: 12
                                width: 150
                                height: 405
                                spacing: 30
                                GlowingLabel {
                                    color: "#ffffff"
                                    text: qsTr("IN 3")
                                    anchors.horizontalCenter: mixerDial3.horizontalCenter
                                }

                                MixerDial {
                                    id: mixerDial3
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
                                x: 850
                                y: 12
                                width: 150
                                height: 405
                                spacing: 30
                                GlowingLabel {
                                    color: "#ffffff"
                                    text: qsTr("IN 4")
                                    anchors.horizontalCenter: mixerDial4.horizontalCenter
                                }

                                MixerDial {
                                    id: mixerDial4
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

                        PolyFrame {
                            id: bus1
                            width: 1280
                            height: 474
                            z: -1

                            Column {
                                id: columnMixer1
                                height: 360
                                anchors.fill: parent

                                Row {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 0.5 * parent.height
                                    GroupBox {
                                        id: groupBox3
                                        title: qsTr("INPUT 1")
                                        font.pixelSize: baseFontSize
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 0.5 * parent.width
                                        background: null
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
                                        title: qsTr("INPUT 2")
                                        font.pixelSize: baseFontSize
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 0.5 * parent.width
                                        background: null
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
                                        title: qsTr("INPUT 3")
                                        font.pixelSize: baseFontSize
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 0.5 * parent.width
                                        background: null
                                        PolyBus {
                                            id: polyBusMix4
                                            availablePorts: system_capture_3AvailablePorts
                                            usedPorts: system_capture_3UsedPorts
                                            sourcePort: "capture_3"
                                            effect: "system"
                                        }
                                    }
                                    GroupBox {
                                        title: qsTr("INPUT 4")
                                        font.pixelSize: baseFontSize
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: 0.5 * parent.width
                                        background: null
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
                    }

                    TabBar {
                        id: delayTabs1
                        x: -5
                        y: -5
                        width: 376
                        currentIndex: 1
                        anchors.bottomMargin: 0
                        spacing: 0
                        TabButton {
                            id: tabButton10
                            text: qsTr("MAIN")
                            font.pixelSize: baseFontSize
                        }

                        TabButton {
                            id: tabButton12
                            text: qsTr("BUS")
                            font.pixelSize: baseFontSize
                        }
                        anchors.bottom: parent.bottom
                    }

                    Layout.fillHeight: true
                }

                PolyFrame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    z: -1

                    StackLayout {
                        currentIndex: cabTabs.currentIndex
                        anchors.bottomMargin: 40
                        anchors.rightMargin: 0
                        anchors.topMargin: tabHeight
                        anchors.fill: parent


                        PolyFrame {
                            width: 1280
                            // height: 720
                            height: 720
                            z: -1


                            FolderBrowser {
                                x: 191
                                y: 0
                                // Layout.fillHeight: true
                                height: 500
                                width: 500
                                current_selected: polyValues.cab.ir.name
                                top_folder: "file:///audio/cabs/"
                                after_file_selected: (function(name) { 
                                    console.log("got new cab file");
                                    // update that we're setting reverb
                                    // cause file callback
                                    console.log("file is", name.toString());
                                    knobs.update_ir(false, name.toString()); // false is set cab
                                    // some way to handle errors also needed
                                })
                            }
                            // Column {
                            //     x: 625
                            //     y: 66
                            //     width: 102
                            //     height: 271
                            //     spacing: 10
                            //     GlowingLabel {
                            //         color: "#ffffff"
                            //         text: qsTr("TREBLE")
                            //     }

                            //     MixerDial {
                            //         effect: "cab"
                            //         param: "CTreble"
                            //         value: polyValues.cab.CTreble.value
                            //         from: -10
                            //         to: 10
                            //         width: 100
                            //         height: 100
                            //     }

                            //     GlowingLabel {
                            //         color: "#ffffff"
                            //         text: qsTr("BASS")
                            //     }

                            //     MixerDial {
                            //         effect: "cab"
                            //         param: "CBass"
                            //         value: polyValues.cab.CBass.value
                            //         from: -10
                            //         to: 10
                            //         width: 100
                            //         height: 100
                            //     }
                            // }
                        }

                        PolyFrame {
                            width: parent.width
                            height:parent.height
                            // width: parent.width
                            PolyBus {
                                availablePorts: cab_OutAvailablePorts
                                usedPorts: cab_OutUsedPorts
                                effect: "cab"
                                sourcePort: "Out"
                            }
                            z: -1
                        }
                    }

                    TabBar {
                        id: cabTabs
                        width: 376
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        TabButton {
                            text: qsTr("MAIN")
                            font.pixelSize: baseFontSize
                        }

                        TabButton {
                            font.pixelSize: baseFontSize
                            text: qsTr("BUS")
                        }
                    }
                }

                PolyFrame {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    z: -1

                    StackLayout {
                        currentIndex: modTabs.currentIndex
                        anchors.bottomMargin: 40
                        anchors.rightMargin: 0
                        anchors.topMargin: tabHeight
                        anchors.fill: parent


                        PolyFrame {
                            width: 1280
                            // height: 720
                            height: 720
                            z: -1


                            LFOControl {
                                x: 10
                                y: -10
                                effect: "lfo1"
                            }
                        }
                        PolyFrame {
                            width: 1280
                            // height: 720
                            height: 720
                            z: -1


                            LFOControl {
                                x: 10
                                y: -10
                                effect: "lfo2"
                            }
                        }
                        PolyFrame {
                            width: 1280
                            // height: 720
                            height: 720
                            z: -1


                            LFOControl {
                                x: 10
                                y: -10
                                effect: "lfo3"
                            }
                        }
                        PolyFrame {
                            width: 1280
                            // height: 720
                            height: 720
                            z: -1


                            LFOControl {
                                x: 10
                                y: -10
                                effect: "lfo4"
                            }
                        }
                        PolyFrame {
                        }
                        PolyFrame {
                        }

                    }

                    TabBar {
                        id: modTabs
                        width: 476
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 0
                        TabButton {
                            text: qsTr("LFO1")
                            font.pixelSize: baseFontSize
                        }
                        TabButton {
                            text: qsTr("LFO2")
                            font.pixelSize: baseFontSize
                        }
                        TabButton {
                            text: qsTr("LFO3")
                            font.pixelSize: baseFontSize
                        }
                        TabButton {
                            text: qsTr("LFO4")
                            font.pixelSize: baseFontSize
                        }
                        TabButton {
                            text: qsTr("ENV1")
                            font.pixelSize: baseFontSize
                        }
                        TabButton {
                            text: qsTr("ENV2")
                            font.pixelSize: baseFontSize
                        }
                    }
                }

            }

            TabBar {
                id: topLevelBar
                x: 240
                y: 0
                width: 800
                currentIndex: 2

                TabButton {
                    Material.foreground: pluginState.delay1.value ? Material.color(Material.Indigo, Material.Shade200) : Material.Grey
                    Material.accent: pluginState.delay1.value ? Material.color(Material.Indigo, Material.Shade200) : Material.Grey
                    id: tabButton
                    // height: parent.height
                    text: qsTr("DELAY")
                    font.pixelSize: fontSizeMedium
                    // color:
                    onPressAndHold: {
                        knobs.toggle_enabled("delay1")
                    }
                }

                TabButton {
                    Material.foreground: pluginState.reverb.value ? Material.color(Material.Indigo, Material.Shade200) : Material.Grey
                    Material.accent: pluginState.reverb.value ? Material.color(Material.Indigo, Material.Shade200) : Material.Grey
                    id: tabButton1
                    text: qsTr("REVERB")
                    font.pixelSize: fontSizeMedium
                    // color: pluginState.reverb ? Material.Green : Material.Grey
                    onPressAndHold: {
                        knobs.toggle_enabled("reverb")
                    }
                }

                TabButton {
                    // Material.foreground: pluginState.mixer.value ? Material.LightGreen : Material.Grey
                    // Material.accent: pluginState.mixer.value ? Material.lightGreen : Material.Grey
                    Material.foreground: Material.color(Material.Indigo, Material.Shade200)
                    Material.accent: Material.color(Material.Indigo, Material.Shade200)
                    id: tabButton2
                    // color: pluginState.mixer ? Material.Green : Material.Grey
                    font.pixelSize: fontSizeMedium
                    text: qsTr("MIXER")
                }

                TabButton {
                    Material.foreground: pluginState.cab.value ? Material.color(Material.Indigo, Material.Shade200) : Material.Grey
                    Material.accent: pluginState.cab.value ? Material.color(Material.Indigo, Material.Shade200) : Material.Grey
                    id: tabButton3
                    font.pixelSize: fontSizeMedium
                    // color: pluginState.cab ? Material.Green : Material.Grey
                    text: qsTr("CAB")
                    onPressAndHold: {
                        knobs.toggle_enabled("cab")
                    }
                }
                TabButton {
                    // Material.foreground: pluginState.cab.value ? Material.LightGreen : Material.Grey
                    // Material.accent: pluginState.cab.value ? Material.lightGreen : Material.Grey
                    // color: pluginState.cab ? Material.Green : Material.Grey
                    font.pixelSize: fontSizeMedium
                    text: qsTr("MODIFY")
                    // onPressAndHold: {
                    //     knobs.toggle_enabled("cab")
                    // }
                }
            }
            Label {
                // color: "#ffffff"
                text: currentPreset.name
                elide: Text.ElideRight
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 25 
                horizontalAlignment: Text.AlignRight
                anchors.rightMargin: 190
                anchors.right: parent.right
                width: 310
                height: 41
                // horizontalAlignment: Text.AlignLeft
                z: 1
                font {
                    pixelSize: fontSizeLarge
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        mainStack.push("PresetSave.qml")
                    }
                }
            }

            ProgressBar {
                id: leftEncoderVal
                x: 0
                y: 0
                width: 200
                height: 70
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // set map encoder on
                        // python variable in qml context
                        console.warn("waiting for knob mapping")
                        knobs.set_waiting("left")
                    }
                }
                from: polyValues[knobMap.left.effect][knobMap.left.parameter].rmin
                to: polyValues[knobMap.left.effect][knobMap.left.parameter].rmax
                value: polyValues[knobMap.left.effect][knobMap.left.parameter].value
                background: Rectangle {
                    // implicitWidth: 200
                    // implicitHeight: 6
                    // color: "#22e6e6e6"
                    color: "#00222222"
                    border {
                        // color: Material.color(Material.Grey, Material.Shade200);
                        color: "#666666"
                        width: 1
                    }
                }
                contentItem: Item {
                    implicitWidth: parent.width
                    implicitHeight: parent.height
                    // width: parent.width
                    // height: parent.height
                    Rectangle {
                        width: leftEncoderVal.visualPosition * parent.width
                        height: parent.height
                        // radius: 2
                        color: setColorAlpha(Material.color(Material.Pink, Material.Shade200), 0.5)
                        border {
                            color: Material.color(Material.Pink, Material.Shade200);
                            width: 1
                        }
                    }
                }
            }
            GlowingLabel {
                elide: Text.ElideRight
                color: "#ffffff"
                text: polyValues[knobMap.left.effect][knobMap.left.parameter].name
                x: 5
                y: 5
                width: 200
                height: 41
                horizontalAlignment: Text.AlignLeft
                z: 1
                font {
                    pixelSize: fontSizeLarge
                }
            }

            ProgressBar {
                id: rightEncoderVal
                width: 200
                height: 70
                anchors.top: parent.top
                anchors.topMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 0
                from: polyValues[knobMap.right.effect][knobMap.right.parameter].rmin
                to: polyValues[knobMap.right.effect][knobMap.right.parameter].rmax
                value: polyValues[knobMap.right.effect][knobMap.right.parameter].value
                // from: 0
                // to: 1
                // value: 0.7
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // set map encoder on
                        // python variable in qml context
                        console.warn("waiting for knob mapping")
                        knobs.set_waiting("right")
                    }
                }
                background: Rectangle {
                    // implicitWidth: 200
                    // implicitHeight: 6
                    // color: "#22e6e6e6"
                    color: "#00222222"
                    border {
                        // color: Material.color(Material.Grey, Material.Shade200);
                        color: "#666666"
                        width: 1
                    }
                }
                contentItem: Item {
                    implicitWidth: parent.width
                    implicitHeight: parent.height
                    // width: parent.width
                    // height: parent.height
                    Rectangle {
                        width: rightEncoderVal.visualPosition * parent.width
                        height: parent.height
                        // radius: 2
                        color: setColorAlpha(Material.color(Material.Pink, Material.Shade200), 0.5)
                        border {
                            color: Material.color(Material.Pink, Material.Shade200);
                            width: 1
                        }
                    }
                }
            }
            GlowingLabel {
                elide: Text.ElideRight
                color: "#ffffff"
                text: polyValues[knobMap.right.effect][knobMap.right.parameter].name
                horizontalAlignment: Text.AlignRight
                width: 200
                height: 41
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.topMargin: 5
                z: 1
                font {
                    pixelSize: fontSizeLarge
                }
            }
            Button {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: 100
                anchors.bottomMargin: 2
                icon.width: 70
                icon.height: 70
                width: 70
                height: 70
                flat: true
                icon.name: "settings"
            }


            RectangleLoader { 
                width:70
                height: 70
                x: 650
                y: -6
                // width: 145
                // height: 35
                // text: currentBPM.value.toFixed(0) + " BPM"
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 0
                // horizontalAlignment: Text.AlignRight
                anchors.rightMargin: 5
                anchors.right: parent.right
                beat_msec: 60 / currentBPM.value * 1000
                // color: Material.color(Material.accent, Material.Shade200)
            }
            GlowingLabel {
            //     SequentialAnimation on color {
            //         id: anim
            //         // loops: Animation.Infinite
            //         ColorAnimation { to: "white";
            //             duration: (60.0 / currentBPM.value) * 500.0
            //             // onDurationChanged: {
            //             //     anim.restart()
            //             // }
            //         }
            //         ColorAnimation { to: "green";
            //             duration: (60.0 / currentBPM.value) * 500.0
            //             // onDurationChanged: {
            //             //     anim.restart()
            //             // }
            //         }
            //         onStopped: { anim.restart (); }
            //     }
            //     // onTextChanged: {
            //     //     anim.restart()
            //     // }

                // x: 600
                // y: -28
                width: 145
                height: 35
                color: "#EEEEEE"//..Material.color(Material.Grey)
                text: currentBPM.value.toFixed(0) // + " BPM"
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30 
                horizontalAlignment: Text.AlignRight
                anchors.rightMargin: 15
                anchors.right: parent.right
                font {
                    pixelSize: fontSizeLarge
                }
                z: 1
            }
        }
    }

    StackView {
        id: mainStack
        initialItem: mainView
    }
} 
}































/*##^## Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
 ##^##*/
