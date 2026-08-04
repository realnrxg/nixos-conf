import QtQml.Models
import QtQuick
import Quickshell.Services.Notifications

Item {
    id: root

    visible: false

    property bool dnd: false

    readonly property int maxHistory: 30

    NotificationServer {
        id: notifServer

        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
    }

    ListModel {
        id: history
    }

    property var toastQueue: []
    property var currentToast: null

    readonly property int count: history.count
    readonly property ListModel historyModel: history

    function syncKey(n) {
        if (!n || !n.hints)
            return "";

        const hint = n.hints["x-canonical-private-synchronous"];

        if (hint && String(hint) !== "")
            return "sync:" + String(hint);

        return "";
    }

    function findIndex(key) {
        for (let i = 0; i < history.count; i++) {
            if (history.get(i).key === key)
                return i;
        }

        return -1;
    }

    function handleNotification(n) {
        if (!n)
            return;

        const entry = {
            key: root.syncKey(n),
            appName: n.appName || "",
            appIcon: n.appIcon || "",
            summary: n.summary || "",
            body: n.body || "",
            image: n.image || "",
            critical: n.urgency === NotificationUrgency.Critical,
            time: Date.now()
        };

        if (entry.key !== "") {
            const idx = root.findIndex(entry.key);

            if (idx >= 0) {
                history.set(idx, entry);
                history.move(idx, 0, 1);
            } else {
                history.insert(0, entry);
            }
        } else {
            history.insert(0, entry);
        }

        while (history.count > root.maxHistory)
            history.remove(history.count - 1);

        if (root.dnd)
            return;

        if (root.currentToast && root.currentToast.key === entry.key) {
            root.currentToast = entry;
            return;
        }

        for (let i = 0; i < root.toastQueue.length; i++) {
            if (root.toastQueue[i].key === entry.key) {
                root.toastQueue[i] = entry;
                return;
            }
        }

        root.toastQueue.push(entry);
        root.nextToast();
    }

    function nextToast() {
        if (root.currentToast || root.toastQueue.length === 0)
            return;

        root.currentToast = root.toastQueue.shift();
    }

    function ackToast() {
        root.currentToast = null;
        root.nextToast();
    }

    function dismissAt(index) {
        if (index < 0 || index >= history.count)
            return;

        history.remove(index);
    }

    function clearAll() {
        history.clear();
    }

    Connections {
        target: notifServer

        function onNotification(notification) {
            root.handleNotification(notification);
        }
    }
}
