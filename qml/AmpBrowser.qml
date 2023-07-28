import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import "polyconst.js" as Constants
import QtQuick.Controls.Material 2.3
import QtQuick.VirtualKeyboard 2.1

// ApplicationWindow {
//     visible: true
//     width: 400
//     height: 480
//     title: qsTr("Hello World")

//     Material.theme: Material.Dark
//     Material.primary: Material.Green
//     Material.accent: Material.Pink


Item {

    function rsplit(str, sep, maxsplit) {
        var split = str.split(sep);
        return maxsplit ? [ split.slice(0, -maxsplit).join(sep) ].concat(split.slice(-maxsplit)) : split;
    }

    id: mainRect
    property string effect
    property string effect_type
    property url current_selected: currentEffects[effect]["controls"]["ir"].name
	property string selected_amp_name: rsplit(current_selected.toString(), "/", 2)[1] 
    property url top_folder: "file:///audio/amp_nam/"
    property var after_file_selected: (function(name) { return null; })
    property bool is_loading: false
    property bool showing_fav: false
    height: 720
    width: 1280


    // ActionIcons {

    // }

    // Label {
    //     x: Constants.left_col + 15
    //     y: 15
    //     text: display_name
    //     height: 45
    //     // height: 15
    //     color: accent_color.name
    //     font {
    //         pixelSize: fontSizeMedium*1.1
    //         // pixelSize: 11
    //         capitalization: Font.AllUppercase
    //     }
    // }


    Rectangle {
        x: 21
        y: 21
        width: 1230
        height: 70
        color: Constants.background_color  
        radius: 12
        border.width: 2
        border.color: "white"
        TextField {
            x:20
            y:0
            // validator: RegExpValidator { regExp: /^[0-9a-zA-Z ]+$/}
            id: amp_search
            width: 1180
            height: 70
            font {
                pixelSize: 24
            }
            placeholderText: qsTr("SEARCH")    
            onEditingFinished: {
                amp_browser_model.add_filter(amp_search.text)
            
            }
        }
    }

    // PolyButton {
    //     x:935
    //     y: 21
    //     height: 69
    //     width: 295
    //     // text: modelData
    //     onClicked: {
    //         // current_loop = index;
    //         // add new loop
    //         // loopler.ui_add_loop(1)
    //     }

    //     contentItem: Item { 
    //         Image {
    //             x: 20
    //             y: 16
    //             source: showing_fav ? "../icons/digit/fav.png" : "../icons/digit/not_fav.png" 
    //         }

    //         Text {
    //             x: 108
    //             y: 16
    //             text: "favourites"
    //             color: Constants.poly_pink
    //             height: 22
    //             font {
    //                 pixelSize: 22
    //                 capitalization: Font.AllUppercase
    //             }
    //         }
    //     } 



    //     background: Rectangle {
    //         width: parent.width
    //         height: parent.height
    //         color: Constants.background_color
    //         border.width: 2
    //         border.color: Constants.poly_pink  
    //         radius: 4
    //     }
    // }

    InputPanel {
        id: inputPanel
        z: 1000002
        anchors.bottom:parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        width: 1000

        visible: Qt.inputMethod.visible
    }

	Connections {
		target: Qt.inputMethod
		onVisibleChanged: {
			if (Qt.inputMethod.visible != true){
				// console.log("keyboard show / hide" + Qt.inputMethod.visible)
				amp_browser_model.add_filter(amp_search.text)
			}
		}
	
	}

    Item {
        id: folderRect
        x: 21
        y: 100
        height: 525
        width: 1280


        // width: parent.width
        // height: parent.height
        // GlowingLabel {
        //     anchors.left: mainRect.left
        //     anchors.leftMargin: 5
        //     text: remove_suffix(mainRect.basename(mainRect.current_selected))
        //     height: 60
        //     width: parent.width - 50
        //     font {
        //         pixelSize: fontSizeLarge
        //     }
        //     elide: Text.ElideMiddle
        // }

        // PolyButton {
        //     anchors.right: folderRect.right
        //     anchors.rightMargin: -100
        //     font_size: 30
        //     text: "UP"
        //     visible: folderListModel.folder != top_folder
        //     Material.foreground: Constants.background_color
        //     background_color: accent_color.name
        //     onClicked: {
        //         folderListModel.folder = folderListModel.parentFolder
        //         // console.log(folderListModel.folder, top_folder);
        //     } 
        //     height: 90
        //     width: 120
        //     z: 2
        // }
        Rectangle {
            width: parent.width
            height: 1
            color: "#1E000088"
            anchors.bottom: fileList.top
        }
        GridView {
            id: fileList
            y: 0
            width: parent.width
            height: 533
            clip: true
            cellWidth: 310
            cellHeight: 410
            visible: !(is_loading)

            model: amp_browser_model 
            // model: FolderListModel {
            //     id: folderListModel
            //     showDirsFirst: true
            //     folder: top_folder
// //                nameFilters: ["*.mp3", "*.flac"]
            // }
            delegate: Item {
                width: 300
                height: 400
				property bool is_selected: amp_name == selected_amp_name

            
                Rectangle {
                    width: parent.width
                    height: parent.height
                    color: is_selected ? "white" : Constants.background_color  
                    radius: 12
                    border.width: 2
                    border.color: Constants.outline_color
                }

                Item {
                    width: 304
                    height: 376

                    Image {
                        x: 10
                        y: 10
                        source: amp_image
						width: 280
						height: 280

                        PolyButton {
                            x: 8
                            y: 252 
                            height: 22
                            width: 54
                            topPadding: 5
                            // leftPadding: -5
                            // rightPadding: -5
                            radius: 25
                            Material.foreground: Constants.background_color
                            border_color: Constants.poly_yellow
                            background_color: Constants.poly_yellow
                            text: amp_year
                            font_size: 16
                        }

						// Item {
						// 	x: 228
						// 	y: 7
						// 	width: 45
						// 	height: 45

						// 	Image {
						// 		x: 7
						// 		y: 7
						// 		source: is_favourite ? "../icons/digit/fav.png" : "../icons/digit/not_fav.png" 
						// 	}
						// 	MouseArea {
						// 		// fill everything apart from favourite button
						// 		anchors.fill: parent
						// 		onClicked: {
						// 			knobs.toggle_module_favourite(l_effect);
						// 		}
						// 	}
						// }
                    }

                    // Rectangle {
                    //     x: 0
                    //     y: 289
                    //     width: parent.width
                    //     height: 87
                    //     color: Constants.outline_color  
                    //     radius: 4
                    //     border.width: 2
                    //     border.color: "white"
                    // }

                    Label {
                        x: 10
                        y: 299
                        height: 30
                        width: 300
                        text: amp_brand.replace(/_/g, " ")
                        wrapMode: Text.Wrap
						color: is_selected ? Constants.background_color : "white"  
                        // anchors.centerIn: parent
                        // anchors.bottomMargin: 25 
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        font {
                            pixelSize: 24
                            family: mainFont.name
                            weight: Font.DemiBold
                            capitalization: Font.AllUppercase
                        }
                    }

                    Label {
                        x: 10
                        y: 323
                        height: 30
                        width: 300
                        text: amp_model.replace(/_/g, " ")
                        wrapMode: Text.Wrap
						color: is_selected ? Constants.background_color : "white"  
                        // anchors.centerIn: parent
                        // anchors.bottomMargin: 25 
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        font {
                            pixelSize: 20
                            family: docFont.name
                            weight: Font.Medium
                            capitalization: Font.AllUppercase
                        }
                    }

                    // Label {
                    //     x: 31
                    //     y: 55
                    //     width: 598
                    //     height: 30
                    //     text: description 
                    //     wrapMode: Text.Wrap
                    //     // anchors.top: parent.top
                    //     font {
                    //         pixelSize: 24
                    //         family: docFont.name
                    //         weight: Font.Normal
                    //         // capitalization: Font.AllUppercase
                    //     }
                    // }

                    Row {
                        x: 10
                        y: 370
                        spacing: 6
                        width: 300
                        Repeater {
                            model: tags

                            PolyButton {
                                height: 22
                                topPadding: 5
                                leftPadding: 15
                                rightPadding: 15
                                radius: 25
                                Material.foreground: Constants.background_color
								border_color: Constants.short_rainbow[index % 4]
								background_color: Constants.short_rainbow[index % 4]
                                text: modelData
                                font_size: 16
                            }
                        }
                    }


                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            patchStack.push(ampCaptureSelection, {"objectName":"ampCaptureSelection", "amp_name":amp_name, 
                            "amp_brand": amp_brand, "amp_model": amp_model, "amp_year": amp_year, "tags": tags, "long_description": long_description, "amp_image": amp_image, "amp_control_names": amp_control_names, "amp_controls": amp_controls, "amp_selected_controls":amp_selected_controls});
							amp_browser_model.set_amp_control(effect, amp_name, "", "");
                        }
                    }
                }

            }

        }
        Label {
            visible: is_loading
            text: "LOADING"
            font.pixelSize: fontSizeLarge
            // anchors.centerIn: parent
            y: 160
            x: 30
            width: parent.width
            height: parent.height - 60
        }
    }
    Rectangle {
        x: 1280
        y: 0
        height: 540
        width: 2
        color: "pink"
    }


    // VerticalSlider {
    //     x: 1125
    //     y: 50
    //     width: 100 
    //     height: 400
    //     title: "Gain (dB)"
    //     current_effect: effect
    //     row_param: "gain"
    //     Material.foreground: Constants.poly_blue
    // }
	MoreButton {
        l_effect_type: effect_type
	}

    Component {
        id: ampCaptureSelection

        Item {
            id: ampCaptureSelectionScrollParent

            property string amp_name
            property string amp_brand
            property string amp_model
            property string amp_image
            property string amp_year
            property string description
            property string long_description
            property var tags
            property bool is_favourite
            property var amp_control_names
            property var amp_controls
            property var amp_selected_controls
            property int update_counter

            height:630
            width:1280
            
            Rectangle {
				x: 16
				y: 17
                width: 300
                height: 613
                color: "white"
                radius: 12


                Label {
                    x: 30
                    y: 17
                    height: 30
                    width: 300
                    text: amp_brand.replace(/_/g, " ")
                    wrapMode: Text.Wrap
                    color: Constants.background_color
                    // anchors.centerIn: parent
                    // anchors.bottomMargin: 25 
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font {
                        pixelSize: 24
                        family: mainFont.name
                        weight: Font.DemiBold
                        capitalization: Font.AllUppercase
                    }
                }

                Label {
                    x: 30
                    y: 47
                    height: 30
                    width: 300
                    text: amp_model.replace(/_/g, " ")
                    wrapMode: Text.Wrap
                    color: Constants.background_color
                    // anchors.centerIn: parent
                    // anchors.bottomMargin: 25 
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font {
                        pixelSize: 20
                        family: mainFont.name
                        weight: Font.DemiBold
                        capitalization: Font.AllUppercase
                    }
                }

				ScrollView {
					x: 14
					y: 91
					clip: true
					contentWidth: 280
					contentHeight: 790

					Image {
						x: 0
						y: 0
						source: amp_image
						width: 280
						height: 280

						PolyButton {
							x: 8
							y: 252 
							height: 22
							width: 54
							topPadding: 5
							// leftPadding: -5
							// rightPadding: -5
							radius: 25
							Material.foreground: Constants.background_color
							border_color: Constants.poly_yellow
							background_color: Constants.poly_yellow
							text: amp_year
							font_size: 16
						}
					}
					Label {
						x: 0
						y: 290
						width: 270
						height: 500
						text: long_description 
						wrapMode: Text.Wrap
						elide: Text.ElideRight
						color: Constants.background_color
						font {
							pixelSize: 18
							family: docFont.name
							weight: Font.Normal
						}
					}
				}

				Row {
					x: 14
					y: 570
					spacing: 6
					height: 25
					width: 270
					Repeater {
						model: tags

						PolyButton {
							height: 22
							topPadding: 5
							leftPadding: 15
							rightPadding: 15
							radius: 25
							Material.foreground: Constants.background_color
							border_color: Constants.short_rainbow[index % 4]
                            background_color: Constants.short_rainbow[index % 4]
							text: modelData
							font_size: 16
						}
					}
				}
            }

            Rectangle {
                x: 354
                y: 10
                width: 980
                height: 540
                color: Constants.background_color

                ListView {
                    model: amp_control_names
                    width: parent.width
                    x: 10
                    y: 10
                    height: 540
                    spacing: 22
                    clip: true
                    delegate: Item {
                        property string control_name: modelData //.split(":")[1]
                        width: 800
                        height: control_flow.height + 50
                        // Rectangle {
                        //     width: parent.width
                        //     height: parent.height
                        //     color: Constants.background_color  
                        //     border.width: 2
                        //     border.color: Constants.poly_dark_grey  
                        //     radius: 12
                        // }

                        Item {
                            // width: 362
                            Rectangle {
                                x:0
                                y:0
                                height: control_flow.height + 55
                                width: 800
                                color: Constants.background_color  
                                border.width: 2
                                border.color: Constants.longer_rainbow[index % 9]
                                radius: 10
                                Label {
                                    x: 0
                                    y: 0
                                    height: 42
                                    width: 800
                                    text: control_name.replace(/_/g, " ")
                                    // anchors.top: parent.top
                                    //
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font {
                                        pixelSize: 32
                                        family: mainFont.name
                                        weight: Font.DemiBold
                                        capitalization: Font.AllUppercase
                                    }
                                }
                            }
                            Flow {
                                id: control_flow
                                property int num_this_control: amp_controls[index].length //.split(":")[1]
                                property int parent_index: index //.split(":")[1]
                                x: 20
                                y: 40
                                spacing: 12
                                width: 800
                                Repeater {
                                    model: amp_controls[index]
                                    PolyButton {
                                        height: 60
                                        width: (parent.width / control_flow.num_this_control) - (control_flow.num_this_control * control_flow.spacing)
                                        topPadding: 5
                                        leftPadding: 15
                                        rightPadding: 15
                                        checked: update_counter, amp_selected_controls[control_name] == modelData
                                        // checked: index == Math.floor(currentEffects[effect_id]["controls"]["x_scale"].value)
                                        onClicked: {
                                            amp_selected_controls[control_name] = modelData;
                                            amp_browser_model.set_amp_control(effect, amp_name, control_name, modelData);
                                            update_counter++;
                                        }
                                        Material.foreground: Constants.longer_rainbow[control_flow.parent_index % 9]
                                        border_color: Constants.background_color
                                        background_color: Constants.poly_grey
                                        text: modelData
                                        radius: 10
                                        font_size: 22
                                    }
                                }
                            }

                        }

                    }
                    ScrollIndicator.vertical: ScrollIndicator {
                        anchors.top: parent.top
                        parent: ampCaptureSelectionScrollParent
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.bottom: parent.bottom
                    }
                }
            }
        }
    }
}
// }
