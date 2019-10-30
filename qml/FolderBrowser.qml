import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.2
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
        property url current_selected: "file:///none.wav"
        property string display_name: remove_suffix(mainRect.basename(mainRect.current_selected))
        property url top_folder: "file:///audio/reverbs/"
        property var after_file_selected: (function(name) { return null; })
        property bool is_loading: false

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

        width: parent.width
        height: parent.height
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
            anchors.right: mainRect.right
            anchors.rightMargin: 0
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

            delegate: ItemDelegate {
                width: parent.width
                height: 60
                text: remove_suffix(fileName)
                font.bold: fileIsDir ? true : false
                font.pixelSize: fontSizeMedium
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
// }
