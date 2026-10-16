pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property int popupTargetWidth: Math.min(Math.round(screenGeometry.width * 0.9),
        Math.max(Kirigami.Units.gridUnit * 44, Math.min(Kirigami.Units.gridUnit * 88, Math.round(screenGeometry.width * 0.3))))
    readonly property int popupTargetHeight: Math.min(Math.round(screenGeometry.height * 0.9),
        Math.max(Kirigami.Units.gridUnit * 22, Math.min(Kirigami.Units.gridUnit * 66, Math.round(screenGeometry.height * 0.8))))

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
        onCloseRequested: root.expanded = false
        Layout.minimumWidth: Math.min(Kirigami.Units.gridUnit * 28, root.popupTargetWidth)
        Layout.minimumHeight: Math.min(Kirigami.Units.gridUnit * 22, root.popupTargetHeight)
        Layout.preferredWidth: root.popupTargetWidth
        // Keep remembered sizes within the screen-relative targets.
        Layout.maximumWidth: root.popupTargetWidth
        Layout.preferredHeight: root.popupTargetHeight
        Layout.maximumHeight: root.popupTargetHeight
    }
}
