import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

// Window {

//     Material.theme: Material.Dark
//     Material.primary: Material.Green
//     Material.accent: Material.Pink
//     width: 1000
//     height: 600
//     title: "Drag & drop example"
//     visible: true

    Item {
        id: time_scale
        width: 1200
        height: 550
        property bool snapping: true
        property bool synced: true
        property int division: 4
        property int bars: 1
        property int active_width: 900
        property int num_delays: 1
        property string current_parameter: "LEVEL"
        property int max_delay_length: 30
		property var delay_data: [{"time": polyValues["delay1"]["l_delay"].value, 
			"LEVEL": polyValues["delay1"]["carla_level"].value, 
			"TONE": polyValues["delay1"]["tone"].value, 
			"FEEDBACK": polyValues["delay1"]["feedback"].value},
			{"time": polyValues["delay2"]["l_delay"].value, 
			"LEVEL": polyValues["delay2"]["carla_level"].value, 
			"TONE": polyValues["delay2"]["tone"].value, 
			"FEEDBACK": polyValues["delay2"]["feedback"].value},
			{"time": polyValues["delay3"]["l_delay"].value, 
			"LEVEL": polyValues["delay3"]["carla_level"].value, 
			"TONE": polyValues["delay3"]["tone"].value, 
			"FEEDBACK": polyValues["delay3"]["feedback"].value},
			{"time": polyValues["delay4"]["l_delay"].value, 
			"LEVEL": polyValues["delay4"]["carla_level"].value, 
			"TONE": polyValues["delay4"]["tone"].value, 
			"FEEDBACK": polyValues["delay4"]["feedback"].value}]
        property var delay_colors: [Material.Pink, Material.Purple, Material.LightBlue, Material.Amber]
        property var parameter_map: {"LEVEL":"carla_level", "TONE":"tone", "FEEDBACK": "feedback"}
        // PPQN * bars
        //
        function nearestDivision(x) {
            // given pixel find nearest pixel for division
            var grid_width = active_width/time_scale.division;
            return Math.round(x / grid_width) * grid_width;
        }

        function beatToPixel(beat) {
            // given factional beat find pixel 
            return beat * active_width / time_scale.bars;
        }

        function pixelToBeat(x) {
            // given factional beat find pixel 
            return x * time_scale.bars / active_width;
        }

        function valueToPixel(v) {
            // work out a y pixel from level / tone / feedback value
            return (1 - v) * height; // TODO values scaling?
        }

        function pixelToValue(y) {
            // given a y pixel set level / tone / feedback value
            return 1 - (y / height);
        }

        function secondsToPixel(t) {
            // log / inv log 0-max delay length seconds TODO
            return t * active_width / max_delay_length
        }

        function pixelToSeconds(x) {
            return x * max_delay_length / active_width
        }

        function pixelToTime(x) {
            if (synced) {
                return pixelToBeat(x);
            } else {
                return pixelToSeconds(x);
            } 
        }

        function timeToPixel(t) {
            if (synced) {
                return beatToPixel(t);
            } else {
                return secondsToPixel(t);
            } 
        }

		function setColorAlpha(color, alpha) {
			return Qt.hsla(color.hslHue, color.hslSaturation, color.hslLightness, alpha)
		}

        // Row {
        PolyFrame {
            // background: Material.background
            width:200
            height:parent.height
            // Material.elevation: 2

            Column {
                width:200
                spacing: 10
                height:parent.height

                SpinBox {
                    from: 1
                    value: 1
                    to: 4
                    onValueModified: {
                        time_scale.num_delays = value;
                    }
                }

                Switch {
                    text: qsTr("SNAPPING")
					font.pixelSize: baseFontSize
                    bottomPadding: 0
                    width: 200
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: true
                    enabled: time_scale.synced
                    onClicked: {
                        time_scale.snapping = checked
                    }
                }
                Switch {
                    text: qsTr("TEMPO SYNC")
					font.pixelSize: baseFontSize
                    bottomPadding: 0
                    width: 200
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: true
                    onClicked: {
                        time_scale.synced = checked
                        mycanvas.requestPaint();
                    }
                }
                ComboBox {
                    width: 140
                    enabled: time_scale.synced
                    textRole: "key"
                    model: ListModel {
                        ListElement { key: "1/4"; value: 4 }
                        ListElement { key: "1/3"; value: 3 }
                        ListElement { key: "1/8"; value: 8 }
                        ListElement { key: "1/16"; value: 16 }
                        ListElement { key: "1/32"; value: 32 }
                    }
                    onActivated: {
                        time_scale.division = model.get(index).value;
                        mycanvas.requestPaint();
                    }
                }

                ComboBox {
                    width: 140
                    model: ["LEVEL", "TONE", "FEEDBACK"]
                    onActivated: {
                        console.debug(model[index]);
                        time_scale.current_parameter = model[index];
                    }
                }
            }
        }
        
        Item {
            x: 300
            width: 900
            height: parent.height

            Repeater {
                model: time_scale.num_delays 
                Rectangle {
                    id: rect
                    width: 50
                    height: 50
                    z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
                    // color: Material.color(time_scale.delay_colors[index])
					// color: Qt.rgba(0, 0, 0, 0)
					// color: setColorAlpha(Material.Pink, 0.1);//Qt.rgba(0.1, 0.1, 0.1, 1);
					color: Material.color(Material.Pink, Material.Shade200)
                    x: time_scale.timeToPixel(time_scale.delay_data[index]["time"])
                    y: time_scale.valueToPixel(time_scale.delay_data[index][time_scale.current_parameter])
                    property point beginDrag
                    property bool caught: false
                    // border { width:1; color: Material.color(Material.Cyan, Material.Shade100)}
					// border { width:2; color: Material.color(Material.Pink, Material.Shade200)}
                    radius: 5
                    Drag.active: mouseArea.drag.active

                    Text {
                        anchors.centerIn: parent
                        text: index
                        color: "white"
						font {
							pixelSize: fontSizeMedium
						}
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        drag.target: parent
                        onPressed: {
                            rect.beginDrag = Qt.point(rect.x, rect.y);
                        }
                        onReleased: {
							var in_x = rect.x;
							var in_y = rect.y;

                  			if(!rect.caught) {
								// clamp to bounds
								in_x = Math.min(Math.max(0, in_x), mycanvas.width);
								in_y = Math.min(Math.max(0, in_y), mycanvas.height);
							}
							if(time_scale.snapping && time_scale.synced) {
								in_x = time_scale.nearestDivision(in_x);
							}
							knobs.ui_knob_change("delay"+(index+1), "l_delay", time_scale.pixelToTime(in_x));
							knobs.ui_knob_change("delay"+(index+1), 
								time_scale.parameter_map[time_scale.current_parameter], 
								time_scale.pixelToValue(in_y));
							console.log("parameter map", 
								time_scale.parameter_map[time_scale.current_parameter], "value", 
								time_scale.pixelToValue(in_y),
								"rect.y", rect.y, "in_y", in_y);
                        }

                    }
                    ParallelAnimation {
                        id: backAnim
                        SpringAnimation { id: backAnimX; target: rect; property: "x"; duration: 500; spring: 2; damping: 0.2 }
                        SpringAnimation { id: backAnimY; target: rect; property: "y"; duration: 500; spring: 2; damping: 0.2 }
                    }
                }
            }

            Canvas {
                id: mycanvas
                anchors {
                    top: parent.top
                    right:  parent.right
                    bottom:  parent.bottom
                }
                width: time_scale.active_width
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.fillStyle = Material.background; //Qt.rgba(1, 1, 0, 1);
                    ctx.fillRect(0, 0, width, height);
                    // draw beat snap lines  
                    if (time_scale.synced){
                        ctx.fillStyle = Material.accent;//Qt.rgba(0.1, 0.1, 0.1, 1);

                        for (var i = 0; i < time_scale.division; i++) {
                            ctx.fillRect(width/time_scale.division*i, 0, 1, height);
                        }
                    }
                    else
                    {
                        // every second
                        ctx.fillStyle = Material.accent;//Qt.rgba(0.1, 0.1, 0.1, 1);

                        // ctx.fillRect(0, 0, 1, height);

                        for (var i = 1; i < time_scale.max_delay_length+1; i++) {
                            var x = (width/time_scale.max_delay_length)*i
                            ctx.fillRect(x, 0, 1, height);
                            // var x = width/Math.log(time_scale.max_delay_length+1)*Math.log(i)
                            // ctx.fillRect(x, 0, 1, height);
                            if (i < 4)
                            {
                                ctx.fillText(i-1, x+2, height - 10);
                            }
                        }
                    }

                }
                DropArea {
                    anchors.fill: parent
                    onEntered: drag.source.caught = true;
                    onExited: drag.source.caught = false;
                }
            }
            // Rectangle {
            //     anchors {
            //         top: parent.top
            //         right:  parent.right
            //         bottom:  parent.bottom
            //     }
            //     width: parent.width / 2
            //     color: "gold"
            //     DropArea {
            //         anchors.fill: parent
            //         onEntered: drag.source.caught = true;
            //         onExited: drag.source.caught = false;
            //     }
            // }
            Label {
                text: time_scale.synced ? "BEAT" : "TIME (S)"
                font.pixelSize: 20
                z: 2
                anchors.horizontalCenter: mycanvas.horizontalCenter
                anchors.top: mycanvas.bottom
                color: "grey"
            }

            Label {
                text: time_scale.current_parameter
                font.pixelSize: 20
                height:30
                width: 30
                // x: 200
                z: 2
                anchors.verticalCenter: mycanvas.verticalCenter
                anchors.right: mycanvas.left
                rotation : 270
                color: "grey"
            }
        }

        // }
    }
// }

