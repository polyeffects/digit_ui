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

    Slider {
        x: 0
        y: 0
        is_log: control.is_log
        visible: v_type != "bool"
        snapMode: Slider.SnapAlways
        stepSize: v_type == "int" ? 1.0 : 0.0
        title: control.title
        width: parent.width - 50
        height:parent.height
        value: currentEffects[current_effect]["controls"][row_param].value
        from: currentEffects[current_effect]["controls"][row_param].rmin
        to: currentEffects[current_effect]["controls"][row_param].rmax
        onMoved: {
            knobs.ui_knob_change(current_effect, row_param, value);
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
