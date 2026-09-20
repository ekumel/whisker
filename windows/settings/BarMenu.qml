import Quickshell.Widgets
import Quickshell
import Quickshell.Io

import QtQuick
import QtQuick.Layouts

import qs.modules
import qs.components
import qs.preferences

BaseMenu {
    title: Translations.tr("settings.bar")
    description: Translations.tr("settings.bar_description")

    BaseCard {

        ColumnLayout {
            StyledText {
                text: Translations.tr("settings.bar_position")
                font.pixelSize: 16
                color: Appearance.colors.m3on_background
            }

            StyledDropDown {
                Layout.fillWidth: true
                label: Translations.tr("settings.bar_position_label")
                model: [
                    Translations.tr("settings.bar_position_left"),
                    Translations.tr("settings.bar_position_bottom"),
                    Translations.tr("settings.bar_position_top"),
                    Translations.tr("settings.bar_position_right")
                ]

                currentIndex: {
                    const pos = Preferences.bar.position
                    const positions = ["left", "bottom", "top", "right"]
                    return positions.indexOf(pos)
                }

                onSelectedIndexChanged: (index) => {
                    const positions = ["left", "bottom", "top", "right"]
                    Quickshell.execDetached({
                        command: ["whisker", "prefs", "set", "bar.position", positions[index]]
                    })
                }
            }
        }

        SwitchOption {
            title: Translations.tr("settings.switch_keep_bar_opaque")
            description: Translations.tr("settings.switch_keep_bar_opaque_desc")
            prefField: "bar.keepOpaque"
        }

        SwitchOption {
            title: Translations.tr("settings.switch_small_bar")
            description: Translations.tr("settings.switch_small_bar_desc")
            prefField: "bar.small"
        }

        SliderOption {
            visible: Preferences.bar.small && Preferences.horizontalBar()
            title: Translations.tr("settings.slider_bar_padding")
            description: Translations.tr("settings.slider_bar_padding_desc")
            prefField: "bar.padding"
            from: 0
            to: 500
            stepSize: 50
        }

        SwitchOption {
            title: Translations.tr("settings.switch_auto_hide_bar")
            description: Translations.tr("settings.switch_auto_hide_bar_desc")
            prefField: "bar.autoHide"
        }

        SwitchOption {
            title: Translations.tr("settings.switch_floating_mode")
            description: Translations.tr("settings.switch_floating_mode_desc")
            prefField: "bar.floating"
        }

        SwitchOption {
            title: Translations.tr("settings.switch_render_overview")
            description: Translations.tr("settings.switch_render_overview_desc")
            prefField: "misc.renderOverviewWindows"
        }
    }
}