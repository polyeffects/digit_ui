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

					RowLayout {
						id: grid
						y: 17; x: 20
						spacing: 20
						property int columnIndex: index

						Repeater {
							model: ListModel {
								id: iconModel
								ListElement { name: "eye"; iconWidth: 66; iconHeight: 20}
								// ListElement { name: "restart"; iconWidth: 30; iconHeight: 30}
							}

							Button {
								Layout.minimumWidth: 140
								Layout.minimumHeight: 70
								icon.width: iconWidth
								icon.height: iconHeight
								icon.source: (!isEnabled && index == 0) ? "../icons/digit/euclidean/hidden.png" : "../icons/digit/euclidean/" + name + ".png"
								icon.color: isEnabled ? (index == 0) ? "black" : trackColor : (index == 0) ? trackColor : Constants.poly_grey

								onClicked: {
									if (index === 0) {
										knobs.ui_knob_change(effect, "is_enabled"+(grid.columnIndex+1), 1 - isEnabled);
										canvas.requestPaint()
									}
								}

								background: Rectangle {
									width: parent.width
									height: parent.height
									border.width: 2
									border.color: (isEnabled && index == 0) ? trackColor : Constants.poly_grey
									color: (!isEnabled && index == 0) ? Constants.poly_grey : (index == 0) ? trackColor : Constants.background_color
									radius: 11
								}
							}
						}
					}

					ColumnLayout {
						id: columnLayout
						x: 20; y:171
						spacing: 19
						property int columnIndex: index

						Repeater {
							model: ["steps", "beats", "shift"]

							RowLayout {
								spacing: -11

								Rectangle {
									width: 54
									height:65
									border.width: 2
									border.color: Constants.poly_grey
									color: Constants.background_color
									radius: 11

									Button {
										width: 41
										height:60
										y:2
										x: 2
										icon.source: "../icons/digit/euclidean/substract.png"
										icon.color: isEnabled ? "white" : Constants.poly_grey
										icon.width: 17
										enabled: isEnabled

										onClicked: {
											var column = columnLayout.columnIndex
											var value =  currentEffects[effect]["controls"][modelData + (column+1)].value 
											if (value > 0) {
												knobs.ui_knob_change(effect, modelData+(column+1), value - 1);
												canvas.requestPaint();
												if (modelData === "steps") {
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
								}

								Rectangle {
									width: 70
									height: 65
									z: 1
									color: Constants.background_color
									border.width: 2
									border.color: Constants.poly_grey

									Rectangle {
										x:2
										y:2
										height: 30
										width: 65
										color: Constants.background_color

										Text {
											text: modelData
											color: isEnabled ? "white" : "#6E6E6E"
											anchors.centerIn: parent
											font {
												pixelSize: 20
												capitalization: Font.AllUppercase
												family: mainFont.name
											}
										}
									}

									Rectangle {
										x:2
										y: 29
										height: 30
										width: 65
										color: Constants.background_color

										Text {
											text: currentEffects[effect]["controls"][modelData + (columnLayout.columnIndex+1)].value 
											color: isEnabled ? trackColor : Constants.poly_grey
											anchors.centerIn: parent
											font {
												pixelSize: 30
												capitalization: Font.AllUppercase
												family: mainFont.name
											}
										}
									}
								}

								Rectangle {
									width: 54
									height:65
									border.width: 2
									border.color: Constants.poly_grey
									color: Constants.background_color
									radius: 11

									Button {
										width: 41
										height:60
										y:2
										x: 11
										icon.source: "../icons/digit/euclidean/add.png"
										icon.color: isEnabled ? "white" : Constants.poly_grey
										icon.width: 17
										enabled: isEnabled

										onClicked: {
											var column = columnLayout.columnIndex
											var value =  currentEffects[effect]["controls"][modelData + (column+1)].value 
											var l_steps =  currentEffects[effect]["controls"]["steps" + (column+1)].value 
											if (modelData === "beats" && value === l_steps) {
												//canvas.requestPaint();
											}
											else if (modelData === "shift" && (value + 1) === l_steps) {
												// canvas.requestPaint();
											}
											else if (value >= 0 && value <= 32) {
												knobs.ui_knob_change(effect, modelData+(column+1), value + 1);
												canvas.requestPaint();
											}

										}

										background: Rectangle {
											width: parent.width
											height: parent.height
											color: Constants.background_color
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
	}
}
