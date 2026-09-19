import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.components
import qs.preferences
import qs.services

BaseMenu {
    title: Translations.tr("settings.widgets")
    description: Translations.tr("settings.widgets_description")

    BaseCard {
        ColumnLayout {
            width: parent.width
            spacing: 16

            SectionTitle { icon: "bar_chart"; text: Translations.tr("settings.section_visualizers") }
            SwitchOption { title: Translations.tr("settings.switch_enable_visualizers"); description: Translations.tr("settings.switch_enable_visualizers_desc"); prefField: "misc.cavaEnabled" }
            SwitchOption { title: Translations.tr("settings.switch_render_overview"); description: Translations.tr("settings.switch_render_overview_desc"); prefField: "misc.renderOverviewWindows" }
        }
    }

    BaseCard {
        ColumnLayout {
            width: parent.width
            spacing: 16

            SectionTitle { icon: "lyrics"; text: Translations.tr("settings.section_music_widget") }
            SwitchOption { title: Translations.tr("settings.switch_show_lyrics"); description: Translations.tr("settings.switch_show_lyrics_desc"); prefField: "widgets.showLyrics" }
            SwitchOption { visible: Preferences.widgets.showLyrics; title: Translations.tr("settings.switch_lyrics_overlay"); description: Translations.tr("settings.switch_lyrics_overlay_desc"); prefField: "widgets.lyricsAsOverlay" }
            SwitchOption { visible: Preferences.widgets.showLyrics; title: Translations.tr("settings.switch_translate_lyrics"); description: Translations.tr("settings.switch_translate_lyrics_desc"); prefField: "misc.translateLyrics" }
            TextFieldOption { visible: Preferences.misc.translateLyrics && Preferences.widgets.showLyrics; title: Translations.tr("settings.field_translation_language"); description: Translations.tr("settings.field_translation_language_desc"); prefField: "misc.lyricsLanguage"; placeholder: "en" }

            Item {
                visible: Preferences.misc.translateLyrics && Preferences.widgets.showLyrics;
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialIcon { icon: "translate"; font.pixelSize: 32; color: Colors.opacify(Appearance.colors.m3on_surface, 0.3); Layout.alignment: Qt.AlignHCenter }
                    StyledText { text: Translations.tr("common.powered_by", "Google Translate"); font.pixelSize: 11; color: Colors.opacify(Appearance.colors.m3on_surface, 0.5); Layout.alignment: Qt.AlignHCenter }
                }
            }
        }
    }

    BaseCard {
        ColumnLayout {
            width: parent.width
            spacing: 16

            SectionTitle { icon: "schedule"; text: Translations.tr("settings.section_desktop") }
            SwitchOption { title: Translations.tr("settings.switch_desktop_clock"); description: Translations.tr("settings.switch_desktop_clock_desc"); prefField: "widgets.desktop.clock" }
            SwitchOption { title: Translations.tr("settings.switch_desktop_player"); description: Translations.tr("settings.switch_desktop_player_desc"); prefField: "widgets.desktop.player" }
        }
    }

    BaseCard {
        ColumnLayout {
            width: parent.width
            spacing: 16

            SectionTitle { icon: "horizontal_rule"; text: Translations.tr("settings.section_bar") }
            SwitchOption { title: Translations.tr("settings.switch_battery_animation"); description: Translations.tr("settings.switch_battery_animation_desc"); prefField: "widgets.animatedBattery" }
        }
    }

    BaseCard {
        ColumnLayout {
            width: parent.width
            spacing: 16

            SectionTitle { icon: "code"; text: Translations.tr("settings.section_github_widget") }
            TextFieldOption { title: Translations.tr("settings.field_github_username"); description: Translations.tr("settings.field_github_username_desc"); prefField: "misc.githubUsername"; placeholder: "octocat" }

            Item {
                visible: Preferences.misc.githubUsername !== ""
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                StyledText { anchors.centerIn: parent; text: Translations.tr("settings.preview"); font.pixelSize: 13; font.family: "Outfit SemiBold"; color: Colors.opacify(Appearance.colors.m3on_surface, 0.6) }
            }

            GithubContribCalendar { visible: Preferences.misc.githubUsername !== ""; Layout.alignment: Qt.AlignHCenter }
        }
    }

    BaseCard {
        ColumnLayout {
            width: parent.width
            spacing: 16

            SectionTitle { icon: "tune"; text: Translations.tr("settings.section_misc") }
            SwitchOption {
                title: Translations.tr("settings.switch_stats_overlay")
                description: Translations.tr("settings.switch_stats_overlay_desc")
                prefField: "misc.showStatsOverlay"
            }

            SwitchOption {
                title: Translations.tr("settings.switch_activate_linux")
                description: Translations.tr("settings.switch_activate_linux_desc")
                prefField: "misc.activateLinuxOverlay"
            }

        }
    }
}
