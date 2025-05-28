import "controls" as PolyControls
import QtQuick 2.11
// import QtQuick.Controls.Material 2.4
// import QtQuick.Controls.Material.impl 2.4
import QtQuick.Controls 2.4

ComboBox {
    flat: true
    id: control
    // width: 140
    // model: ["LEVEL", "TONE", "FEEDBACK", "GLIDE", "WARP"]
    font.pixelSize: baseFontSize
    delegate:PolyControls.ItemDelegate {
        width: control.width
        text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
        font.weight: control.currentIndex === index ? Font.DemiBold : Font.Normal
        font.family: control.font.family
        font.pixelSize: control.font.pixelSize 
        highlighted: control.highlightedIndex === index
        hoverEnabled: control.hoverEnabled
    }
}
