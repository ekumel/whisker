import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.preferences
import qs.components
import qs.components.filepicker
import qs.modules
import qs.services

BaseMenu {
    title: Translations.tr("settings.user")
    description: Translations.tr("settings.user_description")

    InfoCard {
        icon: "info"
        backgroundColor: Appearance.colors.m3tertiary
        contentColor: Appearance.colors.m3on_tertiary
        title: Translations.tr("settings.root_required")
        description: Translations.tr("settings.root_required_desc")
    }

    BaseCard {
        SectionTitle {
            icon: "portrait"
            text: Translations.tr("settings.profile_picture")
        }

        Item {
            id: userIcon
            Layout.alignment: Qt.AlignHCenter
            width: icon.width
            height: icon.height

            ProfileIcon {
                id: icon
                implicitWidth: 150
            }

            StyledButton {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                icon: "edit"
                onClicked: imagePicker.open()
            }

            Process {
                id: setPfpProc
                onExited: {
                    if (exitCode !== 0) {
                        Quickshell.execDetached(["whisker", "notify", "Whisker", Translations.tr("settings.failed_set_pfp")]);
                        return;
                    }
                    Appearance.refreshProfileImage();
                    Quickshell.execDetached(["whisker", "notify", "Whisker", Translations.tr("settings.pfp_updated")]);
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translations.tr("settings.click_edit_pfp")
            font.pixelSize: 12
            color: Appearance.colors.m3on_surface_variant
        }
    }

    BaseCard {
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            SectionTitle {
                icon: "badge"
                text: Translations.tr("settings.your_info")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: Translations.tr("settings.username")
                    color: Appearance.colors.m3on_surface_variant
                    Layout.preferredWidth: 120
                }

                StyledText {
                    text: Quickshell.env("USER")
                    color: Appearance.colors.m3on_surface
                    font.weight: Font.Medium
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: Translations.tr("settings.home")
                    color: Appearance.colors.m3on_surface_variant
                    Layout.preferredWidth: 120
                }

                StyledText {
                    text: Quickshell.env("HOME")
                    color: Appearance.colors.m3on_surface
                    font.weight: Font.Medium
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: Translations.tr("settings.shell_label")
                    color: Appearance.colors.m3on_surface_variant
                    Layout.preferredWidth: 120
                }

                StyledText {
                    text: Quickshell.env("SHELL") || Translations.tr("common.unknown")
                    color: Appearance.colors.m3on_surface
                    font.weight: Font.Medium
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: Translations.tr("settings.last_login")
                    color: Appearance.colors.m3on_surface_variant
                    Layout.preferredWidth: 120
                }

                StyledText {
                    id: lastLoginText
                    text: Translations.tr("settings.loading_dots")
                    color: Appearance.colors.m3on_surface
                    font.weight: Font.Medium
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                StyledText {
                    text: Translations.tr("settings.account_created")
                    color: Appearance.colors.m3on_surface_variant
                    Layout.preferredWidth: 120
                }

                StyledText {
                    id: accountCreatedText
                    text: Translations.tr("settings.loading_dots")
                    color: Appearance.colors.m3on_surface
                    font.weight: Font.Medium
                }
            }
        }

        Process {
            id: getLastLoginProc
            running: true
            command: ["bash", "-c", "lastlog -u " + Quickshell.env("USER") + " | tail -n 1 | awk '{print $4, $5, $6, $9}'"]
            stdout: StdioCollector {
                onStreamFinished: {
                    var result = text.trim()
                    lastLoginText.text = result !== "" && !result.includes("Never") ? result : Translations.tr("settings.never_logged_in")
                }
            }
        }

        Process {
            id: getAccountCreatedProc
            running: true
            command: ["bash", "-c", "stat -c %w " + Quickshell.env("HOME") + " 2>/dev/null || stat -c %y " + Quickshell.env("HOME")]
            stdout: StdioCollector {
                onStreamFinished: {
                    var timestamp = text.trim().split(' ')[0]
                    accountCreatedText.text = timestamp || Translations.tr("common.unknown")
                }
            }
        }
    }


    FilePicker {
        id: imagePicker
        title: Translations.tr("settings.pick_pfp")
        filterLabel: Translations.tr("settings.images")
        filters: ["png", "jpg", "jpeg", "gif", "svg", "webp"]
        onAccepted: path => {
            setPfpProc.command = ['whisker', 'users', Quickshell.env('USER'), 'icon', path];
            setPfpProc.running = true
        }
        onRejected: {
        }
    }
}
