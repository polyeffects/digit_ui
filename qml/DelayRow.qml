import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
Item {
    height: 40
    width:  900
    property string row_param: "Amp_5"
    property string current_effect 
    Row {
        height: 40
        spacing: 25
        GlowingLabel {
            text: currentEffects[current_effect]["controls"][row_param].name
            width: 140
        }

        Slider {
            width: 625
            value: currentEffects[current_effect]["controls"][row_param].value
            from: currentEffects[current_effect]["controls"][row_param].rmin
            to: currentEffects[current_effect]["controls"][row_param].rmax
            onMoved: {
                knobs.ui_knob_change(current_effect, row_param, value);
            }

        }

        SpinBox {
            id: spinbox
            value: currentEffects[current_effect]["controls"][row_param].value * 100
            from: currentEffects[current_effect]["controls"][row_param].rmin * 100
            to: currentEffects[current_effect]["controls"][row_param].rmax * 100
            stepSize: 10
            // editable: true
            property int decimals: 2
            property real realValue: value / 100
            onValueModified: {
                knobs.ui_knob_change(current_effect, row_param, realValue);
            }
            inputMethodHints: Qt.ImhFormattedNumbersOnly

            validator: DoubleValidator {
                bottom: Math.min(spinbox.from, spinbox.to)
                top:  Math.max(spinbox.from, spinbox.to)
            }

            textFromValue: function(value, locale) {
                return Number(value / 100).toLocaleString(locale, 'f', spinbox.decimals)
            }

            valueFromText: function(text, locale) {
                return Number.fromLocaleString(locale, text) * 100
            }
        }

        // Button {
        //     text: "Mapping"
        //     font.pixelSize: baseFontSize
        //     // width: 100
        //     onClicked: {
        //         midiAssignPopup.set_mapping_choice("delay"+(time_scale.current_delay+1), row_param);
        //     }
        //     // flat: true
        // }
    }
}
