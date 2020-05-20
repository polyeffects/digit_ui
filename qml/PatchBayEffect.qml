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

Rectangle {
    id: rect
    width: (effect_id.length * 1.6) + 100
    // height: is_io ? 80 : 68
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
    property bool highlight: effect_id in currentEffects && currentEffects[effect_id]["highlight"].value
    property bool selected: false
    property Rectangle cv_area: cv_rec
    property Column inputs: input_rec
    property Column outputs: output_rec
	property real current_subdivision: 1.0 
	property int rotaryTabIndex: 0

    function isAudio(item){
        return effectPrototypes[effect_type]["inputs"][item][1] == "AudioPort"
    }

    function isCV(item){
        return effectPrototypes[effect_type]["inputs"][item][1] == "CVPort"
    }

    function isMIDI(item){
        return effectPrototypes[effect_type]["inputs"][item][1] == "AtomPort"
    }

    function isRightInput(item){
        return ["AtomPort", "AudioPort"].indexOf(effectPrototypes[effect_type]["inputs"][item][1]) >= 0
    }


	function isSpecialWarpsParam(item){
		return ['int_osc', 'space_size', 'mode', 'algorithm', 'shape'].indexOf(item) < 0;
	}

    property var input_keys: Object.keys(effectPrototypes[effect_type]["inputs"]).filter(isRightInput) 
    property var output_keys: Object.keys(effectPrototypes[effect_type]["outputs"])
    property bool no_sliders: ["mono_EQ", "stereo_EQ", "input", "output", "lfo", 'algo_reverb', 'granular', 'looping_delay', 'resonestor', 'spectral_twist', 'time_stretch'].indexOf(effect_type) >= 0
    property bool has_ui: ['bitmangle', 'comparator', 'chebyschev_waveshaper', 'meta_modulation', 'wavefolder', 'vocoder', 'doppler_panner', 'twist_delay', 'frequency_shifter', 'rotary_advanced'].indexOf(effect_type) >= 0
    property bool is_io: ["input", "output", "midi_input", "midi_output"].indexOf(effect_type) >= 0
    property var sliders; 
    // border { width:2; color: Material.color(Material.Cyan, Material.Shade100)}
    Drag.active: mouseArea.drag.active

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

    function connect_clicked() {
        /*
         * on click, check if we are highlight, if not find source ports 
         * if we are, then we're a current target
         */
        if (!(highlight)){
            var k = output_keys;
            if (k.length == 0){
                return;
            }

            selected = true
            patch_bay.selected_effect = rect
            hide_sliders(false);
            knobs.select_effect(true, effect_id)
            patch_bay.list_effect_id = effect_id;
            patch_bay.list_source = true;

            if (k.length > 1 )
            {
                mainStack.push(portSelection);
                patch_bay.current_help_text = Constants.help["connect_to"];
            } 
            else if (k.length == 1) {
                knobs.set_current_port(true, effect_id, k[0]);
                // rep1.model.items_changed();
                patch_bay.externalRefresh();
                patch_bay.current_help_text = Constants.help["connect_to"];
            }
        } else {
            patch_bay.selected_effect.selected = false;

            knobs.select_effect(false, effect_id)
            patch_bay.list_effect_id = effect_id;
            patch_bay.list_source = false;
            var source_port_pair = rsplit(connectSourcePort.name, "/", 1)
            var source_port_type = effectPrototypes[currentEffects[source_port_pair[0]]["effect_type"]]["outputs"][source_port_pair[1]][1]

            var k;
            var matched = 0;
            var matched_id = 0;
            // console.log("source port ", source_port_pair);
            // console.log("source port ", effect_id);
            k = Object.keys(effectPrototypes[effect_type]["inputs"])
            for (var i in k) {
                // console.log("port name is ", i[k]);
                if (effectPrototypes[effect_type]["inputs"][k[i]][1] == source_port_type){
                    matched++;
                    matched_id = i;
                }
            }
            if (matched > 1 )
            {
                mainStack.push(portSelection);
                patch_bay.current_help_text = Constants.help["connect_from"];
            } 
            else if (matched == 1){
                knobs.set_current_port(false, effect_id, k[matched_id]);
                // rep1.model.items_changed();
                patch_bay.externalRefresh();
                patch_bay.current_help_text = Constants.help["connect_from"];
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
        patch_bay.currentMode = PatchBay.Details;
		title_text = effect_type.replace(/_/g, " ")

        if (effect_type == "stereo_EQ" || effect_type == "mono_EQ"){
            patchStack.push("EQWidget.qml", {"effect": effect_id});
            patch_bay.current_help_text = Constants.help["eq_detail"];
        }
        else if (effect_type == "delay"){
            patchStack.push(editDelay);
            patch_bay.current_help_text = Constants.help["delay_detail"];
        }
        else if (effect_type == "lfo"){
            patchStack.push(editLfo);
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
		else if (['algo_reverb', 'granular', 'looping_delay', 'resonestor', 'spectral_twist', 'time_stretch'].indexOf(effect_type) >= 0){
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
        else if (effect_type == "mono_reverb" || effect_type == "stereo_reverb" || effect_type == "true_stereo_reverb")
        {
            patch_bay.current_help_text = Constants.help["reverb_detail"];
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
            patch_bay.current_help_text = Constants.help["reverb_detail"];
            patchStack.push("ReverbBrowser.qml", {"effect": effect_id, 
            "top_folder": "file:///audio/cabs",
            "after_file_selected": (function(name) { 
                // console.log("got new reveb file");
                // console.log("file is", name.toString());
                knobs.update_ir(effect_id, name.toString());
                })
            });
        }
		else if (['input', 'output', 'midi_input', 'midi_output'].indexOf(effect_type) >= 0){
            patchStack.push(editIO);
            // patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
        } else {
			patch_bay.current_help_text = Constants.help["sliders"];
            patchStack.push(editGeneric);
        }
    }

	function show_advanced_special_clicked(){
		if (['bitmangle', 'comparator', 'chebyschev_waveshaper', 'wavefolder', 'vocoder'].indexOf(effect_type) >= 0){
            patchStack.push("IconSelector.qml", {"effect_id": effect_id, "row_param": "int_osc", "icons": ["OFF.png", "Sine.png", "Sawtooth.png", "Triangle.png"]});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "twist_delay") {
            patchStack.push("IconSelector.qml", {"effect_id": effect_id, "row_param": "mode", "icons": ["Open FB Loop.png", "Dual Delay.png", "Tape Delay.png", "Ping Pong.png"]});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "frequency_shifter") {
            patchStack.push("IconSelector.qml", {"effect_id": effect_id, "row_param": "mode", "icons": ["OFF.png", "Sin.png", "2 Harmonics.png", "4 Harmonics.png"]});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "doppler_panner") {
            patchStack.push("IconSelector.qml", {"effect_id": effect_id, "row_param": "space_size", "icons": ["Small.png", "Medium.png", "Large.png", "XL.png"]});
            patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
		} else if (effect_type == "meta_modulation") {
			if (patchStack.currentItem.objectName == "editWarpsMeta"){
				patchStack.push(editWarps);
				patch_bay.current_help_text = "" // Constants.help["delay_detail"]; // FIXME
			} else {
				patchStack.push("IconSelector.qml", {"effect_id": effect_id, "row_param": "shape", "icons": ["OFF.png", "Sine.png", "Sawtooth.png", "Triangle.png"]});
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


    border { width:2; color: selected ? accent_color.name : Constants.outline_color}

    Column {
        id: output_rec
        width:5
        y:20
        anchors.left: parent.left
        spacing: 8
        Repeater {
            id: outputRep
            model: output_keys
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: -2
                width: 3
                height: 14
                color: Constants.port_color_map[effectPrototypes[effect_type]["outputs"][modelData][1]]
            }
        }
    }

    Column {
        id: input_rec
        width:5
        anchors.right: parent.right
        spacing: 8
        y:20
        Repeater {
            id: inputRep
            model: input_keys
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: -2
                width: 3
                height: 14
                color: highlight ? accent_color.name : Constants.port_color_map[effectPrototypes[effect_type]["inputs"][modelData][1]]
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
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: rsplit(effect_id, "/", 1)[1].replace(/_/g, " ")
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: rect.is_io ? "white" : effect_color 
        lineHeight: 0.65
        fontSizeMode: Text.Fit 
        minimumPixelSize: 18
        font {
            // pixelSize: fontSizeMedium
            family: mainFont.name
            pixelSize: 32
            capitalization: Font.AllUppercase
            letterSpacing: 0
        }
    }
    //
    MouseArea {
        id: mouseArea
        z: -1
        anchors.fill: parent
        // drag.target: patch_bay.current_mode == PatchBay.Move ? parent : undefined
        drag.target: !rect.is_io && patch_bay.currentMode == PatchBay.Move ? parent : undefined
        // drag.target: parent 
        onPressed: {
            // check mode: move, delete, connect, open
            rect.beginDrag = Qt.point(rect.x, rect.y);
			// console.log("effect proto", Object.keys(effectPrototypes[effect_type]["inputs"]))

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
				//
                patch_bay.currentMode = PatchBay.Sliders;
				expand_clicked();
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
           
            patch_bay.isMoving = false;
            if (rect.beginDrag != Qt.point(rect.x, rect.y)){
				patch_bay.externalRefresh();
				knobs.move_effect(effect_id, rect.x, rect.y)
            }
            // if (patch_bay.currentMode == PatchBay.Move){
			// }

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
							checked: true
							text: qsTr("Time (MS)")
						}
						RadioButton {
							id: beatsRadio
							text: qsTr("Beats")
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
						height: 60
                        id: note_subdivisions
						textRole: "text"

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
            }
        }

        Component {
            id: editLfo
            Item {
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
							model: ["tempo", "tempoMultiplier", "level", "phi0", "is_uni"]
							DelayRow {
								row_param: modelData
								current_effect: effect_id
								Material.foreground: Constants.rainbow[index]
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
						text: "TREMELO\n (FAST)"
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
						text: "TREMELO\n (FAST)"
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
				IconSlider {
					x: 175
					y: 122
					width: 1008
					row_param: "texture_param"
					icons: ['Square.png', 'ramp.png',  'sawtooth.png',  'Triangle.png', 'diffused triangle.png']
					current_effect: effect_id
					icon_path: "../icons/digit/clouds/"
					only_top: true
				}
			}
        }


        Component {
            id: editGeneric
            Item {
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
							}
						}
					}
				
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
						icon.source: "../icons/digit/clouds/Connect.png"
						rightPadding: 20
						leftPadding: 0
						visible: patch_bay.selected_effect && (patch_bay.selected_effect.effect_type != "output")
						width: 110
						height: 90
						onClicked: {
							connect_clicked();
							patch_bay.currentMode = PatchBay.Connect;
							patch_bay.current_help_text = Constants.help["connect_to"];
						}
						Material.foreground: "white"
						radius: 30

						SideHelpLabel {
							text: "connect"
						}
					}
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

}
