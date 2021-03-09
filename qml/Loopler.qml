import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.3
import "../qml/polyconst.js" as Constants
import "../qml/looplerconst.js" as LoopMap

// ApplicationWindow {

//     Material.theme: Material.Dark
//     Material.primary: Material.Green
//     Material.accent: Material.Pink

//     readonly property int baseFontSize: 20 
//     readonly property int tabHeight: 60 
//     readonly property int fontSizeExtraSmall: baseFontSize * 0.8
//     readonly property int fontSizeMedium: baseFontSize * 1.5
//     readonly property int fontSizeLarge: baseFontSize * 2
//     readonly property int fontSizeExtraLarge: baseFontSize * 5
//     width: 800
//     height: 580
//     title: "Drag & drop example"
//     visible: true

Item {
    id: looper_widget
    property string effect_id: "none"
    property int tab_index: 0
    property int current_loop: loopler.selected_loop_num 
    property int global_focused: 0
    property bool midi_learn_select: false
    property bool midi_learn_waiting: false
    z: 3
    x: 0
    height:546
    width:1280

    // top row is 2 groups, 1 column, 1 grid
    //
    function midiLearn(param){
        if (midi_learn_select){
            loopler.ui_bind_request(param, current_loop);
            midi_learn_select = false;
            return true;
        }
        else {
            return false;
        }
    }

    StackLayout {
        width: 1280
        height: 522
        x: 0
        y: 0
        currentIndex: global_focused
        Item {
            width: 1280
            height: 522
            x: 0
            y: 0

            Item {
                x: 0
                y: 0
                width: parent.width
                height: 270
                Column {
                    x: 12
                    y: 12
                    width: 223
                    height: 522
                    spacing: 9
                
                    Repeater {
                        model: ["Commands", "Level / Sync", "Rate"]
                        Button {
                            height: 70
                            width: 170
                            text: modelData
                            checked: tab_index == index
                            onClicked: {
                                tab_index = index;
                            }

                            contentItem: Text {
                                text: modelData
                                color:  checked ? Constants.background_color : Constants.loopler_purple
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                // elide: Text.ElideRight
                                height: parent.height
                                wrapMode: Text.WordWrap
                                width: parent.width
                                font {
                                    pixelSize: 24
                                    capitalization: Font.AllUppercase
                                }
                            }

                            background: Rectangle {
                                width: parent.width
                                height: parent.height
                                color: checked ? Constants.loopler_purple : Constants.background_color  
                                border.width: 3
                                border.color: checked ? Constants.loopler_purple : Constants.poly_dark_grey  
                                radius: 10
                            }
                        }
                    }
                }

                Rectangle {
                    x:  198
                    y: 0
                    width: 2
                    z: 3
                    height: parent.height
                    color: Constants.poly_grey
                }

            }

            Rectangle {
                x:  0
                y: 270
                width: 1280
                height: 2
                z: 3
                color: Constants.poly_grey
            }


            // [  'filtatype', 'filtbtype', 'filtdtype',   'link', 'rt_speed']

            StackLayout {
                width: 1107
                height: 522
                x: 223
                y: 16
                currentIndex: tab_index

                Item { // commands
                    x: 2
                    y: 0
                    width: 1107
                    height: 270

                    Grid {
                        spacing: 13 
                        height: 270
                        columns: 6
                        width: parent.width

                        Repeater {
                            model: ["undo", "overdub", "replace", "solo", "oneshot", "reverse", 
                            "redo", "mute", "multiply", "insert", "substitute", "delay"]
                            // TODO Fix delay mode

                            IconButton {
                                id: commandButton
                                icon.source: "../icons/digit/loopler/commands/" + modelData + ".png"
                                width: 160
                                height: 110
                                topPadding: -25
                                icon.width: 80
                                icon.height: 70
                                has_border: true
                                // checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
                                checked: LoopMap.command_map[modelData] == loopler.loops[current_loop].state || (modelData == "solo" && loopler.loops[current_loop].is_soloed > 0) || (modelData == "reverse" && loopler.loops[current_loop].rate_output < 0)
                                onClicked: {
                                    if (looper_widget.midiLearn(modelData)){
                                        return;
                                    }
                                    if (modelData == "delay"){
                                        loopler.ui_set(current_loop, "delay_trigger", loopler.loops[current_loop].delay_trigger * -1);
                                    } else {
                                        loopler.ui_loop_command(current_loop, modelData);
                                    }
                                }
                                Material.background: "transparent"
                                Material.foreground: "transparent"
                                // Material.foreground: !checked ? Constants.poly_pink : "black"
                                // Material.foreground: !checked ? Constants.poly_pink : "black"
                                Material.accent: Constants.poly_pink 
                                radius: 3
                                Label {
                                    x: 0
                                    y: 76 
                                    text: modelData
                                    horizontalAlignment: Text.AlignHCenter
                                    width: 157
                                    height: 22
                                    z: 1
                                    color: "white"
                                    font {
                                        pixelSize: 20
                                        capitalization: Font.AllUppercase
                                    }
                                }
                                SequentialAnimation {
                                    id: blinkCommand;
                                    loops: Animation.Infinite;
                                    alwaysRunToEnd: true;
                                    running: LoopMap.next_command_map[modelData] == loopler.loops[current_loop].next_state
                                    ColorAnimation { target: commandButton; property: "Material.accent"; from: "yellow"; to: "white"; duration: 1000 }
                                    ColorAnimation { target: commandButton; property: "Material.accent"; to: "yellow"; from: "white"; duration: 1000 }
                                }
                            }

                        }
                    }
                }

                Item { // level Sync
                    x: 2
                    y: 0
                    width: 1107
                    height: 270

                    Column {
                        y: 20
                        x: 0
                        spacing: 30

                        Item {
                            id: loop_slider
                            height: 62
                            width:  714
                            property real multiplier: 1  
                            property string v_type: "float"
                            property bool is_log: false
                            property string selected_parameter: "feedback"
                            visible: v_type != "hide"


                            function logslider(position) {
                                // linear in to log out
                                // input position will be between 0 and 1
                                var minp = 0;
                                var maxp = 1;

                                // The output result should be between 20 an 20000
                                var minv = Math.log(20);
                                var maxv = Math.log(20000);

                                // calculate adjustment factor
                                var scale = (maxv-minv) / (maxp-minp);

                                return Math.exp(minv + scale*(position-minp));
                            }

                            function logposition(value) {
                                // log in to linear out
                                // input position will be between 0 and 1
                                var minp = 0;
                                var maxp = 1;

                                // The output result should be between 20 an 200000
                                var minv = Math.log(20);
                                var maxv = Math.log(20000);

                                // calculate adjustment factor
                                var scale = (maxv-minv) / (maxp-minp);

                                return (Math.log(value)-minv) / scale + minp;
                            }

                            Slider {
                                x: 0
                                y: 0
                                Material.foreground: Constants.short_rainbow[2]
                                visible: loop_slider.v_type != "bool"
                                snapMode: Slider.SnapAlways
                                stepSize: loop_slider.v_type == "int" ? 1.0 : 0.0
                                title: LoopMap.parameter_map[loop_slider.selected_parameter]
                                width: parent.width - 50
                                height:parent.height
                                // value: is_log ? logslider(currentEffects[current_effect]["controls"][row_param].value) : currentEffects[current_effect]["controls"][row_param].value
                                value: loopler.loops[current_loop][loop_slider.selected_parameter] 
                                from: loop_slider.is_log ? 20 : 0
                                to: loop_slider.is_log ? 20000 : 1
                                onMoved: {
                                    if (loop_slider.is_log){
                                        // knobs.ui_knob_change(current_effect, selected_parameter, logposition(value));
                                        //
                                    } else {
                                        // knobs.ui_knob_change(current_effect, selected_parameter, value);
                                        loopler.ui_set(current_loop, loop_slider.selected_parameter, value)
                                    }
                                }
                                // onPressedChanged: {
                                //     if (pressed){
                                //         knobs.set_knob_current_effect(current_effect, row_param);
                                //     }
                                // }
                            }


                            // IconButton {
                            //     id: midiBut
                            //     property bool learning: false
                            //     x: parent.width - 50
                            //     anchors.verticalCenter: parent.verticalCenter
                            //     icon.source: (currentEffects[current_effect]["controls"][row_param].cc == -1) ?  "../icons/digit/midi_inactive.png" : "../icons/digit/midi_active.png"  
                            //     width: 60
                            //     height: 60
                            //     onClicked: {
                            //         knobs.midi_learn(current_effect, row_param);
                            //         learning = !learning;
                            //     }
                            //     radius: 15

                            //     SequentialAnimation {
                            //                         id: blinkLearn;
                            //                         loops: Animation.Infinite;
                            //                         alwaysRunToEnd: true;
                            //                         running: currentEffects[current_effect]["controls"][row_param].cc == -1 && midiBut.learning;
                            //                         ColorAnimation { target: midiBut; property: "Material.foreground"; from: control.Material.foreground; to: "white"; duration: 1000 }
                            //                         ColorAnimation { target: midiBut; property: "Material.foreground"; to: control.Material.foreground; from: "white"; duration: 1000 }
                            //                     }
                            // }

                        }

                        Row {
                            spacing: 25 
                            height: 135
                            width: parent.width

                            Repeater {
                                model: ["input_gain", "rec_thresh", "feedback", "wet"]

                                ValueButton {
                                    width: 160
                                    height: 110
                                    // checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
                                    checked: loop_slider.selected_parameter == modelData
                                    onClicked: {
                                        if (looper_widget.midiLearn(modelData)){
                                            return;
                                        }
                                         loop_slider.selected_parameter = modelData
                                         loop_slider.Material.foreground = Constants.short_rainbow[index]
                                    }
                                    Material.foreground: Constants.short_rainbow[index]
                                    text: LoopMap.parameter_map[modelData]
                                    value: loopler.loops[current_loop][modelData].toFixed(2) //["feedback"].value // [loop_slider.selected_parameter]
                                }
                            }
                        }
                    }

                    Rectangle {
                        x:  779
                        y: -16
                        width: 2
                        height: 270
                        z: 3
                        color: Constants.poly_grey
                    }

                    Column {
                        x: 799
                        spacing: 14 
                        height: 270
                        width: parent.width

                        Repeater {
                            model: ["sync", "playback_sync", "use_feedback_play"]

                            PolyButton {
                                width: 252
                                height: 64
                                checked: loopler.loops[current_loop][modelData] == 1.0
                                // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                                onClicked: {
                                    if (looper_widget.midiLearn(modelData)){
                                        return;
                                    }
                                    loopler.ui_set(current_loop, modelData, 1 - loopler.loops[current_loop][modelData])
                                }
                                Material.foreground: Constants.short_rainbow[index]
                                Material.background: Constants.background_color
                                text: LoopMap.parameter_map[modelData]
                                font {
                                    pixelSize: 24
                                    capitalization: Font.AllUppercase
                                }
                            }

                        }
                    }
                }

                Item { // rate
                    x: 2
                    y: 0
                    width: 1107
                    height: 270

                    Column {
                        y: 20
                        x: 0
                        spacing: 30

                        Item {
                            Material.foreground: Constants.rainbow[0]
                            id: loop_slider_rate
                            height: 62
                            width:  714
                            property real multiplier: 1  
                            property bool is_log: false
                            property string selected_parameter: "pitch_shift"
                            property string v_type: selected_parameter == "pitch_shift" ? "int" : "float"
                            property bool force_update: false
                            visible: v_type != "hide"


                            function logslider(position) {
                                // linear in to log out
                                // input position will be between 0 and 1
                                var minp = 0;
                                var maxp = 1;

                                // The output result should be between 20 an 20000
                                var minv = Math.log(20);
                                var maxv = Math.log(20000);

                                // calculate adjustment factor
                                var scale = (maxv-minv) / (maxp-minp);

                                return Math.exp(minv + scale*(position-minp));
                            }

                            function logposition(value) {
                                // log in to linear out
                                // input position will be between 0 and 1
                                var minp = 0;
                                var maxp = 1;

                                // The output result should be between 20 an 200000
                                var minv = Math.log(20);
                                var maxv = Math.log(20000);

                                // calculate adjustment factor
                                var scale = (maxv-minv) / (maxp-minp);

                                return (Math.log(value)-minv) / scale + minp;
                            }

                            Slider {
                                x: 0
                                y: 0
                                Material.foreground: Constants.short_rainbow[0]
                                visible: loop_slider_rate.v_type != "bool"
                                snapMode: Slider.SnapAlways
                                stepSize: loop_slider_rate.v_type == "int" ? 1.0 : 0.0
                                title: LoopMap.parameter_map[loop_slider_rate.selected_parameter]
                                width: parent.width - 50
                                height:parent.height
                                value: loop_slider_rate.force_update, loopler.loops[current_loop][loop_slider_rate.selected_parameter] 
                                from: loop_slider_rate.selected_parameter  in LoopMap.param_bounds ? LoopMap.param_bounds[loop_slider_rate.selected_parameter][0] : 0
                                to: loop_slider_rate.selected_parameter in LoopMap.param_bounds ? LoopMap.param_bounds[loop_slider_rate.selected_parameter][1] : 1
                                onMoved: {
                                    if (loop_slider_rate.is_log){
                                        // knobs.ui_knob_change(current_effect, selected_parameter, logposition(value));
                                        //
                                    } else {
                                        // knobs.ui_knob_change(current_effect, selected_parameter, value);
                                        loopler.ui_set(current_loop, loop_slider_rate.selected_parameter, value)
                                    }
                                }
                                // onPressedChanged: {
                                //     if (pressed){
                                //         knobs.set_knob_current_effect(current_effect, row_param);
                                //     }
                                // }
                            }


                            // IconButton {
                            //     id: midiBut
                            //     property bool learning: false
                            //     x: parent.width - 50
                            //     anchors.verticalCenter: parent.verticalCenter
                            //     icon.source: (currentEffects[current_effect]["controls"][row_param].cc == -1) ?  "../icons/digit/midi_inactive.png" : "../icons/digit/midi_active.png"  
                            //     width: 60
                            //     height: 60
                            //     onClicked: {
                            //         knobs.midi_learn(current_effect, row_param);
                            //         learning = !learning;
                            //     }
                            //     radius: 15

                            //     SequentialAnimation {
                            //                         id: blinkLearn;
                            //                         loops: Animation.Infinite;
                            //                         alwaysRunToEnd: true;
                            //                         running: currentEffects[current_effect]["controls"][row_param].cc == -1 && midiBut.learning;
                            //                         ColorAnimation { target: midiBut; property: "Material.foreground"; from: control.Material.foreground; to: "white"; duration: 1000 }
                            //                         ColorAnimation { target: midiBut; property: "Material.foreground"; to: control.Material.foreground; from: "white"; duration: 1000 }
                            //                     }
                            // }

                        }

                        Row {
                            spacing: 25 
                            height: 135
                            width: parent.width

                            Repeater {
                                model: ["pitch_shift", "stretch_ratio", "scratch_pos", "rate"]

                                ValueButton {
                                    width: 160
                                    height: 110
                                    // checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
                                    checked: loop_slider_rate.selected_parameter == modelData
                                    onClicked: {
                                        if (looper_widget.midiLearn(modelData)){
                                            return;
                                        }
                                        loop_slider_rate.selected_parameter = modelData
                                        loop_slider_rate.Material.foreground = Constants.short_rainbow[index]
                                        loop_slider_rate.force_update = !(loop_slider_rate.force_update)
                                    }
                                    Material.foreground: Constants.short_rainbow[index]
                                    text: LoopMap.parameter_map[modelData]
                                    value: loopler.loops[current_loop][modelData].toFixed(2) //["feedback"].value // [loop_slider.selected_parameter]
                                }
                            }
                        }
                    }

                    Rectangle {
                        x:  779
                        y: -16
                        width: 2
                        height: 270
                        z: 3
                        color: Constants.poly_grey
                    }

                    Column {
                        x: 799
                        spacing: 14 
                        height: 270
                        width: parent.width

                        Repeater {
                            model: ["rate 1/2X", "rate 1X", "rate 2X"]

                            PolyButton {
                                width: 252
                                height: 64
                                checked: loopler.loops[current_loop][modelData] == 1.0
                                // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                                onClicked: {
                                    if (looper_widget.midiLearn(LoopMap.rate_bind_list[index])){
                                        return;
                                    }
                                    loopler.ui_set(current_loop, "rate", LoopMap.rate_list[index]);
                                }
                                Material.foreground: Constants.short_rainbow[index]
                                Material.background: Constants.background_color
                                text: modelData
                                font {
                                    pixelSize: 24
                                    capitalization: Font.AllUppercase
                                }
                            }

                        }
                    }
                }
            }

            Row {
                x: 0
                y: 283
                id: loop_row
                width: parent.width
                height: 250
                spacing: 13 

                ListView {
                    x: 0
                    y: 0
                    width: 1280
                    height: 296
                    clip: true
                    model: loopler.loops.length
                    orientation: ListView.Horizontal
                    spacing: 13 

                    delegate: PolyButton {
                        // property string l_effect: edit //.split(":")[1]
                        height: 221
                        width: 296
                        // text: modelData
                        checked: current_loop == index
                        onClicked: {
                            loopler.select_loop(index);
                        }

                        contentItem: Item { 
                            Image {
                                x: 12
                                y: 14
                                source: "../icons/digit/loopler/commands/"+ LoopMap.state_png_map[loopler.loops[index].state.toString()] +".png"
                            }

                            Text {
                                x: 108
                                y: 22
                                text: "loop "+modelData
                                color: "white" // checked ? Constants.background_color : "white"
                                // horizontalAlignment: Text.AlignHCenter
                                // verticalAlignment: Text.AlignVCenter
                                // elide: Text.ElideRight
                                height: 22
                                font {
                                    pixelSize: 22
                                    capitalization: Font.AllUppercase
                                }
                            }

                            Text {
                                x: 108
                                y: 51
                                text: "Cycle: "+ loopler.loops[index].cycle_len.toFixed(3) + "sec"
                                color: "white"
                                // horizontalAlignment: Text.AlignHCenter
                                // verticalAlignment: Text.AlignVCenter
                                // elide: Text.ElideRight
                                height: 22
                                font {
                                    pixelSize: 18
                                    capitalization: Font.AllUppercase
                                }
                            }
                            Text {
                                x: 108
                                y: 72
                                text: "total: "+ loopler.loops[index].loop_len.toFixed(2) + "sec"
                                color: "white"
                                // horizontalAlignment: Text.AlignHCenter
                                // verticalAlignment: Text.AlignVCenter
                                // elide: Text.ElideRight
                                height: 22
                                font {
                                    pixelSize: 18
                                    capitalization: Font.AllUppercase
                                }
                            }
                            Text {
                                x: 21
                                y: 115
                                text: "Waiting to sync"
                                color: Constants.loopler_purple
                                visible: loopler.loops[index].waiting > 0
                                // horizontalAlignment: Text.AlignHCenter
                                // verticalAlignment: Text.AlignVCenter
                                // elide: Text.ElideRight
                                height: 22
                                font {
                                    pixelSize: 18
                                    capitalization: Font.AllUppercase
                                }
                            }
                            Text {
                                x: 21
                                y: 135
                                text: LoopMap.state_map[loopler.loops[index].state]
                                color: Constants.loopler_purple
                                // horizontalAlignment: Text.AlignHCenter
                                // verticalAlignment: Text.AlignVCenter
                                // elide: Text.ElideRight
                                height: 22
                                font {
                                    pixelSize: 20
                                    capitalization: Font.AllUppercase
                                }
                            }
                            ProgressBar {
                                x: 21
                                y: 172
                                from: 0
                                to: loopler.loops[index].loop_len
                                value: loopler.loops[index].loop_pos
                                Material.background: "white"
                                Material.accent: Constants.loopler_purple 
                                // horizontalAlignment: Text.AlignHCenter
                                // verticalAlignment: Text.AlignVCenter
                                // elide: Text.ElideRight
                                width: 255
                                height: 22
                            }
                            // Text {
                            //     x: 144
                            //     y: 183
                            //     text: loopler.loops[index].loop_pos.toFixed(2) + " / " + loopler.loops[index].loop_len.toFixed(2) + " sec"
                            //     color: Constants.poly_yellow
                            //     // horizontalAlignment: Text.AlignHCenter
                            //     // verticalAlignment: Text.AlignVCenter
                            //     // elide: Text.ElideRight
                            //     height: 22
                            //     font {
                            //         pixelSize: 20
                            //         capitalization: Font.AllUppercase
                            //     }
                            // }
                        
                        } 
                        
                        

                        background: Rectangle {
                            width: parent.width
                            height: parent.height
                            color: Constants.background_color
                            border.width: 3
                            border.color: checked ? Constants.loopler_purple : Constants.poly_dark_grey  
                            radius: 10
                        }
                    }

                    footer: Item {
                        PolyButton {
                            // property string l_effect: edit //.split(":")[1]
                            x: 13
                            height: 221
                            width: 296
                            // text: modelData
                            onClicked: {
                                // current_loop = index;
                                // add new loop
                                loopler.ui_add_loop()
                            }

                            contentItem: Item { 
                                // Image {
                                //     x: 12
                                //     y: 14
                                //     source: "../icons/digit/loopler/commands/"+ LoopMap.state_png_map[loopler.loops[index].state.toString()] +".png"
                                // }

                                Text {
                                    x: 108
                                    y: 22
                                    text: "Add loop"
                                    color: Constants.poly_dark_grey // checked ? Constants.background_color : "white"
                                    // horizontalAlignment: Text.AlignHCenter
                                    // verticalAlignment: Text.AlignVCenter
                                    // elide: Text.ElideRight
                                    height: 22
                                    font {
                                        pixelSize: 22
                                        capitalization: Font.AllUppercase
                                    }
                                }
                            } 
                            
                            

                            background: Rectangle {
                                width: parent.width
                                height: parent.height
                                color: Constants.background_color
                                border.width: 3
                                border.color: Constants.poly_dark_grey  
                                radius: 10
                            }
                        }
                    }

                    ScrollIndicator.horizontal: ScrollIndicator {
                        x: 1
                        anchors.top: parent.top
                        parent: loop_row
                        anchors.bottom: parent.bottom
                    }
                }
            }
        }

        // global
        Item {
            width: 1280
            height: 522
            x: 0
            y: 0

            Column {
                x: 0
                y: 20
                height: 515
                spacing: 14 
                width: 339

                Text {
                    text: "SYNC TO"
                    color: "white"
                    font.pixelSize: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                PolySpin {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 285
                    height: 100
                    font.pixelSize: 24
                    items: ["internal", "midi", "none", "loop 1"]
                    Material.foreground: Constants.loopler_purple
                    value: LoopMap.sync_to_index[loopler.sync_source.toString()]
                    onValueModified: {
                        loopler.ui_set_global("sync_source", LoopMap.sync_to_map[Number(value)]);
                    }

                }

                Text {
                    text: "BPM"
                    color: "white"
                    font.pixelSize: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                SpinBox {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 285
                    height: 100
                    font.pixelSize: 36
                    from: 20
                    to: 320
                    Material.foreground: Constants.poly_pink
                    value: loopler.tempo
                    onValueModified: {
                        loopler.ui_set_global("tempo", Number(value));
                    }

                }

                Text {
                    text: "8TH/CYCLE"
                    color: "white"
                    font.pixelSize: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                SpinBox {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 285
                    height: 100
                    font.pixelSize: 36
                    from: 1
                    to: 128
                    Material.foreground: Constants.poly_pink
                    value: loopler.eighth_per_cycle
                    onValueModified: {
                        loopler.ui_set_global("eighth_per_cycle", Number(value));
                    }

                }
            
            }

            Rectangle {
                x:  339
                y: 0
                z: 3
                width: 2
                height: parent.height
                color: Constants.poly_dark_grey
            }
            Row {
                x: 380
                y: 70 
                width: 671
                spacing: 45

                Slider {
                    width: 120 
                    height: 370
                    orientation: Qt.Vertical
                    title: "cross fade"
                    value: loopler.loops[current_loop]["fade_samples"] 
                    from: 0.0
                    to: 1024
                    stepSize: 1
                    snapMode: Slider.SnapAlways
                    onMoved: {
                        loopler.ui_set_all("fade_samples", value)
                    }
                    Material.foreground: Constants.short_rainbow[0]

                }

                Slider {
                    width: 120 
                    height: 370
                    orientation: Qt.Vertical
                    title: "input gain"
                    value: loopler.input_gain
                    from: 0.0
                    to: 1
                    snapMode: Slider.SnapAlways
                    onMoved: {
                        loopler.ui_set_global("input_gain", value)
                    }
                    Material.foreground: Constants.short_rainbow[1]

                }

                Slider {
                    width: 120 
                    height: 370
                    orientation: Qt.Vertical
                    title: "wet"
                    value: loopler.wet
                    from: 0.0
                    to: 1
                    snapMode: Slider.SnapAlways
                    onMoved: {
                        loopler.ui_set_global("wet", value)
                    }
                    Material.foreground: Constants.short_rainbow[2]

                }

                Slider {
                    width: 120 
                    height: 370
                    orientation: Qt.Vertical
                    title: "dry"
                    value: loopler.wet
                    from: 0.0
                    to: 1
                    snapMode: Slider.SnapAlways
                    onMoved: {
                        loopler.ui_set_global("dry", value)
                    }
                    Material.foreground: Constants.short_rainbow[3]

                }

            
            }

            Rectangle {
                x:  1010
                y: 0
                z: 3
                width: 2
                height: parent.height
                color: Constants.poly_dark_grey
            }

            Column {
                x: 1034
                y: 20
                height: 515
                spacing: 14 
                width: 270

                Text {
                    text: "Quantize"
                    color: "white"
                    font {
                        pixelSize: 24
                        capitalization: Font.AllUppercase
                    }
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                PolySpin {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 252
                    height: 100
                    font.pixelSize: 24
                    Material.foreground: Constants.poly_green
                    value: loopler.loops[0].quantize
                    onValueModified: {
                        loopler.ui_set_all("quantize", Number(value));
                    }

                }


                Repeater {
                    model: ["mute_quantized", "overdub_quantized", "relative_sync"]

                    PolyButton {
                        width: 252
                        height: 64
                        checked: loopler.loops[0][modelData] == 1.0
                        // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                        onClicked: {
                            if (looper_widget.midiLearn(modelData)){
                                return;
                            }
                            loopler.ui_set_all(modelData, 1 - loopler.loops[current_loop][modelData])
                        }
                        Material.foreground: Constants.short_rainbow[index]
                        Material.background: Constants.background_color
                        text: LoopMap.parameter_map[modelData]
                        font {
                            pixelSize: 24
                            capitalization: Font.AllUppercase
                        }
                    }

                }
            
            }

        }
    }

    Rectangle {
        x:  0
        y: 520
        z: 3
        width: parent.width
        height: 2
        color: Constants.poly_dark_grey
    }

    IconButton {
        x: 198 
        y: 529
        width: 86
        height: 86
        icon.width: 86
        icon.height: 86
        // flat: false
        icon.source: "../icons/digit/loopler/nav_buttons/Midi.png"
        Material.background: Constants.background_color
        Material.foreground: midi_learn_select ? Constants.loopler_purple : "white"
        onClicked: {
            midi_learn_select = !midi_learn_select;
        }
        // HelpLabel {
        //     text: "Global"
        // }
    }

    IconButton {
        x: 317 
        y: 529
        width: 86
        height: 86
        icon.width: 86
        icon.height: 86
        // flat: false
        icon.source: "../icons/digit/loopler/nav_buttons/Global.png"
        Material.background: Constants.background_color
        Material.foreground: global_focused == 1 ? Constants.loopler_purple : "white"
        onClicked: {
            global_focused = 1 - global_focused 
        }
        // HelpLabel {
        //     text: "Global"
        // }
    }

    IconButton {
        x: 491 
        y: 529
        width: 86
        height: 86
        icon.width: 86
        icon.height: 86
        // flat: false
        icon.source: "../icons/digit/loopler/nav_buttons/Trigger.png"
        Material.background: Constants.background_color
        Material.foreground: LoopMap.command_map["trigger"] == loopler.loops[current_loop].state ? Constants.loopler_purple : "white"
        onClicked: {
            if (looper_widget.midiLearn("trigger")){
                return;
            }
            loopler.ui_loop_command(current_loop, "trigger");
        }
        // HelpLabel {
        //     text: "Global"
        // }
    }

    IconButton {
        x: 597 
        y: 529
        width: 86
        height: 86
        icon.width: 86
        icon.height: 86
        // flat: false
        icon.source: "../icons/digit/loopler/nav_buttons/Pause.png"
        Material.background: Constants.background_color
        Material.foreground: LoopMap.command_map["pause"] == loopler.loops[current_loop].state ? Constants.loopler_purple : "white"
        onClicked: {
            if (looper_widget.midiLearn("pause")){
                return;
            }
            loopler.ui_loop_command(current_loop, "pause");
        }
        // HelpLabel {
        //     text: "Global"
        // }
    }
    IconButton {
        x: 703 
        y: 529
        width: 86
        height: 86
        icon.width: 86
        icon.height: 86
        // flat: false
        icon.source: "../icons/digit/loopler/nav_buttons/Record.png"
        Material.background: Constants.background_color
        Material.foreground: LoopMap.command_map["record"] == loopler.loops[current_loop].state ? Constants.loopler_purple : "white"
        onClicked: {
            if (looper_widget.midiLearn("record")){
                return;
            }
            loopler.ui_loop_command(current_loop, "record");
        }
        // HelpLabel {
        //     text: "Global"
        // }
    }
    IconButton {
        x: 883 
        y: 529
        width: 86
        height: 86
        icon.width: 86
        icon.height: 86
        // flat: false
        icon.source: "../icons/digit/loopler/nav_buttons/Bin.png"
        Material.background: Constants.background_color
        onClicked: {
            loopler.ui_remove_loop()
        }
        // HelpLabel {
        //     text: "Global"
        // }
    }

}

