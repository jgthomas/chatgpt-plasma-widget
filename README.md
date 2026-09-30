# ChatGPT Plasma widget

Stage 2 is a browser feasibility prototype: a panel icon opens ChatGPT in a Qt WebEngine view. It uses a persistent, separate browser profile so you can test whether sign-in survives closing and reopening the widget.

## How the project fits together

`package/` is the installable *plasmoid*. Plasma reads `package/metadata.json`, then loads `package/contents/ui/main.qml`. QML describes the panel and popup interface. `scripts/dev.sh` wraps the commands used while developing; it is outside the installed package.

The plugin ID, `dev.chatgpt.plasma`, identifies the installed widget. Changing it later creates a separate widget in Plasma, so keep it stable while developing.

## Requirements

- KDE Plasma 6 and Qt 6.9 or newer
- `kpackagetool6` for installation and `plasmawindowed` for a quick preview
- `python3` and `qmllint` for static checks
- Qt WebEngine for the embedded browser (`qt6-webengine` on Arch Linux)

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

## Browser feasibility check

1. Test the installed panel widget for the definitive result. Close extra widget windows so they do not complicate the test.
2. Open the widget and sign in to ChatGPT inside it. Its browser profile is separate from your regular browser, so you will likely need to sign in again.
3. Send a message, open an existing conversation, and check that the site is usable at the popup size.
4. Close and reopen the popup. Then log out and back in to restart Plasma Shell and check whether you are still signed in. If testing through `plasmawindowed`, close and relaunch that program instead.
5. Try your normal sign-in method. If it opens another window, the prototype gives that window the same browser profile.

Qt stores the named browser profile under the host application's user data directory, outside this repository. Copies of the widget in the same Plasma Shell process share one profile and sign-in. `plasmawindowed` and Plasma Shell are different host applications, so signing in to the preview does not sign in to the panel widget. The **Open in browser** button uses your regular browser and its own login state. The panel popup makes a tiny viewport resize when reopened to prompt WebEngine to repaint. If a black area still appears, **Redraw** briefly hides and shows the web view without reloading the page; **Reload** retries the current page. Loading errors appear above the web view.

The **Top**, **Page up**, **Page down**, and **Bottom** controls scroll the conversation area when ChatGPT's thin scrollbar is awkward to use or page navigation keys do not work.

The widget's built-in Plasma shortcut opens and closes the popup. On opening, it focuses ChatGPT's message editor when available. The popup stays open when another window gets focus; use the shortcut or panel icon to close it.

For package or QML errors, inspect the terminal output from `plasmawindowed`. For errors from an installed panel widget, inspect the Plasma Shell journal with `journalctl --user -u plasma-plasmashell.service -f`.

## Small project conventions

- Keep installable files inside `package/`; keep development scripts and notes outside it.
- Wrap new user-visible QML text in `i18n("...")`, so translations can be added later without revisiting the interface. [KDE's i18n guide](https://develop.kde.org/docs/plasma/widget/translations-i18n/) explains the syntax.
- Use `./scripts/dev.sh check` before installing or committing. `.editorconfig` sets basic whitespace defaults without imposing a formatter.
- Keep browser cookies and profile data outside the repository. The current named Qt WebEngine profile does this by default.

## Current scope

This stage checks basic browsing and sign-in. Keyboard shortcut behaviour, a slide-out drawer, and richer browser features are still future work. Login and session persistence must be verified by signing in manually; automated checks cannot establish that they work with your account.

## References

- [KDE Plasma widget setup](https://develop.kde.org/docs/plasma/widget/setup/)
- [KDE Plasma widget testing](https://develop.kde.org/docs/plasma/widget/testing/)
- [Qt WebEngine profile storage](https://doc.qt.io/qt-6/qml-qtwebengine-webengineprofileprototype.html)
