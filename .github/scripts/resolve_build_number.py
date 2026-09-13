#!/usr/bin/env python3
"""Determine the next TestFlight build number for the app.

Reads the highest existing build version from the App Store Connect
builds API (via a JWT signed with the repo's .p8 key) and prints
max(version) + 1. Exits non-zero if it cannot be determined, so the
caller can fail loudly rather than reuse a stale pubspec number.

Usage:
  resolve_build_number.py <p8_content> <key_id> <issuer_id> <bundle_id>
"""
import sys

from asc_api import AscClient, AscError


def main() -> int:
    try:
        return _run()
    except Exception as exc:
        # Any failure (bad key, network, API error, parsing) must surface the
        # real reason on stderr -- the workflow prints it and then refuses to
        # fall back to the pubspec number, which is likely already used.
        print(f"resolve_build_number.py failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 3


def _run() -> int:
    p8, key_id, issuer, bundle_id = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
    api = AscClient(p8, key_id, issuer)

    try:
        app_id = api.app_id(bundle_id)
    except AscError as exc:
        print(str(exc), file=sys.stderr)
        return 3

    data = api.request(
        "GET", f"/v1/builds?filter[app]={app_id}&sort=-version&limit=200"
    )

    versions = []
    for b in (data or {}).get("data") or []:
        v = b.get("attributes", {}).get("version")
        # The ASC API returns version as a string ("114"); accept both.
        if isinstance(v, str) and v.strip().isdigit():
            versions.append(int(v))
        elif isinstance(v, int):
            versions.append(v)

    if not versions:
        return 3

    print(max(versions) + 1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
