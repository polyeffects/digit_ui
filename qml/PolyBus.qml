import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import QtQuick.Controls.Imagine 2.3
// import QtQuick.Controls.Material 2.3
import QtQuick.Window 2.0

Row {
	anchors.left: parent.left
	anchors.right: parent.right
	height: parent.height
    id: control
    property var availablePorts // maybe ListModel
    property var usedPorts
    property string effect
    property string sourcePort
    GroupBox {
        id: groupBox4
		anchors.top: parent.top
		anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 0
		width: 0.5 * parent.width
        title: qsTr("AVAILABLE")
        Frame {
            id: stationFrame3
            bottomPadding: 1
            Layout.fillWidth: true
            // contentHeight: 300
            anchors.fill: parent
            leftPadding: 1
            ListView {
                width: parent.width
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true
                delegate: ItemDelegate {
                    width: parent.width
                    height: 22
                    text: edit
                    bottomPadding: 0
                    font.pixelSize: fontSizeExtraSmall
                    topPadding: 0
                    onClicked: {
                        knobs.ui_add_connection(effect, sourcePort, edit)
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator {
                    anchors.top: parent.top
                    parent: stationFrame3
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    anchors.bottom: parent.bottom
                }
                model: availablePorts
            }
            topPadding: 1
            Layout.fillHeight: true
            Layout.preferredHeight: 128
            rightPadding: 1
            // contentWidth: 300
        }
    }

    GroupBox {
        id: groupBox5
		width: 0.5 * parent.width
		anchors.top: parent.top
		anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 0
        title: qsTr("CONNECTED")
        Frame {
            id: stationFrame4
            bottomPadding: 1
            Layout.fillWidth: true
            // contentHeaight: 300
            anchors.fill: parent
            leftPadding: 1
            ListView {
                // x: 0
                // y: 0
                width: parent.width
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                clip: true
                // anchors.bottomMargin: 10
                delegate: ItemDelegate {
                    width: parent.width
                    height: 22
                    text: "section "+edit
                    bottomPadding: 0
                    font.pixelSize: fontSizeExtraSmall
                    topPadding: 0
                    onClicked: {
                        knobs.ui_remove_connection(effect, sourcePort, edit)
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator {
                    anchors.top: parent.top
                    parent: stationFrame4
                    anchors.right: parent.right
                    anchors.rightMargin: 1
                    anchors.bottom: parent.bottom
                }
                model: usedPorts
            }
            topPadding: 1
            Layout.fillHeight: true
            Layout.preferredHeight: 128
            rightPadding: 1
            // contentWidth: 300
        }
    }
    anchors.top: parent.top
    anchors.topMargin: 10

}





/*##^## Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
 ##^##*/
