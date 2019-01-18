import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3

Dial {
    id: control
    property string param
    property string effect: "mixer"
    width: 75
    height: 75
    from: 0
    Label {
        color: "#ffffff"
        text: control.value.toFixed(1)
        font.pixelSize: Qt.application.font.pixelSize * 3
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
            knobs.map_parameter_to_encoder(effect, param)    
            console.warn("set knob mapping")
        }
    }
    Layout.minimumHeight: 64
    value: polyValues[effect][param].value
    Layout.minimumWidth: 64
    Layout.maximumHeight: 128
    Layout.fillHeight: true
    Layout.preferredWidth: 128
    stepSize: 0.01
    to: 1
    Layout.preferredHeight: 128
    Layout.alignment: Qt.AlignHCenter
    Layout.maximumWidth: 128
}
