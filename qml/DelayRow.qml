import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

Item {
    id: control
    height: 62
    width:  472
    property string row_param: "Amp_5"
    property string current_effect 
    property real multiplier: 1  
    property string v_type: "float"
	property bool is_log: false
	property string title: currentEffects[current_effect]["controls"][row_param].name
    visible: v_type != "hide"

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
        visible: v_type != "bool"
        snapMode: Slider.SnapAlways
        stepSize: v_type == "int" ? 1.0 : 0.0
        title: control.title
        width: parent.width - 50
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
				if (patch_single.more_hold){
					patch_single.more_hold = false;
					patchStack.push("More.qml", {"current_effect": current_effect, "row_param": row_param});
				}
            }
        }
    }

    Switch {
        x: 0
        y: 0
        visible: v_type == "bool"
        text: currentEffects[current_effect]["controls"][row_param].name
        width: 420
        height:parent.height
        checked: Boolean(currentEffects[current_effect]["controls"][row_param].value)
        onToggled: {
            knobs.ui_knob_change(current_effect, row_param, 1.0 - currentEffects[current_effect]["controls"][row_param].value);
        }
        font {
            pixelSize: 24
            capitalization: Font.AllUppercase
            family: mainFont.name
        }
    
    }
}
