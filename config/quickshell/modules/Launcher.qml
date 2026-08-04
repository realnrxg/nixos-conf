import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    required property bool open
    required property string fontFamily
    property bool embedded: false

    signal closeRequested()

    readonly property real searchHeight: 36
    readonly property real rowHeight: 56
    readonly property int maxVisible: 8
    readonly property real maxListHeight: root.rowHeight * root.maxVisible
    readonly property real listHeight: list.count > 0 ? Math.min(root.maxListHeight, list.count * root.rowHeight) : 0
    readonly property real emptyHeight: list.count === 0 ? 44 : 0
    readonly property real cardHeight: 10 + root.searchHeight + 10 + root.listHeight + root.emptyHeight + 10

    readonly property var allApps: DesktopEntries.applications.values

    function appMatches(entry, text) {
        if (!entry)
            return false;

        if (entry.noDisplay)
            return false;

        if (!entry.name)
            return false;

        if (!text)
            return true;

        const t = text.toLowerCase();
        const haystacks = [entry.name, entry.genericName, entry.comment, (entry.categories || []).join(" "), (entry.keywords || []).join(" ")];

        for (let i = 0; i < haystacks.length; i += 1) {
            if (haystacks[i] && haystacks[i].toLowerCase().includes(t))
                return true;
        }

        return false;
    }

    function filteredApps() {
        const text = search.text.trim();
        const out = [];

        for (let i = 0; i < root.allApps.length; i += 1) {
            const entry = root.allApps[i];

            if (root.appMatches(entry, text))
                out.push(entry);
        }

        out.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        return out;
    }

    function launch(entry) {
        if (!entry)
            return;

        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: ["kitty"].concat(entry.command),
                                    workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }

        root.closeRequested();
    }

    function launchCurrent() {
        const values = list.model.values;

        if (values.length === 0)
            return;

        const index = Math.max(0, Math.min(list.currentIndex, values.length - 1));
        root.launch(values[index]);
    }

    implicitWidth: 380
    implicitHeight: root.open ? root.cardHeight : 0
    opacity: root.open ? 1 : 0
    visible: root.open
    clip: true

    Behavior on opacity {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    onOpenChanged: {
        if (root.open) {
            search.text = "";
            list.currentIndex = 0;
            Qt.callLater(() => search.forceActiveFocus());
        }
    }

    Rectangle {
        id: panelBackground

        anchors.fill: parent
        radius: 12
        color: "#000000"
        border.color: "#1a1a1a"
        border.width: 1
        visible: !root.embedded
    }

    TextField {
        id: search

        x: 10
        y: 10
        width: root.width - 20
        height: root.searchHeight
        font.family: root.fontFamily
        font.pixelSize: 13
        color: "#f2f2f2"
        placeholderText: "Search apps..."
        placeholderTextColor: "#7f7f7f"
        selectByMouse: true
        verticalAlignment: TextInput.AlignVCenter

        background: Rectangle {
            radius: 8
            color: search.activeFocus ? "#111111" : "#0a0a0a"
            border.color: search.activeFocus ? "#2e2e2e" : "#232323"
            border.width: 1
        }

        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onEscapePressed: root.closeRequested()
        onAccepted: root.launchCurrent()
    }

    ListView {
        id: list

        x: 10
        y: search.y + search.height + 10
        width: root.width - 20
        height: root.listHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ScriptModel {
            values: root.filteredApps()

            onValuesChanged: list.currentIndex = 0
        }
        delegate: appDelegate
        currentIndex: 0

        Keys.onUpPressed: list.decrementCurrentIndex()
        Keys.onDownPressed: list.incrementCurrentIndex()
        Keys.onReturnPressed: root.launchCurrent()
        Keys.onEscapePressed: root.closeRequested()

        onCurrentIndexChanged: list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    Text {
        id: empty

        x: 10
        y: search.y + search.height + 10
        width: root.width - 20
        height: root.emptyHeight
        visible: list.count === 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.family: root.fontFamily
        font.pixelSize: 12
        color: "#6d6d6d"
        text: "No apps found"
    }

    Component {
        id: appDelegate

        Item {
            required property DesktopEntry modelData
            required property int index

            readonly property bool current: list.currentIndex === index

            width: list.width
            height: root.rowHeight

            Rectangle {
                id: selectBar
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.top: parent.top
                anchors.topMargin: 6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                width: 3
                radius: 1.5
                color: rowMouse.containsMouse || parent.current ? "#4ade80" : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: 90
                    }
                }
            }

            MouseArea {
                id: rowMouse

                anchors.fill: parent
                hoverEnabled: true
                onEntered: list.currentIndex = index
                onClicked: root.launch(modelData)
            }

            IconImage {
                id: icon

                x: 8
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                implicitSize: 24
                source: Quickshell.iconPath(modelData?.icon, "image-missing")
            }


            Item {
                anchors.left: icon.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.topMargin: 6
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6

                Text {
                    id: nameText

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    color: "#f7f7f7"
                    elide: Text.ElideRight
                    text: modelData?.name ?? ""
                }

                Text {
                    id: subText

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: nameText.bottom
                    anchors.bottom: parent.bottom
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    color: "#7f7f7f"
                    elide: Text.ElideRight

                    maximumLineCount: 1
                    text: (modelData?.genericName || modelData?.comment || "") ?? ""
                }
            }
        }
    }
}
