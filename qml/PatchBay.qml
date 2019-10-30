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
        id: time_scale
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
            // mycanvas.requestPaint();
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
                PatchBayEffect {}
            }

            Shape {
                width: parent.width
                height: parent.height
                ShapePath {
                    strokeWidth: 1
                    strokeColor: "red"
                    // strokeStyle: ShapePath.DashLine
                    // dashPattern: [ 1, 4 ]
                    // startX: rep1.itemAt(0).children[0].x; startY: rep1.itemAt(0).children[0].y
                    startX: 20; startY: 20  
                    PathLine { x: rep1.itemAt(current_index).children[1].x; y: rep1.itemAt(current_index).children[1].y}
                    // PathLine { x: 100; y: 100}
                }
                z: 5
            }

            // Canvas {
            //     id: mycanvas
            //     anchors {
            //         top: parent.top
            //         right:  parent.right
            //         bottom:  parent.bottom
            //     }
            //     width: time_scale.active_width
            //     onPaint: {
            //         var ctx = getContext("2d");
            //         ctx.fillStyle = Material.background; //Qt.rgba(1, 1, 0, 1);
            //         ctx.fillRect(0, 0, width, height);
            //         // draw beat snap lines  
            //         if (time_scale.synced){
            //             ctx.fillStyle = Material.accent;//Qt.rgba(0.1, 0.1, 0.1, 1);

            //             for (var i = 0; i < (time_scale.division*time_scale.bars); i++) {
            //                 if ((i % time_scale.division) == 0)
            //                 {
            //                     ctx.fillRect((width/(time_scale.division*time_scale.bars))*i, 0, 3, height);
            //                     ctx.fillText(i-1, x+2, height - 10);
            //                 }
            //                 else
            //                 {
            //                     ctx.fillRect((width/(time_scale.division*time_scale.bars))*i, 0, 1, height);
            //                 }
            //             }
            //         }
            //         else
            //         {
            //             // every second
            //             ctx.fillStyle = Material.accent;//Qt.rgba(0.1, 0.1, 0.1, 1);

            //             // ctx.fillRect(0, 0, 1, height);

            //             for (var i = 1; i < time_scale.max_delay_length+1; i++) {
            //                 var x = (width/time_scale.max_delay_length)*i
            //                 ctx.fillRect(x, 0, 1, height);
            //                 // var x = width/Math.log(time_scale.max_delay_length+1)*Math.log(i)
            //                 // ctx.fillRect(x, 0, 1, height);
            //                 if (i < 4)
            //                 {
            //                     ctx.fillText(i-1, x+2, height - 10);
            //                 }
            //             }
            //         }

            //     }
            //     DropArea {
            //         anchors.fill: parent
            //         onEntered: drag.source.caught = true;
            //         onExited: drag.source.caught = false;
            //     }
            // }

            // bottom buttons
            // normal
            // add
            // remove
            // move
            Row {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                spacing: 20
                Button {
                    icon.name: "md-expand"
                    width: 70
                    height: 70
                }
                Button {
                    icon.name: "md-move"
                    width: 70
                    height: 70
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
                    icon.name: "md-close"
                    width: 70
                    height: 70
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
                            knobs.ui_add_effect(edit)
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

    }
