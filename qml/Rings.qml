import "controls" as PolyControls
import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.3
import "../qml/polyconst.js" as Constants
Item {
    property string effect_id: "none"
    property int tab_index: 0
    property string effect_type: "multi_resonator"
    z: 3
    height:540
    width:1280

    // 2 columns,
    Column {
        x: 25
        y: 30
        width: 223
        height: 522
        spacing: 15
    
        Repeater {
            model: ["Model", "Tone", "Modulation"]
           PolyControls.Button {
                height: 141
                width: 130
                text: modelData
                checked: tab_index == index
                onClicked: {
                    tab_index = index;
                }

                contentItem: Text {
                    text: modelData
                    color:  checked ? Constants.background_color : "white"
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
                    color: checked ? Constants.poly_blue : Constants.poly_dark_grey  
                    border.width: 0
                    radius: 20
                }
            }
        }
    }

    Rectangle {
        x:  190
        y: 0
        width: 2
        z: 3
        height: parent.height
        color: Constants.poly_grey
    }

    StackLayout {
        y: 0
        x: 220
        width: 1107
        currentIndex: tab_index
        Column {
            spacing: 20
            width: 1123
            IconSelector {
                x: -100
                current_effect: effect_id
                height: 314
                width: 1123
                row_param: "resonator_param"
                icon_prefix: "../icons/digit/rings/"
                icons: ['rings.png', 'strings.png', 'brrings.png', 'sings.png', 'clings.png', 'springs.png', 'things.png']
                button_height: 200
                button_width:130
                icon_size: 50
                button_spacing: 10
                icon_offset: 30
                label_offset: 140
            }
            Row {
                width: 1123
                height: 208
                Label {
                    height: 208
                    text: "polyphony"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    width: 150
                    color: Constants.poly_green
                    font {
                        pixelSize: 28
                        capitalization: Font.AllUppercase
                    }
                }
                TextButtonSelector {
                    height: 208
                    current_effect: effect_id
                    labels: ["1", "2", "4"]
                    pixel_size: 36
                    color: Constants.poly_green
                    row_param: "polyphony_param"
                    width: 700
                    center: true
                }
            }
        } 

        Item {
            width: parent.width
            Grid {
                // x: 300
                // y: 100

                anchors.centerIn: parent
                spacing: 60
                columns: 2

                // Tone
                Repeater {
                    model: ['frequency_param', 'structure_param',  'brightness_param', 'damping_param', 'position_param', "internal_exciter_param"] 
                    DelayRow {
                        row_param: modelData
                        current_effect: effect_id
                        Material.foreground: Constants.rainbow[index+5]
                        v_type: modelData == "internal_exciter_param" ? "bool" : "float"
                    }
                }
            }
        }

        Item {
            width: parent.width
            Grid {
                anchors.centerIn: parent
                // x: 300
                // y: 100
                spacing: 60
                columns: 2
                // Modulation 
                Repeater {
                    model: ['frequency_mod_param', 'structure_mod_param',  'brightness_mod_param', 'damping_mod_param', 'position_mod_param'] 
                    DelayRow {
                        row_param: modelData
                        current_effect: effect_id
                        Material.foreground: Constants.rainbow[index+5]
                    }
                }
            }	
        }
    }
    MoreButton {
        l_effect_type: effect_type
    }
}

