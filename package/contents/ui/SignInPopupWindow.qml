import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami

Window {
    id: popup
    width: Math.min(Kirigami.Units.gridUnit * 44, Screen.width * 0.9)
    height: Math.min(Kirigami.Units.gridUnit * 39, Screen.height * 0.9)
    visible: false
    property bool destinationPending: true
    property int destinationTimeout: 15000

    function dismiss() {
        // A never-shown window may not emit closing when close() is called.
        destroy()
    }

    onClosing: dismiss()

    Timer {
        interval: popup.destinationTimeout
        running: popup.destinationPending
        onTriggered: popup.dismiss()
    }
}
