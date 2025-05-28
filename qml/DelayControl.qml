import "controls" as PolyControls
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
        height: 530
        property bool snapping: false
        property bool synced: true
        property int division: 4
        property int bars: delayNumBars.value 
        property int active_width: 900
        property int num_delays: 4
        property string current_parameter: "Amp_5"
        property int max_delay_length: 30
        property color assign_color: knobs.waiting != "" ? Material.color(Material.Cyan, Material.Shade400) : Material.color(Material.Pink, Material.Shade200) 
        property int updateCount: updateCounter, externalRefresh()
		// property var delay_data: [{"time": polyValues["delay1"]["Delay_1"].value, 
		// 	"LEVEL": polyValues["delay1"]["carla_level"].value, 
		// 	"TONE": polyValues["delay1"]["fb_tone"].value, 
		// 	"FEEDBACK": polyValues["delay1"]["feedback"].value},
		// 	{"time": polyValues["delay2"]["Delay_1"].value, 
		// 	"LEVEL": polyValues["delay2"]["carla_level"].value, 
		// 	"TONE": polyValues["delay2"]["fb_tone"].value, 
		// 	"FEEDBACK": polyValues["delay2"]["feedback"].value},
		// 	{"time": polyValues["delay3"]["Delay_1"].value, 
		// 	"LEVEL": polyValues["delay3"]["carla_level"].value, 
		// 	"TONE": polyValues["delay3"]["fb_tone"].value, 
		// 	"FEEDBACK": polyValues["delay3"]["feedback"].value},
		// 	{"time": polyValues["delay4"]["Delay_1"].value, 
		// 	"LEVEL": polyValues["delay4"]["carla_level"].value, 
		// 	"TONE": polyValues["delay4"]["fb_tone"].value, 
		// 	"FEEDBACK": polyValues["delay4"]["feedback"].value}]
        property var delay_data: [polyValues["delay1"], polyValues["delay2"], polyValues["delay3"], polyValues["delay4"]]
        property var delay_colors: [Material.Pink, Material.Purple, Material.LightBlue, Material.Amber]
        property var parameter_map: {"LEVEL":"Amp_5", "TONE":"FeedbackSm_6", "FEEDBACK": "Feedback_4", 
                                    "GLIDE": "DelayT60_3", "WARP":"Warp_2", "POST LVL": "carla_level" }
        property var inv_parameter_map: {'Amp_5': 'LEVEL', 'DelayT60_3': 'GLIDE', 'Feedback_4': 'FEEDBACK', 'Warp_2': 'WARP', 'FeedbackSm_6': 'TONE', "Delay_1": "TIME", "carla_level": "POST LVL"}
        property int current_delay: 1
        // PPQN * bars
        //
        function nearestDivision(x) {
            // given pixel find nearest pixel for division
            var grid_width = active_width/(time_scale.division*time_scale.bars);
            return Math.round(x / grid_width) * grid_width;
        }

        function convertRange( value, r1, r2 ) { 
            return ( value - r1[ 0 ] ) * ( r2[ 1 ] - r2[ 0 ] ) / ( r1[ 1 ] - r1[ 0 ] ) + r2[ 0 ];
        }

        function beatToPixel(beat) {
            // given factional beat find pixel 
            return beat * active_width / time_scale.bars / 4;
        }

        function pixelToBeat(x) {
            // given factional beat find pixel 
            return x * time_scale.bars * 4 / active_width;
        }

        function valueToPixel(rmin, rmax, v) {
            // work out a y pixel from level / tone / feedback value
            return (1 - convertRange(v, [rmin, rmax], [0, 1])) * height; // TODO values scaling?
        }

        function pixelToValue(rmin, rmax, y) {
            // given a y pixel set level / tone / feedback value
            return convertRange(1 - (y / height), [0, 1], [rmin, rmax]);
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

        function externalRefresh() {
            mycanvas.requestPaint();
            return updateCounter.value;
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

                //PolyControls.SpinBox {
                //     from: 1
                //     value: 1
                //     to: 4
                //     onValueModified: {
                //         time_scale.num_delays = value;
                //     }
                // }

               PolyControls.Switch {
                    text: qsTr("SNAPPING")
					font.pixelSize: baseFontSize
                    bottomPadding: 0
                    width: 200
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: time_scale.snapping
                    enabled: time_scale.synced
                    onClicked: {
                        time_scale.snapping = checked
                    }
                }
                //PolyControls.Switch {
                //     text: qsTr("TEMPO SYNC")
					// font.pixelSize: baseFontSize
                //     bottomPadding: 0
                //     width: 200
                //     leftPadding: 0
                //     topPadding: 0
                //     rightPadding: 0
                //     checked: true
                //     onClicked: {
                //         time_scale.synced = checked
                //         mycanvas.requestPaint();
                //     }
                // }
                PolyCombo {
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

                PolyCombo {
                    flat: true
                    id: control
                    width: 140
                    model: ["LEVEL", "TONE", "FEEDBACK", "GLIDE", "WARP"]
                    onActivated: {
                        // console.debug(model[index]);
                        time_scale.current_parameter = parameter_map[model[index]];
                    }
                }

                Label {
                    text: "# Bars"
                    font.pixelSize: baseFontSize
                    // color: "grey"
                }

               PolyControls.SpinBox {
                    value: bars
					font.pixelSize: baseFontSize
                    from: 1 
                    to: delayNumBars.rmax
                    onValueModified: {
                        delayNumBars.value = value;
                        mycanvas.requestPaint();
                        // console.log("rmax is ",  polyValues["delay1"]["Delay_1"].rmax)
                        polyValues["delay1"]["Delay_1"].rmax = value * 4
                        polyValues["delay2"]["Delay_1"].rmax = value * 4
                        polyValues["delay3"]["Delay_1"].rmax = value * 4
                        polyValues["delay4"]["Delay_1"].rmax = value * 4
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
                    width: 100
                    height: 100
                    radius: 10
                    color: Qt.rgba(0,0,0,0.0)
                    Rectangle {
                        x: 25
                        y: 25
                        width: 50
                        height: 50
                        radius: 5
                        color: time_scale.delay_data[index]["Amp_5"].value > 0 ? time_scale.assign_color: Material.color(Material.Grey, Material.Shade200)  
                    }
                    z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
                    // color: Material.color(time_scale.delay_colors[index])
					// color: Qt.rgba(0, 0, 0, 0)
					// color: setColorAlpha(Material.Pink, 0.1);//Qt.rgba(0.1, 0.1, 0.1, 1);
                    x: time_scale.timeToPixel(time_scale.delay_data[index]["Delay_1"].value) - (width / 2)
                    y: time_scale.valueToPixel(time_scale.delay_data[index][time_scale.current_parameter].rmin, 
                        time_scale.delay_data[index][time_scale.current_parameter].rmax, 
                        time_scale.delay_data[index][time_scale.current_parameter].value) - (width / 2)
                    property point beginDrag
                    property bool caught: false
                    // border { width:1; color: Material.color(Material.Cyan, Material.Shade100)}
					// border { width:2; color: Material.color(Material.Pink, Material.Shade200)}
                    Drag.active: mouseArea.drag.active

                    Text {
                        anchors.centerIn: parent
                        text: (index+1)
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
                            if (knobs.waiting != "") // mapping on
                            {
                                // pop up knob mapping selector
                                mappingPopup.set_mapping_choice("delay"+(index+1), "Delay_1", "TIME", 
                                    "delay"+(index+1), time_scale.current_parameter, 
                                    time_scale.inv_parameter_map[time_scale.current_parameter], true);
                            }
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

                  			if(!rect.caught) {
								// clamp to bounds
								in_x = Math.min(Math.max(-(width / 2), in_x), mycanvas.width - (width / 2));
								in_y = Math.min(Math.max(-(width / 2), in_y), mycanvas.height - (width / 2));
							}
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

                        for (var i = 0; i < (time_scale.division*time_scale.bars); i++) {
                            if ((i % time_scale.division) == 0)
                            {
                                ctx.fillRect((width/(time_scale.division*time_scale.bars))*i, 0, 3, height);
                                ctx.fillText(i-1, x+2, height - 10);
                            }
                            else
                            {
                                ctx.fillRect((width/(time_scale.division*time_scale.bars))*i, 0, 1, height);
                            }
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
                font.pixelSize: 26
                z: 2
                anchors.horizontalCenter: mycanvas.horizontalCenter
                anchors.top: mycanvas.bottom
                color: "white"
            }

            Label {
                text: time_scale.inv_parameter_map[time_scale.current_parameter]
                font.pixelSize: 26
                height:30
                width: 30
                // x: 200
                // x: -2
                z: 2
                anchors.verticalCenter: mycanvas.verticalCenter
                anchors.right: mycanvas.left
                anchors.rightMargin: 10
                rotation : 270
                color: "white"
            }
        }

        // }
        Component {
            id: editDelay
            Item {
                height:700
                width:1280
                Column {
                    id: editDelayCol
                    width: 1100
                    spacing: 20
                    anchors.centerIn: parent
                
                    GlowingLabel {
                        color: "#ffffff"
                        text: "DELAY "+(current_delay+1)
                        font {
                            pixelSize: fontSizeLarge
                        }
                    }
                    // property var parameter_map: {"LEVEL":"Amp_5", "TONE":"", "FEEDBACK": "", 
                    //                 "GLIDE": "", "WARP":""  }
                    DelayRow {
                        row_param: "Delay_1"
                    }
                    Row {
                        height: 40
                        spacing: 25
                        GlowingLabel {
                            text: "TIME (ms)"
                            width: 140
                        }

                       PolyControls.Slider {
                            width: 625
                            value: time_scale.delay_data[time_scale.current_delay]["Delay_1"].value 
                            from: time_scale.delay_data[time_scale.current_delay]["Delay_1"].rmin 
                            to: time_scale.delay_data[time_scale.current_delay]["Delay_1"].rmax 
                            onMoved: {
                                knobs.ui_knob_change("delay"+(time_scale.current_delay+1), "Delay_1", value);
                            }

                        }

                       PolyControls.SpinBox {
                            id: spinbox
                            value: time_scale.delay_data[time_scale.current_delay]["Delay_1"].value * (60 / currentBPM.value) * 1000
                            from: time_scale.delay_data[time_scale.current_delay]["Delay_1"].rmin * (60 / currentBPM.value) * 1000
                            to: time_scale.delay_data[time_scale.current_delay]["Delay_1"].rmax  * (60 / currentBPM.value) * 1000
                            stepSize: 10
                            // editable: true
                            onValueModified: {
                                knobs.ui_knob_change("delay"+(time_scale.current_delay+1), "Delay_1", value / 1000 / (60 / currentBPM.value));
                            }
                        }
                    }
                    DelayRow {
                        row_param: "Amp_5"
                    }
                    DelayRow {
                        row_param: "FeedbackSm_6"
                    }
                    DelayRow {
                        row_param: "Feedback_4"
                    }
                    DelayRow {
                        row_param: "DelayT60_3"
                    }
                    DelayRow {
                        row_param: "Warp_2"
                    }
                    // DelayRow {
                    //     row_param: "carla_level"
                    // }
                }
                

               PolyControls.Button {
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
    }
// }

