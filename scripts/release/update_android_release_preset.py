#!/usr/bin/env python3

import argparse
import pathlib
import re


def parse_args():
    parser = argparse.ArgumentParser(
        description="Update the Android release preset fields in export_presets.cfg."
    )
    parser.add_argument("--preset-file", default="export_presets.cfg")
    parser.add_argument("--package-name", required=True)
    parser.add_argument("--version-name", required=True)
    parser.add_argument("--version-code", required=True)
    parser.add_argument("--export-path", default="build/android/gameoflife-release.aab")
    return parser.parse_args()


def replace_value(section: str, key: str, value: str, quote: bool = False) -> str:
    escaped_value = f'"{value}"' if quote else value
    pattern = rf"(^\s*{re.escape(key)}=).*$"
    replacement = rf"\g<1>{escaped_value}"
    updated, count = re.subn(pattern, replacement, section, flags=re.MULTILINE)
    if count == 0:
        raise SystemExit(f"Missing key {key!r} in release preset section")
    return updated


def main():
    args = parse_args()
    preset_path = pathlib.Path(args.preset_file)
    content = preset_path.read_text(encoding="utf-8")

    match = re.search(
        r"(\[preset\.1\].*?\[preset\.1\.options\]\n)(.*)$",
        content,
        flags=re.DOTALL,
    )
    if not match:
        raise SystemExit("Unable to locate [preset.1.options] in export_presets.cfg")

    release_section = match.group(0)
    release_section = replace_value(release_section, "export_path", args.export_path, quote=True)
    release_section = replace_value(
        release_section, "package/unique_name", args.package_name, quote=True
    )
    release_section = replace_value(
        release_section, "version/name", args.version_name, quote=True
    )
    release_section = replace_value(release_section, "version/code", args.version_code)

    updated_content = content[: match.start()] + release_section
    preset_path.write_text(updated_content, encoding="utf-8")


if __name__ == "__main__":
    main()
