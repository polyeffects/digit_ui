import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import "../qml/polyconst.js" as Constants

Rectangle {
  id: rectangle
  width: 1285; height: 520
  color: Constants.background_color
  property var currentBeat: [1, 3, 3, 2]

  function drawArchs(radius, ctx, trackIndex) {
    if (!trackModel.get(trackIndex).isEnabled) {
      ctx.globalAlpha = 0
      return
    }
    ctx.beginPath();
    ctx.lineWidth = 2;
    ctx.strokeStyle = Constants.poly_grey;
    ctx.arc(260, 260, radius, 0, Math.PI * 2);
    ctx.stroke();
    drawSteps(radius, ctx, trackIndex);
  }

  function findBeats(index) {
    var steps = trackModel.get(index).steps;
    var beats = trackModel.get(index).beats;
    var bucket = 0
    var beatsArray = [];
    var beat = beats
    for (var i = 1; i <= steps; i++) {
      bucket += beats
      if (bucket >= steps){
        bucket -= steps
        beatsArray.push(beat)
        beat -= 1
      } else {
        beatsArray.push(0);
      }
    }
    return beatsArray;
  }

  function styleStep(lineWidth, strockStyle, fillStyle, ctx, steps, stepIndex, radius, stepRadius) {
    ctx.strokeStyle = strockStyle
    ctx.lineWidth = lineWidth
    ctx.fillStyle = fillStyle
    ctx.beginPath()
    var a = (Math.PI *3/2) + (2 * Math.PI/steps * stepIndex);
    var x = 260 + (radius * Math.cos(a))
    var y = 260 + (radius * Math.sin(a))
    ctx.arc(x, y, stepRadius, 0, 2 * Math.PI)
    ctx.fill()
    ctx.stroke()
  }

  function drawSteps(radius, ctx, trackIndex) {
    var steps = trackModel.get(trackIndex).steps
    var beats = trackModel.get(trackIndex).beats
    var beatsArray = findBeats(trackIndex)

    for (var i = 0; i < trackModel.get(trackIndex).shift; i++) {
      var lastStep = beatsArray.shift()
      beatsArray.push(lastStep)
    }

    beatsArray = beatsArray.reverse()
    var currentBeatIndex = beatsArray.indexOf(currentBeat[trackIndex])

    if (!trackModel.get(trackIndex).isEnabled) {
      ctx.globalAlpha = 0
      return
    }

    for (i = 0; i < steps; i++) {
      if (i === currentBeatIndex) {
        styleStep(2, trackModel.get(trackIndex).trackColor, Constants.background_color, ctx, steps, i, radius, 15.5)
        styleStep(2, trackModel.get(trackIndex).trackColor, Constants.background_color, ctx, steps, i, radius, 10.5)
        styleStep(0, trackModel.get(trackIndex).trackColor, trackModel.get(trackIndex).trackColor, ctx, steps, i, radius, 5.5)
      }
      else if (beatsArray[i] != 0 && i === trackModel.get(trackIndex).shift) {
          styleStep(2, trackModel.get(trackIndex).trackColor, Constants.background_color, ctx, steps, i, radius, 10.5)
          styleStep(0, trackModel.get(trackIndex).trackColor, trackModel.get(trackIndex).trackColor, ctx, steps, i, radius, 5.5)
        }
      else if (beatsArray[i] != 0)
        styleStep(2, trackModel.get(trackIndex).trackColor, Constants.background_color, ctx, steps, i, radius, 10.5)
      else
        styleStep(4, Constants.background_color, Constants.poly_grey, ctx, steps, i, radius, 10.5)
    }
  }

  Canvas {
    id: canvas
    width: parent.width
    height: parent.height
    property var radiusArray: [230, 180, 130, 80]
    onPaint: {
      var ctx = getContext("2d");
      ctx.reset()
      for (var i = 0; i < radiusArray.length; i++) {
        drawArchs(radiusArray[i], ctx, i);
      }
    }
  }

  Rectangle {
    x: 514
    height: 520; width: 762
    color: Constants.background_color

    RowLayout {
      spacing: 9
      
      Repeater {
        model: ListModel {
          id: trackModel

          ListElement {
            trackColor: "#53A2FD"
            isEnabled: true
            steps: 12
            beats: 4
            shift: 1
          }
          
          ListElement {
            trackColor: "#80FFE8"
            isEnabled: true
            steps: 6
            beats: 1
            shift: 1
          }

          ListElement {
            trackColor: "#FFD645"
            isEnabled: true
            steps: 12
            beats: 1
            shift: 1
          }

          ListElement {
            trackColor: "#FFA9EC"
            isEnabled: true
            steps: 12
            beats: 1
            shift: 1
          }
        }

        Item {
          height: 520; width: 180

          Rectangle {
            x: 0; y: 0
            height: 520; width: 2; color: Constants.poly_grey
          }

          GridLayout {
            id: grid
            y: 17; x: 20
            columns: 2; rows: 3; columnSpacing: 16; rowSpacing: 14
            flow: GridLayout.TopToBottom

            Repeater {
              model: ListModel {
                id: iconModel
                ListElement { name: "eye"; iconWidth: 33; iconHeight: 20}
                ListElement { name: "forward"; iconWidth: 35; iconHeight: 40}
                ListElement { name: "vector"; iconWidth: 34; iconHeight: 31}
                ListElement { name: "close"; iconWidth: 28; iconHeight: 30}
                ListElement { name: "backward"; iconWidth: 35; iconHeight: 40}
                ListElement { name: "restart"; iconWidth: 30; iconHeight: 30}
              }
              
              Button {
                Layout.minimumWidth: 70
                Layout.minimumHeight: 70
                icon.width: iconWidth
                icon.height: iconHeight
                enabled: isEnabled
                icon.source: (!isEnabled && index == 0) ? "../icons/digit/euclidean/hidden.png" : "../icons/digit/euclidean/" + name + ".png"
                icon.color: isEnabled ? (index == 0) ? "black" : trackColor : (index == 0) ? trackColor : Constants.poly_grey

                onClicked: {
                  if (index === 0) {
                    isEnabled = !isEnabled
                    enabled = true
                    canvas.requestPaint()
                  }
                }

                background: Rectangle {
                  width: parent.width
                  height: parent.height
                  border.width: 2
                  border.color: (isEnabled && index == 0) ? trackColor : Constants.poly_grey
                  color: (!isEnabled && index == 0) ? Constants.poly_grey : (index == 0) ? trackColor : Constants.background_color
                  radius: 11
                }
              }
            }
          }

          ColumnLayout {
            id: columnLayout
            x: 20; y:271
            spacing: 19
            property int columnIndex: index
            
            Repeater {
              model: ["steps", "beats", "shift"]

              RowLayout {
                spacing: -11

                Rectangle {
                  width: 54
                  height:65
                  border.width: 2
                  border.color: Constants.poly_grey
                  color: Constants.background_color
                  radius: 11

                  Button {
                    width: 41
                    height:60
                    y:2
                    x: 2
                    icon.source: "../icons/digit/euclidean/substract.png"
                    icon.color: isEnabled ? "white" : Constants.poly_grey
                    icon.width: 17
                    enabled: isEnabled

                    onClicked: {
                      var column = columnLayout.columnIndex
                      var value =  trackModel.get(column)[modelData]
                      if (value > 0) {
                        trackModel.setProperty(column, modelData, value - 1)
                        canvas.requestPaint();
                        if (modelData === "steps") {
                          if (value === trackModel.get(column).beats) {
                            trackModel.setProperty(column, "beats", value - 1)
                          }
                          if (value === trackModel.get(column).shift) {
                            trackModel.setProperty(column, "shift", value - 1)
                          }
                          if ((value - 1) === (trackModel.get(column).shift)) {
                            trackModel.setProperty(column, "shift", trackModel.get(column).shift === 0 ? 0 :  trackModel.get(column).shift - 1)
                          }
                        }
                      }
                    }
                    
                    background: Rectangle {
                      width: parent.width
                      height: parent.height
                      color: Constants.background_color
                      radius: 11
                    }
                  }
                }

                Rectangle {
                  width: 70
                  height: 65
                  z: 1
                  color: Constants.background_color
                  border.width: 2
                  border.color: Constants.poly_grey

                  Rectangle {
                    x:2
                    y:2
                    height: 30
                    width: 65
                    color: Constants.background_color

                    Text {
                      text: modelData
                      color: isEnabled ? "white" : "#6E6E6E"
                      anchors.centerIn: parent
                      font {
                        pixelSize: 20
                        capitalization: Font.AllUppercase
                        family: mainFont.name
                      }
                    }
                  }

                  Rectangle {
                    x:2
                    y: 29
                    height: 30
                    width: 65
                    color: Constants.background_color

                    Text {
                      text: trackModel.get(columnLayout.columnIndex)[modelData]
                      color: isEnabled ? trackColor : Constants.poly_grey
                      anchors.centerIn: parent
                      font {
                        pixelSize: 30
                        capitalization: Font.AllUppercase
                        family: mainFont.name
                      }
                    }
                  }
                }

                Rectangle {
                  width: 54
                  height:65
                  border.width: 2
                  border.color: Constants.poly_grey
                  color: Constants.background_color
                  radius: 11

                  Button {
                    width: 41
                    height:60
                    y:2
                    x: 11
                    icon.source: "../icons/digit/euclidean/add.png"
                    icon.color: isEnabled ? "white" : Constants.poly_grey
                    icon.width: 17
                    enabled: isEnabled

                    onClicked: {
                      var column = columnLayout.columnIndex
                      var value =  trackModel.get(column)[modelData]
                      if (value >= 0) {
                        trackModel.setProperty(column, modelData, value + 1)
                        canvas.requestPaint();
                      }
                      if (modelData === "beats" && value === trackModel.get(column).steps) {
                        trackModel.setProperty(column, modelData, value)
                        canvas.requestPaint();
                      }
                      if (modelData === "shift" && (value + 1) === trackModel.get(column).steps) {
                        trackModel.setProperty(column, modelData, 0)
                        canvas.requestPaint();
                      }

                    }

                    background: Rectangle {
                      width: parent.width
                      height: parent.height
                      color: Constants.background_color
                      radius: 11
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
