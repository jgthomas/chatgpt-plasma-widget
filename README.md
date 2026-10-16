# ChatGPT Plasma widget

A Plasma 6 panel widget that opens the ChatGPT website in a popup. It embeds the site with Qt WebEngine and uses your normal ChatGPT sign-in; no API key is needed.

## Requirements

- KDE Plasma 6, Qt 6.9 or newer, KDE Frameworks 6.23 or newer (KI18n QML module), and the Qt WebEngine QML module
- `kpackagetool6` to install the widget
- `python3`, `shellcheck`, `qmake6`, Qt 6 `qmllint`, `qmltestrunner`, and the QtTest QML module to run the project checks
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

The popup opens beside the widget's panel position. It targets 30% of the screen width and 80% of the screen height, with font-relative size limits and a cap of 90% of each screen dimension. Plasma may reduce the size to fit the available space and remembers manual resizing for each widget instance. The width and height remain capped at their screen-relative targets.

### Links

The **Open in browser** globe button hands the current page to your default browser and closes the widget popup. The embedded page remains available when you reopen it.

Links to external sites open in your default browser while the widget stays open, whether they request a new window or navigate the current one. Same-window ChatGPT navigation stays embedded, including links within and between conversations, starting a new chat, and opening settings. ChatGPT's client-side conversation routing is left untouched.

New-window requests open in your default browser, except ChatGPT's own sign-in windows, which stay embedded. External sign-in providers also open in your browser but cannot sign the widget in.

Blank popups stay hidden until their destination is known. Sign-in handling may need updating if ChatGPT changes its authentication flow.

### Sign-in and browser profiles

Open the popup and sign in to ChatGPT there. The widget keeps a persistent browser profile separate from your regular browser, so each needs its own sign-in. Google disallows embedded OAuth, so Google authentication URLs open externally. This does not sign the widget in: there is no browser-to-widget authentication handoff, and the external flow may also lack the state cookies established in the widget. Google-based sign-in to the widget is therefore not currently supported. Multiple copies of the widget within Plasma Shell share the same profile and sign-in.

The standalone `plasmawindowed` preview runs in a different host application, so it has a separate profile from the panel widget. Qt stores browser data in the host application's user data directory, outside this repository.

## Develop

`package/` contains the installable Plasma widget: its metadata and QML components for the panel icon, popup, embedded browser, and shared browser profile. `scripts/` contains the development and packaging helpers.

For normal development, edit the widget, then run these commands from the repository root:

```bash
./scripts/dev.sh verify   # Run all project checks and tests
./scripts/dev.sh reload   # Upgrade the widget and restart Plasma Shell
```

Open the panel widget to try the changes. Use the panel widget to check layout, focus, popup placement, opening animation, the global shortcut, links, and sign-in.

### Commands

```bash
./scripts/dev.sh check    # Validate metadata, QML, and shell scripts
./scripts/dev.sh test     # Run routing, popup, and package tests
./scripts/dev.sh verify   # Run all project checks and tests
./scripts/dev.sh install  # Install the widget for the first time
./scripts/dev.sh update   # Upgrade the installed widget without restarting its host
./scripts/dev.sh reload   # Upgrade the widget and restart Plasma Shell
./scripts/dev.sh preview  # Standalone inspection of the installed widget
```

`install`, `update`, and `reload` run the static checks automatically. The checks use Qt 6 `qmllint` with warnings treated as failures, Bash's syntax check, and ShellCheck, alongside metadata validation. The separate `test` command runs Qt Quick tests of link routing, navigation state transitions, and popup destruction, followed by the package install/upgrade smoke test. The Qt Quick tests run offscreen without a ChatGPT account or network access.

Use `check` or `test` to run just that part of verification. Use `update` when you want to upgrade the installed files and restart the host separately. `preview` is optional for quick standalone inspection; run `update` first if you need it to show recent edits. The preview has a separate browser profile and differs from the panel widget in focus, popup behaviour, and placement, so verify those in the panel after `reload`.

### Tests

Run all automated tests directly with:

```bash
./scripts/dev.sh test
```

This covers link routing, popup navigation after sign-in, cleanup of pending windows, and package installation and upgrades. The Qt Quick tests run offscreen; the packaging test uses a temporary package root. Neither changes your installed widget or browser profile, and no ChatGPT account or network access is needed.

To run only the package install/upgrade smoke test:

```bash
./scripts/test-package.sh
```

CI runs static checks in **Check project** and the full automated test suite in **Run all tests** on pushes and pull requests. Live sign-in, actual default-browser launching, and ChatGPT's client-side link handling still need manual testing.

The plugin ID is `dev.chatgpt.plasma`. Changing it makes Plasma treat the package as a different widget, so keep it stable. Keep installable files under `package/` and translate new user-visible QML text with `root.translations.i18n("...")`.

## Logs

For preview errors, inspect the `plasmawindowed` terminal. For panel errors, follow the Plasma Shell journal with `journalctl --user -u plasma-plasmashell.service -f`.

