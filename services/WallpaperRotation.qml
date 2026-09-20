pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules
import qs.preferences

Singleton {
    id: rotation

    readonly property string defaultDirectory: Quickshell.env("HOME") + "/Pictures/wallpapers"

    function _stripTrailingSlash(p) {
        if (!p) return p;
        while (p.length > 1 && p.endsWith("/")) p = p.substring(0, p.length - 1);
        return p;
    }

    readonly property string directory: {
        var dir = Preferences.theme.wallpaperDirectory;
        if (!dir || dir === "")
            return defaultDirectory;
        if (dir.startsWith("~"))
            dir = Quickshell.env("HOME") + dir.substring(1);
        dir = _stripTrailingSlash(dir);
        return dir;
    }

    property var wallpapers: []
    property bool listLoaded: false

    function listDir() {
        checkProc.command = ["sh", "-c", "[ -d \"" + directory + "\" ] && echo OK || echo MISSING"];
        checkProc.running = true;
    }

    function _effectiveDir() {
        // Fall back to defaultDirectory if the configured one is missing.
        // Common cause: stale `theme.wallpaperDirectory` (renamed/moved folder,
        // wrong case on a case-sensitive filesystem, trailing slash etc.).
        if (directory === defaultDirectory) return directory;
        return _lastDirOk ? directory : defaultDirectory;
    }

    // Cached result of the last `listDir()` existence check. Optimistically
    // true so that the initial synchronous reads (before checkProc finishes)
    // don't temporarily drop the user back to the default directory.
    property bool _lastDirOk: true

    Process {
        id: checkProc
        stdout: StdioCollector {
            onStreamFinished: {
                rotation._lastDirOk = text.trim() === "OK";
                if (!rotation._lastDirOk) {
                    Log.warn("WallpaperRotation", "Configured wallpaper directory does not exist: "
                        + rotation.directory + " — falling back to " + rotation.defaultDirectory);
                }
                var d = rotation._effectiveDir();
                listProc.command = ["sh", "-c", "ls -1 -- \"" + d + "\" 2>/dev/null"];
                listProc.running = true;
            }
        }
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
                    var fullPath = rotation._effectiveDir() + "/" + name;
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
        pushToGreeter(next);
    }

    // Push the user's current wallpaper into /var/lib/whisker/wallpapers/<USER>
    // so the greetd greeter (running as the `greeter` user with no access to
    // $HOME) can render it as a static background.
    //
    // /var/lib/whisker/wallpapers is owned by root:root 0755 -- users cannot
    // write into it directly, so we delegate to the `whisker` binary which
    // owns that path (typically setuid / polkit-helpered). This mirrors the
    // existing pattern used by UserMenu.qml for the profile icon:
    //
    //     `whisker users <USER> icon <path>`
    //
    // The greeter-side handler for the `wallpaper` subcommand is expected to:
    //   - for images:  copy/symlink the file to /var/lib/whisker/wallpapers/<USER>
    //   - for videos:  extract a single frame at theme.videoWallpaper.fps via
    //                  ffmpeg (same fps as mpvpaper) and write a JPEG there
    //   - chmod 0644 so the `greeter` user can read it
    //
    // Gated on `Preferences.misc.applyWallpaperToGreeter` so users can opt out.
    function pushToGreeter(path) {
        if (!Preferences.misc.applyWallpaperToGreeter) return;
        if (!path || path === "") return;

        var user = Quickshell.env("USER");
        if (!user || user === "") {
            Log.warn("WallpaperRotation", "pushToGreeter: USER env is empty, skipping");
            return;
        }

        Quickshell.execDetached({
            command: ["whisker", "users", user, "wallpaper", path]
        });
        Log.info("WallpaperRotation", "pushToGreeter: " + path + " for " + user);
    }

    Component.onCompleted: listDir()
}