# ChatGPT Plasma widget

Stage 1 is a minimal Plasma 6 widget: a panel icon opens a popup with placeholder text. Stage 2 will test loading the ChatGPT website and signing in through Qt WebEngine.

## How the project fits together

`package/` is the installable *plasmoid*. Plasma reads `package/metadata.json`, then loads `package/contents/ui/main.qml`. QML describes the panel and popup interface. `scripts/dev.sh` wraps the commands used while developing; it is outside the installed package.

The plugin ID, `dev.chatgpt.plasma`, identifies the installed widget. Changing it later creates a separate widget in Plasma, so keep it stable while developing.

## Requirements

- KDE Plasma 6 and Qt 6
- `kpackagetool6` for installation and `plasmawindowed` for a quick preview
- `python3` and `qmllint` for static checks
- Qt WebEngine will be required in Stage 2

## Development loop

From the project root:

```bash
./scripts/dev.sh check
./scripts/dev.sh install
./scripts/dev.sh preview
```

`check` validates the Plasma package metadata and entry point, lints every QML file in `package/contents`, and checks the development script's Bash syntax. `install` and `update` run the same checks before changing the installed widget. `preview` opens the installed widget in its own window. Close that window to stop the preview. After editing QML, run:

```bash
./scripts/dev.sh check
./scripts/dev.sh update
./scripts/dev.sh preview
```

To test the panel behaviour, use **Add Widgets** in Plasma and add **ChatGPT Plasma Prototype** to a panel. Click its icon to open the popup. If an updated widget is already on the panel, Plasma may need to reload it before changes appear. `plasmoidviewer` from `plasma-sdk` is another way to test panel form factors without changing your panel.

For package or QML errors, inspect the terminal output from `plasmawindowed`. For errors from an installed panel widget, inspect the Plasma Shell journal with `journalctl --user -u plasma-plasmashell.service -f`.

## Small project conventions

- Keep installable files inside `package/`; keep development scripts and notes outside it.
- Wrap new user-visible QML text in `i18n("...")`, so translations can be added later without revisiting the interface. [KDE's i18n guide](https://develop.kde.org/docs/plasma/widget/translations-i18n/) explains the syntax.
- Use `./scripts/dev.sh check` before installing or committing. `.editorconfig` sets basic whitespace defaults without imposing a formatter.
- Keep browser cookies and profile data outside the repository when the web view is added in Stage 2.

## Current scope

The popup is a placeholder. It does not yet load a website, hold login state, or register a keyboard shortcut. Those follow after the basic widget loads reliably.

## References

- [KDE Plasma widget setup](https://develop.kde.org/docs/plasma/widget/setup/)
- [KDE Plasma widget testing](https://develop.kde.org/docs/plasma/widget/testing/)
