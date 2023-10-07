import QtQuick 2.11
import QtQuick.Templates 2.4 as T
import QtQuick.Controls 2.4
import QtQuick.Controls.impl 2.4
import QtQuick.Controls.Material 2.4
import QtQuick.Controls.Material.impl 2.4
import "../qml/polyconst.js" as Constants
// import QtQuick.Shapes 1.11

T.Button {
    id: control
    property int radius: 3
    property int extra_padding: 0
    property bool has_border: true
    property real value: 0.0
    property string value_suffix: ""

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem.implicitHeight + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    // external vertical padding is 6 (to increase touch area)
    padding: 0
	topPadding: 10
	bottomPadding: 5
    leftPadding: 5 
    rightPadding: 5 + extra_padding 
    spacing: 0

	flat: true

    Material.elevation: flat ? control.down || control.hovered ? 2 : 0
                             : control.down ? 8 : 2
    // Material.background: flat ? "transparent" : undefined

    contentItem: Column {
        Text {
			text: control.text
            anchors.horizontalCenter: parent.horizontalCenter
            color: !control.enabled ? control.Material.hintTextColor :
                control.checked ? Constants.background_color: "white"
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
            font {
                pixelSize: 24
                capitalization: Font.AllUppercase
            }
			// width: math.max(62, control.width)
        }
        Text {
            text: control.value + control.value_suffix
            anchors.horizontalCenter: parent.horizontalCenter
            color: !control.enabled ? control.Material.hintTextColor :
                control.checked ? Constants.background_color: control.Material.foreground
            font {
                pixelSize: 36
                capitalization: Font.AllUppercase
            }
			verticalAlignment: Text.AlignVCenter
			horizontalAlignment: Text.AlignHCenter
			// width: math.max(62, control.width)
        }
    }


    // TODO: Add a proper ripple/ink effect for mouse/touch input and focus state
    background: Rectangle {
        implicitWidth: 62
        implicitHeight: 62

        // external vertical padding is 6 (to increase touch area)
        // y: 6
        width: parent.width
        height: parent.height 
        radius: control.radius
        color: control.checked ? control.Material.foreground : Constants.background_color
        border {
            width: control.checked ? 0 : 3; 
            color: Constants.poly_dark_grey
        }
    }
}
