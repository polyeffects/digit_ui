
import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

import "polyconst.js" as Constants

ApplicationWindow {

    Material.theme: Material.Dark
    Material.primary: Constants.cv_color
    Material.accent: accent_color.name
    Material.background: "black"
    // Material.buttonColor: "grey"
    // contentOrientation: Qt.LandscapeOrientation
    contentOrientation: Qt.InvertedLandscapeOrientation
    
    property bool onDevice: false // Qt.platform.os == "linux" 
    readonly property int baseFontSize: 20 
    readonly property int tabHeight: 60 
    readonly property int fontSizeExtraSmall: baseFontSize * 0.8
    readonly property int fontSizeMedium: baseFontSize * 1.5
    readonly property int fontSizeLarge: baseFontSize * 2
    readonly property int fontSizeExtraLarge: baseFontSize * 5
    property int presetBrowserIndex: 0
    width: onDevice ? 720 : 1280 
    height: onDevice ? 1280 : 720
    title: "Digit 2"
    visible: true
    // FontLoad0er { source: "ionicons.ttf" }
    //00
    // FontLoader { id: mainFont; source: "fonts/Dosis-VF.ttf" }
    // FontLoader { id: mainFont; source: "fonts/SourceSerifPro-Semibold.ttf" }
    FontLoader { id: docFont; source: "fonts/BarlowSemiCondensed-Medium.ttf" }
    FontLoader { id: mainFont; source: "fonts/BarlowSemiCondensed-SemiBold.ttf" }
    // FontLoader { id: docFont; name: "Open Sans" }
    font.family: mainFont.name
    font.weight: Font.DemiBold
    Component {
        id: mainView
        // PatchBay {
        // }
        // TitleFooter {
        // }

        // Item {
        //     width: 1280
        //     height: 720
        
        // Slider {
        //     x: 50
        //     y: 50
        //     width: 625
        //     height: 48
        //     value: 0.5
        //     from: 0
        //     to: 1
        //     title: "Fragment Length"
        // }

        // Slider {
        //     x: 100
        //     y: 300
        //     value: 0.5
        //     from: 0
        //     to: 1
        //     title: "Fragment"
        //     orientation: Qt.Vertical
        //     width: 50 
        //     height: 300
        // }

        // Slider {
        //     x: 200
        //     y: 300
        //     value: 0.5
        //     from: 0
        //     to: 1
        //     title: "Gain"
        //     orientation: Qt.Vertical
        //     width: 75 
        //     height: 300
        // }

        // Slider {
        //     x: 300
        //     y: 300
        //     value: 0.5
        //     from: 0
        //     to: 1
        //     title: "Gain"
        //     orientation: Qt.Vertical
        //     width: 75 
        //     height: 200
        // }
        // // Switch {
        // //     x: 50
        // //     y: 50
        // //     text: qsTr("BAND 5")
        // //     font.pixelSize: baseFontSize
        // //     bottomPadding: 0
        // //     // height: 20
        // //     // implicitWidth: 100
        // //     width: 175
        // //     height: 30
        // //     leftPadding: 0
        // //     topPadding: 0
        // //     rightPadding: 0
        // // }

        // SpinBox {
        //     x: 100
        //     y: 100
        //     height: 50
        //     value: 10
        //     from: 1
        //     to:  100
        //     stepSize: 10
        // }
    // }
        // NoteSequencer {
        
        // }
        // Tuner {

        // }

		// Strum {
		
		// }
        //
        // StackView {
        //     id: patchStack
        //     initialItem: 
        //     AmpBrowser {

        //     }
        // }
        
        // Loopler {
        
        // }
        ModuleBrowser {
        
        }
        // EuclideanSequencer {
        
        // }
        // More {
        
        // }
    }
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
    //
    Item {
        transform: Rotation {
            angle: onDevice ? -90 : 0
            // origin.y: 720 / 2
            origin.x: 1280 / 2
            origin.y: 1280 / 2
        } 
        width: 1280//Screen.height
        height: 720//Screen.wid
        StackView {
            id: mainStack
            initialItem: mainView
        }
    }
}
