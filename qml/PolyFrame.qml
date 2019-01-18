import QtQuick 2.11
// import QtQuick.Templates 2.4 as T
// import QtQuick.Controls.Material 2.4
// import QtQuick.Controls.Material.impl 2.4
import QtQuick.Controls 2.4


Frame {
    id: control

    implicitWidth: Math.max(background ? background.implicitWidth : 0, contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0, contentHeight + topPadding + bottomPadding)

    contentWidth: contentItem.implicitWidth || (contentChildren.length === 1 ? contentChildren[0].implicitWidth : 0)
    contentHeight: contentItem.implicitHeight || (contentChildren.length === 1 ? contentChildren[0].implicitHeight : 0)

    padding: 12
    background: null

    // background: Rectangle {
    //     radius: 2
    //     color: control.Material.elevation > 0 ? control.Material.backgroundColor : "transparent"
    //     border.color: control.Material.frameColor

    //     layer.enabled: control.enabled && control.Material.elevation > 0
    //     layer.effect: ElevationEffect {
    //         elevation: control.Material.elevation
    //     }
    // }
}
   
