import qs.modules
import qs.components
import qs.preferences

import QtQuick
import QtQuick.Layouts

import Quickshell

BaseMenu {
    title: Translations.tr("settings.section_misc")
    description: Translations.tr("settings.misc_description")

    BaseCard {
        SwitchOption {
            title: Translations.tr("settings.switch_enable_visualizers")
            description: Translations.tr("settings.switch_enable_visualizers_desc")
            prefField: "misc.cavaEnabled"
        }

        SwitchOption {
            title: Translations.tr("settings.switch_render_overview")
            description: Translations.tr("settings.switch_render_overview_desc")
            prefField: "misc.renderOverviewWindows"
        }

        Divider {}

        SwitchOption {
            title: Translations.tr("settings.switch_translate_lyrics")
            description: Translations.tr("settings.switch_translate_lyrics_desc")
            prefField: "misc.translateLyrics"
        }

        TextFieldOption {
            visible: Preferences.misc.translateLyrics
            title: Translations.tr("settings.field_translation_language")
            description: Translations.tr("settings.field_translation_language_desc")
            prefField: "misc.lyricsLanguage"
        }

        Divider {}

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

        Divider {}

        SwitchOption {
            title: Translations.tr("settings.switch_enable_polkit_agent")
            description: Translations.tr("settings.switch_enable_polkit_agent_desc")
            prefField: "misc.enablePolkitAgent"
        }

        Divider {}

        LanguageOption {}
    }

    component Divider: StyledRectangle {
        height: 1
        Layout.fillWidth: true
        color: Appearance.colors.m3on_surface_variant
        opacity: 0.3
    }

    component SwitchOption: RowLayout {
        id: main
        property string title: "Title"
        property string description: "Description"
        property string prefField: ''

        ColumnLayout {
            StyledText {
                text: main.title
                font.pixelSize: 16
                color: Appearance.colors.m3on_background
            }
            StyledText {
                text: main.description
                font.pixelSize: 12
                color: Colors.opacify(Appearance.colors.m3on_background, 0.6)
            }
        }

        Item {
            Layout.fillWidth: true
        }

        StyledSwitch {
            checked: Preferences[main.prefField.split('.')[0]][main.prefField.split('.')[1]]
            onToggled: {
                Quickshell.execDetached({
                    command: ['whisker', 'prefs', 'set', prefField, checked]
                });
            }
        }
    }

    component TextFieldOption: RowLayout {
        id: main
        property string title: "Title"
        property string description: "Description"
        property string prefField: ''

        ColumnLayout {
            StyledText {
                text: main.title
                font.pixelSize: 16
                color: Appearance.colors.m3on_background
            }
            StyledText {
                text: main.description
                font.pixelSize: 12
                color: Colors.opacify(Appearance.colors.m3on_background, 0.6)
            }
        }

        Item {
            Layout.fillWidth: true
        }

        StyledTextField {
            text: Preferences[main.prefField.split('.')[0]][main.prefField.split('.')[1]]
            padding: 10
            leftPadding: undefined
            implicitWidth: 200
            onTextChanged: {
                Quickshell.execDetached({
                    command: ['whisker', 'prefs', 'set', main.prefField, text.toString()]
                });
            }
        }
    }

    component LanguageOption: RowLayout {
        id: langOption
        property string title: Translations.tr("settings.language")
        property string description: Translations.tr("settings.language_description")

        ColumnLayout {
            StyledText {
                text: langOption.title
                font.pixelSize: 16
                color: Appearance.colors.m3on_background
            }
            StyledText {
                text: langOption.description
                font.pixelSize: 12
                color: Colors.opacify(Appearance.colors.m3on_background, 0.6)
            }
        }

        Item {
            Layout.fillWidth: true
        }

        StyledDropDown {
            id: langDropDown
            implicitWidth: 180

            // Index 0 is the "follow system" entry; the rest map to the
            // supported language codes.
            model: {
                const codes = Translations.availableLanguages || [];
                return [Translations.tr("settings.language_system")].concat(codes.map(c => Translations.languageName(c)));
            }

            currentIndex: {
                const saved = Preferences.misc.language;
                const codes = Translations.availableLanguages || [];
                const i = codes.indexOf(saved);
                return i >= 0 ? i + 1 : 0;
            }

            onSelectedIndexChanged: (idx) => {
                if (idx < 0) return;
                const codes = Translations.availableLanguages || [];
                const code = idx === 0 ? "" : (codes[idx - 1] || "");
                Translations.setLanguage(code);
                Quickshell.execDetached({
                    command: ['whisker', 'prefs', 'set', 'misc.language', code]
                });
            }
        }
    }
}
