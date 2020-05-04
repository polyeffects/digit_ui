import QtQuick 2.9
import QtQuick.Controls 2.3
// This container and the transform on the Label are
// necessary to get precise bounding rect of the text for layouting reasons,
// since some of the labels' font sizes can get quite large.
Label {
    visible: title_footer.show_help 
    x: -10
    y: 75 
    width: 110
    horizontalAlignment: Text.AlignHCenter
    height: 9
    z: 1
    color: "white"
    font {
        pixelSize: 14
        capitalization: Font.AllUppercase
    }
}
