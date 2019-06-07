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
        property url current_selected: "file:///none.wav"

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

        id: mainRect
        width: parent.width
        height: parent.height
        GlowingLabel {
            anchors.left: mainRect.left
            anchors.leftMargin: 5
            text: remove_suffix(mainRect.basename(mainRect.current_selected))
            height: 60
            width: 250
            font {
                pixelSize: fontSizeLarge
            }
            elide: Text.ElideRight
        }

        Button {
            anchors.right: mainRect.right
            anchors.rightMargin: 5
            text: "UP"
            onClicked: folderListModel.folder = folderListModel.parentFolder
            height: 60
        }
        Rectangle {
            width: parent.width
            height: 1
            color: "#1E000088"
            anchors.bottom: fileList.top
        }
        ListView {
            id: fileList
            y: 60
            width: parent.width
            height: parent.height - 60
            clip: true
            model: FolderListModel {
                id: folderListModel
                showDirsFirst: true
//                nameFilters: ["*.mp3", "*.flac"]
            }

            delegate: ItemDelegate {
                width: parent.width
                height: 60
                text: remove_suffix(fileName)
                font.bold: fileIsDir ? true : false
                font.pixelSize: fontSizeMedium
                icon.name: fileIsDir ? "windows" : false // XXX replace with folder icon
                onClicked: {
                    if (fileIsDir) {
                        folderListModel.folder = fileURL
                    }
                    else
                    {
                        console.log(mainRect.basename(fileURL.toString()))
                        mainRect.current_selected = fileURL
                    }
                }
                // background: Rectangle {
                    // color: fileIsDir ? "orange" : "gray"
                    // border.color: "black"
                // }
            }
        }
    }
// }
