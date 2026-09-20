import QtQuick
import QtQuick.Layouts
import qs.modules
import qs.components

Item {
    id: root
    anchors.fill: parent
    property bool startAnim: false
    Component.onCompleted: {
        Qt.callLater(() => {
            root.startAnim = true;
        });
    }
    opacity: startAnim ? 1 : 0
    scale: startAnim ? 1 : 0.95
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
    property var messages: [
        Translations.tr("settings.fallback_title_1"),
        Translations.tr("settings.fallback_title_2"),
        Translations.tr("settings.fallback_title_3")
    ]
    property string randomMessage: messages[Math.floor(Math.random() * messages.length)]

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        MaterialIcon {
            icon: "error_outline"
            font.pixelSize: 80
            color: Colors.opacify(Appearance.colors.m3on_surface, 0.3)
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            text: randomMessage
            font.pixelSize: 20
            font.family: "Outfit SemiBold"
            color: Colors.opacify(Appearance.colors.m3on_surface, 0.6)
            Layout.alignment: Qt.AlignHCenter
        }

        StyledText {
            text: Translations.tr("settings.fallback_subtitle")
            font.pixelSize: 14
            color: Colors.opacify(Appearance.colors.m3on_surface, 0.4)
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
