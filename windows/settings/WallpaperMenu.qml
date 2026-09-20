import Quickshell.Widgets
import Quickshell
import Quickshell.Io

import QtQuick
import QtQuick.Layouts
import QtMultimedia

import qs.modules
import qs.components
import qs.preferences
import qs.services

BaseMenu {
    id: root
    required property var screen
    title: Translations.tr("settings.wallpaper")
    description: Translations.tr("settings.wallpaper_description")

    BaseRowCard {
        cardMargin: 0
        verticalPadding: 8
        id: wpSelectorCard
        property var wallpapers: []
        property var filteredWallpapers: []
        property int currentPage: 0
        readonly property int gridColumns: 5
        // Two rows per page keeps the number of live video thumbnails low
        // enough that paging stays smooth.
        readonly property int pageSize: gridColumns * 2
        readonly property int totalPages: Math.max(1, Math.ceil(filteredWallpapers.length / pageSize))
        readonly property var pagedWallpapers: filteredWallpapers.slice(currentPage * pageSize, (currentPage + 1) * pageSize)
        readonly property int itemWidth: Math.floor((wpFlick.width - 20 - (gridColumns - 1) * 10) / gridColumns)

        onWallpapersChanged: updateFiltered()
        onFilteredWallpapersChanged: currentPage = 0
        onTotalPagesChanged: currentPage = Math.min(currentPage, totalPages - 1)

        Connections {
            target: WallpaperRotation
            function onWallpapersChanged() { wpSelectorCard.updateFiltered() }
            function onDirectoryChanged() { wpSelectorCard.updateFiltered() }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 10

                StyledTextField {
                    id: searchInput
                    Layout.fillWidth: true
                    icon: "search"
                    placeholder: Translations.tr("settings.search_wallpapers")
                    fieldPadding: 12
                    iconSize: 20
                    font.pixelSize: 14
                    onTextChanged: wpSelectorCard.updateFiltered()
                }

                StyledButton {
                    id: imageFilterBtn
                    icon: "image"
                    iconSize: 20
                    checkable: true
                    checked: true
                    onToggled: function(checked) {
                        if (!checked && !videoFilterBtn.checked) {
                            checked = true
                            imageFilterBtn.checked = true
                        }
                        wpSelectorCard.updateFiltered()
                    }
                }

                StyledButton {
                    id: videoFilterBtn
                    icon: "videocam"
                    iconSize: 20
                    checkable: true
                    checked: true
                    onToggled: function(checked) {
                        if (!checked && !imageFilterBtn.checked) {
                            checked = true
                            videoFilterBtn.checked = true
                        }
                        wpSelectorCard.updateFiltered()
                    }
                }
            }

            Flickable {
                id: wpFlick
                Layout.fillWidth: true
                // Fit the two rows on this page instead of reserving the old
                // multi-row viewport, so the card doesn't leave a big gap.
                Layout.preferredHeight: Math.max(120, Math.min(460, contentHeight))
                clip: true
                contentWidth: width
                contentHeight: gridContent.childrenRect.height
                boundsBehavior: Flickable.StopAtBounds

                Grid {
                    id: gridContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    columns: wpSelectorCard.gridColumns
                    spacing: 10

                    Repeater {
                        model: wpSelectorCard.pagedWallpapers

                        delegate: Item {
                            width: wpSelectorCard.itemWidth
                            height: width * root.screen.height / root.screen.width + 35
                            property bool hovered: mouseArea.containsMouse
                            property bool selected: Preferences.theme.wallpaper === modelData
                            property bool itemIsVideo: Utils.isVideo(modelData)

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !wpSetProc.running
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (selected)
                                        return

                                    wpSetProc.command = [
                                        "whisker",
                                        "wallpaper",
                                        modelData
                                    ]

                                    wpSetProc.running = true
                                    WallpaperRotation.pushToGreeter(modelData)
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 5

                                ClippingRectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: parent.width * root.screen.height / root.screen.width
                                    radius: 10
                                    color: Appearance.colors.m3surface_container_high

                                    LoadingIcon {
                                        anchors.centerIn: parent
                                    }
                                    Image {
                                        anchors.fill: parent
                                        source: !itemIsVideo ? modelData : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        // Thumbnail: downscale to a max of 120px on the
                                        // longest side to speed up loading and rendering.
                                        sourceSize.width: Math.min(parent.width, 120)
                                        sourceSize.height: Math.min(parent.height, 120)
                                        visible: !itemIsVideo
                                    }

                                    Video {
                                        id: thumbVideo
                                        anchors.fill: parent
                                        source: {
                                            if (!itemIsVideo) return ""
                                            return modelData.startsWith("file://") ? modelData : "file://" + modelData
                                        }
                                        autoPlay: true
                                        muted: true
                                        visible: itemIsVideo
                                        position: 100
                                        Component.onCompleted: {
                                            thumbVideo.pause();
                                        }
                                        Connections {
                                            target: mouseArea
                                            function onContainsMouseChanged() {
                                                if (itemIsVideo) {
                                                    if (mouseArea.containsMouse)
                                                        thumbVideo.play();
                                                    else {
                                                        thumbVideo.pause();
                                                        thumbVideo.position = 100;
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    StyledRectangle {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 5
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: Colors.opacify(Appearance.colors.m3primary, 0.9)
                                        visible: itemIsVideo

                                        MaterialIcon {
                                            anchors.centerIn: parent
                                            icon: "play_circle"
                                            font.pixelSize: 16
                                            color: Appearance.colors.m3on_primary
                                        }
                                    }

                                    StyledRectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: "transparent"
                                        border.width: selected ? 3 : (hovered ? 2 : 1)
                                        border.color: selected
                                            ? Appearance.colors.m3primary
                                            : Colors.opacify(Appearance.colors.m3on_background, hovered ? 0.6 : 0.3)
                                    }
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.split('/').pop()
                                    color: Appearance.colors.m3on_surface
                                    font.pixelSize: 11
                                    elide: Text.ElideMiddle
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 10

                StyledText {
                    Layout.fillWidth: true
                    text: wpSelectorCard.filteredWallpapers.length === 1
                        ? Translations.tr("settings.wallpapers_found_one", wpSelectorCard.filteredWallpapers.length)
                        : Translations.tr("settings.wallpapers_found_many", wpSelectorCard.filteredWallpapers.length)
                    color: Appearance.colors.m3on_surface_variant
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignLeft
                }

                StyledButton {
                    icon: "chevron_left"
                    iconSize: 18
                    enabled: wpSelectorCard.currentPage > 0
                    onClicked: wpSelectorCard.currentPage = Math.max(0, wpSelectorCard.currentPage - 1)
                }

                StyledText {
                    text: (wpSelectorCard.filteredWallpapers.length === 0)
                        ? "0 / 0"
                        : (wpSelectorCard.currentPage + 1) + " / " + wpSelectorCard.totalPages
                    color: Appearance.colors.m3on_surface
                    font.pixelSize: 12
                    Layout.preferredWidth: 60
                    horizontalAlignment: Text.AlignHCenter
                }

                StyledButton {
                    icon: "chevron_right"
                    iconSize: 18
                    enabled: wpSelectorCard.currentPage < wpSelectorCard.totalPages - 1
                    onClicked: wpSelectorCard.currentPage = Math.min(wpSelectorCard.totalPages - 1, wpSelectorCard.currentPage + 1)
                }
            }

            StyledRectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.opacify(Appearance.colors.m3surface, 0.4)
                visible: wpSetProc.running
                z: 999

                LoadingIcon {
                    anchors.centerIn: parent
                    visible: true
                }
            }
        }

        function updateFiltered() {
            var result = []
            var searchTerm = searchInput.text.toLowerCase()

            var pool = WallpaperRotation.wallpapers && WallpaperRotation.wallpapers.length > 0
                ? WallpaperRotation.wallpapers
                : wallpapers

            for (var i = 0; i < pool.length; i++) {
                var wp = pool[i]
                var fileName = wp.split('/').pop().toLowerCase()
                var matchesSearch = !searchTerm || fileName.indexOf(searchTerm) !== -1
                var wpIsVideo = Utils.isVideo(wp)
                var matchesFilter = (imageFilterBtn.checked && !wpIsVideo) ||
                                    (videoFilterBtn.checked && wpIsVideo)

                if (matchesSearch && matchesFilter) {
                    result.push(wp)
                }
            }

            filteredWallpapers = result
        }

        Process {
            id: wpFetchProc
            command: ["whisker", "list", "wallpapers"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    var lines = this.text.trim().split("\n").filter(function(s) { return s.length > 0 })
                    wpSelectorCard.wallpapers = lines
                }
            }
        }

        Process {
            id: wpSetProc
            command: []
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    Quickshell.execDetached({
                        command: [
                            "whisker",
                            "notify",
                            "Whisker",
                            Translations.tr("settings.wallpaper_changed")
                        ]
                    })
                }
            }
        }
    }

    BaseRowCard {
        SwitchOption {
            title: Translations.tr("settings.switch_animation")
            description: Translations.tr("settings.switch_animation_desc")
            prefField: "theme.switchAnimation"
        }
    }

    BaseRowCard {
        SwitchOption {
            title: Translations.tr("settings.switch_timed_rotation")
            description: Translations.tr("settings.switch_timed_rotation_desc")
            prefField: "theme.rotationEnabled"
        }
        SliderOption {
            visible: Preferences.theme.rotationEnabled
            title: Translations.tr("settings.slider_rotation_interval")
            description: Translations.tr("settings.slider_rotation_interval_desc")
            prefField: "theme.rotationIntervalMinutes"
            from: 1
            to: 720
            stepSize: 1
        }
    }

    BaseRowCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.rotation_mode")
                    font.pixelSize: 15
                    color: Appearance.colors.m3on_surface
                }
                StyledText {
                    text: Translations.tr("settings.rotation_mode_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            StyledDropDown {
                implicitWidth: 160
                model: [
                    Translations.tr("settings.rotation_mode_sequential"),
                    Translations.tr("settings.rotation_mode_random")
                ]
                currentIndex: Preferences.theme.rotationMode
                onSelectedIndexChanged: (idx) => {
                    if (idx < 0) return;
                    Quickshell.execDetached({
                        command: ['whisker', 'prefs', 'set', 'theme.rotationMode', idx.toString()]
                    });
                }
            }
        }
    }

    BaseRowCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.fill_mode")
                    font.pixelSize: 15
                    color: Appearance.colors.m3on_surface
                }
                StyledText {
                    text: Translations.tr("settings.fill_mode_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            StyledDropDown {
                implicitWidth: 180
                model: [
                    Translations.tr("settings.fill_mode_crop"),
                    Translations.tr("settings.fill_mode_fit"),
                    Translations.tr("settings.fill_mode_stretch"),
                    Translations.tr("settings.fill_mode_tile")
                ]
                currentIndex: Preferences.theme.fillMode
                onSelectedIndexChanged: (idx) => {
                    if (idx < 0) return;
                    Quickshell.execDetached({
                        command: ['whisker', 'prefs', 'set', 'theme.fillMode', idx.toString()]
                    });
                }
            }
        }
    }

    BaseRowCard {
        TextFieldOption {
            title: Translations.tr("settings.field_wallpaper_directory")
            description: Translations.tr("settings.field_wallpaper_directory_desc")
            prefField: "theme.wallpaperDirectory"
            placeholder: "~/Pictures/wallpapers"
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Item { Layout.fillWidth: true }
            StyledButton {
                text: Translations.tr("settings.refresh_list")
                icon: "refresh"
                onClicked: WallpaperRotation.listDir()
            }
        }
    }

    BaseRowCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.apply_to_greeter")
                    font.pixelSize: 15
                    color: Appearance.colors.m3on_surface
                }
                StyledText {
                    text: Translations.tr("settings.apply_to_greeter_desc", "")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            StyledSwitch {
                checked: Preferences.misc.applyWallpaperToGreeter
                onToggled: {
                    Quickshell.execDetached({ command: ['whisker', 'prefs', 'set', 'misc.applyWallpaperToGreeter', checked] })
                }
            }
        }
    }

    BaseCard {
        SliderOption {
            title: Translations.tr("settings.slider_video_fps")
            description: Translations.tr("settings.slider_video_fps_desc")
            prefField: "theme.videoWallpaper.fps"
            from: 0
            to: 144
            stepSize: 1
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.switch_hardware_decoding")
                    font.pixelSize: 15
                    color: Appearance.colors.m3on_surface
                }
                StyledText {
                    text: Translations.tr("settings.switch_hardware_decoding_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            StyledSwitch {
                checked: Preferences.theme.videoWallpaper.hwdec
                onToggled: {
                    Quickshell.execDetached({ command: ['whisker', 'prefs', 'set', 'theme.videoWallpaper.hwdec', checked] })
                }
            }
        }
    }

    BaseCard {
        StyledText {
            text: Translations.tr("settings.pause_video_when")
            font.pixelSize: 14
            font.bold: true
            color: Appearance.colors.m3on_surface
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.switch_pause_on_any_window")
                    font.pixelSize: 15
                    color: Appearance.colors.m3on_surface
                }
                StyledText {
                    text: Translations.tr("settings.switch_pause_on_any_window_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            StyledSwitch {
                checked: Preferences.theme.videoWallpaper.pauseOnAnyWindow
                onToggled: {
                    Quickshell.execDetached({ command: ['whisker', 'prefs', 'set', 'theme.videoWallpaper.pauseOnAnyWindow', checked] })
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.switch_pause_on_floating")
                    font.pixelSize: 15
                    color: Appearance.colors.m3on_surface
                }
                StyledText {
                    text: Translations.tr("settings.switch_pause_on_floating_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            StyledSwitch {
                checked: Preferences.theme.videoWallpaper.pauseOnFloating
                onToggled: {
                    Quickshell.execDetached({ command: ['whisker', 'prefs', 'set', 'theme.videoWallpaper.pauseOnFloating', checked] })
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.switch_pause_on_tiled")
                    font.pixelSize: 15
                    color: Appearance.colors.m3on_surface
                }
                StyledText {
                    text: Translations.tr("settings.switch_pause_on_tiled_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            StyledSwitch {
                checked: Preferences.theme.videoWallpaper.pauseOnTiled
                onToggled: {
                    Quickshell.execDetached({ command: ['whisker', 'prefs', 'set', 'theme.videoWallpaper.pauseOnTiled', checked] })
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.switch_pause_on_fullscreen")
                    font.pixelSize: 15
                    color: Appearance.colors.m3on_surface
                }
                StyledText {
                    text: Translations.tr("settings.switch_pause_on_fullscreen_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }
            Item { Layout.fillWidth: true }
            StyledSwitch {
                checked: Preferences.theme.videoWallpaper.pauseOnFullscreen
                onToggled: {
                    Quickshell.execDetached({ command: ['whisker', 'prefs', 'set', 'theme.videoWallpaper.pauseOnFullscreen', checked] })
                }
            }
        }
    }
}