import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property int popupTargetWidth: Math.max(320, Math.min(1600, Math.round(screenGeometry.width * 0.3)))

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
        Layout.preferredWidth: root.popupTargetWidth
        // Plasma remembers a manually sized popup; keep older values from
        // overriding the screen-relative width while we test this layout.
        Layout.maximumWidth: root.popupTargetWidth
        Layout.preferredHeight: Math.max(400, Math.min(1400, root.screenGeometry.height * 0.8))
    }
}
