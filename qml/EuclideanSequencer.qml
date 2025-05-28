import "controls" as PolyControls
import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import "../qml/polyconst.js" as Constants

Rectangle {
	id: rectangle
	width: 1285; height: 520
	color: Constants.background_color
	property string effect: "euclidean1"
	property var currentBeat: [currentEffects[effect]["broadcast_ports"]["current_step_out_1"].value, currentEffects[effect]["broadcast_ports"]["current_step_out_2"].value, currentEffects[effect]["broadcast_ports"]["current_step_out_3"].value, currentEffects[effect]["broadcast_ports"]["current_step_out_4"].value]
	property int allBeats: currentEffects[effect]["broadcast_ports"]["current_step_out_1"].value + currentEffects[effect]["broadcast_ports"]["current_step_out_2"].value + currentEffects[effect]["broadcast_ports"]["current_step_out_3"].value + currentEffects[effect]["broadcast_ports"]["current_step_out_4"].value

	onAllBeatsChanged:  {
		// console.log("beats changed");
		canvas.requestPaint();
	}

	function drawArchs(radius, ctx, trackIndex) {
		if (currentEffects[effect]["controls"]["is_enabled" + (trackIndex+1)].value  < 0.9) {
			ctx.globalAlpha = 0
			return
		}
		ctx.beginPath();
		ctx.lineWidth = 2;
		ctx.strokeStyle = Constants.poly_grey;
		ctx.arc(260, 260, radius, 0, Math.PI * 2);
		ctx.stroke();
		drawSteps(radius, ctx, trackIndex);
	}


	function findBeats(steps, beats, shift) {
		var bucket = 0
		var beatsArray = [];
		var shiftedArray = [];
		var beat = beats;
		for (var i = 0; i < steps; i++) {
			bucket += beats;
			if (bucket >= steps){
				bucket -= steps;
				beatsArray[steps-1-i] = beat;
				beat -= 1;
			} else {
				beatsArray[steps-1-i] = 0;
			}
		}

		for (var i = 0; i < steps; i++) {
			shiftedArray[(i+shift) % steps] = beatsArray[i];
		}
		return shiftedArray;
	}

	function styleStep(lineWidth, strockStyle, fillStyle, ctx, steps, stepIndex, radius, stepRadius) {
		ctx.strokeStyle = strockStyle
		ctx.lineWidth = lineWidth
		ctx.fillStyle = fillStyle
		ctx.beginPath()
		var a = (Math.PI *3/2) + (2 * Math.PI/steps * stepIndex);
		var x = 260 + (radius * Math.cos(a))
		var y = 260 + (radius * Math.sin(a))
		ctx.arc(x, y, stepRadius, 0, 2 * Math.PI)
		ctx.fill()
		ctx.stroke()
	}

	function drawSteps(radius, ctx, trackIndex) {
		var steps =  currentEffects[effect]["controls"]["steps" + (trackIndex+1)].value 
		var beats =  currentEffects[effect]["controls"]["beats" + (trackIndex+1)].value 
		var shift =  currentEffects[effect]["controls"]["shift" + (trackIndex+1)].value 

		var beatsArray = findBeats(steps, beats, shift);

		var currentBeatIndex = currentBeat[trackIndex];

		for (var i = 0; i < steps; i++) {
			if (i === currentBeatIndex) {
				if (beatsArray[i] != 0) {
					styleStep(2, trackModel.get(trackIndex).trackColor, Constants.background_color, ctx, steps, i, radius, 15.5)
					styleStep(2, trackModel.get(trackIndex).trackColor, Constants.background_color, ctx, steps, i, radius, 10.5)
					styleStep(0, trackModel.get(trackIndex).trackColor, trackModel.get(trackIndex).trackColor, ctx, steps, i, radius, 5.5)
				}
				else {
					styleStep(2, Constants.poly_grey, Constants.background_color, ctx, steps, i, radius, 10.5)
					styleStep(0, Constants.poly_grey, Constants.poly_grey, ctx, steps, i, radius, 5.5)
				}
			}
			else if (beatsArray[i] != 0){
				styleStep(2, trackModel.get(trackIndex).trackColor, Constants.background_color, ctx, steps, i, radius, 10.5)
			}
			else {
				styleStep(4, Constants.background_color, Constants.poly_grey, ctx, steps, i, radius, 10.5)
			}
		}
	}

	Component.onDestruction: {
		// if we're not visable, turn off broadcast
		// console.log("setting broadcast false in step");
		knobs.set_broadcast(effect, false);
	}
	Component.onCompleted: {
		// console.log("setting broadcast true in step");
		knobs.set_broadcast(effect, true);
	}

	Canvas {
		id: canvas
		width: parent.width
		height: parent.height
		property var radiusArray: [230, 180, 130, 80]
		onPaint: {
			var ctx = getContext("2d");
			ctx.reset()
			for (var i = 0; i < radiusArray.length; i++) {
				if (currentEffects[effect]["controls"]["is_enabled" + (i+1)].value  > 0.9) {
					drawArchs(radiusArray[i], ctx, i);
				}
			}
		}
	}

	Rectangle {
		x: 514
		height: 520; width: 762
		color: Constants.background_color

		RowLayout {
			spacing: 9

			Repeater {
				model: ListModel {
					id: trackModel

					ListElement {
						trackColor: "#53A2FD"
						// isEnabled: currentEffects[effect]["controls"]["is_enabled1"].value > 0.9
						// steps: currentEffects[effect]["controls"]["steps1"].value
						// beats: currentEffects[effect]["controls"]["beats1"].value
						// shift: currentEffects[effect]["controls"]["shift1"].value
					}

					ListElement {
						trackColor: "#80FFE8"
					}

					ListElement {
						trackColor: "#FFD645"
					}

					ListElement {
						trackColor: "#FFA9EC"
					}
				}

				Item {
					height: 520; width: 180

					Rectangle {
						x: 0; y: 0
						height: 520; width: 2; color: Constants.poly_grey
					}
					property bool isEnabled: currentEffects[effect]["controls"]["is_enabled"+(index+1)].value > 0.9


                   PolyControls.Button {
                        y: 17; x: 20
                        width: 155
                        height: 70
                        icon.width: 66
                        icon.height: 20
                        icon.source: (!isEnabled) ? "../icons/digit/euclidean/hidden.png" : "../icons/digit/euclidean/eye.png"
                        icon.color: isEnabled ? "black" : trackColor 

                        onClicked: {
                            knobs.ui_knob_change(effect, "is_enabled"+(index+1), 1 - isEnabled);
                            canvas.requestPaint()
                        }

                        background: Rectangle {
                            width: parent.width
                            height: parent.height
                            border.width: 2
                            border.color: (isEnabled) ? trackColor : Constants.poly_grey
                            color: (!isEnabled) ? Constants.poly_grey : trackColor
                            radius: 11
                        }
                    }

					ColumnLayout {
						id: columnLayout
						x: 20; y:90
						spacing: 10
						property int columnIndex: index
						property string selected_parameter: "steps"

						Repeater {
							model: ["steps", "beats", "shift"]

							RowLayout {
								spacing: -11


								Rectangle {
									width: 155
									height: 100
									z: 1
									color: modelData == columnLayout.selected_parameter && isEnabled ? trackColor : Constants.background_color 
									border.width: 2
									border.color: Constants.poly_grey
                                    radius: 11

                                    Text {
                                        x:0
                                        y:0
                                        height: 100
                                        width: 100
                                        text: modelData
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        color: modelData == columnLayout.selected_parameter && isEnabled ? Constants.background_color : isEnabled ? "white" : "#6E6E6E"
                                        font {
                                            pixelSize: 24
                                            capitalization: Font.AllUppercase
                                            family: mainFont.name
                                        }
                                    }

                                    Text {
                                        x:100
                                        y:0 
                                        height: 100
                                        width: 55
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: currentEffects[effect]["controls"][modelData + (columnLayout.columnIndex+1)].value 
                                        color: modelData == columnLayout.selected_parameter && isEnabled ? Constants.background_color : isEnabled ? trackColor : Constants.poly_grey
                                        font {
                                            pixelSize: 40
                                            capitalization: Font.AllUppercase
                                            family: mainFont.name
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: { 
                                            columnLayout.selected_parameter = modelData;

                                            if (modelData === "beats"){
                                                if ( currentEffects[effect]["controls"][modelData + (columnLayout.columnIndex+1)].value  < currentEffects[effect]["controls"]["steps" + (columnLayout.columnIndex+1)].value) 
                                                {  
                                                    plusButton.enabled = true;
                                                } else {
                                                    plusButton.enabled = false;
                                                } 
                                            }
                                            else {
                                                plusButton.enabled = true;
                                            }
                                        }
                                    }

								}

							}
						}
                        Item {
                            height:82

                           PolyControls.Button {
                                width: 72
                                height:82
                                y:2
                                x: 2
                                icon.source: "../icons/digit/euclidean/substract.png"
                                icon.color: isEnabled ? "white" : Constants.poly_grey
                                icon.width: 28
                                enabled: isEnabled 

                                onClicked: {
                                    var column = columnLayout.columnIndex
                                    var value =  currentEffects[effect]["controls"][columnLayout.selected_parameter + (column+1)].value 
                                    if (value > 0) {
                                        knobs.ui_knob_change(effect, columnLayout.selected_parameter+(column+1), value - 1);
                                        var l_steps =  currentEffects[effect]["controls"]["steps" + (column+1)].value 
                                        if (columnLayout.selected_parameter === "beats" && value <= l_steps) {
                                            plusButton.enabled = true;
                                        }
                                        canvas.requestPaint();
                                        if (columnLayout.selected_parameter === "steps") {
                                            if (value === currentEffects[effect]["controls"]["beats" + (column+1)].value) {
                                                knobs.ui_knob_change(effect, "beats"+(column+1), value - 1);
                                            }
                                            if (value === currentEffects[effect]["controls"]["shift" + (column+1)].value) {
                                                knobs.ui_knob_change(effect, "shift"+(column+1), value - 1 > 0 ? value - 1: 0);
                                            }
                                        }
                                    }
                                }

                                background: Rectangle {
                                    width: parent.width
                                    height: parent.height
                                    color: Constants.background_color
                                    radius: 11
                                }
                            }

                           PolyControls.Button {
                                id: plusButton
                                width: 72
                                height:82
                                y:2
                                x:84
                                icon.source: "../icons/digit/euclidean/add.png"
                                enabled: isEnabled
                                icon.color: isEnabled && enabled ? "black" : Constants.poly_grey
                                icon.width: 28

                                onClicked: {
                                    var column = columnLayout.columnIndex
                                    var value =  currentEffects[effect]["controls"][columnLayout.selected_parameter + (column+1)].value 
                                    var l_steps =  currentEffects[effect]["controls"]["steps" + (column+1)].value 
                                    if (columnLayout.selected_parameter === "beats" && value === l_steps) {
                                        //canvas.requestPaint();
                                        enabled = false;
                                    }
                                    else if (columnLayout.selected_parameter === "shift" && (value + 1) === l_steps) {
                                        // canvas.requestPaint();
                                        enabled = false;
                                    }
                                    else if (value >= 0 && value <= 32) {
                                        knobs.ui_knob_change(effect, columnLayout.selected_parameter+(column+1), value + 1);
                                        if (columnLayout.selected_parameter === "beats" && value + 1 === l_steps) {
                                            enabled = false;
                                        }

                                        canvas.requestPaint();
                                    }

                                }

                                background: Rectangle {
                                    width: parent.width
                                    height: parent.height
									color: isEnabled && enabled ? trackColor : Constants.poly_dark_grey
                                    radius: 11
                                }
                            }
                        }
					}
				}
			}
		}
	}
}
