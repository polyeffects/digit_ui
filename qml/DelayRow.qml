import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
Item {
    height: 40
    width:  500
    property string row_param: "Amp_5"
    property string current_effect 

    function basename(ustr)
    {
        // return (String(str).slice(String(str).lastIndexOf("/")+1))
        if (ustr != null)
        {
            var str = ustr.toString()
            return (str.slice(str.lastIndexOf("/")+1))
        }
        return "None Selected"
    }

    function remove_suffix(x)
    {
       return x.replace(/\.[^/.]+$/, "") 
    }

    Slider {
        x: 0
        y: 0
        visible: row_param != "ir"
        title: currentEffects[current_effect]["controls"][row_param].name
        width: 500
        height:40
        value: currentEffects[current_effect]["controls"][row_param].value
        from: currentEffects[current_effect]["controls"][row_param].rmin
        to: currentEffects[current_effect]["controls"][row_param].rmax
        onMoved: {
            knobs.ui_knob_change(current_effect, row_param, value);
        }
        onPressedChanged: {
            if (pressed){
                knobs.set_knob_current_effect(current_effect, row_param);
            }
        }
    }

   Text {
        x: 10
        y: 0
        visible: row_param == "ir"
        font.pixelSize: 18
        font.capitalization: Font.AllUppercase
        width: 500
        height:40
        color: "white"
        text: row_param == "ir" ? remove_suffix(basename(currentEffects[current_effect]["controls"][row_param].name)) : "not IR"
        }


        // SpinBox {
        //     id: spinbox
        //     value: currentEffects[current_effect]["controls"][row_param].value * 100
        //     from: currentEffects[current_effect]["controls"][row_param].rmin * 100
        //     to: currentEffects[current_effect]["controls"][row_param].rmax * 100
        //     stepSize: 10
        //     // editable: true
        //     property int decimals: 2
        //     property real realValue: value / 100
        //     onValueModified: {
        //         knobs.ui_knob_change(current_effect, row_param, realValue);
        //     }
        //     inputMethodHints: Qt.ImhFormattedNumbersOnly

        //     validator: DoubleValidator {
        //         bottom: Math.min(spinbox.from, spinbox.to)
        //         top:  Math.max(spinbox.from, spinbox.to)
        //     }

        //     textFromValue: function(value, locale) {
        //         return Number(value / 100).toLocaleString(locale, 'f', spinbox.decimals)
        //     }

        //     valueFromText: function(text, locale) {
        //         return Number.fromLocaleString(locale, text) * 100
        //     }
        // }

        // Button {
        //     text: "Mapping"
        //     font.pixelSize: baseFontSize
        //     // width: 100
        //     onClicked: {
        //         midiAssignPopup.set_mapping_choice("delay"+(time_scale.current_delay+1), row_param);
        //     }
        //     // flat: true
        // }
    // }
}
