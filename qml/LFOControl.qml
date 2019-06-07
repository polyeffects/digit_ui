import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

// segment type / glide, value, time
// global glide, num_points, +- mode, repeat
Item {
    id: lfo_control
    width: 1200
    height: 550
    property bool snapping: true
    property bool synced: true
    property bool repeat: true
    property bool plus_minus: true
    property real global_glide: 1.0
    property int division: 4
    property int bars: 1
    property int active_width: 900
    property int num_lfos: 4
    property string current_parameter: "level"
    property int max_lfo_length: 30
    property var lfo_data: [{"time": 0.0, "level": 0.5, "TONE": 0.8, "FEEDBACK":0.2},
    {"time": 0.5, "level": 0.4, "TONE": 0.8, "FEEDBACK":0.2},
    {"time": 0.75, "level": 0.3, "TONE": 0.8, "FEEDBACK":0.2},
    {"time": 0.85, "level": 0.2, "TONE": 0.8, "FEEDBACK":0.2}]
    property var lfo_colors: [Material.Pink, Material.Purple, Material.LightBlue, Material.Amber]
    // PPQN * bars
    //
    function nearestDivision(x) {
        // given pixel find nearest pixel for division
        var grid_width = active_width/lfo_control.division;
        return Math.round(x / grid_width) * grid_width;
    }

    function beatToPixel(beat) {
        // given factional beat find pixel 
        return beat * active_width / lfo_control.bars;
    }

    function pixelToBeat(x) {
        // given factional beat find pixel 
        return x * lfo_control.bars / active_width;
    }

    function valueToPixel(index) {
        // work out a y pixel from level / tone / feedback value
        return (1 - lfo_data[index][current_parameter]) * height; // TODO values scaling?
    }

    function pixelToValue(index, y) {
        // given a y pixel set level / tone / feedback value
        lfo_data[index][current_parameter] = 1 - (y / height);
    }

    function secondsToPixel(t) {
        // log / inv log 0-max lfo length seconds TODO
        return t * active_width / max_lfo_length
    }

    function pixelToSeconds(x) {
        return x * max_lfo_length / active_width
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
                value: lfo_control.num_lfos
                to: 16
                onValueModified: {
                    lfo_control.num_lfos = value;
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
                    lfo_control.snapping = checked
                }
            }
            Switch {
                text: qsTr("REPEAT")
                bottomPadding: 0
                width: 200
                leftPadding: 0
                topPadding: 0
                rightPadding: 0
                checked: true
                onClicked: {
                    lfo_control.repeat = checked
                    mycanvas.requestPaint();
                }
            }
            Switch {
                text: qsTr("+-")
                bottomPadding: 0
                width: 200
                leftPadding: 0
                topPadding: 0
                rightPadding: 0
                checked: true
                onClicked: {
                    lfo_control.plus_minus = checked
                    mycanvas.requestPaint();
                }
            }
            ComboBox {
                width: 140
                enabled: lfo_control.synced
                textRole: "key"
                model: ListModel {
                    ListElement { key: "1/4"; value: 4 }
                    ListElement { key: "1/3"; value: 3 }
                    ListElement { key: "1/8"; value: 8 }
                    ListElement { key: "1/16"; value: 16 }
                    ListElement { key: "1/32"; value: 32 }
                }
                onActivated: {
                    lfo_control.division = model.get(index).value;
                    mycanvas.requestPaint();
                }
            }

            ComboBox {
                width: 140
                model: ["level", "TONE", "FEEDBACK"]
                onActivated: {
                    console.debug(model[index]);
                    lfo_control.current_parameter = model[index];
                }
            }
        }
    }

    Item {
        x: 300
        width: 900
        height: parent.height

        Repeater {
            model: lfo_control.num_lfos 
            Rectangle {
                id: rect
                width: 30
                height: 30
                z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
                color: Qt.rgba(0, 0, 0, 0)
                x: lfo_control.timeToPixel(lfo_control.lfo_data[index]["time"])
                y: mycanvas.y_at_level(lfo_control.lfo_data[index]["level"]);
                property point beginDrag
                property bool caught: false
                border { width:1; color: Material.color(Material.Indigo, Material.Shade200)}
                // border { 
                //     width:1; 
                    // color: lfo_control.point_updated, lfo_control.eq_data[index]["enabled"] ? Material.color(Material.Indigo, Material.Shade200) : Material.color(Material.Grey, Material.Shade200)  
                // }
                radius: width * 0.5
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
                            if(lfo_control.snapping && lfo_control.synced) {
                                rect.x = lfo_control.nearestDivision(rect.x);
                            }
                            lfo_control.lfo_data[index]["time"] = lfo_control.pixelToTime(rect.x);
                            lfo_control.lfo_data[index]["level"] = mycanvas.level_at_y(rect.y);
                            mycanvas.requestPaint();
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

            function setColorAlpha(color, alpha) {
                return Qt.hsla(color.hslHue, color.hslSaturation, color.hslLightness, alpha)
            }

            function y_at_level(value) {
                if (lfo_control.plus_minus){ // range is +-1 
                    return (height / 2) - (value * (height / 2));
                } else {
                    return ((1 - value) * height);
                }
            }

            function level_at_y(y) {
                // given a y pixel set level / tone / feedback value
                if (lfo_control.plus_minus){ // range is +-1 
                    return 1 - ((2 * y) / height);
                } else {
                    return  1 - (y / height);
                }
            }

            anchors {
                top: parent.top
                right:  parent.right
                bottom:  parent.bottom
            }

            width: lfo_control.active_width
            onPaint: {
                var ctx = getContext("2d");
                var mid_y = Math.round(height / 2.0);
                if (!lfo_control.plus_minus){
                    mid_y = height;
                }
                ctx.fillStyle = Material.background; //Qt.rgba(1, 1, 0, 1);
                ctx.fillRect(0, 0, width, height);
                ctx.strokeStyle = Qt.rgba(0.1,0.1,0.1,1);//setColorAlpha(Material.accent, 0.8);//Qt.rgba(0.1, 0.1, 0.1, 1);
                ctx.beginPath();
                // draw beat snap lines  
                if (lfo_control.synced){
                    ctx.fillStyle = Material.accent;//Qt.rgba(0.1, 0.1, 0.1, 1);

                    for (var i = 0; i < lfo_control.division; i++) {
                        var x = width/lfo_control.division*i;
                        ctx.moveTo(x, 0);
                        ctx.lineTo(x, height);
                    }
                }
                else
                {
                    // every second
                    ctx.fillStyle = Material.accent;//Qt.rgba(0.1, 0.1, 0.1, 1);

                    // ctx.fillRect(0, 0, 1, height);

                    for (var i = 1; i < lfo_control.max_lfo_length+1; i++) {
                        var x = (width/lfo_control.max_lfo_length)*i
                        ctx.fillRect(x, 0, 1, height);
                        // var x = width/Math.log(lfo_control.max_lfo_length+1)*Math.log(i)
                        // ctx.fillRect(x, 0, 1, height);
                        if (i < 4)
                        {
                            ctx.fillText(i-1, x+2, height - 10);
                        }
                    }
                }
                ctx.font = "14px sans-serif"
                ctx.lineWidth = 1.0;
                // draw center line at zero if +-
                // if (lfo_control.plus_minus){
                    ctx.moveTo(0, mid_y);
                    ctx.lineTo(width, mid_y);
                    ctx.stroke();
                    ctx.fillText("0", 0, mid_y-5); 
                // }

                ctx.beginPath();
                // draw curve between points
                // for points, draw based on segment type from previous value
                // first move to first point y val
                //

                ctx.strokeStyle = Material.accent;//setColorAlpha(Material.accent, 0.8);//Qt.rgba(0.1, 0.1, 0.1, 1);
                ctx.fillStyle = setColorAlpha(Material.accent, 0.3);//Qt.rgba(0.1, 0.1, 0.1, 1);
                ctx.moveTo(0, y_at_level(lfo_control.lfo_data[0]["level"]));
                var a;
                for (var i = 1; i < lfo_control.lfo_data.length; i++) {
                    // linear
                    a = lfo_control.timeToPixel(lfo_control.lfo_data[i]["time"])
                    var b = y_at_level(lfo_control.lfo_data[i]["level"])
                    ctx.lineTo(a, b);
                    console.log("drawing line", a, b, width, mid_y, ctx.lineWidth);    
                }
                if (lfo_control.repeat){
                    ctx.lineTo(width, y_at_level(lfo_control.lfo_data[0]["level"])); // if repeating
                } else {
                    ctx.lineTo(a, mid_y); // if repeating
                }

                ctx.stroke();
                ctx.lineTo(width, mid_y); 
                ctx.lineTo(0, mid_y);
                ctx.lineTo(0, y_at_level(lfo_control.lfo_data[0]["level"]));
                // ctx.fileStyle = Qt.rgba(0.5, 0.5, 0.5, 0.33 * shade);
                ctx.fill();

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
            text: lfo_control.synced ? "BEAT" : "TIME (S)"
            font.pixelSize: 20
            z: 2
            anchors.horizontalCenter: mycanvas.horizontalCenter
            anchors.top: mycanvas.bottom
            color: "grey"
        }

        Label {
            text: lfo_control.current_parameter
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

