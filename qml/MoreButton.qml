import "polyconst.js" as Constants
import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

IconButton {
    property string l_effect_type
    property bool module_more: true
    property var alt_module_more: (function(name) { return null; })
    x: 1145 
    y: 635
    width: 120
    height: 70
    icon.width: 55
    icon.height: 55
    icon.source: "../icons/digit/bottom_menu/more.png"
    Material.background: patch_single.more_hold ? Constants.poly_dark_grey: "white" //
    Material.foreground: Constants.background_color //accent_color.name
    onPressed: {
        patch_single.more_hold = true;
    }
    onReleased: {
        patch_single.more_hold = false;
        if (module_more){
            patchStack.push("ModuleMore.qml", {"effect_type": l_effect_type});
        } else {
            alt_module_more(l_effect_type); 
        }
    }
}
