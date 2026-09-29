#!/usr/bin/env python3
"""Check the minimal Plasma package contract before installing the widget."""

import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"Plasma package check failed: {message}")


if len(sys.argv) != 2:
    fail("expected the package directory as the only argument")

package_dir = Path(sys.argv[1])
metadata_path = package_dir / "metadata.json"

try:
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as error:
    fail(f"cannot read {metadata_path}: {error}")

if metadata.get("KPackageStructure") != "Plasma/Applet":
    fail("KPackageStructure must be Plasma/Applet")
if metadata.get("X-Plasma-API-Minimum-Version") != "6.0":
    fail("X-Plasma-API-Minimum-Version must be 6.0")

plugin = metadata.get("KPlugin")
if not isinstance(plugin, dict):
    fail("KPlugin must be an object")
for field in ("Id", "Name", "Icon", "Version"):
    if not isinstance(plugin.get(field), str) or not plugin[field].strip():
        fail(f"KPlugin.{field} must be a non-empty string")

if not (package_dir / "contents" / "ui" / "main.qml").is_file():
    fail("contents/ui/main.qml is missing")

print(plugin["Id"])
