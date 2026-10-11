import QtQuick
import QtQuick.Window

Window {
    id: popup
    width: 800
    height: 700
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
