import "controls" as PolyControls
import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.2
import "polyconst.js" as Constants
import QtQuick.Controls.Material 2.3
import QtQuick.VirtualKeyboard 2.1
import ir_browser_module 1.0

// ApplicationWindow {
//     visible: true
//     width: 400
//     height: 480
//     title: qsTr("Hello World")

//     Material.theme: Material.Dark
//     Material.primary: Material.Green
//     Material.accent: Material.Pink


Item {
    id: mainRect
    property string effect
    property string effect_type
    property url current_selected: currentEffects[effect]["controls"]["ir"].name
    property url top_folder: "file:///home/loki/shared/cabs_and_reverbs/reverbs/"
    property string current_reverse: e_update_counter, current_selected, ir_browser_model.external_ir_set(current_selected)
    // property string display_name: remove_suffix(mainRect.basename(mainRect.current_selected))
    // property url top_folder: "file:///home/loki/shared/cabs_and_reverbs/cabs/"
    // property url top_folder: 'file:///audio/reverbs/'
    property var after_file_selected: (function(name) { return null; })
    property bool is_loading: false
    property bool is_cab: false
    property int e_update_counter: 0
    height: 720
    width: 1280

    function basename(ustr)
    {
        // return (String(str).slice(String(str).lastIndexOf("/")+1))
        if (ustr != null)
        {
            var str = ustr.toString()
            return (str.slice(str.lastIndexOf("/")+1))
        }
        return "None Selected"
    }

    function remove_suffix(x)
    {
       return x.replace(/\.[^/.]+$/, "") 
    }

    function format_name(category, prefix, name){
        console.log("prefix is", prefix, "name is", name);
        
        if (prefix.startsWith(category+"-")){
            prefix = prefix.slice((category.length)+1 );
        }
        const regex = new RegExp('.+'+prefix); 
        return name.replace(regex, '').replace(".wav", "").replace(/_/g, " ").replace('/', '');
    }

    function category_colour(category)
    {
        // console.log("category is", category);
        return {"Real Spaces":Constants.poly_pink, "Analog Reverb Devices": Constants.poly_yellow, "Digital Reverb Devices": Constants.poly_blue,  
        "bass":Constants.poly_pink, "guitar": Constants.poly_yellow, "other": Constants.poly_blue, "imported": Constants.poly_purple}[category]
    }

    Rectangle {
        x: 17
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
            id: ir_search
            width: 1180
            height: 70
            font {
                pixelSize: 24
            }
            placeholderText: qsTr("SEARCH")    
            onEditingFinished: {
                ir_browser_model.add_filter(ir_search.text)
            
            }
        }
    }
    InputPanel {
        // id: inputPanel
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
				ir_browser_model.add_filter(ir_search.text)
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
            //     background_color: accent_color.name"
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

                model: IrBrowserModel {
                     id: ir_browser_model
                     Component.onCompleted: {
                         set_knobs(knobs, top_folder.toString().slice(7), is_cab);
                         e_update_counter++;
                     }
                }
                delegate: Item {
                    width: 300
                    height: 400
                    property bool is_selected: current_reverse == ir_name

                
                    Rectangle {
                        width: parent.width
                        height: parent.height
                        color: is_selected ? Constants.poly_green : Constants.background_color  
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
                            source: ir_image.length > 0 ? top_folder+ir_image : top_folder+"placeholder.jpg"
                            width: 280
                            height: 280

                            PolyButton {
                                visible: ir_num_captures > 1
                                x: 8
                                y: 8 
                                height: 22
                                // width: 54
                                topPadding: 5
                                leftPadding: 10
                                rightPadding: 10
                                radius: 25
                                Material.foreground: Constants.background_color
                                border_color: Constants.poly_green
                                background_color: Constants.poly_green
                                text: ir_num_captures + " captures"
                                font_size: 16
                            }

                            PolyButton {
                                x: 8
                                y: 250 
                                height: 22
                                // width: 54
                                topPadding: 5
                                leftPadding: 10
                                rightPadding: 10
                                radius: 25
                                Material.foreground: Constants.background_color
                                border_color: category_colour(ir_category)
                                background_color: category_colour(ir_category)
                                text: ir_category.replace(" Reverb Devices", "")
                                font_size: 16
                                // real space yellow, digital blue, analog green, imported purple
                                //
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
                            y: 297
                            height: 30
                            width: 300
                            text: ir_display_name.replace(/_/g, " ")
                            // wrapMode: Text.Wrap
                            color: is_selected ? Constants.background_color : "white"  
                            elide: Text.ElideRight
                            // anchors.centerIn: parent
                            // anchors.bottomMargin: 25 
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                            font {
                                pixelSize: 26
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
                            text: ir_location.replace(/_/g, " ")
                            elide: Text.ElideRight
                            color: is_selected ? Constants.background_color : "white"  
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

                        Text {
                            x: 10
                            y:ir_location.length > 0 ? 349 : 327
                            // z:1
                            text: description
                            color: is_selected ? Constants.background_color : "white"  
                            // anchors.centerIn: parent
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignTop
                            elide: Text.ElideRight
                            height:ir_location.length > 0 ? 50 : 70
                            wrapMode: Text.WordWrap
                            width: 280
                            lineHeight: 0.9
                            font {
                                pixelSize: 20
                                family: docFont.name
                                weight: Font.Medium
                                // capitalization: Font.AllUppercase
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

                        // Row {
                        //     x: 10
                        //     y: 370
                        //     spacing: 6
                        //     width: 300
                        //     Repeater {
                        //         model: tags

                        //         PolyButton {
                        //             height: 22
                        //             topPadding: 5
                        //             leftPadding: 15
                        //             rightPadding: 15
                        //             radius: 25
                        //             Material.foreground: Constants.background_color
                        //             border_color: Constants.short_rainbow[index % 4]
                        //             background_color: Constants.short_rainbow[index % 4]
                        //             text: modelData
                        //             font_size: 16
                        //         }
                        //     }
                        // }


                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                patchStack.push(irCaptureSelection, {"objectName":"irCaptureSelection", "ir_name":ir_name, 
                                "ir_image": ir_image, "description":description, "is_favourite": is_favourite, "ir_files":ir_files, "ir_num_captures":ir_num_captures, "ir_location":ir_location, "ir_category": ir_category, "ir_display_name":ir_display_name});
                                // ir_browser_model.set_ir_file(effect, ir_name, "", "");
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

    Component {
        id: irCaptureSelection

        Item {
            id: irCaptureSelectionScrollParent

            property string ir_name
            property string ir_image
            property string description
            property bool is_favourite
            property var ir_files
            property int ir_num_captures
            property string ir_category
            property string ir_location
            property string ir_display_name
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
                    x: 14
                    y: 17
                    height: 30
                    width: 295
                    text: ir_display_name.replace(/_/g, " ")
                    wrapMode: Text.Wrap
                    color: Constants.background_color
                    elide: Text.ElideRight
                    // anchors.centerIn: parent
                    // anchors.bottomMargin: 25 
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font {
                        pixelSize: 27
                        family: mainFont.name
                        weight: Font.DemiBold
                        capitalization: Font.AllUppercase
                    }
                }
                Label {
                    x: 14
                    y: 47
                    z:1
                    height: 30
                    width: 295
                    text: ir_location.replace(/_/g, " ")
                    elide: Text.ElideRight
                    color: "black"  
                    // anchors.centerIn: parent
                    // anchors.bottomMargin: 25 
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    font {
                        pixelSize: 24
                        family: docFont.name
                        weight: Font.Medium
                        capitalization: Font.Capitalize
                    }
                }


				ScrollView {
					x: 14
					y: 91
                    height:510
                    width:280
					clip: true
					contentWidth: 280
					contentHeight: 990

					Image {
						x: 0
						y: 0
                        source: ir_image.length > 0 ? top_folder+ir_image : top_folder+"placeholder.jpg"
						width: 280
						height: 280

                        PolyButton {
                            visible: ir_num_captures > 1
                            x: 8
                            y: 8 
                            height: 22
                            // width: 54
                            topPadding: 5
                            leftPadding: 10
                            rightPadding: 10
                            radius: 25
                            Material.foreground: Constants.background_color
                            border_color: Constants.poly_green
                            background_color: Constants.poly_green
                            text: ir_num_captures + " captures"
                            font_size: 16
                        }

                        PolyButton {
                            x: 8
                            y: 250 
                            height: 22
                            // width: 54
                            topPadding: 5
                            leftPadding: 10
                            rightPadding: 10
                            radius: 25
                            Material.foreground: Constants.background_color
                            border_color: category_colour(ir_category)
                            background_color: category_colour(ir_category)
                            text: ir_category.replace(" Reverb Devices", "")
                            font_size: 16
                        }

					}
					Label {
						x: 0
						y: 290
						width: 270
						height: 700
						text: description 
						wrapMode: Text.Wrap
						elide: Text.ElideRight
						color: Constants.background_color
                        lineHeight: 0.9
						font {
							pixelSize: 24
							family: docFont.name
							weight: Font.Normal
						}
					}
				}

            }

            Rectangle {
                x: 354
                y: 10
                width: 720
                height: 540
                color: Constants.background_color
                


                ListView {
                    model: ir_files
                    width: parent.width
                    x: 10
                    y: 10
                    height: 540
                    spacing: 22
                    clip: true
                    delegate: Item {
                        property string control_name: modelData //.split(":")[1]
                        width: 702
                        height: 60
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
                            PolyButton {
                                height: 64
                                width: 702
                                topPadding: 5
                                leftPadding: 15
                                rightPadding: 15
                                checked: update_counter, current_selected == top_folder+modelData
                                onClicked: {
                                    // ir_selected_controls[control_name] = modelData;
                                    ir_browser_model.set_ir_file(effect, modelData);
                                    update_counter++;
                                }
                                Material.foreground: checked ? Constants.poly_green : "white"
                                border_color: Constants.poly_dark_grey
                                background_color: Constants.background_color
                                text:ir_num_captures > 1 || ir_category == "imported" ? format_name(ir_category, ir_name, control_name) : ir_display_name
                                radius: 10
                                font_size: 28
                            }

                        }

                    }
                    ScrollIndicator.vertical: ScrollIndicator {
                        anchors.top: parent.top
                        parent: irCaptureSelectionScrollParent
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.bottom: parent.bottom
                    }
                }
            }

            VerticalSlider {
                x: 1125
                y: 50
                width: 120 
                height: 500
                title: "Gain (dB)"
                current_effect: effect
                row_param: "gain"
                Material.foreground: Constants.poly_green
            }

            MoreButton {
                l_effect_type: effect_type
            }
        }
    }

}
