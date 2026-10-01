import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine
import org.kde.plasma.components as PlasmaComponents
import "." 1.0 as Shared

Item {
    id: root

    property string loadError: ""
    property bool popupExpanded: true
    property int focusRequestId: 0
    property int focusAttempts: 0

    function restartComposerFocus() {
        focusRequestId += 1
        focusAttempts = 0
        focusTimer.interval = 150
        focusTimer.restart()
    }

    onPopupExpandedChanged: {
        focusRequestId += 1
        focusTimer.stop()
        if (popupExpanded && browserProfile !== null) {
            nudgeBrowser()
            restartComposerFocus()
        }
    }

    Timer {
        id: focusTimer
        interval: 150
        onTriggered: root.focusComposer()
    }

    function focusComposer() {
        if (!popupExpanded || browserProfile === null || browserView.loading) {
            return
        }

        const requestId = focusRequestId
        focusAttempts += 1
        if (focusAttempts === 1) {
            browserView.forceActiveFocus()
        }
        browserView.runJavaScript(`(() => {
            const active = document.activeElement
            for (const selector of ["#prompt-textarea", '[contenteditable="true"][role="textbox"]', "textarea"]) {
                for (const editor of document.querySelectorAll(selector)) {
                    if (editor.getClientRects().length > 0 && !editor.matches(":disabled")) {
                        // Do not override a control the user has already focused.
                        if (active && active !== document.body && active !== document.documentElement && active !== editor) {
                            return true
                        }
                        editor.focus({preventScroll: true})
                        return document.activeElement === editor
                    }
                }
            }
            return Boolean(active && active !== document.body && active !== document.documentElement)
        })()`, function(focused) {
            if (requestId === root.focusRequestId && root.popupExpanded
                    && focused === false && root.focusAttempts < 10) {
                focusTimer.interval = 250
                focusTimer.restart()
            }
        })
    }

    function scrollConversation(action) {
        if (browserProfile === null || browserView.loading) {
            return
        }

        browserView.runJavaScript(`(() => {
            const action = ${JSON.stringify(action)}
            const main = document.querySelector("main") || document.body
            const isScrollable = element => {
                const overflow = getComputedStyle(element).overflowY
                return element.getClientRects().length > 0
                    && element.clientHeight >= 100
                    && element.scrollHeight > element.clientHeight + 2
                    && (overflow === "auto" || overflow === "scroll" || overflow === "overlay")
            }
            const candidates = [main, ...main.querySelectorAll("*")].filter(isScrollable)
            candidates.sort((a, b) => b.clientWidth * b.clientHeight - a.clientWidth * a.clientHeight)
            const target = candidates[0] || document.scrollingElement
            if (!target || target.scrollHeight <= target.clientHeight + 2) {
                return false
            }

            if (action === "top" || action === "bottom") {
                // Reversed scroll containers use 0 at the bottom and negative
                // scrollTop values above it; these extremes work in either direction.
                target.scrollTop = action === "top" ? -target.scrollHeight : target.scrollHeight
                return true
            }

            const page = Math.max(160, Math.round(target.clientHeight * 0.85))
            target.scrollBy({top: action === "up" ? -page : page, behavior: "smooth"})
            return true
        })()`)
    }

    Timer {
        id: nudgeTimer
        interval: 50
        onTriggered: browserView.anchors.bottomMargin = 0
    }

    function nudgeBrowser() {
        // A tiny viewport resize can prompt a repaint when the panel popup reopens.
        browserView.anchors.bottomMargin = 1
        nudgeTimer.restart()
    }

    Timer {
        id: redrawTimer
        interval: 100
        onTriggered: browserView.visible = true
    }

    function redrawBrowser() {
        // A hidden panel popup can reopen with a stale WebEngine texture.
        // Toggling the item asks WebEngine to paint again without reloading the page.
        browserView.visible = false
        redrawTimer.restart()
    }

    property var browserProfile: Shared.ChatProfile.profile

    function openPopup(request) {
        const popup = popupComponent.createObject(null)
        if (popup) {
            popup.webView.acceptAsNewWindow(request)
        } else {
            loadError = i18n("Could not open the sign-in window.")
        }
    }

    Component {
        id: popupComponent

        Window {
            id: popupWindow
            width: 800
            height: 700
            visible: true
            title: i18n("ChatGPT sign-in")
            onClosing: destroy()

            property alias webView: popupWebView

            WebEngineView {
                id: popupWebView
                anchors.fill: parent
                profile: root.browserProfile
                onNewWindowRequested: function(request) { root.openPopup(request) }
                onWindowCloseRequested: popupWindow.close()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: browserView.loading ? i18n("Loading ChatGPT…") : i18n("ChatGPT")
                elide: Text.ElideRight
            }

            PlasmaComponents.Button {
                text: i18n("Redraw")
                enabled: root.browserProfile !== null
                onClicked: root.redrawBrowser()
            }

            PlasmaComponents.Button {
                text: i18n("Reload")
                enabled: root.browserProfile !== null
                onClicked: browserView.reload()
            }

            PlasmaComponents.Button {
                text: i18n("Open in browser")
                onClicked: Qt.openUrlExternally(browserView.url.toString().length > 0 ? browserView.url : "https://chatgpt.com/")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 8

            PlasmaComponents.Button {
                text: i18n("Top")
                focusPolicy: Qt.NoFocus
                onClicked: root.scrollConversation("top")
            }

            PlasmaComponents.Button {
                text: i18n("Page up")
                focusPolicy: Qt.NoFocus
                onClicked: root.scrollConversation("up")
            }

            PlasmaComponents.Button {
                text: i18n("Page down")
                focusPolicy: Qt.NoFocus
                onClicked: root.scrollConversation("down")
            }

            PlasmaComponents.Button {
                text: i18n("Bottom")
                focusPolicy: Qt.NoFocus
                onClicked: root.scrollConversation("bottom")
            }
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.margins: 8
            visible: root.loadError.length > 0
            text: root.loadError
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            WebEngineView {
                id: browserView
                anchors.fill: parent
                profile: root.browserProfile
                url: root.browserProfile ? "https://chatgpt.com/" : ""

                onLoadingChanged: function(info) {
                    if (info.status === WebEngineView.LoadFailedStatus) {
                        root.loadError = info.errorString || i18n("ChatGPT could not be loaded.")
                    } else if (info.status === WebEngineView.LoadSucceededStatus) {
                        root.loadError = ""
                        if (root.popupExpanded) {
                            root.restartComposerFocus()
                        }
                    }
                }

                onNewWindowRequested: function(request) { root.openPopup(request) }

                onRenderProcessTerminated: function(status, exitCode) {
                    console.warn("ChatGPT widget renderer terminated: status=" + status + ", exitCode=" + exitCode)
                    root.loadError = i18n("The browser renderer stopped. Reload ChatGPT to continue.")
                }
            }
        }
    }

    Component.onCompleted: {
        if (browserProfile === null) {
            loadError = i18n("Could not create the browser profile. Reopen the widget or restart Plasma Shell.")
        }
    }

    onBrowserProfileChanged: {
        if (browserProfile !== null) {
            loadError = ""
        }
    }
}
