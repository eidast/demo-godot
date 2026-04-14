#!/usr/bin/env python3

import argparse
import os
import pathlib
from datetime import datetime, timezone


def parse_args():
    parser = argparse.ArgumentParser(
        description="Derive Android release version metadata for GitHub Actions."
    )
    parser.add_argument("--github-output", required=True)
    parser.add_argument("--build-name", default="")
    parser.add_argument("--build-number", default="")
    parser.add_argument("--default-build-name", default="1.0.0")
    parser.add_argument("--minimum-build-number", type=int, default=2026041300)
    return parser.parse_args()


def main():
    args = parse_args()

    build_name = args.build_name or args.default_build_name
    if args.build_number:
        build_number = args.build_number
    else:
        run_number = int(os.environ.get("GITHUB_RUN_NUMBER", "1"))
        build_number = str(args.minimum_build_number + run_number)

    github_output = pathlib.Path(args.github_output)
    with github_output.open("a", encoding="utf-8") as fh:
        fh.write(f"build_name={build_name}\n")
        fh.write(f"build_number={build_number}\n")
        fh.write(
            "built_at_utc="
            + datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            + "\n"
        )


if __name__ == "__main__":
    main()
