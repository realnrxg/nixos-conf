import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property string fontFamily
    required property var store

    readonly property var notification: root.store ? root.store.currentToast : null
    readonly property bool critical: root.notification ? root.notification.critical === true : false

    signal dismissRequested()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10
        visible: root.notification !== null
        opacity: root.notification ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Item {
            implicitWidth: 36
            implicitHeight: 36
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: "#0d0d0d"
                border.width: 1
                border.color: root.critical ? "#4a3c10" : "#232323"
            }

            IconImage {
                id: toastIcon

                anchors.fill: parent
                anchors.margins: 5
                asynchronous: true
                source: root.notification && root.notification.image && !root.notification.image.startsWith("image://icon/")
                    ? root.notification.image
                    : (root.notification && root.notification.appIcon !== "" ? Quickshell.iconPath(root.notification.appIcon, true) : "")
                visible: source !== ""
            }

            MIcon {
                anchors.centerIn: parent
                name: root.critical ? "error" : "notifications"
                size: 16
                color: root.critical ? "#f0c040" : "#9a9a9a"
                visible: !toastIcon.visible
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.notification ? root.notification.appName : ""
                color: "#7f7f7f"
                font.family: root.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }

            Text {
                Layout.fillWidth: true
                text: root.notification ? root.notification.summary : ""
                color: "#f7f7f7"
                font.family: root.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                visible: root.notification && root.notification.body !== ""
                text: root.notification ? root.notification.body : ""
                color: "#a5a5a5"
                font.family: root.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
                textFormat: Text.PlainText
            }
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.critical ? "!" : "\u2715"
            color: root.critical ? "#f0c040" : "#5a5a5a"
            font.family: root.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.dismissRequested()
    }
}
