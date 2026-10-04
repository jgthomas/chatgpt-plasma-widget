# ChatGPT Plasma widget

A Plasma 6 panel widget that opens the ChatGPT website in a popup. It embeds the site with Qt WebEngine and uses your normal ChatGPT sign-in; no API key is needed.

## Requirements

- KDE Plasma 6, Qt 6.9 or newer, KDE Frameworks 6.23 or newer (KI18n QML module), and the Qt WebEngine QML module
- `kpackagetool6` to install the widget
- `python3` and `qmllint` to run the project checks
- `plasmawindowed` for the optional standalone preview

## Install and use

From this repository:

```bash
./scripts/dev.sh install
```

In Plasma, open **Add Widgets**, find **ChatGPT Plasma Prototype**, and add it to a panel. Click its icon to open the popup, then sign in to ChatGPT inside the widget. You can assign a global keyboard shortcut in the widget's built-in settings; the shortcut opens and closes the popup.

The popup stays open when another window receives focus. Close it with the shortcut or panel icon. Its position follows the widget's position on the panel. Its requested size is 30% of the screen width, bounded to 500–1600 pixels, and 80% of the screen height, bounded to 400–1400 pixels. Plasma may reduce the size to fit the screen and remembers manual popup resizing per widget instance. The width is capped at its screen-relative target, even if Plasma has saved a larger width.

The toolbar provides:

- **Top**, **Scroll up**, **Scroll down**, and **Bottom** to navigate a conversation when ChatGPT's own scrollbar is hard to use.
- **Open in browser** to hand the current page to your default browser and close the widget popup. The embedded page remains available when you reopen it.

Links in ChatGPT that request a new window open in your default browser while the widget stays open. Links that navigate the current page stay inside the widget. Authentication dialogs and blank popup requests stay in Qt WebEngine so they can use the widget's sign-in profile.

### Sign-in and browser profiles

The widget has a persistent browser profile separate from your regular browser. Signing in to one does not sign in to the other. Multiple copies of the widget within Plasma Shell share the same profile and sign-in.

The standalone `plasmawindowed` preview runs in a different host application, so it has a separate profile from the panel widget. Qt stores browser data in the host application's user data directory, outside this repository.

## Develop

`package/` is the installable plasmoid. Plasma reads `package/metadata.json` and loads `package/contents/ui/main.qml`; the browser view and shared profile live alongside it. `scripts/dev.sh` is a local development helper and is not installed with the widget.

| File | Purpose |
| --- | --- |
| `package/contents/ui/main.qml` | Panel representation, popup sizing, and close behavior |
| `package/contents/ui/ChatWebView.qml` | Browser view, controls, focus, and link handling |
| `package/contents/ui/ChatProfile.qml` and `qmldir` | Shared persistent WebEngine profile |
| `package/metadata.json` | Widget name and stable plugin ID |
| `scripts/dev.sh` | Checks, installation, updates, and preview |

Run the checks after editing:

```bash
./scripts/dev.sh check
```

This validates the package metadata and entry point, runs Qt 6 `qmllint` over the QML files (with warnings treated as failures), and checks the development script's Bash syntax. To upgrade the installed copy and open a standalone preview:

```bash
./scripts/dev.sh update
./scripts/dev.sh preview
```

`install` and `update` also run the checks. The preview uses the **installed** package, so run `update` first. Test panel placement, popup animation, shortcut behavior, and the panel sign-in in Plasma Shell; the preview does not reproduce all of those. Plasma may need to reload an already running widget after an update. To reload Plasma Shell during development:

```bash
systemctl --user restart plasma-plasmashell.service
```

The plugin ID is `dev.chatgpt.plasma`. Changing it makes Plasma treat the package as a different widget, so keep it stable. Keep installable files under `package/` and translate new user-visible QML text with `root.translations.i18n("...")`.

## Logs

For preview errors, inspect the `plasmawindowed` terminal. For panel errors, follow the Plasma Shell journal with `journalctl --user -u plasma-plasmashell.service -f`.

## References

- [KDE Plasma widget setup](https://develop.kde.org/docs/plasma/widget/setup/)
- [KDE Plasma widget testing](https://develop.kde.org/docs/plasma/widget/testing/)
- [KDE's QML translation guide](https://develop.kde.org/docs/plasma/widget/translations-i18n/)
- [Qt WebEngine profile storage](https://doc.qt.io/qt-6/qml-qtwebengine-webengineprofileprototype.html)
