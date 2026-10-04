pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine
import org.kde.ki18n
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import "." 1.0 as Shared

Item {
    id: root

    // Use native screen width to distinguish the 1080p laptop from the 4K desktop.
    readonly property bool compactDesktopToolbar: Screen.width * Screen.devicePixelRatio >= 2560
    readonly property int toolbarButtonSize: compactDesktopToolbar ? 32 : 40
    readonly property int toolbarGlyphSize: compactDesktopToolbar ? 22 : 28

    readonly property KI18nContext translations: KI18nContext {
        translationDomain: "plasma_applet_dev.chatgpt.plasma"
    }

    signal closeRequested()

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
            // DOM focus survives while this WebEngineView is hidden. Clear the
            // previous visit's focus before the delayed editor-focus attempt.
            browserView.runJavaScript("document.activeElement?.blur()")
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
        if (browserProfile === null) {
            return
        }

        browserView.runJavaScript(`(() => {
            const action = ${JSON.stringify(action)}
            // ChatGPT currently uses this element for the conversation scrollbar.
            // Fall back to the layout search if the site changes its class name.
            let target = document.querySelector(".thread-scroll-container")
            if (!target) {
                const composer = document.querySelector("#prompt-textarea")
                const main = composer?.closest("main") || document.querySelector("main") || document.body
                const x = window.innerWidth * 0.5
                const y = window.innerHeight * 0.35
                const candidates = [document.scrollingElement, ...document.querySelectorAll("*")]
                    .filter(element => {
                        if (!element || element.clientHeight < 100
                                || element.scrollHeight <= element.clientHeight) {
                            return false
                        }
                        const rect = element.getBoundingClientRect()
                        if (rect.width === 0 || rect.height === 0
                                || rect.bottom <= 0 || rect.top >= window.innerHeight
                                || rect.right <= 0 || rect.left >= window.innerWidth) {
                            return false
                        }
                        if (element === document.scrollingElement) {
                            return true
                        }
                        const overflow = getComputedStyle(element).overflowY
                        return overflow === "auto" || overflow === "scroll"
                            || overflow === "overlay" || overflow === "hidden"
                    })
                // Prefer the conversation's own scroller over a page wrapper
                // or the chat list when using the fallback search.
                const tier = element => main.contains(element) ? 2 : element.contains(main) ? 1 : 0
                const score = element => {
                    const rect = element.getBoundingClientRect()
                    const coversConversation = rect.left <= x && x < rect.right
                        && rect.top <= y && y < rect.bottom
                    const range = element.scrollHeight - element.clientHeight
                    return range * Math.min(rect.width, window.innerWidth)
                        * (coversConversation ? 4 : 1)
                }
                candidates.sort((a, b) => tier(b) - tier(a) || score(b) - score(a))
                target = candidates[0]
            }
            if (!target || target.scrollHeight <= target.clientHeight) {
                return false
            }

            if (action === "top" || action === "bottom") {
                // Reversed scroll containers use 0 at the bottom and negative
                // scrollTop values above it; these extremes work in either direction.
                target.scrollTo({
                    top: action === "top" ? -target.scrollHeight : target.scrollHeight,
                    behavior: "instant"
                })
                return true
            }

            const page = Math.max(160, Math.round(target.clientHeight * 0.85))
            target.scrollTop += action === "up" ? -page : page
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

    property var browserProfile: Shared.ChatProfile.profile

    function openPopup(request) {
        const popup = popupComponent.createObject(null) as SignInWindow
        if (popup) {
            popup.webView.acceptAsNewWindow(request)
        } else {
            loadError = root.translations.i18n("Could not open the sign-in window.")
        }
    }

    function handleNewWindow(request) {
        const target = request.requestedUrl.toString()
        // Keep ChatGPT sign-in on its own domains in the shared profile, even
        // when a click opens an HTTPS window. Blank pages and dialogs can
        // navigate to sign-in later.
        const chatgptDomain = /^https:\/\/(?:[a-z0-9-]+\.)*(?:chatgpt\.com|openai\.com)(?::[0-9]+)?(?:[/?#]|$)/i.test(target)
        if (!request.userInitiated
                || request.destination === WebEngineNewWindowRequest.InNewDialog
                || !/^https?:\/\//i.test(target)
                || chatgptDomain) {
            openPopup(request)
            return
        }

        if (!Qt.openUrlExternally(request.requestedUrl)) {
            loadError = root.translations.i18n("Could not open the link in your browser.")
        }
    }

    Component {
        id: popupComponent

        SignInWindow {}
    }

    component SignInWindow: Window {
        id: popupWindow
        width: 800
        height: 700
        visible: true
        title: root.translations.i18n("ChatGPT sign-in")
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

    component ToolbarIconButton: PlasmaComponents.Button {
        id: toolbarIconButton

        property bool flipSymbol: false

        Layout.minimumWidth: root.toolbarButtonSize
        Layout.preferredWidth: root.toolbarButtonSize
        Layout.maximumWidth: root.toolbarButtonSize
        Layout.minimumHeight: root.toolbarButtonSize
        Layout.preferredHeight: root.toolbarButtonSize
        Layout.maximumHeight: root.toolbarButtonSize
        padding: 0
        font.pixelSize: root.toolbarGlyphSize

        contentItem: PlasmaComponents.Label {
            text: toolbarIconButton.text
            font: toolbarIconButton.font
            color: "#4a90e2"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            rotation: toolbarIconButton.flipSymbol ? 180 : 0
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PlasmaExtras.Heading {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.topMargin: 8
            level: 1
            text: root.translations.i18n("ChatGPT")
            horizontalAlignment: Text.AlignLeft
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8

            ToolbarIconButton {
                text: "⌃"
                font.overline: true
                Accessible.name: root.translations.i18n("Top")
                focusPolicy: Qt.NoFocus
                onClicked: root.scrollConversation("top")
            }

            ToolbarIconButton {
                text: "⌃"
                Accessible.name: root.translations.i18n("Scroll up")
                focusPolicy: Qt.NoFocus
                onClicked: root.scrollConversation("up")
            }

            ToolbarIconButton {
                text: "⌄"
                Accessible.name: root.translations.i18n("Scroll down")
                focusPolicy: Qt.NoFocus
                onClicked: root.scrollConversation("down")
            }

            ToolbarIconButton {
                text: "⌃"
                font.overline: true
                flipSymbol: true
                Accessible.name: root.translations.i18n("Bottom")
                focusPolicy: Qt.NoFocus
                onClicked: root.scrollConversation("bottom")
            }

            Item {
                Layout.fillWidth: true
            }

            ToolbarIconButton {
                text: "🌐"
                font.pixelSize: root.compactDesktopToolbar ? 20 : 24
                Accessible.name: root.translations.i18n("Open in browser")
                onClicked: {
                    const target = browserView.url.toString().length > 0 ? browserView.url : "https://chatgpt.com/"
                    if (Qt.openUrlExternally(target)) {
                        root.closeRequested()
                    } else {
                        root.loadError = root.translations.i18n("Could not open the page in your browser.")
                    }
                }
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
                        root.loadError = info.errorString || root.translations.i18n("ChatGPT could not be loaded.")
                    } else if (info.status === WebEngineView.LoadSucceededStatus) {
                        root.loadError = ""
                        if (root.popupExpanded) {
                            root.restartComposerFocus()
                        }
                    }
                }

                onNewWindowRequested: function(request) { root.handleNewWindow(request) }

                onRenderProcessTerminated: function(status, exitCode) {
                    console.warn("ChatGPT widget renderer terminated: status=" + status + ", exitCode=" + exitCode)
                    root.loadError = root.translations.i18n("The browser renderer stopped. Restart Plasma Shell to continue.")
                }
            }
        }
    }

    Component.onCompleted: {
        if (browserProfile === null) {
            loadError = root.translations.i18n("Could not create the browser profile. Reopen the widget or restart Plasma Shell.")
        }
    }

    onBrowserProfileChanged: {
        if (browserProfile !== null) {
            loadError = ""
        }
    }
}
