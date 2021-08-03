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
        y: 30
        width: 223
        height: 522
        spacing: 15
    
        Repeater {
            model: ["Shape", "Output", "Mod"]
            Button {
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
        x:  170
        y: 0
        width: 2
        z: 3
        height: parent.height
        color: Constants.poly_grey
    }



    StackLayout {
        width: 1107
        height: 522
        x: 200
        y: 0
        currentIndex: tab_index

		Item { // Shape
			x: 2
			y: 0
			width: 1109
			height: 522


			Label {
				width: parent.width
				y: 25
				height: 30
				text: "Shape"
				z: 2
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				color: "white"
				font {
					pixelSize: 24
					capitalization: Font.AllUppercase
				}
			}

			IconSlider {
				x: 100
				y: 140
				width: 900
				height: 200
				row_param: "shape_param"
				icons: ['Shape_1.png', 'Shape_2.png', 'Shape_3.png', 'Shape_4.png', 'Shape_5.png', 'Shape_6.png', 'Shape_7.png']
				current_effect: effect_id
				icon_path: "../icons/digit/tides/shape/"
				only_top: true
				show_labels: false
				topPadding: -130
			}

			Rectangle {
				y: 255
				width: parent.width
				height: 2
				z: 3
				color: Constants.poly_grey
			}

			Row {
				y: 255
				x: 50
				height: 268
				width: parent.width
				spacing:  50
				Column {
					spacing: 30
					width: 460
					height: parent.height

					Label {
						width: parent.width
						height: 71
						text: "slope"
						z: 2
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						color: "white"
						font {
							pixelSize: 24
							capitalization: Font.AllUppercase
						}
					}

					IconSlider {
						width: parent.width
						row_param: "slope_param"
						icons: ['Slope_1.png', 'Slope_2.png', 'Slope_3.png']
						current_effect: effect_id
						icon_path: "../icons/digit/tides/slope/"
						only_top: true
						show_labels: false
						topPadding: -130
					}
				}

				Column {
					spacing: 30
					width: 460
					height: parent.height

					Label {
						width: parent.width
						height: 71
						text: "smoothness"
						z: 2
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						color: "white"
						font {
							pixelSize: 24
							capitalization: Font.AllUppercase
						}
					}

					IconSlider {
						width: parent.width
						row_param: "smoothness_param"
						icons: ['Smooth_1.png', 'Smooth_2.png', 'Smooth_3.png']
						current_effect: effect_id
						icon_path: "../icons/digit/tides/smoothness/"
						only_top: true
						show_labels: false
						topPadding: -130
					}
				}

			}

		}
        Item { // output
            x: 2
            y: 0
            width: 1107
            height: 522

			Row {
				spacing: 0

				Column {
					spacing: 30
					width: 340
					height: 522
					Label {
						width: parent.width
						height: 71
						text: "Frequency Range"
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
						spacing: 30
						width: 430

						VerticalTextButtonSelector {
							width: 160
							row_param: "range_param"
							current_effect: effect_id
						}

						VerticalSlider {
							width: 120 
							height: 350
							title: "Frequency"
							current_effect: effect_id
							row_param: "frequency_param"
							Material.foreground: Constants.poly_pink
						}

					}

				}
				Rectangle {
					width: 2
					z: 3
					height: parent.height
					color: Constants.poly_grey
				}
				Item {
					width: 448
					height: 522
					Label {
						x: 0
						y: 0
						width: parent.width
						height: 71
						text: "Output Mode"
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						color: Constants.poly_pink
						font {
							// pixelSize: fontSizeMedium
							pixelSize: 30
							capitalization: Font.AllUppercase
						}
					}

					VerticalIconSelector {
						y: 60
						x: 50
						current_effect: effect_id
						height: 505
						width: 230
						row_param: "mode_param"
						icon_prefix: "../icons/digit/tides/Output mode/"
						icons: ['differents_shapes.png', 'different_amplitudes.png', 'different_times.png', 'different_frequencies.png']
						button_height: 100
						button_width:230
						icon_size: 50
						button_spacing: 10
						label_offset: 70
						z: 2
					}

					VerticalSlider {
						y: 100
						x: 310
						width: 120 
						height: 350
						title: "Shift / Level"
						current_effect: effect_id
						row_param: "shift_param"
						Material.foreground: Constants.poly_blue
					}
				}
				Rectangle {
					width: 2
					z: 3
					height: parent.height
					color: Constants.poly_grey
				}
				Item {
					width: 290
					height: 522
					Label {
						x: 0
						y: 0
						width: parent.width
						height: 71
						text: "Ramp Mode"
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
						color: Constants.poly_pink
						font {
							// pixelSize: fontSizeMedium
							pixelSize: 30
							capitalization: Font.AllUppercase
						}
					}

					VerticalIconSelector {
						x: 20
						y: 60
						current_effect: effect_id
						height: 505
						width: 240
						row_param: "ramp_param"
						icon_prefix: "../icons/digit/tides/Ramp Mode/"
						icons: ['One-shot_unipolar_AD_envelope_generation.png', 'cyclic_bipolar_oscillations.png', 'one_shot_unipolar_envelope.png']
						button_height: 135
						button_width:240
						icon_size: 50
						button_spacing: 10
						label_offset: 85
						z: 2
					}
				}
			}
        }

        Item { // Mod 
            x: 2
            y: 0
            width: 1107
            height: 522

            Row {
                x: 50
				y: -20
                spacing: 50
                width: 900
                // height: 522
                anchors.verticalCenter: parent.verticalCenter

				Repeater {
					model: ['slope_cv_param', 'frequency_cv_param', 'smoothness_cv_param', 'shape_cv_param', 'shift_cv_param'] 

					VerticalSlider {
						height: 350
						row_param: modelData
						current_effect: effect_id
						Material.foreground: Constants.rainbow[index]
					}
				}

            }

        }

    }
	MoreButton {
	}
}

