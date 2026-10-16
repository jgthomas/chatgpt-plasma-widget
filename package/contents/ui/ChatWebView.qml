pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import QtWebEngine
import org.kde.ki18n
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import "." 1.0 as Shared
import "../code/link-routing.js" as Links

Item {
    id: root

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

    function openExternal(target) {
        if (!Qt.openUrlExternally(target)) {
            loadError = root.translations.i18n("Could not open the link in your browser.")
        }
    }

    function openPopup(request, authenticating) {
        const popup = popupComponent.createObject(null) as SignInWindow
        if (popup) {
            popup.webView.authInProgress = authenticating
            popup.webView.acceptAsNewWindow(request)
        } else {
            loadError = root.translations.i18n("Could not open the sign-in window.")
        }
    }

    function handleNewWindow(request, authenticating) {
        const route = Links.route(request.requestedUrl, true, authenticating)
        if (route === "embedded" || route === "pending") {
            openPopup(request, authenticating || route === "embedded")
        } else if (route === "external") {
            openExternal(request.requestedUrl)
        }
    }

    function handleNavigation(request, view, popup) {
        Links.navigate(request, view, popup, target => root.openExternal(target))
    }

    Component {
        id: popupComponent

        SignInWindow {}
    }

    component SignInWindow: Shared.SignInPopupWindow {
        id: popupWindow
        // Blank window.open() requests are classified at their first navigation.
        title: root.translations.i18n("ChatGPT sign-in")

        property alias webView: popupWebView

        WebEngineView {
            id: popupWebView
            anchors.fill: parent
            profile: root.browserProfile
            property bool authInProgress: false
            onNavigationRequested: function(request) { root.handleNavigation(request, popupWebView, popupWindow) }
            onNewWindowRequested: function(request) { root.handleNewWindow(request, authInProgress) }
            onWindowCloseRequested: popupWindow.dismiss()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PlasmaExtras.PlasmoidHeading {
            Layout.fillWidth: true

            contentItem: RowLayout {
                spacing: Kirigami.Units.mediumSpacing
                PlasmaExtras.Heading {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    level: 1
                    text: root.translations.i18n("ChatGPT")
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                }

                PlasmaComponents.ToolButton {
                    text: root.translations.i18n("Open in browser")
                    display: QQC2.AbstractButton.IconOnly
                    icon.name: "globe"
                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
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
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            visible: root.loadError.length > 0
            type: Kirigami.MessageType.Error
            text: root.loadError
            actions: [Kirigami.Action {
                visible: root.pageLoadFailed
                text: root.translations.i18n("Try again")
                icon.name: "view-refresh"
                onTriggered: browserView.reload()
            }]
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            WebEngineView {
                id: browserView
                anchors.fill: parent
                profile: root.browserProfile
                property bool authInProgress: false
                url: root.browserProfile ? "https://chatgpt.com/" : ""

                userScripts.collection: [{
                    name: "Conversation scroll focus styling",
                    sourceUrl: Qt.resolvedUrl("../code/scroll-focus.js"),
                    injectionPoint: WebEngineScript.DocumentReady,
                    worldId: WebEngineScript.ApplicationWorld,
                    runsOnSubFrames: false
                }]

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

                onNavigationRequested: function(request) { root.handleNavigation(request, browserView, null) }
                onNewWindowRequested: function(request) { root.handleNewWindow(request, authInProgress) }

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
