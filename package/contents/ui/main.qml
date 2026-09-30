import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // Plasma supplies the panel icon and handles opening this representation.
    Plasmoid.icon: "dialog-messages"
    // WebEngine focus changes can otherwise dismiss the popup while typing.
    // The shortcut still toggles it closed.
    hideOnWindowDeactivate: false
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                             || Plasmoid.formFactor === PlasmaCore.Types.Vertical
                             ? compactRepresentation : fullRepresentation

    fullRepresentation: ChatWebView {
        popupExpanded: root.expanded
        Layout.minimumWidth: 320
        Layout.minimumHeight: 400
        Layout.preferredWidth: 440
        Layout.preferredHeight: 600
    }
}
