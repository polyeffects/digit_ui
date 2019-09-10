import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
Item {
    height: 40
    width:  900
    property string row_param: "Amp_5"
    Row {
        height: 40
        spacing: 25
        GlowingLabel {
            text: time_scale.inv_parameter_map[row_param]
            width: 140
        }

        Slider {
            width: 625
            value: time_scale.delay_data[time_scale.current_delay][row_param].value 
            from: time_scale.delay_data[time_scale.current_delay][row_param].rmin 
            to: time_scale.delay_data[time_scale.current_delay][row_param].rmax 
            onMoved: {
                knobs.ui_knob_change("delay"+(time_scale.current_delay+1), row_param, value);
            }

        }

        SpinBox {
            id: spinbox
            value: time_scale.delay_data[time_scale.current_delay][row_param].value * 100 
            from: time_scale.delay_data[time_scale.current_delay][row_param].rmin * 100
            to: time_scale.delay_data[time_scale.current_delay][row_param].rmax * 100
            stepSize: 10
            // editable: true
            property int decimals: 2
            property real realValue: value / 100
            onValueModified: {
                knobs.ui_knob_change("delay"+(time_scale.current_delay+1), row_param, realValue);
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

        Button {
            text: "Mapping"
            font.pixelSize: baseFontSize
            // width: 100
            onClicked: {
                midiAssignPopup.set_mapping_choice("delay"+(time_scale.current_delay+1), row_param);
            }
            // flat: true
        }
    }
}
