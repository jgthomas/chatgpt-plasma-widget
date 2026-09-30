pragma Singleton

import QtQml
import QtWebEngine

QtObject {
    id: root

    // Plasma applets share a QML engine, so this object owns one profile for
    // every instance of the widget in the current Plasma Shell process.
    property var profile: null

    property WebEngineProfilePrototype prototype: WebEngineProfilePrototype {
        storageName: "dev.chatgpt.plasma"
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
    }

    Component.onCompleted: profile = prototype.instance()
}
