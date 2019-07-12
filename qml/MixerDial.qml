import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import Qt.labs.handlers 1.0

Dial {
    id: control
    property string param
    property string effect: "mixer"
    property string textOverride: control.value.toFixed(1)
    property bool canMap: true 
    width: 75
    height: 75
    from: polyValues[effect][param].rmin
    to: polyValues[effect][param].rmax
    Rectangle {
        width: parent.width
        height: parent.height
        radius: parent.width / 2
        color: Material.color(Material.Cyan, Material.Shade400)
        visible: knobs.waiting != ""
        z:-2
    }
    Label {
        color: "#ffffff"
        text: textOverride
        font.pixelSize: 20 * 2
        anchors.centerIn: parent
    }
    onMoved: {
        if (pressed === true)
        {
            knobs.ui_knob_change(effect, param, control.value)
        }
    }
    onPressedChanged: {
        // console.warn("set knob mapping")
        // if we're in set control mode, then set this control
        // python variable in qml context
        if (knobs.waiting != "") // left or right
        {
            console.warn("knob waiting", knobs.waiting)
            knobs.map_parameter(effect, param)    
            console.warn("set knob mapping")
        }
        if (pressed === true){
            if(timer.running)
            {
                // console.log("double tapped");
                midiAssignPopup.set_mapping_choice(effect, param);
                timer.stop()
            }
            timer.restart()
        }
    }
    Timer{
        id:timer
        interval: 200
    }
    // TapHandler {
    //     onDoubleTapped: console.log("double tapped")
    //     gesturePolicy: TapHandler.DragThreshold
    // }
    // onDoubleClick: {
    //     midiAssignPopup.set_mapping_choice(effect, param);
    // }
    Layout.minimumHeight: 64
    value: polyValues[effect][param].value
    Layout.minimumWidth: 64
    Layout.maximumHeight: 128
    Layout.fillHeight: true
    Layout.preferredWidth: 128
    stepSize: 0.01
    Layout.preferredHeight: 128
    Layout.alignment: Qt.AlignHCenter
    Layout.maximumWidth: 128
    // MouseArea {
    //     anchors.fill: parent
    //     propagateComposedEvents: true
    //     onDoubleClicked: {
    //         console.log("clicked blue")
    //         mouse.accepted = false
    //     }
    // }
    //
    // MouseArea {
    //     property int pressAndHoldDuration: 2000
    //     signal myPressAndHold()
    //     anchors.fill: parent
    //     onPressed: {
    //         pressAndHoldTimer.start();
    //     }
    //     onReleased: {
    //         pressAndHoldTimer.stop();
    //     }
    //     onMyPressAndHold: {
    //         console.log("It works!");
    //     }

    //     Timer {
    //         id:  pressAndHoldTimer
    //         interval: parent.pressAndHoldDuration
    //         running: false
    //         repeat: false
    //         onTriggered: {
    //             parent.myPressAndHold();
    //         }
    //     }
    // }
}
