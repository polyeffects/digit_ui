import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import "../qml/polyconst.js" as Constants

    Item {
        x: 0
        id: time_scale
        width: 1280
        height: 620
        property int step_height: 354

        Rectangle {
            x: 20
			y: 20
            width: 1260
            height: 600 
			id: stepCol

			MultiPointTouchArea {
				id: mouseArea
				anchors.fill: parent
				minimumTouchPoints: 1
				maximumTouchPoints: 1
				// hoverEnabled: true
				onTouchUpdated: {
					var point = touchPoints[0];
					// console.log("position is", point.y);
					if (point == undefined){
						return;
					}
					var x1 = point.x;
					var y1 = point.y;
                    touch_indicator.x = x1;
                    touch_indicator.y = y1;
					// console.log("step child is", c.children[0].step_id, "point y is", point.y);
					knobs.xy_pad_change(x1 / parent.width, y1 / parent.height);
				}

			}

			color: Qt.rgba(0, 0, 0, 0)
			border { 
				width:1; 
				color: Constants.outline_color
			}

            Rectangle {
                x: parent.width / 2
                y: 0
                width: 2
                height: parent.height 
				color: Constants.outline_color
            }

            Rectangle {
                x: 0
                y: parent.height / 2
                width: parent.width
                height: 2
				color: Constants.outline_color
            }

            Rectangle {
                id: touch_indicator
                x:parent.width / 2
                y: parent.height / 2
                width:62
                height: 62 
                color: Qt.rgba(0, 0, 0, 0)
                radius: 31
                border { 
                    width:2; 
                    color: Constants.rainbow[0]
                }
            }


		}

    }

