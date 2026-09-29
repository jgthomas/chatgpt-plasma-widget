#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
package_dir="$project_dir/package"

check_project() {
    python3 "$project_dir/scripts/check_metadata.py" "$package_dir" >/dev/null
    shopt -s globstar nullglob
    qml_files=("$package_dir"/contents/**/*.qml)
    if ((${#qml_files[@]} == 0)); then
        printf 'No QML files found in %s/contents\n' "$package_dir" >&2
        exit 1
    fi
    qmllint "${qml_files[@]}"
    bash -n "$project_dir/scripts/dev.sh"
}

case "${1:-}" in
    check)
        check_project
        ;;
    install)
        check_project
        kpackagetool6 --type Plasma/Applet --install "$package_dir"
        ;;
    update)
        check_project
        kpackagetool6 --type Plasma/Applet --upgrade "$package_dir"
        ;;
    preview)
        plugin_id="$(python3 "$project_dir/scripts/check_metadata.py" "$package_dir")"
        plasmawindowed "$plugin_id"
        ;;
    *)
        printf 'Usage: %s {check|install|update|preview}\n' "$0" >&2
        exit 2
        ;;
esac
