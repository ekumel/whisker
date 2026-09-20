pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules

Singleton {
    id: root
    signal reloaded

    property bool ready: false
    property bool spawnedWelcome: false

    // Set by `welcome.qml` (and any other "owned" welcome config) so its
    // own Preferences instance knows it shouldn't recursively spawn another
    // `whisker welcome` from `onReloaded`. Without this flag the first-run
    // welcome would spawn welcome → spawn welcome → … flooding the screen
    // with nested setup windows right after login.
    property bool suppressWelcomeSpawn: false

    property QtObject bar: QtObject {
        property bool floating: false
        property string position: "top"
        property bool small: false
        property int padding: 200
        property bool autoHide: false
        property bool keepOpaque: true
    }

    property QtObject theme: QtObject {
        property bool dark: true
        property string scheme: "tonal-spot"
        property bool smart: false
        property bool useWallpaper: true
        property string wallpaper: ""
        property real contrast: 0.0
        property int videoFrame: 0
        property bool useColorCache: true
        property bool runUserMatugenTemplate: false
        property string wallpaperDirectory: ""
        // 0 = PreserveAspectCrop (default), 1 = PreserveAspectFit, 2 = Stretch, 3 = Tile
        property int fillMode: 0
        property bool switchAnimation: true
        property bool rotationEnabled: false
        property int rotationIntervalMinutes: 30
        // 0 = sequential, 1 = random
        property int rotationMode: 0
        // -1 = unset (will pick first wallpaper deterministically)
        property int rotationLastIndex: -1

        property QtObject videoWallpaper: QtObject {
            property int fps: 30
            property bool hwdec: true
            property bool pauseOnAnyWindow: false
            property bool pauseOnFloating: false
            property bool pauseOnTiled: false
            property bool pauseOnFullscreen: true
        }
    }

    property QtObject misc: QtObject {
        property bool cavaEnabled: true
        property bool notificationEnabled: true
        property bool renderOverviewWindows: true
        property bool finishedSetup: false
        property string githubUsername: ""
        property bool translateLyrics: true
        property string lyricsLanguage: 'en'
        property bool showStatsOverlay: false
        property bool activateLinuxOverlay: false
        property int clickerCount: 0
        property bool applyWallpaperToGreeter: false
        // Empty string means "auto-detect from system locale".
        property string language: ""
        // Disable when running another polkit agent (e.g. hyprpolkitagent).
        property bool enablePolkitAgent: false
    }

    property QtObject widgets: QtObject {
        property bool animatedBattery: true
        property bool showLyrics: true
        property bool lyricsAsOverlay: false

        property QtObject desktop: QtObject {
            property bool clock: true
            property bool player: false
        }
    }

    onReloaded: {
        // Don't re-spawn when:
        //  - this Preferences instance is the welcome config itself (it set
        //    `suppressWelcomeSpawn` on startup), or
        //  - we're already in the greetd greeter process (HOME points at the
        //    greeter's throwaway home which has no preferences.json; also the
        //    lock file /tmp/whisker.lck left over from a previous user
        //    session would point at the user's whisker share and cause
        //    `whisker welcome` to spawn the welcome wizard in the greeter
        //    context, which crashes the login), or
        //  - we've already spawned a welcome in this process, or
        //  - the user has finished setup.
        if (Quickshell.env("HOME") === "/var/lib/whisker/greeter-home")
            return;
        if (root.suppressWelcomeSpawn || root.spawnedWelcome || root.misc.finishedSetup)
            return;
        root.spawnedWelcome = true;
        Quickshell.execDetached({ command: ["whisker", "welcome"] });
    }

    Component.onCompleted: {
        fileView.reload();
        root.ready = true;
    }

    Process {
        id: exitProc
        command: ["whisker", "prefs", "--no-prompt"]
        running: true
        stdout: StdioCollector { onStreamFinished: fileView.reload() }
    }

    function loadNested(target, obj) {
        for (const [key, value] of Object.entries(obj)) {
            if (!target.hasOwnProperty(key)) continue;

            if (typeof value === "object" && value !== null && !Array.isArray(value)) {
                if (typeof target[key] === "object" && target[key] !== null) {
                    loadNested(target[key], value);
                }
            } else {
                target[key] = value;
            }
        }
    }

    function load(content) {
        const parsed = JSON.parse(content);
        loadNested(root, parsed);
        root.ready = true;
        root.reloaded();
    }

    FileView {
        id: fileView
        path: Utils.getConfigRelativePath("preferences.json")
        watchChanges: true
        onFileChanged: {
            // console.log("Preferences updated.");
            fileView.reload();
        }
        onLoaded: root.load(text())
    }

    function horizontalBar() { return root.bar.position === "top" || root.bar.position === "bottom"; }
    function verticalBar() { return root.bar.position === "left" || root.bar.position === "right"; }
}
