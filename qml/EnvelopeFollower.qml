import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

// segment type / glide, value, time
// global glide, num_points, +- mode, repeat
Item {
    id: lfo_control
    property string effect: "envg1"
    height: 550
    width: 1200

    // Row {
    PolyFrame {
        // background: Material.background
        // width:parent.width
        // height:parent.height
        // Material.elevation: 2
        x: 200
        y: 100
        Column {
            width:parent.width
            spacing:20
            Row {
                height:200
                spacing: 10
                GlowingLabel {
                    text: qsTr("THRESHOLD")
                }
                MixerDial {
                    effect: effect
                    param: "THRESHOLD"
                }
                GlowingLabel {
                    text: qsTr("SATURATION")
                }
                MixerDial {
                    effect: effect
                    param: "SATURATION"
                }
                GlowingLabel {
                    text: qsTr("ATTACK")
                }
                MixerDial {
                    effect: effect
                    param: "ATIME"
                }
                GlowingLabel {
                    text: qsTr("DECAY")
                }
                MixerDial {
                    effect: effect
                    param: "DTIME"
                }
            }
            Row {
                height:200
                spacing: 10
                GlowingLabel {
                    text: qsTr("OUT MIN")
                }
                MixerDial {
                    effect: effect
                    param: "MMINV"
                }
                GlowingLabel {
                    text: qsTr("OUT MAX")
                }
                MixerDial {
                    effect: effect
                    param: "MMAXV"
                }
                GlowingLabel {
                    text: qsTr("PEAK/RMS")
                }
                MixerDial {
                    effect: effect
                    param: "PEAKRMS"
                }
                Switch {
                    text: qsTr("INVERT")
                    font.pixelSize: baseFontSize
                    width: 300
                    checked: polyValues[effect]["MDIRECTION"].value 
                    bottomPadding: 0
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    onClicked: {
                        knobs.ui_knob_change(effect, "MDIRECTION", checked | 0); // force to int
                    }
                }
            }

            Button {
                text: "ASSIGN"
                font.pixelSize: baseFontSize
                width: 140
                x: 400
                onClicked: {
                    // set learn
                    knobs.set_waiting(effect)
                }
            }

        }
    }


    // }
}

