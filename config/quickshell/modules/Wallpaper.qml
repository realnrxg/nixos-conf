import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property bool open
    required property string fontFamily

    signal closeRequested()

    readonly property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wallpapers"
    readonly property string wallpaperLink: Quickshell.env("HOME") + "/.config/hypr/current_wallpaper"

    readonly property real cardWidth: 175
    readonly property real cardHeight: 92
    readonly property real cardSpacing: 16
    readonly property real enlargedScale: 1.18
    readonly property real sideScale: 1 / root.enlargedScale
    readonly property real edgePadding: 24

    readonly property real thumbHeight: Math.round(root.cardHeight * root.enlargedScale)
    readonly property real panelHeight: root.thumbHeight + 8


    readonly property int batchSize: 20
    property bool allLoaded: false
    property bool isLoadingBatch: false


    property string selectedWallpaper: ""
    property string activeWallpaper: ""
    property bool positionedOnce: false

    function readCurrentWallpaperName() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + root.wallpaperLink, false);
        xhr.send();

        if (xhr.status !== 0 && xhr.status !== 200)
            return "";

        return String(xhr.responseText || "").trim().split("/").pop() || "";
    }

    function currentWallpaperIndex() {
        const name = root.readCurrentWallpaperName();
        root.activeWallpaper = name;

        if (!name)
            return -1;

        for (let i = 0; i < wallModel.count; i += 1) {
            if (wallModel.get(i).fileName === name)
                return i;
        }

        return -1;
    }

    function positionOnOpen() {
        if (root.positionedOnce || wallModel.count === 0)
            return;

        root.positionedOnce = true;
        const idx = root.currentWallpaperIndex();
        view.currentIndex = idx >= 0 ? idx : 0;
        view.positionViewAtIndex(view.currentIndex, ListView.Center);
    }

    function applyWallpaper(filePath) {
        if (!filePath)
            return;

        let wall = String(filePath).replace(/^file:\/\//, "");
        wall = decodeURIComponent(wall);
        root.activeWallpaper = wall.split("/").pop();
        const esc = (str) => String(str).replace(/(["\\$`])/g, '\\$1');

        const script = `
        (
            WALL="${esc(wall)}"
            LINK="${esc(root.wallpaperLink)}"
            matugen image "$WALL" --mode dark --type scheme-tonal-spot --source-color-index 0 || true
            awww img "$WALL" --transition-type any
            mkdir -p "$(dirname "$LINK")"
            ln -sf "$WALL" "$LINK"
        ) > /tmp/qs_wallpaper_apply.log 2>&1 & disown
        `;
        Quickshell.execDetached(["bash", "-c", script]);
        root.closeRequested();
    }

    function syncWallModel() {
        wallModel.clear();
        root.allLoaded = false;
        root.loadNextBatch();
    }

    function loadNextBatch() {
        if (root.allLoaded || root.isLoadingBatch) return;
        root.isLoadingBatch = true;

        const start = wallModel.count;
        const end = Math.min(start + root.batchSize, folderModel.count);

        for (let i = start; i < end; i += 1) {
            wallModel.append({
                fileName: folderModel.get(i, "fileName"),
                             fileUrl: String(folderModel.get(i, "fileUrl"))
            });
        }

        if (end >= folderModel.count) {
            root.allLoaded = true;
        }
        root.isLoadingBatch = false;
    }

    onOpenChanged: {
        if (root.open) {
            root.positionedOnce = false;
            Qt.callLater(() => {
                root.positionOnOpen();
                view.forceActiveFocus();
            });
        }
    }

    implicitWidth: view.width
    implicitHeight: root.open ? root.panelHeight : 0
    opacity: root.open ? 1 : 0
    visible: root.open
    clip: true

    Behavior on opacity {
        NumberAnimation {
            duration: 160
            easing.type: Easing.OutCubic
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        transform: Translate {
            id: entranceShift

            y: root.open ? 0 : 6

            Behavior on y {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
        }

        FolderListModel {
            id: folderModel

            folder: "file://" + root.wallpaperDir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
            showDirs: false
            sortField: FolderListModel.Name
            sortReversed: false

            onCountChanged: root.syncWallModel()
            onStatusChanged: {
                if (status === FolderListModel.Ready)
                    root.syncWallModel()
            }
        }

        ListModel {
            id: wallModel
        }

        ListView {
            id: view

            Layout.fillWidth: true
            Layout.preferredHeight: root.thumbHeight
            Layout.topMargin: 6
            orientation: ListView.Horizontal
            spacing: root.cardSpacing
            clip: true
            focus: root.open
            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.SnapToItem
            model: wallModel
            currentIndex: 0

            header: Item { width: root.edgePadding }
            footer: Item { width: root.edgePadding }

            property bool loadingNext: false
            onContentXChanged: {
                if (contentX + width + (width * 0.5) > contentWidth && !root.allLoaded && !loadingNext) {
                    loadingNext = true;
                    batchLoadTimer.start();
                }
            }

            Keys.onLeftPressed: (event) => {
                if (view.currentIndex > 0)
                    view.currentIndex -= 1;
                event.accepted = true;
            }
            Keys.onRightPressed: (event) => {
                if (view.currentIndex < view.count - 1)
                    view.currentIndex += 1;
                event.accepted = true;
            }
            Keys.onReturnPressed: (event) => {
                const entry = wallModel.get(view.currentIndex);
                if (entry)
                    root.applyWallpaper(entry.fileUrl);
                event.accepted = true;
            }
            Keys.onEscapePressed: (event) => {
                root.closeRequested();
                event.accepted = true;
            }

            onCurrentIndexChanged: {
                const entry = view.currentIndex >= 0 ? wallModel.get(view.currentIndex) : null;
                const name = entry ? String(entry.fileName || "") : "";
                root.selectedWallpaper = name;

                if (view.currentIndex >= 0)
                    view.positionViewAtIndex(view.currentIndex, ListView.Center);
            }

            delegate: Item {
                id: delegateRoot

                required property string fileName
                required property string fileUrl
                required property int index

                readonly property bool isCurrent: ListView.isCurrentItem
                readonly property bool isActive: fileName === root.activeWallpaper

                property bool hovered: false

                readonly property real targetScale: isCurrent ? 1.0 : (hovered ? root.sideScale + 0.03 : root.sideScale)

                width: root.cardWidth
                height: ListView.view.height
                z: isCurrent ? 10 : (hovered ? 5 : 1)
                transformOrigin: Item.Center
                scale: targetScale
                opacity: isCurrent ? 1.0 : (hovered ? 0.7 : 0.55)

                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "#0a0a0a"
                    border.width: 1
                    border.color: isCurrent ? "#3a3a3a" : (hovered ? "#262626" : "#1a1a1a")
                    clip: true

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: fileUrl
                        sourceSize: Qt.size(root.cardWidth, root.cardHeight)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        clip: true
                    }

                    Rectangle {
                        id: captionBar

                        visible: isCurrent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 24
                        opacity: isCurrent ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }

                        gradient: Gradient {
                            GradientStop { position: 0; color: "#00000000" }
                            GradientStop { position: 0.45; color: "#40000000" }
                            GradientStop { position: 1; color: "#d9000000" }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 9
                            anchors.rightMargin: 9
                            spacing: 8

                            Text {
                                width: parent.width - indexText.implicitWidth - parent.spacing
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: fileName
                                color: "#f7f7f7"
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                id: indexText

                                width: implicitWidth
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: (view.currentIndex + 1) + " / " + wallModel.count
                                color: "#9a9a9a"
                                font.family: root.fontFamily
                                font.pixelSize: 9
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        border.width: isCurrent ? 1.5 : 0
                        border.color: isCurrent ? "#73ffffff" : "transparent"
                        color: "transparent"
                        opacity: isCurrent ? 1 : 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 120
                            }
                        }
                    }

                    Rectangle {
                        id: setBadge

                        visible: isActive
                        anchors.top: parent.top
                        anchors.topMargin: 5
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        height: 15
                        width: badgeText.implicitWidth + 14
                        radius: 7.5
                        color: "#99000000"
                        border.width: 1
                        border.color: "#2effffff"

                        Row {
                            anchors.centerIn: parent
                            spacing: 3

                            Rectangle {
                                width: 5
                                height: 5
                                radius: 2.5
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: badgeText

                                text: "SET"
                                color: "#f2f2f2"
                                font.family: root.fontFamily
                                font.pixelSize: 8
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                MouseArea {
                    id: cardMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: delegateRoot.hovered = true
                    onExited: delegateRoot.hovered = false
                    onClicked: view.currentIndex = index
                    onDoubleClicked: root.applyWallpaper(fileUrl)
                }
            }
        }

        Timer {
            id: batchLoadTimer
            interval: 80
            repeat: false
            onTriggered: {
                root.loadNextBatch();
                view.loadingNext = false;
            }
        }
    }
}
