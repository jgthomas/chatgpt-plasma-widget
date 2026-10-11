import QtQuick
import QtTest
import "../package/contents/ui" as Widget

TestCase {
    id: testCase
    name: "PopupLifecycle"
    property int destroyedWindows: 0

    Component {
        id: windowComponent
        Widget.SignInPopupWindow {
            Component.onDestruction: testCase.destroyedWindows += 1
        }
    }

    function test_pendingTimeoutDestroysWindow() {
        const before = destroyedWindows
        windowComponent.createObject(null, {destinationTimeout: 20})
        tryCompare(testCase, "destroyedWindows", before + 1)
    }

    function test_dismissNeverShownWindow() {
        const before = destroyedWindows
        const popup = windowComponent.createObject(null)
        popup.dismiss()
        tryCompare(testCase, "destroyedWindows", before + 1)
    }

    function test_establishingPendingWindowCancelsTimeout() {
        const before = destroyedWindows
        const popup = windowComponent.createObject(null, {
            destinationTimeout: 200
        })
        try {
            wait(20) // Let the pending window's timer start.
            compare(destroyedWindows, before)
            compare(popup.destinationPending, true)
            popup.destinationPending = false
            wait(240) // Survive beyond the original pending deadline.
            compare(destroyedWindows, before)
        } finally {
            if (destroyedWindows === before) popup.dismiss()
        }
        tryCompare(testCase, "destroyedWindows", before + 1)
    }
}
