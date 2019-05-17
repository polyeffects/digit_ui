import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

Window {

    Material.theme: Material.Dark
    Material.primary: Material.Green
    Material.accent: Material.Pink
    width: 1000
    height: 600
    title: "Drag & drop example"
    visible: true

    Item {
    
        id: time_scale
        width: 1000
        height: 600
        property bool snapping: true
        property bool synced: true
        property int division: 4
        property int bars: 1
        property int active_width: 800
        property int num_delays: 1
        property string current_parameter: "LEVEL"
        property int max_delay_length: 30
        property var delay_data: [{"time": 0.25, "LEVEL": 0.5, "TONE": 0.8, "FEEDBACK":0.2},
            {"time": 0.5, "LEVEL": 0.4, "TONE": 0.8, "FEEDBACK":0.2},
            {"time": 0.75, "LEVEL": 0.3, "TONE": 0.8, "FEEDBACK":0.2},
            {"time": 0.85, "LEVEL": 0.2, "TONE": 0.8, "FEEDBACK":0.2}]
        property var delay_colors: [Material.Pink, Material.Purple, Material.LightBlue, Material.Amber]
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

        function valueToPixel(index) {
            // work out a y pixel from level / tone / feedback value
            return (1 - delay_data[index][current_parameter]) * height; // TODO values scaling?
        }

        function pixelToValue(index, y) {
            // given a y pixel set level / tone / feedback value
            delay_data[index][current_parameter] = 1 - (y / height);
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

        // Row {
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
                    bottomPadding: 0
                    width: 200
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: true
                    onClicked: {
                        time_scale.snapping = checked
                    }
                }
                Switch {
                    text: qsTr("BEATS/SEC")
                    bottomPadding: 0
                    width: 200
                    leftPadding: 0
                    topPadding: 0
                    rightPadding: 0
                    checked: true
                    onClicked: {
                        time_scale.synced = checked
                    }
                }
                ComboBox {
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
                    model: ["LEVEL", "TONE", "FEEDBACK"]
                    onActivated: {
                        console.debug(model[index]);
                        time_scale.current_parameter = model[index];
                    }
                }
            }
        
        Item {
            x: 200
            width: 800
            height: parent.height

            Repeater {
                model: time_scale.num_delays 
                Rectangle {
                    id: rect
                    width: 50
                    height: 50
                    z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
                    color: Material.color(time_scale.delay_colors[index])
                    x: time_scale.timeToPixel(time_scale.delay_data[index]["time"])
                    y: time_scale.valueToPixel(index)
                    property point beginDrag
                    property bool caught: false
                    // border { width:1; color: Material.color(Material.Grey, Material.Shade100)}
                    radius: 5
                    Drag.active: mouseArea.drag.active

                    Text {
                        anchors.centerIn: parent
                        text: index
                        color: "white"
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        drag.target: parent
                        onPressed: {
                            rect.beginDrag = Qt.point(rect.x, rect.y);
                        }
                        onReleased: {
                            if(!rect.caught) {
                                backAnimX.from = rect.x;
                                backAnimX.to = beginDrag.x;
                                backAnimY.from = rect.y;
                                backAnimY.to = beginDrag.y;
                                backAnim.start()
                            }
                            else 
                            {
                                if(time_scale.snapping) {
                                    rect.x = time_scale.nearestDivision(rect.x);
                                }
                                time_scale.delay_data[index]["time"] = time_scale.pixelToTime(rect.x);
                                time_scale.pixelToValue(index, rect.y);
                            }
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

                        for (var i = 1; i < time_scale.division; i++) {
                            ctx.fillRect(width/time_scale.division*i, 0, 2, height);
                        }
                    }
                    else
                    {
                        // every second
                        ctx.fillStyle = Material.accent;//Qt.rgba(0.1, 0.1, 0.1, 1);

                        for (var i = 1; i < time_scale.max_delay_length; i++) {
                            ctx.fillRect(width/Math.log(time_scale.max_delay_length)*Math.log(i), 0, 2, height);
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
                text: "TIME"
                font.pixelSize: 20
                z: 2
                anchors.horizontalCenter: mycanvas.horizontalCenter
                anchors.bottom: mycanvas.bottom
                color: "grey"
            }

            Label {
                text: time_scale.current_parameter
                font.pixelSize: 20
                z: 2
                anchors.verticalCenter: mycanvas.verticalCenter
                anchors.right: mycanvas.left
                rotation : 270
                color: "grey"
            }
        }

        // }
    }
}

