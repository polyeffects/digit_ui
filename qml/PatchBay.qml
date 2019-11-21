import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Shapes 1.11

import Poly 1.0
/*
 * connection pairs of id / port, id / port
 *
 */

    Item {
        id: patch_bay
        width: 1200
        height: 700
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
        property var delay_data: [polyValues["delay1"], polyValues["delay2"], polyValues["delay3"], polyValues["delay4"]]
        property var delay_colors: [Material.Pink, Material.Purple, Material.LightBlue, Material.Amber]
        property var parameter_map: {"LEVEL":"Amp_5", "TONE":"FeedbackSm_6", "FEEDBACK": "Feedback_4", 
                                    "GLIDE": "DelayT60_3", "WARP":"Warp_2", "POST LVL": "carla_level" }
        property var inv_parameter_map: {'Amp_5': 'LEVEL', 'DelayT60_3': 'GLIDE', 'Feedback_4': 'FEEDBACK', 'Warp_2': 'WARP', 'FeedbackSm_6': 'TONE', "Delay_1": "TIME", "carla_level": "POST LVL"}
        property int current_index: -1
        property bool delete_mode: deleteMode.checked
        property bool move_mode: moveMode.checked
        property bool isMoving: false
        property bool connect_mode: connectMode.checked
        property bool disconnect_mode: disconnectMode.checked
        property bool expand_mode: expandMode.checked
        // relate to port selection popup
        property bool list_source: true
        property string list_effect_id
        property var effect_map: {"invalid":"b"}
        // PPQN * bars
        //

        function convertRange( value, r1, r2 ) { 
            return ( value - r1[ 0 ] ) * ( r2[ 1 ] - r2[ 0 ] ) / ( r1[ 1 ] - r1[ 0 ] ) + r2[ 0 ];
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

        Item {
            x: 0
            width: 1200
            height: parent.height

            Repeater {
                id: rep1
                // model: [1, 2, 3, 4]
                model: PatchBayModel {}
                PatchBayEffect {
                    effect_id: l_effect_id
                    effect_type: l_effect_type
                    x: cur_x
                    y: cur_y
                    highlight: l_highlight
                }
                onItemAdded: {
                    if ("invalid" in effect_map){
                        delete effect_map["invalid"];
                    }
                    // console.log("added", index, item.effect_id);
                    effect_map[item.effect_id] = item;
                    // console.log(Object.keys(effect_map)); //[item.effect_id]);
                }
            }

            // Shape {
            //     width: parent.width
            //     height: parent.height
            //     ShapePath {
            //         strokeWidth: 1
            //         strokeColor: "red"
            //         // strokeStyle: ShapePath.DashLine
            //         // dashPattern: [ 1, 4 ]
            //         // startX: rep1.itemAt(0).children[0].x; startY: rep1.itemAt(0).children[0].y
            //         startX: 20; startY: 20  
            //         PathLine { x: rep1.itemAt(current_index).x; y: rep1.itemAt(current_index).y}
            //         // PathLine { x: 100; y: 100}
            //     }
            //     z: 5
            // }

            Canvas {
                id: mycanvas
                function findConnections(drawContext){ 
                    // iterate over items in rep1, adding to dictionary of effect_id : patchbayeffect
                    console.log("finding connection", Object.keys(portConnections));
                    for (var source_effect_port_str in portConnections){ 
                        console.log("key ", source_effect_port_str);
                        var source_effect_port = source_effect_port_str.split(":");
                        var targets = portConnections[source_effect_port_str];
                        console.log("drawing connection 1", source_effect_port[0], portConnections[source_effect_port_str]);
                        for (var target in targets){
                             console.log("drawing connection 2 targets", targets[0][0]);
                             console.log("drawing connection 2 obj", effect_map[source_effect_port[0]], effect_map[targets[target][0]]);
                             console.log("drawing connection 2 keys", source_effect_port[0], targets[target][0]);
                             //effect_map[source_effect_port[0]], effect_map[targets[target][0]]
                             drawConnection(drawContext, effect_map[source_effect_port[0]], effect_map[targets[target][0]]);
                        } 
                    }
                }

                function drawConnection( drawContext, outputPort, inputPort ) {
                    var start   = getCanvasCoordinates( outputPort, 0, 10)
                    var end     = getCanvasCoordinates( inputPort,  inputPort.width, 10) 
                    if( start.x > end.x ) {
                        var tmp = start;
                        start = end;
                        end = tmp;
                    }

                    var minmax  = getMinMax( start, end )
                    var sizeX   = minmax[2] - minmax[0]


                    drawContext.lineWidth   = 4;
                    if (patch_bay.isMoving){
                        drawContext.strokeStyle = setColorAlpha(Material.accent, 0.2);
                    } else
                    {
                        drawContext.strokeStyle = Material.accent;
                    }
                    drawContext.beginPath();
                    drawContext.moveTo( start.x, start.y );
                    drawContext.bezierCurveTo( start.x + sizeX / 4 , start.y, end.x - sizeX / 4, end.y, end.x, end.y );
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

            // bottom buttons
            // normal
            // add
            // remove
            // move
            //
            ButtonGroup {
                id: modeButtonGroup
                buttons: patchButtons.children
                exclusive: true
                onClicked: {
                    checkedButton = button;
                }
            }

            Row {
                id: patchButtons
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                spacing: 20
                Button {
                    id: expandMode
                    icon.name: "md-expand"
                    width: 70
                    height: 70
                    checked: true
                }
                Button {
                    id: moveMode
                    icon.name: "md-move"
                    width: 70
                    height: 70
                    onClicked: {
                    }
                }
                Button {
                    id: connectMode
                    icon.name: "md-git-branch"
                    width: 70
                    height: 70
                    onClicked: {
                    }
                }
                Button {
                    id: disconnectMode
                    icon.name: "md-git-compare"
                    width: 70
                    height: 70
                    onClicked: {
                    }
                }
                Button {
                    icon.name: "md-add"
                    width: 70
                    height: 70
                    onClicked: {
                        mainStack.push(addEffect);
                    }
                }
                Button {
                    id: deleteMode
                    icon.name: "md-close"
                    width: 70
                    height: 70
                    onClicked: {
                        console.log("clicked:");
                        // if (checked){
                        //     modeButtonGroup.checkedButton = expandMode;
                        // }
                        // else
                        // {
                        //     modeButtonGroup.checkedButton = deleteMode;
                        // }
                    }
                }
            
            }
        }

        Component {
            id: addEffect
            Item {
                id: addEffectCon
                height:700
                width:1280

                GlowingLabel {
                    color: "#ffffff"
                    text: "Add Effect"
                    font {
                        pixelSize: fontSizeLarge
                    }
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ListView {
                    width: 400
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 50
                    anchors.bottom: parent.bottom
                    clip: true
                    delegate: ItemDelegate {
                        width: parent.width
                        height: 50
                        text: edit
                        bottomPadding: 0
                        font.pixelSize: fontSizeMedium
                        topPadding: 0
                        onClicked: {
                            knobs.add_new_effect(edit)
                            // knobs.ui_add_effect(edit)
                            mainStack.pop()
                        }
                    }
                    ScrollIndicator.vertical: ScrollIndicator {
                        anchors.top: parent.top
                        parent: addEffectCon
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.bottom: parent.bottom
                    }
                    model: available_effects
                }
            
                

                Button {
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

        Component {
            id: portSelection
            Item {
                id: portSelectionCon
                height:700
                width:1280

                GlowingLabel {
                    color: "#ffffff"
                    text: "Choose Port"
                    font {
                        pixelSize: fontSizeLarge
                    }
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ListView {
                    width: 400
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 50
                    anchors.bottom: parent.bottom
                    clip: true
                    delegate: ItemDelegate {
                        width: parent.width
                        height: 50
                        text: edit
                        bottomPadding: 0
                        font.pixelSize: fontSizeMedium
                        topPadding: 0
                        onClicked: {
                            // set this as the current port
                            // and update valid targets
                            knobs.set_current_port(list_source, list_effect_id, edit);
                            rep1.model.items_changed();
                            mycanvas.requestPaint();
                            // rep1.model.add_effect(edit)
                            // knobs.ui_add_effect(edit)
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
            
                

                Button {
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

        Component {
            id: disconnectPortSelection
            Item {
                id: disPortSelectionCon
                height:700
                width:1280

                GlowingLabel {
                    color: "#ffffff"
                    text: "Disconnect Port"
                    font {
                        pixelSize: fontSizeLarge
                    }
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                ListView {
                    width: 400
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 50
                    anchors.bottom: parent.bottom
                    clip: true
                    delegate: ItemDelegate {
                        width: parent.width
                        height: 50
                        text: edit
                        bottomPadding: 0
                        font.pixelSize: fontSizeMedium
                        topPadding: 0
                        onClicked: {
                            // set this as the current port
                            // and update valid targets
                            //knobs.set_current_port(list_source, list_effect_id, edit);
                            console.log("disconnect", edit);
                            rep1.model.items_changed();
                            mycanvas.requestPaint();
                            // rep1.model.add_effect(edit)
                            // knobs.ui_add_effect(edit)
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
            
                

                Button {
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

        // Popup {
        //     id: portSelectionPopup
        //     property var ports: []
        //     // x: 500
        //     // y: 200
        //     width: 600
        //     height: 400
        //     modal: true
        //     focus: true
        //     closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        //     parent: Overlay.overlay
        //     Overlay.modal: Rectangle {
        //         // x: 500
        //         // y: -560
        //         width: 1280
        //         height: 1280
        //         color: "#AA333333"
        //         transform: Rotation {
        //             angle: -90
        //             // origin.x: Screen.height / 2
        //             // origin.x: Screen.height / 2
        //             // origin.x: 720 / 2
        //             // origin.y: 720 / 2
        //             origin.x: 1280 / 2
        //             origin.y: 1280 / 2
        //         }
        //     }

        //     x: Math.round((parent.width - width) / 2)
        //     y: Math.round((parent.height - height) / 2)

        //     function open_port_selection(effect){
        //         portSelectionPopup.open()
        //     }

        //     Item {
        //         id: portSelectCont
        //         anchors.centerIn: parent
        //         width:500
        //         height:500
        //         Label {
        //             text: "Select Port"
        //             font.pixelSize: baseFontSize
        //             width: 190
        //         }
        //         ListView {
        //             width: 400
        //             anchors.centerIn: parent
        //             clip: true
        //             delegate: ItemDelegate {
        //                 width: parent.width
        //                 height: 50
        //                 text: edit
        //                 bottomPadding: 0
        //                 font.pixelSize: fontSizeMedium
        //                 topPadding: 0
        //                 onClicked: {
        //                     // rep1.model.add_effect(edit)
        //                     // knobs.ui_add_effect(edit)
        //                     // mainStack.pop()
        //                     portSelectionPopup.close()
        //                 }
        //             }
        //             ScrollIndicator.vertical: ScrollIndicator {
        //                 anchors.top: parent.top
        //                 parent: portSelectCont
        //                 anchors.right: parent.right
        //                 anchors.rightMargin: 1
        //                 anchors.bottom: parent.bottom
        //             }
        //             model: selectedEffectPorts
        //         }
        //     }
        // } 
    }
