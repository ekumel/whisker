pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Services.Polkit
import QtQuick
import qs.preferences

Singleton {
    id: root

    // Forwarded properties. They expose the underlying agent state when an
    // agent is actually registered. When Preferences.misc.enablePolkitAgent
    // is false (e.g. the user is running hyprpolkitagent, polkit-gnome, or
    // any other authentication agent on the system bus), we skip creating a
    // PolkitAgent entirely so we don't spam the log with a "registration
    // failed" warning every shell start.
    property bool isActive: polkitLoader.item ? polkitLoader.item.isActive : false
    property bool isRegistered: polkitLoader.item ? polkitLoader.item.isRegistered : false
    property var flow: polkitLoader.item ? polkitLoader.item.flow : null
    property string path: polkitLoader.item ? polkitLoader.item.path : ""

    Component {
        id: agentComponent
        PolkitAgent {}
    }

    Loader {
        id: polkitLoader
        active: Preferences.misc.enablePolkitAgent
        sourceComponent: agentComponent
    }
}
