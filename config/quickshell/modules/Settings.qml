import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire


Item {
    id: root

    required property string fontFamily
    required property bool dnd

    signal closeRequested()
    signal dndToggleRequested(bool value)

    readonly property real padding: 12
    readonly property real headerHeight: 16
    readonly property real rowHeight: 34
    readonly property real sliderRowHeight: 50
    readonly property real rowSpacing: 5


    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property var audioNode: root.audioSink ? root.audioSink.audio : null
    readonly property real audioPercent: root.audioNode ? Math.round((Number(root.audioNode.volume) || 0) * 100) : 0

    PwObjectTracker {
        objects: root.audioSink ? [root.audioSink] : []
    }


    property string wifiSsid: ""
    property int wifiSignal: 0


    property bool btHasAdapter: false
    property int btConnected: 0


    readonly property var battery: UPower.displayDevice
    readonly property bool batteryVisible: root.battery ? (root.battery.isPresent || false) : false


    property bool brightnessVisible: false
    property string brightnessPath: ""

    readonly property int visibleRows: 3 + (root.batteryVisible ? 1 : 0) + (root.brightnessVisible ? 1 : 0)
    readonly property real contentHeight:
        root.headerHeight +
        (root.rowHeight + root.rowSpacing) * 3 +
        (root.batteryVisible ? root.rowHeight + root.rowSpacing : 0) +
        root.sliderRowHeight +
        (root.brightnessVisible ? root.rowSpacing + root.sliderRowHeight : 0) +
        root.padding * 2

    implicitHeight: root.contentHeight
    implicitWidth: 400

    property var bluetoothAdapter: Bluetooth.defaultAdapter

    function readFile(path) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + path, false);
        xhr.send();
        if (xhr.status !== 0 && xhr.status !== 200)
            return "";
        return String(xhr.responseText || "").trim();
    }

    function probeBrightness() {
        const names = ["intel_backlight", "amdgpu_bl0", "amdgpu_bl1", "acpi_video0", "nv_backlight", "backlight"];
        for (const n of names) {
            const p = "/sys/class/backlight/" + n + "/max_brightness";
            const v = root.readFile(p);
            if (v && parseInt(v, 10) > 0) {
                root.brightnessPath = "/sys/class/backlight/" + n;
                root.brightnessVisible = true;
                return;
            }
        }
        root.brightnessPath = "";
        root.brightnessVisible = false;
    }

    function brightnessMax() {
        if (!root.brightnessPath)
            return 1;
        return parseInt(root.readFile(root.brightnessPath + "/max_brightness"), 10) || 1;
    }

    function brightnessCurrent() {
        if (!root.brightnessPath)
            return 0;
        const cur = parseInt(root.readFile(root.brightnessPath + "/brightness"), 10) || 0;
        const max = root.brightnessMax();
        return max > 0 ? Math.round(cur / max * 100) : 0;
    }

    function setBrightness(pct) {
        if (!root.brightnessPath)
            return;
        const max = root.brightnessMax();
        const target = Math.max(1, Math.min(max, Math.round(pct / 100 * max)));
        Quickshell.execDetached(["bash", "-c", 'printf \'%d\' "' + target + '" > "' + root.brightnessPath + '/brightness"']);
    }

    function wifiIcon() {
        if (!Networking.wifiHardwareEnabled || !Networking.wifiEnabled)
            return "wifi_off";
        return "wifi";
    }

    function refreshWifi() {
        let ssid = "";
        let sig = 0;
        const devices = (Networking.devices && Networking.devices.values) || [];
        for (const d of devices) {
            if (!d || !d.networks)
                continue;
            const networks = d.networks.values || [];
            for (const n of networks) {
                if (n && n.connected) {
                    ssid = String(n.name || n.ssid || "");
                    sig = Number(n.signalStrength) || 0;
                }
            }
        }
        root.wifiSsid = ssid;
        root.wifiSignal = sig;
    }

    function wifiDetail() {
        if (!Networking.wifiHardwareEnabled)
            return "No wifi device";
        if (!Networking.wifiEnabled)
            return "Off";
        return root.wifiSsid ? root.wifiSsid + " \u00b7 " + root.wifiSignal + "%" : "On";
    }

    function setWifiEnabled(value) {
        if (Networking.wifiHardwareEnabled)
            Networking.wifiEnabled = value;
    }

    function bluetoothIcon() {
        if (!root.btHasAdapter)
            return "bluetooth_disabled";
        if (root.btHasAdapter && bluetoothAdapter && bluetoothAdapter.enabled)
            return "bluetooth_connected";
        return "bluetooth";
    }

    function refreshBluetooth() {
        const adapter = Bluetooth.defaultAdapter;
        root.btHasAdapter = !!adapter;
        if (root.btHasAdapter) {
            const devices = (adapter.devices && adapter.devices.values) || [];
            const conn = devices.filter(d => d && d.connected).length;
            root.btConnected = conn;
        } else {
            root.btConnected = 0;
        }
    }

    function bluetoothDetail() {
        if (!root.btHasAdapter)
            return "No adapter";
        if (!bluetoothAdapter.enabled)
            return "Off";
        return root.btConnected > 0 ? "On \u00b7 " + root.btConnected + " connected" : "On";
    }

    function setBluetoothEnabled(value) {
        if (root.btHasAdapter)
            bluetoothAdapter.enabled = value;
    }

    function batteryStateText() {
        if (!root.battery)
            return "";
        switch (root.battery.state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.FullyCharged:
            return "Fully Charged";
        case UPowerDeviceState.Discharging:
            return "Discharging";
        default:
            return "Battery";
        }
    }

    function audioIcon() {
        if (!root.audioNode)
            return "volume_off";
        if (root.audioNode.muted)
            return "volume_off";
        if (root.audioPercent < 2)
            return "volume_mute";
        if (root.audioPercent < 50)
            return "volume_down";
        return "volume_up";
    }

    onVisibleChanged: {
        if (root.visible) {
            root.refreshWifi();
            root.refreshBluetooth();
            root.probeBrightness();
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: root.visible
        onTriggered: {
            root.refreshWifi();
            root.refreshBluetooth();
        }
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
                text: "System"
                color: "#9a9a9a"
                font.family: root.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                text: String(root.visibleRows)
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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: root.rowSpacing


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.rowHeight
                radius: 8
                color: dndMouse.containsMouse ? "#151515" : "#090909"
                border.width: 1
                border.color: dndMouse.containsMouse ? "#262626" : "#232323"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    MIcon {
                        name: root.dnd ? "do_not_disturb_on" : "notifications_off"
                        size: 17
                        color: root.dnd ? "#ff9f1c" : "#7a7a7a"
                    }

                    Text {
                        text: "Do Not Disturb"
                        color: "#e6e6e6"
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: root.dnd ? "On" : "Off"
                        color: root.dnd ? "#ff9f1c" : "#9a9a9a"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    ToggleSwitch {
                        checked: root.dnd
                        onToggled: value => root.dndToggleRequested(value)
                    }
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.dndToggleRequested(!root.dnd)
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.rowHeight
                radius: 8
                color: wifiMouse.containsMouse ? "#151515" : "#090909"
                border.width: 1
                border.color: wifiMouse.containsMouse ? "#262626" : "#232323"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    MIcon {
                        name: root.wifiIcon()
                        size: 17
                        color: Networking.wifiEnabled ? "#f5f5f5" : "#7a7a7a"
                    }

                    Text {
                        text: "Wifi"
                        color: "#e6e6e6"
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: root.wifiDetail()
                        color: "#9a9a9a"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    ToggleSwitch {
                        checked: Networking.wifiEnabled
                        enabled: Networking.wifiHardwareEnabled
                        onToggled: value => root.setWifiEnabled(value)
                    }
                }

                MouseArea {
                    id: wifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Networking.wifiHardwareEnabled)
                            root.setWifiEnabled(!Networking.wifiEnabled);
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.rowHeight
                radius: 8
                color: btMouse.containsMouse ? "#151515" : "#090909"
                border.width: 1
                border.color: btMouse.containsMouse ? "#262626" : "#232323"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    MIcon {
                        name: root.bluetoothIcon()
                        size: 17
                        color: root.btHasAdapter && bluetoothAdapter && bluetoothAdapter.enabled ? "#f5f5f5" : "#7a7a7a"
                    }

                    Text {
                        text: "Bluetooth"
                        color: "#e6e6e6"
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: root.bluetoothDetail()
                        color: "#9a9a9a"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    ToggleSwitch {
                        checked: root.btHasAdapter && bluetoothAdapter ? bluetoothAdapter.enabled : false
                        enabled: root.btHasAdapter
                        onToggled: value => root.setBluetoothEnabled(value)
                    }
                }

                MouseArea {
                    id: btMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.btHasAdapter)
                            root.setBluetoothEnabled(!bluetoothAdapter.enabled);
                    }
                }
            }


            Rectangle {
                visible: root.batteryVisible
                Layout.fillWidth: true
                Layout.preferredHeight: root.rowHeight
                radius: 8
                color: "#090909"
                border.width: 1
                border.color: "#232323"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 10

                    MIcon {
                        name: root.battery && root.battery.state === UPowerDeviceState.Charging ? "battery_charging_full" : "battery_full"
                        size: 17
                        color: "#f5f5f5"
                    }

                    Text {
                        text: "Battery"
                        color: "#e6e6e6"
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(root.battery ? (root.battery.percentage || 0) : 0) + "% \u00b7 " + root.batteryStateText()
                        color: "#9a9a9a"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.sliderRowHeight
                radius: 8
                color: "#090909"
                border.width: 1
                border.color: "#232323"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        Item {
                            width: 20
                            height: 20

                            MIcon {
                                anchors.centerIn: parent
                                name: root.audioIcon()
                                size: 17
                                color: root.audioNode && root.audioNode.muted ? "#7a7a7a" : "#f5f5f5"
                                opacity: root.audioNode ? 1 : 0.4
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.audioNode)
                                        root.audioNode.muted = !root.audioNode.muted;
                                }
                            }
                        }

                        Text {
                            text: "Audio"
                            color: "#e6e6e6"
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            text: root.audioNode ? root.audioPercent + "%" : "no device"
                            color: root.audioNode && root.audioNode.muted ? "#7a7a7a" : "#f0f0f0"
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    SliderTrack {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        Layout.bottomMargin: 4
                        value: root.audioNode ? (Number(root.audioNode.volume) || 0) : 0
                        enabled: !!root.audioNode
                        onUserChanged: v => {
                            if (root.audioNode) {
                                root.audioNode.volume = v;
                                root.audioNode.muted = false;
                            }
                        }
                    }
                }
            }


            Rectangle {
                visible: root.brightnessVisible
                Layout.fillWidth: true
                Layout.preferredHeight: root.sliderRowHeight
                radius: 8
                color: "#090909"
                border.width: 1
                border.color: "#232323"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        MIcon {
                            name: "brightness_high"
                            size: 17
                            color: "#f5f5f5"
                        }

                        Text {
                            text: "Brightness"
                            color: "#e6e6e6"
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            id: brightnessPct
                            text: root.brightnessCurrent() + "%"
                            color: "#f0f0f0"
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    SliderTrack {
                        id: brightnessSlider

                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        Layout.bottomMargin: 4
                        value: root.brightnessMax() > 0 ? root.brightnessCurrent() / root.brightnessMax() : 0
                        onUserChanged: v => {
                            root.setBrightness(v * 100);
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: brightnessTimer

        interval: 1500
        repeat: true
        running: root.brightnessVisible && root.visible
        onTriggered: {
            brightnessSlider.value = root.brightnessMax() > 0 ? root.brightnessCurrent() / root.brightnessMax() : 0;
            brightnessPct.text = root.brightnessCurrent() + "%";
        }
    }
}
