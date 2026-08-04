import QtQuick
import QtQuick.Layouts


Item {
    id: root

    required property string fontFamily

    property int totalSeconds: 0
    property int remainingSeconds: 0
    property bool running: false
    property string customText: ""
    property bool customInputActive: false

    signal setTotal(int seconds)
    signal adjust(int deltaSeconds)
    signal startPause
    signal resetRequest

    readonly property color accentColor: root.running ? "#ff9f1c" : "#8a8a8a"

    readonly property real padding: 12
    readonly property real headerHeight: 16
    readonly property real ringSize: 132
    readonly property real buttonHeight: 34
    readonly property real buttonSpacing: 8

    readonly property real contentHeight:
        root.padding +
        root.headerHeight +
        6 +
        root.ringSize +
        14 +
        30 +
        8 +
        26 +
        8 +
        26 +
        10 +
        root.buttonHeight +
        root.padding

    implicitHeight: root.contentHeight
    implicitWidth: 380

    function frac() {
        if (root.totalSeconds <= 0)
            return root.running ? 0 : 1;
        return Math.max(0, Math.min(1, root.remainingSeconds / root.totalSeconds));
    }

    function formatRingText() {
        const s = Math.max(0, root.remainingSeconds);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;

        if (h > 0)
            return String(h) + ":" + (m < 10 ? "0" + m : String(m)) + ":" + (sec < 10 ? "0" + sec : String(sec));
        return String(m) + ":" + (sec < 10 ? "0" + sec : String(sec));
    }

    function parseCustom(text) {
        const t = String(text).trim();

        if (t === "")
            return 0;

        let seconds = 0;

        if (t.includes(":")) {
            const parts = t.split(":");
            const m = parseInt(parts[0], 10) || 0;
            const s = parseInt(parts[1], 10) || 0;
            seconds = m * 60 + s;
        } else {
            seconds = Math.round((parseFloat(t) || 0) * 60);
        }

        return Math.max(1, seconds);
    }

    function commitCustom() {
        const seconds = root.parseCustom(root.customText);

        if (seconds <= 0)
            return;

        root.setTotal(seconds);
        root.customText = "";
        root.customInputActive = false;
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
                text: "Timer"
                color: "#9a9a9a"
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: root.running ? "running" : (root.totalSeconds > 0 ? "ready" : "set a time")
                color: "#6d6d6d"
                font.family: root.fontFamily
                font.pixelSize: 11
            }
        }


        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: root.ringSize
            Layout.preferredHeight: root.ringSize
            Layout.topMargin: 6

            Canvas {
                id: ring

                anchors.fill: parent

                onPaint: {
                    const ctx = ring.getContext("2d");
                    const w = ring.width;
                    const h = ring.height;
                    ctx.clearRect(0, 0, w, h);

                    const cx = w / 2;
                    const cy = h / 2;
                    const r = (Math.min(w, h) / 2) - 6;
                    const lineWidth = 6;

                    ctx.lineWidth = lineWidth;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = "#262626";
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                    ctx.stroke();

                    const f = root.frac();
                    if (f > 0.002) {
                        const start = -Math.PI / 2;
                        const end = start + 2 * Math.PI * f;
                        ctx.strokeStyle = root.accentColor;
                        ctx.beginPath();
                        ctx.arc(cx, cy, r, start, end);
                        ctx.stroke();
                    }
                }

                Connections {
                    target: root
                    function onRemainingSecondsChanged() {
                        ring.requestPaint();
                    }
                    function onTotalSecondsChanged() {
                        ring.requestPaint();
                    }
                    function onRunningChanged() {
                        ring.requestPaint();
                    }
                    function onAccentColorChanged() {
                        ring.requestPaint();
                    }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.formatRingText()
                    color: "#f5f5f5"
                    font.family: root.fontFamily
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.totalSeconds > 0
                    text: root.running ? "Remaining" : "Ready"
                    color: "#7f7f7f"
                    font.family: root.fontFamily
                    font.pixelSize: 10
                }
            }
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 6
            enabled: !root.running

            Repeater {
                model: ["1", "3", "5", "10", "30", "60"]

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 30
                    radius: 9
                    color: presets.containsMouse ? "#1a1a1a" : "#0b0b0b"
                    border.width: 1
                    border.color: "#262626"

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "m"
                        color: "#e6e6e6"
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: presets

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setTotal(parseInt(modelData, 10) * 60)
                    }
                }
            }
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 26
                radius: 8
                color: "#0b0b0b"
                border.width: 1
                border.color: customInput.activeFocus ? "#ff9f1c" : "#222222"
                enabled: !root.running

                TextInput {
                    id: customInput

                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: Text.AlignVCenter
                    color: "#e6e6e6"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    inputMethodHints: Qt.ImhPreferNumbers
                    enabled: !root.running
                    text: root.customText
                    onTextChanged: root.customText = customInput.text

                    onAccepted: root.commitCustom()

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            root.customText = "";
                            root.customInputActive = false;
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    enabled: false
                    visible: customInput.text === ""
                    verticalAlignment: Text.AlignVCenter
                    text: "custom (min or mm:ss)"
                    color: root.running ? "#3a3a3a" : "#6d6d6d"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.running
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        customInput.forceActiveFocus();
                        root.customInputActive = true;
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 26
                radius: 8
                color: customSet.containsMouse ? "#1a1a1a" : "#0b0b0b"
                border.width: 1
                border.color: "#222222"

                Text {
                    anchors.centerIn: parent
                    text: "Set"
                    color: root.running ? "#3a3a3a" : (root.customText !== "" ? "#ff9f1c" : "#6d6d6d")
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: customSet

                    anchors.fill: parent
                    enabled: !root.running && root.customText !== ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.commitCustom()
                }
            }
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 6

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 26
                radius: 8
                color: stepDown.containsMouse && !root.running ? "#1a1a1a" : "#0b0b0b"
                border.width: 1
                border.color: "#222222"

                Text {
                    anchors.centerIn: parent
                    text: "-1m"
                    color: root.running ? "#555555" : "#cfcfcf"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: stepDown

                    anchors.fill: parent
                    enabled: !root.running
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adjust(-60)
                }
            }

            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 26
                radius: 8
                color: stepUp.containsMouse && !root.running ? "#1a1a1a" : "#0b0b0b"
                border.width: 1
                border.color: "#222222"

                Text {
                    anchors.centerIn: parent
                    text: "+1m"
                    color: root.running ? "#555555" : "#cfcfcf"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: stepUp

                    anchors.fill: parent
                    enabled: !root.running
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adjust(60)
                }
            }

            Item { Layout.fillWidth: true }
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 10
                color: startMouse.containsMouse ? "#2a2a2a" : "#161616"
                border.width: 1
                border.color: root.totalSeconds > 0 ? "#ff9f1c" : "#2c2c2c"

                Text {
                    anchors.centerIn: parent
                    text: root.running ? "Pause" : "Start"
                    color: root.totalSeconds > 0 ? "#ff9f1c" : "#7f7f7f"
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: startMouse

                    anchors.fill: parent
                    enabled: root.totalSeconds > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startPause()
                }
            }

            Rectangle {
                Layout.preferredWidth: 96
                Layout.preferredHeight: 34
                radius: 10
                color: resetMouse.containsMouse ? "#1a1a1a" : "#0a0a0a"
                border.width: 1
                border.color: "#262626"

                Text {
                    anchors.centerIn: parent
                    text: "Reset"
                    color: "#b8b8b8"
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: resetMouse

                    anchors.fill: parent
                    enabled: root.totalSeconds > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetRequest()
                }
            }
        }
    }
}
