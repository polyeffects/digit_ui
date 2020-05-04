import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.VirtualKeyboard 2.1

import "polyconst.js" as Constants
/*
 * connection pairs of id / port, id / port
 *
 */

    Item {
        x: 0
        y: 0
        id: patch_bay
        width: 1280
        height: 548

        enum PatchMode {
            Select,
            Move,
            Connect,
            Sliders,
            Details
        }
        property int active_width: 900
        property int updateCount: updateCounter, externalRefresh()
        property int current_index: -1
        property bool isMoving: false
        property int currentMode: PatchBay.Select
        property string current_help_text: "Tap or add a module"
        // relate to port selection popup
        property bool list_source: true
        property string list_effect_id
        property var effect_map: {"invalid":"b"}
        property PatchBayEffect selected_effect

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
        }

        function rsplit(str, sep, maxsplit) {
            var split = str.split(sep);
            return maxsplit ? [ split.slice(0, -maxsplit).join(sep) ].concat(split.slice(-maxsplit)) : split;
        }

        signal reAddModule(string l_effect_id)
        signal reRemoveModule(string l_effect_id)

        Connections { 
            target: patch_bay

            onReAddModule: { 
                var component;

                // console.log("add module signal ", l_effect_id);
                
                effect_map[l_effect_id] = patchWrap.createObject(patch_bay, { effect_id: l_effect_id,
                    effect_type: currentEffects[l_effect_id]["effect_type"],
                    x: currentEffects[l_effect_id]["x"],
                    y: currentEffects[l_effect_id]["y"],
                    // highlight: currentEffects[l_effect_id]["highlight"]
                });
                

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
                // console.log("done remove module signal", l_effect_id);
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
                    // console.log("key ", source_effect_port_str);
                    // console.log(Object.keys(effect_map)); //[item.effect_id]);
                    var source_effect_port = rsplit(source_effect_port_str, "/", 1);
                    var targets = portConnections[source_effect_port_str];
                    var source_index = effect_map[source_effect_port[0]].input_keys.indexOf(source_effect_port[1])
                    // console.log("drawing connection 1", source_effect_port[0], portConnections[source_effect_port_str]);
                    
                    for (var target in targets){
                        // console.log("drawing connection 2 targets", targets[0][0]);
                        // console.log("drawing connection 2 obj", effect_map[source_effect_port[0]], effect_map[targets[target][0]]);
                        // console.log("drawing connection 2 keys", source_effect_port[0], targets[target][0]);
                        var target_port_type = effectPrototypes[currentEffects[targets[target][0]]["effect_type"]]["outputs"][targets[target][1]][1]

                        var target_index = effect_map[targets[target][0]].output_keys.indexOf(targets[target][1])
                        // console.log("target_port_type", target_port_type);
                        //effect_map[source_effect_port[0]], effect_map[targets[target][0]]
                        drawConnection(drawContext, effect_map[source_effect_port[0]], effect_map[targets[target][0]], target_port_type, target_index, source_index);
                    } 
                }
            }

            function drawConnection( drawContext, targetPort, sourcePort, source_port_type, source_index, target_index ) {
                if (source_port_type == "AudioPort"){
                    var start   = getCanvasCoordinates( targetPort.inputs, 0, 4+(target_index* 22))
                } else {
                    var start   = getCanvasCoordinates( targetPort.cv_area, targetPort.cv_area.width / 2, targetPort.cv_area.height - 2)
                }
                var end     = getCanvasCoordinates( sourcePort.outputs,  0, 4 + (source_index * 22)) 
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
                else if (source_port_type == "ControlPort"){
                    line_color = Constants.control_color;
                } else {
                    line_color = accent_color.name;
                }

                drawContext.strokeStyle = line_color;
                drawContext.beginPath();
                drawContext.moveTo( start.x, start.y );
                if (source_port_type == "AudioPort"){
                    drawContext.bezierCurveTo( start.x + sizeX / 2.0 , start.y, end.x - sizeX / 2.0, end.y, end.x, end.y );
                } else {
                    drawContext.bezierCurveTo( start.x, start.y + 50, end.x - sizeX / 2, end.y, end.x, end.y );
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
                var ctx = getContext("2d");
                ctx.fillStyle = Material.background; //Qt.rgba(1, 1, 0, 1);
                ctx.fillRect(0, 0, width, height);
                findConnections(ctx);
            }
            DropArea {
                anchors.fill: parent
                onEntered: drag.source.caught = true;
                onExited: drag.source.caught = false;
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
            y: 10
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
            id: portSelection
            Item {
                id: portSelectionCon
                y: 50
                height:700
                width:1280

                GlowingLabel {
                    color: "#ffffff"
                    text: "Choose Port"
                    font {
                        pixelSize: fontSizeLarge * 1.2
                    }
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ListView {
                    width: 400
                    spacing: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 90
                    anchors.bottom: parent.bottom
                    clip: true
                    delegate: ItemDelegate {
                        width: parent.width
                        height: 90
                        text: edit.split("|")[1]
                        bottomPadding: 2
                        font.pixelSize: fontSizeLarge
                        topPadding: 2
                        onClicked: {
                            // set this as the current port
                            // and update valid targets
                            knobs.set_current_port(list_source, list_effect_id, edit.split("|")[0]);
                            // rep1.model.items_changed(); //  FIXME
                            mycanvas.requestPaint();
                            mainStack.pop();
                        }
                    }
                    ScrollIndicator.vertical: ScrollIndicator {
                        anchors.top: parent.top
                        parent: portSelectionCon
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.bottom: parent.bottom
                    }
                    model: selectedEffectPorts
                }
            
                
                IconButton {
                    x: 34 
                    y: 596
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

                    onClicked: { 
                        current_help_text = ""
                        mainStack.pop()
                    }
                }
            }
        }

        Component {
            id: disconnectPortSelection
            Item {
                id: disPortSelectionCon
                y: 50
                height:700
                width:1280

                GlowingLabel {
                    color: "#ffffff"
                    text: "Disconnect Port"
                    font {
                        pixelSize: fontSizeLarge * 1.2
                    }
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ListView {
                    width: 700
                    spacing: 5
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 90
                    anchors.bottom: parent.bottom
                    clip: true
                    delegate: ItemDelegate {
                        width: parent.width
                        height: 90
                        text: edit.split("===")[0].replace(/_/g, " ")
                        bottomPadding: 2
                        font.pixelSize: fontSizeLarge
                        font.capitalization: Font.AllUppercase
                        topPadding: 2
                        onClicked: {
                            // set this as the current port
                            // and update valid targets
                            // console.log("disconnect", edit);
                            knobs.disconnect_port(edit.split("===")[1]);
                            mycanvas.requestPaint();
                            mainStack.pop();
                        }
                    }
                    ScrollIndicator.vertical: ScrollIndicator {
                        anchors.top: parent.top
                        parent: disPortSelectionCon
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.bottom: parent.bottom
                    }
                    model: selectedEffectPorts
                }
            
                
                IconButton {
                    x: 34 
                    y: 596
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

                    onClicked: mainStack.pop()
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
