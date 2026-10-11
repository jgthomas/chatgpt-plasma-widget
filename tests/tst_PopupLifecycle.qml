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

    function test_establishedWindowDoesNotExpire() {
        const before = destroyedWindows
        const popup = windowComponent.createObject(null, {
            destinationTimeout: 20, destinationPending: false
        })
        wait(60)
        compare(destroyedWindows, before)
        popup.dismiss()
        tryCompare(testCase, "destroyedWindows", before + 1)
    }
}
