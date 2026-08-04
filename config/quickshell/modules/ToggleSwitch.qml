import QtQuick

Item {
    id: togg

    property bool checked: false
    property bool enabled: true

    signal toggled(bool value)

    width: 34
    height: 20

    Rectangle {
        anchors.fill: parent
        radius: parent.height / 2
        color: togg.checked ? "#f2f2f2" : "#2a2a2a"
        opacity: togg.enabled ? 1 : 0.4

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    Rectangle {
        id: knob

        x: togg.checked ? parent.width - width - 2 : 2
        y: 2
        width: parent.height - 4
        height: width
        radius: width / 2
        color: "#0a0a0a"

        Behavior on x {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: togg.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: togg.toggled(!togg.checked)
    }
}
