pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine
import org.kde.ki18n
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import "." 1.0 as Shared

Item {
    id: root

    // Keep a usable logical size even when Wayland's buffer scale is higher
    // than the display scale selected in Plasma.
    readonly property real toolbarScale: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1
    readonly property int toolbarButtonSize: Math.max(32, Math.round(40 / toolbarScale))
    readonly property int toolbarIconSize: Math.max(22, Math.round(28 / toolbarScale))

    readonly property KI18nContext translations: KI18nContext {
        translationDomain: "plasma_applet_dev.chatgpt.plasma"
    }

    signal closeRequested()

    property string loadError: ""
    property bool pageLoadFailed: false
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
        Layout.minimumWidth: root.toolbarButtonSize
        Layout.preferredWidth: root.toolbarButtonSize
        Layout.maximumWidth: root.toolbarButtonSize
        Layout.minimumHeight: root.toolbarButtonSize
        Layout.preferredHeight: root.toolbarButtonSize
        Layout.maximumHeight: root.toolbarButtonSize
        padding: 0
        display: QQC2.AbstractButton.IconOnly
        icon.width: root.toolbarIconSize
        icon.height: root.toolbarIconSize
        QQC2.ToolTip.text: text
        QQC2.ToolTip.visible: hovered
        QQC2.ToolTip.delay: 500
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                level: 1
                text: root.translations.i18n("ChatGPT")
                horizontalAlignment: Text.AlignLeft
            }

            ToolbarIconButton {
                text: root.translations.i18n("Open in browser")
                icon.name: "globe"
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

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 8
            visible: root.loadError.length > 0

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.loadError
                wrapMode: Text.WordWrap
            }

            PlasmaComponents.Button {
                visible: root.pageLoadFailed
                text: root.translations.i18n("Try again")
                onClicked: browserView.reload()
            }
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
                        root.pageLoadFailed = true
                        root.loadError = info.errorString || root.translations.i18n("ChatGPT could not be loaded.")
                    } else if (info.status === WebEngineView.LoadStartedStatus) {
                        root.pageLoadFailed = false
                        root.loadError = ""
                    } else if (info.status === WebEngineView.LoadSucceededStatus) {
                        root.pageLoadFailed = false
                        root.loadError = ""
                        if (root.popupExpanded) {
                            root.restartComposerFocus()
                        }
                    }
                }

                onNewWindowRequested: function(request) { root.handleNewWindow(request) }

                onRenderProcessTerminated: function(status, exitCode) {
                    console.warn("ChatGPT widget renderer terminated: status=" + status + ", exitCode=" + exitCode)
                    root.pageLoadFailed = false
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
