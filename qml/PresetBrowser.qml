import QtQuick 2.9
import QtQuick.Controls 2.3
// import QtQuick.Window 2.2
import Qt.labs.folderlistmodel 2.2
import QtQuick.Controls.Material 2.3


    Item {
        id: mainRect
        property string effect
        property url current_selected: currentEffects[effect]["controls"]["ir"].name
        property string display_name: remove_suffix(mainRect.basename(mainRect.current_selected))
        property url top_folder: "file:///audio/reverbs/"
        property var after_file_selected: (function(name) { return null; })
        property bool is_loading: false
        property bool swipeable: false
        property bool only_favourite: false
        property bool only_mine: false
        height: 546
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

        function is_favourite(f)
        {
            var t_f = f.slice(7)
            return (t_f in presetMeta && "favourite" in presetMeta[t_f] && presetMeta[t_f]["favourite"])
        }

        function preset_filter(f)
        {
            var t_f = f.slice(7)
            if (only_favourite && !is_favourite(f)){
                return false;
            }
            else if (only_mine && t_f in presetMeta && "author" in presetMeta[t_f] && presetMeta[t_f]["author"] != pedalState["author"]){
                return false;
            }
            return true;
        }

        function get_preset_description(f){
            var t_f = f.slice(7)
            // console.log("get_preset_description", t_f)
            if (t_f in presetMeta && "description" in presetMeta[t_f]){
                // console.log("found get_preset_description", '<br>'+presetMeta[t_f]["description"])
                return '<br>'+presetMeta[t_f]["description"]
            } else {
                return ""
            }
        
        }

        function get_preset_author(f){
            var t_f = f.slice(7)
            if (t_f in presetMeta && "author" in presetMeta[t_f]){
                return '<font color="'+accent_color.name+'"> by '+presetMeta[t_f]["author"]+'</font>'
            } else {
                return ""
            }
        }

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
        
        Grid {
            y: 0
            x: 60
            width: 345
            height: parent.height
            spacing: 20
            // columns: 2

            Button {
                checked: mainRect.only_favourite
                height: 80
                font {
                    pixelSize: 24
                }
                text: "FAVOURITE"
                // width: 300
                onClicked: { // save preset and close browser
                    mainRect.only_favourite = !mainRect.only_favourite;
                }
            }
            
            Button {
                checked: mainRect.only_mine
                height: 80
                font {
                    pixelSize: 24
                }
                text: "MINE"
                // width: 300
                onClicked: { // save preset and close browser
                    mainRect.only_mine = !mainRect.only_mine;
                }
            }

            // Repeater {
            //     model: Object.keys(currentEffects[effect_id]["controls"])
            //     DelayRow {
            //         row_param: modelData
            //         current_effect: effect_id
            //         Material.foreground: Constants.rainbow[index]
            //         is_log: modelData == "cutoff"
            //     }
            // }
        }
        
        Item {
            x: 405
            y: 0
            width: 875
            height: parent.height

            Button {
                anchors.right: parent.right
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
                highlightRangeMode: ListView.StrictlyEnforceRange 
                y: 0
                width: parent.width
                height: parent.height 
                preferredHighlightBegin : 0
                preferredHighlightEnd : 50 
                highlightFollowsCurrentItem: true
                clip: true
                snapMode: ListView.SnapToItem
                maximumFlickVelocity: 10000
                visible: !(is_loading)
                model: FolderListModel {
                    id: folderListModel
                    showDirsFirst: true
                    folder: top_folder
                    //                nameFilters: ["*.mp3", "*.flac"]
                }

                Component.onCompleted: {
                    // console.log("oncomplete presetbrowser component", presetBrowserIndex);
                    // fileList.positionViewAtIndex(presetBrowserIndex, ListView.SnapPosition);
                    // fileList.positionViewAtEnd()
                    // fileList.currentIndex = presetBrowserIndex;
                    // console.log("oncomplete presetbrowser component currentIndex", fileList.currentIndex);
                } 

                delegate: SwipeDelegate {
                    id: swipeDelegate
                    width: parent.width
                    swipe.enabled: mainRect.swipeable
                    visible: preset_filter(fileURL.toString())
                    enabled : visible
                    height: visible ? 95 : 0

                    text: "<b>"+remove_suffix(fileName).replace(/_/g, " ")+ '</b> '+ get_preset_author(fileURL.toString()) + get_preset_description(fileURL.toString())
                    font {
                        bold: fileIsDir && !fileURL.toString().endsWith(".ingen") ? true : false
                        pixelSize: 24
                        family: mainFont.name
                        capitalization: Font.AllUppercase
                    }
                    icon.name: fileIsDir && !fileURL.toString().endsWith(".ingen") ? "md-folder-open" : false // or md-folder
                    onClicked: {
                        if (fileIsDir) {
                            if (fileURL.toString().endsWith(".ingen")){
                                mainRect.current_selected = fileURL
                                presetBrowserIndex = index;
                                mainRect.after_file_selected(fileURL)
                            } else {
                                folderListModel.folder = fileURL
                            }
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

                    swipe.left: IconButton {
                        icon.source: "../icons/digit/favourite.png"
                        width: 100
                        height: 90
                        icon.width: 60
                        checked: is_favourite(fileURL.toString());
                        onClicked: {
                            knobs.toggle_favourite(fileURL.toString());
                        }
                        Material.foreground: "pink"
                        Material.accent: "white"
                        radius: 10
                        // Label {
                        // 	visible: title_footer.show_help 
                        // 	x: 0
                        // 	y: 20 
                        // 	text: favourite
                        // 	horizontalAlignment: Text.AlignHCenter
                        // 	width: 114
                        // 	height: 22
                        // 	z: 1
                        // 	color: "white"
                        // 	font {
                        // 		pixelSize: 18
                        // 		capitalization: Font.AllUppercase
                        // 	}
                        // }
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
                                console.log("delete clicked");
                                knobs.delete_preset(fileURL.toString());
                            }
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

        Component.onDestruction: {
            // console.log("destroying presetbrowser component", fileList.currentIndex);
            presetBrowserIndex = fileList.currentIndex;
        }

    }
// }
