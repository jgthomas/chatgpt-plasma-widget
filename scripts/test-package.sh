#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_id="$(python3 "$project_dir/scripts/check_metadata.py" "$project_dir/package")"
test_dir="$(mktemp -d "${TMPDIR:-/tmp}/chatgpt-package-test.XXXXXXXX")"
trap 'rm -rf -- "$test_dir"' EXIT

fixture_dir="$test_dir/package"
# --show can use the standard data lookup even with --packageroot. Isolate
# that lookup too, so discovery cannot succeed via a real installed widget.
export XDG_DATA_HOME="$test_dir/data"
export XDG_DATA_DIRS="$test_dir/data-dirs"
package_root="$XDG_DATA_HOME/plasma/plasmoids"
mkdir -p "$package_root" "$XDG_DATA_DIRS"
cp -R "$project_dir/package" "$fixture_dir"

# Use predictable versions in the disposable copy so this test also works
# when the project's version includes a development suffix.
python3 - "$fixture_dir/metadata.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
metadata = json.loads(path.read_text(encoding="utf-8"))
metadata["KPlugin"]["Version"] = "1.0.0"
path.write_text(json.dumps(metadata, indent=4) + "\n", encoding="utf-8")
PY

kpackagetool6 --type Plasma/Applet --packageroot "$package_root" --install "$fixture_dir"
kpackagetool6 --type Plasma/Applet --packageroot "$package_root" --show "$plugin_id"
diff -r "$fixture_dir" "$package_root/$plugin_id"

# Change an existing QML file as well as the version: a successful exit alone
# would not prove that an upgrade replaced the installed content.
python3 - "$fixture_dir" <<'PY'
import json
import sys
from pathlib import Path

package = Path(sys.argv[1])
path = package / "metadata.json"
metadata = json.loads(path.read_text(encoding="utf-8"))
metadata["KPlugin"]["Version"] = "1.0.1"
path.write_text(json.dumps(metadata, indent=4) + "\n", encoding="utf-8")
with (package / "contents/ui/main.qml").open("a", encoding="utf-8") as qml:
    qml.write("\n// Package upgrade smoke test.\n")
PY

kpackagetool6 --type Plasma/Applet --packageroot "$package_root" --upgrade "$fixture_dir"
kpackagetool6 --type Plasma/Applet --packageroot "$package_root" --show "$plugin_id"
diff -r "$fixture_dir" "$package_root/$plugin_id"
printf 'Package install/upgrade smoke test passed.\n'
