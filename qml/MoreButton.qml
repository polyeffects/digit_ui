import "polyconst.js" as Constants
import QtQuick 2.4
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.3

IconButton {
    property string l_effect_type
    x: 584 
    y: 550
    width: 76
    height: 76
    icon.width: 70
    icon.height: 70
    icon.source: "../icons/digit/bottom_menu/more.png"
    Material.background: patch_single.more_hold ? Constants.poly_dark_grey: Constants.background_color
    Material.foreground: accent_color.name
    onPressed: {
        patch_single.more_hold = true;
    }
    onReleased: {
        patch_single.more_hold = false;
        patchStack.push("ModuleMore.qml", {"effect_type": l_effect_type});
    }
}
