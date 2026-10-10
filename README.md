# ChatGPT Plasma widget

A Plasma 6 panel widget that opens the ChatGPT website in a popup. It embeds the site with Qt WebEngine and uses your normal ChatGPT sign-in; no API key is needed.

## Requirements

- KDE Plasma 6, Qt 6.9 or newer, KDE Frameworks 6.23 or newer (KI18n QML module), and the Qt WebEngine QML module
- `kpackagetool6` to install the widget
- `python3`, `shellcheck`, `qmake6`, and Qt 6 `qmllint` to run the project checks
- `diff` (provided by `diffutils` on Arch) to run the package smoke test
- `plasmawindowed` for the optional standalone preview

## Install

From this repository, run:

```bash
./scripts/dev.sh install
```

In Plasma, open **Add Widgets**, find **ChatGPT Plasma Prototype**, and add it to a panel.

## Use

### Open and close

Click the panel icon to open or close the popup. You can also assign a global keyboard shortcut in the widget's settings to toggle it. The popup stays open when another window receives focus.

### Size and placement

The popup opens beside the widget's panel position. It requests 30% of the screen width (between 800 and 1600 pixels) and 80% of the screen height (between 400 and 1200 pixels). Plasma may reduce the size to fit the screen and remembers manual resizing for each widget instance. The width and height remain capped at their screen-relative targets.

### Links

The **Open in browser** globe button hands the current page to your default browser and closes the widget popup. The embedded page remains available when you reopen it.

New-window links to external sites open in your default browser while the widget stays open. Links that navigate the current page stay inside the widget. New windows on ChatGPT or OpenAI domains, authentication dialogs, and blank popup requests stay in Qt WebEngine so they can use the widget's sign-in profile.

### Sign-in and browser profiles

Open the popup and sign in to ChatGPT there. The widget keeps a persistent browser profile separate from your regular browser, so each needs its own sign-in. Multiple copies of the widget within Plasma Shell share the same profile and sign-in.

The standalone `plasmawindowed` preview runs in a different host application, so it has a separate profile from the panel widget. Qt stores browser data in the host application's user data directory, outside this repository.

## Develop

`package/` contains the installable Plasma widget: its metadata and QML components for the panel icon, popup, embedded browser, and shared browser profile. `scripts/` contains the development and packaging helpers.

Run `scripts/dev.sh` from the repository root:

```bash
./scripts/dev.sh check    # Validate metadata, QML, and shell scripts
./scripts/dev.sh install  # Install the widget for the first time
./scripts/dev.sh update   # Upgrade the installed widget after editing
./scripts/dev.sh reload   # Upgrade the widget and restart Plasma Shell
./scripts/dev.sh preview  # Open the installed widget in a standalone window
```

`install`, `update`, and `reload` run the checks automatically. The checks use Qt 6 `qmllint` with warnings treated as failures, Bash's syntax check, and ShellCheck, alongside metadata validation.

After editing, run `update` followed by `preview`. Use the preview for quick layout checks; test popup placement, opening animation, the global shortcut, and sign-in from a Plasma panel.

To try changes in the panel widget, run `reload`. It upgrades the installed copy and restarts Plasma Shell after a successful upgrade so the panel loads the latest code.

Run the automated packaging smoke test after packaging changes:

```bash
./scripts/test-package.sh
```

This verifies installation and upgrades in a temporary package root without changing your installed widget or browser profile. CI runs the checks and packaging test on pushes and pull requests; browser behaviour needs manual testing.

The plugin ID is `dev.chatgpt.plasma`. Changing it makes Plasma treat the package as a different widget, so keep it stable. Keep installable files under `package/` and translate new user-visible QML text with `root.translations.i18n("...")`.

## Logs

For preview errors, inspect the `plasmawindowed` terminal. For panel errors, follow the Plasma Shell journal with `journalctl --user -u plasma-plasmashell.service -f`.

