# ChatGPT Plasma widget

A Plasma 6 panel widget that opens the ChatGPT website in a popup. It embeds the site with Qt WebEngine and uses your normal ChatGPT sign-in; no API key is needed.

## Requirements

- KDE Plasma 6, Qt 6.9 or newer, KDE Frameworks 6.23 or newer (KI18n QML module), and the Qt WebEngine QML module
- `kpackagetool6` to install the widget
- `python3`, `shellcheck`, `qmake6`, and Qt 6 `qmllint` to run the project checks
- `plasmawindowed` for the optional standalone preview

## Install and use

### Install

From this repository, run:

```bash
./scripts/dev.sh install
```

In Plasma, open **Add Widgets**, find **ChatGPT Plasma Prototype**, and add it to a panel.

### Open and close

Click the panel icon to open or close the popup. You can also assign a global keyboard shortcut in the widget's settings to toggle it. The popup stays open when another window receives focus.

### Size and placement

The popup opens beside the widget's panel position. It requests 30% of the screen width (between 800 and 1600 pixels) and 80% of the screen height (between 400 and 1400 pixels). Plasma may reduce the size to fit the screen and remembers manual resizing for each widget instance. The width remains capped at its screen-relative target.

### Navigation and links

Use ChatGPT's in-page navigation, keyboard scrolling, or the mouse to move through a conversation.

The **Open in browser** globe button hands the current page to your default browser and closes the widget popup. The embedded page remains available when you reopen it.

New-window links to external sites open in your default browser while the widget stays open. Links that navigate the current page stay inside the widget. New windows on ChatGPT or OpenAI domains, authentication dialogs, and blank popup requests stay in Qt WebEngine so they can use the widget's sign-in profile.

### Sign-in and browser profiles

Open the popup and sign in to ChatGPT there. The widget keeps a persistent browser profile separate from your regular browser, so each needs its own sign-in. Multiple copies of the widget within Plasma Shell share the same profile and sign-in.

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
| `scripts/test-package.sh` | Isolated package installation and upgrade smoke test |

Run the checks after editing:

```bash
./scripts/dev.sh check
```

This validates the package metadata and entry point, runs Qt 6 `qmllint` over the QML files (with warnings treated as failures), and checks the shell scripts with Bash's syntax check and ShellCheck. ShellCheck is required locally and in CI.

Run the automated packaging smoke test after packaging changes:

```bash
./scripts/test-package.sh
```

It uses `kpackagetool6` to install a temporary package copy, checks that it is discoverable and all files match, then upgrades it with a changed version and QML file and checks the installed files again. Every package operation explicitly targets a temporary package root, which is cleaned up on exit. Your installed widget and browser profile are untouched. CI runs this test on pushes and pull requests; it does not launch Plasma or test sign-in or browser behaviour.

To upgrade the installed copy and open a standalone preview:

```bash
./scripts/dev.sh update
./scripts/dev.sh preview
```

`install` and `update` run the checks automatically. The preview opens the installed copy of the widget, so run `update` after editing the QML and before starting the preview.

Use the preview for quick layout checks. To test where the popup appears, its opening animation, the global shortcut, or sign-in, open the widget from a Plasma panel. The standalone preview does not behave exactly like the panel widget.

If the panel widget still shows the old version after `update`, restart Plasma Shell:

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
