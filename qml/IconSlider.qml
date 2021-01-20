import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Templates 2.4 as T
import QtQuick.Controls.Material 2.4
import QtQuick.Controls.Material.impl 2.4
import "polyconst.js" as Constants

T.Slider {
    id: control
    property string title
    property color accent: Material.foreground
    property string current_effect
    property string row_param: "int_osc"
    property bool only_top: false
    property bool only_bottom: false
    property bool show_labels: true
    property var icons: ['Crossfade.png', 'Crossfold.png', 'Diode Ring Modulation.png', 'Digital Ring Modulation.png', 'Bitwise XOR Modulation.png', 'Octaver Comparator.png', 'Vocoder 1.png', 'Vocoder 2.png', 'Freeze.png']
    property string  icon_path: "../icons/digit/warps/slider/"

    value: currentEffects[current_effect]["controls"][row_param].value
    from: currentEffects[current_effect]["controls"][row_param].rmin
    to: currentEffects[current_effect]["controls"][row_param].rmax
    onMoved: {
        knobs.ui_knob_change(current_effect, row_param, value);
        title_footer.current_footer_value = value
    }
    onPressedChanged: {
        if (pressed){
            knobs.set_knob_current_effect(current_effect, row_param);
            title_footer.show_footer_value = true
        }
        else {
            title_footer.show_footer_value = false
        }
    }


    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                           (handle ? handle.implicitWidth : 0) + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                            (handle ? handle.implicitHeight : 0) + topPadding + bottomPadding)

    padding: 6

    function remove_suffix(x)
    {
        return x.replace(/\.[^/.]+$/, "") 
    }

    handle: Rectangle {
        x: control.leftPadding + (control.horizontal ? control.visualPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : control.visualPosition * (control.availableHeight - height))
        // value: control.value
        // handleHasFocus: control.visualFocus
        // handlePressed: control.pressed
        // handleHovered: control.hovered
        id: handleRect
        width: 30
        height: 30
        radius: 15 
        color: "#80ffffff"
        scale: control.pressed ? 1.5 : 1


        Behavior on scale {
            NumberAnimation {
                duration: 250
            }
        }

    }

    // handle: Rectangle {
    //     x: control.leftPadding + (control.horizontal ? control.visualPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2)
    //     y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : control.visualPosition * (control.availableHeight - height))
    //     // value: control.value
    //     height: 25
    //     width: 25
    // } 

    background: Rectangle {
        x: control.leftPadding + (control.horizontal ? 0 : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : 0)
        implicitWidth: control.horizontal ? 420 : 325
        implicitHeight: control.horizontal ? 325 : 420
        // width: control.horizontal ? control.availableWidth : 30
        // height: control.horizontal ? 30 : control.availableHeight
        width: control.availableWidth 
        height: control.availableHeight
        color: control.Material.background
        border { width:0; color: accent}
        scale: control.horizontal && control.mirrored ? -1 : 1
        Rectangle {
            id: main_line
            x: 0
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            width: parent.width
            border { width:2; color: accent}
        }
        
        Repeater {
            model: icons
            Image {
                x: 2*control.leftPadding + (index  * ((main_line.width - 4*control.leftPadding) / (icons.length-1))) - (width / 2)
                y: (index % 2 == 0 || only_top) && !only_bottom ? -height + 16 + (parent.height / 2 ) : -16 + (parent.height / 2)
                source: icon_path+modelData
                Label {
                    visible: show_labels
                    x: -19 //- (parent.width / 2) + 30
                    y: index % 2 == 0 && !only_top ? -70 : parent.height + 5 //+ parent.height
                    text: remove_suffix(modelData)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    width: 120
                    height: 52
                    z: 1
                    color: "white"
                    font {
                        pixelSize: 18
                        capitalization: Font.AllUppercase
                    }
                }
            }
        }



        // Rectangle {
        //     x: control.horizontal ? 0 : (parent.width - width) / 2
        //     y: control.horizontal ? (parent.height - height) / 2 : control.visualPosition * parent.height
        //     width: control.horizontal ? control.position * parent.width : 3
        //     height: control.horizontal ? 3 : control.position * parent.height

        //     color: control.Material.accentColor
        // }
    }
}
