//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QML_XHR_ALLOW_FILE_READ=1
//@ pragma IconTheme Adwaita

import QtQuick
import Quickshell
import "modules"

ShellRoot {
    id: root

    Main {
    }

}
