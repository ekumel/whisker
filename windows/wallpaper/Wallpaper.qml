import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Io
import qs.modules
import qs.services as WhiskerServ
import qs.preferences
import qs.components
import qs.components.effects
import qs.components.players
import QtQuick.Layouts
import QtQuick.Effects

PanelWindow {
    id: wallpaper

    IpcHandler {
        target: "wallpaper"
        function reload() {
            wallpaper.currentWallpaperChanged();
        }
    }

    property string fallbackWallpaper: Utils.getPath("images/fallback-wallpaper.png")
    property string currentWallpaper: Appearance.wallpaper !== "" ? Appearance.wallpaper : fallbackWallpaper
    property bool isVideo: Utils.isVideo(currentWallpaper)

    property real widgetOffset: 40
    property real screenOffset: 50

    property bool barIsShowing: !Preferences.bar.autoHide || Globals.isBarHovered
    property real wallpaperShift: (Preferences.bar.autoHide && barIsShowing) ? widgetOffset * 0.3 : 0
    property real widgetShift: barIsShowing ? widgetOffset + screenOffset : widgetOffset

    anchors {
        left: true
        bottom: true
        top: true
        right: true
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "whisker:wallpaper"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // mpvpaper processes
    property var mpvpaperProcesses: []

    onCurrentWallpaperChanged: {
        var newIsVideo = Utils.isVideo(currentWallpaper);
        var wasVideo = isVideo;

        if (wasVideo) {
            stopAllMpvpaper();
        }

        if (!wasVideo) {
            if (Preferences.theme.switchAnimation) {
                oldImage.source = currentImage.source;
                oldImage.opacity = 1;
                oldImageFadeOut.start();
            } else {
                oldImage.source = "";
                oldImage.opacity = 0;
            }
        }

        isVideo = newIsVideo;

        if (newIsVideo) {
            currentImage.opacity = 0;
            _lastPauseSent = false;
            startMpvpaperForAllMonitors();
        } else {
            currentImage.source = currentWallpaper;
            currentImage.opacity = Preferences.theme.switchAnimation ? 0 : 1;
            if (!Preferences.theme.switchAnimation) {
                newImageFadeIn.stop();
            }
        }
    }

    Component.onCompleted: {
        if (isVideo) {
            startMpvpaperForAllMonitors();
            // Schedule initial pause-state sync after mpvpaper has had a chance
            // to create its IPC socket. Without this delay the first IPC send
            // can race the socket creation and silently fail.
            pauseSyncTimer.restart();
        }
        // Reference the rotation service so it loads with the wallpaper window
        WhiskerServ.WallpaperRotation.listDir();
    }

    Timer {
        id: pauseSyncTimer
        interval: 1500
        repeat: false
        onTriggered: updateMpvpaperPlayback()
    }

    function fillModeFromPref(mode) {
        // 0 = PreserveAspectCrop, 1 = PreserveAspectFit, 2 = Stretch (IgnoreAspectRatio),
        // 3 = Tile
        if (mode === 1) return Image.PreserveAspectFit;
        if (mode === 2) return Image.Stretch;
        if (mode === 3) return Image.Tile;
        return Image.PreserveAspectCrop;
    }

    function startMpvpaperForAllMonitors() {
        if (!isVideo)
            return;

        stopAllMpvpaper();

        var monitors = WhiskerServ.Hyprland.monitors?.values || [];
        Log.info("windows/wallpaper/Wallpaper.qml", "Starting mpvpaper for " + monitors.length + " monitors");

        monitors.forEach(monitor => {
            if (monitor && monitor.name) {
                startMpvpaperForMonitor(monitor.name);
            }
        });
    }

    function startMpvpaperForMonitor(monitorName) {
        Log.info("windows/wallpaper/Wallpaper.qml", "Starting mpvpaper for monitor: " + monitorName);

        var proc = mpvpaperComponent.createObject(wallpaper, {
            "monitorName": monitorName,
            "videoPath": currentWallpaper
        });

        if (proc) {
            mpvpaperProcesses.push(proc);
        }
    }

    function stopAllMpvpaper() {
        Log.info("windows/wallpaper/Wallpaper.qml", "Stopping all mpvpaper processes");

        mpvpaperProcesses.forEach(proc => {
            if (proc) {
                proc.running = false;
                proc.destroy();
            }
        });

        mpvpaperProcesses = [];
    }

    Component {
        id: mpvpaperComponent

        Process {
            id: mpvProc
            property string monitorName: ""
            property string videoPath: ""

            command: {
                var opts = [];
                opts.push("keep-open");
                opts.push("load-scripts=no");
                opts.push("load-stats-overlay=no");
                opts.push("input-ipc-server=/tmp/whisker-mpvpaper-" + monitorName + ".sock");

                if (!Preferences.theme.videoWallpaper.hwdec) {
                    opts.push("hwdec=no");
                }

                var fps = Preferences.theme.videoWallpaper.fps;
                if (fps > 0) {
                    opts.push("fps=" + fps);
                    opts.push("framedrop=vo");
                }

                opts.push("no-audio");
                opts.push("loop");

                // XDG_CONFIG_HOME is redirected so mpv doesn't read mpv.conf or
                // load any Lua scripts from the user's config dir. The directory
                // must already exist (or be auto-created) -- we mkdir below.
                var xdgDir = "/tmp/whisker-mpv-empty-" + monitorName;
                var mpvpaperCmd = "mpvpaper -o " + shellQuote(opts.join(" ")) + " " +
                                   shellQuote(monitorName) + " " + shellQuote(videoPath);
                return ["sh", "-c", "mkdir -p " + shellQuote(xdgDir) +
                                    " && XDG_CONFIG_HOME=" + shellQuote(xdgDir) +
                                    " exec " + mpvpaperCmd];
            }
            running: true

            stdout: SplitParser {
                onRead: data => {
                // console.log("[mpvpaper:" + mpvProc.monitorName + "]", data.trim());
                }
            }

            stderr: SplitParser {
                onRead: data => {
                    console.error("[mpvpaper:" + mpvProc.monitorName + " ERROR]", data.trim());
                }
            }

            onRunningChanged: {
                if (!running) {
                    Log.info("windows/wallpaper/Wallpaper.qml", "[mpvpaper:" + monitorName + "] Process stopped");
                }
            }
        }
    }

    Connections {
        target: WhiskerServ.Hyprland
        function onWorkspaceUpdated() {
            // Defer so the IPC refresh triggered by our handler has time
            // to populate the toplevel/workspace caches before we read them.
            Qt.callLater(updateMpvpaperPlayback);
        }
        function onRawEvent(event) {
            const n = event?.name || "";
            if (!n.endsWith("v2")) return;
            if (n.includes("fullscreen") || n.includes("changefloatingmode") ||
                n === "openwindow>>v2" || n === "closewindow>>v2" ||
                n === "movewindow>>v2" || n === "minimize>>v2") {
                Qt.callLater(updateMpvpaperPlayback);
            }
        }
    }

    property bool _lastPauseSent: false

    function updateMpvpaperPlayback() {
        if (!isVideo)
            return;

        var p = Preferences.theme.videoWallpaper;
        var shouldPause = false;

        try {
            if (WhiskerServ.Hyprland.currentWorkspace.hasWindow) {
                if (p.pauseOnAnyWindow) {
                    shouldPause = true;
                } else {
                    if (p.pauseOnFullscreen && WhiskerServ.Hyprland.currentWorkspace.hasFullscreenWindow())
                        shouldPause = true;
                    else if (p.pauseOnFloating && WhiskerServ.Hyprland.currentWorkspace.hasFloatingWindow())
                        shouldPause = true;
                    else if (p.pauseOnTiled && WhiskerServ.Hyprland.currentWorkspace.hasTilingWindow())
                        shouldPause = true;
                }
            }
        } catch (e) {
            console.warn("Wallpaper: pause check failed", e);
        }

        if (shouldPause === _lastPauseSent)
            return;

        _lastPauseSent = shouldPause;
        Log.info("windows/wallpaper/Wallpaper.qml", "Setting mpvpaper pause=" + shouldPause + " for " + mpvpaperProcesses.length + " process(es)");

        var payload = JSON.stringify({ command: ["set_property", "pause", shouldPause] });
        mpvpaperProcesses.forEach(proc => {
            if (!proc)
                return;
            var sockPath = "/tmp/whisker-mpvpaper-" + proc.monitorName + ".sock";
            Quickshell.execDetached({
                command: ["sh", "-c", "printf '%s\\n' " + shellQuote(payload) + " | nc -U -w 1 " + shellQuote(sockPath)]
            });
        });
    }

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\\''") + "'";
    }

    Item {
        id: wallpaperWrapper
        anchors.fill: parent

        transform: Translate {
            x: {
                if (Preferences.bar.position === "left") return wallpaperShift;
                if (Preferences.bar.position === "right") return -wallpaperShift;
                return 0;
            }
            y: {
                if (Preferences.bar.position === "top") return wallpaperShift;
                if (Preferences.bar.position === "bottom") return -wallpaperShift;
                return 0;
            }

            Behavior on x {
                NumberAnimation {
                    duration: Appearance.animation.medium
                    easing.type: Appearance.animation.easing
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: Appearance.animation.medium
                    easing.type: Appearance.animation.easing
                }
            }
        }

        Image {
            id: currentImage
            anchors.fill: parent
            sourceSize: Qt.size(wallpaper.width, wallpaper.height)
            source: ""
            fillMode: fillModeFromPref(Preferences.theme.fillMode)
            smooth: true
            cache: true
            visible: !isVideo
            opacity: 1

            scale: Preferences.bar.autoHide ? 1.025 : 1
            Behavior on scale { NumberAnimation { duration: Appearance.animation.fast; easing.type: Appearance.animation.easing } }
            Component.onCompleted: {
                if (!isVideo)
                    source = currentWallpaper;
            }
        }

        Image {
            id: oldImage
            anchors.fill: parent
            sourceSize: Qt.size(wallpaper.width, wallpaper.height)
            source: ""
            fillMode: fillModeFromPref(Preferences.theme.fillMode)
            smooth: true
            cache: true
            opacity: 0

            NumberAnimation {
                id: oldImageFadeOut
                target: oldImage
                property: "opacity"
                duration: Appearance.animation.medium
                easing.type: Appearance.animation.easing
                from: 1
                to: 0

                onStopped: {
                    oldImage.source = "";
                    if (Preferences.theme.switchAnimation) {
                        newImageFadeIn.start();
                    }
                }
            }
        }

        NumberAnimation {
            id: newImageFadeIn
            target: currentImage
            property: "opacity"
            duration: Appearance.animation.medium
            easing.type: Appearance.animation.easing
            from: 0
            to: 1
        }

        CavaVisualizer {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: {
                if (Preferences.bar.small)
                    return 0;
                if (Preferences.bar.position === "bottom" && barIsShowing)
                    return screenOffset - 15 - wallpaperShift;
                return 0;
            }
            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: Appearance.animation.fast
                    easing.type: Appearance.animation.easing
                }
            }
            visible: !WhiskerServ.Hyprland.currentWorkspace.hasTilingWindow()
        }

        Lyrics {
            id: lyricsBox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Preferences.bar.position === "bottom" ? widgetShift : widgetOffset
            visible: Preferences.widgets.showLyrics && !Preferences.widgets.lyricsAsOverlay && !WhiskerServ.Hyprland.currentWorkspace.hasTilingWindow()
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.left: parent.left
        anchors.bottom: parent.bottom

        anchors.leftMargin: Preferences.bar.position === "left" ? widgetShift : widgetOffset
        anchors.bottomMargin: Preferences.bar.position === "bottom" ? widgetShift : widgetOffset

        Behavior on anchors.leftMargin {
            NumberAnimation {
                duration: Appearance.animation.fast
                easing.type: Appearance.animation.easing
            }
        }
        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: Appearance.animation.fast
                easing.type: Appearance.animation.easing
            }
        }

        spacing: -10

        RowLayout {
            visible: Preferences.widgets.desktop.clock
            StyledText {
                Layout.alignment: Qt.AlignCenter
                text: Qt.formatDateTime(WhiskerServ.Time.date, "HH")
                font.family: "Outfit Black"
                color: Appearance.colors.m3primary
                font.pixelSize: 96
            }
            StyledText {
                Layout.alignment: Qt.AlignCenter
                text: ":"
                font.family: "Outfit Black"
                color: Appearance.colors.m3error
                font.pixelSize: 96
            }
            StyledText {
                Layout.alignment: Qt.AlignCenter
                text: Qt.formatDateTime(WhiskerServ.Time.date, "mm")
                font.family: "Outfit Black"
                color: Appearance.colors.m3secondary
                font.pixelSize: 96
            }
        }


        StyledText {
            text: Qt.formatDateTime(WhiskerServ.Time.date, "dddd, dd/MM")
            color: Appearance.colors.m3primary
            font.pixelSize: 32
            font.bold: true
            visible: Preferences.widgets.desktop.clock
        }

        PlayerDisplay {
            visible: Preferences.widgets.desktop.player && !!Players.active
            Layout.topMargin: 20
            Layout.minimumWidth: 400
        }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: 1
            shadowColor: Appearance.colors.m3shadow
            shadowBlur: 0.5
        }
    }
}