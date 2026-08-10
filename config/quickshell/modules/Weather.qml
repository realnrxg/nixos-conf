import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string fontFamily

    property double latitude: 0
    property double longitude: 0
    property string locationName: ""
    property string units: "metric"
    property bool autodetect: true

    property bool loading: false
    property string error: ""
    property string updatedLabel: ""

    property string currentIcon: "cloud"
    property string currentTemp: "—"
    property string currentCondition: "—"
    property string feelsLike: "—"
    property string humidity: "—"
    property string windSpeed: "—"
    property string precipitation: "—"
    property var daily: []

    readonly property color accent: "#ff9f1c"
    readonly property color textPrimary: "#f5f5f5"
    readonly property color textSecondary: "#9a9a9a"
    readonly property color textDim: "#6d6d6d"

    readonly property real padding: 14
    readonly property real headerHeight: 24
    readonly property real currentHeight: 88
    readonly property real statsHeight: 42
    readonly property real forecastHeight: 66

    readonly property real contentHeight:
        root.padding +
        root.headerHeight +
        12 +
        root.currentHeight +
        12 +
        root.statsHeight +
        14 +
        root.forecastHeight +
        root.padding

    implicitWidth: 380
    implicitHeight: root.contentHeight

    function pad2(v) {
        return v < 10 ? "0" + v : String(v);
    }

    function codeLabel(code) {
        const c = Math.round(Number(code) || 0);

        if (c === 0)
            return "Clear";
        if (c === 1)
            return "Mainly clear";
        if (c === 2)
            return "Partly cloudy";
        if (c === 3)
            return "Overcast";
        if (c >= 45 && c <= 48)
            return "Fog";
        if (c >= 51 && c <= 57)
            return "Drizzle";
        if (c >= 61 && c <= 67)
            return "Rain";
        if (c >= 71 && c <= 77)
            return "Snow";
        if (c >= 80 && c <= 82)
            return "Showers";
        if (c >= 85 && c <= 86)
            return "Snow showers";
        if (c >= 95)
            return "Thunderstorm";

        return "Unknown";
    }

    function codeIcon(code, isDay) {
        const c = Math.round(Number(code) || 0);
        const night = parseInt(isDay, 10) === 0;

        if (c === 0)
            return night ? "clear_night" : "sunny";
        if (c === 1 || c === 2)
            return night ? "partly_cloudy_night" : "partly_cloudy_day";
        if (c === 3)
            return "cloud";
        if (c >= 45 && c <= 48)
            return "foggy";
        if (c >= 51 && c <= 57)
            return "grain";
        if (c >= 61 && c <= 67)
            return "rainy";
        if (c >= 71 && c <= 77)
            return "ac_unit";
        if (c >= 80 && c <= 82)
            return "rainy";
        if (c >= 85 && c <= 86)
            return "ac_unit";
        if (c >= 95)
            return "thunderstorm";

        return "help";
    }

    function windUnit() {
        return root.units === "imperial" ? "mph" : "km/h";
    }

    function fmtUrl(lat, lon) {
        const params = root.units === "imperial"
            ? "temperature_unit=fahrenheit&wind_speed_unit=mph"
            : "wind_speed_unit=kmh";

        return "https://api.open-meteo.com/v1/forecast?latitude=" + lat
            + "&longitude=" + lon
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,precipitation,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min"
            + "&timezone=auto&forecast_days=7&" + params;
    }

    function httpGet(url, done) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 4) {
                if (xhr.status === 200)
                    done(xhr.responseText);
                else
                    done(null);
            }
        };
        xhr.send();
    }

    function refresh() {
        if (root.loading)
            return;

        root.loading = true;
        root.error = "";

        if (root.latitude !== 0 && root.longitude !== 0)
            root.fetchForecast(root.latitude, root.longitude);
        else
            root.detectLocation();
    }

    function detectLocation() {
        if (!root.autodetect && root.latitude === 0 && root.longitude === 0) {
            root.loading = false;
            root.error = "No location configured";
            return;
        }

        root.geolocate(0);
    }

    function geolocate(step) {
        const sources = [
            "https://ipwho.is/",
            "https://ipinfo.io/json",
            "https://ipapi.co/json/"
        ];

        if (step >= sources.length) {
            root.loading = false;
            root.error = "Couldn't detect location";
            return;
        }

        root.httpGet(sources[step], (body) => {
            if (body === null) {
                root.geolocate(step + 1);
                return;
            }

            let lat = NaN;
            let lon = NaN;
            let city = "";
            let region = "";
            let country = "";
            const data = JSON.parse(body);

            if (step === 0) {
                if (!data || data.success === false)
                    return root.geolocate(step + 1);

                lat = parseFloat(data.latitude);
                lon = parseFloat(data.longitude);
                city = String(data.city || "");
                region = String(data.region || "");
                country = String(data.country || "");
            } else {
                lat = parseFloat(data.latitude);
                lon = parseFloat(data.longitude);

                if (isNaN(lat) || isNaN(lon)) {
                    const loc = String(data.loc || "");
                    const parts = loc.split(",");

                    if (parts.length === 2) {
                        lat = parseFloat(parts[0]);
                        lon = parseFloat(parts[1]);
                    }
                }

                city = String(data.city || "");
                region = String(data.region || "");
                country = String(data.country_name || data.country || "");
            }

            if (isNaN(lat) || isNaN(lon)) {
                root.geolocate(step + 1);
                return;
            }

            root.locationName = [city, region, country].filter(v => v !== "").join(", ");
            root.latitude = lat;
            root.longitude = lon;
            root.fetchForecast(lat, lon);
        });
    }

    function fetchForecast(lat, lon) {
        root.httpGet(root.fmtUrl(lat, lon), (body) => {
            root.loading = false;

            if (body === null) {
                root.error = "Weather unavailable";
                return;
            }

            const data = JSON.parse(body);

            if (!data || !data.current) {
                root.error = "Weather unavailable";
                return;
            }

            root.error = "";
            const now = new Date();
            root.updatedLabel = root.pad2(now.getHours()) + ":" + root.pad2(now.getMinutes());

            const cur = data.current;
            root.currentTemp = Math.round(cur.temperature_2m) + "°";
            root.currentCondition = root.codeLabel(cur.weather_code);
            root.currentIcon = root.codeIcon(cur.weather_code, cur.is_day);
            root.feelsLike = Math.round(cur.apparent_temperature) + "°";
            root.humidity = Math.round(cur.relative_humidity_2m) + "%";
            root.windSpeed = Math.round(cur.wind_speed_10m) + " " + root.windUnit();
            root.precipitation = (Number(cur.precipitation) || 0).toFixed(1) + " mm";

            const days = data.daily || {};
            const names = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
            const list = [];

            for (let i = 0; i < 7; i += 1) {
                const date = new Date((days.time || [])[i] + "T12:00:00");
                const day = names[date.getDay()];
                const code = (days.weather_code || [])[i];
                const hi = Math.round((days.temperature_2m_max || [])[i]) + "°";
                const lo = Math.round((days.temperature_2m_min || [])[i]) + "°";

                list.push({
                    day: day,
                    code: code,
                    hi: hi,
                    lo: lo,
                    today: i === 0
                });
            }

            root.daily = list;
        });
    }

    onVisibleChanged: {
        if (root.visible)
            root.refresh();
    }

    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.visible
        onTriggered: root.refresh()
    }

    Timer {
        interval: 12000
        running: root.loading
        onTriggered: {
            root.loading = false;
            root.error = "Weather timed out";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: root.loading && root.locationName === "" ? "Locating…" : (root.locationName !== "" ? root.locationName : "Weather")
                color: root.textPrimary
                font.family: root.fontFamily
                font.pixelSize: 15
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                visible: root.updatedLabel !== ""
                text: root.updatedLabel
                color: root.textDim
                font.family: root.fontFamily
                font.pixelSize: 10
            }

            Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: 12
                color: refreshMouse.containsMouse ? "#1a1a1a" : "#0b0b0b"
                border.width: 1
                border.color: refreshMouse.containsMouse ? "#2c2c2c" : "#232323"

                MIcon {
                    anchors.centerIn: parent
                    name: "refresh"
                    size: 13
                    color: root.accent
                }

                MouseArea {
                    id: refreshMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refresh()
                }
            }
        }

        Item {
            Layout.preferredHeight: 12
        }

        Item {
            visible: root.loading || root.error !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: root.currentHeight

            Column {
                anchors.centerIn: parent
                spacing: 6

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    MIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.error !== "" ? "error" : "cloud_sync"
                        size: 18
                        color: root.error !== "" ? "#f0c040" : root.textSecondary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.error !== "" ? root.error : "Loading weather…"
                        color: root.error !== "" ? "#f0c040" : root.textSecondary
                        font.family: root.fontFamily
                        font.pixelSize: 12
                    }
                }

                Text {
                    visible: root.error !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "click to retry"
                    color: root.textDim
                    font.family: root.fontFamily
                    font.pixelSize: 10
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refresh()
            }
        }

        Item {
            visible: !root.loading && root.error === ""
            Layout.fillWidth: true
            Layout.preferredHeight: root.currentHeight

            Row {
                anchors.centerIn: parent
                spacing: 18

                Item {
                    width: 64
                    height: 64
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: "#0d0d0d"
                        border.width: 1
                        border.color: "#262626"
                    }

                    MIcon {
                        anchors.centerIn: parent
                        name: root.currentIcon
                        size: 38
                        color: root.textPrimary
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.currentTemp
                        color: root.textPrimary
                        font.family: root.fontFamily
                        font.pixelSize: 34
                        font.weight: Font.Bold
                    }

                    Text {
                        text: root.currentCondition
                        color: root.textSecondary
                        font.family: root.fontFamily
                        font.pixelSize: 13
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: "H " + (root.daily.length > 0 ? root.daily[0].hi : "—")
                        color: root.textSecondary
                        font.family: root.fontFamily
                        font.pixelSize: 11
                    }

                    Text {
                        text: "L " + (root.daily.length > 0 ? root.daily[0].lo : "—")
                        color: root.textDim
                        font.family: root.fontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: 12
        }

        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: root.statsHeight
            spacing: 8

            Repeater {
                model: [
                    { icon: "device_thermostat", value: root.feelsLike, label: "feels" },
                    { icon: "humidity_high", value: root.humidity, label: "humidity" },
                    { icon: "air", value: root.windSpeed, label: "wind" },
                    { icon: "water_drop", value: root.precipitation, label: "precip" }
                ]

                delegate: Column {
                    property var stat: modelData
                    width: (parent.width - 24) / 4

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 3

                        MIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: stat.icon
                            size: 12
                            color: root.accent
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: stat.value
                            color: root.textSecondary
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: stat.label
                        color: root.textDim
                        font.family: root.fontFamily
                        font.pixelSize: 9
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: 14
        }

        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: root.forecastHeight
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Repeater {
                model: root.daily

                delegate: Column {
                    property var dayModel: modelData
                    width: (parent.width - 6 * 6) / 7
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dayModel.today ? "TODAY" : dayModel.day
                        color: dayModel.today ? root.accent : root.textDim
                        font.family: root.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    MIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: root.codeIcon(dayModel.code, true)
                        size: 20
                        color: root.textSecondary
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dayModel.hi + " / " + dayModel.lo
                        color: root.textSecondary
                        font.family: root.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}