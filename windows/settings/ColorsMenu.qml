import Quickshell.Widgets
import Quickshell
import Quickshell.Io

import QtQuick
import QtQuick.Layouts

import qs.modules
import qs.components
import qs.preferences


BaseMenu {
    title: Translations.tr("settings.color_scheme")
    description: Translations.tr("settings.color_scheme_description")
    BaseCard {
        ColorSchemePreview {}
        Flickable {
            id: schemeFlick
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick
            contentWidth: rowContent.childrenRect.width
            contentHeight: rowContent.childrenRect.height

            RowLayout {
                id: rowContent
                spacing: 10
                Repeater {
                    model: ['content', 'expressive', 'fidelity', 'fruit-salad', 'monochrome', 'neutral', 'rainbow', 'tonal-spot']
                    delegate: ColorSchemeCard { schemeName: modelData }
                }
            }
        }
    }

    BaseCard {
        SectionTitle { icon: "build"; text: Translations.tr("settings.configuration") }

        SwitchOption {
            id: smartSwitch
            title: Translations.tr("settings.switch_smart_theme")
            description: Translations.tr("settings.switch_smart_theme_desc")
            prefField: "theme.smart"
        }

        SwitchOption {
            title: Translations.tr("settings.switch_dark_mode")
            description: Translations.tr("settings.switch_dark_mode_desc")
            prefField: "theme.dark"
            visible: !smartSwitch.checked
        }

        SliderOption {
            title: Translations.tr("settings.slider_contrast")
            description: Translations.tr("settings.slider_contrast_desc")
            prefField: "theme.contrast"
            from: -1
            to: 1
            stepSize: 0.2
            visible: !smartSwitch.checked
        }

        SwitchOption {
            title: Translations.tr("settings.switch_color_cache")
            description: Translations.tr("settings.switch_color_cache_desc")
            prefField: "theme.useColorCache"
        }

        SwitchOption {
            title: Translations.tr("settings.switch_run_user_matugen")
            description: Translations.tr("settings.switch_run_user_matugen_desc")
            prefField: "theme.runUserMatugenTemplate"
        }
    }
}
