import QtQuick
import QtQuick.Layouts
import qs.preferences
import qs.components
import qs.modules
import qs.services
import Quickshell.Bluetooth as QsBluetooth

BaseMenu {
    title: Translations.tr("settings.bluetooth")
    description: Translations.tr("settings.manage_bluetooth")

    BaseCard {
        BaseRowCard {
            cardSpacing: 0
            verticalPadding: Bluetooth.enabled ? 10 : 0
            cardMargin: 0
            StyledText {
                text: powerSwitch.checked ? Translations.tr("settings.bluetooth_power_on") : Translations.tr("settings.bluetooth_power_off")
                font.pixelSize: 16
                font.bold: true
                color: Appearance.colors.m3on_background
            }
            Item {
                Layout.fillWidth: true
            }
            StyledSwitch {
                id: powerSwitch
                checked: Bluetooth.enabled
                onToggled: Bluetooth.setEnabled(checked)
            }
        }
        BaseRowCard {
            visible: Bluetooth.enabled
            cardSpacing: 0
            verticalPadding: 10
            cardMargin: 0
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.switch_discoverable")
                    font.pixelSize: 16
                    color: Appearance.colors.m3on_background
                }
                StyledText {
                    text: Translations.tr("settings.switch_discoverable_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_background, 0.6)
                }
            }
            Item {
                Layout.fillWidth: true
            }
            StyledSwitch {
                checked: Bluetooth.discoverable
                onToggled: Bluetooth.setDiscoverable(checked)
            }
        }
        BaseRowCard {
            visible: Bluetooth.enabled
            cardSpacing: 0
            verticalPadding: 0
            cardMargin: 0
            ColumnLayout {
                spacing: 2
                StyledText {
                    text: Translations.tr("settings.switch_bluetooth_scanning")
                    font.pixelSize: 16
                    color: Appearance.colors.m3on_background
                }
                StyledText {
                    text: Translations.tr("settings.switch_bluetooth_scanning_desc")
                    font.pixelSize: 12
                    color: Colors.opacify(Appearance.colors.m3on_background, 0.6)
                }
            }
            Item {
                Layout.fillWidth: true
            }
            StyledSwitch {
                checked: Bluetooth.scanning
                onToggled: Bluetooth.setScanning(checked)
            }
        }
    }

    BaseCard {
        visible: Bluetooth.devices.filter(d => d.connected).length > 0
        StyledText {
            text: Translations.tr("settings.connected_devices")
            font.pixelSize: 18
            font.bold: true
            color: Appearance.colors.m3on_background
        }

        Repeater {
            id: connectedDevices
            model: Bluetooth.devices.filter(d => d.connected)
            delegate: BluetoothDeviceCard {
                device: modelData
                statusText: modelData.batteryAvailable
                    ? Translations.tr("settings.connected_battery", Math.floor(modelData.battery * 100))
                    : Translations.tr("settings.connected")
                showDisconnect: true
                showRemove: true
                usePrimary: true
            }
        }
    }

    BaseCard {
        visible: Bluetooth.enabled
        StyledText {
            text: Translations.tr("settings.paired_devices")
            font.pixelSize: 18
            font.bold: true
            color: Appearance.colors.m3on_background
        }


        RowLayout {
            opacity: 0.4
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            visible: pairedDevices.count === 0

            MaterialIcon {
                icon: "bluetooth_disabled"
                size: 64
                verticalAlignment: Text.AlignVCenter
                Layout.fillHeight: true
                color: Appearance.colors.m3on_surface_variant
            }
            StyledText {
                Layout.fillHeight: true

                verticalAlignment: Text.AlignVCenter
                text: Translations.tr("settings.no_devices_found")
                font.bold: true
                font.pixelSize: 18
                color: Appearance.colors.m3on_surface_variant
            }

        }

        Repeater {
            id: pairedDevices
            model: Bluetooth.devices.filter(d => !d.connected && d.paired)
            delegate: BluetoothDeviceCard {
                device: modelData
                statusText: Translations.tr("settings.not_connected")
                showConnect: true
                showRemove: true
            }
        }
    }

    BaseCard {
        visible: Bluetooth.defaultAdapter?.enabled
        StyledText {
            text: Translations.tr("settings.available_devices")
            font.pixelSize: 18
            font.bold: true
            color: Appearance.colors.m3on_background
        }

        Item {
            visible: discoveredDevices.count === 0 && !Bluetooth.defaultAdapter.discovering
            width: parent.width
            height: 40
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translations.tr("settings.no_new_devices")
                font.pixelSize: 14
                color: Colors.opacify(Appearance.colors.m3on_background, 0.6)
            }
        }

        Repeater {
            id: discoveredDevices
            model: Bluetooth.devices.filter(d => !d.paired && !d.connected)
            delegate: BluetoothDeviceCard {
                device: modelData
                statusText: Translations.tr("settings.discovered")
                showConnect: true
                showPair: true
            }
        }
    }
}
