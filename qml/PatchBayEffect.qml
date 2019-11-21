import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
// list for inputs, outputs
// each has a type, id, name.  icon? 
// effect has name, internal name / class, id
//
// later exposed parameters
//

Rectangle {
    id: rect
    width: 200
    height: 100
    radius: 10
    // color: patch_bay.delete_mode ? Qt.rgba(0.9,0.0,0.0,1.0) : Qt.rgba(0.3,0.3,0.3,1.0)  
    color: highlight ? Qt.rgba(0.9,0.0,0.0,1.0) : Qt.rgba(0.3,0.3,0.3,1.0)  
    z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
    // color: Material.color(time_scale.delay_colors[index])
    // color: Qt.rgba(0, 0, 0, 0)
    // color: setColorAlpha(Material.Pink, 0.1);//Qt.rgba(0.1, 0.1, 0.1, 1);
    property point beginDrag
    property bool caught: false
    property string effect_id
    property string effect_type
    property bool highlight: false
    // border { width:1; color: Material.color(Material.Cyan, Material.Shade100)}
    // border { width:2; color: Material.color(Material.Pink, Material.Shade200)}
    Drag.active: mouseArea.drag.active

	Column {
		width:20
		Repeater {
			id: outputRep
			model: Object.keys(effectPrototypes[effect_type]["outputs"]) 
			Button {
				anchors.left: parent.left
				anchors.leftMargin: 5
				// text: "<"
				background: Rectangle {
					anchors.left: parent.left
					anchors.leftMargin: 5
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
			}
			// onItemAdded: {
			// 	if ("invalid" in effect_map){
			// 		delete effect_map["invalid"];
			// 	}
			// 	// console.log("added", index, item.effect_id);
			// 	effect_map[item.effect_id] = item;
			// 	// console.log(Object.keys(effect_map)); //[item.effect_id]);
			// }
		}
	}
    // Button {
    //     anchors.left: parent.left
    //     anchors.leftMargin: 5
    //     icon.name: "md-arrow-back"
    //     width: 45
    //     height: 45
    //     // On click make this the current patch source, highlight this and possible targets
    //     // port id
    //     // creates new path element / connection
    //     // text: "<"
    //     // background: Rectangle {
    //     //     // anchors.left: parent.left
    //     //     // anchors.leftMargin: 0
    //     //     width: 20
    //     //     height: 20
    //     //     radius: 20
    //     //     // color: Material.color(Material.Pink, Material.Shade200)
    //     //     color: setColorAlpha(Material.color(Material.Pink, Material.Shade200), 0.2)
    //     //     border {
    //     //         color: Material.color(Material.Pink, Material.Shade200);
    //     //         width: 1
    //     //     }
    //     // }
    // }

	Column {
		width:20
		anchors.right: parent.right
		Column {
			width:20
			anchors.right: parent.right
			Repeater {
				id: inputRep
				model: Object.keys(effectPrototypes[effect_type]["inputs"]) 
				Button {
					anchors.right: parent.right
					anchors.rightMargin: 35
					// text: "<"
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
				}
			}
		}
		// Column {
		// 	width:20
		// 	anchors.right: parent.right
		// 	spacing: 0
		// 	Repeater {
		// 		id: controlRep
		// 		model: Object.keys(effectPrototypes[effect_type]["controls"]) 
		// 		Button {
		// 			height: 10
		// 			anchors.right: parent.right
		// 			anchors.rightMargin: 35
		// 			// text: "<"
		// 			background: Rectangle {
		// 				anchors.right: parent.right
		// 				anchors.rightMargin: -25
		// 				y:5
		// 				width: 10
		// 				height: 10
		// 				radius: 10
		// 				// color: Material.color(Material.Pink, Material.Shade200)
		// 				color: setColorAlpha(Material.color(Material.Indigo, Material.Shade200), 0.2)
		// 				border {
		// 					color: Material.color(Material.Indigo, Material.Shade200);
		// 					width: 1
		// 				}
		// 			}
		// 		}
		// 	}
		// }
	}

    Label {
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
        text: effect_id
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
			console.log("effect proto", Object.keys(effectPrototypes[effect_type]["inputs"]))

			if (patch_bay.connect_mode){

				/*
				 * on click, check if we are highlight, if not find source ports 
				 * if we are, then we're a current target
				 */
				if (!highlight){
					knobs.select_effect(true, effect_id)
					// if (selectedEffectPorts.count > 1){
						patch_bay.list_effect_id = effect_id;
						patch_bay.list_source = true;
						mainStack.push(portSelection);
						// select source, show popup with source ports
					// } 
					// else {
					//     knobs.set_current_port(true, effect_id, selectedEffectPorts[0]);
					// }
				} else {
					knobs.select_effect(false, effect_id)
					 // * on click if highlighted (valid port)
					 // * show select target port if port count > 1
						patch_bay.list_effect_id = effect_id;
						patch_bay.list_source = false;
						mainStack.push(portSelection);
						// select target, show popup with target ports
					// } 
					// else {
						// knobs.set_current_port(false, effect_id, ) // XXX

					// }
				}
			}
			else if (patch_bay.move_mode) {
				patch_bay.isMoving = true;
				patch_bay.externalRefresh();
			}
			else if (patch_bay.delete_mode) {
				// delete current effect
				// console.log("clicked", display);
				// rep1.model.remove_effect(display)
				console.log("deleting", effect_id);
				knobs.remove_effect(effect_id);
				patch_bay.externalRefresh();
			}
			else if (patch_bay.expand_mode) {
				mainStack.push(editDelay);
				patch_bay.externalRefresh();
			}
             // * 
             // * effect_connections[(effect_id, port_id)].append((target_effect_id, target_port_id))
             // *  
             // * for conn in effect_connections:
             // *  draw arc
             // */
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
            // var in_x = rect.x;
            // var in_y = rect.y;
			if (patch_bay.move_mode){
				patch_bay.isMoving = false;
				patch_bay.externalRefresh();
				knobs.move_effect(effect_id, rect.x, rect.y)
			
			}

            // if(!rect.caught) {
            // // clamp to bounds
            // in_x = Math.min(Math.max(-(width / 2), in_x), mycanvas.width - (width / 2));
            // in_y = Math.min(Math.max(-(width / 2), in_y), mycanvas.height - (width / 2));
            // }
            // if(time_scale.snapping && time_scale.synced) {
            //     in_x = time_scale.nearestDivision(in_x + (width / 2)) - (width / 2);
            // }
            // in_x = in_x + (width / 2);
            // in_y = in_y + (width / 2);
            // knobs.ui_knob_change("delay"+(index+1), "Delay_1", time_scale.pixelToTime(in_x));
            // knobs.ui_knob_change("delay"+(index+1), 
            // time_scale.current_parameter, 
            // time_scale.pixelToValue(time_scale.delay_data[index][time_scale.current_parameter].rmin, 
            // time_scale.delay_data[index][time_scale.current_parameter].rmax, 
            // in_y)); 
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
