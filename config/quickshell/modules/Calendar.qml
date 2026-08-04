import QtQuick
import QtQuick.Layouts


Item {
    id: root

    required property string fontFamily

    property date date: new Date()
    property var grid: []

    readonly property color accent: "#ff9f1c"
    readonly property color todayText: "#000000"
    readonly property color weekdayColor: "#7f7f7f"
    readonly property color dayText: "#c8c8c8"
    readonly property color dimText: "#555555"

    readonly property real padding: 14
    readonly property real headerHeight: 22
    readonly property real weekdayHeight: 16
    readonly property real cellHeight: 32
    readonly property real cellGap: 6
    readonly property real rowGap: 4
    readonly property real gridCellWidth: (root.implicitWidth - 2 * root.padding - 6 * root.cellGap) / 7

    readonly property int gridRows: Math.max(5, Math.ceil((root.firstDayOffset() + root.daysInMonth()) / 7))
    readonly property real gridHeight: root.gridRows * root.cellHeight + (root.gridRows - 1) * root.rowGap

    readonly property real contentHeight:
        root.padding +
        root.headerHeight +
        10 +
        root.weekdayHeight +
        8 +
        root.gridHeight +
        root.padding

    implicitHeight: root.contentHeight
    implicitWidth: 380

    function monthYearText() {
        const d = root.date ? new Date(root.date) : new Date();
        const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        return months[d.getMonth()] + " " + d.getFullYear();
    }

    function firstDayOffset() {
        const d = root.date ? new Date(root.date) : new Date();
        return new Date(d.getFullYear(), d.getMonth(), 1).getDay();
    }

    function daysInMonth() {
        const d = root.date ? new Date(root.date) : new Date();
        return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
    }

    function rebuildGrid() {
        const d = root.date ? new Date(root.date) : new Date();
        const y = d.getFullYear();
        const m = d.getMonth();
        const firstDay = new Date(y, m, 1).getDay();
        const days = new Date(y, m + 1, 0).getDate();
        const today = d.getDate();
        const cells = [];

        for (let i = 0; i < firstDay; i += 1)
            cells.push({ day: 0, current: false, today: false });

        for (let i = 1; i <= days; i += 1)
            cells.push({ day: i, current: true, today: i === today });

        const total = root.gridRows * 7;
        while (cells.length < total)
            cells.push({ day: 0, current: false, today: false });

        root.grid = cells;
    }

    Component.onCompleted: root.rebuildGrid()
    onDateChanged: root.rebuildGrid()

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        spacing: 0


        Text {
            Layout.fillWidth: true
            Layout.preferredHeight: root.headerHeight
            text: root.monthYearText()
            color: "#f5f5f5"
            font.family: root.fontFamily
            font.pixelSize: 16
            font.weight: Font.Bold
        }

        Item {
            Layout.preferredHeight: 10
        }


        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.weekdayHeight
            spacing: root.cellGap

            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]

                Text {
                    Layout.fillWidth: true
                    text: modelData
                    color: root.weekdayColor
                    horizontalAlignment: Text.AlignHCenter
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }

        Item {
            Layout.preferredHeight: 8
        }


        Grid {
            id: monthGrid

            Layout.fillWidth: true
            Layout.preferredHeight: root.gridHeight
            columns: 7
            columnSpacing: root.cellGap
            rowSpacing: root.rowGap

            Repeater {
                model: root.grid

                Rectangle {
                    width: root.gridCellWidth
                    height: root.cellHeight
                    radius: height / 2
                    color: modelData.today ? root.accent : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day > 0 ? String(modelData.day) : ""
                        color: modelData.today ? root.todayText : (modelData.current ? root.dayText : root.dimText)
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        font.weight: modelData.today ? Font.Bold : Font.Normal
                    }
                }
            }
        }
    }
}
