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
    property int actual_current_loop: loopler.selected_loop_num 
    property int current_loop: loopler.selected_loop_num > 0 ? loopler.selected_loop_num : 0
    property int binding_current_loop: 0
    property int global_focused: 0
    property bool midi_learn_select: false
    property bool midi_learn_waiting: loopler.midi_learn_waiting
    z: 3
    x: 0
    height:613
    width:1280

    // top row is 2 groups, 1 column, 1 grid
    //
    function midiLearn(param){
        if (midi_learn_select){
            loopler.ui_bind_request(param, binding_current_loop);
            midi_learn_select = false;
            loopler.ui_unset_current_command();
            return true;
        }
        else {
            return false;
        }
    }

    Component {
        id: looplerMain
        Item { 
            height:613
            width:1280

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
                        height: 520
                        Column {
                            x: 12
                            y: 18
                            width: 223
                            height: 520
                            spacing: 12

                            Repeater {
                                model: ["Commands", "Level / Sync", "Rate"]
                                Button {
                                    height: 80
                                    width: 130
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
                            Button {
                                id: g_but
                                height: 210
                                width: 130
                                text: "Global Settings"
                                checked: tab_index == 3
                                onClicked: {
                                    tab_index = 3;
                                }

                                contentItem: Item {
                                    height: parent.height
                                    width: parent.width
                                    Image {
                                        x: 28
                                        y: 14
                                        source: g_but.checked ? "../icons/digit/loopler/global-1.png" :"../icons/digit/loopler/global.png" 
                                    }
                                    Text {
                                        y: 128
                                        text: "Global Settings"
                                        color:  g_but.checked ? Constants.background_color : Constants.loopler_purple
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        // elide: Text.ElideRight
                                        height: 40
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                        font {
                                            pixelSize: 24
                                            capitalization: Font.AllUppercase
                                        }
                                    }
                                }

                                background: Rectangle {
                                    width: parent.width
                                    height: parent.height
                                    color: g_but.checked ? Constants.loopler_purple : Constants.background_color  
                                    border.width: 3
                                    border.color: g_but.checked ? Constants.loopler_purple : Constants.poly_dark_grey  
                                    radius: 10
                                }
                            }
                        }

                        Rectangle {
                            x:  158
                            y: 0
                            width: 2
                            z: 3
                            height: parent.height
                            color: Constants.poly_grey
                        }

                    }

                    Rectangle {
                        visible: tab_index != 3
                        x:  158
                        y: 270
                        width: 1128
                        height: 2
                        z: 3
                        color: Constants.poly_grey
                    }


                    // [  'filtatype', 'filtbtype', 'filtdtype',   'link', 'rt_speed']

                    StackLayout {
                        width: 1107
                        height: 522
                        x: 177
                        y: 16
                        currentIndex: tab_index

                        Item { // commands
                            x: 2
                            y: 0
                            width: 1107
                            height: 270

                            Row {
                                spacing: 12 
                                height: 120
                                width: parent.width

                                Repeater {
                                    model: ["undo", "redo", "record", "overdub", "trigger", "reverse", "pause"]
                                    // TODO Fix delay mode

                                    IconButton {
                                        id: commandButton
                                        icon.source: checked ? "../icons/digit/loopler/commands/active/" + modelData + ".png" : "../icons/digit/loopler/commands/inactive/" + modelData + ".png" 
                                        width: 140
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
                                                loopler.ui_set_delay(actual_current_loop);
                                            } else {
                                                loopler.ui_loop_command(actual_current_loop, modelData);
                                            }
                                            loopler.ui_unset_current_command();
                                        }
                                        onPressed: {
                                            if (modelData == "delay"){
                                                loopler.ui_set_current_command("ui_set_delay", [actual_current_loop]);
                                            } else {
                                                loopler.ui_set_current_command("ui_loop_command", [actual_current_loop, modelData]);
                                            }

                                        }
                                        // onReleased: {
                                        // }
                                        Material.background: checked ? Constants.loopler_rainbow[index] : "transparent"
                                        Material.foreground: "transparent"
                                        Material.accent: Constants.loopler_rainbow[index] 
                                        radius: 3
                                        Label {
                                            x: 0
                                            y: 76 
                                            text: modelData
                                            horizontalAlignment: Text.AlignHCenter
                                            width: 140
                                            height: 22
                                            z: 1
                                            color: checked ? "black" : "white"
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
                            Row {
                                y: 130
                                spacing: 13 
                                height: 120
                                width: parent.width

                                Repeater {
                                    model: ["multiply", "replace", "insert", "substitute", "delay", "oneshot", "solo", "mute"]
                                    // TODO Fix delay mode

                                    IconButton {
                                        id: commandButton
                                        icon.source: checked ? "../icons/digit/loopler/commands/active/" + modelData + ".png" : "../icons/digit/loopler/commands/inactive/" + modelData + ".png" 
                                        width: 120
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
                                                loopler.ui_set_delay(current_loop);
                                            } else {
                                                loopler.ui_loop_command(current_loop, modelData);
                                            }
                                            loopler.ui_unset_current_command();
                                        }
                                        onPressed: {
                                            if (modelData == "delay"){
                                                loopler.ui_set_current_command("ui_set_delay", [current_loop]);
                                            } else {
                                                loopler.ui_set_current_command("ui_loop_command", [current_loop, modelData]);
                                            }

                                        }
                                        // onReleased: {
                                        // }
                                        Material.background: checked ? Constants.loopler_rainbow[index+7] : "transparent"
                                        Material.foreground: "transparent"
                                        Material.accent: Constants.loopler_rainbow[index+7] 
                                        radius: 3
                                        Label {
                                            x: 0
                                            y: 76 
                                            text: modelData
                                            horizontalAlignment: Text.AlignHCenter
                                            width: 120
                                            height: 22
                                            z: 1
                                            color: checked ? "black" : "white"
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
                                    Material.foreground: Constants.short_rainbow[2]



                                    Slider {
                                        x: 0
                                        y: 0
                                        Material.foreground: parent.Material.foreground
                                        visible: loop_slider.v_type != "bool"
                                        snapMode: Slider.SnapAlways
                                        stepSize: loop_slider.v_type == "int" ? 1.0 : 0.0
                                        title: LoopMap.parameter_map[loop_slider.selected_parameter]
                                        width: parent.width - 50
                                        height:parent.height
                                        value: loopler.loops[current_loop][loop_slider.selected_parameter] 
                                        from: loop_slider.is_log ? 20 : 0
                                        to: loop_slider.is_log ? 20000 : 1
                                        onMoved: {
                                            loopler.ui_set(current_loop, loop_slider.selected_parameter, value)
                                        }
                                        onPressedChanged: {
                                            if (pressed){
                                                knobs.set_loopler_knob("ui_set", current_loop, loop_slider.selected_parameter, from, to);
                                            }
                                        }
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
                                                var from = modelData  in LoopMap.param_bounds ? LoopMap.param_bounds[modelData][0] : 0
                                                var to = modelData in LoopMap.param_bounds ? LoopMap.param_bounds[modelData][1] : 1
                                                knobs.set_loopler_knob("ui_set", current_loop, modelData, from, to);
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

                            Flow {
                                x: 799
                                spacing: 14 
                                height: 270
                                width: 270

                                Repeater {
                                    model: ["sync", "round", "playback_sync", "use_feedback_play"]

                                    PolyButton {
                                        width: index > 1 ? 252  : 126
                                        height: 64
                                        checked: loopler.loops[current_loop][modelData] == 1.0
                                        // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                                        onClicked: {
                                            if (looper_widget.midiLearn(modelData)){
                                                return;
                                            }
                                            loopler.ui_set(current_loop, modelData, 1 - loopler.loops[current_loop][modelData])
                                            loopler.ui_unset_current_command();
                                        }
                                        onPressed: {
                                            loopler.ui_set_current_command("ui_set", [current_loop, modelData, 1 - loopler.loops[current_loop][modelData]]);
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
                                    id: loop_slider_rate
                                    height: 62
                                    width:  714
                                    property real multiplier: 1  
                                    property bool is_log: false
                                    property string selected_parameter: "rate"
                                    property bool force_update: false
                                    Material.foreground: Constants.short_rainbow[0]

                                    Slider {
                                        x: 0
                                        y: 0
                                        Material.foreground: parent.Material.foreground
                                        snapMode: Slider.SnapAlways
                                        stepSize: loop_slider_rate.selected_parameter == "rate" ? 0.25 : 0.01
                                        title: LoopMap.parameter_map[loop_slider_rate.selected_parameter]
                                        width: parent.width - 50
                                        height:parent.height
                                        value: loop_slider_rate.force_update, loopler.loops[current_loop][loop_slider_rate.selected_parameter] 
                                        from: loop_slider_rate.selected_parameter  in LoopMap.param_bounds ? LoopMap.param_bounds[loop_slider_rate.selected_parameter][0] : 0
                                        to: loop_slider_rate.selected_parameter in LoopMap.param_bounds ? LoopMap.param_bounds[loop_slider_rate.selected_parameter][1] : 1
                                        onMoved: {
                                            loopler.ui_set(current_loop, loop_slider_rate.selected_parameter, value)
                                        }
                                        onPressedChanged: {
                                            if (pressed){
                                                knobs.set_loopler_knob("ui_set", current_loop, loop_slider_rate.selected_parameter, from, to);
                                            }
                                        }
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
                                        model: ["scratch_pos", "rate", "pan_1", "pan_2"]

                                        ValueButton {
                                            width: 160
                                            height: 110
                                            // checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
                                            checked: loop_slider_rate.selected_parameter == modelData
                                            visible: modelData != "pan_2" || loopler.loops[current_loop].channel_count > 1 
                                            onClicked: {
                                                if (looper_widget.midiLearn(modelData)){
                                                    return;
                                                }
                                                loop_slider_rate.selected_parameter = modelData
                                                loop_slider_rate.Material.foreground = Constants.short_rainbow[index]
                                                loop_slider_rate.force_update = !(loop_slider_rate.force_update)
                                                var from = modelData  in LoopMap.param_bounds ? LoopMap.param_bounds[modelData][0] : 0
                                                var to = modelData in LoopMap.param_bounds ? LoopMap.param_bounds[modelData][1] : 1
                                                if (modelData == "scratch_pos"){
                                                    loopler.ui_loop_command(current_loop, "scratch");
                                                }
                                                knobs.set_loopler_knob("ui_set", current_loop, modelData, from, to);
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
                                            loopler.ui_unset_current_command();
                                        }
                                        onPressed: {
                                            loopler.ui_set_current_command("ui_set", [current_loop, "rate", LoopMap.rate_list[index]]);
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
                        Item { // global
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
                                    items: ["internal", "midi", "none", "loop 0"]
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
                                    up.onPressedChanged: {
                                        if (!(up.pressed)){
                                            loopler.ui_set_global("tempo", Number(value));
                                        }
                                    }
                                    down.onPressedChanged: {
                                        if (!(down.pressed)){
                                            loopler.ui_set_global("tempo", Number(value));
                                        }
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
                                    up.onPressedChanged: {
                                        if (!(up.pressed)){
                                            loopler.ui_set_global("eighth_per_cycle", Number(value));
                                        }
                                    }
                                    down.onPressedChanged: {
                                        if (!(down.pressed)){
                                            loopler.ui_set_global("eighth_per_cycle", Number(value));
                                        }
                                    }

                                }

                            }

                            Rectangle {
                                x:  339
                                y: -16
                                z: 3
                                width: 2
                                height: parent.height
                                color: Constants.poly_dark_grey
                            }

                            Item {
                                x: 390
                                y: 0 
                                width: 640
                                // height: 270

                                Row {
                                    y: 0
                                    x: 0
                                    spacing: 35



                                    Column {
                                        spacing: 25 
                                        height: parent.height
                                        width: 150

                                        Repeater {
                                            model: ["input_gain", "wet", "dry", "fade_samples"]

                                            ValueButton {
                                                width: 150
                                                height: 100
                                                // checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
                                                checked: global_slider.selected_parameter == modelData
                                                onClicked: {
                                                    if (looper_widget.midiLearn(modelData)){
                                                        return;
                                                    }
                                                    global_slider.selected_parameter = modelData
                                                    global_slider.Material.foreground = Constants.short_rainbow[index]
                                                    global_slider.force_update = !(global_slider.force_update)
                                                    var from = modelData  in LoopMap.param_bounds ? LoopMap.param_bounds[modelData][0] : 0
                                                    var to = modelData in LoopMap.param_bounds ? LoopMap.param_bounds[modelData][1] : 1
                                                    if (modelData == "fade_samples"){
                                                        knobs.set_loopler_knob("ui_set_all", -1, "fade_samples", from, to);
                                                        //
                                                    } else {
                                                        knobs.set_loopler_knob("ui_set_global", -1, modelData, from, to);
                                                    }
                                                }
                                                Material.foreground: Constants.short_rainbow[index]
                                                text: LoopMap.parameter_map[modelData]
                                                value: modelData == "fade_samples" ? loopler.loops[0]["fade_samples"].toFixed(2)  : loopler[modelData].toFixed(2)
                                            }
                                        }
                                    }

                                    Item {
                                        Material.foreground: Constants.short_rainbow[0]
                                        id: global_slider
                                        height: 463
                                        width:  90
                                        property real multiplier: 1  
                                        property bool is_log: false
                                        property string selected_parameter: "input_gain"
                                        property string v_type: selected_parameter == "fade_samples" ? "int" : "float"
                                        property bool force_update: false

                                        Slider {
                                            x: 0
                                            y: 0
                                            Material.foreground: parent.Material.foreground
                                            snapMode: Slider.SnapAlways
                                            stepSize: global_slider.v_type == "int" ? 1.0 : 0.0
                                            orientation: Qt.Vertical
                                            title: LoopMap.parameter_map[global_slider.selected_parameter]
                                            width: 90
                                            show_labels: false
                                            height:parent.height
                                            value: global_slider.force_update, global_slider.selected_parameter == "fade_samples" ? loopler.loops[0][global_slider.selected_parameter] : loopler[global_slider.selected_parameter]
                                            from: global_slider.selected_parameter  in LoopMap.param_bounds ? LoopMap.param_bounds[global_slider.selected_parameter][0] : 0
                                            to: global_slider.selected_parameter in LoopMap.param_bounds ? LoopMap.param_bounds[global_slider.selected_parameter][1] : 1
                                            onMoved: {
                                                if (global_slider.selected_parameter == "fade_samples"){
                                                    loopler.ui_set_all("fade_samples", value)
                                                    //
                                                } else {
                                                    loopler.ui_set_global(global_slider.selected_parameter, value);
                                                }
                                            }
                                            onPressedChanged: {
                                                if (pressed){
                                                    if (global_slider.selected_parameter == "fade_samples"){
                                                        knobs.set_loopler_knob("ui_set_all", -1, "fade_samples", from, to);
                                                        //
                                                    } else {
                                                        knobs.set_loopler_knob("ui_set_global", -1, global_slider.selected_parameter, from, to);
                                                    }
                                                }
                                            }
                                        }


                                    }
                                }

                                // Rectangle {
                                //     x:  779
                                //     y: -16
                                //     width: 2
                                //     height: 270
                                //     z: 3
                                //     color: Constants.poly_grey
                                // }

                            }




                            Rectangle {
                                x:  716
                                y: -16
                                z: 3
                                width: 2
                                height: parent.height
                                color: Constants.poly_dark_grey
                            }

                            Column {
                                x: 740
                                y: 20
                                height: 515
                                spacing: 14 
                                width: 404

                                Text {
                                    text: "Quantize"
                                    color: Constants.loopler_purple
                                    width: 252
                                    font {
                                        pixelSize: 24
                                        capitalization: Font.AllUppercase
                                    }
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                PolySpin {
                                    // anchors.horizontalCenter: parent.horizontalCenter
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
                                            loopler.ui_unset_current_command();
                                        }
                                        onPressed: {
                                            loopler.ui_set_current_command("ui_set_all", [modelData, 1 - loopler.loops[current_loop][modelData]]);
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

                                Row {
                                    spacing: 5
                                    Repeater {
                                        model: ["select_prev_loop", "select_next_loop"]

                                        PolyButton {
                                            width: 125
                                            height: 64
                                            // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                                            onClicked: {
                                                if (looper_widget.midiLearn(modelData)){
                                                    return;
                                                }
                                                loopler.ui_set_global_change(modelData)
                                                loopler.ui_unset_current_command();
                                            }
                                            onPressed: {
                                                loopler.ui_set_current_command("ui_set_global_change", [modelData]);
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
                    }

                    Row {
                        x: 177
                        y: 283
                        id: loop_row
                        width: parent.width
                        visible: tab_index != 3
                        height: 250
                        spacing: 13 

                        ListView {
                            id: loop_list_view
                            x: 0
                            y: 0
                            width: 1280
                            height: 296
                            clip: true
                            model: loopler.loops.length
                            orientation: ListView.Horizontal
                            spacing: 13 
                            highlightRangeMode: ListView.StrictlyEnforceRange 

                            delegate: PolyButton {
                                // property string l_effect: edit //.split(":")[1]
                                height: 221
                                width: 296
                                // text: modelData
                                checked: actual_current_loop == index
                                onClicked: {
                                    if (actual_current_loop == index){
                                        loopler.select_loop(-1);
                                    }
                                    else
                                    {
                                        loopler.select_loop(index);
                                    }
                                }

                                contentItem: Item { 
                                    Image {
                                        x: 12
                                        y: 14
                                        source: "../icons/digit/loopler/commands/loop_box/"+ LoopMap.state_png_map[loopler.loops[index].state.toString()] +".png"
                                    }

                                    Image {
                                        x: 250
                                        y: 6
                                        width:27 
                                        height: 27
                                        source: loopler.loops[index].channel_count > 1 ? "../icons/digit/loopler/stereo-large.png" : "../icons/digit/loopler/mono-large.png"
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
                                    height: 105
                                    width: 296
                                    // text: modelData
                                    onClicked: {
                                        // current_loop = index;
                                        // add new loop
                                        loopler.ui_add_loop(1)
                                    }

                                    contentItem: Item { 
                                        Image {
                                            x: 19
                                            y: 7
                                            source: "../icons/digit/loopler/mono-large.png"
                                        }

                                        Text {
                                            x: 108
                                            y: 7
                                            text: "Add Mono\nLoop"
                                            color: "white" // Constants.poly_grey // checked ? Constants.background_color : "white"
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
                                PolyButton {
                                    // property string l_effect: edit //.split(":")[1]
                                    x: 13
                                    y: 116
                                    height: 105
                                    width: 296
                                    // text: modelData
                                    onClicked: {
                                        // current_loop = index;
                                        // add new loop
                                        loopler.ui_add_loop(2)
                                    }

                                    contentItem: Item { 
                                        Image {
                                            x: 19
                                            y: 7
                                            source: "../icons/digit/loopler/stereo-large.png"
                                        }

                                        Text {
                                            x: 108
                                            y: 7
                                            text: "Add stereo\nloop"
                                            color: "white" // Constants.poly_grey // checked ? Constants.background_color : "white"
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

                            // ScrollIndicator.horizontal: ScrollIndicator {
                            //     // x: 1
                            //     anchors.top: loop_list_view.top
                            //     parent: loop_list_view.parent
                            //     // anchors.left: loop_list_view.left
                            //     anchors.bottom: loop_list_view.bottom
                            // }
                        }
                    }
                }

                // global
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
                id: midiButton
                x: 198 
                y: 529
                width: 86
                height: 86
                icon.width: 86
                icon.height: 86
                // flat: false
                icon.source: "../icons/digit/loopler/midi.png"
                Material.background: Constants.background_color
                Material.foreground: midi_learn_select ? Constants.loopler_purple : "white"
                onClicked: {
                    if (midi_learn_waiting){
                        midi_learn_select = false;
                        loopler.ui_cancel_bind_request();
                    }
                    else if (tab_index == 3){
                        midi_learn_select = !midi_learn_select;
                        binding_current_loop = -2;
                    } else {
                        looplerStack.push(midiBindScreen) 
                    }

                }

                SequentialAnimation {
                    loops: Animation.Infinite;
                    alwaysRunToEnd: true;
                    running: midi_learn_waiting
                    ColorAnimation { target: midiButton; property: "Material.background"; to: Constants.loopler_purple; from: Constants.background_color; duration: 1000 }
                    ColorAnimation { target: midiButton; property: "Material.background"; from: Constants.loopler_purple; to: Constants.background_color; duration: 1000 }
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
                visible: loopler.loops.length > 1
                // flat: false
                icon.source: "../icons/digit/loopler/bin.png"
                Material.background: Constants.background_color
                onClicked: {
                    loopler.ui_remove_loop()
                }
                // HelpLabel {
                //     text: "Global"
                // }
            }
        }
    }

    Component {
        id: midiBindScreen
        Item {
            height:700
            width:1280
            Row {
                spacing: 50
                anchors.centerIn: parent

                PolyButton {
                    width: 300
                    height: 150
                    onClicked: {
                        midi_learn_select = !midi_learn_select;
                        binding_current_loop = -3;
                        looplerStack.pop()
                    }
                    Material.foreground: Constants.short_rainbow[0]
                    Material.background: Constants.background_color
                    text: "Selected Loop"
                    font {
                        pixelSize: 36
                        capitalization: Font.AllUppercase
                    }
                }

                PolyButton {
                    width: 300
                    height: 150
                    onClicked: {
                        midi_learn_select = !midi_learn_select;
                        binding_current_loop = -1;
                        looplerStack.pop()
                    }
                    Material.foreground: Constants.short_rainbow[1]
                    Material.background: Constants.background_color
                    text: "All Loops"
                    font {
                        pixelSize: 36
                        capitalization: Font.AllUppercase
                    }
                }

                PolyButton {
                    width: 300
                    height: 150
                    onClicked: {
                        midi_learn_select = !midi_learn_select;
                        binding_current_loop = current_loop;
                        looplerStack.pop()
                    }
                    Material.foreground: Constants.short_rainbow[2]
                    Material.background: Constants.background_color
                    text: "Loop " + current_loop
                    font {
                        pixelSize: 36
                        capitalization: Font.AllUppercase
                    }
                }

            }

            IconButton {
                x: 34 
                y: 646
                icon.width: 15
                icon.height: 25
                width: 119
                height: 62
                text: "BACK"
                font {
                    pixelSize: 24
                }
                flat: false
                icon.name: "back"
                Material.background: "white"
                Material.foreground: Constants.outline_color
                onClicked: looplerStack.pop()
            }
        }
    }

    StackView {
        id: looplerStack
        initialItem: looplerMain
    }
}

