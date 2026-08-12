import QtQml.Models
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

Scope {
    id: root

    property string mode: "idle"
    property string title: "Ready"
    property string artist: ""
    property string artUrl: ""
    property bool playing: true
    property bool demoRunning: false
    property bool pointerInside: false
    property bool pinnedOpen: false
    property bool mediaHoverSuppressed: false
    property bool liveLinksEnabled: true
    property bool liveLinksPrimed: false
    property date currentDateTime: new Date()
    property string handleStyle: "bump"
    property var activePlayer: null
    property string lastTrackKey: ""
    property int demoStep: 0
    property bool trayMediaDismissed: false
    property bool launcherOpen: false
    property bool wallpaperOpen: false
    property bool fastfetchOpen: false
    property bool quickMenuOpen: false
    property string quickMenuPage: "tray"
    property bool sniMenuOpen: island.sniMenuOpen
    property int timerTotalSeconds: 0
    property int timerRemainingSeconds: 0
    property bool timerRunning: false

    readonly property bool timerActive: root.timerTotalSeconds > 0
    readonly property int timerRemaining: Math.max(0, root.timerRemainingSeconds)
    readonly property int timerTotal: Math.max(0, root.timerTotalSeconds)

    readonly property int launcherWidth: 380
    readonly property int wallpaperWidth: 900
    readonly property int wallpaperHeight: 144
    readonly property int fastfetchWidth: 620
    readonly property int fastfetchHeight: 144

    readonly property bool interactionOpen: !root.launcherOpen && root.mode === "idle" && (root.pointerInside || root.pinnedOpen || root.quickMenuOpen)
    readonly property bool trayVisible: !root.launcherOpen && root.handleStyle === "bump" && !root.interactionOpen && root.visualMode === "idle"
    readonly property bool hoverMediaMode: !root.launcherOpen && root.liveLinksEnabled && root.mode === "idle" && !root.toastActive && root.interactionOpen && !root.mediaHoverSuppressed && root.hasActiveMedia()
    readonly property string visualMode: root.fastfetchOpen ? "fastfetch" : (root.wallpaperOpen ? "wallpaper" : (root.launcherOpen ? "launcher" : (root.quickMenuOpen ? "tray" : (root.toastActive ? "toast" : (root.hoverMediaMode ? "media" : root.mode)))))
    readonly property int idleTopMargin: 0
    readonly property int expandedTopMargin: 0
    readonly property int reservedZone: root.handleStyle === "strip" ? 0 : 24
    readonly property int windowHeight: 136
    readonly property int bumpWidth: 120
    readonly property int bumpHeight: 25
    readonly property int stripWidth: 98
    readonly property int stripHeight: 4
    readonly property int peekWidth: 340
    readonly property int peekHeight: 132
    readonly property int mediaWidth: 400
    readonly property int mediaHeight: 135
    readonly property int toastWidth: 360
    readonly property int toastHeight: 82
    readonly property int toastHoldMs: 4500
    readonly property bool toastActive: notifStore.currentToast !== null
    readonly property string fontFamily: "Maple Mono NF"
    readonly property int currentWorkspace: Hyprland.focusedWorkspace?.id ?? 0
    readonly property bool mediaCanGoPrevious: root.activePlayer?.canGoPrevious ?? false
    readonly property bool mediaCanTogglePlaying: (root.activePlayer?.canTogglePlaying ?? false) || (root.activePlayer?.canPause ?? false) || (root.activePlayer?.canPlay ?? false)
    readonly property bool mediaCanGoNext: root.activePlayer?.canGoNext ?? false
    readonly property real mediaPosition: Math.max(0, root.activePlayer?.position ?? 0)
    readonly property real mediaLength: Math.max(0, root.activePlayer?.length ?? 0)
    readonly property string hoverTimeText: root.formatClockTime(root.currentDateTime)
    readonly property string hoverDateText: root.formatClockDate(root.currentDateTime)
    readonly property bool mediaAvailable: root.liveLinksEnabled && root.hasActiveMedia()
    readonly property bool mediaCanSeek: (root.activePlayer?.canSeek ?? false) && (root.activePlayer?.positionSupported ?? false) && root.mediaLength > 0

    function targetWidth() {
        switch (root.visualMode) {
        case "fastfetch":
            return root.fastfetchWidth;
        case "wallpaper":
            return root.wallpaperWidth;
        case "launcher":
            return root.launcherWidth;
        case "toast":
            return root.toastWidth;
        case "media":
        case "tray":
            return root.mediaWidth;
        default:
            if (root.interactionOpen)
                return root.peekWidth;
            return root.handleStyle === "strip" ? root.stripWidth : root.bumpWidth;
        }
    }

    function targetHeight() {
        switch (root.visualMode) {
        case "fastfetch":
            return root.fastfetchHeight;
        case "wallpaper":
            return root.wallpaperHeight;
        case "launcher":
            return island.launcherHeight + 20;
        case "toast":
            return root.toastHeight;
        case "media":
            return root.mediaHeight;
        case "tray":
            if (root.quickMenuOpen && root.quickMenuPage === "settings")
                return island.settingsHeight + 20;
            if (root.quickMenuOpen && root.quickMenuPage === "timer")
                return island.timerHeight + 20;
            if (root.quickMenuOpen && root.quickMenuPage === "calendar")
                return island.calendarHeight + 20;
            if (root.quickMenuOpen && root.quickMenuPage === "weather")
                return island.weatherHeight + 20;
            return root.mediaHeight;
        default:
            if (root.interactionOpen)
                return root.peekHeight;
            return root.handleStyle === "strip" ? root.stripHeight : root.bumpHeight;
        }
    }

    function targetY() {
        return root.visualMode === "idle" && !root.interactionOpen ? root.idleTopMargin : root.expandedTopMargin;
    }

    function hold(milliseconds) {
        collapseTimer.interval = milliseconds;
        collapseTimer.restart();
    }

    function keepInteractionOpen(prepareMedia) {
        hoverLeaveTimer.stop();
        root.pointerInside = true;

        if (prepareMedia)
            root.prepareHoverMedia();
    }

    function scheduleInteractionClose() {
        if (!root.pinnedOpen)
            hoverLeaveTimer.restart();
    }

    function boolFromIpc(value) {
        return value === true || value === "true" || value === "1" || value === "on" || value === "yes";
    }

    function pad2(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function formatClockTime(value) {
        const date = new Date(value);
        const hours24 = date.getHours();
        const hours12 = hours24 % 12 || 12;
        const period = hours24 >= 12 ? "PM" : "AM";

        return hours12 + ":" + root.pad2(date.getMinutes()) + " " + period;
    }

    function formatClockDate(value) {
        const date = new Date(value);
        const shortDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        const day = date.getDay();

        return root.pad2(date.getDate()) + "." + root.pad2(date.getMonth() + 1) + "." + date.getFullYear() + ", " + shortDays[day];
    }

    function showIdle() {
        collapseTimer.stop();
        root.mode = "idle";
        root.pinnedOpen = false;
        root.title = "Ready";

        if (root.liveLinksEnabled) {
            root.chooseActivePlayer(null);
            if (root.hasActiveMedia())
                root.syncMediaFields(root.activePlayer);
        }
    }

    function setHandleStyle(style) {
        if (style === "strip" || style === "bump")
            root.handleStyle = style;
    }

    function toggleHandleStyle() {
        root.handleStyle = root.handleStyle === "strip" ? "bump" : "strip";
    }

    function showMedia(trackTitle, trackArtist, isPlaying, trackArtUrl) {
        root.title = trackTitle || "Unknown track";
        root.artist = trackArtist || "Unknown artist";
        root.artUrl = trackArtUrl || "";
        root.playing = isPlaying;
        root.mode = "media";
        root.hold(6200);
    }

    function trackTitle(player) {
        return player?.trackTitle || "Unknown track";
    }

    function trackArtist(player) {
        return player?.trackArtist || player?.identity || "Unknown artist";
    }

    function trackArtUrl(player) {
        return player?.trackArtUrl || "";
    }

    function trackKey(player) {
        if (!player)
            return "";

        return [player.uniqueId || player.dbusName || "", root.trackTitle(player), root.trackArtist(player), player.isPlaying ? "playing" : "paused"].join("|");
    }

    function syncMediaFields(player) {
        if (!player)
            return;

        root.title = root.trackTitle(player);
        root.artist = root.trackArtist(player);
        root.artUrl = root.trackArtUrl(player);
        root.playing = player.isPlaying;
    }

    function hasActiveMedia() {
        const player = root.activePlayer;

        if (!player)
            return false;

        return player.isPlaying || root.trackTitle(player) !== "Unknown track";
    }

    function chooseActivePlayer(preferredPlayer) {
        const players = Mpris.players.values;

        if (preferredPlayer) {
            root.activePlayer = preferredPlayer;
            return;
        }

        for (let i = 0; i < players.length; i += 1) {
            if (players[i].isPlaying) {
                root.activePlayer = players[i];
                return;
            }
        }

        root.activePlayer = players.length > 0 ? players[0] : null;
    }

    function prepareHoverMedia() {
        if (!root.liveLinksEnabled)
            return;

        root.chooseActivePlayer(null);
        root.syncMediaFields(root.activePlayer);
    }

    function mediaPrevious() {
        if (root.activePlayer?.canGoPrevious)
            root.activePlayer.previous();
    }

    function mediaTogglePlaying() {
        const player = root.activePlayer;

        if (!player)
            return;

        if (player.canTogglePlaying) {
            player.togglePlaying();
        } else if (player.isPlaying && player.canPause) {
            player.pause();
        } else if (!player.isPlaying && player.canPlay) {
            player.play();
        }
    }

    function mediaNext() {
        if (root.activePlayer?.canGoNext)
            root.activePlayer.next();
    }

    function maybeShowMediaFromPlayer(preferredPlayer, force) {
        if (!root.liveLinksEnabled)
            return;

        root.chooseActivePlayer(preferredPlayer);
        const player = root.activePlayer;
        const key = root.trackKey(player);

        if (!player || !key)
            return;

        const keepMediaFieldsFresh = root.mode === "idle" || root.hoverMediaMode;

        if (keepMediaFieldsFresh)
            root.syncMediaFields(player);

        if (!root.liveLinksPrimed) {
            root.lastTrackKey = key;
            return;
        }

        if (force || key !== root.lastTrackKey) {
            root.lastTrackKey = key;
            root.trayMediaDismissed = false;
            if (keepMediaFieldsFresh)
                root.syncMediaFields(player);
        }
    }

    function mediaSeek(position) {
        const player = root.activePlayer;

        if (!player || !root.mediaCanSeek)
            return;

        player.position = Math.max(0, Math.min(root.mediaLength, Number(position)));
    }

    function primeLiveLinks() {
        root.chooseActivePlayer(null);
        root.syncMediaFields(root.activePlayer);
        root.lastTrackKey = root.trackKey(root.activePlayer);
        root.liveLinksPrimed = true;
    }

    function demo() {
        const step = root.demoStep % 2;
        root.demoStep += 1;

        if (step === 0) {
            root.showMedia("Subzero Signal", "Glacier FM", true);
        } else {
            root.showIdle();
        }
    }

    function focusedScreen() {
        const focusedMonitor = Hyprland.focusedMonitor;

        if (focusedMonitor) {
            for (let i = 0; i < Quickshell.screens.length; i += 1) {
                if (Quickshell.screens[i].name === focusedMonitor.name)
                    return Quickshell.screens[i];
            }
        }

        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function setLauncher(open) {
        if (root.launcherOpen === open)
            return;

        root.launcherOpen = open;
        root.setQuickMenu(false);

        if (open) {
            root.setWallpaper(false);
            root.showIdle();
            root.mediaHoverSuppressed = true;
        } else {
            root.mediaHoverSuppressed = false;
        }
    }

    function toggleLauncher() {
        root.setLauncher(!root.launcherOpen);
    }

    function setWallpaper(open) {
        if (root.wallpaperOpen === open)
            return;

        root.wallpaperOpen = open;
        root.setQuickMenu(false);

        if (open) {
            root.setFastfetch(false);
            root.setLauncher(false);
            root.showIdle();
            root.mediaHoverSuppressed = true;
        } else {
            root.mediaHoverSuppressed = false;
        }
    }

    function toggleWallpaperPicker() {
        root.setWallpaper(!root.wallpaperOpen);
    }

    function setFastfetch(open) {
        if (root.fastfetchOpen === open)
            return;

        root.fastfetchOpen = open;
        root.setQuickMenu(false);

        if (open) {
            root.setWallpaper(false);
            root.setLauncher(false);
            root.showIdle();
            root.mediaHoverSuppressed = true;
        } else {
            root.mediaHoverSuppressed = false;
        }
    }

    function toggleFastfetchPicker() {
        root.setFastfetch(!root.fastfetchOpen);
    }

    function setQuickMenu(open) {
        if (root.quickMenuOpen === open)
            return;

        root.quickMenuOpen = open;
        if (!open)
            root.quickMenuPage = "tray";
    }

    function toggleQuickMenu() {
        root.setQuickMenu(!root.quickMenuOpen);
    }

    function cycleQuickMenu(dir) {
        const pages = ["tray", "notifications", "settings"];
        let index = pages.indexOf(root.quickMenuPage);
        if (index < 0)
            index = 0;
        index = (index + dir + pages.length) % pages.length;
        root.quickMenuPage = pages[index];
    }

    function timerSet(totalSeconds) {
        if (root.timerRunning)
            return;

        const value = Math.round(Number(totalSeconds) || 0);
        root.timerTotalSeconds = Math.max(1, value);
        root.timerRemainingSeconds = root.timerTotalSeconds;
    }

    function timerAdjust(deltaSeconds) {
        if (root.timerRunning)
            return;

        root.timerTotalSeconds = Math.max(1, root.timerTotalSeconds + Math.round(Number(deltaSeconds) || 0));
        root.timerRemainingSeconds = root.timerTotalSeconds;
    }

    function timerStartPause() {
        if (root.timerTotalSeconds <= 0)
            return;

        root.timerRunning = !root.timerRunning;
    }

    function timerReset() {
        root.timerRunning = false;
        root.timerRemainingSeconds = root.timerTotalSeconds;
    }

    function timerTick() {
        if (!root.timerRunning)
            return;

        if (root.timerRemainingSeconds <= 1) {
            root.timerRemainingSeconds = 0;
            root.timerRunning = false;

            notifStore.toastQueue.push({
                key: "timer-done",
                appName: "Timer",
                appIcon: "",
                summary: "Time's up!",
                body: "",
                image: "",
                critical: false,
                time: Date.now()
            });
            notifStore.nextToast();
            root.timerTotalSeconds = 0;
            root.timerRemainingSeconds = 0;
        } else {
            root.timerRemainingSeconds -= 1;
        }
    }

    function syncQuickMenuGrab() {
        quickMenuFocusGrab.active = root.quickMenuOpen || root.hoverMediaMode;
    }

    Component.onCompleted: root.syncQuickMenuGrab()

    Timer {
        id: collapseTimer
        repeat: false
        onTriggered: root.showIdle()
    }

    Timer {
        id: hoverLeaveTimer
        interval: 140
        repeat: false
        onTriggered: root.pointerInside = false
    }

    Timer {
        id: demoLoopTimer
        interval: 2600
        repeat: true
        running: root.demoRunning
        onTriggered: root.demo()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.currentDateTime = new Date()
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visualMode === "media" && root.activePlayer !== null
        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged();
            root.syncMediaFields(root.activePlayer);
        }
    }

    Timer {
        id: timerTickTimer

        interval: 1000
        repeat: true
        running: root.timerRunning
        onTriggered: root.timerTick()
    }

    Timer {
        id: liveLinkPrimeTimer
        interval: 900
        repeat: false
        running: true
        onTriggered: root.primeLiveLinks()
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: {
                root.trayMediaDismissed = false;
                root.maybeShowMediaFromPlayer(modelData, false);
            }

            function onPlaybackStateChanged() {
                root.maybeShowMediaFromPlayer(modelData, false);
            }

            function onPostTrackChanged() {
                root.maybeShowMediaFromPlayer(modelData, true);
            }
        }
    }

    onMediaAvailableChanged: {
        if (root.mediaAvailable)
            root.trayMediaDismissed = false;
    }

    onHoverMediaModeChanged: {
        root.syncQuickMenuGrab();

        if (!root.hoverMediaMode)
            root.setQuickMenu(false);
    }

    onSniMenuOpenChanged: root.syncQuickMenuGrab()

    onQuickMenuOpenChanged: root.syncQuickMenuGrab()

    Notifications {
        id: notifStore
    }

    Timer {
        id: toastTimer

        interval: root.toastHoldMs
        repeat: false
        onTriggered: notifStore.ackToast()
    }

    Connections {
        target: notifStore

        function onCurrentToastChanged() {
            toastTimer.stop();

            if (root.toastActive && !notifStore.currentToast.critical)
                toastTimer.start();
        }
    }

    PanelWindow {
        id: islandWindow

        screen: root.focusedScreen()
        color: "transparent"
        exclusiveZone: root.reservedZone
        exclusionMode: ExclusionMode.Normal
        implicitHeight: Math.max(root.windowHeight, island.height + 14)
        visible: true

        WlrLayershell.namespace: "dynamic-island"
        WlrLayershell.layer: root.visualMode === "toast" ? WlrLayer.Overlay : WlrLayer.Top

        anchors {
            top: true
            left: true
            right: true
        }

        mask: Region {
            item: interactionMask
        }

        Item {
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (!root.launcherOpen && !root.wallpaperOpen && !root.fastfetchOpen && !root.sniMenuOpen && !root.quickMenuOpen) {
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                        root.toggleQuickMenu();
                        event.accepted = true;
                    }
                }
            }

            Item {
                id: interactionMask

                readonly property real maskPadding: 8
                readonly property bool trayLeftVisible: trayLeft.visible && trayLeft.opacity > 0
                readonly property bool trayRightVisible: trayRight.visible && trayRight.opacity > 0
                readonly property real islandRightEdge: island.x + island.width
                readonly property real islandBottomEdge: island.y + island.height
                readonly property real trayRightEdge: trayRightVisible ? trayRight.x + trayRight.width : islandRightEdge
                readonly property real trayLeftEdge: trayLeftVisible ? trayLeft.x : island.x
                readonly property real leftEdge: Math.min(island.x, trayLeftEdge)
                readonly property real rightEdge: Math.max(islandRightEdge, trayRightEdge)
                readonly property real bottomEdge: Math.max(islandBottomEdge, trayRightVisible ? trayRight.y + trayRight.height : islandBottomEdge)

                x: Math.max(0, leftEdge - maskPadding)
                y: Math.max(0, island.y - maskPadding)
                width: Math.min(parent.width - x, rightEdge - x + maskPadding)
                height: Math.min(parent.height - y, bottomEdge - y + maskPadding)
            }

            Surface {
                id: island

                anchors.horizontalCenter: parent.horizontalCenter
                y: root.targetY()
                width: root.targetWidth()
                height: root.targetHeight()
                mode: root.visualMode
                handleStyle: root.handleStyle
                forceExpanded: root.interactionOpen
                quickMenuPage: root.quickMenuPage
                notifStore: notifStore
                title: root.title
                artist: root.artist
                artUrl: root.artUrl
                playing: root.playing
                canGoPrevious: root.mediaCanGoPrevious
                canTogglePlaying: root.mediaCanTogglePlaying
                canGoNext: root.mediaCanGoNext
                canSeek: root.mediaCanSeek
                mediaPosition: root.mediaPosition
                mediaLength: root.mediaLength
                mediaAvailable: root.mediaAvailable
                timerActive: root.timerActive
                timerRemaining: root.timerRemaining
                timerTotal: root.timerTotal
                timerRunning: root.timerRunning
                onSetTotalRequested: seconds => root.timerSet(seconds)
                onAdjustRequested: delta => root.timerAdjust(delta)
                onStartPauseRequested: root.timerStartPause()
                onResetRequested: root.timerReset()
                fontFamily: root.fontFamily
                timeText: root.hoverTimeText
                dateText: root.hoverDateText
                calendarDate: root.currentDateTime
                onPreviousRequested: root.mediaPrevious()
                onPlayPauseRequested: root.mediaTogglePlaying()
                onNextRequested: root.mediaNext()
                onDismissRequested: {
                    root.mediaHoverSuppressed = true;
                    root.showIdle();
                }
                onSeekRequested: position => root.mediaSeek(position)
                onHandleStyleRequested: style => root.setHandleStyle(style)
                onTrayCloseRequested: root.setQuickMenu(false)
                onLauncherCloseRequested: root.setLauncher(false)
                onWallpaperCloseRequested: root.setWallpaper(false)
                onFastfetchCloseRequested: root.setFastfetch(false)
            }

            HyprlandFocusGrab {
                id: launcherFocusGrab

                active: root.launcherOpen
                windows: [islandWindow]
                onCleared: root.setLauncher(false)
            }

            HyprlandFocusGrab {
                id: wallpaperFocusGrab

                active: root.wallpaperOpen
                windows: [islandWindow]
                onCleared: root.setWallpaper(false)
            }

            HyprlandFocusGrab {
                id: fastfetchFocusGrab

                active: root.fastfetchOpen
                windows: [islandWindow]
                onCleared: root.setFastfetch(false)
            }

            HyprlandFocusGrab {
                id: quickMenuFocusGrab

                windows: [islandWindow]
                onCleared: root.syncQuickMenuGrab()
            }

            Item {
                id: quickMenuKeys

                focus: (root.quickMenuOpen || root.hoverMediaMode) && !root.sniMenuOpen
                visible: (root.quickMenuOpen || root.hoverMediaMode) && !root.sniMenuOpen
                Keys.onLeftPressed: root.cycleQuickMenu(-1)
                Keys.onRightPressed: root.cycleQuickMenu(1)
                Keys.onEscapePressed: root.setQuickMenu(false)
            }


            Row {
                id: trayLeft

                z: 30
                x: island.x - width - 8
                y: island.y + Math.max(0, (island.height - height) / 2)
                spacing: 6
                opacity: root.trayVisible ? 1 : 0
                visible: opacity > 0

                Workspace {
                    active: root.trayVisible
                    workspace: root.currentWorkspace
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }


            Row {
                id: trayRight

                z: 30
                x: island.x + island.width + 8
                y: island.y + Math.max(0, (island.height - height) / 2)
                spacing: 6
                opacity: root.trayVisible ? 1 : 0
                visible: opacity > 0

                Audio {
                    active: root.trayVisible && root.mediaAvailable
                    playing: root.playing
                    dismissed: root.trayMediaDismissed
                    onClicked: root.trayMediaDismissed = true
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: islandHitbox
                z: 20
                anchors.horizontalCenter: island.horizontalCenter
                y: island.y
                width: island.width
                height: root.mode === "idle" && !root.interactionOpen ? Math.max(root.reservedZone, island.height) : island.height
                hoverEnabled: true
                enabled: root.visualMode !== "launcher" && root.visualMode !== "wallpaper" && root.visualMode !== "fastfetch"
                acceptedButtons: root.visualMode === "toast" ? Qt.LeftButton : (root.visualMode === "media" || root.interactionOpen ? Qt.NoButton : Qt.LeftButton)
                cursorShape: Qt.PointingHandCursor

                onEntered: root.keepInteractionOpen(true)
                onExited: {
                    root.mediaHoverSuppressed = false
                    root.scheduleInteractionClose()
                }
                onClicked: {
                    if (root.visualMode === "toast") {
                        notifStore.ackToast()
                    } else if (root.mode === "idle" && !root.launcherOpen) {
                        root.pinnedOpen = !root.pinnedOpen
                    } else {
                        root.showIdle()
                    }
                }


                onWheel: function(wheel) {
                    if (wheel.angleDelta.y > 0) {

                        if (root.mode === "idle" && !root.quickMenuOpen) {
                            root.toggleQuickMenu()
                        } else if (root.quickMenuOpen && root.quickMenuPage === "tray") {
                            root.quickMenuPage = "notifications"
                        } else if (root.quickMenuOpen && root.quickMenuPage === "notifications") {
                            const handled = island.notifScroll(1)
                            if (!handled)
                                root.quickMenuPage = "settings"
                        } else if (root.quickMenuOpen && root.quickMenuPage === "settings") {
                            root.quickMenuPage = "tray"
                        }
                    } else {

                        if (root.quickMenuOpen && root.quickMenuPage === "notifications") {
                            const handled = island.notifScroll(-1)
                            if (!handled)
                                root.quickMenuPage = "tray"
                        } else if (root.quickMenuOpen && root.quickMenuPage === "settings") {
                            root.quickMenuPage = "notifications"
                        } else if (root.quickMenuOpen) {
                            root.setQuickMenu(false)
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "island"

        function idle(): void {
            root.showIdle();
        }

        function handle(style: string): void {
            root.setHandleStyle(style);
        }

        function toggleHandle(): void {
            root.toggleHandleStyle();
        }

        function live(enabled: string): void {
            root.liveLinksEnabled = root.boolFromIpc(enabled);
        }

        function media(trackTitle: string, trackArtist: string, isPlaying: string, artUrl: string): void {
            root.showMedia(trackTitle, trackArtist, root.boolFromIpc(isPlaying) || isPlaying === "playing", artUrl);
        }

        function demo(): void {
            root.demo();
        }

        function demoLoop(): void {
            root.demoRunning = !root.demoRunning;
            if (root.demoRunning)
                root.demo();
        }

        function toggleLauncher(): void {
            root.toggleLauncher();
        }

        function toggleWallpaperPicker(): void {
            root.toggleWallpaperPicker();
        }

        function toggleFastfetchPicker(): void {
            root.toggleFastfetchPicker();
        }

        function toggleQuickMenu(): void {
            root.toggleQuickMenu();
        }
    }

    IpcHandler {
        target: "dynamic-island"

        function toggleLauncher(): void {
            root.toggleLauncher();
        }

        function toggleWallpaperPicker(): void {
            root.toggleWallpaperPicker();
        }

        function toggleFastfetchPicker(): void {
            root.toggleFastfetchPicker();
        }

        function toggleQuickMenu(): void {
            root.toggleQuickMenu();
        }

        function setTimerPage(): void {
            root.setQuickMenu(true);
            root.quickMenuPage = "timer";
        }

        function setCalendarPage(): void {
            root.setQuickMenu(true);
            root.quickMenuPage = "calendar";
        }

        function toggleWeather(): void {
            if (root.quickMenuOpen && root.quickMenuPage === "weather") {
                root.setQuickMenu(false);
            } else {
                root.setQuickMenu(true);
                root.quickMenuPage = "weather";
            }
        }

        function startTimer(minutes: string): void {
            root.timerSet((Number(minutes) || 1) * 60);
            root.timerStartPause();
        }

        function toggleTimer(): void {
            root.timerStartPause();
        }
    }
}

