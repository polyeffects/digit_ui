import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
// list for inputs, outputs
// each has a type, id, name.  icon? 
// effect has name, internal name / class, id
//
// later exposed parameters

Rectangle {
    id: rect
    width: 200
    height: 100
    radius: 10
    color: patch_bay.delete_mode ? Qt.rgba(0.9,0.0,0.0,1.0) : Qt.rgba(0.3,0.3,0.3,1.0)  
    z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
    // color: Material.color(time_scale.delay_colors[index])
    // color: Qt.rgba(0, 0, 0, 0)
    // color: setColorAlpha(Material.Pink, 0.1);//Qt.rgba(0.1, 0.1, 0.1, 1);
    x: 0
    y: 0
    property point beginDrag
    property bool caught: false
    property int effect_id
    // border { width:1; color: Material.color(Material.Cyan, Material.Shade100)}
    // border { width:2; color: Material.color(Material.Pink, Material.Shade200)}
    Drag.active: mouseArea.drag.active

    Button {
        anchors.left: parent.left
        anchors.leftMargin: 5
        icon.name: "md-arrow-back"
        width: 45
        height: 45
        // On click make this the current patch source, highlight this and possible targets
        // port id
        // creates new path element / connection
        // text: "<"
        // background: Rectangle {
        //     // anchors.left: parent.left
        //     // anchors.leftMargin: 0
        //     width: 20
        //     height: 20
        //     radius: 20
        //     // color: Material.color(Material.Pink, Material.Shade200)
        //     color: setColorAlpha(Material.color(Material.Pink, Material.Shade200), 0.2)
        //     border {
        //         color: Material.color(Material.Pink, Material.Shade200);
        //         width: 1
        //     }
        // }
    }

    Button {
        anchors.right: parent.right
        anchors.rightMargin: 35
        text: "<"
        background: Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: -25
            y:5
            width: 20
            height: 20
            radius: 20
            // color: Material.color(Material.Pink, Material.Shade200)
            color: setColorAlpha(Material.color(Material.Pink, Material.Shade200), 0.2)
            border {
                color: Material.color(Material.Pink, Material.Shade200);
                width: 1
            }
        }
        onClicked: {
            // delete current effect
            // console.log("clicked", display);
            // rep1.model.remove_effect(display)
            console.log("clicked", effect_id);
            rep1.model.remove_effect(effect_id)
        }
    }

    Label {
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Delay "+(index+1)
        color: "white"
        font {
            // pixelSize: fontSizeMedium
            pixelSize: 26
        }
    }
    //
    MouseArea {
        id: mouseArea
        z: -1
        anchors.fill: parent
        drag.target: parent
        onPressed: {
            // check mode: move, delete, connect, open
            rect.beginDrag = Qt.point(rect.x, rect.y);
            if (knobs.waiting != "") // mapping on
            {
                // pop up knob mapping selector
                mappingPopup.set_mapping_choice("delay"+(index+1), "Delay_1", "TIME", 
                "delay"+(index+1), time_scale.current_parameter, 
                time_scale.inv_parameter_map[time_scale.current_parameter], true);
            }

            /*
             * on click, find source ports 
             * knobs.effectSourcePorts(effect_name)
             * select source, show popup with source ports
             * highlight effects given source port
             * for effect in effects:
             *  for input_port in effect.input_ports:
             *      if input_port.type == source_port.type:
             *          highlight and break
             *
             * on click if highlighted (valid port)
             * show select target port if port count > 1
             * 
             * effect_connections[(effect_id, port_id)].append((target_effect_id, target_port_id))
             *  
             * for conn in effect_connections:
             *  draw arc
             */
        }
        onDoubleClicked: {
            time_scale.current_delay = index;
            mainStack.push(editDelay);
            // mappingPopup.set_mapping_choice("delay"+(index+1), "Delay_1", "TIME", 
            //     "delay"+(index+1), time_scale.current_parameter, 
            //     time_scale.inv_parameter_map[time_scale.current_parameter], false);    
            // remove MIDI mapping
            // add MIDI mapping
        }
        onReleased: {
            var in_x = rect.x;
            var in_y = rect.y;

            // if(!rect.caught) {
            // // clamp to bounds
            // in_x = Math.min(Math.max(-(width / 2), in_x), mycanvas.width - (width / 2));
            // in_y = Math.min(Math.max(-(width / 2), in_y), mycanvas.height - (width / 2));
            // }
            if(time_scale.snapping && time_scale.synced) {
                in_x = time_scale.nearestDivision(in_x + (width / 2)) - (width / 2);
            }
            in_x = in_x + (width / 2);
            in_y = in_y + (width / 2);
            knobs.ui_knob_change("delay"+(index+1), "Delay_1", time_scale.pixelToTime(in_x));
            knobs.ui_knob_change("delay"+(index+1), 
            time_scale.current_parameter, 
            time_scale.pixelToValue(time_scale.delay_data[index][time_scale.current_parameter].rmin, 
            time_scale.delay_data[index][time_scale.current_parameter].rmax, 
            in_y)); 
            // console.log("parameter map", 
            // time_scale.current_parameter, "value", 
            // time_scale.pixelToValue(in_y),
            // "rect.y", rect.y, "in_y", in_y);
        }

    }
    ParallelAnimation {
        id: backAnim
        SpringAnimation { id: backAnimX; target: rect; property: "x"; duration: 500; spring: 2; damping: 0.2 }
        SpringAnimation { id: backAnimY; target: rect; property: "y"; duration: 500; spring: 2; damping: 0.2 }
    }
}
