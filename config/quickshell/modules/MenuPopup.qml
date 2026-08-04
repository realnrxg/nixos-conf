import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell._Window
import Quickshell.Widgets

PopupWindow {
    id: root

    required property QsMenuHandle menuHandle
    required property QtObject anchorItem
    required property string fontFamily

    property var menuStack: []
    property int cursorIndex: 0

    implicitWidth: 240
    implicitHeight: Math.min(menuColumn.implicitHeight + 20, 460)
    color: "transparent"
    grabFocus: true

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        adjustment: PopupAdjustment.FlipY | PopupAdjustment.SlideX | PopupAdjustment.SlideY
    }

    QsMenuOpener {
        id: opener

        menu: root.menuHandle
    }

    function activateEntry(entry) {
        if (!entry || !entry.enabled || entry.isSeparator)
            return;

        if (entry.hasChildren) {
            root.drillIn(entry);
            return;
        }

        entry.triggered();
        root.closePopup();
    }

    function drillIn(entry) {
        if (!entry || !entry.hasChildren)
            return;
        root.menuStack.push(opener.menu);
        opener.menu = entry.menu;
        root.cursorIndex = 0;
        if (typeof opener.menu.updateLayout === "function")
            opener.menu.updateLayout();
    }

    function goBack() {
        if (root.menuStack.length > 0) {
            opener.menu = root.menuStack.pop();
            root.cursorIndex = 0;
        } else {
            root.closePopup();
        }
    }

    function closePopup() {
        root.visible = false;
    }

    function entryList() {
        const list = [];

        for (let i = 0; i < entryRepeater.count; i++) {
            const item = entryRepeater.itemAt(i);

            if (item && item.entry)
                list.push(item.entry);
        }

        return list;
    }

    function moveCursor(delta) {
        const list = root.entryList();
        const n = list.length;

        if (n === 0)
            return;

        let idx = root.cursorIndex;

        for (let step = 0; step < n; step++) {
            idx = (idx + delta + n) % n;

            if (list[idx].enabled && !list[idx].isSeparator)
                break;
        }

        root.cursorIndex = idx;

        const item = entryRepeater.itemAt(idx);

        if (item) {
            const target = Math.max(0, Math.min(item.y - 8, scroller.contentHeight - scroller.height));
            scroller.contentY = target;
        }
    }

    function currentEntry() {
        const list = root.entryList();

        if (list.length === 0)
            return null;

        return list[root.cursorIndex] || null;
    }

    onVisibleChanged: {
        if (root.visible) {
            root.menuStack = [];
            opener.menu = root.menuHandle;
            root.cursorIndex = 0;
            scroller.contentY = 0;

            if (root.menuHandle && root.menuHandle.menu
                    && typeof root.menuHandle.menu.sendOpened === "function")
                root.menuHandle.menu.sendOpened();
        } else {
            root.menuStack = [];

            if (root.menuHandle && root.menuHandle.menu
                    && typeof root.menuHandle.menu.sendClosed === "function")
                root.menuHandle.menu.sendClosed();
        }
    }

    onClosed: root.visible = false

    Rectangle {
        id: panel

        anchors.fill: parent
        anchors.margins: 6
        radius: 12
        color: "#000000"
        border.width: 1
        border.color: "#232323"
        clip: true
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Up) {
                root.moveCursor(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                root.moveCursor(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activateEntry(root.currentEntry());
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                const entry = root.currentEntry();

                if (entry && entry.hasChildren)
                    root.drillIn(entry);

                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Escape) {
                root.goBack();
                event.accepted = true;
            }
        }

        Flickable {
            id: scroller

            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: menuColumn.implicitHeight

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

            ColumnLayout {
                id: menuColumn

                width: scroller.width
                spacing: 0

                Repeater {
                    id: entryRepeater

                    model: opener.children

                    delegate: Component {
                        Item {
                            id: row

                            required property var modelData
                            required property int index

                            readonly property var entry: row.modelData

                            Layout.fillWidth: true
                            implicitHeight: entry.isSeparator ? 9 : 32
                            Layout.topMargin: entry.isSeparator ? 3 : 0
                            Layout.bottomMargin: entry.isSeparator ? 3 : 0

                            Rectangle {
                                id: rowBg

                                anchors.fill: parent
                                anchors.leftMargin: 3
                                anchors.rightMargin: 3
                                radius: 6
                                visible: !entry.isSeparator
                                color: (rowMouse.containsMouse || root.cursorIndex === index) ? "#151515" : "transparent"
                                border.width: (rowMouse.containsMouse || root.cursorIndex === index) ? 1 : 0
                                border.color: "#262626"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 80
                                    }
                                }
                            }

                            Rectangle {
                                visible: entry.isSeparator
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                height: 1
                                color: "#171717"
                            }

                            RowLayout {
                                visible: !entry.isSeparator
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 8
                                spacing: 8

                                Item {
                                    implicitWidth: 18
                                    implicitHeight: 18

                                    IconImage {
                                        anchors.centerIn: parent
                                        asynchronous: true
                                        implicitSize: 15
                                        visible: entry.icon !== ""
                                        source: entry.icon
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: entry.text
                                    color: entry.enabled ? "#c8c8c8" : "#5a5a5a"
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Rectangle {
                                    visible: entry.buttonType !== QsMenuButtonType.None
                                    implicitWidth: 15
                                    implicitHeight: 15
                                    radius: entry.buttonType === QsMenuButtonType.RadioButton ? 7.5 : 4
                                    color: "transparent"
                                    border.width: 1
                                    border.color: entry.checkState !== Qt.Unchecked ? "#f0f0f0" : "#3a3a3a"

                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: 3.5
                                        radius: entry.buttonType === QsMenuButtonType.RadioButton ? width / 2 : 2
                                        color: "#f0f0f0"
                                        visible: entry.checkState !== Qt.Unchecked
                                    }
                                }

                                MIcon {
                                    visible: entry.hasChildren
                                    name: "chevron_right"
                                    size: 12
                                    color: "#9a9a9a"
                                }
                            }

                            MouseArea {
                                id: rowMouse

                                anchors.fill: parent
                                visible: !entry.isSeparator
                                hoverEnabled: true
                                cursorShape: entry.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: {
                                    if (entry.enabled)
                                        root.cursorIndex = index;
                                }
                                onClicked: {
                                    panel.forceActiveFocus();
                                    root.activateEntry(row.entry);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
