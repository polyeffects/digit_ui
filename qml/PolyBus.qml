import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import QtQuick.Controls.Imagine 2.3
// import QtQuick.Controls.Material 2.3
import QtQuick.Window 2.0

Item {
    id: row1
    x: 0
    y: 10
    width: 800
    height: 376
    GroupBox {
        id: groupBox4
        width: 200
        height: 200
        title: qsTr("AVAILABLE")
        Frame {
            id: stationFrame3
            bottomPadding: 1
            Layout.fillWidth: true
            contentHeight: 300
            leftPadding: 1
            ListView {
                clip: true
                anchors.fill: parent
                delegate: ItemDelegate {
                    width: parent.width
                    height: 22
                    text: edit
                    bottomPadding: 0
                    font.pixelSize: fontSizeExtraSmall
                    topPadding: 0
                }
                ScrollIndicator.vertical: ScrollIndicator {
                    anchors.top: parent.top
                    parent: stationFrame3
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    anchors.bottom: parent.bottom
                }
                model: delay1_Left_OutAvailablePorts
            }
            topPadding: 1
            Layout.fillHeight: true
            Layout.preferredHeight: 128
            rightPadding: 1
            contentWidth: 300
        }
        anchors.leftMargin: 0
        anchors.left: parent.left
    }

    GroupBox {
        id: groupBox5
        width: 300
        height: 300
        title: qsTr("CONNECTED")
        Frame {
            id: stationFrame4
            bottomPadding: 1
            Layout.fillWidth: true
            contentHeight: 300
            anchors.fill: parent
            leftPadding: 1
            ListView {
                x: 0
                y: 0
                width: 300
                height: 300
                clip: true
                anchors.bottomMargin: 10
                anchors.fill: parent
                delegate: ItemDelegate {
                    width: parent.width
                    height: 22
                    text: "section "+edit
                    bottomPadding: 0
                    font.pixelSize: fontSizeExtraSmall
                    topPadding: 0
                }
                ScrollIndicator.vertical: ScrollIndicator {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    parent: stationFrame4
                    anchors.rightMargin: 1
                    anchors.bottom: parent.bottom
                }
                model: delay1_Left_OutUsedPorts
            }
            topPadding: 1
            Layout.fillHeight: true
            Layout.preferredHeight: 128
            rightPadding: 1
            contentWidth: 300
        }
        anchors.right: parent.right
        anchors.rightMargin: 0
    }
    anchors.top: parent.top
    anchors.topMargin: 10

}
