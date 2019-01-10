/* DIGIT UI ****************************************************************************/

//import QtQuick 2.12
//import QtQuick.Layouts 1.12
//import QtQuick.Controls 2.12
//import QtQuick.Controls.Imagine 2.12
//import QtQuick.Window 2.0
import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import QtQuick.Controls.Imagine 2.3
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
        //     angle: 90
        //     /* origin.x: Screen.height / 2 */
        //     /* origin.x: Screen.height / 2 */
        //     origin.x: 480 / 2
        //     origin.y: 480 / 2
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

                            Dial {
                                id: mixDial1
                                width: 100
                                height: 100
                                Layout.preferredHeight: 128
                                Layout.alignment: Qt.AlignHCenter
                                Label {
                                    color: "#ffffff"
                                    text: mixDial1.value.toFixed(0)
                                    font.pixelSize: Qt.application.font.pixelSize * 3
                                    anchors.centerIn: parent
                                }
                                Layout.maximumHeight: 128
                                value: 42
                                stepSize: 1
                                to: 100
                                Layout.preferredWidth: 128
                                from: 0
                                Layout.maximumWidth: 128
                                Layout.minimumHeight: 64
                                Layout.fillHeight: true
                                Layout.minimumWidth: 64
                            }

                            GlowingLabel {
                                color: "#ffffff"
                                text: "FEEDBACK"
                                font.pixelSize: fontSizeMedium
                            }

                            Dial {
                                id: sizeDial1
                                width: 100
                                height: 100
                                Layout.preferredHeight: 128
                                Layout.alignment: Qt.AlignHCenter
                                onMoved: {
                                    knobs.ui_knob_change("feedback", sizeDial1.value)
                                }
                                value: 42
                                Layout.maximumHeight: 128
                                Layout.preferredWidth: 128
                                stepSize: 1
                                to: 100
                                from: 0
                                Layout.maximumWidth: 128
                                Layout.minimumHeight: 64
                                Layout.fillHeight: true
                                Layout.minimumWidth: 64

                                Label {
                                    x: 33
                                    y: 8
                                    color: "#ffffff"
                                    text: sizeDial1.value.toFixed(0)

                                    font.pixelSize: Qt.application.font.pixelSize * 3
                                    anchors.centerIn: parent
                                }
                            }



                        }
                    }
                }

                TabBar {
                    id: delayTabs
                    width: 376
                    height: 38
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

                ProgressBar {
                    id: leftEncoderVal1
                    x: -12
                    y: -12
                    width: 93
                    height: 41
                    GlowingLabel {
                        width: 93
                        height: 41
                        color: "#ffffff"
                        text: qsTr("SIZE")
                        font.pixelSize: fontSizeMedium
                    }
                    value: 0.5
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


                    Frame {
                        id: reverbFrame
                        width: 800
                        height: 480
                        z: -1

                        Column {
                            id: column
                            x: -12
                            y: 168
                            width: 120
                            height: 258

                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("SIZE")
                                font.pixelSize: fontSizeMedium
                            }

                            Dial {
                                id: sizeDial
                                width: 100
                                height: 100
                                from: 0
                                value: 42
                                Layout.minimumHeight: 64
                                Layout.preferredWidth: 128
                                Layout.minimumWidth: 64
                                stepSize: 1
                                Layout.preferredHeight: 128
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignHCenter
                                to: 100
                                Layout.maximumWidth: 128
                                Layout.maximumHeight: 128
                                Label {
                                    color: "#ffffff"
                                    text: sizeDial.value.toFixed(0)
                                    font.pixelSize: Qt.application.font.pixelSize * 3
                                    anchors.centerIn: parent
                                }
                            }
                        }


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
                            x: 662
                            y: 168
                            width: 102
                            height: 271
                            GlowingLabel {
                                color: "#ffffff"
                                text: qsTr("MIX")
                                font.pixelSize: fontSizeMedium
                            }

                            Dial {
                                id: mixDial
                                width: 100
                                height: 100
                                stepSize: 1
                                Layout.fillHeight: true
                                from: 0
                                Layout.maximumHeight: 128
                                Layout.preferredHeight: 128
                                to: 100
                                Label {
                                    color: "#ffffff"
                                    text: mixDial.value.toFixed(0)
                                    font.pixelSize: Qt.application.font.pixelSize * 3
                                    anchors.centerIn: parent
                                }
                                Layout.minimumWidth: 64
                                Layout.alignment: Qt.AlignHCenter
                                value: 42
                                Layout.minimumHeight: 64
                                Layout.maximumWidth: 128
                                Layout.preferredWidth: 128
                            }
                        }
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

                ProgressBar {
                    id: leftEncoderVal
                    x: -12
                    y: -12
                    width: 93
                    height: 41
                    value: 0.5

                    GlowingLabel {
                        width: 93
                        height: 41
                        color: "#ffffff"
                        text: qsTr("SIZE")
                        font.pixelSize: fontSizeMedium
                    }
                }
            }

            Frame {
                id: mixerFrame
                z: -1
                Layout.fillWidth: true

                Frame {
                    id: reverbFrame4
                    x: 0
                    y: 41
                    width: 800
                    height: 439
                    z: -1
                    Column {
                        id: column4
                        x: 97
                        y: 36
                        width: 131
                        height: 409
                        GlowingLabel {
                            color: "#ffffff"
                            text: qsTr("IN 1")
                            font.pixelSize: fontSizeMedium
                        }

                        Dial {
                            id: sizeDial2
                            width: 100
                            height: 100
                            from: 0
                            Label {
                                color: "#ffffff"
                                text: sizeDial2.value.toFixed(0)
                                font.pixelSize: Qt.application.font.pixelSize * 3
                                anchors.centerIn: parent
                            }
                            Layout.minimumHeight: 64
                            value: 42
                            Layout.minimumWidth: 64
                            Layout.maximumHeight: 128
                            Layout.fillHeight: true
                            Layout.preferredWidth: 128
                            stepSize: 1
                            to: 100
                            Layout.preferredHeight: 128
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 128
                        }

                        Dial {
                            id: sizeDial3
                            width: 100
                            height: 100
                            from: 0
                            Label {
                                color: "#ffffff"
                                text: sizeDial3.value.toFixed(0)
                                font.pixelSize: Qt.application.font.pixelSize * 3
                                anchors.centerIn: parent
                            }
                            Layout.minimumHeight: 64
                            value: 42
                            Layout.minimumWidth: 64
                            Layout.maximumHeight: 128
                            Layout.fillHeight: true
                            to: 100
                            stepSize: 1
                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 128
                            Layout.maximumWidth: 128
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Dial {
                            id: sizeDial4
                            width: 100
                            height: 100
                            from: 0
                            Label {
                                color: "#ffffff"
                                text: sizeDial4.value.toFixed(0)
                                font.pixelSize: Qt.application.font.pixelSize * 3
                                anchors.centerIn: parent
                            }
                            Layout.minimumHeight: 64
                            value: 42
                            Layout.minimumWidth: 64
                            Layout.maximumHeight: 128
                            Layout.fillHeight: true
                            to: 100
                            stepSize: 1
                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 128
                            Layout.maximumWidth: 128
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Dial {
                            id: sizeDial5
                            width: 100
                            height: 100
                            from: 0
                            Label {
                                color: "#ffffff"
                                text: sizeDial5.value.toFixed(0)
                                font.pixelSize: Qt.application.font.pixelSize * 3
                                anchors.centerIn: parent
                            }
                            Layout.minimumHeight: 64
                            value: 42
                            Layout.minimumWidth: 64
                            Layout.maximumHeight: 128
                            Layout.fillHeight: true
                            to: 100
                            stepSize: 1
                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 128
                            Layout.maximumWidth: 128
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    Column {
                        id: column5
                        x: 295
                        y: 36
                        width: 131
                        height: 409
                        GlowingLabel {
                            color: "#ffffff"
                            text: qsTr("IN 1")
                            font.pixelSize: fontSizeMedium
                        }

                        Dial {
                            id: sizeDial6
                            width: 100
                            height: 100
                            from: 0
                            Label {
                                color: "#ffffff"
                                text: sizeDial6.value.toFixed(0)
                                font.pixelSize: Qt.application.font.pixelSize * 3
                                anchors.centerIn: parent
                            }
                            Layout.minimumHeight: 64
                            value: 42
                            Layout.minimumWidth: 64
                            Layout.maximumHeight: 128
                            Layout.fillHeight: true
                            to: 100
                            stepSize: 1
                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 128
                            Layout.maximumWidth: 128
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Dial {
                            id: sizeDial7
                            width: 100
                            height: 100
                            from: 0
                            Label {
                                color: "#ffffff"
                                text: sizeDial7.value.toFixed(0)
                                font.pixelSize: Qt.application.font.pixelSize * 3
                                anchors.centerIn: parent
                            }
                            Layout.minimumHeight: 64
                            value: 42
                            Layout.minimumWidth: 64
                            Layout.maximumHeight: 128
                            Layout.fillHeight: true
                            Layout.preferredWidth: 128
                            stepSize: 1
                            to: 100
                            Layout.preferredHeight: 128
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 128
                        }

                        Dial {
                            id: sizeDial8
                            width: 100
                            height: 100
                            from: 0
                            Label {
                                color: "#ffffff"
                                text: sizeDial8.value.toFixed(0)
                                font.pixelSize: Qt.application.font.pixelSize * 3
                                anchors.centerIn: parent
                            }
                            Layout.minimumHeight: 64
                            value: 42
                            Layout.minimumWidth: 64
                            Layout.maximumHeight: 128
                            Layout.fillHeight: true
                            Layout.preferredWidth: 128
                            stepSize: 1
                            to: 100
                            Layout.preferredHeight: 128
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 128
                        }

                        Dial {
                            id: sizeDial9
                            width: 100
                            height: 100
                            from: 0
                            Label {
                                color: "#ffffff"
                                text: sizeDial9.value.toFixed(0)
                                font.pixelSize: Qt.application.font.pixelSize * 3
                                anchors.centerIn: parent
                            }
                            Layout.minimumHeight: 64
                            value: 42
                            Layout.minimumWidth: 64
                            Layout.maximumHeight: 128
                            Layout.fillHeight: true
                            Layout.preferredWidth: 128
                            stepSize: 1
                            to: 100
                            Layout.preferredHeight: 128
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 128
                        }
                    }
                }

                Layout.fillHeight: true
            }

            Frame {
                id: frame
                width: 800
                height: 480
                anchors.rightMargin: 0
                anchors.bottomMargin: 0
                anchors.leftMargin: 0
                anchors.topMargin: 0
                contentHeight: 480
                contentWidth: 800


                RowLayout {
                    id: mainRowLayout
                    width: 800
                    height: 480
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 36

                    Container {
                        id: leftTabBar

                        currentIndex: 1

                        Layout.fillWidth: false
                        Layout.fillHeight: true

                        ButtonGroup {
                            buttons: columnLayout.children
                        }

                        contentItem: ColumnLayout {
                            id: columnLayout
                            spacing: 3

                            Repeater {
                                model: leftTabBar.contentModel
                            }
                        }

                        FeatureButton {
                            id: navigationFeatureButton
                            text: qsTr("Navigation")
                            icon.name: "navigation"
                            Layout.fillHeight: true
                        }

                        FeatureButton {
                            text: qsTr("Music")
                            icon.name: "music"
                            checked: true
                            Layout.fillHeight: true
                        }

                        FeatureButton {
                            text: qsTr("Message")
                            icon.name: "message"
                            Layout.fillHeight: true
                        }

                        FeatureButton {
                            text: qsTr("Command")
                            icon.name: "command"
                            Layout.fillHeight: true
                        }

                        FeatureButton {
                            text: qsTr("Settings")
                            font.family: "Times New Roman"
                            icon.name: "settings"
                            Layout.fillHeight: true
                        }
                    }

                    StackLayout {
                        currentIndex: leftTabBar.currentIndex

                        Layout.preferredWidth: 150
                        Layout.maximumWidth: 150
                        Layout.fillWidth: false

                        Item {}

                        ColumnLayout {
                            spacing: 16

                            ButtonGroup {
                                id: viewButtonGroup
                                buttons: viewTypeRowLayout.children
                            }

                            RowLayout {
                                id: viewTypeRowLayout
                                spacing: 3

                                Layout.bottomMargin: 12

                                Button {
                                    text: qsTr("Compact")
                                    font.pixelSize: fontSizeExtraSmall
                                    checked: true

                                    Layout.fillWidth: true
                                }
                                Button {
                                    text: qsTr("Full")
                                    font.pixelSize: fontSizeExtraSmall
                                    checkable: true

                                    Layout.fillWidth: true
                                }
                            }

                            GlowingLabel {
                                text: qsTr("VOLUME")
                                color: "white"
                                font.pixelSize: fontSizeMedium
                            }

                            Dial {
                                id: volumeDial
                                from: 0
                                value: 42
                                to: 100
                                stepSize: 1

                                Layout.alignment: Qt.AlignHCenter
                                Layout.minimumWidth: 64
                                Layout.minimumHeight: 64
                                Layout.preferredWidth: 128
                                Layout.preferredHeight: 128
                                Layout.maximumWidth: 128
                                Layout.maximumHeight: 128
                                Layout.fillHeight: true

                                Label {
                                    text: volumeDial.value.toFixed(0)
                                    color: "white"
                                    font.pixelSize: Qt.application.font.pixelSize * 3
                                    anchors.centerIn: parent
                                }
                            }

                            ButtonGroup {
                                id: audioSourceButtonGroup
                            }

                            RowLayout {
                                Layout.topMargin: 16

                                GlowingLabel {
                                    id: radioOption
                                    text: qsTr("RADIO")
                                    color: "white"
                                    font.pixelSize: fontSizeMedium
                                    horizontalAlignment: Label.AlignLeft

                                    Layout.fillWidth: true
                                }
                                GlowingLabel {
                                    text: qsTr("AUX")
                                    color: colorLightGrey
                                    font.pixelSize: fontSizeMedium * 0.8
                                    horizontalAlignment: Label.AlignHCenter
                                    glowEnabled: false

                                    Layout.alignment: Qt.AlignBottom
                                    Layout.fillWidth: true
                                }
                                GlowingLabel {
                                    text: qsTr("MP3")
                                    color: colorDarkGrey
                                    font.pixelSize: fontSizeMedium * 0.6
                                    horizontalAlignment: Label.AlignRight
                                    glowEnabled: false

                                    Layout.alignment: Qt.AlignBottom
                                    Layout.fillWidth: true
                                }
                            }

                            Frame {
                                id: stationFrame
                                leftPadding: 1
                                rightPadding: 1
                                topPadding: 1
                                bottomPadding: 1

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredHeight: 128

                                ListView {
                                    clip: true
                                    anchors.fill: parent

                                    ScrollIndicator.vertical: ScrollIndicator {
                                        parent: stationFrame
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.rightMargin: 1
                                        anchors.bottom: parent.bottom
                                    }

                                    model: ListModel {
                                        ListElement { name: "V-Radio"; frequency: "105.5 MHz" }
                                        ListElement { name: "World News"; frequency: "93.4 MHz" }
                                        ListElement { name: "TekStep FM"; frequency: "95.0 MHz" }
                                        ListElement { name: "Classic Radio"; frequency: "89.9 MHz" }
                                        ListElement { name: "Buena Vista FM"; frequency: "100.8 MHz" }
                                        ListElement { name: "Drive-by Radio"; frequency: "99.1 MHz" }
                                        ListElement { name: "Unknown #1"; frequency: "104.5 MHz" }
                                        ListElement { name: "Unknown #2"; frequency: "91.2 MHz" }
                                        ListElement { name: "Unknown #3"; frequency: "93.8 MHz" }
                                        ListElement { name: "Unknown #4"; frequency: "80.4 MHz" }
                                        ListElement { name: "Unknown #5"; frequency: "101.1 MHz" }
                                        ListElement { name: "Unknown #6"; frequency: "92.2 MHz" }
                                    }
                                    delegate: ItemDelegate {
                                        id: stationDelegate
                                        width: parent.width
                                        height: 22
                                        text: model.name
                                        font.pixelSize: fontSizeExtraSmall
                                        topPadding: 0
                                        bottomPadding: 0

                                        contentItem: RowLayout {
                                            Label {
                                                text: model.name
                                                font: stationDelegate.font
                                                horizontalAlignment: Text.AlignLeft
                                                Layout.fillWidth: true
                                            }
                                            Label {
                                                text: model.frequency
                                                font: stationDelegate.font
                                                horizontalAlignment: Text.AlignRight
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }
                                }
                            }

                            Frame {
                                Layout.fillWidth: true

                                RowLayout {
                                    anchors.fill: parent

                                    Label {
                                        text: qsTr("Sort by")
                                        font.pixelSize: fontSizeExtraSmall

                                        Layout.alignment: Qt.AlignTop
                                    }

                                    ColumnLayout {
                                        RadioButton {
                                            text: qsTr("Name")
                                            font.pixelSize: fontSizeExtraSmall
                                        }
                                        RadioButton {
                                            text: qsTr("Frequency")
                                            font.pixelSize: fontSizeExtraSmall
                                        }
                                        RadioButton {
                                            text: qsTr("Favourites")
                                            font.pixelSize: fontSizeExtraSmall
                                            checked: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        color: colorMain
                        implicitWidth: 1
                        Layout.fillHeight: true
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 350
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        GlowingLabel {
                            id: timeLabel
                            text: qsTr("11:02")
                            font.pixelSize: fontSizeExtraLarge

                            Layout.alignment: Qt.AlignHCenter

                            GlowingLabel {
                                text: qsTr("AM")
                                font.pixelSize: fontSizeLarge
                                anchors.left: parent.right
                                anchors.leftMargin: 8
                            }
                        }

                        Label {
                            text: qsTr("01/01/2018")
                            color: colorLightGrey
                            font.pixelSize: fontSizeMedium

                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 2
                            Layout.bottomMargin: 10
                        }

                        Image {
                            source: "qrc:/icons/car.png"
                            fillMode: Image.PreserveAspectFit

                            Layout.fillHeight: true

                            Column {
                                x: parent.width * 0.88
                                y: parent.height * 0.56
                                spacing: 3

                                Image {
                                    source: "qrc:/icons/warning.png"
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    layer.enabled: true
                                    layer.effect: CustomGlow {
                                        spread: 0.2
                                        samples: 40
                                        color: colorWarning
                                    }
                                }

                                GlowingLabel {
                                    text: qsTr("Door open")
                                    color: colorWarning
                                    glowColor: Qt.rgba(colorWarning.r, colorWarning.g, colorWarning.b, 0.4)
                                }
                            }
                        }
                    }

                    Rectangle {
                        color: colorMain
                        implicitWidth: 1
                        Layout.fillHeight: true
                    }

                    ColumnLayout {
                        Row {
                            spacing: 8

                            Image {
                                source: "qrc:/icons/weather.png"
                            }

                            Column {
                                spacing: 8

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    GlowingLabel {
                                        id: outsideTempValueLabel
                                        text: qsTr("31")
                                        font.pixelSize: fontSizeExtraLarge
                                    }

                                    GlowingLabel {
                                        text: qsTr("°C")
                                        font.pixelSize: Qt.application.font.pixelSize * 2.5
                                        anchors.baseline: outsideTempValueLabel.baseline
                                    }
                                }

                                Label {
                                    text: qsTr("Osaka, Japan")
                                    color: colorLightGrey
                                    font.pixelSize: fontSizeMedium
                                }
                            }
                        }

                        ColumnLayout {
                            id: airConRowLayout
                            spacing: 8

                            Layout.preferredWidth: 128
                            Layout.preferredHeight: 380
                            Layout.fillHeight: true

                            Item {
                                Layout.fillHeight: true
                            }

                            SwitchDelegate {
                                text: qsTr("AC")
                                leftPadding: 0
                                rightPadding: 0
                                topPadding: 0
                                bottomPadding: 0

                                Layout.fillWidth: true
                            }

                            // QTBUG-63269
                            Item {
                                implicitHeight: temperatureValueLabel.implicitHeight
                                Layout.fillWidth: true
                                Layout.topMargin: 16

                                Label {
                                    text: qsTr("Temperature")
                                    anchors.baseline: temperatureValueLabel.bottom
                                    anchors.left: parent.left
                                }

                                GlowingLabel {
                                    id: temperatureValueLabel
                                    text: qsTr("24°C")
                                    font.pixelSize: fontSizeLarge
                                    anchors.right: parent.right
                                }
                            }

                            Slider {
                                value: 0.35
                                Layout.fillWidth: true
                            }

                            // QTBUG-63269
                            Item {
                                implicitHeight: powerValueLabel.implicitHeight
                                Layout.fillWidth: true
                                Layout.topMargin: 16

                                Label {
                                    text: qsTr("Power")
                                    anchors.baseline: powerValueLabel.bottom
                                    anchors.left: parent.left
                                }

                                GlowingLabel {
                                    id: powerValueLabel
                                    text: qsTr("10%")
                                    font.pixelSize: fontSizeLarge
                                    anchors.right: parent.right
                                }
                            }

                            Slider {
                                value: 0.25
                                Layout.fillWidth: true
                            }

                            SwitchDelegate {
                                text: qsTr("Low")
                                leftPadding: 0
                                rightPadding: 0
                                topPadding: 0
                                bottomPadding: 0

                                Layout.fillWidth: true
                                Layout.topMargin: 16
                            }

                            SwitchDelegate {
                                text: qsTr("High")
                                checked: true
                                leftPadding: 0
                                rightPadding: 0
                                topPadding: 0
                                bottomPadding: 0

                                Layout.fillWidth: true
                            }

                            SwitchDelegate {
                                text: qsTr("Defog")
                                leftPadding: 0
                                rightPadding: 0
                                topPadding: 0
                                bottomPadding: 0

                                Layout.fillWidth: true
                            }

                            SwitchDelegate {
                                text: qsTr("Recirculate")
                                leftPadding: 0
                                rightPadding: 0
                                topPadding: 0
                                bottomPadding: 0

                                Layout.fillWidth: true
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    Container {
                        id: rightTabBar

                        currentIndex: 1

                        Layout.fillHeight: true

                        ButtonGroup {
                            buttons: rightTabBarContentLayout.children
                        }

                        contentItem: ColumnLayout {
                            id: rightTabBarContentLayout
                            spacing: 3

                            Repeater {
                                model: rightTabBar.contentModel
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        FeatureButton {
                            text: qsTr("Windows")
                            icon.name: "windows"

                            Layout.maximumHeight: navigationFeatureButton.height
                            Layout.fillHeight: true
                        }
                        FeatureButton {
                            text: qsTr("Air Con.")
                            icon.name: "air-con"
                            checked: true

                            Layout.maximumHeight: navigationFeatureButton.height
                            Layout.fillHeight: true
                        }
                        FeatureButton {
                            text: qsTr("Seats")
                            icon.name: "seats"

                            Layout.maximumHeight: navigationFeatureButton.height
                            Layout.fillHeight: true
                        }
                        FeatureButton {
                            text: qsTr("Statistics")
                            icon.name: "statistics"

                            Layout.maximumHeight: navigationFeatureButton.height
                            Layout.fillHeight: true
                        }
                    }
                }
            }





        }

        RoundButton {
            id: roundButton
            x: 741
            y: 422
            width: 74
            height: 77
            text: "M"
        }

        TabBar {
            id: topLevelBar
            x: 94
            y: 0
            width: 613
            height: 41

            TabButton {
                id: tabButton
                text: qsTr("Delay")
            }

            TabButton {
                id: tabButton1
                text: qsTr("Reverb")
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





    }

}







































/*##^## Designer {
    D{i:125;invisible:true}
}
 ##^##*/
