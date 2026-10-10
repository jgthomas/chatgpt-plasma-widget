#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
package_dir="$project_dir/package"

check_project() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        printf 'shellcheck is required to check the development script\n' >&2
        exit 1
    fi
    python3 "$project_dir/scripts/check_metadata.py" "$package_dir" >/dev/null
    shopt -s globstar nullglob
    qml_files=("$package_dir"/contents/**/*.qml)
    if ((${#qml_files[@]} == 0)); then
        printf 'No QML files found in %s/contents\n' "$package_dir" >&2
        exit 1
    fi
    if ! command -v qmake6 >/dev/null 2>&1; then
        printf 'qmake6 is required to locate the Qt 6 qmllint\n' >&2
        exit 1
    fi
    qt6_qmllint="$(qmake6 -query QT_INSTALL_BINS)/qmllint"
    if [[ ! -x "$qt6_qmllint" ]]; then
        printf 'Qt 6 qmllint not found at %s\n' "$qt6_qmllint" >&2
        exit 1
    fi
    "$qt6_qmllint" --max-warnings 0 "${qml_files[@]}"
    bash -n "$project_dir/scripts/dev.sh"
    shellcheck "$project_dir/scripts/dev.sh"
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
