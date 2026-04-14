#!/usr/bin/env python3

import argparse
import json
import os
import pathlib
import sys
import urllib.error
import urllib.parse
import urllib.request


API_ROOT = "https://androidpublisher.googleapis.com/androidpublisher/v3"
UPLOAD_ROOT = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3"
ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher"


def request_json(method, url, access_token, body=None, content_type="application/json"):
    headers = {
        "Authorization": f"Bearer {access_token}",
    }

    payload = None
    if body is not None:
        if isinstance(body, (bytes, bytearray)):
            payload = body
            if content_type:
                headers["Content-Type"] = content_type
        else:
            payload = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = content_type
    elif content_type:
        headers["Content-Type"] = content_type

    request = urllib.request.Request(url=url, data=payload, headers=headers, method=method)

    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            charset = response.headers.get_content_charset() or "utf-8"
            raw = response.read().decode(charset)
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"{method} {url} failed with {exc.code}: {message}") from exc


def parse_args():
    parser = argparse.ArgumentParser(
        description="Upload an Android App Bundle to Google Play using the Publishing API."
    )
    parser.add_argument("--package-name", required=True)
    parser.add_argument("--bundle-path", required=True)
    parser.add_argument("--track", required=True)
    parser.add_argument("--release-status", required=True)
    parser.add_argument("--access-token", default="")
    parser.add_argument("--release-name", default="")
    parser.add_argument("--user-fraction", type=float)
    parser.add_argument("--changes-not-sent-for-review", action="store_true")
    return parser.parse_args()


def validate_args(args):
    valid_statuses = {"completed", "draft", "halted", "inProgress"}
    if args.release_status not in valid_statuses:
        raise SystemExit(
            f"--release-status must be one of {sorted(valid_statuses)}, got {args.release_status!r}"
        )

    if args.release_status == "inProgress":
        if args.user_fraction is None:
            raise SystemExit("--user-fraction is required when --release-status is inProgress")
        if not 0 < args.user_fraction < 1:
            raise SystemExit("--user-fraction must be greater than 0 and less than 1")
    elif args.user_fraction is not None:
        raise SystemExit("--user-fraction is only valid when --release-status is inProgress")

    bundle_path = pathlib.Path(args.bundle_path)
    if not bundle_path.is_file():
        raise SystemExit(f"Bundle not found: {bundle_path}")

    if not args.access_token:
        raise SystemExit(
            "Missing access token. Ensure the workflow authenticated with scope "
            f"{ANDROID_PUBLISHER_SCOPE}."
        )


def insert_edit(package_name, access_token):
    url = f"{API_ROOT}/applications/{urllib.parse.quote(package_name, safe='')}/edits"
    response = request_json("POST", url, access_token, body={})
    return response["id"]


def upload_bundle(package_name, edit_id, bundle_path, access_token):
    encoded_package = urllib.parse.quote(package_name, safe="")
    encoded_edit_id = urllib.parse.quote(edit_id, safe="")
    url = (
        f"{UPLOAD_ROOT}/applications/{encoded_package}/edits/{encoded_edit_id}/bundles"
        "?uploadType=media"
    )
    bundle_bytes = pathlib.Path(bundle_path).read_bytes()
    response = request_json(
        "POST",
        url,
        access_token,
        body=bundle_bytes,
        content_type="application/octet-stream",
    )
    return str(response["versionCode"])


def update_track(package_name, edit_id, track, version_code, release_status, release_name, user_fraction, access_token):
    encoded_package = urllib.parse.quote(package_name, safe="")
    encoded_edit_id = urllib.parse.quote(edit_id, safe="")
    encoded_track = urllib.parse.quote(track, safe="")
    url = f"{API_ROOT}/applications/{encoded_package}/edits/{encoded_edit_id}/tracks/{encoded_track}"

    release = {
        "versionCodes": [version_code],
        "status": release_status,
    }
    if release_name:
        release["name"] = release_name
    if user_fraction is not None:
        release["userFraction"] = user_fraction

    body = {
        "track": track,
        "releases": [release],
    }
    request_json("PUT", url, access_token, body=body)


def commit_edit(package_name, edit_id, access_token, changes_not_sent_for_review):
    encoded_package = urllib.parse.quote(package_name, safe="")
    encoded_edit_id = urllib.parse.quote(edit_id, safe="")
    url = f"{API_ROOT}/applications/{encoded_package}/edits/{encoded_edit_id}:commit"
    if changes_not_sent_for_review:
        url += "?changesNotSentForReview=true"
    request_json("POST", url, access_token, body={})


def main():
    args = parse_args()
    if not args.access_token:
        args.access_token = os.environ.get("GOOGLE_PLAY_ACCESS_TOKEN", "")
    validate_args(args)

    edit_id = insert_edit(args.package_name, args.access_token)
    version_code = upload_bundle(args.package_name, edit_id, args.bundle_path, args.access_token)
    update_track(
        args.package_name,
        edit_id,
        args.track,
        version_code,
        args.release_status,
        args.release_name,
        args.user_fraction,
        args.access_token,
    )
    commit_edit(
        args.package_name,
        edit_id,
        args.access_token,
        args.changes_not_sent_for_review,
    )

    print(f"Uploaded versionCode={version_code} to track={args.track} using editId={edit_id}")


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
