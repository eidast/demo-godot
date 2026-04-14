#!/usr/bin/env python3

import argparse
import pathlib


def parse_args():
    parser = argparse.ArgumentParser(
        description="Write a minimal Godot editor settings file for Android CI exports."
    )
    parser.add_argument("--output", required=True, help="Path to editor_settings-4.6.tres")
    parser.add_argument("--java-sdk-path", required=True)
    parser.add_argument("--android-sdk-path", required=True)
    parser.add_argument("--debug-keystore-path", default="")
    parser.add_argument("--debug-keystore-password", default="android")
    return parser.parse_args()


def main():
    args = parse_args()
    output_path = pathlib.Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    content = f"""[gd_resource type="EditorSettings" format=3]

[resource]
_export_preset_advanced_mode = false
export/android/debug_keystore = "{args.debug_keystore_path}"
export/android/debug_keystore_pass = "{args.debug_keystore_password}"
export/android/java_sdk_path = "{args.java_sdk_path}"
export/android/android_sdk_path = "{args.android_sdk_path}"
"""

    output_path.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    main()
