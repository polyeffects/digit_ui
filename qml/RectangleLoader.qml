import QtQuick 2.7
import QtQuick.Controls.Material 2.3
import QtQuick.Controls.Material.impl 2.3

/**
 * Design by Enes Özgör: ens.ninja
 **/
Item {

    // ----- Public Properties ----- //

    property alias color: rect.color
    property int beat_msec: 500

    id: root

    Rectangle {
        id: rect
        width: root.width / 2
        height: root.height / 2
        transformOrigin: Item.BottomRight
        x: 0
        y: 0
        transform: Scale {
            id: transformScale
            origin {
                x: rect.width
                y: rect.height
            }
        }
        // color: "pink"
        color: Material.accent

        SequentialAnimation {
            running: true
            loops: Animation.Infinite

            // Top right
            ParallelAnimation {
                NumberAnimation {
                    target: transformScale; property: "xScale"; from: 1; to: -1; duration: beat_msec; easing.type: Easing.OutQuint
                }

                SequentialAnimation {
                    NumberAnimation {
                        target: transformScale; property: "yScale"; from: 1; to: 1.4; duration: beat_msec / 2; easing.type: Easing.OutQuart
                    }

                    NumberAnimation {
                        target: transformScale; property: "yScale"; from: 1.4; to: 1; duration: beat_msec / 2; easing.type: Easing.OutQuart
                    }
                }
            }

            // Bottom right
            ParallelAnimation {
                NumberAnimation {
                    target: transformScale; property: "yScale"; from: 1; to: -1; duration: beat_msec; easing.type: Easing.OutQuint
                }

                SequentialAnimation {
                    NumberAnimation {
                        target: transformScale; property: "xScale"; from: -1; to: -1.4; duration: beat_msec / 2; easing.type: Easing.OutQuart
                    }

                    NumberAnimation {
                        target: transformScale; property: "xScale"; from: -1.4; to: -1; duration: beat_msec / 2; easing.type: Easing.OutQuart
                    }
                }
            }

            // Bottom left
            ParallelAnimation {
                NumberAnimation {
                    target: transformScale; property: "xScale"; from: -1; to: 1; duration: beat_msec; easing.type: Easing.OutQuint
                }

                SequentialAnimation {
                    NumberAnimation {
                        target: transformScale; property: "yScale"; from: -1; to: -1.4; duration: beat_msec / 2; easing.type: Easing.OutQuart
                    }

                    NumberAnimation {
                        target: transformScale; property: "yScale"; from: -1.4; to: -1; duration: beat_msec / 2; easing.type: Easing.OutQuart
                    }
                }
            }

            // Top left
            ParallelAnimation {
                NumberAnimation {
                    target: transformScale; property: "yScale"; from: -1; to: 1; duration: beat_msec; easing.type: Easing.OutQuint
                }

                SequentialAnimation {
                    NumberAnimation {
                        target: transformScale; property: "xScale"; from: 1; to: 1.4; duration: beat_msec / 2; easing.type: Easing.OutQuart
                    }

                    NumberAnimation {
                        target: transformScale; property: "xScale"; from: 1.4; to: 1; duration: beat_msec / 2; easing.type: Easing.OutQuart
                    }
                }
            }
        }
    }
}
