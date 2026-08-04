import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root

    property string mode: "idle"
    property string appName: ""
    property string title: ""
    property string body: ""
    property string artist: ""
    property string artUrl: ""
    property int volume: 0
    property bool muted: false
    property bool volumeIndicatorVisible: false
    property bool playing: false
    property bool canGoPrevious: false
    property bool canTogglePlaying: false
    property bool canGoNext: false
    property bool canSeek: false
    property real mediaPosition: 0
    property real mediaLength: 0
    property bool forceExpanded: false
    property string quickMenuPage: "tray"
    property var notifStore: null
    property bool mediaAvailable: false
    property bool timerActive: false
    property int timerRemaining: 0
    property int timerTotal: 0
    property bool timerRunning: false
    property date calendarDate: new Date()
    property string handleStyle: "bump"
    property string timeText: ""
    property string dateText: ""
    property string fontFamily: "Maple Mono NF"
    readonly property bool expanded: mode !== "idle" || forceExpanded
    readonly property bool sniMenuOpen: trayContent.sniMenuOpen
    readonly property var sniMenuWindow: trayContent.menuWindow
    readonly property real bottomRadius: Math.max(1, Math.min(height / 2, expanded ? Math.min(height * 0.28, 24) : Math.min(height * 0.42, 8)))
    readonly property real flareRadius: Math.max(1, root.expanded ? Math.min(root.height * 0.14, 16) : Math.min(root.height * 0.4, 10))
    readonly property color surfaceColor: !expanded && handleStyle === "strip" ? "#0c0c0c" : "#000000"
    readonly property real bezierK: 0.55228475

    signal previousRequested
    signal playPauseRequested
    signal nextRequested
    signal favoriteRequested
    signal dismissRequested
    signal seekRequested(real position)
    signal handleStyleRequested(string style)
    signal trayCloseRequested
    signal launcherCloseRequested
    signal wallpaperCloseRequested
    signal wallpaperSelected(string fileName)
    signal fastfetchCloseRequested
    signal fastfetchSelected(string baseName)
    signal setTotalRequested(int seconds)
    signal adjustRequested(int deltaSeconds)
    signal startPauseRequested
    signal resetRequested

    readonly property real launcherHeight: launcherPanel.implicitHeight
    readonly property real settingsHeight: settingsContent.implicitHeight
    readonly property real timerHeight: timerContent.implicitHeight
    readonly property real calendarHeight: calendarContent.implicitHeight

    function notifScroll(delta) {
        if (notifContent && notifContent.visible)
            return notifContent.scrollList(delta);

        return false;
    }

    transformOrigin: Item.Top



    Shape {
        id: islandSilhouette

        x: -root.flareRadius
        y: 0
        width: root.width + root.flareRadius * 2
        height: root.height
        antialiasing: true

        ShapePath {
            fillColor: root.surfaceColor
            strokeColor: "transparent"
            joinStyle: ShapePath.RoundJoin

            startX: 0
            startY: 0

            PathLine {
                x: root.width + root.flareRadius * 2
                y: 0
            }

            PathCubic {
                x: root.width + root.flareRadius
                y: root.flareRadius
                control1X: root.width + root.flareRadius * 2 - root.flareRadius * root.bezierK
                control1Y: 0
                control2X: root.width + root.flareRadius
                control2Y: root.flareRadius - root.flareRadius * root.bezierK
            }

            PathLine {
                x: root.width + root.flareRadius
                y: root.height - root.bottomRadius
            }

            PathCubic {
                x: root.width + root.flareRadius - root.bottomRadius
                y: root.height
                control1X: root.width + root.flareRadius
                control1Y: root.height - root.bottomRadius + root.bottomRadius * root.bezierK
                control2X: root.width + root.flareRadius - root.bottomRadius + root.bottomRadius * root.bezierK
                control2Y: root.height
            }

            PathLine {
                x: root.flareRadius + root.bottomRadius
                y: root.height
            }

            PathCubic {
                x: root.flareRadius
                y: root.height - root.bottomRadius
                control1X: root.flareRadius + root.bottomRadius - root.bottomRadius * root.bezierK
                control1Y: root.height
                control2X: root.flareRadius
                control2Y: root.height - root.bottomRadius + root.bottomRadius * root.bezierK
            }

            PathLine {
                x: root.flareRadius
                y: root.flareRadius
            }

            PathCubic {
                x: 0
                y: 0
                control1X: root.flareRadius
                control1Y: root.flareRadius - root.flareRadius * root.bezierK
                control2X: root.flareRadius * root.bezierK
                control2Y: 0
            }
        }
    }

    Rectangle {
        id: shadow

        anchors.fill: bodyShape
        anchors.topMargin: 8
        radius: root.bottomRadius
        color: "#000000"
        opacity: 0
        scale: 1

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: outerGlow

        anchors.fill: bodyShape
        anchors.margins: -1
        radius: root.bottomRadius + 1
        color: "transparent"
        border.width: 1
        border.color: "#000000"
        opacity: 0
    }

    Item {
        id: bodyShape

        anchors.fill: parent
        clip: true

        Rectangle {
            id: coldSheen

            x: parent.width * 0.08
            y: 3
            width: parent.width * 0.84
            height: Math.max(6, parent.height * 0.32)
            radius: height / 2
            opacity: 0

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "#00243a00"
                }

                GradientStop {
                    position: 0.34
                    color: "#55d7ff"
                }

                GradientStop {
                    position: 0.68
                    color: "#d6fbff"
                }

                GradientStop {
                    position: 1
                    color: "#00243a00"
                }
            }
        }

        Rectangle {
            id: leftCore

            width: root.expanded ? 84 : 42
            height: width
            radius: width / 2
            x: -width * 0.38
            y: -width * 0.18
            color: "#000000"
            opacity: 0
        }

        Rectangle {
            id: rightCore

            width: root.expanded ? 96 : 48
            height: width
            radius: width / 2
            x: parent.width - width * 0.58
            y: parent.height - width * 0.68
            color: "#000000"
            opacity: 0
        }

        Canvas {
            id: volumeTrace

            z: 8
            anchors.fill: parent
            opacity: root.volumeIndicatorVisible ? 1 : 0

            function perimeterPoints() {
                const inset = Math.max(1.5, Math.min(4, height * 0.22, width * 0.08));
                const left = inset;
                const right = Math.max(left + 1, width - inset);
                const openTop = Math.min(height - inset - 1, Math.max(inset + 1, height * 0.18));
                const bottom = Math.max(openTop + 1, height - inset);
                const radius = Math.max(0, Math.min(root.bottomRadius - inset, (right - left) / 2));
                const arcSteps = 10;
                const points = [
                    {
                        x: left,
                        y: openTop
                    },
                    {
                        x: left,
                        y: bottom - radius
                    }
                ];

                for (let i = 0; i <= arcSteps; i += 1) {
                    const angle = Math.PI - i / arcSteps * Math.PI / 2;
                    points.push({
                        x: left + radius + Math.cos(angle) * radius,
                                y: bottom - radius + Math.sin(angle) * radius
                    });
                }

                points.push({
                    x: right - radius,
                    y: bottom
                });

                for (let i = 0; i <= arcSteps; i += 1) {
                    const angle = Math.PI / 2 - i / arcSteps * Math.PI / 2;
                    points.push({
                        x: right - radius + Math.cos(angle) * radius,
                                y: bottom - radius + Math.sin(angle) * radius
                    });
                }

                points.push({
                    x: right,
                    y: openTop
                });
                return points;
            }

            function distance(a, b) {
                const dx = b.x - a.x;
                const dy = b.y - a.y;

                return Math.sqrt(dx * dx + dy * dy);
            }

            function tracePath(ctx, progress) {
                const points = perimeterPoints();
                let total = 0;

                for (let i = 1; i < points.length; i += 1)
                    total += distance(points[i - 1], points[i]);

                ctx.beginPath();
                ctx.moveTo(points[0].x, points[0].y);

                if (total <= 0 || progress <= 0)
                    return;

                const target = total * Math.max(0, Math.min(1, progress));
                let walked = 0;

                for (let i = 1; i < points.length; i += 1) {
                    const previous = points[i - 1];
                    const current = points[i];
                    const segment = distance(previous, current);

                    if (walked + segment >= target) {
                        const t = segment === 0 ? 0 : (target - walked) / segment;

                        ctx.lineTo(previous.x + (current.x - previous.x) * t, previous.y + (current.y - previous.y) * t);
                        return;
                    }

                    ctx.lineTo(current.x, current.y);
                    walked += segment;
                }
            }

            onPaint: {
                const ctx = getContext("2d");
                const progress = root.muted ? 0 : Math.max(0, Math.min(1, root.volume / 100));

                ctx.reset();
                ctx.clearRect(0, 0, width, height);
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                ctx.strokeStyle = "rgba(190, 190, 190, 0.22)";
                tracePath(ctx, 1);
                ctx.stroke();

                if (progress > 0) {
                    ctx.strokeStyle = "rgba(245, 245, 245, 0.92)";
                    tracePath(ctx, progress);
                    ctx.stroke();
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: requestPaint()
            Connections {
                target: root

                function onVolumeChanged() {
                    volumeTrace.requestPaint();
                }

                function onMutedChanged() {
                    volumeTrace.requestPaint();
                }

                function onVolumeIndicatorVisibleChanged() {
                    volumeTrace.requestPaint();
                }
            }
        }

        Content {
            z: 10
            anchors.fill: parent
            anchors.margins: root.expanded ? (root.mode === "media" ? 10 : 12) : 0
            opacity: root.mode === "launcher" || root.mode === "wallpaper" || root.mode === "fastfetch" ? 0 : 1
            visible: opacity > 0
            mode: root.mode
            handleStyle: root.handleStyle
            forceExpanded: root.forceExpanded
                title: root.title
                body: root.body
                artist: root.artist
                artUrl: root.artUrl
                playing: root.playing
                canGoPrevious: root.canGoPrevious
                canTogglePlaying: root.canTogglePlaying
                canGoNext: root.canGoNext
                canSeek: root.canSeek
                mediaPosition: root.mediaPosition
                mediaLength: root.mediaLength
                mediaAvailable: root.mediaAvailable
                timerActive: root.timerActive
                timerRemaining: root.timerRemaining
                timerTotal: root.timerTotal
                fontFamily: root.fontFamily
                timeText: root.timeText
                dateText: root.dateText
                onPreviousRequested: root.previousRequested()
                onPlayPauseRequested: root.playPauseRequested()
                onNextRequested: root.nextRequested()
                onFavoriteRequested: root.favoriteRequested()
                onDismissRequested: root.dismissRequested()
                onSeekRequested: position => root.seekRequested(position)
                onHandleStyleRequested: style => root.handleStyleRequested(style)
        }

        Tray {
            id: trayContent

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            opacity: root.mode === "tray" && root.quickMenuPage === "tray" ? 1 : 0
            visible: opacity > 0
            fontFamily: root.fontFamily
            onCloseRequested: root.trayCloseRequested()

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }
        }

        NotificationList {
            id: notifContent

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            opacity: root.mode === "tray" && root.quickMenuPage === "notifications" ? 1 : 0
            visible: opacity > 0
            fontFamily: root.fontFamily
            store: root.notifStore
            onCloseRequested: root.trayCloseRequested()

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }
        }

        Settings {
            id: settingsContent

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            opacity: root.mode === "tray" && root.quickMenuPage === "settings" ? 1 : 0
            visible: opacity > 0
            fontFamily: root.fontFamily
            dnd: root.notifStore ? root.notifStore.dnd : false
            onDndToggleRequested: function(v) {
                if (root.notifStore)
                    root.notifStore.dnd = v;
            }
            onCloseRequested: root.trayCloseRequested()

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }
        }

        Countdown {
            id: timerContent

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            opacity: root.mode === "tray" && root.quickMenuPage === "timer" ? 1 : 0
            visible: opacity > 0
            fontFamily: root.fontFamily
            totalSeconds: root.timerTotal
            remainingSeconds: root.timerRemaining
            running: root.timerRunning
            onSetTotal: seconds => root.setTotalRequested(seconds)
            onAdjust: delta => root.adjustRequested(delta)
            onStartPause: root.startPauseRequested()
            onResetRequest: root.resetRequested()

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }
        }

        Calendar {
            id: calendarContent

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            opacity: root.mode === "tray" && root.quickMenuPage === "calendar" ? 1 : 0
            visible: opacity > 0
            fontFamily: root.fontFamily
            date: root.calendarDate

            Behavior on opacity {
                NumberAnimation {
                    duration: 180
                }
            }
        }

        Toast {
            id: toastContent

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            opacity: root.mode === "toast" ? 1 : 0
            visible: opacity > 0
            fontFamily: root.fontFamily
            store: root.notifStore
            onDismissRequested: root.notifStore.ackToast()

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }
        }

        Launcher {
            id: launcherPanel

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            embedded: true
            open: root.mode === "launcher"
            fontFamily: root.fontFamily
            onCloseRequested: root.launcherCloseRequested()
        }

        Wallpaper {
            id: wallpaperPanel

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            open: root.mode === "wallpaper"
            fontFamily: root.fontFamily
            onCloseRequested: root.wallpaperCloseRequested()
            onWallpaperSelectionChanged: fileName => root.wallpaperSelected(fileName)
        }

        Fastfetch {
            id: fastfetchPanel

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            open: root.mode === "fastfetch"
            fontFamily: root.fontFamily
            onCloseRequested: root.fastfetchCloseRequested()
            onFastfetchSelectionChanged: baseName => root.fastfetchSelected(baseName)
        }
    }


    Behavior on width {
        NumberAnimation {
            duration: 380
            easing.type: Easing.OutBack
            easing.overshoot: 0.4
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 380
            easing.type: Easing.OutBack
            easing.overshoot: 0.4
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: 380
            easing.type: Easing.OutBack
            easing.overshoot: 0.4
        }
    }
}
