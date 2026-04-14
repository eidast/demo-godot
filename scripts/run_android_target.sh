#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APK_PATH="$ROOT_DIR/build/android/demo-godot-debug.apk"
ADB_PATH="${ADB_PATH:-$HOME/Library/Android/sdk/platform-tools/adb}"
PACKAGE_NAME="${PACKAGE_NAME:-com.starquantix.gameoflife}"
GODOT_BIN="${GODOT_BIN:-godot}"
PROJECT_FILE="$ROOT_DIR/project.godot"
DEVICE_KIND="${1:-}"
DEVICE_SERIAL="${2:-}"

if [[ "$DEVICE_KIND" != "emulator" && "$DEVICE_KIND" != "phone" ]]; then
  echo "Usage: scripts/run_android_target.sh <emulator|phone> [device_serial]" >&2
  exit 1
fi

if [[ ! -x "$ADB_PATH" ]]; then
  echo "adb not found at: $ADB_PATH" >&2
  echo "Set ADB_PATH or install Android platform-tools." >&2
  exit 1
fi

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot binary not found: $GODOT_BIN" >&2
  echo "Set GODOT_BIN to your Godot executable name or full path." >&2
  exit 1
fi

if [[ -z "$DEVICE_SERIAL" ]]; then
  if [[ "$DEVICE_KIND" == "emulator" ]]; then
    DEVICE_SERIAL="$("$ADB_PATH" devices | awk 'NR > 1 && $1 ~ /^emulator-/ && $2 == "device" { print $1; exit }')"
  else
    DEVICE_SERIAL="$("$ADB_PATH" devices | awk 'NR > 1 && $1 !~ /^emulator-/ && $2 == "device" { print $1; exit }')"
  fi
fi

if [[ -z "$DEVICE_SERIAL" ]]; then
  echo "No matching Android $DEVICE_KIND detected." >&2
  echo "Start/connect one first or pass a device serial explicitly." >&2
  exit 1
fi

TARGET_RENDERER="mobile"
if [[ "$DEVICE_KIND" == "emulator" ]]; then
  TARGET_RENDERER="gl_compatibility"
fi

ORIGINAL_RENDERING_METHOD="$(awk -F= '/^renderer\/rendering_method=/{gsub(/"/, "", $2); print $2; exit}' "$PROJECT_FILE")"
ORIGINAL_RENDERING_METHOD_MOBILE="$(awk -F= '/^renderer\/rendering_method\.mobile=/{gsub(/"/, "", $2); print $2; exit}' "$PROJECT_FILE")"

restore_renderer() {
  python3 - "$PROJECT_FILE" "$ORIGINAL_RENDERING_METHOD" "$ORIGINAL_RENDERING_METHOD_MOBILE" <<'PY'
import pathlib
import re
import sys

project_file = pathlib.Path(sys.argv[1])
rendering_method = sys.argv[2]
rendering_method_mobile = sys.argv[3]
text = project_file.read_text(encoding="utf-8")
text = re.sub(r'^renderer/rendering_method="[^"]*"$', f'renderer/rendering_method="{rendering_method}"', text, flags=re.MULTILINE)
text = re.sub(r'^renderer/rendering_method\.mobile="[^"]*"$', f'renderer/rendering_method.mobile="{rendering_method_mobile}"', text, flags=re.MULTILINE)
project_file.write_text(text, encoding="utf-8")
PY
}

trap restore_renderer EXIT

python3 - "$PROJECT_FILE" "$TARGET_RENDERER" <<'PY'
import pathlib
import re
import sys

project_file = pathlib.Path(sys.argv[1])
renderer = sys.argv[2]
text = project_file.read_text(encoding="utf-8")
text = re.sub(r'^renderer/rendering_method="[^"]*"$', f'renderer/rendering_method="{renderer}"', text, flags=re.MULTILINE)
text = re.sub(r'^renderer/rendering_method\.mobile="[^"]*"$', f'renderer/rendering_method.mobile="{renderer}"', text, flags=re.MULTILINE)
project_file.write_text(text, encoding="utf-8")
PY

echo "Using device: $DEVICE_SERIAL"
echo "Using renderer: $TARGET_RENDERER"
echo "Exporting debug APK..."
(cd "$ROOT_DIR" && "$GODOT_BIN" --headless --editor --path . --script res://scripts/ExportAndroid.gd)

if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found after export: $APK_PATH" >&2
  exit 1
fi

echo "Installing APK..."
"$ADB_PATH" -s "$DEVICE_SERIAL" install -r "$APK_PATH"

echo "Launching app..."
"$ADB_PATH" -s "$DEVICE_SERIAL" shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1 >/dev/null

echo "Done."
