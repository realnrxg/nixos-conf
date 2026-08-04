import QtQuick



Item {
    id: root

    property int workspace: 1
    property bool active: false
    property color textColor: "#e8e8e8"
    property color backgroundColor: "#000000"
    property color borderColor: "#1a1a1a"
    readonly property bool showing: active

    width: chip.width
    height: chip.height
    opacity: showing ? 1 : 0
    visible: opacity > 0
    scale: showing ? 1 : 0.7

    Rectangle {
        id: chip

        width: 22
        height: 22
        radius: height / 2
        color: chipMouse.containsMouse ? "#0f0f0f" : root.backgroundColor
        border.width: 1
        border.color: root.borderColor

        Text {
            anchors.centerIn: parent
            text: root.workspace
            color: root.textColor
            font.family: "Maple Mono NF"
            font.pixelSize: 12
            font.weight: Font.Bold
        }

        MouseArea {
            id: chipMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }


    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutBack
            easing.overshoot: 0.3
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutBack
            easing.overshoot: 0.3
        }
    }
}
