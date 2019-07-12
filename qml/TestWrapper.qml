
import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

ApplicationWindow {

    Material.theme: Material.Dark
    Material.primary: Material.Green
    Material.accent: Material.Pink
    contentOrientation: Qt.LandscapeOrientation

    readonly property int baseFontSize: 20 
    readonly property int tabHeight: 60 
    readonly property int fontSizeExtraSmall: baseFontSize * 0.8
    readonly property int fontSizeMedium: baseFontSize * 1.5
    readonly property int fontSizeLarge: baseFontSize * 2
    readonly property int fontSizeExtraLarge: baseFontSize * 5
    width: 1280
    height: 720
    title: "Drag & drop example"
    visible: true
    LFOControl {
    }
    // // EQWidget {
    
    // }
    // PresetSave {
    // }
    // Settings {
    
    // }
    // EnvelopeFollower {

    // }
    
    // FolderBrowser {
   		// height: 400
    //     width: 300 
    //     top_folder: "file:///c:/git_repos/PolyDigit/UI" 
    //     after_file_selected: (function(name) { 
    //         console.log("in test wrapper call");
    //         console.log("file  is", name.toString());
            
    //     })

    // }
}
