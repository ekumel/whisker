pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules
import qs.preferences

Singleton {
    id: rotation

    readonly property string defaultDirectory: Quickshell.env("HOME") + "/Pictures/wallpapers"

    readonly property string directory: {
        var dir = Preferences.theme.wallpaperDirectory;
        if (!dir || dir === "")
            return defaultDirectory;
        if (dir.startsWith("~"))
            return Quickshell.env("HOME") + dir.substring(1);
        return dir;
    }

    property var wallpapers: []
    property bool listLoaded: false

    function listDir() {
        listProc.command = ["sh", "-c", "ls -1 -- \"" + directory + "\" 2>/dev/null"];
        listProc.running = true;
    }

    Process {
        id: listProc
        stdout: StdioCollector {
            onStreamFinished: {
                var imageExts = ["png", "jpg", "jpeg", "webp", "bmp", "gif", "tif", "tiff", "ico"];
                var videoExts = ["mp4", "mkv", "webm", "avi", "mov", "flv", "wmv", "m4v"];
                var raw = text.split("\n");
                var out = [];
                for (var i = 0; i < raw.length; i++) {
                    var name = raw[i].trim();
                    if (name.length === 0) continue;
                    var fullPath = rotation.directory + "/" + name;
                    var ext = name.toLowerCase().split(".").pop();
                    if (imageExts.indexOf(ext) !== -1 || videoExts.indexOf(ext) !== -1) {
                        out.push(fullPath);
                    }
                }
                rotation.wallpapers = out;
                rotation.listLoaded = true;
            }
        }
    }

    FileView {
        id: dirWatcher
        path: rotation.directory
        watchChanges: true
        printErrors: false
        blockLoading: true
        onFileChanged: rotation.listDir()
        onLoaded: rotation.listDir()
    }

    Timer {
        id: rotationTimer
        interval: Math.max(1, Preferences.theme.rotationIntervalMinutes) * 60 * 1000
        running: Preferences.theme.rotationEnabled && rotation.listLoaded && rotation.wallpapers.length > 1
        repeat: true
        triggeredOnStart: false
        onTriggered: rotation.rotate()
    }

    Connections {
        target: rotation
        function onWallpapersChanged() {
            if (Preferences.theme.rotationLastIndex >= rotation.wallpapers.length) {
                Quickshell.execDetached({
                    command: ["whisker", "prefs", "set", "theme.rotationLastIndex", -1]
                });
            }
        }
    }

    function pickNext() {
        if (wallpapers.length === 0) return "";
        var current = Preferences.theme.wallpaper || "";
        var currentIdx = wallpapers.indexOf(current);

        if (Preferences.theme.rotationMode === 1) {
            // random: avoid picking the same as current
            if (wallpapers.length === 1) return wallpapers[0];
            var newIdx;
            var attempts = 0;
            do {
                newIdx = Math.floor(Math.random() * wallpapers.length);
                attempts++;
            } while (newIdx === currentIdx && attempts < 8);
            return wallpapers[newIdx];
        }

        // sequential
        var nextIdx;
        if (currentIdx >= 0) {
            nextIdx = (currentIdx + 1) % wallpapers.length;
        } else {
            var last = Preferences.theme.rotationLastIndex;
            if (last >= 0 && last < wallpapers.length) {
                nextIdx = (last + 1) % wallpapers.length;
            } else {
                nextIdx = 0;
            }
        }
        return wallpapers[nextIdx];
    }

    function rotate() {
        if (wallpapers.length === 0) return;
        var next = pickNext();
        if (!next || next === "") return;
        var idx = wallpapers.indexOf(next);
        Quickshell.execDetached({
            command: ["whisker", "wallpaper", next]
        });
        if (idx >= 0) {
            Quickshell.execDetached({
                command: ["whisker", "prefs", "set", "theme.rotationLastIndex", idx.toString()]
            });
        }
    }

    Component.onCompleted: listDir()
}