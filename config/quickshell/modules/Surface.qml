import QtQuick
import QtQuick.Layouts
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
    readonly property real bottomRadius: Math.max(1, Math.min(height / 2, expanded ? Math.min(height * 0.28, 24) : Math.min(height * 0.42, 8)))
    readonly property real flareRadius: Math.max(1, root.expanded ? Math.min(root.height * 0.14, 16) : Math.min(root.height * 0.4, 10))
    readonly property color surfaceColor: !expanded && handleStyle === "strip" ? "#0c0c0c" : "#000000"
    readonly property real bezierK: 0.55228475

    signal previousRequested
    signal playPauseRequested
    signal nextRequested
    signal dismissRequested
    signal seekRequested(real position)
    signal handleStyleRequested(string style)
    signal trayCloseRequested
    signal launcherCloseRequested
    signal wallpaperCloseRequested
    signal fastfetchCloseRequested
    signal setTotalRequested(int seconds)
    signal adjustRequested(int deltaSeconds)
    signal startPauseRequested
    signal resetRequested

    readonly property real launcherHeight: launcherPanel.implicitHeight
    readonly property real settingsHeight: settingsContent.implicitHeight
    readonly property real timerHeight: timerContent.implicitHeight
    readonly property real calendarHeight: calendarContent.implicitHeight
    readonly property real weatherHeight: weatherContent.implicitHeight

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

        Weather {
            id: weatherContent

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            opacity: root.mode === "tray" && root.quickMenuPage === "weather" ? 1 : 0
            visible: opacity > 0
            fontFamily: root.fontFamily

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
        }

        Fastfetch {
            id: fastfetchPanel

            z: 10
            anchors.fill: parent
            anchors.margins: 10
            open: root.mode === "fastfetch"
            fontFamily: root.fontFamily
            onCloseRequested: root.fastfetchCloseRequested()
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
