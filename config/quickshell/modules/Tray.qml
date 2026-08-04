import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    required property string fontFamily

    signal closeRequested()

    readonly property real padding: 10
    readonly property real headerHeight: 16
    readonly property real trayButtonSize: 34
    readonly property real traySpacing: 6
    readonly property real powerHeight: 30

    property var trayItems: SystemTray.items.values.filter(item => item && item.icon)
    property int armedIndex: -1

    readonly property int trayCount: root.trayItems.length
    readonly property bool sniMenuOpen: menuPopupWindow.visible

    function openAppMenu(item, itemDelegate) {
        if (!item || !item.hasMenu)
            return;

        menuPopupWindow.menuHandle = item.menu;
        menuPopupWindow.anchorItem = itemDelegate;
        menuPopupWindow.visible = true;
    }

    MenuPopup {
        id: menuPopupWindow

        fontFamily: root.fontFamily
    }

    readonly property MenuPopup menuWindow: menuPopupWindow

    function executePower(modelData) {
        if (!modelData)
            return;

        Quickshell.execDetached({
            command: modelData.command
        });
    }

    property var powerActions: [
        {
            id: "power",
            label: "Shutdown",
            icon: "power_settings_new",
            command: ["systemctl", "poweroff"]
        },
        {
            id: "lock",
            label: "Lock",
            icon: "lock",
            command: ["sh", "-c", "qs -n -p ~/.config/quickshell/lock/shell.qml"]
        },
        {
            id: "restart",
            label: "Restart",
            icon: "restart_alt",
            command: ["systemctl", "reboot"]
        }
    ]

    onVisibleChanged: {
        if (root.visible)
            root.armedIndex = -1;
    }

    Timer {
        interval: 2600
        repeat: false
        running: root.armedIndex >= 0
        onTriggered: root.armedIndex = -1
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
                text: "System Tray"
                color: "#9a9a9a"
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: String(root.trayCount)
                color: "#6d6d6d"
                font.family: root.fontFamily
                font.pixelSize: 11
            }

            Text {
                text: "  \u2190 / \u2192"
                color: "#4d4d4d"
                font.family: root.fontFamily
                font.pixelSize: 10
            }
        }

        Item {
            visible: root.trayCount > 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.trayButtonSize
            Layout.topMargin: 6

            Flow {
                anchors.fill: parent
                spacing: root.traySpacing
                layoutDirection: Qt.LeftToRight

                Repeater {
                    model: root.trayItems

                    delegate: Item {
                        id: trayItem

                        required property var modelData
                        required property int index

                        readonly property bool needsAttention: modelData.status === Status.NeedsAttention

                        width: root.trayButtonSize
                        height: root.trayButtonSize

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: trayMouse.containsMouse ? "#151515" : "transparent"
                            border.width: 1
                            border.color: trayMouse.containsMouse ? "#262626" : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 90
                                }
                            }
                        }

                        IconImage {
                            anchors.centerIn: parent
                            asynchronous: true
                            implicitSize: 22
                            source: modelData.icon
                        }

                        Rectangle {
                            visible: parent.needsAttention
                            anchors.top: parent.top
                            anchors.topMargin: 4
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            width: 5
                            height: 5
                            radius: 2.5
                            color: "#f0f0f0"
                        }

                        MouseArea {
                            id: trayMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                root.armedIndex = -1;

                                if (mouse.button === Qt.RightButton) {
                                    if (modelData.hasMenu)
                                        root.openAppMenu(modelData, trayItem);
                                    else
                                        modelData.activate();
                                } else if (mouse.button === Qt.MiddleButton) {
                                    modelData.secondaryActivate();
                                } else if (modelData.hasMenu && modelData.onlyMenu) {
                                    root.openAppMenu(modelData, trayItem);
                                } else {
                                    modelData.activate();
                                }
                            }
                            onWheel: wheel => {
                                const delta = wheel.angleDelta.y > 0 ? 1 : -1;
                                modelData.scroll(delta, false);
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.trayCount === 0
            Layout.fillWidth: true
            Layout.preferredHeight: root.trayButtonSize
            Layout.topMargin: 6
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.family: root.fontFamily
            font.pixelSize: 12
            color: "#6d6d6d"
            text: "No tray items"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.topMargin: 6
            color: "#171717"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.powerHeight
            Layout.topMargin: 6
            spacing: 6

            Repeater {
                model: root.powerActions

                delegate: Component {
                    Item {
                        required property int index
                        required property var modelData

                        readonly property bool armed: root.armedIndex === index

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Rectangle {
                            anchors.fill: parent
                            radius: 8


                            color: parent.armed ? "#1a0808" : (powerMouse.containsMouse ? "#151515" : "#090909")

                            border.width: 1
                            border.color: parent.armed ? "#ff4444" : (powerMouse.containsMouse ? "#262626" : "#232323")

                            Behavior on border.color {
                                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 5

                            MIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: parent.armed ? "check" : modelData.icon
                                size: 13
                                color: parent.armed ? "#ffffff" : "#d0d0d0"
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.armed ? "Confirm?" : modelData.label
                                color: parent.armed ? "#ffffff" : "#c8c8c8"
                                font.family: root.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: powerMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (parent.armed) {
                                    root.executePower(modelData);
                                    root.armedIndex = -1;
                                    root.closeRequested();
                                } else {
                                    root.armedIndex = index;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
