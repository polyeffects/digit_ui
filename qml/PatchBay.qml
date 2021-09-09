import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.VirtualKeyboard 2.1

import "polyconst.js" as Constants
import "module_info.js" as ModuleInfo
/*
 * connection pairs of id / port, id / port
 *
 */

    Item {
        x: 0
        y: 0
        id: patch_bay
        width: 1280
        height: currentPedalModel.name == "beebo" || patch_single.currentMode == PatchBay.Details ?  548: 700

        enum PatchMode {
            Select,
            Move,
            Connect,
            Sliders,
			Details,
			Hold,
            Spotlight
        }

        property int active_width: 900
        property int updateCount: updateCounter, externalRefresh()
        property int current_index: -1
        property bool isMoving: false
        property int currentMode: PatchBay.Select
        property string current_help_text: "Tap or add a module"
        // relate to port selection popup
        property string list_source_effect_id
        property string list_dest_effect_id
        property string list_dest_effect_type
        property bool source_selected: false
        property bool from_hold: false
        property bool more_hold: false
        property bool multi_touch_connect: false
        property bool in_spotlight: false
        property bool cancel_expand: false
        property var effect_map: {"invalid":"b"}
        property PatchBayEffect selected_effect

        onCurrentModeChanged: {
            knobs.set_current_mode(currentMode, selected_effect ? selected_effect.effect_id : "")
        }

		function setColorAlpha(color, alpha) {
			return Qt.hsla(color.hslHue, color.hslSaturation, color.hslLightness, alpha)
		}

        function externalRefresh() {
            mycanvas.requestPaint();
            return updateCounter.value;
        }

        Component.onCompleted: {
            title_footer.patch_single = patch_bay;
            patchBayNotify.add_module.connect(reAddModule);
            patchBayNotify.remove_module.connect(reRemoveModule);
            patchBayNotify.loading_preset.connect(reLoadingPreset);
            if (currentPedalModel.name != "beebo"){
                mycanvas.loadImage("../icons/digit/hector_background.png")
            }
        }

        function rsplit(str, sep, maxsplit) {
            var split = str.split(sep);
            return maxsplit ? [ split.slice(0, -maxsplit).join(sep) ].concat(split.slice(-maxsplit)) : split;
        }

        function calc_io_y(l_effect_id){
            var effect_type = currentEffects[l_effect_id]["effect_type"];
            var offset = 60;
            if (effect_type == "input"){
                return offset + (95 *  (Number(l_effect_id.slice(-1) - 1)))
            } else if (effect_type == "output"){
                return offset + (75 *  (Number(l_effect_id.slice(-1) - 1)))
            } else if (effect_type == "midi_input"){
                return offset + (95 *  6)
            } else if (effect_type == "midi_output"){
                return offset + (75 *  8)
            }
        }

        signal reAddModule(string l_effect_id)
        signal reRemoveModule(string l_effect_id)
        signal reLoadingPreset(bool is_loading_preset)

        Connections { 
            target: patch_bay

            onReAddModule: { 
                var component;

                // console.log("add module signal ", l_effect_id);
                
                if (currentPedalModel.name == "beebo")
                {
                    effect_map[l_effect_id] = patchWrap.createObject(patch_bay, { effect_id: l_effect_id,
                        effect_type: currentEffects[l_effect_id]["effect_type"],
                        x: lToR.value ? 1170 - currentEffects[l_effect_id]["x"] : currentEffects[l_effect_id]["x"],
                        y: currentEffects[l_effect_id]["y"],
                        // highlight: currentEffects[l_effect_id]["highlight"]
                    });
                
                }
                else
                {
                    var is_io = ["input", "output", "midi_input", "midi_output"].indexOf(currentEffects[l_effect_id]["effect_type"]) >= 0
                    effect_map[l_effect_id] = patchWrap.createObject(patch_bay, { effect_id: l_effect_id,
                        effect_type: currentEffects[l_effect_id]["effect_type"],
                        x: lToR.value ? 1170 - currentEffects[l_effect_id]["x"] : currentEffects[l_effect_id]["x"],
                        y: !is_io ? currentEffects[l_effect_id]["y"] :  calc_io_y(l_effect_id),
                        // highlight: currentEffects[l_effect_id]["highlight"]
                    });
                }  

                if ("invalid" in effect_map){
                    delete effect_map["invalid"];
                }

                if (!selected_effect){
                    selected_effect = effect_map[l_effect_id] ;
                }
            }

            onReRemoveModule: {
                // console.log("remove module signal", l_effect_id);
                selected_effect = null;
                if  (l_effect_id in effect_map) {
                    effect_map[l_effect_id].destroy(1);
                    delete effect_map[l_effect_id];
                }
                knobs.finish_remove_effect(l_effect_id)

                // console.log("done remove module signal", l_effect_id);
            }

            onReLoadingPreset: {
                // console.log("loading preset signal", is_loading_preset);
                // return to main screen 
                mainStack.pop(null); 
                // console.log("done loading preset signal", is_loading_preset);

            }
        }


        // Repeater {
        //     id: rep1
        //     // model: [1, 2, 3, 4]
        //     model: PatchBayModel {}
        //     PatchBayEffect {
        //         effect_id: l_effect_id
        //         effect_type: l_effect_type
        //         x: cur_x
        //         y: cur_y
        //         highlight: l_highlight
        //     }
        //     onItemAdded: {
        //         if ("invalid" in effect_map){
        //             delete effect_map["invalid"];
        //         }
        //         // console.log("added", index, item.effect_id);
        //         effect_map[item.effect_id] = item;
        //         if (!selected_effect){
        //             selected_effect = item;
        //         }
        //     }
        // }

        Canvas {
            id: mycanvas
            function findConnections(drawContext){ 
                // iterate over items in rep1, adding to dictionary of effect_id : patchbayeffect
                // source and targets are the wrong way round XXX 
                // console.log("finding connection", Object.keys(portConnections));
                for (var source_effect_port_str in portConnections){ 
                    var source_effect_port = rsplit(source_effect_port_str, "/", 1);
                    var targets = portConnections[source_effect_port_str];
                    var source_index = effect_map[source_effect_port[0]].input_keys.indexOf(source_effect_port[1])
					var source_port_type = ModuleInfo.effectPrototypes[currentEffects[source_effect_port[0]]["effect_type"]]["inputs"][source_effect_port[1]][1]
                    
                    for (var target in targets){
                        var target_port_type = ModuleInfo.effectPrototypes[currentEffects[targets[target][0]]["effect_type"]]["outputs"][targets[target][1]][1]

                        var target_index = effect_map[targets[target][0]].output_keys.indexOf(targets[target][1])
						drawConnection(drawContext, effect_map[source_effect_port[0]], effect_map[targets[target][0]], target_port_type, 
							target_index, source_index, source_port_type);
                    } 
                }
            }

            function drawConnection( drawContext, targetPort, sourcePort, source_port_type, source_index, target_index, target_port_type ) {
                if (target_port_type == "AudioPort" || target_port_type == "AtomPort"){
                    var start   = getCanvasCoordinates( targetPort.inputs, 0, 9+(target_index* 24))
                } else {
                    var start   = getCanvasCoordinates( targetPort.cv_area, targetPort.cv_area.width / 2, targetPort.cv_area.height - 2)
                }
                var end     = getCanvasCoordinates( sourcePort.outputs,  0, 9 + (source_index * 24)) 
                if( start.x > end.x ) {
                    var tmp = start;
                    start = end;
                    end = tmp;
                }

                var minmax  = getMinMax( start, end )
                var sizeX   = minmax[2] - minmax[0]


                drawContext.lineWidth   = 2;
                var line_color;  
                if (source_port_type == "CVPort"){
                    line_color = Constants.cv_color;
                } 
                else if (source_port_type == "AudioPort"){
                    line_color = Constants.audio_color;
                }
                else if (source_port_type == "AtomPort"){
                    line_color = Constants.midi_color;
                }
                else if (source_port_type == "ControlPort"){
                    line_color = Constants.control_color;
                } else {
                    line_color = accent_color.name;
                }

                drawContext.strokeStyle = line_color;
                drawContext.beginPath();
                drawContext.moveTo( start.x, start.y );

                // console.log("drawing curve", start.x, start.y, end.x, end.y, source_port_type);
                if (target_port_type == "AudioPort" || target_port_type == "AtomPort"){
                    drawContext.bezierCurveTo( start.x + sizeX / 2.0 , start.y, end.x - sizeX / 2.0, end.y, end.x, end.y );
                } else {
                    if (lToR.value){
                        drawContext.bezierCurveTo( start.x + sizeX / 2.0, start.y, end.x, end.y + 50, end.x, end.y );
                    } else {
                        drawContext.bezierCurveTo( start.x, start.y + 50, end.x - sizeX / 2, end.y, end.x, end.y );
                    }
                }
                drawContext.stroke();
                return true;
            }

            function getCanvasCoordinates( port, hotSpotX, hotSpotY )
            {
                return mycanvas.mapFromItem( port, hotSpotX, hotSpotY )
            }

            function getMinMax( start, end )
            {
                var minX, minY,
                maxX, maxY
                if( start.x < end.x ) {
                    minX = start.x
                    maxX = end.x
                }
                else {
                    minX = end.x
                    maxX = start.x
                }

                if( start.y < end.y ) {
                    minY = start.y
                    maxY = end.y
                }
                else {
                    minY = end.y
                    maxY = start.y
                }
                return [minX, minY, maxX, maxY]
            }

            anchors {
                top: parent.top
                right:  parent.right
                bottom:  parent.bottom
            }
            width: parent.width
            onPaint: {
                // only draw if we're visable
                if (patchStack.currentItem instanceof PatchBay) 
                {
                    var ctx = getContext("2d");
                    ctx.fillStyle = Material.background; //Qt.rgba(1, 1, 0, 1);
                    ctx.fillRect(0, 0, width, height);
                    if (currentPedalModel.name != "beebo"){
                        ctx.drawImage("../icons/digit/hector_background.png", 212, 32, 855, 655);
                    }
                    findConnections(ctx);
                }
            }
            DropArea {
                anchors.fill: parent
                onEntered: drag.source.caught = true;
                onExited: drag.source.caught = false;
            }
        }


        Rectangle {
            x: lToR.value ? 1195 : 0
            // y: currentPedalModel.name == "beebo" ? 0 : -100
            y: 0
            width: 95
            height: 720
            color: Constants.poly_very_dark_grey
            Label {
                x: 15
                y: 15
                color: accent_color.name
                text: "OUT"
                font {
                    pixelSize: 18
                    capitalization: Font.AllUppercase
                }
            }
        }



        Rectangle {
            x: lToR.value ? 0 : 1195
            // y: currentPedalModel.name == "beebo" ? 0 : -100
            y: 0
            width: 90
            height: 720
            color: Constants.poly_very_dark_grey
            Label {
                x: 55
                y: 15
                color: accent_color.name
                text: "IN"
                font {
                    pixelSize: 18
                    capitalization: Font.AllUppercase
                }
            }
        }


        Rectangle {
            z: 3
            id: darken_patch
            anchors.fill: parent
            color: "#90000000"
            visible: patch_bay.currentMode == PatchBay.Sliders
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }
        }

        Label {
            id: pedalboard_description
            y: currentPedalModel.name == "beebo" ? 15 : 90
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            // x: 120
            width: 500
            height: 100
            color: "grey" // Constants.outline_color
            text: pedalboardDescription.name
            // onEditingFinished: {
            //     knobs.set_description(text)
            // }
            font {
                pixelSize: fontSizeMedium
                family: docFont.name
                weight: Font.Normal
                capitalization: Font.AllUppercase
            }
            z: 0
            MouseArea {
                anchors.fill: parent
                onClicked: { 
                    mainStack.push(enterDescription);
                }
            }
        }

        Component {
            id: patchWrap
            PatchBayEffect {}
        }


        Component {
            id: sourcePortSelection
            Item {
                id: sourcePortSelectionCon
                height: 720
                width:1280

                Rectangle {
                    color: accent_color.name
                    x: 0
                    y: 0
                    width: 1280
                    height: 100

                    Image {
                        x: 10
                        y: 9
                        source: currentPedalModel.name == "beebo" ? "../icons/digit/Beebo.png" : "../icons/digit/Hector.png" 
                    }

                    Label {
                        // color: "#ffffff"
                        property string effect_title: rsplit(list_source_effect_id, "/", 1)[1].replace(/_/g, " ").replace(/1$/, '');
                        text: "Select Port of "+ effect_title + " to Connect From"
                        elide: Text.ElideRight
                        anchors.centerIn: parent
                        anchors.bottomMargin: 25 
                        horizontalAlignment: Text.AlignHCenter
                        width: 1000
                        height: 60
                        z: 1
                        color: Constants.background_color
                        font {
                            pixelSize: 36
                            capitalization: Font.AllUppercase
                        }
                    }
                }
                Item {
                    y: 100

                    ListView {
                        id: from_list
                        property bool move_finished: false
                        width: 1218
                        x: 29
                        y: 27
                        height: 520
                        spacing: 12
                        clip: true
                        delegate: Item {
                            property var split_port: edit.split("|")
                            property bool is_pressed: false
                            property bool clearPressed: from_list.move_finished
                            onClearPressedChanged: {
                                is_pressed = false;
                            }
                            width: 1218
                            height: 88

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                color: is_pressed ? Constants.poly_pink : Constants.background_color  
                                border.width: 2
                                border.color: Constants.poly_dark_grey  
                                radius: 12
                            }

                            PolyButton {
                                height: 35
                                width: 74  
                                x: 44
                                y: 24
                                topPadding: 5
                                leftPadding: 15
                                rightPadding: 15
                                radius: 25
                                Material.foreground: Constants.background_color
                                border_color: Constants.port_color_map[split_port[0]]
                                background_color: Constants.port_color_map[split_port[0]]
                                text: Constants.port_display_name[split_port[0]]
                                font_size: 24
                            }

                            Label {
                                x: 165
                                y: 17
                                height: 60
                                width: 598
                                text: split_port[1]
                                // anchors.top: parent.top
                                font {
                                    pixelSize: 30
                                    family: mainFont.name
                                    weight: Font.DemiBold
                                    capitalization: Font.AllUppercase
                                }
                            }


                            MouseArea {
                                anchors.fill: parent
                                onPressed: { parent.is_pressed = true; }
                                onReleased: { parent.is_pressed = false; }
                                onClicked: {
                                    // set this as the current port
                                    // and update valid targets
                                    // console.log("list_source_effect_id", list_source_effect_id, edit.split("|")[0]);
                                    knobs.set_current_port(true, list_source_effect_id, split_port[2]);
                                    // rep1.model.items_changed(); //  FIXME
                                    mycanvas.requestPaint();
                                    if (patch_bay.from_hold){
                                        knobs.select_effect(false, list_dest_effect_id, true);
                                        var source_port_pair = [list_source_effect_id, split_port[2]];
                                        var source_port_type = ModuleInfo.effectPrototypes[currentEffects[source_port_pair[0]]["effect_type"]]["outputs"][source_port_pair[1]][1]

                                        var k;
                                        var matched = 0;
                                        var matched_id = 0;
                                        // console.log("source port in from hold ", source_port_pair);
                                        // console.log("source port ", effect_id);
                                        k = Object.keys(ModuleInfo.effectPrototypes[list_dest_effect_type]["inputs"])
                                        if (currentPedalModel.name == "hector"){
                                            if (currentEffects[source_port_pair[0]]["effect_type"] == "input" || list_dest_effect_type == "output"){
                                                matched = k.length;
                                                console.log("patchbay matched, hector", matched);

                                            } else
                                            {
                                                for (var i in k) {
                                                    // console.log("port name is ", i[k]);
                                                    if (ModuleInfo.effectPrototypes[list_dest_effect_type]["inputs"][k[i]][1] == source_port_type){
                                                        matched++;
                                                        matched_id = i;
                                                    }
                                                }
                                                console.log("patchbay not matched, hector", matched);

                                            }
                                        } else{ 
                                            for (var i in k) {
                                                // console.log("port name is ", i[k]);
                                                if (ModuleInfo.effectPrototypes[list_dest_effect_type]["inputs"][k[i]][1] == source_port_type){
                                                    matched++;
                                                    matched_id = i;
                                                }
                                            }
                                            console.log("patchbay not hector");
                                        }
                                        if (matched > 1 )
                                        {
                                            mainStack.replace(destPortSelection);
                                            patch_bay.current_help_text = ""
                                        } 
                                        else if (matched == 1){
                                            knobs.set_current_port(false, list_dest_effect_id, k[matched_id]);
                                            // rep1.model.items_changed();
                                            patch_bay.externalRefresh();
                                            patch_bay.currentMode = PatchBay.Select;
                                            patch_bay.current_help_text = Constants.help["select"];
                                            mainStack.pop();
                                        }

                                    } 
                                    else {
                                        mainStack.pop();
                                    }
                                }
                            }
                        }
                        ScrollIndicator.vertical: ScrollIndicator {
                            anchors.top: parent.top
                            parent: sourcePortSelectionCon
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            anchors.bottom: parent.bottom
                            contentItem: Rectangle {
                                implicitWidth: 4
                                implicitHeight: 100
                                color: Constants.poly_pink
                            }
                        }
                        model: selectedSourceEffectPorts
                        onMovementEnded: {
                            from_list.move_finished = !from_list.move_finished;
                        }

                        // section.property: "edit"
                        // section.criteria: ViewSection.FirstCharacter
                        // section.delegate: sectionHeading
                    }

                    IconButton {
                        x: 34 
                        y: 560
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
                        Material.background: Constants.background_color
                        Material.foreground: "white" // Constants.outline_color
                        onClicked: { 
                            current_help_text = ""
                            mainStack.pop()
                            if (patch_bay.currentMode == PatchBay.Hold){
                                patch_bay.currentMode = PatchBay.Select;
                            }
                        }
                    }
                }
            }
        }



        Component {
            id: destPortSelection

            Item {
                id: destPortSub
                height: 720
                width:1280

                Rectangle {
                    color: accent_color.name
                    x: 0
                    y: 0
                    width: 1280
                    height: 100

                    Image {
                        x: 10
                        y: 9
                        source: currentPedalModel.name == "beebo" ? "../icons/digit/Beebo.png" : "../icons/digit/Hector.png" 
                    }

                    Label {
                        // color: "#ffffff"
                        property string effect_title: rsplit(list_dest_effect_id, "/", 1)[1].replace(/_/g, " ").replace(/1$/, '');
                        text: "Select Port of "+ effect_title + " to Connect to"
                        elide: Text.ElideRight
                        anchors.centerIn: parent
                        anchors.bottomMargin: 25 
                        horizontalAlignment: Text.AlignHCenter
                        width: 1000
                        height: 60
                        z: 1
                        color: Constants.background_color
                        font {
                            pixelSize: 36
                            capitalization: Font.AllUppercase
                        }
                    }
                }
                Item {
                    y: 100

                    ListView {
                        id: to_list
                        property bool move_finished: false
                        width: 1218
                        x: 29
                        y: 27
                        height: 520
                        spacing: 12
                        clip: true
                        delegate: Item {
                            property var split_port: edit.split("|")
                            width: 1218
                            height: 88
                            property bool is_pressed: false
                            property bool clearPressed: to_list.move_finished
                            onClearPressedChanged: {
                                is_pressed = false;
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                color: is_pressed ? Constants.poly_pink : Constants.background_color  
                                border.width: 2
                                border.color: Constants.poly_dark_grey  
                                radius: 12
                            }

                            PolyButton {
                                height: 35
                                width: 74  
                                x: 44
                                y: 24
                                topPadding: 5
                                leftPadding: 15
                                rightPadding: 15
                                radius: 25
                                Material.foreground: Constants.background_color
                                border_color: Constants.port_color_map[split_port[0]]
                                background_color: Constants.port_color_map[split_port[0]]
                                text: Constants.port_display_name[split_port[0]]
                                font_size: 24
                            }

                            Label {
                                x: 165
                                y: 17
                                height: 60
                                width: 598
                                text: split_port[1]
                                // anchors.top: parent.top
                                font {
                                    pixelSize: 30
                                    family: mainFont.name
                                    weight: Font.DemiBold
                                    capitalization: Font.AllUppercase
                                }
                            }
                            // Label {
                            //     x: 31
                            //     y: 55
                            //     width: 598
                            //     height: 30
                            //     text: description // effectPrototypes[l_effect]["description"]
                            //     wrapMode: Text.Wrap
                            //     // anchors.top: parent.top
                            //     font {
                            //         pixelSize: 24
                            //         family: docFont.name
                            //         weight: Font.Normal
                            //         // capitalization: Font.AllUppercase
                            //     }
                            // }


                            MouseArea {
                                anchors.fill: parent
                                onPressed: { parent.is_pressed = true; }
                                onReleased: { parent.is_pressed = false; }
                                onClicked: {
                                    // set this as the current port
                                    // and update valid targets
                                    knobs.set_current_port(false, list_dest_effect_id, split_port[2]);
                                    // rep1.model.items_changed(); //  FIXME
                                    mycanvas.requestPaint();
                                    if (patch_bay.from_hold){
                                        patch_bay.currentMode = PatchBay.Select;
                                        patch_bay.current_help_text = Constants.help["select"];
                                    }
                                    mainStack.pop();
                                }
                            }
                        }
                        ScrollIndicator.vertical: ScrollIndicator {
                            anchors.top: parent.top
                            parent: destPortSub
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            anchors.bottom: parent.bottom
                        }
                        model: selectedDestEffectPorts

                        onMovementEnded: {
                            to_list.move_finished = !to_list.move_finished;
                        }
                    }

                    IconButton {
                        x: 34 
                        y: 560
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
                        Material.background: Constants.background_color
                        Material.foreground: "white" // Constants.outline_color
                        onClicked: { 
                            current_help_text = ""
                            mainStack.pop()
                            if (patch_bay.currentMode == PatchBay.Hold){
                                patch_bay.currentMode = PatchBay.Select;
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: disconnectPortSelection

            Item {
                id: disconnectPortSub
                height: 720
                width:1280

                Rectangle {
                    color: accent_color.name
                    x: 0
                    y: 0
                    width: 1280
                    height: 100

                    Image {
                        x: 10
                        y: 9
                        source: currentPedalModel.name == "beebo" ? "../icons/digit/Beebo.png" : "../icons/digit/Hector.png" 
                    }

                    Label {
                        // color: "#ffffff"
                        text: "Disconnect port"
                        elide: Text.ElideRight
                        anchors.centerIn: parent
                        anchors.bottomMargin: 25 
                        horizontalAlignment: Text.AlignHCenter
                        width: 1000
                        height: 60
                        z: 1
                        color: Constants.background_color
                        font {
                            pixelSize: 36
                            capitalization: Font.AllUppercase
                        }
                    }
                }
                Item {
                    y: 100

                    ListView {
                        id: disconnect_list
                        property bool move_finished: false
                        width: 1218
                        x: 29
                        y: 27
                        height: 520
                        spacing: 12
                        clip: true
                        delegate: Item {
                            property var split_port: edit.split("===")
                        //text: edit.split("===")[1].replace(/_/g, " ")
                            width: 1218
                            height: 88
                            property bool is_pressed: false
                            property bool clearPressed: disconnect_list.move_finished
                            onClearPressedChanged: {
                                is_pressed = false;
                            }

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                color: is_pressed ? Constants.poly_pink : Constants.background_color  
                                border.width: 2
                                border.color: Constants.poly_dark_grey  
                                radius: 12
                            }

                            PolyButton {
                                height: 35
                                width: 100  
                                x: 44
                                y: 24
                                topPadding: 5
                                leftPadding: 15
                                rightPadding: 15
                                radius: 25
                                Material.foreground: Constants.background_color
                                // border_color: split_port[0] == "input" ?  Constants.poly_pink : Constants.poly_purple
                                background_color: split_port[0] == "input" ?  Constants.poly_pink : Constants.poly_purple
                                text: split_port[0]
                                font_size: 24
                            }

                            Label {
                                x: 190
                                y: 17
                                height: 60
                                width: 598
                                text: split_port[1].replace(/_/g, " ")
                                // anchors.top: parent.top
                                font {
                                    pixelSize: 30
                                    family: mainFont.name
                                    weight: Font.DemiBold
                                    capitalization: Font.AllUppercase
                                }
                            }
                            // Label {
                            //     x: 31
                            //     y: 55
                            //     width: 598
                            //     height: 30
                            //     text: description // effectPrototypes[l_effect]["description"]
                            //     wrapMode: Text.Wrap
                            //     // anchors.top: parent.top
                            //     font {
                            //         pixelSize: 24
                            //         family: docFont.name
                            //         weight: Font.Normal
                            //         // capitalization: Font.AllUppercase
                            //     }
                            // }


                            MouseArea {
                                anchors.fill: parent
                                onPressed: { parent.is_pressed = true; }
                                onReleased: { parent.is_pressed = false; }
                                onClicked: {
                                    knobs.disconnect_port(split_port[2], edit);
                                    // patch_single.mycanvas.requestPaint();
                                    // mainStack.pop();
                                }
                            }
                        }
                        ScrollIndicator.vertical: ScrollIndicator {
                            anchors.top: parent.top
                            parent: disconnectPortSub
                            anchors.right: parent.right
                            anchors.rightMargin: 1
                            anchors.bottom: parent.bottom
                        }
                        model: selectedSourceEffectPorts

                        onMovementEnded: {
                            disconnect_list.move_finished = !disconnect_list.move_finished;
                        }
                    }

                    IconButton {
                        x: 34 
                        y: 560
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
                        Material.background: Constants.background_color
                        Material.foreground: "white" // Constants.outline_color
                        onClicked: { 
                            current_help_text = ""
                            mainStack.pop()
                            if (patch_bay.currentMode == PatchBay.Hold){
                                patch_bay.currentMode = PatchBay.Select;
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: enterDescription
            Item {
                y: 100
                height:700
                width:1280
                Column {
                    x: 0
                    height:600
                    width:1280
                    Label {
                        color: accent_color.name
                        text: "Preset Description"
                        font {
                            pixelSize: fontSizeLarge * 1.2
                            capitalization: Font.AllUppercase
                        }
                        // anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    TextArea {
                        font {
                            pixelSize: fontSizeMedium
                            family: docFont.name
                            weight: Font.Normal
                            capitalization: Font.AllUppercase
                        }
                        horizontalAlignment: TextEdit.AlignHCenter
                        width: 800
                        height: 400
                        text: pedalboardDescription.name
                        anchors.horizontalCenter: parent.horizontalCenter
                        inputMethodHints: Qt.ImhUppercaseOnly
                        onEditingFinished: {
                            knobs.set_description(text)
                        }
                    }

                    InputPanel {
                        // parent:mainWindow.contentItem
                        z: 1000002
                        // anchors.bottom:parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 200
                        width: 1000
                        visible: Qt.inputMethod.visible
                    }
                }

                IconButton {
                    x: 34 
                    y: 596
                    icon.width: 15
                    icon.height: 25
                    width: 119
                    height: 62
                    text: "DONE"
                    font {
                        pixelSize: 24
                    }
                    flat: false
                    icon.name: "back"
                    Material.background: "white"
                    Material.foreground: Constants.outline_color

                    onClicked: mainStack.pop()
                }
            }
        }
    }
