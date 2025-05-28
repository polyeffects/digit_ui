import "controls" as PolyControls
import QtQuick 2.9
import QtQuick.Controls 2.3
// This container and the transform on the Label are
// necessary to get precise bounding rect of the text for layouting reasons,
// since some of the labels' font sizes can get quite large.
Label {
	property alias text: label.text
	property alias font: label.font
	property alias horizontalAlignment: label.horizontalAlignment
	property alias verticalAlignment: label.verticalAlignment
	font {
		pixelSize: fontSizeMedium
	}

	id: label
	color: "#ffffff"
}
