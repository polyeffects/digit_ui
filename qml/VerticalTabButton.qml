import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "polyconst.js" as Constants

Item {
    property alias target_index: index  
    property string text
    property int our_index: 0

    Button {
        height: 92
        width: 180
        text: text
        checked: target == index
        font {
            pixelSize: 24
            capitalization: Font.AllUppercase
        }
        onClicked: {
            target = index;
        }

        contentItem: Text {
            text: text
            color:  checked ? Constants.background_color : Constants.poly_blue
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            height: parent.height
            width: parent.width
            font {
                pixelSize: 48
            }
        }

        background: Rectangle {
            width: parent.width
            height: parent.height
            color: checked ? Constants.poly_blue : Constants.poly_dark_grey  
            border.width: 0
            radius: 20
        }
    }

}
