import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

ShellRoot {
    id: root

    Timer {
        id: pamActionTimer
        interval: 50
        onTriggered: pam.start()
    }

    // ─── POWER ACTION PROCESS ──────────────────────────────────────
    // Using a tracked Process instead of Quickshell.execDetached() so
    // failures are actually visible (run quickshell from a terminal to
    // see this output) instead of silently doing nothing.
    Process {
        id: powerActionProc

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) console.log("[power] stdout:", text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0) console.log("[power] stderr:", text);
            }
        }
        onExited: (exitCode, exitStatus) => {
            console.log("[power] '" + command.join(" ") + "' exited with code " + exitCode + " (status " + exitStatus + ")");
        }

        function run(cmd) {
            command = cmd;
            running = true;
        }
    }

    QtObject {
        id: lockUI
        property bool failed: false
        property bool authenticating: false
        property string statusText: "Locked"
        property bool powerMenuOpen: false
        property int armedPowerIndex: -1
    }

    PamContext {
        id: pam
        Component.onCompleted: pamActionTimer.start()

        onCompleted: (result) => {
            lockUI.authenticating = false;
            if (result === PamResult.Success) {
                rootLock.locked = false;
                Qt.quit();
            } else {
                lockUI.failed = true;
                lockUI.statusText = "Access Denied";
                pamActionTimer.start();
            }
        }
    }

    WlSessionLock {
        id: rootLock
        locked: true

        WlSessionLockSurface {
            Item {
                id: screenRoot
                anchors.fill: parent

                readonly property real sc: Math.max(0.5, Math.min(2.0, (screenRoot.width > 0 ? screenRoot.width : 1920) / 1920))
                readonly property string wallpaperPath: "file:///home/nrxg/.config/hypr/current_wallpaper"
                readonly property color textColor: "#f2f2f2"
                readonly property color subTextColor: "#9a9a9a"
                readonly property color accent: "#7aa2f7"
                readonly property color errorColor: "#f7768e"

                // ─── GLOW REMOVAL ──────────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                }

                Image {
                    id: bgWallpaper
                    anchors.fill: parent
                    source: screenRoot.wallpaperPath
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    visible: false
                }

                MultiEffect {
                    source: bgWallpaper
                    anchors.fill: parent
                    blurEnabled: true
                    blurMax: 64 * screenRoot.sc
                    blur: 1.0
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.3
                }

                // ─── POWER BUTTON ──────────────────────────────────────────
                Item {
                    id: powerButton
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.margins: 20 * screenRoot.sc
                    width: 42 * screenRoot.sc
                    height: 42 * screenRoot.sc
                    z: 10

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: powerMouse.containsMouse
                        ? Qt.rgba(1, 1, 1, 0.20)
                        : Qt.rgba(1, 1, 1, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.25)
                        Behavior on color {
                            ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        color: screenRoot.textColor
                        font.family: "Maple Mono NF"
                        font.pixelSize: 20 * screenRoot.sc
                        opacity: powerMouse.containsMouse ? 1.0 : 0.7
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            lockUI.powerMenuOpen = !lockUI.powerMenuOpen;
                            if (!lockUI.powerMenuOpen) lockUI.armedPowerIndex = -1;
                        }
                    }

                    // ─── POWER POPUP ──────────────────────────────────────
                    Item {
                        id: powerPopup
                        anchors.bottom: powerButton.top
                        anchors.bottomMargin: 10 * screenRoot.sc
                        anchors.right: powerButton.right
                        width: Math.max(140 * screenRoot.sc, popupColumn.implicitWidth + 16 * screenRoot.sc)
                        height: popupColumn.implicitHeight + 16 * screenRoot.sc
                        visible: lockUI.powerMenuOpen
                        opacity: visible ? 1 : 0
                        scale: visible ? 1 : 0.9

                        Behavior on opacity {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                        }

                        // Glass background
                        Rectangle {
                            anchors.fill: parent
                            radius: 12 * screenRoot.sc
                            color: Qt.rgba(0, 0, 0, 0.75)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.20)
                        }

                        // ── OUTSIDE‑CLICK AREA (placed first so it's behind the options) ──
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -20 * screenRoot.sc
                            visible: lockUI.powerMenuOpen
                            propagateComposedEvents: true
                            onClicked: {
                                lockUI.powerMenuOpen = false;
                                lockUI.armedPowerIndex = -1;
                                mouse.accepted = false;
                            }
                        }

                        // ── OPTIONS ──────────────────────────────────────
                        Column {
                            id: popupColumn
                            anchors.fill: parent
                            anchors.margins: 8 * screenRoot.sc
                            spacing: 4 * screenRoot.sc

                            Repeater {
                                model: [
                                    { label: "Suspend", cmd: ["systemctl", "suspend"] },
                                    { label: "Restart",  cmd: ["systemctl", "reboot"] },
                                    { label: "Shutdown", cmd: ["systemctl", "poweroff"] }
                                ]

                                delegate: Rectangle {
                                    id: optionDelegate
                                    width: parent.width
                                    height: 32 * screenRoot.sc
                                    radius: 6 * screenRoot.sc

                                    readonly property bool armed: lockUI.armedPowerIndex === index

                                    color: armed
                                    ? Qt.rgba(0.97, 0.47, 0.56, 0.25)
                                    : (mouseArea.containsMouse
                                    ? Qt.rgba(1, 1, 1, 0.15)
                                    : "transparent")

                                    border.width: armed ? 1.5 * screenRoot.sc : 0
                                    border.color: armed ? screenRoot.errorColor : "transparent"

                                    Behavior on color {
                                        ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                                    }
                                    Behavior on border.color {
                                        ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: armed ? "Confirm" : modelData.label
                                        color: armed ? screenRoot.errorColor : screenRoot.textColor
                                        font.family: "Maple Mono NF"
                                        font.pixelSize: 13 * screenRoot.sc
                                        font.weight: armed ? Font.Bold : Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (armed) {
                                                powerActionProc.run(modelData.cmd);
                                                lockUI.powerMenuOpen = false;
                                                lockUI.armedPowerIndex = -1;
                                            } else {
                                                lockUI.armedPowerIndex = index;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ─── MAIN UI ──────────────────────────────────────────────
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        lockUI.failed = false;
                        lockUI.statusText = "Locked";
                        inputField.forceActiveFocus();
                        lockUI.powerMenuOpen = false;
                        lockUI.armedPowerIndex = -1;
                    }
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -30 * screenRoot.sc
                    spacing: 12 * screenRoot.sc

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4 * screenRoot.sc

                        Text {
                            id: clockHours
                            font.family: "Maple Mono NF"
                            font.pixelSize: 150 * screenRoot.sc
                            font.weight: Font.Bold
                            color: screenRoot.textColor
                        }
                        Text {
                            text: ":"
                            font.family: "Maple Mono NF"
                            font.pixelSize: 150 * screenRoot.sc
                            font.weight: Font.Bold
                            opacity: 0.5
                            color: screenRoot.textColor
                        }
                        Text {
                            id: clockMinutes
                            font.family: "Maple Mono NF"
                            font.pixelSize: 150 * screenRoot.sc
                            font.weight: Font.Bold
                            color: screenRoot.textColor
                        }
                    }

                    Text {
                        id: dateText
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: "Maple Mono NF"
                        font.pixelSize: 22 * screenRoot.sc
                        font.weight: Font.Bold
                        color: screenRoot.textColor
                    }

                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            const d = new Date();
                            clockHours.text = Qt.formatDateTime(d, "HH");
                            clockMinutes.text = Qt.formatDateTime(d, "mm");
                            dateText.text = Qt.formatDateTime(d, "dddd, MMMM dd");
                        }
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 160 * screenRoot.sc
                    spacing: 26 * screenRoot.sc

                    // ─── GLASS PASSWORD PILL ─────────────────────────────
                    Rectangle {
                        id: pinPill
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 320 * screenRoot.sc
                        height: 62 * screenRoot.sc
                        radius: height / 2
                        clip: true

                        color: lockUI.failed
                        ? Qt.rgba(0.97, 0.47, 0.56, 0.20)
                        : Qt.rgba(1, 1, 1, 0.12)

                        border.width: Math.max(1, 1.5 * screenRoot.sc)
                        border.color: {
                            if (lockUI.failed) return screenRoot.errorColor;
                            if (lockUI.authenticating) return screenRoot.accent;
                            if (inputField.text.length > 0) return Qt.rgba(1, 1, 1, 0.7);
                            return Qt.rgba(1, 1, 1, 0.30);
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.width: 2 * screenRoot.sc
                            border.color: Qt.rgba(1, 1, 1, 0.05)
                        }

                        Behavior on color {
                            ColorAnimation { duration: 250; easing.type: Easing.OutExpo }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: 250; easing.type: Easing.OutExpo }
                        }

                        transform: Translate {
                            id: shakeTranslate
                            x: 0
                        }

                        SequentialAnimation {
                            id: shakeAnim
                            NumberAnimation {
                                target: shakeTranslate
                                property: "x"
                                from: 0
                                to: -8 * screenRoot.sc
                                duration: 120
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: shakeTranslate
                                property: "x"
                                from: -8 * screenRoot.sc
                                to: 8 * screenRoot.sc
                                duration: 120
                                easing.type: Easing.InOutSine
                            }
                            NumberAnimation {
                                target: shakeTranslate
                                property: "x"
                                from: 8 * screenRoot.sc
                                to: 0
                                duration: 120
                                easing.type: Easing.InOutSine
                            }
                        }

                        Connections {
                            target: lockUI
                            function onFailedChanged() {
                                if (lockUI.failed) shakeAnim.restart();
                            }
                        }

                        TextInput {
                            id: inputField
                            anchors.fill: parent
                            anchors.leftMargin: 28 * screenRoot.sc
                            anchors.rightMargin: 28 * screenRoot.sc
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "\u2022"
                            color: screenRoot.textColor
                            font.family: "Maple Mono NF"
                            font.pixelSize: 26 * screenRoot.sc
                            font.weight: Font.Bold

                            Component.onCompleted: forceActiveFocus()

                            onActiveFocusChanged: {
                                if (!activeFocus) forceActiveFocus();
                            }

                            onAccepted: {
                                if (text.length > 0 && pam.responseRequired && !lockUI.authenticating) {
                                    lockUI.authenticating = true;
                                    lockUI.statusText = "Authenticating...";
                                    lockUI.failed = false;
                                    pam.respond(text);
                                    text = "";
                                }
                            }

                            onTextChanged: {
                                if (lockUI.authenticating) return;

                                if (text.length > 0) {
                                    lockUI.failed = false;
                                    lockUI.statusText = "Enter Password";
                                } else if (!lockUI.failed) {
                                    lockUI.statusText = "Locked";
                                }
                            }

                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Escape) {
                                    text = "";
                                    lockUI.failed = false;
                                    lockUI.statusText = "Locked";
                                    event.accepted = true;
                                }
                            }
                        }
                    }

                    // ─── GLASS STATUS PILL ──────────────────────────────
                    Item {
                        id: statusPill
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: statusText.implicitWidth + 26 * screenRoot.sc
                        implicitHeight: statusText.implicitHeight + 10 * screenRoot.sc

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.15)
                        }

                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: lockUI.statusText.toUpperCase()
                            font.family: "Maple Mono NF"
                            font.pixelSize: 14 * screenRoot.sc
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                            color: lockUI.failed
                            ? screenRoot.errorColor
                            : (lockUI.authenticating
                            ? screenRoot.accent
                            : (inputField.text.length > 0 ? screenRoot.textColor : screenRoot.subTextColor))

                            Behavior on color {
                                ColorAnimation { duration: 250 }
                            }

                            SequentialAnimation on opacity {
                                running: lockUI.authenticating
                                loops: Animation.Infinite
                                NumberAnimation {
                                    from: 0.55
                                    to: 1.0
                                    duration: 650
                                    easing.type: Easing.InOutQuad
                                }
                                NumberAnimation {
                                    from: 1.0
                                    to: 0.55
                                    duration: 650
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
