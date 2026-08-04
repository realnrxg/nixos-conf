import QtQuick

Item {
    id: sl

    property real value: 0
    property bool enabled: true

    signal userChanged(real value)

    implicitHeight: 18

    readonly property real pct: Math.max(0, Math.min(1, sl.value))

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        radius: 1.5
        color: "#262626"

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * sl.pct
            height: parent.height
            radius: parent.radius
            color: "#e8e8e8"
        }
    }

    Rectangle {
        id: sliderKnob

        width: 12
        height: 12
        radius: 6
        color: "#e8e8e8"
        visible: sl.enabled
        x: parent.width * sl.pct - width / 2
        y: parent.height / 2 - height / 2
    }

    MouseArea {
        anchors.fill: parent
        enabled: sl.enabled
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => sl.setFromMouse(mouse.x)
        onPositionChanged: mouse => sl.setFromMouse(mouse.x)
        onWheel: wheel => {
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            sl.userChanged(Math.max(0, Math.min(1, sl.value + step)));
        }
    }

    function setFromMouse(mx) {
        const v = Math.max(0, Math.min(1, mx / width));
        sl.userChanged(v);
    }
}
