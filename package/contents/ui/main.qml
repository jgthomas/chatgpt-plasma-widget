import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // Plasma supplies the panel icon and handles opening this representation.
    Plasmoid.icon: "dialog-messages"
    preferredRepresentation: compactRepresentation

    fullRepresentation: Item {
        Layout.minimumWidth: 320
        Layout.minimumHeight: 400
        Layout.preferredWidth: 440
        Layout.preferredHeight: 600

        PlasmaComponents.Label {
            anchors.centerIn: parent
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "ChatGPT browser prototype coming next"
        }
    }
}
