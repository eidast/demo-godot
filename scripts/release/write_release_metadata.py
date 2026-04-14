#!/usr/bin/env python3

import argparse
import json
import pathlib
from datetime import datetime, timezone


def parse_args():
    parser = argparse.ArgumentParser(
        description="Write release metadata for an exported Android App Bundle."
    )
    parser.add_argument("--output", required=True)
    parser.add_argument("--package-name", required=True)
    parser.add_argument("--version-name", required=True)
    parser.add_argument("--build-number", required=True)
    parser.add_argument("--git-sha", required=True)
    parser.add_argument("--ref-name", required=True)
    parser.add_argument("--source-run-id", required=True)
    parser.add_argument("--source-repo", required=True)
    parser.add_argument("--source-run-url", required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    output_path = pathlib.Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    metadata = {
        "package_name": args.package_name,
        "version_name": args.version_name,
        "build_number": args.build_number,
        "git_sha": args.git_sha,
        "ref_name": args.ref_name,
        "source_run_id": args.source_run_id,
        "source_repo": args.source_repo,
        "source_run_url": args.source_run_url,
        "built_at_utc": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }

    output_path.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
