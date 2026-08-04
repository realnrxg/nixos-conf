import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property string fontFamily
    required property var store

    signal closeRequested()

    readonly property real padding: 10
    readonly property real headerHeight: 16
    readonly property real cardSpacing: 5

    function relativeTime(timestamp) {
        const diff = Math.floor((Date.now() - timestamp) / 1000);

        if (diff < 10)
            return "now";

        if (diff < 60)
            return diff + "s";

        if (diff < 3600)
            return Math.floor(diff / 60) + "m";

        if (diff < 86400)
            return Math.floor(diff / 3600) + "h";

        return Math.floor(diff / 86400) + "d";
    }

    function indexOfKey(key) {
        for (let i = 0; i < root.store.historyModel.count; i++) {
            if (root.store.historyModel.get(i).key === key)
                return i;
        }

        return -1;
    }

    function scrollList(delta) {
        if (root.store.count === 0)
            return false;

        const maxY = Math.max(0, list.contentHeight - list.height);

        if (delta > 0) {
            if (list.contentY <= 0)
                return false;

            list.contentY = Math.max(0, list.contentY - 60);
        } else {
            if (list.contentY >= maxY)
                return false;

            list.contentY = Math.min(maxY, list.contentY + 60);
        }

        return true;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                color: "#9a9a9a"
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: String(root.store.count)
                color: "#6d6d6d"
                font.family: root.fontFamily
                font.pixelSize: 11
            }

            Text {
                visible: root.store.count > 0
                text: "  Clear"
                color: clearMouse.containsMouse ? "#ffffff" : "#7f7f7f"
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.store.clearAll()
                }
            }
        }

        Item {
            visible: root.store.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 6

                MIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "notifications_none"
                    size: 22
                    color: "#4d4d4d"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No notifications"
                    color: "#6d6d6d"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                }
            }
        }

        ListView {
            id: list

            visible: root.store.count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 6
            clip: true
            spacing: root.cardSpacing
            boundsBehavior: Flickable.StopAtBounds
            model: root.store.historyModel

            add: Transition {
                NumberAnimation {
                    properties: "opacity, y"
                    from: 0
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            addDisplaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            remove: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        properties: "opacity"
                        to: 0
                        duration: 130
                        easing.type: Easing.InCubic
                    }

                    NumberAnimation {
                        properties: "height"
                        to: 0
                        duration: 160
                        easing.type: Easing.InCubic
                    }
                }
            }

            removeDisplaced: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 4

                contentItem: Rectangle {
                    color: "#3a3a3a"
                    radius: 2
                }
                background: Rectangle {
                    color: "transparent"
                }
            }

            delegate: Component {
                Item {
                    id: card

                    required property string key
                    required property string appName
                    required property string appIcon
                    required property string summary
                    required property string body
                    required property string image
                    required property bool critical
                    required property double time

                    width: ListView.view.width
                    implicitHeight: Math.max(card.body !== "" ? 50 : 42, iconBox.height + 14)

                    Rectangle {
                        anchors.fill: parent
                        radius: 9
                        color: cardMouse.containsMouse ? "#141414" : "#0b0b0b"
                        border.width: 1
                        border.color: card.critical ? "#4a3c10" : (cardMouse.containsMouse ? "#262626" : "#181818")

                        Behavior on color {
                            ColorAnimation {
                                duration: 80
                            }
                        }
                    }

                    Item {
                        id: iconBox

                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30

                        Rectangle {
                            anchors.fill: parent
                            radius: 7
                            color: "#161616"
                            border.width: 1
                            border.color: "#232323"
                        }

                        IconImage {
                            id: iconImg

                            anchors.fill: parent
                            anchors.margins: 4
                            asynchronous: true
                            source: card.appIcon !== "" ? Quickshell.iconPath(card.appIcon, true) : ""
                            visible: source !== ""
                        }

                        MIcon {
                            anchors.centerIn: parent
                            name: card.critical ? "error" : "notifications"
                            size: 15
                            color: card.critical ? "#f0c040" : "#6d6d6d"
                            visible: !iconImg.visible
                        }
                    }

                    ColumnLayout {
                        anchors.left: iconBox.right
                        anchors.right: dismissBox.left
                        anchors.leftMargin: 9
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: card.appName !== "" ? card.appName : "Notification"
                                color: "#8a8a8a"
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.relativeTime(card.time)
                                color: "#555555"
                                font.family: root.fontFamily
                                font.pixelSize: 9
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: card.summary
                            color: "#f0f0f0"
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            id: bodyText

                            Layout.fillWidth: true
                            visible: card.body !== ""
                            text: card.body
                            color: "#9a9a9a"
                            font.family: root.fontFamily
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            textFormat: Text.PlainText
                        }
                    }

                    Rectangle {
                        id: dismissBox

                        anchors.right: parent.right
                        anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        radius: 6
                        color: dismissMouse.containsMouse ? "#1f1f1f" : "transparent"
                        visible: cardMouse.containsMouse || dismissMouse.containsMouse

                        MIcon {
                            anchors.centerIn: parent
                            name: "close"
                            size: 11
                            color: "#8a8a8a"
                        }

                        MouseArea {
                            id: dismissMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const idx = root.indexOfKey(card.key);

                                if (idx >= 0)
                                    root.store.dismissAt(idx);
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const idx = root.indexOfKey(card.key);

                            if (idx >= 0)
                                root.store.dismissAt(idx);
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 6
            color: "#171717"
        }

        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            horizontalAlignment: Text.AlignHCenter
            text: "scroll \u2191 tray  \u00b7  scroll \u2193 close"
            color: "#4d4d4d"
            font.family: root.fontFamily
            font.pixelSize: 9
        }
    }
}
