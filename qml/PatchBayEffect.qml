import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
// list for inputs, outputs
// each has a type, id, name.  icon? 
// effect has name, internal name / class, id
//
// later exposed parameters
//
import "polyconst.js" as Constants

Rectangle {
    id: rect
    width: 114
    height: 68
    radius: 6
    // color: patch_bay.delete_mode ? Qt.rgba(0.9,0.0,0.0,1.0) : Qt.rgba(0.3,0.3,0.3,1.0)  
    color: Constants.background_color
    z: mouseArea.drag.active ||  mouseArea.pressed || selected ? 4 : 1
    // color: Material.color(time_scale.delay_colors[index])
    // color: Qt.rgba(0, 0, 0, 0)
    // color: setColorAlpha(Material.Pink, 0.1);//Qt.rgba(0.1, 0.1, 0.1, 1);
    property point beginDrag
    property bool caught: false
    property string effect_id
    property string effect_type
    property color effect_color: effect_id in currentEffects && currentEffects[effect_id]["enabled"].value > 0 ? Constants.audio_color : Constants.outline_color
    property bool highlight: false
    property bool selected: false
    property Rectangle cv_area: cv_rec
    property Column inputs: input_rec
    property Column outputs: output_rec
    property bool no_sliders: ["mono_EQ", "stereo_EQ", "input", "output"].indexOf(effect_type) >= 0
    property bool has_ui: ["mono_EQ", "stereo_EQ", "mono_reverb", "stereo_reverb", "true_stereo_reverb",
        "mono_cab", "stereo_cab", "true_stereo_cab"].indexOf(effect_type) >= 0
    property var sliders; 
    // border { width:2; color: Material.color(Material.Cyan, Material.Shade100)}
    Drag.active: mouseArea.drag.active

        // if (effect_type == "stereo_EQ" || effect_type == "mono_EQ"){
        // else if (effect_type == "delay"){

    function hide_sliders(leave_selected) {
        // console.log("hiding sliders");
        if (sliders){
            sliders.destroy();
        }
        if (leave_selected){
            selected = false;
            patch_bay.currentMode = PatchBay.Select;
        }
    }

    function connect_clicked() {
        /*
         * on click, check if we are highlight, if not find source ports 
         * if we are, then we're a current target
         */
        if (!highlight){
            hide_sliders(false);
            knobs.select_effect(true, effect_id)
            patch_bay.list_effect_id = effect_id;
            patch_bay.list_source = true;

            var k = Object.keys(effectPrototypes[effect_type]["outputs"])
            if (k.length > 1 )
            {
                mainStack.push(portSelection);
            } 
            else {
                knobs.set_current_port(true, effect_id, k[0]);
                rep1.model.items_changed();
                patch_bay.externalRefresh();
            }
        } else {
            knobs.select_effect(false, effect_id)
            patch_bay.list_effect_id = effect_id;
            patch_bay.list_source = false;
            var source_port_pair = connectSourcePort.name.split("/")
            var source_port_type = effectPrototypes[currentEffects[source_port_pair[0]]["effect_type"]]["outputs"][source_port_pair[1]][1]

            var k;
            var matched = 0;
            var matched_id = 0;
            k = Object.keys(effectPrototypes[effect_type]["inputs"])
            for (var i in k) {
                console.log("port name is ", i);
                if (effectPrototypes[effect_type]["inputs"][k[i]][1] == source_port_type){
                    matched++;
                    matched_id = i;
                }
            }
            if (matched > 1 )
            {
                mainStack.push(portSelection);
            } 
            else {
                knobs.set_current_port(false, effect_id, k[matched_id]);
                rep1.model.items_changed();
                patch_bay.externalRefresh();
            }
        }

    }

    function delete_clicked() {
        // delete current effect
        // console.log("clicked", display);
        // rep1.model.remove_effect(display)
        console.log("deleting", effect_id);
        knobs.remove_effect(effect_id);
        patch_bay.externalRefresh();
        hide_sliders(true);
    }

    function expand_clicked () {
        patch_bay.currentMode = PatchBay.Details;
        if (effect_type == "stereo_EQ" || effect_type == "mono_EQ"){
            patchStack.push("EQWidget.qml", {"effect": effect_id});
        }
        else if (effect_type == "delay"){
            patchStack.push(editDelay);
        }
        else if (effect_type == "mono_reverb" || effect_type == "stereo_reverb" || effect_type == "true_stereo_reverb")
        {
            patchStack.push("ReverbBrowser.qml", {"effect": effect_id, 
            "top_folder": "file:///audio/reverbs",
            "after_file_selected": (function(name) { 
                // console.log("got new reveb file");
                // console.log("file is", name.toString());
                knobs.update_ir(effect_id, name.toString());
                })
            });
        }
        else if (effect_type == "mono_cab" || effect_type == "stereo_cab" || effect_type == "true_stereo_cab"){
            patchStack.push("ReverbBrowser.qml", {"effect": effect_id, 
            "top_folder": "file:///audio/cabs",
            "after_file_selected": (function(name) { 
                // console.log("got new reveb file");
                // console.log("file is", name.toString());
                knobs.update_ir(effect_id, name.toString());
                })
            });
        }
        else if (effect_type == "input" || effect_type == "output"){
            // pass
        } else {
            // mainStack.push(editGeneric);
        }
    }

    function disconnect_clicked()
    {
        /*
         * on click, if there's just one port then connected then disconnect it
         * otherwise list connected
         */
        knobs.list_connected(effect_id);
        // * on click if highlighted (valid port)
        // * show select target port if port count > 1
        patch_bay.list_effect_id = effect_id;
        patch_bay.list_source = false;
        hide_sliders(true);
        mainStack.push(disconnectPortSelection);
        // select target, show popup with target ports
        // } 
        // else {
        // knobs.set_current_port(false, effect_id, ) // XXX

        // }
    }

    function isAudio(item){
        return effectPrototypes[effect_type]["inputs"][item][1] == "AudioPort"
    }

    function isCV(item){
        return effectPrototypes[effect_type]["inputs"][item][1] == "CVPort"
    }

    border { width:2; color: selected ? Constants.accent_color : Constants.outline_color}

    Column {
        id: output_rec
        width:5
        y:20
        anchors.left: parent.left
        spacing: 4
        Repeater {
            id: outputRep
            model: Object.keys(effectPrototypes[effect_type]["outputs"]) 
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 0
                width: 2
                height: 8
                color: effectPrototypes[effect_type]["outputs"][modelData][1] == "AudioPort" ? Constants.audio_color : Constants.cv_color
            }
        }
    }

    Column {
        id: input_rec
        width:5
        anchors.right: parent.right
        spacing: 4
        y:20
        Repeater {
            id: inputRep
            model: Object.keys(effectPrototypes[effect_type]["inputs"]).filter(isAudio) 
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 0
                width: 2
                height: 8
                color: highlight ? Constants.accent_color : Constants.audio_color
            }
        }
	}

    Rectangle {
        id: cv_rec
        visible: Object.keys(effectPrototypes[effect_type]["controls"]).length > 0
        anchors.verticalCenter: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 30
        height: 30
        radius: 15
        color: Constants.background_color
        border { width:2; color: Constants.cv_color}
        Label {
            anchors.centerIn: parent
            text: Object.keys(effectPrototypes[effect_type]["controls"]).length
            // height: 15
            color: Constants.cv_color
            font {
                // pixelSize: fontSizeMedium
                pixelSize: 18
                capitalization: Font.AllUppercase
            }
        }
    }

    Label {
        width: rect.width-4
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        text: effect_id.replace(/_/g, " ")
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        height: 36
        color: effect_color
        lineHeight: 0.9
        font {
            // pixelSize: fontSizeMedium
            family: mainFont.name
            pixelSize: 17
            capitalization: Font.AllUppercase
            letterSpacing: -1
        }
    }
    //
    MouseArea {
        id: mouseArea
        z: -1
        anchors.fill: parent
        // drag.target: patch_bay.current_mode == PatchBay.Move ? parent : undefined
        drag.target: parent 
        onPressed: {
            // check mode: move, delete, connect, open
            rect.beginDrag = Qt.point(rect.x, rect.y);
			console.log("effect proto", Object.keys(effectPrototypes[effect_type]["inputs"]))

            if (patch_bay.currentMode == PatchBay.Connect){
                connect_clicked();
            }
            else if (patch_bay.currentMode == PatchBay.Move){
				patch_bay.isMoving = true;
				patch_bay.externalRefresh();
			}
            else if (patch_bay.currentMode == PatchBay.Select){
                selected = true
                patch_bay.selected_effect = rect
                // bring up sliders/controls, and icons
                // if we're past left of center sliders on right
                // else sliders on left
                // selected changes z via binding
                if (rect.x > 582){
                    if (! no_sliders){
                        sliders = editGeneric.createObject(patch_bay, {x: Math.max(rect.x - 600, 50) , y: 0});
                    }
                    if (rect.x + 130 > 1200){
                        action_icons.x = rect.x - 90; // bound max
                    }
                    else {
                        action_icons.x = rect.x + 130;
                    }
                } else {
                    if (! no_sliders){
                        sliders = editGeneric.createObject(patch_bay, {x: Math.min(rect.x + 220, 790) , y: 0});
                    }
                    action_icons.x = rect.x - 90; // and min
                    if (rect.x - 90 < 10){
                        action_icons.x = rect.x + 130; // bound max
                    }
                    else {
                        action_icons.x = rect.x - 90; // bound max
                    }
                }
                patch_bay.currentMode = PatchBay.Sliders;
            }
        }
        onDoubleClicked: {
            // time_scale.current_delay = index;
            // mainStack.push(editDelay);
            // mappingPopup.set_mapping_choice("delay"+(index+1), "Delay_1", "TIME", 
            //     "delay"+(index+1), time_scale.current_parameter, 
            //     time_scale.inv_parameter_map[time_scale.current_parameter], false);    
            // remove MIDI mapping
            // add MIDI mapping
        }
        onReleased: {
            // var in_x = rect.x;
            // var in_y = rect.y;
            if (patch_bay.currentMode == PatchBay.Move){
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

        Component {
            id: editDelay
            Item {
                height:700
                width:1280
                Column {
                    width: 1100
                    spacing: 20
                    anchors.centerIn: parent
                
                    GlowingLabel {
                        color: "#ffffff"
                        text: effect_id
                        font {
                            pixelSize: fontSizeLarge
                        }
                    }
                    // property var parameter_map: {"LEVEL":"Amp_5", "TONE":"", "FEEDBACK": "", 
                    //                 "GLIDE": "", "WARP":""  }
                    DelayRow {
                        row_param: "Delay_1"
						current_effect: effect_id
                    }
                    Row {
                        height: 40
                        spacing: 25

                        Slider {
                            title: "TIME (ms)" 
                            width: 625
							value: currentEffects[effect_id]["controls"]["Delay_1"].value
							from: currentEffects[effect_id]["controls"]["Delay_1"].rmin
							to: currentEffects[effect_id]["controls"]["Delay_1"].rmax
                            onMoved: {
								knobs.ui_knob_change(effect_id, "Delay_1", value);
                            }

                        }

                        SpinBox {
                            value: currentEffects[effect_id]["controls"]["Delay_1"].value * (60 / currentBPM.value) * 1000
                            from: currentEffects[effect_id]["controls"]["Delay_1"].rmin * (60 / currentBPM.value) * 1000
                            to:  currentEffects[effect_id]["controls"]["Delay_1"].rmax * (60 / currentBPM.value) * 1000
                            stepSize: 10
                            // editable: true
                            onValueModified: {
								knobs.ui_knob_change(effect_id, "Delay_1", value / 1000 / (60 / currentBPM.value));
                            }
                        }
                    }
                    DelayRow {
                        row_param: "Amp_5"
						current_effect: effect_id
                    }
                    DelayRow {
                        row_param: "FeedbackSm_6"
						current_effect: effect_id
                    }
                    DelayRow {
                        row_param: "Feedback_4"
						current_effect: effect_id
                    }
                    DelayRow {
                        row_param: "DelayT60_3"
						current_effect: effect_id
                    }
                    DelayRow {
                        row_param: "Warp_2"
						current_effect: effect_id
                    }
                    // DelayRow {
                    //     row_param: "carla_level"
                    // }
                }
                

                Button {
                    font {
                        pixelSize: fontSizeMedium
                    }
                    text: "BACK"
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.topMargin: 10
                    width: 100
                    height: 100
                    onClicked: mainStack.pop()
                }
            }
        }

        Component {
            id: editGeneric
            Item {
                z: 3
                height:540
                width:500
                Column {
                    width: 500
                    spacing: 20
                    anchors.centerIn: parent

                    Switch {
                        text: qsTr("BYPASS")
                        font.pixelSize: baseFontSize
                        width: 190
                        checked: currentEffects[effect_id]["enabled"].value
                        onClicked: {
                            knobs.set_bypass(effect_id, checked); 
                            // mycanvas.requestPaint();
                        }
                    }


					Repeater {
						model: Object.keys(currentEffects[effect_id]["controls"])
						DelayRow {
							row_param: modelData
							current_effect: effect_id
						}
					}
                }
                
            }
        }

}
