import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.4
import "../qml/polyconst.js" as Constants
import "module_info.js" as ModuleInfo

Item {
    height:540
    width:1280
    id: control
    property string effect_type

        Column {
            x: 50
            y: 20
            width:1280
            spacing: 20
            Text {
                width: 1100
                wrapMode: Text.Wrap
                color: "white"
                font {
                    pixelSize: 24
                    capitalization: Font.AllUppercase
                    family: mainFont.name
                }
				text: ModuleInfo.effectPrototypes[effect_type]["description"] + "\n"  + "manual_url" in ModuleInfo.effectPrototypes[effect_type] ? "" : ModuleInfo.effectPrototypes[effect_type]["long_description"] + " Hold the three dots and press a slider to MIDI bind." 
            }

            Row {
                x: 125
                spacing: 75
                Column {
                    width: 450
                    height: 480
                    visible: "manual_url" in ModuleInfo.effectPrototypes[effect_type]
                    Text {
                        width: parent.width
                        color: "white"
                        font {
                            pixelSize: 34
                            capitalization: Font.AllUppercase
                            family: mainFont.name
                        }
                        text: "Manual:"
                    }
                    Image {
                        // width:27 
                        // height: 27
                        source: "manual_url" in ModuleInfo.effectPrototypes[effect_type] ? "../icons/digit/qr_codes/manual_"+effect_type+".png" : "../icons/digit/loopler/mono-large.png"
                    }
                }
                Column {
                    width: 450
                    height: 480
                    visible: "video_url" in ModuleInfo.effectPrototypes[effect_type]
                    Text {
                        width: parent.width
                        color: "white"
                        font {
                            pixelSize: 34
                            capitalization: Font.AllUppercase
                            family: mainFont.name
                        }
                        text: "Video:"
                    }
                    Image {
                        // width:27 
                        // height: 27
                        source: "video_url" in ModuleInfo.effectPrototypes[effect_type] ? "../icons/digit/qr_codes/video_"+effect_type+".png" : "../icons/digit/loopler/mono-large.png"
                    }
                }
            }
        }
}
