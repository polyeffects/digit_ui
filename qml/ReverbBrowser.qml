import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.2
import "polyconst.js" as Constants
// import QtQuick.Controls.Material 2.3

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
    property url current_selected: currentEffects[effect]["controls"]["ir"].name
    property string display_name: remove_suffix(mainRect.basename(mainRect.current_selected))
    property url top_folder: "file:///audio/reverbs/"
    property var after_file_selected: (function(name) { return null; })
    property bool is_loading: false
    height: 500
    width: 1000

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

    ActionIcons {

    }

    Label {
        x: Constants.left_col + 15
        y: 15
        text: display_name
        height: 45
        // height: 15
        color: accent_color.name
        font {
            pixelSize: fontSizeMedium*1.1
            // pixelSize: 11
            capitalization: Font.AllUppercase
        }
    }

    Item {
        id: folderRect
        x: Constants.left_col + 10
        y: 60
        height: 450
        width: 850


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

        Button {
            anchors.right: folderRect.right
            anchors.rightMargin: -100
            font {
                pixelSize: fontSizeMedium
            }
            flat: true
            text: "UP"
            visible: folderListModel.folder != top_folder
            onClicked: {
                folderListModel.folder = folderListModel.parentFolder
                // console.log(folderListModel.folder, top_folder);
            } 
            height: 60
            z: 2
        }
        Rectangle {
            width: parent.width
            height: 1
            color: "#1E000088"
            anchors.bottom: fileList.top
        }
        ListView {
            id: fileList
            y: 0
            width: parent.width
            height: parent.height 
            clip: true
            visible: !(is_loading)
            model: FolderListModel {
                id: folderListModel
                showDirsFirst: true
                folder: top_folder
//                nameFilters: ["*.mp3", "*.flac"]
            }

            delegate: SwipeDelegate {
                id: swipeDelegate
                width: parent.width
                height: 60
                text: remove_suffix(fileName)
                font.bold: fileIsDir ? true : false
                font.pixelSize: fontSizeMedium
                highlighted: fileURL == mainRect.current_selected
                icon.name: fileIsDir ? "md-folder-open" : false // or md-folder
                onClicked: {
                    if (fileIsDir) {
                        folderListModel.folder = fileURL
                    }
                    else
                    {
                        // console.log(mainRect.basename(fileURL.toString()))
                        mainRect.current_selected = fileURL
                        mainRect.after_file_selected(fileURL)
                    }
                }
                // background: Rectangle {
                    // color: fileIsDir ? "orange" : "gray"
                    // border.color: "black"
                // }
                //
                ListView.onRemove: SequentialAnimation {
                    PropertyAction {
                        target: swipeDelegate
                        property: "ListView.delayRemove"
                        value: true
                    }
                    NumberAnimation {
                        target: swipeDelegate
                        property: "height"
                        to: 0
                        easing.type: Easing.InOutQuad
                    }
                    PropertyAction {
                        target: swipeDelegate
                        property: "ListView.delayRemove"
                        value: false
                    }
                }

                swipe.right: Label {
                    id: deleteLabel
                    text: qsTr("Delete")
                    color: "white"
                    verticalAlignment: Label.AlignVCenter
                    padding: 30
                    height: parent.height
                    anchors.right: parent.right


                    background: Rectangle {
                        color: deleteLabel.SwipeDelegate.pressed ? Qt.darker("tomato", 1.1) : "tomato"
                    }
                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: { 
                            knobs.delete_ir(fileURL.toString());
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


    Slider {
        x: 1100
        y: 50
        width: 60 
        height: 450
        orientation: Qt.Vertical
        title: "Gain (dB)"
        value: currentEffects[effect]["controls"]["gain"].value
        from: currentEffects[effect]["controls"]["gain"].rmin
        to: currentEffects[effect]["controls"]["gain"].rmax
        onMoved: {
            knobs.ui_knob_change(effect, "gain", value);
        }
        onPressedChanged: {
            if (pressed){
                knobs.set_knob_current_effect(effect, "gain");
            }
        }

    }
}
// }
