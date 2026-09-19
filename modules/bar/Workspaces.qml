import QtQuick
import QtQml.Models
import QtQuick.Layouts
import qs.modules
import qs.components
import qs.preferences
import qs.services

Item {
    id: root
    height: 25
    width: pills.implicitWidth + 20

    Behavior on width {
        NumberAnimation {
            duration: Appearance.animation.fast;
            easing.type: Appearance.animation.easing
        }
    }

    property bool verticalMode: false

    transform: Rotation {
        origin.x: width / 2
        origin.y: height / 2
        angle: verticalMode ? 90 : 0
    }

    StyledRectangle {
        id: bgRect
        opacity: !Preferences.bar.keepOpaque && !Hyprland.currentWorkspace.hasTilingWindow() ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Appearance.animation.fast; easing.type: Appearance.animation.easing } }

        anchors.fill: parent
        color: Appearance.colors.m3surface_container
        radius: 20
    }

    Row {
        id: pills
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: Hyprland.fullWorkspaces

            delegate: StyledRectangle {
                id: pill
                width: focused ? 20 : 10
                height: 10
                radius: 20
                anchors.verticalCenter: parent.verticalCenter
                opacity: focused ? 1.0 : 0.4

                color: {
                    if (focused || hasWindows)
                        return Appearance.colors.m3primary;
                    return Appearance.colors.m3primary_container;
                }

                Behavior on width { NumberAnimation { duration: Appearance.animation.fast; easing.type: Appearance.animation.easing } }
                Behavior on opacity { NumberAnimation { duration: Appearance.animation.fast; easing.type: Appearance.animation.easing } }
                Behavior on color { ColorAnimation { duration: Appearance.animation.fast; easing.type: Appearance.animation.easing } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (Hyprland.activeWsId !== id) Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`)
                }
            }
        }
    }

    property real _wheelDelta: 0
    readonly property real _wheelThreshold: 100

    // Scroll up steps back one workspace; the number cannot go below 1.
    // Scroll down steps forward with no upper bound. Accumulating the delta
    // keeps high-resolution touchpad scrolling from flying through workspaces.
    function handleWheelDelta(delta) {
        _wheelDelta += delta

        if (Math.abs(_wheelDelta) < _wheelThreshold)
            return

        if (_wheelDelta > 0) {
            if (Hyprland.activeWsId > 1)
                Hyprland.dispatch("hl.dsp.focus({ workspace = \"-1\" })")
        } else {
            // "+1" is relative (next workspace); "1" would be absolute.
            Hyprland.dispatch("hl.dsp.focus({ workspace = \"+1\" })")
        }

        _wheelDelta = 0
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        hoverEnabled: true

        onWheel: (wheel) => {
            // A mouse wheel reports vertical deltas regardless of how the
            // widget is rotated, so always read the y axis. The pixelDelta
            // fallback covers high-resolution touchpad scrolling.
            const angle = wheel.angleDelta.y
            const pixel = wheel.pixelDelta.y
            root.handleWheelDelta(angle !== 0 ? angle : pixel * 8)
            wheel.accepted = true
        }

        onClicked: {
            if (popout.isVisible)
                popout.hide()
            else
                popout.show()
        }
    }
    HoverHandler {
        id: hover
    }
    StyledPopout {
        id: popout
        hoverTarget: hover
        interactable: true
        hCenterOnItem: true
        requiresHover: false
        Component {
            WorkspacePreview {}
        }
    }
}
