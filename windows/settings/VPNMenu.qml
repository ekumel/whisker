import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.preferences
import qs.components
import qs.modules
import qs.services
BaseMenu {
    title: Translations.tr("settings.vpn")
    description: Translations.tr("settings.manage_vpn")
    InfoCard {
        icon: "info"
        backgroundColor: Appearance.colors.m3primary
        contentColor: Appearance.colors.m3on_primary
        title: Translations.tr("settings.vpn_warning_title")
        description: Translations.tr("settings.vpn_warning_desc")
    }

    InfoCard {
        visible: VPN.lastErrorMessage !== "" && VPN.lastErrorMessage !== "ok"
        icon: "error"
        backgroundColor: Appearance.colors.m3error
        contentColor: Appearance.colors.m3on_error
        title: Translations.tr("settings.failed_vpn")
        description: VPN.lastErrorMessage
    }

    BaseCard {
        StyledText {
            text: Translations.tr("settings.vpn")
            font.pixelSize: 20
            font.bold: true
            color: Appearance.colors.m3on_background
        }
        RowLayout {
            StyledTextField {
                id: pathInput
                padding: 10
                leftPadding: undefined
                Layout.fillWidth: true
            }
            StyledButton {
                text: Translations.tr("settings.import_wireguard")
                onClicked: {
                    Log.info("windows/settings/VPNMenu.qml", "OK " + pathInput.text)
                    VPN.importWireguard(pathInput.text)
                }
            }
        }
        ExpandableCard {
            id: vpnList
            title: VPN.active?.name ?? Translations.tr("settings.vpn_not_connected")
            icon: "vpn_key"
            Repeater {
                model: VPN.connections
                delegate: BaseRowCard {
                    MaterialIcon {
                        icon: "vpn_key"
                        color: Appearance.colors.m3on_background
                        font.pixelSize: 32
                    }
                    StyledText {
                        text: modelData.name
                        color: Appearance.colors.m3on_background
                    }
                    MouseArea {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        onClicked: {
                            if (modelData.active) VPN.disconnectVpn();
                            else VPN.connectVpn(modelData.name);
                            vpnList.expanded = false;
                        }
                    }
                }
            }
        }

    }

}
