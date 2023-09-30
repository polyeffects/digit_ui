import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import "../qml/polyconst.js" as Constants
import "module_info.js" as ModuleInfo

Item {
    height:720
    width:1280
    id: control
	property string selected_effect: knobs.spotlight_entries.length == 0 ? ""  : knobs.spotlight_entries[0][0]
	property string selected_param: knobs.spotlight_entries.length == 0 ? ""  : knobs.spotlight_entries[0][1]
	property string num_param: knobs.spotlight_entries.length

    function rsplit(str, sep, maxsplit) {
        var split = str.split(sep);
        return maxsplit ? [ split.slice(0, -maxsplit).join(sep) ].concat(split.slice(-maxsplit)) : split;
    }

    Component.onCompleted: {

        if (knobs.spotlight_entries.length > 0){
            control.selected_effect = knobs.spotlight_entries[0][0]
            control.selected_param = knobs.spotlight_entries[0][1]
            slider.Material.foreground = Constants.rainbow[0]
            knobs.set_knob_current_effect(knobs.spotlight_entries[0][0], knobs.spotlight_entries[0][1]);
        }

    }

    // Rectangle {
    //     color: accent_color.name
    //     x: 0
    //     y: 0
    //     width: 1280
    //     height: 100
    
    //     Image {
    //         x: 10
    //         y: 9
    //         source: currentPedalModel.name == "beebo" ? "../icons/digit/Beebo.png" : "../icons/digit/Hector.png" 
    //     }

    //     Label {
    //         // color: "#ffffff"
    //         text: "Spotlight"
    //         elide: Text.ElideRight
    //         anchors.centerIn: parent
    //         anchors.bottomMargin: 25 
    //         horizontalAlignment: Text.AlignHCenter
    //         width: 1000
    //         height: 60
    //         z: 1
    //         color: Constants.background_color
    //         font {
    //             pixelSize: 36
    //             capitalization: Font.AllUppercase
    //         }
    //     }
    // }
    Row {
        x: 29
        y: 11
        spacing: 32 

        PolyButton {
            width: 220
            height: 80
            Material.foreground: Constants.poly_orange
            border_color: Constants.poly_orange
            background_color: Constants.background_color
            text: "left knob"
            font_size: 30
            onClicked: knobs.toggle_spotlight_binding(control.selected_effect, control.selected_param, "l")
        }
        PolyButton {
            width: 160
            height: 80
            Material.foreground: Constants.poly_yellow
            border_color: Constants.poly_yellow
            background_color: Constants.background_color
            text: "x assign"
            font_size: 30
            onClicked: knobs.toggle_spotlight_binding(control.selected_effect, control.selected_param, "x")
        }
        PolyButton {
            width: 335
            height: 80
            Material.foreground: "white"
            border_color: "white"
            background_color: Constants.background_color
            text: "xy view"
            font_size: 30
            onClicked: {
                patchStack.push("XYPad.qml" );
            }
        }
        PolyButton {
            width: 160
            height: 80
            Material.foreground: Constants.poly_green
            border_color: Constants.poly_green
            background_color: Constants.background_color
            text: "y assign"
            font_size: 30
            onClicked: knobs.toggle_spotlight_binding(control.selected_effect, control.selected_param, "y")
        }
        PolyButton {
            width: 220
            height: 80
            Material.foreground: Constants.poly_purple
            border_color: Constants.poly_purple
            background_color: Constants.background_color
            text: "right knob"
            font_size: 30
            onClicked: knobs.toggle_spotlight_binding(control.selected_effect, control.selected_param, "r")
        }

    }

	Column {
		x: 29
		y: 124
		spacing: 30
        visible: num_param > 0

       

		Row {
			spacing: 32 
			height: 180
			width: 1180

			Repeater {
                id: top_rep
                model: knobs.spotlight_entries.length > 1 ? knobs.spotlight_entries.slice(0, num_param / 2) : knobs.spotlight_entries

				ValueButton {
					width: (1180 / top_rep.count) - ((top_rep.count-1) * 16)
					height: 180
					// checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
					checked: control.selected_param == modelData[1] && control.selected_effect == modelData[0]
					onClicked: {
						 control.selected_effect = modelData[0]
						 control.selected_param = modelData[1]
						 slider.Material.foreground = Constants.rainbow[index]
						 // slider.force_update = !(slider.force_update)
					}
                    onPressedChanged: {
                        if (pressed){
                            knobs.set_knob_current_effect(modelData[0], modelData[1]);
                            if (patch_single.more_hold){
                                patch_single.more_hold = false;
                                patchStack.push("More.qml", {"current_effect": modelData[0], "row_param": modelData[1]});
                            }
                        }
                    }
					Material.foreground: Constants.rainbow[index]
					text: rsplit(modelData[0], "/", 1)[1].replace(/_/g, " ").replace(/1$/, '') + "\n" + currentEffects[modelData[0]]["controls"][modelData[1]].name
					value: currentEffects[modelData[0]]["controls"][modelData[1]].value.toFixed(2)

                    PolyButton {
                        visible: modelData[2].indexOf("l") >= 0
                        x: -10
                        y: -10 
                        height: 32
                        width: 32
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: Constants.background_color
                        border_color: Constants.poly_orange
                        background_color: Constants.poly_orange
                        text: "L"
                        font_size: 28
                    }

                    PolyButton {
                        visible: modelData[2].indexOf("x") >= 0
                        x: 42
                        y: -10 
                        height: 32
                        width: 32
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: Constants.background_color
                        border_color: Constants.poly_yellow
                        background_color: Constants.poly_yellow
                        text: "X"
                        font_size: 28
                    }

                    PolyButton {
                        visible: modelData[2].indexOf("y") >= 0
                        x: parent.width - 72
                        y: -10 
                        height: 32
                        width: 32
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: Constants.background_color
                        border_color: Constants.poly_green
                        background_color: Constants.poly_green
                        text: "Y"
                        font_size: 28
                    }

                    PolyButton {
                        visible: modelData[2].indexOf("r") >= 0
                        x: parent.width - 22
                        y: -10 
                        height: 32
                        width: 32
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: Constants.background_color
                        border_color: Constants.poly_purple
                        background_color: Constants.poly_purple
                        text: "R"
                        font_size: 28
                    }
				}
			}
        }
        DelayRow {
            id: slider
            visible: selected_param != ""
            row_param: selected_param
            current_effect: selected_effect
            Material.foreground: Constants.rainbow[0]
            v_type: ModuleInfo.effectPrototypes[selected_effect]["controls"][selected_param].length > 4 ? ModuleInfo.effectPrototypes[selected_effect]["controls"][selected_param][4] : "float"
            width: 1180
        }

		Row {
			spacing: 32 
			height: 180
			width: 1180

			Repeater {
                id: bottom_rep
                model: num_param > 1 ? knobs.spotlight_entries.slice(num_param / 2) : []

				ValueButton {
					width: (1180 / bottom_rep.count) - ((bottom_rep.count-1) * 16)
					height: 180
					// checked: currentEffects[effect_id]["controls"]["t_deja_vu_param"].value == 1.0
					checked: control.selected_param == modelData[1] && control.selected_effect == modelData[0]
					onClicked: {
						 control.selected_effect = modelData[0]
						 control.selected_param = modelData[1]
						 slider.Material.foreground = Constants.rainbow[top_rep.count+index]
						 // slider.force_update = !(slider.force_update)
					}
                    onPressedChanged: {
                        if (pressed){
                            knobs.set_knob_current_effect(modelData[0], modelData[1]);
                            if (patch_single.more_hold){
                                patch_single.more_hold = false;
                                patchStack.push("More.qml", {"current_effect": modelData[0], "row_param": modelData[1]});
                            }
                        }
                    }
					Material.foreground: Constants.rainbow[top_rep.count+index]
					text: rsplit(modelData[0], "/", 1)[1].replace(/_/g, " ").replace(/1$/, '') + "\n" + currentEffects[modelData[0]]["controls"][modelData[1]].name
					value: currentEffects[modelData[0]]["controls"][modelData[1]].value.toFixed(2)

                    PolyButton {
                        visible: modelData[2].indexOf("l") >= 0
                        x: -10
                        y: -10 
                        height: 32
                        width: 32
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: Constants.background_color
                        border_color: Constants.poly_orange
                        background_color: Constants.poly_orange
                        text: "L"
                        font_size: 28
                    }

                    PolyButton {
                        visible: modelData[2].indexOf("x") >= 0
                        x: 42
                        y: -10 
                        height: 32
                        width: 32
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: Constants.background_color
                        border_color: Constants.poly_yellow
                        background_color: Constants.poly_yellow
                        text: "X"
                        font_size: 28
                    }

                    PolyButton {
                        visible: modelData[2].indexOf("y") >= 0
                        x: parent.width - 72
                        y: -10 
                        height: 32
                        width: 32
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: Constants.background_color
                        border_color: Constants.poly_green
                        background_color: Constants.poly_green
                        text: "Y"
                        font_size: 28
                    }

                    PolyButton {
                        visible: modelData[2].indexOf("r") >= 0
                        x: parent.width - 22
                        y: -10 
                        height: 32
                        width: 32
                        // topPadding: 5
                        // leftPadding: 10
                        // rightPadding: 10
                        // radius: 25
                        Material.foreground: Constants.background_color
                        border_color: Constants.poly_purple
                        background_color: Constants.poly_purple
                        text: "R"
                        font_size: 28
                    }
				}
			}
        }
	}

    Text {
        x: 50
        y: 140
        visible: knobs.spotlight_entries.length == 0
        anchors.horizontalCenter: parent.horizontalCenter
        height: 300
        width: 800
        text: "Parameters you spotlight will appear here." 
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        color: "white"
        font {
            pixelSize: 24
            capitalization: Font.AllUppercase
            family: mainFont.name
        }
    }

    MoreButton {
        l_effect_type: "no_effect"
        module_more: false
        alt_module_more: (function(l_effect_type) { 
            patchStack.push("SpotlightDetail.qml");
        })
    }

    // IconButton {

    //     x: 34 
    //     y: 650
    //     icon.width: 15
    //     icon.height: 25
    //     width: 119
    //     height: 62
    //     text: "BACK"
    //     font {
    //         pixelSize: 24
    //     }
    //     flat: false
    //     icon.name: "back"
    //     Material.background: Constants.background_color
    //     Material.foreground: "white" // Constants.outline_color
    //     onClicked: patchStack.pop()
    // }
}

