import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

Item {
    height: 62
    width:  472
    property string row_param: "Amp_5"
    property string current_effect 
    property real multiplier: 1  
	property bool is_log: false


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

	function logslider(position) {
		// linear in to log out
		// input position will be between 0 and 1
		var minp = 0;
		var maxp = 1;

		// The output result should be between 20 an 20000
		var minv = Math.log(20);
		var maxv = Math.log(20000);

		// calculate adjustment factor
		var scale = (maxv-minv) / (maxp-minp);

		return Math.exp(minv + scale*(position-minp));
	}

	function logposition(value) {
		// log in to linear out
		// input position will be between 0 and 1
		var minp = 0;
		var maxp = 1;

		// The output result should be between 20 an 200000
		var minv = Math.log(20);
		var maxv = Math.log(20000);

		// calculate adjustment factor
		var scale = (maxv-minv) / (maxp-minp);

		return (Math.log(value)-minv) / scale + minp;
	}

    Slider {
        x: 0
        y: 0
        visible: row_param != "ir"
        title: currentEffects[current_effect]["controls"][row_param].name
        width: 420
        height:parent.height
        value: is_log ? logslider(currentEffects[current_effect]["controls"][row_param].value) : currentEffects[current_effect]["controls"][row_param].value
        from: is_log ? 20 : currentEffects[current_effect]["controls"][row_param].rmin
        to: is_log ? 20000 : currentEffects[current_effect]["controls"][row_param].rmax
        onMoved: {
			if (is_log){
				knobs.ui_knob_change(current_effect, row_param, logposition(value));
			} else {
				knobs.ui_knob_change(current_effect, row_param, value);
			}
        }
        onPressedChanged: {
            if (pressed){
                knobs.set_knob_current_effect(current_effect, row_param);
            }
        }
    }

	IconButton {
		x: 425
        anchors.verticalCenter: parent.verticalCenter
		icon.source: "../icons/digit/clouds/Knob.png"
        visible: row_param != "ir"
		width: 60
		height: 60
		Timer {
			id: timer
			interval: 400
		}
		onClicked: {
			if (timer.running){
				knobs.ui_knob_change(current_effect, row_param, currentEffects[current_effect]["controls"][row_param].default_value);
				timer.stop()

			}
			else {
				knobs.set_knob_current_effect(current_effect, row_param);
				timer.restart()
			}
		}
		radius: 15
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
