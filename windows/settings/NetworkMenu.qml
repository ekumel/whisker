import QtQuick
import QtQuick.Layouts
import Quickshell.Networking as QsNet
import qs.preferences
import qs.components
import qs.modules
import qs.services

BaseMenu {
    id: root
    title: Translations.tr("settings.network")
    description: Translations.tr("settings.manage_network")
    
    enum NMState {
        Wifi, 
        Ethernet
    }

    property bool error: false
    property string errorNetworkName: ""
    property string errorMessage: ""

    property int state: NetworkMenu.Wifi

    Item {
        Layout.fillWidth: true
        height: bg.height

        StyledRectangle {
            id: bg
            anchors.fill: tabContainer
            radius: 200
            color: Appearance.colors.m3surface_container_high
        }

        RowLayout {
            id: tabContainer
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            StyledButton {
                icon: "signal_wifi_4_bar"
                text: Translations.tr("settings.wifi_tab")
                iconSize: 28
                iconGap: 10
                radius: 200
                vPadding: 0
                implicitWidth: 200
                checked: root.state === NetworkMenu.Wifi
                base_bg: checked ? Appearance.colors.m3secondary_container : "transparent"
                base_fg: checked ? Appearance.colors.m3secondary : Appearance.colors.m3on_surface_variant
                onClicked: () => {
                    root.state = NetworkMenu.Wifi;
                }
                label.font.pixelSize: 16
            }
            StyledButton {
                icon: "settings_ethernet"
                text: Translations.tr("settings.ethernet_tab")
                iconSize: 28
                iconGap: 10
                radius: 200
                vPadding: 0

                implicitWidth: 200
                checked: root.state === NetworkMenu.Ethernet
                base_bg: checked ? Appearance.colors.m3secondary_container : "transparent"
                base_fg: checked ? Appearance.colors.m3secondary : Appearance.colors.m3on_surface_variant
                onClicked: () => {
                    root.state = NetworkMenu.Ethernet;
                }
                label.font.pixelSize: 16
            }
        }
    }

    ColumnLayout {
        id: wifiMenu
        Layout.fillWidth: true
        visible: root.state === NetworkMenu.Wifi
        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.95
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.medium
                easing.type: Appearance.animation.easing
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animation.medium
                easing.type: Appearance.animation.easing
            }
        }
        
        BaseCard {
            BaseRowCard {
                cardSpacing: 0
                verticalPadding: Network.wifiEnabled ? 10 : 0
                cardMargin: 0
                StyledText {
                    text: powerSwitch.checked ? Translations.tr("settings.wifi_status_on") : Translations.tr("settings.wifi_status_off")
                    font.pixelSize: 16
                    font.bold: true
                    color: Appearance.colors.m3on_background
                }
                Item { Layout.fillWidth: true }
                StyledSwitch {
                    id: powerSwitch
                    checked: Network.wifiEnabled
                    onToggled: Network.enableWifi(checked)
                }
            }

            BaseRowCard {
                visible: Network.wifiEnabled
                cardSpacing: 0
                verticalPadding: 10
                cardMargin: 0
                ColumnLayout {
                    spacing: 2
                    StyledText {
                        text: Translations.tr("settings.scanning_label")
                        font.pixelSize: 16
                        color: Appearance.colors.m3on_background
                    }
                    StyledText {
                        text: Translations.tr("settings.scanning_desc")
                        font.pixelSize: 12
                        color: Colors.opacify(Appearance.colors.m3on_background, 0.6)
                    }
                }
                Item { Layout.fillWidth: true }
                StyledSwitch {
                    checked: Network.wifiDevice.scannerEnabled
                    onToggled: {
                        Network.wifiDevice.scannerEnabled = checked
                    }
                }
            }
        }

        InfoCard {
            visible: root.error
            icon: "error"
            backgroundColor: Appearance.colors.m3error
            contentColor: Appearance.colors.m3on_error
            title: Translations.tr("settings.failed_to_connect", Network.lastNetworkAttempt)
            description: root.errorMessage
        }

        BaseCard {
            visible: !!Network.wifiNetwork
            StyledText {
                text: Translations.tr("settings.active_connection")
                font.pixelSize: 18
                font.bold: true
                color: Appearance.colors.m3on_background
            }

            NetworkCard {
                connection: Network.wifiNetwork
                menu: root
                isActive: true
                showDisconnect: true
            }
        }


        BaseCard {
            visible: Network.connections.filter(c => c.type === "ethernet").length > 0
            StyledText {
                text: Translations.tr("settings.ethernet_tab")
                font.pixelSize: 18
                font.bold: true
                color: Appearance.colors.m3on_background
            }

            Repeater {
                model: Network.connections.filter(c => c.type === "ethernet" && !c.active)
                delegate: NetworkCard {
                    connection: modelData
                    menu: root
                    showConnect: true
                }
            }
        }

        BaseCard {
            visible: Network.wifiEnabled
            StyledText {
                text: Translations.tr("settings.available_wifi_networks")
                font.pixelSize: 18
                font.bold: true
                color: Appearance.colors.m3on_background
            }

            RowLayout {
                opacity: 0.4
                spacing: 10
                Layout.alignment: Qt.AlignHCenter

                visible: Network.wifiEnabled &&
                        Network.wifiDevice &&
                        Network.wifiDevice.networks.values.filter(n => n && !n.connected).length === 0 &&
                        !Network.wifiDevice.scanning

                MaterialIcon {
                    icon: "signal_wifi_bad"
                    size: 64
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillHeight: true
                    color: Appearance.colors.m3on_surface_variant
                }
                StyledText {
                    Layout.fillHeight: true

                    verticalAlignment: Text.AlignVCenter
                    text: Translations.tr("settings.no_networks_found")
                    font.bold: true
                    font.pixelSize: 18
                    color: Appearance.colors.m3on_surface_variant
                }

            }

            Repeater {
                model: Network.wifiDevice.networks.values.filter(c => c && !c.connected)
                delegate: NetworkCard {
                    required property var modelData
                    connection: modelData
                    menu: root
                    showConnect: true
                }
            }
        }

    }
    ColumnLayout {
        id: ethernetMenu
        Layout.fillWidth: true
        visible: root.state === NetworkMenu.Ethernet
        opacity: visible ? 1 : 0
        scale: visible ? 1 : 0.95
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.medium
                easing.type: Appearance.animation.easing
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Appearance.animation.medium
                easing.type: Appearance.animation.easing
            }
        }
        
        BaseCard {
            RowLayout {
                opacity: 0.4
                spacing: 10
                Layout.alignment: Qt.AlignHCenter

                MaterialIcon {
                    icon: "construction"
                    size: 64
                    verticalAlignment: Text.AlignVCenter
                    Layout.fillHeight: true
                    color: Appearance.colors.m3on_surface_variant
                }
                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillHeight: true

                    StyledText {
                        text: Translations.tr("settings.work_in_progress")
                        font.bold: true
                        font.pixelSize: 18
                        color: Appearance.colors.m3on_surface_variant
                    }
                    StyledText {
                        text: Translations.tr("settings.work_in_progress_desc")
                        font.pixelSize: 14
                        color: Appearance.colors.m3on_surface_variant
                    }
                }
            }
        }
    }
}
