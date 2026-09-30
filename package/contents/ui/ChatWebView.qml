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

    onPopupExpandedChanged: {
        if (popupExpanded && browserProfile !== null) {
            nudgeBrowser()
        }
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
