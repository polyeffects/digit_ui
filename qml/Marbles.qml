import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3
import QtQuick.Layouts 1.3
import "../qml/polyconst.js" as Constants

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
    property string effect_id: "none"
    property int tab_index: 0
    z: 3
    x: 0
    height:546
    width:1280

    // 2 columns,
    Column {
        x: 12
        y: 12
        width: 223
        height: 522
        spacing: 9
    
        Repeater {
            model: ["Gate Generator", "X Voltage", "Deja Vu", "Y Voltage", "Steps Quantizer"]
            Button {
                height: 92
                width: 180
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
        x:  198
        y: 0
        width: 2
        z: 3
        height: parent.height
        color: Constants.poly_grey
    }


    // [  'filtatype', 'filtbtype', 'filtdtype',   'link', 'rt_speed']

    StackLayout {
        width: 1107
        height: 522
        x: 223
        y: 0
        currentIndex: tab_index

        Item { // gate generator
            x: 2
            y: 0
            width: 1107
            height: 522


            Column {
                x: 0
                y: 0
                spacing: 30
                width: 515
                height: 522
                Label {
                    width: parent.width
                    height: 71
                    text: "Gate Controls"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Constants.poly_pink
                    font {
                        // pixelSize: fontSizeMedium
                        pixelSize: 30
                        capitalization: Font.AllUppercase
                    }
                }
                Row {

                    VerticalIconSelector {
                        current_effect: effect_id

                    }

                    VerticalSlider {
                        width: 120 
                        height: 350
                        title: "BIAS"
                        current_effect: effect_id
						row_param: "t_bias_param"
                        Material.foreground: Constants.poly_pink
                    }

                }

            }

            Column {
                x: 518
                y: 0
                spacing: 15
                width: 500
                height: 522
                Label {
                    width: parent.width
                    height: 71
                    text: "Clock"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Constants.poly_purple
                    font {
                        pixelSize: 30
                        capitalization: Font.AllUppercase
                    }
                }

                TextButtonSelector {
                    current_effect: effect_id

                }

                DelayRow {
                    row_param: "t_rate_param"
                    current_effect: effect_id
                    Material.foreground: Constants.poly_purple
                    z: 2
                }

                Label {
                    width: parent.width
                    height: 71
                    z: 2
                    text: "Jitter"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Constants.poly_blue
                    font {
                        pixelSize: 30
                        capitalization: Font.AllUppercase
                    }
                }

                IconSlider {
                    width: 470
                    row_param: "t_jitter_param"
                    icons: ['Jitter1.png', 'Jitter2.png']
                    current_effect: effect_id
                    icon_path: "../icons/digit/marbles/gate/Jitter/"
                    only_top: true
                    show_labels: false
                    topPadding: -130
                }



            }

        }
        Item { // x voltage
            x: 2
            y: 0
            width: 1107
            height: 522


            Column {
                x: 0
                y: 0
                spacing: 30
                width: 515
                height: 522
                Label {
                    width: parent.width
                    height: 71
                    text: "Output Voltage Range"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Constants.poly_green
                    font {
                        // pixelSize: fontSizeMedium
                        pixelSize: 30
                        capitalization: Font.AllUppercase
                    }
                }

                TextButtonSelector {
                    current_effect: effect_id
                    labels: ["2 octave", "0 to +V", "-V to +V"]
                    pixel_size: 24
                    color: Constants.poly_green
                    row_param: "x_range_param"
                }

                DelayRow {
                    row_param: "x_spread_param"
                    current_effect: effect_id
                    Material.foreground: Constants.poly_green
                }

                DelayRow {
                    row_param: "x_bias_param"
                    current_effect: effect_id
                    Material.foreground: Constants.poly_green
                }

            }

            Column {
                x: 518
                y: 0
                spacing: 30
                width: 520
                height: 522
                Label {
                    width: parent.width
                    height: 71
                    text: "Output Controls"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Constants.poly_yellow
                    font {
                        pixelSize: 30
                        capitalization: Font.AllUppercase
                    }
                }

                IconSelector {
                    current_effect: effect_id
                    height: 100
                    width: 460
                    row_param: "x_mode_param"
                    icon_prefix: "../icons/digit/marbles/x_voltage/Output Control icons/"
                    icons: ["equal.png", "incremental.png", "steppy.png"]
                    button_height: 100
                    button_width:108
                    icon_size: 40
                    button_spacing: 10
                    label_offset: 130
                    show_labels: false
                    z: 2
                }


                Label {
                    width: parent.width
                    height: 71
                    text: "Smoothness"
                    z: 2
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Constants.poly_yellow
                    font {
                        pixelSize: 30
                        capitalization: Font.AllUppercase
                    }
                }

                IconSlider {
                    width: 450
                    row_param: "x_steps_param"
                    icons: ['Step 1 icon.png', 'Step 2 icon.png', 'Step 3 icon.png']
                    current_effect: effect_id
                    icon_path: "../icons/digit/marbles/x_voltage/Step/"
                    only_top: true
                    show_labels: false
                    topPadding: -130
                }



            }

        }

        Item { // deja vu
            x: 2
            y: 0
            width: 1107
            height: 522


            Column {
                x: 0
                y:50
                spacing: 30
                width: 515
                height: 522

                IconButton {
                    icon.source: "../icons/digit/marbles/deja_vu/T-Generator.png"
                    width: 296
                    height: 186
                    icon.width: 60
                    icon.height: 60
                    has_border: true
                    checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
                    onClicked: {
                        knobs.ui_knob_change(effect_id, "t_deja_vu_param", 1 - currentEffects[effect_id]["controls"]["t_deja_vu_param"].value);
                    }
                    Material.background: checked ? Constants.poly_pink : "transparent"
                    Material.foreground: !checked ? Constants.poly_pink : "black"
                    Material.accent: Constants.poly_pink 
                    radius: 10
                    Label {
                        x: 0
                        y: 150 
                        text: "Loop T"
                        horizontalAlignment: Text.AlignHCenter
                        width: 296
                        height: 22
                        z: 1
                        // color: "white"
                        font {
                            pixelSize: 18
                            capitalization: Font.AllUppercase
                        }
                    }
                }

                IconButton {
                    icon.source: "../icons/digit/marbles/deja_vu/X-Generator.png"
                    width: 296
                    height: 186
                    icon.width: 60
                    icon.height: 60
                    has_border: true
                    checked: currentEffects[effect_id]["controls"]["x_deja_vu_param"].value == 1.0
                    onClicked: {
                        knobs.ui_knob_change(effect_id, "x_deja_vu_param", 1 - currentEffects[effect_id]["controls"]["x_deja_vu_param"].value);
                    }
                    Material.background: checked ? Constants.poly_pink : "transparent"
                    Material.foreground: !checked ? Constants.poly_pink : "black"
                    Material.accent: Constants.poly_pink 
                    radius: 10
                    Label {
                        x: 0
                        y: 150 
                        text: "Loop X"
                        horizontalAlignment: Text.AlignHCenter
                        width: 296
                        height: 22
                        z: 1
                        // color: "white"
                        font {
                            pixelSize: 18
                            capitalization: Font.AllUppercase
                        }
                    }
                }
            }

            Column {
                x: 518
                spacing: 30
                width: 589
                // height: 522
                anchors.verticalCenter: parent.verticalCenter
                

                DelayRow {
                    row_param: "deja_vu_length_param"
                    current_effect: effect_id
                    Material.foreground: Constants.poly_pink
                }

                DelayRow {
                    row_param: "deja_vu_param"
                    current_effect: effect_id
                    Material.foreground: Constants.poly_pink
                }

            }

        }

        Item { // Y 
            x: 2
            y: 0
            width: 1107
            height: 522


            Column {
                x: 0
                y: 0
                spacing: 10
                width: 515
                height: 522
                Row {

                    Label {
                        width: 140
                        height: 120
                        text: "Rate"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Constants.poly_pink
                        font {
                            // pixelSize: fontSizeMedium
                            pixelSize: 30
                            capitalization: Font.AllUppercase
                        }
                    }

                    IconSlider {
                        width: 730
                        height: 120
                        row_param: "y_divider"
                        icons: ['Rate 1.png', 'Rate 2.png',  'Rate 3.png',  'Rate 4.png']
                        current_effect: effect_id
                        icon_path: "../icons/digit/marbles/y_voltage/Rate icons/"
                        only_bottom: true
                        show_labels: false
                    }

                }

                Row {

                    Label {
                        width: 140
                        height: 120
                        text: "Spread"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Constants.poly_pink
                        font {
                            // pixelSize: fontSizeMedium
                            pixelSize: 30
                            capitalization: Font.AllUppercase
                        }
                    }

                    IconSlider {
                        width: 730
                        height: 120
                        row_param: "y_spread_param"
                        icons: ['Spread1.png', 'Spread2.png',  'Spread3.png',  'Spread4.png', 'Spread5.png']
                        current_effect: effect_id
                        icon_path: "../icons/digit/marbles/y_voltage/Spread icons/"
                        only_bottom: true
                        show_labels: false
                    }

                }

                Row {

                    Label {
                        width: 140
                        height: 120
                        text: "Bias"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Constants.poly_pink
                        font {
                            // pixelSize: fontSizeMedium
                            pixelSize: 30
                            capitalization: Font.AllUppercase
                        }
                    }

                    IconSlider {
                        width: 730
                        height: 120
                        row_param: "y_bias_param"
                        icons: ['Bias1.png', 'Bias2.png',  'Bias3.png',  'Bias4.png', 'Bias5.png']
                        current_effect: effect_id
                        icon_path: "../icons/digit/marbles/y_voltage/Bias icons/"
                        only_bottom: true
                        show_labels: false
                    }

                }
                Row {

                    Label {
                        width: 140
                        height: 120
                        text: "Steps"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        color: Constants.poly_pink
                        font {
                            // pixelSize: fontSizeMedium
                            pixelSize: 30
                            capitalization: Font.AllUppercase
                        }
                    }

                    IconSlider {
                        width: 730
                        height: 120
                        row_param: "x_steps_param"
                        icons: ['Steps1.png', 'Steps2.png',  'Steps3.png',  'Steps4.png', 'Steps5.png']
                        current_effect: effect_id
                        icon_path: "../icons/digit/marbles/y_voltage/Steps icons/"
                        only_bottom: true
                        show_labels: false
                    }

                }

            }
        }
        Item { // Scale 
            x: 2
            y: 0
            width: 1107
            height: 522


            Column {
                x: 0
                y: 0
                spacing: 30
                width: 1107
                height: 522
                Label {
                    width: 1107
                    height: 77
                    text: "Scale Selection"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Constants.poly_pink
                    font {
                        // pixelSize: fontSizeMedium
                        pixelSize: 30
                        capitalization: Font.AllUppercase
                    }
                }
                Grid {
                    spacing: 15 
                    height: 450
					columns: 3
                    width: parent.width

                    Repeater {
                        model: ["Major", "Minor", "Pentatonic", "Pelog", "Raag Bhairav That", "Raag Shrg"]
                        RoundButton {
                            width: 337
                            height: 103
                            checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                            onClicked: {
                                knobs.ui_knob_change(effect_id, "x_scale", index);
                            }
                            // Material.background: "white"
                            Material.foreground: Constants.poly_pink 
                            Material.accent: "white"
                            radius: 10
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
    }
	MoreButton {
	}
}

