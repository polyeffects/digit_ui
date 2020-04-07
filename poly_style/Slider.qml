/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the Qt Quick Controls 2 module of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL3$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see http://www.qt.io/terms-conditions. For further
** information use the contact form at http://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPLv3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or later as published by the Free
** Software Foundation and appearing in the file LICENSE.GPL included in
** the packaging of this file. Please review the following information to
** ensure the GNU General Public License version 2.0 requirements will be
** met: http://www.gnu.org/licenses/gpl-2.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.11
import QtQuick.Templates 2.4 as T
import QtQuick.Controls.Material 2.4
import QtQuick.Controls.Material.impl 2.4
import "../qml/polyconst.js" as Constants

T.Slider {
    id: control
    property string title
    property color accent: Material.foreground

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                           (handle ? handle.implicitWidth : 0) + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                            (handle ? handle.implicitHeight : 0) + topPadding + bottomPadding)

    padding: 6

    onPressedChanged: {
        if (pressed){
            title_footer.show_footer_value = true
        }
        else {
            title_footer.show_footer_value = false
        }
    }
    onMoved: {
        title_footer.current_footer_value = value
    }

    handle: Rectangle {
        x: control.leftPadding + (control.horizontal ? control.visualPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : control.visualPosition * (control.availableHeight - height))
        // value: control.value
        // handleHasFocus: control.visualFocus
        // handlePressed: control.pressed
        // handleHovered: control.hovered
        id: handleRect
        width: control.horizontal ? 25 : control.availableWidth - 1
        height: control.horizontal ? control.availableHeight - 1 : 25
        radius: 6 
        color: accent
        scale: control.pressed ? 1.5 : 1


        Behavior on scale {
            NumberAnimation {
                duration: 250
            }
        }

    }

    // handle: Rectangle {
    //     x: control.leftPadding + (control.horizontal ? control.visualPosition * (control.availableWidth - width) : (control.availableWidth - width) / 2)
    //     y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : control.visualPosition * (control.availableHeight - height))
    //     // value: control.value
    //     height: 25
    //     width: 25
    // } 

    background: Rectangle {
        x: control.leftPadding + (control.horizontal ? 0 : (control.availableWidth - width) / 2)
        y: control.topPadding + (control.horizontal ? (control.availableHeight - height) / 2 : 0)
        implicitWidth: control.horizontal ? 420 : 56
        implicitHeight: control.horizontal ? 56 : 420
        // width: control.horizontal ? control.availableWidth : 30
        // height: control.horizontal ? 30 : control.availableHeight
        width: control.availableWidth 
        height: control.availableHeight
        color: control.Material.background
        border { width:2; color: accent}
        scale: control.horizontal && control.mirrored ? -1 : 1
        radius: 6
        
        Text {
            // anchors.centerIn: parent
            x: control.horizontal ? handle.width + padding : (parent.width - width) / 2
            y: control.horizontal ? (parent.height - height) / 2 : parent.height - 40 - (width / 2)
            text: title + "  " + control.value.toFixed(2)
            // height: 15
            color: "white"
            rotation: control.horizontal ? 0 : 270
            font {
                // pixelSize: fontSizeMedium
                pixelSize: 24
                capitalization: Font.AllUppercase
                family: mainFont.name
            }
        }

        // Rectangle {
        //     x: control.horizontal ? 0 : (parent.width - width) / 2
        //     y: control.horizontal ? (parent.height - height) / 2 : control.visualPosition * parent.height
        //     width: control.horizontal ? control.position * parent.width : 3
        //     height: control.horizontal ? 3 : control.position * parent.height

        //     color: control.Material.accentColor
        // }
    }
}
