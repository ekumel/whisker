//@ pragma Env QT_SCALE_FACTOR=1
//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.preferences
import qs.windows.firsttime
import qs.services

ShellRoot {
    Component.onCompleted: Preferences.suppressWelcomeSpawn = true
    FirstTimeSetup {}
}
