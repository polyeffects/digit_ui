import "controls" as PolyControls
import QtQuick 2.9
import QtQuick.Controls 2.3
// This container and the transform on the Label are
// necessary to get precise bounding rect of the text for layouting reasons,
// since some of the labels' font sizes can get quite large.
Label {
    // id: label
    x: 4
    y: -37 
    visible: title_footer.show_help 
	// property alias text: label.text
	// property alias font: label.font
	// property alias horizontalAlignment: label.horizontalAlignment
	// property alias verticalAlignment: label.verticalAlignment
    horizontalAlignment: Text.AlignHCenter
    width: 54
    height: 9
    z: 1
    color: "white"
    font {
        pixelSize: 14
        capitalization: Font.AllUppercase
    }
}
