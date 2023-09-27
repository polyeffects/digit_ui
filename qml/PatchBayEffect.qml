import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.VirtualKeyboard 2.1

import QtQuick.Layouts 1.3
// list for inputs, outputs
// each has a type, id, name.  icon? 
// effect has name, internal name / class, id
//
// later exposed parameters
//
import "polyconst.js" as Constants
import "plaits_names.js" as PlaitsNames
import "module_info.js" as ModuleInfo

Rectangle {
    id: rect
    // color: patch_bay.delete_mode ? Qt.rgba(0.9,0.0,0.0,1.0) : Qt.rgba(0.3,0.3,0.3,1.0)  
    // z: mouseArea.drag.active ||  mouseArea.pressed || selected ? 4 : 1
    // color: Material.color(time_scale.delay_colors[index])
    // color: Qt.rgba(0, 0, 0, 0)
    // color: setColorAlpha(Material.Pink, 0.1);//Qt.rgba(0.1, 0.1, 0.1, 1);
    property vector2d beginDrag
    property bool caught: false
    property string effect_id
    property string effect_type
    property color effect_color: effect_id in currentEffects && currentEffects[effect_id]["enabled"].value > 0 ? "white" : Constants.outline_color
    property bool selected: false
    property Rectangle cv_area: cv_rec
    property Column inputs: input_rec
    property Column outputs: output_rec
	property real current_subdivision: 1.0 
	property int rotaryTabIndex: 0
	property bool set_hold: false
	property bool was_hold: false
	property bool is_pressed: false
    property bool is_io: ["input", "output", "midi_input", "midi_output"].indexOf(effect_type) >= 0

    color: is_pressed ? accent_color.name : is_io ? Constants.poly_very_dark_grey : !effect_type.startsWith("foot_switch_") ? Constants.background_color : currentEffects[effect_id]["controls"]["cur_out"].value > 0.9 ? Constants.cv_color : Constants.background_color

    function isAudio(item){
        return ModuleInfo.effectPrototypes[effect_type]["inputs"][item][1] == "AudioPort"
    }

    function isCV(item){
        return ModuleInfo.effectPrototypes[effect_type]["inputs"][item][1] == "CVPort"
    }

    function isMIDI(item){
        return ModuleInfo.effectPrototypes[effect_type]["inputs"][item][1] == "AtomPort"
    }

    function isRightInput(item){
        return ["AtomPort", "AudioPort"].indexOf(ModuleInfo.effectPrototypes[effect_type]["inputs"][item][1]) >= 0
    }


	function isSpecialWarpsParam(item){
		return ['int_osc', 'space_size', 'mode', 'algorithm', 'shape'].indexOf(item) < 0;
	}

    property var input_keys: Object.keys(ModuleInfo.effectPrototypes[effect_type]["inputs"]).filter(isRightInput) 
    property var output_keys: Object.keys(ModuleInfo.effectPrototypes[effect_type]["outputs"])
    property bool has_ui: ['bitmangle', 'comparator', 'chebyschev_waveshaper', 'meta_modulation', 'wavefolder', 'vocoder', 'doppler_panner', 'twist_delay', 'frequency_shifter', 'rotary_advanced'].indexOf(effect_type) >= 0
    property var sliders; 
    // border { width:2; color: Material.color(Material.Cyan, Material.Shade100)}
    // Drag.active: mouseArea.drag.active

    // width: (effect_id.length * 1.6) + 100
    width: 115
    // height: is_io ? 80 : 68
    height: output_keys.length > 2 || input_keys.length > 2 ? (Math.max(output_keys.length, input_keys.length)- 1)*18 + 72 : is_io ? 58 : 72
    // spacing: 14
    radius: 6

        // if (effect_type == "stereo_EQ" || effect_type == "mono_EQ"){
        // else if (effect_type == "delay"){

    function hide_sliders(leave_selected) {
		patchStack.pop()

        if (leave_selected){
            selected = false;
            patch_bay.currentMode = PatchBay.Select;
            patch_bay.selected_effect = null;
            patch_bay.current_help_text = Constants.help["select"];
        }
    }

    function back_action() {
		patchStack.pop()
		if (patchStack.currentItem instanceof PatchBay){
            selected = false;
            patch_bay.currentMode = PatchBay.Select;
            patch_bay.selected_effect = null;
            patch_bay.current_help_text = Constants.help["select"];
        }
    }

    // function self_destruct() {
    //     // console.log("self destruct called");
    //     rect.destroy(1);
    //     // console.log("self destruct done");
    // }

    Component.onDestruction: {
        // console.log("destroying patchbayeffect component");
        selected = false;
        patch_bay.currentMode = PatchBay.Select;
        patch_bay.current_help_text = Constants.help["select"];
        patch_bay.selected_effect = null;
    }

    function rsplit(str, sep, maxsplit) {
        var split = str.split(sep);
        return maxsplit ? [ split.slice(0, -maxsplit).join(sep) ].concat(split.slice(-maxsplit)) : split;
    }

    property string effect_title: rsplit(effect_id, "/", 1)[1].replace(/_/g, " ").replace(/1$/, '');

    function two_finger_connect_clicked(first) {
        /*
         * on click, check if we are highlight, if not find source ports 
         * if we are, then we're a current target
         */
        if (first){
			patch_bay.from_hold = true;
            var k = output_keys;
            if (k.length == 0){
                return;
            }

            selected = false
            patch_bay.selected_effect = rect
        } else {
            // patch_bay.selected_effect.selected = false;
            var k = patch_bay.selected_effect.output_keys;
            if (k.length == 0){
                return;
            }

            knobs.select_effect(true, patch_bay.selected_effect.effect_id, interconnect)
            patch_bay.list_source_effect_id = patch_bay.selected_effect.effect_id;
			patch_bay.source_selected = false;

            if (k.length > 1 )
            {
				patch_bay.source_selected = false;
            } 
            else if (k.length == 1) {
                knobs.set_current_port(true, patch_bay.selected_effect.effect_id, k[0]);
                // rep1.model.items_changed();
                patch_bay.externalRefresh();
				patch_bay.source_selected = true;
            }
            // 

            patch_bay.list_dest_effect_id = effect_id;
            patch_bay.list_dest_effect_type = effect_type;

            patch_bay.selected_effect.is_pressed = false;
			
			if (!patch_bay.source_selected){
                rect.is_pressed = false;
				mainStack.push(sourcePortSelection);
				return;
			}
            knobs.select_effect(false, effect_id, interconnect)

            var source_port_pair = rsplit(connectSourcePort.name, "/", 1)
            var source_port_type = ModuleInfo.effectPrototypes[currentEffects[source_port_pair[0]]["effect_type"]]["outputs"][source_port_pair[1]][1]

            var k;
            var matched = 0;
            var matched_id = 0;
            // console.log("source port ", source_port_pair);
            // console.log("two finger connect source port ", effect_id);
            k = Object.keys(ModuleInfo.effectPrototypes[effect_type]["inputs"])

            if (interconnect && ["AtomPort", "ControlPort"].indexOf(source_port_type) < 0){
                matched = k.length;
            }
            else if (currentPedalModel.name == "hector"){
                if (currentEffects[source_port_pair[0]]["effect_type"] == "input" || effect_type == "output"){
                    matched = k.length;
                    // console.log("matched, hector", matched);

                } else {
                    for (var i in k) {
                        // console.log("port name is ", i[k]);
                        if (ModuleInfo.effectPrototypes[effect_type]["inputs"][k[i]][1] == source_port_type){
                            matched++;
                            matched_id = i;
                        }
                    }
                    // console.log("not matched, hector", matched);
                }
            } else {
                for (var i in k) {
                    // console.log("port name is ", i[k]);
                    if (ModuleInfo.effectPrototypes[effect_type]["inputs"][k[i]][1] == source_port_type){
                        matched++;
                        matched_id = i;
                    }
                }
                // console.log("not hector", matched);
            } 
            // console.log("final matched", matched);
            if (matched > 1 )
            {
                rect.is_pressed = false;
                mainStack.push(destPortSelection);
                patch_bay.current_help_text = ""
            } 
            else if (matched == 1){
                knobs.set_current_port(false, effect_id, k[matched_id]);
                // rep1.model.items_changed();
                patch_bay.externalRefresh();
                // patch_bay.currentMode = PatchBay.Select;
				// patch_bay.current_help_text = Constants.help["select"];
            }
        }

    }


    function delete_clicked() {
        // delete current effect
        // console.log("clicked", display);
        // rep1.model.remove_effect(display)
        hide_sliders(true);
        // console.log("deleting", effect_id);
        knobs.remove_effect(effect_id);
    }

    function expand_clicked () {
        knobs.clear_knob_effect();
        patch_bay.currentMode = PatchBay.Details;
		title_text = effect_type.replace(/_/g, " ")

        if (effect_type == "stereo_EQ" || effect_type == "mono_EQ"){
            patchStack.push("EQWidget.qml", {"effect": effect_id});
            patch_bay.current_help_text = Constants.help["eq_detail"];
        }
        else if (effect_type == "step_sequencer"){
            patchStack.push("StepSequencer.qml", {"effect": effect_id, "effect_type":"step_sequencer"});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "step_sequencer_ext"){
            patchStack.push("StepSequencer.qml", {"effect": effect_id});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "note_sequencer"){
            patchStack.push("NoteSequencer.qml", {"effect": effect_id, "effect_type":"note_sequencer"});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "note_sequencer_ext"){
            patchStack.push("NoteSequencer.qml", {"effect": effect_id, "effect_type":"note_sequencer_ext"});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "chaos_controller"){
            patchStack.push("Marbles.qml", {"effect_id": effect_id});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "looping_envelope"){
            patchStack.push("Tides.qml", {"effect_id": effect_id});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "tuner"){
            patchStack.push("Tuner.qml", {"effect": effect_id});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "delay"){
            patchStack.push(editDelay);
            patch_bay.current_help_text = Constants.help["delay_detail"];
        }
        else if (effect_type == "bitcrushed_delay"){
            patchStack.push(editBitcrushedDelay);
            patch_bay.current_help_text = ""//Constants.help["delay_detail"];
        }
        else if (effect_type == "lfo"){
            patchStack.push(editLfo);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        }
        else if (effect_type == "cv_meter"){
            patchStack.push(editCVMeter);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        }
        else if (effect_type == "pitch_cal_in"){
            patchStack.push(editPitchCalIn);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        }
        else if (effect_type == "pitch_cal_out"){
            patchStack.push(editPitchCalOut);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        }
		else if (effect_type == "rotary_advanced"){
            patchStack.push(editAdvancedRotary, {"objectName":"editAdvancedRotary"});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		}
		else if (effect_type == "rotary"){
            patchStack.push(editBasicRotary, {"objectName":"editBasicRotary"});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		}
		else if (effect_type == "macro_osc"){
            patchStack.push(editPlaits, {"objectName":"editPlaits"});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		}
		else if (['granular'].indexOf(effect_type) >= 0){
            patchStack.push(editGranular);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		}
		else if (['pitch_verb', 'granular_looping', 'resonestor', 'spectral_twist', 'time_stretch', 'beat_repeat'].indexOf(effect_type) >= 0){
            patchStack.push(editClouds);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		}
		else if (['bitmangle', 'comparator', 'chebyschev_waveshaper', 'wavefolder', 'vocoder', 'doppler_panner', 'twist_delay', 'frequency_shifter'].indexOf(effect_type) >= 0){
            patchStack.push(editWarps);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		}
		else if (effect_type == 'meta_modulation'){
            patchStack.push(editWarpsMeta, {"objectName":"editWarpsMeta"});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		}
        else if (effect_type == "mono_reverb" || effect_type == "stereo_reverb" || effect_type == "quad_ir_reverb")
        {
            patch_bay.current_help_text = Constants.help["reverb_detail"];
            patchStack.push("ReverbBrowser.qml", {"effect": effect_id,  "effect_type": effect_type,
            "top_folder": "file:///audio/reverbs/",
            "is_cab": false,
            "after_file_selected": (function(name) { 
                // console.log("got new reveb file");
                // console.log("file is", name.toString());
                knobs.update_ir(effect_id, name.toString());
                })
            });
        }
        // else if (effect_type == "amp_rtneural")
        // {
        //     patch_bay.current_help_text = Constants.help["reverb_detail"];
        //     patchStack.push("ReverbBrowser.qml", {"effect": effect_id,  "effect_type": effect_type,
        //     "top_folder": "file:///audio/amp_json",
        //     "after_file_selected": (function(name) { 
        //         // console.log("got new reveb file");
        //         // console.log("file is", name.toString());
        //         knobs.update_json(effect_id, name.toString());
        //         })
        //     });
        // }
        else if (effect_type == "amp_nam")
        {
            patch_bay.current_help_text = ""
            patchStack.push("AmpBrowser.qml", {"effect": effect_id,  "effect_type": effect_type,
            "top_folder": "file:///audio/amp_nam",
            // "after_file_selected": (function(name) { 
            //     // console.log("got new reveb file");
            //     // console.log("file is", name.toString());
            //     knobs.update_json(effect_id, name.toString());
            //     })
            });
        }
        else if (effect_type == "mono_cab" || effect_type == "stereo_cab" || effect_type == "quad_ir_cab"){
            patch_bay.current_help_text = Constants.help["reverb_detail"];
            patchStack.push("ReverbBrowser.qml", {"effect": effect_id, "effect_type": effect_type,
            "top_folder": "file:///audio/cabs/",
            "is_cab": true,
            "after_file_selected": (function(name) { 
                // console.log("got new reveb file");
                // console.log("file is", name.toString());
                knobs.update_ir(effect_id, name.toString());
                })
            });
        }
        else if (effect_type == "quantizer"){
            patchStack.push(editQuantizer);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        }
        else if (effect_type == "matrix_mixer"){
            patchStack.push(editMixer);
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        }
        else if (effect_type == "multi_resonator"){
            patchStack.push("Rings.qml", {"effect_id": effect_id});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        }
		else if (['loop_common_in', 'loop_common_out', 'loop_extra_midi', 'loop_midi_out'].indexOf(effect_type) >= 0){
            title_text = "Loopler"
            patchStack.push("Loopler.qml");
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "strum"){
            patchStack.push("Strum.qml", {"effect": effect_id, "effect_type":"strum"});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
        else if (effect_type == "euclidean"){
            // title_text = "Loopler"
            patchStack.push("EuclideanSequencer.qml", {"effect": effect_id});
            patch_bay.current_help_text = "" // Constants.help[""];
        }
		else if (['input', 'output', 'midi_input', 'midi_output'].indexOf(effect_type) >= 0){
            // patchStack.push(editIO);
            disconnect_clicked();
            // patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        } else {
			patch_bay.current_help_text = Constants.help["sliders"];
            patchStack.push(editGeneric);
        }
    }

	function show_advanced_special_clicked(){
		if (['bitmangle', 'comparator', 'chebyschev_waveshaper', 'wavefolder', 'vocoder'].indexOf(effect_type) >= 0){
            patchStack.push("IconSelector.qml", {"current_effect": effect_id, "row_param": "int_osc", "icons": ["OFF.png", "Sine.png", "Sawtooth.png", "Triangle.png"]});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "twist_delay") {
            patchStack.push("IconSelector.qml", {"current_effect": effect_id, "row_param": "mode", "icons": ["Open FB Loop.png", "Dual Delay.png", "Tape Delay.png", "Ping Pong.png"]});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "frequency_shifter") {
            patchStack.push("IconSelector.qml", {"current_effect": effect_id, "row_param": "mode", "icons": ["OFF.png", "Sin.png", "2 Harmonics.png", "4 Harmonics.png"]});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "doppler_panner") {
            patchStack.push("IconSelector.qml", {"current_effect": effect_id, "row_param": "space_size", "icons": ["Small.png", "Medium.png", "Large.png", "XL.png"]});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "meta_modulation") {
			if (patchStack.currentItem.objectName == "editWarpsMeta"){
				patchStack.push(editWarps);
				patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
			} else {
				patchStack.push("IconSelector.qml", {"current_effect": effect_id, "row_param": "shape", "icons": ["OFF.png", "Sine.png", "Sawtooth.png", "Triangle.png"]});
			}
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "rotary_advanced") {
			if (patchStack.currentItem.objectName == "editAdvancedRotary"){
				patch_bay.current_help_text = "Changing any of these values will reinitialize the module and sound will fade out."
				patchStack.push(editAdvancedRotaryExtra, {"objectName":"editAdvancedRotaryExtra"});
			} else {
				patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
				// patchStack.push(editAdvancedRotary, {"objectName":"editAdvancedRotary"});
				patchStack.pop()
			}
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		}
	}

	function whirl_speed_clicked(speed){
		var s = currentEffects[effect_id]["controls"]["rt_speed"].value; 
		var h = Math.floor(s / 3);
		var d = s % 3;
		
		if (rotaryTabIndex == 0){
			h = speed;
		}
		else {
			d = speed;
		}
		knobs.ui_knob_change(effect_id, "rt_speed", (h*3)+d);
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
        patch_bay.list_source_effect_id = effect_id;
        hide_sliders(true);

        // if (selectedSourceEffectPorts.rowCount() == 1)
        mainStack.push(disconnectPortSelection);
        // select target, show popup with target ports
        // } 
        // else {
        // knobs.set_current_port(false, effect_id, ) // XXX

        // }
    }


    border { 
        width: !is_io || patch_bay.selected_effect == rect ? 2 : 0; 
        color: patch_bay.selected_effect == rect ? accent_color.name : "white"
    }

    Column {
        id: output_rec
        width:10
        y:14
        anchors.right: lToR.value ? parent.right : undefined
        anchors.left: lToR.value ? undefined : parent.left
        spacing: 6
        Repeater {
            id: outputRep
            model: output_keys
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: lToR.value ? 0 : -8
                width: 18
                height: 18
                radius: 9
                color: Constants.background_color
                // border { width:4; color: Constants.background_color}
                Rectangle {
                    anchors.centerIn: parent
                    radius: 5
                    width: 10
                    height: 10
                    color: Constants.port_color_map[ModuleInfo.effectPrototypes[effect_type]["outputs"][modelData][1]]
                }
            }
        }
    }

    Column {
        id: input_rec
        width:10
        anchors.right: lToR.value ? undefined : parent.right
        anchors.left: lToR.value ? parent.left : undefined
        spacing: 6
        y:14
        Repeater {
            id: inputRep
            model: input_keys
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: lToR.value ? 0 : -8
                width: 18
                height: 18
                radius: 9
                color: Constants.background_color
                Rectangle {
                    anchors.centerIn: parent
                    radius: 5
                    width: 10
                    height: 10
                    color: Constants.port_color_map[ModuleInfo.effectPrototypes[effect_type]["inputs"][modelData][1]]
                }
            }
        }
	}

    Rectangle {
        id: cv_rec
        visible: ModuleInfo.effectPrototypes[effect_type]["num_cv_in"] > 0
        anchors.verticalCenter: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 22
        height: 22
        radius: 11
        color: Constants.background_color
        border { width:2; color: Constants.cv_color}
        Label {
            width: 20
            height: 20
            anchors.centerIn: parent
            text: ModuleInfo.effectPrototypes[effect_type]["num_cv_in"]
            // height: 15
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white" //Constants.cv_color
            font {
                // pixelSize: fontSizeMedium
                pixelSize: 16
                capitalization: Font.AllUppercase
            }
        }
    }

    Rectangle {
        id: footswitch_rec
        visible: effect_id in currentEffects && currentEffects[effect_id]["assigned_footswitch"].value != ""
        anchors.verticalCenter: parent.bottom
        x: 11
        width: 22
        height: 22
        radius: 11
        color: Constants.background_color
        border { width:2; color: "#AC8EFF" }
        Label {
            width: 20
            height: 20
            anchors.centerIn: parent
            text: effect_id in currentEffects ? currentEffects[effect_id]["assigned_footswitch"].value : ""
            // height: 15
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "white" //Constants.cv_color
            font {
                // pixelSize: fontSizeMedium
                pixelSize: 16
                capitalization: Font.AllUppercase
            }
        }
    }

    Label {
        width: 84
        height: 56
        anchors.top: parent.top
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: !rect.is_io ? effect_title : effect_title == "midi in" || effect_title == "midi out" ? "M" : effect_title.slice(-1) == " " ? "1" : effect_title.slice(-1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        color: is_pressed ? Constants.background_color : effect_color 
        lineHeight: 0.65
        fontSizeMode: Text.Fit 
        minimumPixelSize: 16
        font {
            // pixelSize: fontSizeMedium
            family: mainFont.name
            pixelSize: 32
            capitalization: Font.AllUppercase
            letterSpacing: 0
        }
    }
    //
    MultiPointTouchArea {
        id: mouseArea
        z: -1
        anchors.fill: parent
		property var drag: parent
		property var offset: null
        // drag.target: patch_bay.current_mode == PatchBay.Move ? parent : undefined
        // drag.target: !rect.is_io && patch_bay.currentMode == PatchBay.Move ? parent : undefined
        // drag.target: !rect.is_io ? parent : undefined
        // drag.target: parent 
		minimumTouchPoints: 1
		maximumTouchPoints: 1

		function dragMove(holder, point) {
			if (!rect.is_io){
				if (point && drag) {
					var position = holder.mapFromItem(drag, point.x, point.y);
					drag.x = position.x - offset.x;
					drag.y = position.y - offset.y;
				}
			}
		}

		onTouchUpdated: {
			var point = touchPoints[0];
			dragMove(patch_bay, point);
		}

        onPressed: {
            rect.is_pressed = true;
            // check mode: move, delete, connect, open
            rect.beginDrag = Qt.vector2d(rect.x, rect.y);
			var point = touchPoints[0];
			offset = Qt.point(point.x, point.y);
			dragMove(patch_bay, point);
            rect.set_hold = false;
			rect.was_hold = false;
			// console.log("effect proto", Object.keys(effectPrototypes[effect_type]["inputs"]))
            if (patch_bay.currentMode == PatchBay.Select){
                patch_bay.cancel_expand = false;
                // if there isn't a current pressed point, we are the first one,
                // record us and display the hold action
                // if there's an existing point then we're the destination, connect
                patch_bay.selected_effect = rect
                patch_bay.currentMode = PatchBay.Hold;
                rect.set_hold = true;
                rect.was_hold = true;
                two_finger_connect_clicked(true);
                patch_single.current_help_text = Constants.help["hold"];
                patch_bay.multi_touch_connect = false;
            }
			else if (patch_bay.currentMode == PatchBay.Hold){
                patch_bay.cancel_expand = false;
				rect.was_hold = true;
                patch_bay.multi_touch_connect = true;
				two_finger_connect_clicked(false);
			}

            // if (patch_bay.currentMode == PatchBay.Connect){
            //     connect_clicked(false);
            // }
            // else if (patch_bay.currentMode == PatchBay.Move){
				// patch_bay.isMoving = true;
				// patch_bay.externalRefresh();
			// } 
        }

        onReleased: {
            rect.is_pressed = false;
            // var in_x = rect.x;
            // var in_y = rect.y;
			// console.log("on release called");
			patch_bay.isMoving = false;
			// if we set hold, reset to select
			if (rect.set_hold){
                patch_bay.currentMode = PatchBay.Select;
				patch_bay.current_help_text = Constants.help["select"];
                rect.set_hold = false;
			}

			if (!rect.beginDrag.fuzzyEquals(Qt.vector2d(rect.x, rect.y), 6)){
				patch_bay.externalRefresh();
				knobs.move_effect(effect_id, lToR.value ? 1170 - rect.x : rect.x, rect.y)
			} 
			else if (!patch_bay.multi_touch_connect){
				if (patch_bay.currentMode == PatchBay.Select && !patch_bay.cancel_expand){
					selected = true
					patch_bay.selected_effect = rect
					patch_bay.currentMode = PatchBay.Sliders;
					expand_clicked();
				}
			}
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
				Component.onDestruction: {
					// if we're not visable, turn off broadcast
					// console.log("setting broadcast false in step");
					knobs.set_broadcast(effect_id, false);
				}
				Component.onCompleted: {
					// console.log("setting broadcast true in step");
					knobs.set_broadcast(effect_id, true);
				}
                z: 3
                height:540
                width:1280
				
				ActionIcons {

				}

				Column {
					visible: !Qt.inputMethod.visible
					x: 150
					y: 65
					width: 565
					spacing: 20

					Repeater {
						model: ['Amp_5', 'FeedbackSm_6',  'DelayT60_3']
						DelayRow {
							row_param: modelData
							current_effect: effect_id
							Material.foreground: Constants.rainbow[index]
						}
					}
					Row { 
						spacing: 50
						RadioButton {
							id: timeRadio
                            text: qsTr("Time (MS)")
                            font {
                                // family: mainFont.name
                                pixelSize: 24
                                capitalization: Font.AllUppercase
                            }
                            onCheckedChanged: {
                                knobs.ui_knob_change(effect_id, "is_using_tempo", Number(!checked));
                            }
                            Component.onCompleted: checked = currentEffects[effect_id]["controls"]["is_using_tempo"].value < 0.5
						}
						RadioButton {
							id: beatsRadio
							text: qsTr("Beats")
                            font {
                                // family: mainFont.name
                                pixelSize: 24
                                capitalization: Font.AllUppercase
                            }
                            Component.onCompleted: checked = currentEffects[effect_id]["controls"]["is_using_tempo"].value > 0.5
						}
					}

					DelayRow {
						visible: beatsRadio.checked
						row_param: "BPM_0"
						current_effect: effect_id
						Material.foreground: Constants.rainbow[7]
					}

					DelayRow {
						visible: timeRadio.checked
						row_param: "Delay_1"
						current_effect: effect_id
						Material.foreground: Constants.rainbow[7]
					}
				}

				Column {
					x: 676
					y: 65
					width: 565
					spacing: 20

					Repeater {
						model: ['Feedback_4', 'Warp_2']//, 'BPM_0', 'Delay_1',]
						DelayRow {
							visible: !Qt.inputMethod.visible
							row_param: modelData
							current_effect: effect_id
							Material.foreground: Constants.rainbow[index+5]
						}
					}

                    ComboBox {
						visible: beatsRadio.checked
                        // visible: !Qt.inputMethod.visible
						width: 500
						height: 100
                        id: note_subdivisions
						textRole: "text"
                        font {
                            // family: mainFont.name
                            pixelSize: 32
                            capitalization: Font.AllUppercase
                        }
                        delegate: ItemDelegate {
                            width: note_subdivisions.width
                            contentItem: Text {
                                text: modelData.text
                                color: "white"
                                font: note_subdivisions.font
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            highlighted: note_subdivisions.highlightedIndex === index
                        }

						model: [{text: "1/4", value: 1},
						{text: "2/3", value: 8/3.0}, {text: "1/3", value: 4/3.0}, {text: "1/8 .", value: 0.75},
						{text: "PHI", value: 0.618},
					   	{text: "1/8", value: 0.5},  {text: "1/16", value: 0.25}]

						Component.onCompleted: currentIndex = indexForValue(currentEffects[effect_id]["controls"]["Delay_1"].value % 1)
                        onActivated: {
							current_subdivision = model[currentIndex].value;
                            knobs.ui_knob_change(effect_id, "Delay_1", current_subdivision);
                        }

						function indexForValue(value) {
							for (var i = 0; i < model.length; ++i) {
								if (model[i].value === value)
								return i;
							}
							return -1;
						}
                    }

                    Row {
						visible: timeRadio.checked
						spacing: 50
                        Label {
                            text: "MILLISECONDS"
                            height: 60
                            verticalAlignment: Text.AlignVCenter
                            font {
                                // pixelSize: fontSizeMedium
                                family: mainFont.name
                                pixelSize: 28
                                capitalization: Font.AllUppercase
                                letterSpacing: 0
                            }
                        }
                        TextField {
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator{bottom: 0; top: 32000;}
                            width: 121
                            height: 60
                            text: (60.0 / currentEffects[effect_id]["controls"]["BPM_0"].value * currentEffects[effect_id]["controls"]["Delay_1"].value * 1000).toFixed(0) // + " ms"
                            color: "white"
                            font {
                                // pixelSize: fontSizeMedium
                                family: mainFont.name
                                pixelSize: 28
                                capitalization: Font.AllUppercase
                                letterSpacing: 0
                            }
                            onTextEdited: {
                                if (Number(text) > 0 && Number(text) < 32000){
                                    knobs.ui_knob_change(effect_id, "Delay_1", text * currentEffects[effect_id]["controls"]["BPM_0"].value / ( 1000 * 60)) ;
                                }
                            }
                        }
                    }
				}
				InputPanel {
					x: 150
					y: 0
					width: 1130
					id: inputPanel
					// parent:mainWindow.contentItem
					// z: 1000002
					// anchors.bottom:parent.bottom
					// anchors.left: parent.left
					// anchors.right: parent.right
					height: 500

					visible: Qt.inputMethod.visible
				}
                MoreButton {
                    l_effect_type: effect_type
                }
            }
        }

        Component {
            id: editBitcrushedDelay
            Item {
				Component.onDestruction: {
					// if we're not visable, turn off broadcast
					// console.log("setting broadcast false in step");
					knobs.set_broadcast(effect_id, false);
				}
				Component.onCompleted: {
					// console.log("setting broadcast true in step");
					knobs.set_broadcast(effect_id, true);
				}
                z: 3
                height:540
                width:1280
				
				ActionIcons {

				}

				Column {
					visible: !Qt.inputMethod.visible
					x: 150
					y: 65
					width: 565
					spacing: 20

					Repeater {
						model: ['Amp_6', 'FeedbackSm_7',  'DelayT60_4']
						DelayRow {
							row_param: modelData
							current_effect: effect_id
							Material.foreground: Constants.rainbow[index]
						}
					}
					Row { 
						spacing: 50
						RadioButton {
							id: timeRadio
							checked: true
							text: qsTr("Time (MS)")
                            font {
                                // family: mainFont.name
                                pixelSize: 24
                                capitalization: Font.AllUppercase
                            }
                            onCheckedChanged: {
                                knobs.ui_knob_change(effect_id, "is_using_tempo", Number(!checked));
                            }
                            Component.onCompleted: checked = currentEffects[effect_id]["controls"]["is_using_tempo"].value < 0.5
						}
						RadioButton {
							id: beatsRadio
							text: qsTr("Beats")
                            font {
                                // family: mainFont.name
                                pixelSize: 24
                                capitalization: Font.AllUppercase
                            }
                            Component.onCompleted: checked = currentEffects[effect_id]["controls"]["is_using_tempo"].value > 0.5
						}
					}

					DelayRow {
						visible: beatsRadio.checked
						row_param: "BPM_1"
						current_effect: effect_id
						Material.foreground: Constants.rainbow[7]
					}

					DelayRow {
						visible: timeRadio.checked
						row_param: "Delay_2"
						current_effect: effect_id
						Material.foreground: Constants.rainbow[7]
					}
				}

				Column {
					x: 676
					y: 65
					width: 565
					spacing: 20

					Repeater {
						model: ['Feedback_5', 'Warp_3']//, 'BPM_0', 'Delay_1',]
						DelayRow {
							visible: !Qt.inputMethod.visible
							row_param: modelData
							current_effect: effect_id
							Material.foreground: Constants.rainbow[index+5]
						}
					}
                    DelayRow {
                        visible: !Qt.inputMethod.visible
                        row_param: "NBITS_0"
                        current_effect: effect_id
                        Material.foreground: Constants.rainbow[8]
                        v_type: "int"
                    }

                    ComboBox {
						visible: beatsRadio.checked
                        // visible: !Qt.inputMethod.visible
						width: 500
						height: 100
                        id: note_subdivisions
						textRole: "text"
                        font {
                            // family: mainFont.name
                            pixelSize: 32
                            capitalization: Font.AllUppercase
                        }
                        delegate: ItemDelegate {
                            width: note_subdivisions.width
                            contentItem: Text {
                                text: modelData.text
                                color: "white"
                                font: note_subdivisions.font
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            highlighted: note_subdivisions.highlightedIndex === index
                        }

						model: [{text: "1/4", value: 1},
						{text: "2/3", value: 8/3.0}, {text: "1/3", value: 4/3.0}, {text: "1/8 .", value: 0.75},
						{text: "PHI", value: 0.618},
					   	{text: "1/8", value: 0.5},  {text: "1/16", value: 0.25}]

						Component.onCompleted: currentIndex = indexForValue(currentEffects[effect_id]["controls"]["Delay_2"].value % 1)
                        onActivated: {
							current_subdivision = model[currentIndex].value;
                            knobs.ui_knob_change(effect_id, "Delay_2", current_subdivision);
                        }

						function indexForValue(value) {
							for (var i = 0; i < model.length; ++i) {
								if (model[i].value === value)
								return i;
							}
							return -1;
						}
                    }

                    Row {
						visible: timeRadio.checked
						spacing: 50
                        Label {
                            text: "MILLISECONDS"
                            height: 60
                            verticalAlignment: Text.AlignVCenter
                            font {
                                // pixelSize: fontSizeMedium
                                family: mainFont.name
                                pixelSize: 28
                                capitalization: Font.AllUppercase
                                letterSpacing: 0
                            }
                        }
                        TextField {
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator{bottom: 0; top: 32000;}
                            width: 121
                            height: 60
                            text: (60.0 / currentEffects[effect_id]["controls"]["BPM_1"].value * currentEffects[effect_id]["controls"]["Delay_2"].value * 1000).toFixed(0) // + " ms"
                            color: "white"
                            font {
                                // pixelSize: fontSizeMedium
                                family: mainFont.name
                                pixelSize: 28
                                capitalization: Font.AllUppercase
                                letterSpacing: 0
                            }
                            onTextEdited: {
                                if (Number(text) > 0 && Number(text) < 32000){
                                    knobs.ui_knob_change(effect_id, "Delay_2", text * currentEffects[effect_id]["controls"]["BPM_1"].value / ( 1000 * 60)) ;
                                }
                            }
                        }
                    }
				}
				InputPanel {
					x: 150
					y: 0
					width: 1130
					id: inputPanel
					// parent:mainWindow.contentItem
					// z: 1000002
					// anchors.bottom:parent.bottom
					// anchors.left: parent.left
					// anchors.right: parent.right
					height: 500

					visible: Qt.inputMethod.visible
				}
                MoreButton {
                    l_effect_type: effect_type
                }
            }
        }

        Component {
            id: editLfo
            Item {
				Component.onDestruction: {
					// if we're not visable, turn off broadcast
					// console.log("setting broadcast false in step");
					knobs.set_broadcast(effect_id, false);
				}
				Component.onCompleted: {
					// console.log("setting broadcast true in step");
					knobs.set_broadcast(effect_id, true);
				}
                z: 3
                height:540
                width:1280
				
				ActionIcons {

				}

				Row {
					x: 250
					y: 100
					height:540
					width:1110
					spacing: 100
					Column {
						width: 490
						spacing: 20

						Repeater {
							model: ["tempo", "tempoMultiplier", "level", "is_uni"]
							DelayRow {
								row_param: modelData
								current_effect: effect_id
								Material.foreground: Constants.rainbow[index]
                                v_type: ModuleInfo.effectPrototypes[effect_type]["controls"][modelData].length > 4 ? ModuleInfo.effectPrototypes[effect_type]["controls"][modelData][4] : "float"
							}
						}
					}

					Grid {
						width: 600
						spacing: 20
						columns: 2
						rows: 3

						Repeater {
							model: ["Sine.png", "Triangle.png", "Ramp.png", "Sawtooth.png", "Square.png", "Sample_Hold.png"]
							IconButton {
								icon.source: "../icons/digit/"+modelData
								width: 114
								height: 114
								icon.width: 100
								checked: index == Math.floor(currentEffects[effect_id]["controls"]["waveForm"].value)
								onClicked: {
									knobs.ui_knob_change(effect_id, "waveForm", index);
								}
								// Material.background: "white"
								Material.foreground: "transparent"
								Material.accent: "white"
								radius: 10
								Label {
									visible: title_footer.show_help 
									x: 0
									y: 20 
									text: modelData
									horizontalAlignment: Text.AlignHCenter
									width: 114
									height: 22
									z: 1
									color: "white"
									font {
										pixelSize: 18
										capitalization: Font.AllUppercase
									}
								}
							}
						}
					}

				}
                MoreButton {
                    l_effect_type: effect_type
                }
            }
        }

        Component {
            id: editPlaits
            Item {
                z: 3
                height:540
                width:1280
				
				ActionIcons {

				}


                Item {
                    width: 1150
                    height: 546
                    x: 130
                    y: 0
                    TabBar {
                        id: plaitsBar
                        width: parent.width
                        height: 75
                        TabButton {
                            text: qsTr("Model")
                            height: parent.height
                            font {
                                pixelSize: 24
                                capitalization: Font.AllUppercase
                            }
                        }
                        TabButton {
                            text: qsTr("Tone")
                            height: parent.height
                            font {
                                pixelSize: 24
                                capitalization: Font.AllUppercase
                            }
                        }
                        TabButton {
                            text: qsTr("Modulation")
                            height: parent.height
                            font {
                                pixelSize: 24
                                capitalization: Font.AllUppercase
                            }
                        }
                    }	



                    StackLayout {
                        y: 115
                        x: 0
                        width: 1150
                        currentIndex: plaitsBar.currentIndex	
                        Column {
                            spacing: 60
                            // drop down
                            width: parent.width
                            // horn split
                            IconSelector {
                                current_effect: effect_id
                                height: 160
                                width: parent.width
                                row_param: "model"
                                icon_prefix: "../icons/digit/plaits/"
                                icons: ['Pair of classic waveforms.png', 'Waveshaping Oscillator.png', 'Two operator FM.png', 'Granular Formant Oscillator.png', 'Harmonic Oscillator.png', 'Wavetable oscillator.png', 'CHORDS.png', 'Vowel and Speech Synthesis.png']
                                button_height: 170
                                button_width:130
                                icon_size: 50
                                button_spacing: 10
                                label_offset: 80
                            }

                            IconSelector {
                                height: 160
                                width: parent.width
                                current_effect: effect_id
                                row_param: "model"
                                value_offset: 8
                                icon_prefix: "../icons/digit/plaits/"
                                icons: ['GRANULAR CLOUD.png', 'Filtered noise.png', 'Particle Noise.png', 'Inharmonic string modeling .png', 'Modal resonator.png', 'Analog bass drum model.png', 'Analog snare drum model.png','Analog hi-hat model.png'] 
                                button_height: 170
                                button_width:130
                                icon_size: 50
                                button_spacing: 10
                                label_offset: 80
                            }
                        } 

                        Item {
                            width: parent.width
                            Column {
                                // x: 300
                                // y: 100

                                anchors.centerIn: parent
                                spacing: 30

                                // Tone
                                Repeater {
                                    model: ['frequency', 'harmonics',  'timbre', 'morph'] 
                                    DelayRow {
                                        row_param: modelData
                                        width: 740
                                        current_effect: effect_id
                                        title: modelData == 'frequency' ? 'frequency' : modelData + ": " + PlaitsNames.name_map[currentEffects[effect_id]["controls"]["model"].value][modelData]
                                        Material.foreground: Constants.rainbow[index+5]
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            Grid {
                                anchors.centerIn: parent
                                // x: 300
                                // y: 100
                                spacing: 20
                                columns: 2
                                // Modulation 
                                Repeater {
                                    model: ['freq_mod', 'timbre_mod', 'morph_mod', 'lpg_decay', 'lpg_color'] 
                                    DelayRow {
                                        row_param: modelData
                                        current_effect: effect_id
                                        Material.foreground: Constants.rainbow[index+5]
                                    }
                                }
                            }	
                        }
                    }
				}

                Text {
                    x: 700 
                    y: 540
                    height: 90
                    width: 350
                    text: "Aux out is " + PlaitsNames.name_map[currentEffects[effect_id]["controls"]["model"].value]["aux"]
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    color: "white"
                    font {
                        pixelSize: 24
                        capitalization: Font.AllUppercase
                        family: mainFont.name
                    }
                }

                MoreButton {
                    l_effect_type: effect_type
                }
            }
        }


		Component {
			id: editBasicRotary
			Item {
				z: 3
				x: 0
				height:546
				width:1280
				ActionIcons {

				}

				// 2 columns,
				Column {
					x: 130
					y: 20
					width: 166
					height: 526
					spacing: 14

					IconButton {
						icon.source: "../icons/digit/rotary/Horn.png"
						x: 23
						// y: 18
						width: 116
						height: 100
						checked: rotaryTabIndex == 0
						Label {
							x: 0
							y: 70 
							text: "Horn"
							horizontalAlignment: Text.AlignHCenter
							width: 116
							height: 22
							z: 1
							color: "white"
							font {
								pixelSize: 22
								capitalization: Font.AllUppercase
							}
						}
						onClicked: {
							rotaryTabIndex = 0;
						}

					}


					IconButton {
						icon.source: "../icons/digit/rotary/Drum.png"
						x: 23
						// y: 161
						width: 116
						height: 100
						checked: rotaryTabIndex == 1
						Label {
							x: 0
							y: 70 
							text: "Drum"
							horizontalAlignment: Text.AlignHCenter
							width: 116
							height: 22
							z: 1
							color: "white"
							font {
								pixelSize: 22
								capitalization: Font.AllUppercase
							}
						}
						onClicked: {
							rotaryTabIndex = 1;
						}

					}

					Item {
						width: parent.width
						height: 60
						Rectangle {
							width: parent.width
							height: 2
							color: "white"
							anchors.verticalCenter: parent.verticalCenter
						}
					}


					Label {
						text: "STOP"
						anchors.horizontalCenter: parent.horizontalCenter
						width: 125
						height: 50
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						lineHeight: 0.65
						font {
							// pixelSize: fontSizeMedium
							// family: mainFont.name
							pixelSize: 22
							capitalization: Font.AllUppercase
							letterSpacing: 0
						}

                        background: Rectangle {
							radius: 7
							color: (rotaryTabIndex == 0 && Math.floor(currentEffects[effect_id]["controls"]["rt_speed"].value / 3) == 0) || (rotaryTabIndex == 1 && currentEffects[effect_id]["controls"]["rt_speed"].value % 3 == 0) ? accent_color.name : "transparent" 
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: { 
                                // console.log("stop clicked");
								whirl_speed_clicked(0);
                            }
                        }
					}

					Label {
						text: "CHORALE\n (SLOW)"
						anchors.horizontalCenter: parent.horizontalCenter
						width: 125
						height: 73
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						lineHeight: 0.65
						font {
							// pixelSize: fontSizeMedium
							// family: mainFont.name
							pixelSize: 22
							capitalization: Font.AllUppercase
							letterSpacing: 0
						}

                        background: Rectangle {
							radius: 7
							color: (rotaryTabIndex == 0 && Math.floor(currentEffects[effect_id]["controls"]["rt_speed"].value / 3) == 1) || (rotaryTabIndex == 1 && currentEffects[effect_id]["controls"]["rt_speed"].value % 3 == 1) ? accent_color.name : "transparent" 
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: { 
                                // console.log("delete clicked");
								whirl_speed_clicked(1);
                                // knobs.delete_preset(fileURL.toString());
                            }
                        }
					}

					Label {
						text: "TREMOLO\n (FAST)"
						anchors.horizontalCenter: parent.horizontalCenter
						width: 125
						height: 73
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						lineHeight: 0.65
						font {
							// pixelSize: fontSizeMedium
							// family: mainFont.name
							pixelSize: 22
							capitalization: Font.AllUppercase
							letterSpacing: 0
						}

                        background: Rectangle {
							radius: 7
							color: (rotaryTabIndex == 0 && Math.floor(currentEffects[effect_id]["controls"]["rt_speed"].value / 3) == 2) || (rotaryTabIndex == 1 && currentEffects[effect_id]["controls"]["rt_speed"].value % 3 == 2) ? accent_color.name : "transparent" 
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: { 
								whirl_speed_clicked(2);
                                // console.log("delete clicked");
                                // knobs.delete_preset(fileURL.toString());
                            }
                        }
					}

				}

				Rectangle {
					x:  296
					y: 0
					width: 2
					z: 3
					height: parent.height
					color: "white"
				}


				// [  'filtatype', 'filtbtype', 'filtdtype',   'link', 'rt_speed']

				StackLayout {
					width: 984
					height: 546
					x: 496
					y: 200
					currentIndex: rotaryTabIndex

					Item {
						x: 2
						y: 0
						width: 782

						Column {
							spacing: 30
							width: parent.width
							// drum mix
							Repeater {
								model: ['hornlvl'] 
								DelayRow {
									row_param: modelData
									current_effect: effect_id
									Material.foreground: Constants.rainbow[index+5]
								}
							}
						}
					}

					Item {
						x: 2
						y: 0
						width: 782

						Column {
							spacing: 30
							width: parent.width

							// drum mix
							Repeater {
								model: ['drumwidth', 'drumlvl' ] 
								DelayRow {
									row_param: modelData
									current_effect: effect_id
									Material.foreground: Constants.rainbow[index+5]
								}
							}
						}
					}
				}
                MoreButton {
                    l_effect_type: effect_type
                }
			}
		}


		Component {
			id: editAdvancedRotary
			Item {
				z: 3
				x: 0
				height:546
				width:1280
				ActionIcons {

				}

				// 2 columns,
				Column {
					x: 130
					y: 20
					width: 166
					height: 526
					spacing: 14

					IconButton {
						icon.source: "../icons/digit/rotary/Horn.png"
						x: 23
						// y: 18
						width: 116
						height: 100
						checked: rotaryTabIndex == 0
						Label {
							x: 0
							y: 70 
							text: "Horn"
							horizontalAlignment: Text.AlignHCenter
							width: 116
							height: 22
							z: 1
							color: "white"
							font {
								pixelSize: 22
								capitalization: Font.AllUppercase
							}
						}
						onClicked: {
							rotaryTabIndex = 0;
						}

					}


					IconButton {
						icon.source: "../icons/digit/rotary/Drum.png"
						x: 23
						// y: 161
						width: 116
						height: 100
						checked: rotaryTabIndex == 1
						Label {
							x: 0
							y: 70 
							text: "Drum"
							horizontalAlignment: Text.AlignHCenter
							width: 116
							height: 22
							z: 1
							color: "white"
							font {
								pixelSize: 22
								capitalization: Font.AllUppercase
							}
						}
						onClicked: {
							rotaryTabIndex = 1;
						}

					}

					Item {
						width: parent.width
						height: 60
						Rectangle {
							width: parent.width
							height: 2
							color: "white"
							anchors.verticalCenter: parent.verticalCenter
							IconButton {
								icon.source: "../icons/digit/rotary/Link.png"
								anchors.horizontalCenter: parent.horizontalCenter
								anchors.verticalCenter: parent.verticalCenter
								Material.foreground: accent_color.name
								Material.background: Constants.background_color
								width: 60
								height: 60
								checked: currentEffects[effect_id]["controls"]["link"].value >= 1
								onClicked: {
								    knobs.ui_knob_change(effect_id, "link", 1.0 - currentEffects[effect_id]["controls"]["link"].value);
								}
							}
						}
					}


					Label {
						text: "STOP"
						anchors.horizontalCenter: parent.horizontalCenter
						width: 125
						height: 50
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						lineHeight: 0.65
						font {
							// pixelSize: fontSizeMedium
							// family: mainFont.name
							pixelSize: 22
							capitalization: Font.AllUppercase
							letterSpacing: 0
						}

                        background: Rectangle {
							radius: 7
							color: (rotaryTabIndex == 0 && Math.floor(currentEffects[effect_id]["controls"]["rt_speed"].value / 3) == 0) || (rotaryTabIndex == 1 && currentEffects[effect_id]["controls"]["rt_speed"].value % 3 == 0) ? accent_color.name : "transparent" 
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: { 
                                // console.log("stop clicked");
								whirl_speed_clicked(0);
                            }
                        }
					}

					Label {
						text: "CHORALE\n (SLOW)"
						anchors.horizontalCenter: parent.horizontalCenter
						width: 125
						height: 73
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						lineHeight: 0.65
						font {
							// pixelSize: fontSizeMedium
							// family: mainFont.name
							pixelSize: 22
							capitalization: Font.AllUppercase
							letterSpacing: 0
						}

                        background: Rectangle {
							radius: 7
							color: (rotaryTabIndex == 0 && Math.floor(currentEffects[effect_id]["controls"]["rt_speed"].value / 3) == 1) || (rotaryTabIndex == 1 && currentEffects[effect_id]["controls"]["rt_speed"].value % 3 == 1) ? accent_color.name : "transparent" 
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: { 
                                // console.log("delete clicked");
								whirl_speed_clicked(1);
                                // knobs.delete_preset(fileURL.toString());
                            }
                        }
					}

					Label {
						text: "TREMOLO\n (FAST)"
						anchors.horizontalCenter: parent.horizontalCenter
						width: 125
						height: 73
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						lineHeight: 0.65
						font {
							// pixelSize: fontSizeMedium
							// family: mainFont.name
							pixelSize: 22
							capitalization: Font.AllUppercase
							letterSpacing: 0
						}

                        background: Rectangle {
							radius: 7
							color: (rotaryTabIndex == 0 && Math.floor(currentEffects[effect_id]["controls"]["rt_speed"].value / 3) == 2) || (rotaryTabIndex == 1 && currentEffects[effect_id]["controls"]["rt_speed"].value % 3 == 2) ? accent_color.name : "transparent" 
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: { 
								whirl_speed_clicked(2);
                                // console.log("delete clicked");
                                // knobs.delete_preset(fileURL.toString());
                            }
                        }
					}

				}

				Rectangle {
					x:  296
					y: 0
					width: 2
					z: 3
					height: parent.height
					color: "white"
				}


				// [  'filtatype', 'filtbtype', 'filtdtype',   'link', 'rt_speed']

				StackLayout {
					width: 984
					height: 546
					x: 296
					y: 0
					currentIndex: rotaryTabIndex

					Item {
						x: 2
						y: 0
						width: 982
						TabBar {
							id: hornBar
							width: parent.width
							height: 47
							TabButton {
								text: qsTr("Split")
								font {
									pixelSize: 24
									capitalization: Font.AllUppercase
								}
							}
							TabButton {
								text: qsTr("Character")
								font {
									pixelSize: 24
									capitalization: Font.AllUppercase
								}
							}
							TabButton {
								text: qsTr("Rotor")
								font {
									pixelSize: 24
									capitalization: Font.AllUppercase
								}
							}
							TabButton {
								text: qsTr("Mix")
								font {
									pixelSize: 24
									capitalization: Font.AllUppercase
								}
							}
						}	


						StackLayout {
							y: 150
							x: 220
							width: 700
							currentIndex: hornBar.currentIndex	
							Column {
								spacing: 30
								// drop down
								width: parent.width
								// horn split
								Repeater {
									model: ['filtafreq', 'filtagain',  'filtaq'] 
									DelayRow {
										row_param: modelData
										current_effect: effect_id
										Material.foreground: Constants.rainbow[index+5]
									}
								}
							}

							Column {
								spacing: 30
								// drop down
								width: parent.width

								// horn character
								Repeater {
									model: ['filtbfreq', 'filtbgain',  'filtbq'] 
									DelayRow {
										row_param: modelData
										current_effect: effect_id
										Material.foreground: Constants.rainbow[index+5]
									}
								}
							}

							Column {
								spacing: 30
								width: parent.width
								//  horn rotor
								Repeater {
									model: ['hornrpmfast', 'hornrpmslow', 'hornaccel', 'horndecel'] 
									DelayRow {
										row_param: modelData
										current_effect: effect_id
										Material.foreground: Constants.rainbow[index+5]
									}
								}
							}	

							Column {
								spacing: 30
								width: parent.width
								// drum mix
								Repeater {
									model: ['hornwidth',  'hornlvl',  'hornleak'] 
									DelayRow {
										row_param: modelData
										current_effect: effect_id
										Material.foreground: Constants.rainbow[index+5]
									}
								}

							}
						}
					}

					Item {
						x: 2
						y: 0
						width: 982
						TabBar {
							id: drumBar
							width: parent.width
							height: 47
							TabButton {
								text: qsTr("Split")
								font {
									pixelSize: 24
									capitalization: Font.AllUppercase
								}
							}
							TabButton {
								text: qsTr("Rotor")
								font {
									pixelSize: 24
									capitalization: Font.AllUppercase
								}
							}
							TabButton {
								text: qsTr("Mix")
								font {
									pixelSize: 24
									capitalization: Font.AllUppercase
								}
							}
						}	


						StackLayout {
							y: 150
							x: 220
							width: 700
							currentIndex: drumBar.currentIndex	

							Column {
								spacing: 30
								width: parent.width

								// drum split 
								Repeater {
									model: ['filtdfreq', 'filtdgain',  'filtdq'] 
									DelayRow {
										row_param: modelData
										current_effect: effect_id
										Material.foreground: Constants.rainbow[index+5]
									}
								}
							}

							Column {
								spacing: 30
								width: parent.width


								// drum rotor
								Repeater {
									model: ['drumrpmfast', 'drumrpmslow', 'drumaccel', 'drumdecel'] 
									DelayRow {
										row_param: modelData
										current_effect: effect_id
										Material.foreground: Constants.rainbow[index+5]
									}
								}
							}

							Column {
								spacing: 30
								width: parent.width

								// drum mix
								Repeater {
									model: ['drumwidth', 'drumlvl' ] 
									DelayRow {
										row_param: modelData
										current_effect: effect_id
										Material.foreground: Constants.rainbow[index+5]
									}
								}
							}
						}
					}

				}
                MoreButton {
                    l_effect_type: effect_type
                }
			}
		}

		Component {
			id: editAdvancedRotaryExtra
			Item {
				z: 3
				x: 0
				height:546
				width:1280
				ActionIcons {

				}

				// [  'filtatype', 'filtbtype', 'filtdtype']

				Grid {
					x: 260
					y: 65
					width: 1000
					spacing: 20
					columns: 2
					height: 490
					// anchors.centerIn: parent
					// advanced
					Repeater {
						model: ['drumbrake', 'drumradius', 'hornbrakepos', 'hornradius', 'hornxoff', 'hornzoff', 'micangle', 'micdist' ]
						DelayRow {
							row_param: modelData
							current_effect: effect_id
							Material.foreground: Constants.rainbow[index]
						}
					}

					Label {
						text: "Changing any of these values will reinitialize the module and sound will glitch"
						width: 472
						height: 80
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						wrapMode: Text.Wrap
						lineHeight: 0.65
						font {
							// pixelSize: fontSizeMedium
							// family: mainFont.name
							pixelSize: 22
							// capitalization: Font.AllUppercase
							letterSpacing: 0
						}

					}
				}
			}
		}

        Component {
            id: editGranular
			Item {
				z: 3
				x: 0
				height:540
				width:1280
				ValueButtonsSlider {
					current_effect: effect_id
				}

				Rectangle {
					y: 0
					x: 475
					width:2
					height: 522
					color: Constants.poly_dark_grey
				}

                VerticalSlider {
					y: 31
					x: 475
                    width: 100
                    height: 462
					current_effect: effect_id
                    row_param: "size_param"
                    Material.foreground: Constants.poly_green
                }

				Rectangle {
					y: 0
					x: 575
					width:2
					height: 522
					color: Constants.poly_dark_grey
				}
				IconSlider {
					x: 600
					y: -20
					width: 650
					row_param: "texture_param"
					icons: ['Square.png', 'ramp.png',  'sawtooth.png',  'Triangle.png', 'diffused triangle.png']
					current_effect: effect_id
					icon_path: "../icons/digit/clouds/"
					only_top: true
				}

				IconSlider {
					x: 600
					y: 215
					width: 650
					row_param: "density_param"
					icons: ['d1.png', 'd2.png', 'd3.png', 'd4.png', 'd5.png', 'd6.png', 'd7.png']
					current_effect: effect_id
					icon_path: "../icons/digit/granular/"
					only_top: true
					show_labels: false
				}

				Row {
					width: 600
					x: 600
					y: 420
					spacing: 23
				
					EffectSwitch {
						width: 300
						height: 110
						row_param: "freeze_param"
						current_effect: effect_id
						icon_source: "/clouds/Freeze.png"
						has_border: true
						text: "FREEZE"
						radius: 11
						display: Button.TextUnderIcon
						font {
							pixelSize: 24
							capitalization: Font.AllUppercase
						}
					}
					EffectSwitch {
						width: 300
						height: 110
						row_param: "reverse_param"
						current_effect: effect_id
						icon_source: "/clouds/Reverse.png"
						has_border: true
						text: "REVERSE"
						radius: 11
						display: Button.TextUnderIcon
						font {
							pixelSize: 24
							capitalization: Font.AllUppercase
						}
					}
				}
                MoreButton {
                    l_effect_type: effect_type
                }
			}
        }

        Component {
            id: editMixer
			Item {
				z: 3
				x: 0
				height:540
				width:1280
				MultiValueButtonsSlider {
					current_effect: effect_id
				}
                MoreButton {
                    l_effect_type: effect_type
                }
			}
        }

        Component {
            id: editClouds
			Item {
				z: 3
				x: 0
				height:540
				width:1180
				ActionIcons {
				
				}
				Column {
					x: 160
					y: 65
					width: 541
					spacing: 30

					Repeater {
						model: ['blend_param', 'density_param', 'feedback_param', 'pitch_param']
						DelayRow {
							row_param: modelData
							current_effect: effect_id
							Material.foreground: Constants.rainbow[index]
                            v_type: ModuleInfo.effectPrototypes[effect_type]["controls"][modelData].length > 4 ? ModuleInfo.effectPrototypes[effect_type]["controls"][modelData][4] : "float"
						}
					}
				}

				Column {
					x: 673
					y: 65
					width: 541
					spacing: 30



					Repeater {
						model: effect_type == 'granular' ? ['position_param', 'reverb_param',  'size_param', 'spread_param'] : ['position_param', 'reverb_param',  'size_param', 'spread_param', 'texture_param'] 
						DelayRow {
							row_param: modelData
							current_effect: effect_id
							Material.foreground: Constants.rainbow[index+5]
						}
					}
				}

				Rectangle {
					y: 0
					x: 1170
					width:2
					height: 546
					color: "white"
				}
				Column {
					x: 1183
					anchors.verticalCenter: parent.verticalCenter
					width: 97
					spacing: 40

					EffectSwitch {
						row_param: "freeze_param"
						current_effect: effect_id
						icon_source: "/clouds/Freeze.png"
					}
					EffectSwitch {
						row_param: "reverse_param"
						current_effect: effect_id
						icon_source: "/clouds/Reverse.png"
					}
					// TODO add in link to shape selector
					IconButton {
						visible: effect_type == 'granular'
						icon.source: "../icons/digit/clouds/Shapes.png"
						width: 70
						height: 70
						icon.width: 60
						onClicked: {
							patchStack.push(editCloudsShape);
							patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
						}
						Material.foreground: accent_color.name
						radius: 30
						Label {
							visible: title_footer.show_help 
							x: -92
							y: 19 
							text: "select shape"
							horizontalAlignment: Text.AlignRight
							width: 82
							height: 9
							z: 1
							color: "white"
							font {
								pixelSize: 14
								capitalization: Font.AllUppercase
							}
						}
					}
				}
                MoreButton {
                    l_effect_type: effect_type
                }
			}
        }

        Component {
            id: editWarps

			Item {
				z: 3
				x: 0
				height:540
				width:1180
				ActionIcons {
				
				}
				Column {
					x: 450
					anchors.verticalCenter: parent.verticalCenter
					width: 541
					spacing: 20

					Repeater {
						model: Object.keys(currentEffects[effect_id]["controls"]).filter(isSpecialWarpsParam)
						DelayRow {
							row_param: modelData
							current_effect: effect_id
							Material.foreground: Constants.rainbow[index]
						}
					}
				}
                MoreButton {
                    l_effect_type: effect_type
                }
			}
        }

        Component {
            id: editWarpsMeta

			Item {
				z: 3
				x: 0
				height:540
				width:1280
				ActionIcons {
				
				}
				IconSlider {
					x: 175
					y: 122
					width: 1008
					row_param: "algorithm"
					current_effect: effect_id
				}
                MoreButton {
                    l_effect_type: effect_type
                }
			}
        }

        Component {
            id: editCloudsShape

			Item {
				z: 3
				x: 0
				height:540
				width:1280
				// ActionIcons {
				
				// }
			}
        }


        Component {
            id: editGeneric
            Item {
				Component.onDestruction: {
					// if we're not visable, turn off broadcast
					// console.log("setting broadcast false in step");
					knobs.set_broadcast(effect_id, false);
				}
				Component.onCompleted: {
					// console.log("setting broadcast true in step");
					knobs.set_broadcast(effect_id, true);
				}
                height:546
				width: 1280
				ActionIcons {

				}
                // z: 3
				Item {
					x: 150
					width: 1083
					height: 546

					Grid {
						spacing: 20
						columns: 2
						anchors.centerIn: parent

						Repeater {
							model: Object.keys(currentEffects[effect_id]["controls"])
							DelayRow {
								row_param: modelData
								current_effect: effect_id
								Material.foreground: Constants.rainbow[index]
								is_log: modelData == "cutoff"
                                v_type: ModuleInfo.effectPrototypes[effect_type]["controls"][modelData].length > 4 ? ModuleInfo.effectPrototypes[effect_type]["controls"][modelData][4] : "float"
							}
						}
					}
				
				}

                MoreButton {
                    l_effect_type: effect_type
                }
                
            }
        }

        Component {
            id: editIO
            Item {
				height:546
				width:1280
				Row {
					anchors.centerIn: parent
					spacing: 40
					IconButton {
						icon.source: "../icons/digit/clouds/Disconnect.png"
						rightPadding: 20
						leftPadding: 0
						width: 110
						height: 90
						onClicked: {
							disconnect_clicked();
						}
						Material.foreground: "white"
						radius: 30

						SideHelpLabel {
							text: "disconnect"
						}
					}
				}
                
            }
        }

        Component {
            id: editQuantizer

			Item {
				z: 3
				x: 0
				height:540
				width:1280
				// ActionIcons {
				
				// }
				Item {
					anchors.horizontalCenter: parent.horizontalCenter
					y: 95
					width: 1113
					height: 420

					Repeater {
						model: ['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9', 'n10', 'n11', 'n12']
						Button {
							x : index < 5 ? index * 83 : (index + 1) * 83
							y : ['n2', 'n4', 'n7', 'n9', 'n11'].indexOf(modelData) < 0 ? 93 : 0
							z : ['n2', 'n4', 'n7', 'n9', 'n11'].indexOf(modelData) < 0 ? 0 : 1
							Material.foreground: Constants.rainbow[index]
							Material.background: Constants.background_color
							width: 139
							height: 227
							checked: currentEffects[effect_id]["controls"][modelData].value >= 1
							onClicked: {
								knobs.ui_knob_change(effect_id, modelData, 1.0 - currentEffects[effect_id]["controls"][modelData].value);
							}

							contentItem: Text {
								text: currentEffects[effect_id]["controls"][modelData].name
								color:  checked ? Constants.background_color : Constants.rainbow[index] 
								horizontalAlignment: Text.AlignHCenter
								verticalAlignment: Text.AlignBottom
								elide: Text.ElideRight
								height: 227
								font {
									pixelSize: 48
								}
							}

							background: Rectangle {
								width: 139
								height: 227
								color: checked ? Constants.rainbow[index] : Constants.background_color  
								border.color: Constants.rainbow[index] 
								border.width: 2
								radius: 20
							}
						}
					}	
				}
			}
        }

        Component {
            id: editPitchCalOut
            Item {
                function clamp(number, min, max) {
                    return Math.max(min, Math.min(number, max));
                }

                height:546
				width: 1280
                // z: 3
				Column {
					x: 100
                    y: 150
					width: 1180
					height: 546
                    spacing: 60

                    DelayRow {
                        anchors.horizontalCenter: parent.horizontalCenter
                        row_param: "offset"
                        current_effect: effect_id
                        Material.foreground: Constants.rainbow[0]
                    }
                    DelayRow {
                        anchors.horizontalCenter: parent.horizontalCenter
                        row_param: "scale"
                        current_effect: effect_id
                        Material.foreground: Constants.rainbow[0]
                    }

				}

                MoreButton {
                    l_effect_type: effect_type
                }
                
            }
        }

        Component {
            id: editPitchCalIn
            Item {
                property real min_level: currentEffects[effect_id]["broadcast_ports"]["min_level"].value
                property real max_level: currentEffects[effect_id]["broadcast_ports"]["max_level"].value
				Component.onDestruction: {
					// if we're not visable, turn off broadcast
					// console.log("setting broadcast false in step");
					knobs.set_broadcast(effect_id, false);
				}
				Component.onCompleted: {
					// console.log("setting broadcast true in step");
					knobs.set_broadcast(effect_id, true);
				}

                function clamp(number, min, max) {
                    return Math.max(min, Math.min(number, max));
                }

                height:546
				width: 1280
                // z: 3
				Column {
					x: 100
                    y: 50
					width: 1080
					height: 546
                    spacing: 60

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 90
                        width: 800
                        text: "Press measure then play your note that should be zero volts, then the note 2 octaves up from that. Then press measure again." 
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        color: "white"
                        font {
                            pixelSize: 24
                            capitalization: Font.AllUppercase
                            family: mainFont.name
                        }
                    }

                    Switch {
                        anchors.horizontalCenter: parent.horizontalCenter
                        Material.foreground: Constants.rainbow[0]
                        text: "MEASURE"
                        width: 420
                        height: 90
                        checked: Boolean(currentEffects[effect_id]["controls"]["measure"].value)
                        onToggled: {
                            knobs.ui_knob_change(effect_id, "measure", 1.0 - currentEffects[effect_id]["controls"]["measure"].value);
                            if (!checked){
                                // offset is max - min - 2
                                knobs.ui_knob_change(effect_id, "offset", min_level * -1);
                                knobs.ui_knob_change(effect_id, "scale", (2.0 / (max_level * 5.0 - min_level * 5.0)));
                            }
                        }
                        font {
                            pixelSize: 24
                            capitalization: Font.AllUppercase
                            family: mainFont.name
                        }

                    }


					Row {
                        anchors.horizontalCenter: parent.horizontalCenter
						spacing: 50

                        Text {
                            text: "SCALE: " + (currentEffects[effect_id]["controls"]["scale"].value).toFixed(3)
                            color: "white"
                            font.pixelSize: 34
                        }
                        Text {
                            text: "OFFSET: " + (currentEffects[effect_id]["controls"]["offset"].value * 5).toFixed(3)
                            color: "white"
                            font.pixelSize: 34
                        }
                        Text {
                            text: "MIN LEVEL: " + (min_level * 5).toFixed(3)
                            color: "white"
                            font.pixelSize: 34
                        }
                        Text {
                            text: "MAX LEVEL: " + (max_level * 5).toFixed(3)
                            color: "white"
                            font.pixelSize: 34
                        }
					}

				
				}

                MoreButton {
                    l_effect_type: effect_type
                }
                
            }
        }
        Component {
            id: editCVMeter
            Item {
                property real min_level: currentEffects[effect_id]["broadcast_ports"]["min_level"].value
                property real max_level: currentEffects[effect_id]["broadcast_ports"]["max_level"].value
                property real cur_level: currentEffects[effect_id]["broadcast_ports"]["level"].value
				Component.onDestruction: {
					// if we're not visable, turn off broadcast
					// console.log("setting broadcast false in step");
					knobs.set_broadcast(effect_id, false);
				}
				Component.onCompleted: {
					// console.log("setting broadcast true in step");
					knobs.set_broadcast(effect_id, true);
				}

                function clamp(number, min, max) {
                    return Math.max(min, Math.min(number, max));
                }

                height:546
				width: 1280
                // z: 3
				Column {
					x: 100
                    y: 150
					width: 1080
					height: 546
                    spacing: 60

                    Rectangle {
                        x: 0
                        height: 100
                        width: parent.width
                        color: Constants.poly_dark_grey
                        border { width:2; color: accent_color.name}
                        radius: 5

                        Rectangle {
                            x: (parent.width / 2) 
                            height: 100
                            width: parent.width * Math.abs(clamp(cur_level, -1.0, 1.0)) / 2
                            transform: Scale { origin.x: 0; origin.y: 0; xScale: cur_level > 0 ? 1 : -1}
                            // color: Constants.rainbow[Math.floor(Math.abs(cur_level) * 10) % 5]
                            color: accent_color.name
                            radius: 5
                        }
                    }

                    DelayRow {
                        anchors.horizontalCenter: parent.horizontalCenter
                        row_param: "Reset"
                        current_effect: effect_id
                        Material.foreground: Constants.rainbow[0]
                        v_type: "bool"
                    }

					Row {
                        anchors.horizontalCenter: parent.horizontalCenter
						spacing: 50

                        Text {
                            text: "LEVEL: " + (cur_level * 5).toFixed(3)
                            color: "white"
                            font.pixelSize: 34
                        }
                        Text {
                            text: "MIN LEVEL: " + (min_level * 5).toFixed(3)
                            color: "white"
                            font.pixelSize: 34
                        }
                        Text {
                            text: "MAX LEVEL: " + (max_level * 5).toFixed(3)
                            color: "white"
                            font.pixelSize: 34
                        }
					}

				
				}

                MoreButton {
                    l_effect_type: effect_type
                }
                
            }
        }
}
