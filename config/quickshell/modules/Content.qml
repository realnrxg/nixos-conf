import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    property string mode: "idle"
    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property bool playing: false
    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool canSeek: false
    property real mediaPosition: 0
    property real mediaLength: 0
    property bool forceExpanded: false
    property bool mediaAvailable: false
    property bool timerActive: false
    property int timerRemaining: 0
    property int timerTotal: 0
    property string handleStyle: "bump"
    property string timeText: ""
    property string dateText: ""
    property string fontFamily: "Maple Mono NF"
    readonly property color primaryText: "#f7f7f7"
    readonly property color secondaryText: "#7f7f7f"
    readonly property color accent: "#ffffff"
    readonly property int mediaHorizontalPadding: 24
    readonly property real normalizedMediaPosition: root.normalizedSeconds(mediaPosition)
    readonly property real normalizedMediaLength: root.normalizedSeconds(mediaLength)
    readonly property real mediaProgress: normalizedMediaLength > 0 ? Math.max(0, Math.min(1, normalizedMediaPosition / normalizedMediaLength)) : 0

    signal previousRequested
    signal playPauseRequested
    signal nextRequested
    signal dismissRequested
    signal seekRequested(real position)
    signal handleStyleRequested(string style)

    function normalizedSeconds(value) {
        if (!isFinite(value) || value <= 0)
            return 0;

        return value > 86400 ? value / 1000000 : value;
    }

    function formatTime(seconds) {
        const normalized = root.normalizedSeconds(seconds);

        if (normalized <= 0)
            return "0:00";

        const safeSeconds = Math.floor(normalized);
        const minutes = Math.floor(safeSeconds / 60);
        const hours = Math.floor(minutes / 60);
        const remainingMinutes = minutes % 60;
        const remainingSeconds = safeSeconds % 60;
        const secondText = remainingSeconds < 10 ? "0" + remainingSeconds : String(remainingSeconds);

        if (hours > 0) {
            const minuteText = remainingMinutes < 10 ? "0" + remainingMinutes : String(remainingMinutes);

            return hours + ":" + minuteText + ":" + secondText;
        }

        return minutes + ":" + secondText;
    }

    function timerText() {
        const s = Math.max(0, root.timerRemaining);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;

        if (h > 0)
            return String(h) + ":" + (m < 10 ? "0" + m : String(m)) + ":" + (sec < 10 ? "0" + sec : String(sec));
        return String(m) + ":" + (sec < 10 ? "0" + sec : String(sec));
    }

    readonly property real timerFrac: root.timerTotal > 0 ? Math.max(0, Math.min(1, root.timerRemaining / root.timerTotal)) : 1

    Item {
        id: collapsedBumpMedia

        anchors.fill: parent
        opacity: root.mode === "idle" && !root.forceExpanded && root.handleStyle === "bump" ? 1 : 0
        visible: opacity > 0

        Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.timeText
                color: root.primaryText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Canvas {
                id: timerBumpCanvas

                width: root.timerActive ? 16 : 0
                height: 16
                visible: root.timerActive
                anchors.verticalCenter: parent.verticalCenter

                onPaint: {
                    const ctx = timerBumpCanvas.getContext("2d");
                    const w = timerBumpCanvas.width;
                    const h = timerBumpCanvas.height;
                    ctx.clearRect(0, 0, w, h);

                    if (!root.timerActive || root.timerTotal <= 0 || w <= 0 || h <= 0)
                        return;

                    const cx = w / 2;
                    const cy = h / 2;
                    const r = Math.max(0, w / 2 - 2);
                    const lw = 2;

                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = "#343434";
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.stroke();

                    if (root.timerFrac > 0.002 && root.timerTotal > 0) {
                        const start = -Math.PI / 2;
                        const end = start + 2 * Math.PI * root.timerFrac;
                        ctx.strokeStyle = "#ff9f1c";
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, end);
                        ctx.stroke();
                    }
                }

                Connections {
                    target: root

                    function onTimerFracChanged() {
                        timerBumpCanvas.requestPaint();
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            y: parent.height - 2
            x: 4
            width: parent.width - 8
            height: 2
            radius: 1
            color: "#1d1d1d"
            visible: root.mediaAvailable

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: root.playing ? parent.width * root.mediaProgress : 6
                height: parent.height
                radius: parent.radius
                color: root.playing ? "#f2f2f2" : "#5f5f5f"

                Behavior on width {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: idleContent

        anchors.fill: parent
        opacity: root.mode === "idle" && root.forceExpanded ? 1 : 0
        visible: opacity > 0

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 6
            anchors.bottomMargin: 7
            spacing: 2

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.timeText
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: root.dateText
                    color: "#b8b8b8"
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }
    }

    RowLayout {
        id: mediaContent

        anchors.fill: parent
        anchors.leftMargin: root.mediaHorizontalPadding
        anchors.rightMargin: root.mediaHorizontalPadding
        spacing: 24
        opacity: root.mode === "media" ? 1 : 0
        visible: opacity > 0

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 90

            Rectangle {
                id: mediaArtwork
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -10
                implicitWidth: 90
                implicitHeight: 90
                width: 90
                height: 90
                radius: 20
                color: "#000000"
                border.width: 1
                border.color: root.playing ? "#2a2a2a" : "#171717"

                Image {
                    id: mediaCoverSource
                    anchors.fill: parent
                    source: root.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: root.artUrl !== "" && status === Image.Ready && !root.timerActive

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Shape {
                                id: artworkMask
                                width: mediaArtwork.width
                                height: mediaArtwork.height
                                antialiasing: true

                                property real r: mediaArtwork.radius
                                property real s: 0.85

                                ShapePath {
                                    fillColor: "white"
                                    strokeWidth: -1

                                    startX: artworkMask.r
                                    startY: 0
                                    PathLine { x: artworkMask.width - artworkMask.r; y: 0 }
                                    PathCubic {
                                        x: artworkMask.width
                                        y: artworkMask.r
                                        control1X: artworkMask.width - artworkMask.r * (1 - artworkMask.s)
                                        control1Y: 0
                                        control2X: artworkMask.width
                                        control2Y: artworkMask.r * (1 - artworkMask.s)
                                    }
                                    PathLine { x: artworkMask.width; y: artworkMask.height - artworkMask.r }
                                    PathCubic {
                                        x: artworkMask.width - artworkMask.r
                                        y: artworkMask.height
                                        control1X: artworkMask.width
                                        control1Y: artworkMask.height - artworkMask.r * (1 - artworkMask.s)
                                        control2X: artworkMask.width - artworkMask.r * (1 - artworkMask.s)
                                        control2Y: artworkMask.height
                                    }
                                    PathLine { x: artworkMask.r; y: artworkMask.height }
                                    PathCubic {
                                        x: 0
                                        y: artworkMask.height - artworkMask.r
                                        control1X: artworkMask.r * (1 - artworkMask.s)
                                        control1Y: artworkMask.height
                                        control2X: 0
                                        control2Y: artworkMask.height - artworkMask.r * (1 - artworkMask.s)
                                    }
                                    PathLine { x: 0; y: artworkMask.r }
                                    PathCubic {
                                        x: artworkMask.r
                                        y: 0
                                        control1X: 0
                                        control1Y: artworkMask.r * (1 - artworkMask.s)
                                        control2X: artworkMask.r * (1 - artworkMask.s)
                                        control2Y: 0
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 3
                    visible: !root.timerActive && (root.artUrl === "" || mediaCoverSource.status !== Image.Ready)
                    Repeater {
                        model: 3
                        Rectangle {
                            width: 4
                            height: root.playing ? (12 + index * 5) : 10
                            radius: 2
                            color: root.playing ? root.accent : "#4b4b4b"
                            SequentialAnimation on height {
                                running: root.mode === "media" && root.playing
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 10 + index * 4
                                    duration: 360 + index * 80
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 23 - index * 3
                                    duration: 420 + index * 80
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }


                Item {
                    anchors.fill: parent
                    visible: root.timerActive

                    Canvas {
                        id: timerArtCanvas

                        anchors.fill: parent

                        onPaint: {
                            const ctx = timerArtCanvas.getContext("2d");
                            const w = timerArtCanvas.width;
                            const h = timerArtCanvas.height;
                            ctx.clearRect(0, 0, w, h);

                            if (!root.timerActive || root.timerTotal <= 0 || w <= 0 || h <= 0)
                                return;

                            const cx = w / 2;
                            const cy = h / 2;
                            const r = Math.max(0, Math.min(w, h) / 2 - 6);
                            const lineWidth = 5;

                            ctx.lineWidth = lineWidth;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = "#262626";
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                            ctx.stroke();

                            if (root.timerFrac > 0.002) {
                                const start = -Math.PI / 2;
                                const end = start + 2 * Math.PI * root.timerFrac;
                                ctx.strokeStyle = root.timerRemaining <= 0 ? "#8a8a8a" : "#ff9f1c";
                                ctx.beginPath();
                                ctx.arc(cx, cy, r, start, end);
                                ctx.stroke();
                            }
                        }

                        Connections {
                            target: root

                            function onTimerFracChanged() {
                                timerArtCanvas.requestPaint();
                            }
                        }
                    }
                }
            }
        }

ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                    color: root.primaryText
                    elide: Text.ElideRight
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.timeText
                    color: "#f0f0f0"
                    visible: root.timeText !== ""
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    radius: 10
                    color: dismissMouse.containsMouse ? "#1a1a1a" : "#0a0a0a"
                    border.width: 1
                    border.color: "#232323"

                    MIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: 12
                        color: "#999999"
                    }

                    MouseArea {
                        id: dismissMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismissRequested()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.artist
                color: root.secondaryText
                elide: Text.ElideRight
                font.family: root.fontFamily
                font.pixelSize: 13
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                visible: root.mediaLength > 0

                Text {
                    text: root.formatTime(root.mediaPosition)
                    color: "#6d6d6d"
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    id: mediaProgressTrack

                    Layout.fillWidth: true
                    Layout.preferredHeight: 3
                    radius: height / 2
                    color: "#151515"

                    Rectangle {
                        width: parent.width * root.mediaProgress
                        height: parent.height
                        radius: parent.radius
                        color: "#d8d8d8"

                        Behavior on width {
                            NumberAnimation {
                                duration: 260
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        enabled: root.canSeek
                        hoverEnabled: true
                        cursorShape: root.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor

                        function seekToX(x) {
                            const progress = Math.max(0, Math.min(1, x / Math.max(1, mediaProgressTrack.width)));
                            root.seekRequested(root.mediaLength * progress);
                        }

                        onPressed: event => seekToX(event.x)
                        onPositionChanged: event => {
                            if (pressed)
                                seekToX(event.x);
                        }
                    }
                }

                Text {
                    text: root.formatTime(root.mediaLength)
                    color: "#6d6d6d"
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 1
                spacing: 7

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 10
                    color: previousMouse.containsMouse && root.canGoPrevious ? "#151515" : "#090909"
                    border.width: 1
                    border.color: root.canGoPrevious ? "#232323" : "#111111"
                    opacity: root.canGoPrevious ? 1 : 0.35

                    MIcon {
                        anchors.centerIn: parent
                        name: "skip_previous"
                        size: 16
                        color: root.primaryText
                    }

                    MouseArea {
                        id: previousMouse

                        anchors.fill: parent
                        enabled: root.canGoPrevious
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.previousRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 12
                    color: playPauseMouse.containsMouse && root.canTogglePlaying ? "#191919" : "#0b0b0b"
                    border.width: 1
                    border.color: root.canTogglePlaying ? "#2b2b2b" : "#111111"
                    opacity: root.canTogglePlaying ? 1 : 0.35

                    MIcon {
                        anchors.centerIn: parent
                        name: root.playing ? "pause" : "play_arrow"
                        size: 18
                        color: root.primaryText
                        filled: true
                    }

                    MouseArea {
                        id: playPauseMouse

                        anchors.fill: parent
                        enabled: root.canTogglePlaying
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.playPauseRequested()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 10
                    color: nextMouse.containsMouse && root.canGoNext ? "#151515" : "#090909"
                    border.width: 1
                    border.color: root.canGoNext ? "#232323" : "#111111"
                    opacity: root.canGoNext ? 1 : 0.35

                    MIcon {
                        anchors.centerIn: parent
                        name: "skip_next"
                        size: 16
                        color: root.primaryText
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill: parent
                        enabled: root.canGoNext
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextRequested()
                    }
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 210
            }
        }
    }
}
