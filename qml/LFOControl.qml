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
    property string effect: "lfo1"
    property bool snapping: true
    property bool synced: true
    property bool repeat: true
    property bool plus_minus: false // disabled at the moment
    property real global_glide: 1.0
    property real speed_multiplier: 1.0
    property int division: 4
    property int bars: 1
    property int active_width: 900
    property int num_lfos: polyValues[effect]["num_points"].value
    property string current_parameter: "level"
    property string segment_type: "linear"
    property int selected_point: 1
    property int max_lfo_length: 30
    property int updateCount: updateCounter, externalRefresh()
    property var lfo_data: [{"time": polyValues[effect]["time1"].value, "level": polyValues[effect]["value1"].value, "style": polyValues[effect]["style1"].value},
        {"time": polyValues[effect]["time2"].value, "level": polyValues[effect]["value2"].value, "style": polyValues[effect]["style2"].value},
        {"time": polyValues[effect]["time3"].value, "level": polyValues[effect]["value3"].value, "style": polyValues[effect]["style3"].value},
        {"time": polyValues[effect]["time4"].value, "level": polyValues[effect]["value4"].value, "style": polyValues[effect]["style4"].value},
        {"time": polyValues[effect]["time5"].value, "level": polyValues[effect]["value5"].value, "style": polyValues[effect]["style5"].value},
        {"time": polyValues[effect]["time6"].value, "level": polyValues[effect]["value6"].value, "style": polyValues[effect]["style6"].value},
        {"time": polyValues[effect]["time7"].value, "level": polyValues[effect]["value7"].value, "style": polyValues[effect]["style7"].value},
        {"time": polyValues[effect]["time8"].value, "level": polyValues[effect]["value8"].value, "style": polyValues[effect]["style8"].value},
        {"time": polyValues[effect]["time9"].value, "level": polyValues[effect]["value9"].value, "style": polyValues[effect]["style9"].value},
        {"time": polyValues[effect]["time10"].value, "level": polyValues[effect]["value10"].value, "style": polyValues[effect]["style10"].value},
        {"time": polyValues[effect]["time11"].value, "level": polyValues[effect]["value11"].value, "style": polyValues[effect]["style11"].value},
        {"time": polyValues[effect]["time12"].value, "level": polyValues[effect]["value12"].value, "style": polyValues[effect]["style12"].value},
        {"time": polyValues[effect]["time13"].value, "level": polyValues[effect]["value13"].value, "style": polyValues[effect]["style13"].value},
        {"time": polyValues[effect]["time14"].value, "level": polyValues[effect]["value14"].value, "style": polyValues[effect]["style14"].value},
        {"time": polyValues[effect]["time15"].value, "level": polyValues[effect]["value15"].value, "style": polyValues[effect]["style15"].value},
        {"time": polyValues[effect]["time16"].value, "level": polyValues[effect]["value16"].value, "style": polyValues[effect]["style16"].value}]
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

    function externalRefresh() {
        console.log("external refresh");
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

            SpinBox {
                from: 1
                value: lfo_control.num_lfos
                to: 64
                onValueModified: {
                    if (lfo_control.num_lfos < value){
                        // push
                        // time of last point
                        var t = lfo_control.lfo_data[lfo_control.num_lfos-1]["time"]
                        var v = lfo_control.lfo_data[lfo_control.num_lfos-1]["level"] // same level as previous
                        knobs.ui_knob_change(effect, "time"+(lfo_control.num_lfos+1), Math.min(t + 0.05, bars)) 
                        knobs.ui_knob_change(effect, "value"+(lfo_control.num_lfos+1), v) 
                    }
                    console.log("value is ", value, "num_lfos", lfo_control.num_lfos);
                    knobs.ui_knob_change(effect, "num_points", value);
                    // push or pop from array, putting the new value after the previous one
                    mycanvas.requestPaint();
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
                onClicked: {
                    lfo_control.snapping = checked
                }
            }
            // Switch {
            //     text: qsTr("REPEAT")
            //     bottomPadding: 0
            //     width: 200
            //     leftPadding: 0
            //     topPadding: 0
            //     rightPadding: 0
            //     checked: true
            //     onClicked: {
            //         lfo_control.repeat = checked
            //         mycanvas.requestPaint();
            //     }
            // }
            // Switch {
            //     text: qsTr("+-")
            //     font.pixelSize: baseFontSize
            //     bottomPadding: 0
            //     width: 200
            //     leftPadding: 0
            //     topPadding: 0
            //     rightPadding: 0
            //     checked: true
            //     onClicked: {
            //         lfo_control.plus_minus = checked
            //         mycanvas.requestPaint();
            //     }
            // }
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
                flat: true
            }

            ComboBox {
                width: 140
                model: ["linear", "smooth", "accell", "decell", "step", "random"]
                currentIndex: lfo_control.lfo_data[selected_point]["style"]
                onActivated: {
                    // console.debug(model[index]);
                    knobs.ui_knob_change(effect, "style"+(selected_point+1), index);
                    // lfo_control.lfo_data[selected_point]["style"] = index
                    console.log("setting style", selected_point, index);
                    mycanvas.requestPaint();
                }
                flat: true
            }

            Button {
                text: "ASSIGN"
                flat: true
                font.pixelSize: baseFontSize
                width: 140
                onClicked: {
                    // set learn
                    knobs.set_waiting(effect)
                }
            }

            // GlowingLabel {
            //     color: "#ffffff"
            //     text: qsTr("SPEED")
            //     font {
            //         pixelSize: baseFontSize
            //     }
            // }

            // MixerDial {
            //     effect: "LFO"
            //     param: "Speed"
            //     value: 1
            //     from: 0.0625
            //     to: 16
            // }
            
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
                width: 100
                height: 100
                radius: width * 0.5
                Rectangle {
                    x: 25
                    y: 25
                    width: 50
                    height: 50
                    color: Qt.rgba(0, 0, 0, 0)
                    border { width:1; color: Material.color(Material.Indigo, Material.Shade200)}
                    radius: width * 0.5
                }
                color: Qt.rgba(0,0,0,0.0)
                z: mouseArea.drag.active ||  mouseArea.pressed ? 2 : 1
                x: lfo_control.timeToPixel(lfo_control.lfo_data[index]["time"]) - (width / 2)
                y: mycanvas.y_at_level(lfo_control.lfo_data[index]["level"]) - (width / 2)
                property point beginDrag
                property bool caught: false
                // border { 
                //     width:1; 
                // color: lfo_control.point_updated, lfo_control.eq_data[index]["enabled"] ?
                // Material.color(Material.Indigo, Material.Shade200) : Material.color(Material.Grey, Material.Shade200)  
                // }
                Drag.active: mouseArea.drag.active

                Text {
                    anchors.centerIn: parent
                    text: index
                    color: "white"
                    font.pixelSize: fontSizeMedium
                }
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    drag.target: parent
                    onPressed: {
                        rect.beginDrag = Qt.point(rect.x, rect.y);
                        lfo_control.selected_point = index;
                    }
                    onReleased: {
                        var in_x = rect.x;
                        var in_y = rect.y;

                        if(!rect.caught) {
                            // clamp to bounds
                            in_x = Math.min(Math.max(-(width / 2), in_x), mycanvas.width - (width / 2));
                            in_y = Math.min(Math.max(-(width / 2), in_y), mycanvas.height - (width / 2));
                        }
                        if(lfo_control.snapping && lfo_control.synced) {
                            in_x = lfo_control.nearestDivision(in_x) - (width / 2);
                        }
                        if (index == 0){ // first point, fix to zero
                            in_x = 0;
                        }
                        else {
							in_x = in_x + (width / 2);
							in_y = in_y + (width / 2);
                            // if this points x is less than the previous x make equal (monotonic)
                            if (lfo_control.lfo_data[index-1]["time"] > lfo_control.pixelToTime(in_x)){
                                in_x = lfo_control.timeToPixel(lfo_control.lfo_data[index-1]["time"]);
                            }
                            // if this points x is > than the next x make equal (monotonic)
                            if (lfo_control.num_lfos > index+1 && (lfo_control.lfo_data[index+1]["time"] < lfo_control.pixelToTime(in_x))){
                                in_x = lfo_control.timeToPixel(lfo_control.lfo_data[index+1]["time"]);
                            }
                        }
                        knobs.ui_knob_change(effect, "time"+(index+1), lfo_control.pixelToTime(in_x)); 
                        knobs.ui_knob_change(effect, "value"+(index+1), mycanvas.level_at_y(in_y));
                        mycanvas.requestPaint();
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

            function bend1(x, a){
                x += 0.25;
                x += a * math.sin(x * 2.0 * Math.PI) / (2.0 * Math.PI);
                x -= 0.25;
                return x;
            }

            function bend2(x, a){
                x += a * Math.sin(x * 2.0 * Math.PI) / (2.0 * Math.PI);
                return x;
            }

            function bend3(x, a){
                a = 0.5 * a;
                x = x - a * x * x + a;
                x = x - a * x * x + a;
                return x;
            }

            function clamp(x, lowerlimit, upperlimit) {
                if (x < lowerlimit){
                    x = lowerlimit;
                }
                if (x > upperlimit){
                    x = upperlimit;
                }
                return x;
            }
            
            function smoothstep(x) {
                // Scale, bias and saturate x to 0..1 range
                // x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0); 
                // Evaluate polynomialv
                //
                return x * x * (3 - 2 * x);
            }

            function accell(x){
                return x * x;
            }

            function decell(v){
                return 1 - (1 - v) * (1 - v); 
            }

            function random(v){
                return Math.random() * v;
            }

            function linear_interpolate(y1, y2, mu){
                return (y1*(1-mu)+y2*mu);
            }

            function cosine_interpolate(y1, y2, mu) {
                var mu2;
                mu2 = (1-Math.cos(mu*Math.PI))/2;
                return (y1*(1-mu2)+y2*mu2);
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
                var seg_x1;
                var seg_x2;
                    // draw from current point to next point based on segment type
                for (var i = 0; i < lfo_control.num_lfos; i++) {
                    var seg_y1;
                    var seg_y2;
                    var seg_type = lfo_control.lfo_data[i]["style"]
                    seg_x1 = lfo_control.timeToPixel(lfo_control.lfo_data[i]["time"])
                    seg_y1 = y_at_level(lfo_control.lfo_data[i]["level"])

                    if (i == lfo_control.num_lfos - 1){
                        if (!lfo_control.repeat){
                            break; // don't need to draw to end
                        }
                        seg_x2 = width;
                        seg_y2 = y_at_level(lfo_control.lfo_data[0]["level"])
                    } else {
                        seg_x2 = lfo_control.timeToPixel(lfo_control.lfo_data[i+1]["time"])
                        seg_y2 = y_at_level(lfo_control.lfo_data[i+1]["level"])
                    }


                    // linear
                    // var m = (seg_y2 - seg_y1) / (seg_x2 - seg_x1);
                    var mu; // diff x
                    var cur_y;
                    var bend_factor;

// for (var j = seg_x1; j < seg_x2; j++) {
// {

                    for (var j = seg_x1; j < seg_x2; j++) {
                        // var v = j - seg_x21 / seg_x2;
                        var mu = (j - seg_x1) / (seg_x2 - seg_x1); // 0-1 how far through seg
                        // v = v; // linear
                        if (seg_type < 0.5) {
                            // do nothing 
                        }
                        else if (seg_type <= 1) {
                            mu = smoothstep(mu);
                        } else if (seg_type <= 2) {
                            mu = accell(mu);
                        } else if (seg_type <= 3) {
                            mu = decell(mu);
                        } else if (seg_type <= 4) {
                            mu = 0;
                        } else if (seg_type <= 5) {
                            mu = random(mu);
                        }
                        //if linear do nothing
                        // cur_y = cosine_interpolate(seg_y1, seg_y2, mu);
                        cur_y = (seg_y1 * (1-mu)+seg_y2*mu);
                        ctx.lineTo(j, cur_y);
                    }
                    console.log("drawing line", j, "seg_type", seg_type, "mu", mu, seg_x1, seg_x2, cur_y);    
                } 
                if (!lfo_control.repeat){
                    // ctx.lineTo(width, y_at_level(lfo_control.lfo_data[0]["level"])); // if repeating
                // } else {
                    ctx.lineTo(seg_x2, mid_y); 
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

