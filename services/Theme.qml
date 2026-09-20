pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules
import qs.preferences

Singleton {
    id: theme

    property string schemesFile: Utils.getUserLocalRelativePath("schemes.json")
    property string cacheDir: Utils.getCachePath("schemes")
    property string cacheFile: ""
    property string videoFramePath: "/tmp/whisker_video_frame.png"

    Connections {
        target: Preferences.theme
        function onWallpaperChanged() { theme.regenColor() }
        function onSchemeChanged() { theme.regenColor() }
        function onDarkChanged() { theme.regenColor() }
        function onContrastChanged() { theme.regenColor() }
        function onVideoFrameChanged() { theme.regenColor() }
    }

    function init() {
        Log.info("services/Theme.qml", "init");
    }

    function cacheKey() {
        var wp = Preferences.theme.wallpaper || "none";
        var sanitized = wp.replace(/[^a-zA-Z0-9_-]/g, "_");
        var parts = [
            sanitized,
            Preferences.theme.scheme,
            Preferences.theme.dark ? "dark" : "light",
            "c" + Number(Preferences.theme.contrast).toFixed(2),
            "f" + Preferences.theme.videoFrame
        ];
        return parts.join("_") + ".json";
    }

    function regenColor() {
        var wp = Preferences.theme.wallpaper;
        if (!wp || wp === "") {
            Log.info("services/Theme.qml", "No wallpaper set; skipping color regen");
            return;
        }

        theme.cacheFile = theme.cacheDir + "/" + theme.cacheKey();
        Log.info("services/Theme.qml", "Regenerating Colors for " + wp + " (cache: " + theme.cacheFile + ")");

        if (Preferences.theme.useColorCache) {
            cacheCheck.running = true;
        } else {
            theme.runMatugen();
        }
    }

    Process {
        id: cacheCheck
        command: ["test", "-f", theme.cacheFile]
        onExited: code => {
            if (code === 0 && Preferences.theme.useColorCache) {
                Log.info("services/Theme.qml", "Cache hit: " + theme.cacheFile);
                cacheCopyFrom.running = true;
            } else {
                Log.info("services/Theme.qml", "Cache miss; running matugen");
                theme.runMatugen();
            }
        }
    }

    Process {
        id: cacheCopyFrom
        command: ["cp", theme.cacheFile, theme.schemesFile]
        onExited: {
            Appearance.reloadScheme("");
            theme.runUserTemplates();
        }
    }

    function runMatugen() {
        var wp = Preferences.theme.wallpaper;
        if (!wp) return;

        if (Utils.isVideo(wp)) {
            extractVideoFrame(wp);
        } else {
            invokeMatugen(wp);
        }
    }

    function extractVideoFrame(videoPath) {
        var frame = Math.max(0, Preferences.theme.videoFrame | 0);
        Log.info("services/Theme.qml", "Extracting video frame " + frame + " from " + videoPath);
        ffmpegProc.command = [
            "ffmpeg", "-y",
            "-ss", frame.toString(),
            "-i", videoPath,
            "-frames:v", "1",
            "-q:v", "2",
            theme.videoFramePath
        ];
        ffmpegProc.running = true;
    }

    function invokeMatugen(inputPath) {
        var cmd = [
            "matugen", "image", inputPath,
            "-m", Preferences.theme.dark ? "dark" : "light",
            "-t", "scheme-" + Preferences.theme.scheme,
            "--contrast", Number(Preferences.theme.contrast).toFixed(2),
            "--source-color-index", "0"
        ];
        Log.info("services/Theme.qml", "Running matugen: " + cmd.join(" "));
        matugenProc.command = cmd;
        matugenProc.running = true;
    }

    Process {
        id: ffmpegProc
        onExited: code => {
            if (code === 0) {
                Log.info("services/Theme.qml", "Frame extracted; running matugen on frame");
                theme.invokeMatugen(theme.videoFramePath);
            } else {
                Log.error("services/Theme.qml", "ffmpeg frame extraction failed (code " + code + ")");
            }
        }
    }

    Process {
        id: matugenProc
        stdout: StdioCollector {
            onStreamFinished: Log.info("services/Theme.qml", "Matugen: " + text.trim())
        }
        onExited: code => {
            if (code === 0) {
                Appearance.reloadScheme("");
                if (Preferences.theme.useColorCache) {
                    cacheEnsureDir.running = true;
                } else {
                    theme.runUserTemplates();
                }
            } else {
                Log.error("services/Theme.qml", "matugen failed (code " + code + ")");
            }
        }
    }

    Process {
        id: cacheEnsureDir
        command: ["mkdir", "-p", theme.cacheDir]
        onExited: {
            cacheCopyTo.running = true;
        }
    }

    Process {
        id: cacheCopyTo
        command: ["cp", theme.schemesFile, theme.cacheFile]
        onExited: {
            theme.runUserTemplates();
        }
    }

    function runUserTemplates() {
        if (!Preferences.theme.runUserMatugenTemplate) return;
        Log.info("services/Theme.qml", "Scanning user matugen templates");
        templateScan.running = true;
    }

    Process {
        id: templateScan
        command: ["sh", "-c", "ls -1 '" + Utils.getConfigRelativePath("matugen") + "' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var files = text.trim().split("\n").filter(s => s.length > 0);
                if (files.length === 0) {
                    Log.info("services/Theme.qml", "No user templates found");
                    return;
                }
                Log.info("services/Theme.qml", "Running " + files.length + " user templates");
                var wp = Preferences.theme.wallpaper;
                var input = Utils.isVideo(wp) ? theme.videoFramePath : wp;
                for (var i = 0; i < files.length; i++) {
                    var tpl = Utils.getConfigRelativePath("matugen/" + files[i]);
                    var proc = templateRunner.createObject(null, {
                        command: [
                            "matugen", "image", input,
                            "-m", Preferences.theme.dark ? "dark" : "light",
                            "-t", tpl,
                            "--contrast", Number(Preferences.theme.contrast).toFixed(2),
                            "--source-color-index", "0"
                        ],
                        running: true
                    });
                }
            }
        }
    }

    Component {
        id: templateRunner
        Process {}
    }
}