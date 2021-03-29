import QtQuick 2.11
// import QtQuick.Templates 2.4 as T
import QtQuick.Controls 2.4
// import QtQuick.Controls.Material 2.4
// import QtQuick.Controls.Material.impl 2.4
import "../qml/polyconst.js" as Constants
//
// import QtQuick.Shapes 1.11
SpinBox {
    from: 0
    to: items.length - 1
    value: 1 // "Medium"

    property var items: ["off", "cycle", "8th", "loop"]

    validator: RegExpValidator {
        //regExp: new RegExp("(Small|Medium|Large)", "i")
        regExp: new RegExp("("+items.join("|")+")", "i")
    }

    textFromValue: function(value) {
        return items[value];
    }

    valueFromText: function(text) {
        for (var i = 0; i < items.length; ++i) {
            if (items[i].toLowerCase().indexOf(text.toLowerCase()) === 0)
                return i
        }
        return sb.value
    }
}
