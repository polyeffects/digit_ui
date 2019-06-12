
import QtQuick 2.4
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

ApplicationWindow {

    Material.theme: Material.Dark
    Material.primary: Material.Green
    Material.accent: Material.Pink

    readonly property int baseFontSize: 20 
    readonly property int tabHeight: 60 
    readonly property int fontSizeExtraSmall: baseFontSize * 0.8
    readonly property int fontSizeMedium: baseFontSize * 1.5
    readonly property int fontSizeLarge: baseFontSize * 2
    readonly property int fontSizeExtraLarge: baseFontSize * 5
    width: 1280
    height: 580
    title: "Drag & drop example"
    visible: true
    // LFOControl {
    // // EQWidget {
    
    // }
    PresetSave {
    }
}
