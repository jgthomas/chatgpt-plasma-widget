#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
package_dir="$project_dir/package"
plugin_id="dev.chatgpt.plasma"

case "${1:-}" in
    check)
        python3 -m json.tool "$package_dir/metadata.json" >/dev/null
        qmllint "$package_dir/contents/ui/main.qml"
        ;;
    install)
        kpackagetool6 --type Plasma/Applet --install "$package_dir"
        ;;
    update)
        kpackagetool6 --type Plasma/Applet --upgrade "$package_dir"
        ;;
    preview)
        plasmawindowed "$plugin_id"
        ;;
    *)
        printf 'Usage: %s {check|install|update|preview}\n' "$0" >&2
        exit 2
        ;;
esac
