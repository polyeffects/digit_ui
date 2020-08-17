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
import QtQuick.Controls.Material 2.4
import QtQuick.Controls.Material.impl 2.4
import QtQuick.Templates 2.4 as T

T.Switch {
    id: control
    property color accent: Material.foreground

    // implicitWidth: Math.max(background ? background.implicitWidth : 0,
    //                         contentItem.implicitWidth + leftPadding + rightPadding)
    // implicitHeight: Math.max(background ? background.implicitHeight : 0,
    //                          Math.max(contentItem.implicitHeight,
    //                                   indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    implicitWidth: 100
    implicitHeight: 40
    padding: 8
    spacing: 8

    indicator: Item {
        id: indicator
        // width: control.availableWidth
        // height: control.availableHeight
        width: control.width
        height: control.height


        Rectangle {
            width: parent.width
            height: parent.height
            radius: 6
            y: parent.height / 2 - height / 2
            color: control.Material.background
            border { width:2; color: accent}
        }

        Rectangle {
            id: handle
            x: Math.max(0, Math.min(parent.width - width, control.visualPosition * parent.width - (width / 2)))
            y: (parent.height - height) / 2
            width: parent.width / 2
            height: parent.height
            radius: 6
            color: accent // control.checked ? accent : control.Material.switchUncheckedHandleColor

            Behavior on x {
                enabled: !control.pressed
                SmoothedAnimation {
                    duration: 150
                }
            }
        }
    }
    

    contentItem: Item {
        height: parent.height
        width: parent.width
        Text {
            leftPadding: control.leftPadding
            rightPadding: control.rightPadding + control.spacing
            text: control.text
            font: control.font
            color: "white"
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            width: parent.width - 30
            height: parent.height
        }
        Text {
            x: parent.width - 45
            width: 20
            height: parent.height
            rightPadding: control.rightPadding + control.spacing
            text: control.checked ? "ON" : "OFF"
            font: control.font
            color: "white"
            verticalAlignment: Text.AlignVCenter
        }
    }
}
