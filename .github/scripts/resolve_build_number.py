#!/usr/bin/env python3
"""Determine the next TestFlight build number for the app.

Reads the highest existing build version from the App Store Connect
builds API (via a JWT signed with the repo's .p8 key) and prints
max(version) + 1. Exits non-zero if it cannot be determined, so the
caller can fall back to the pubspec value.

Usage:
  resolve_build_number.py <p8_content> <key_id> <issuer_id> <bundle_id>
"""
import base64
import json
import sys
import time
import urllib.request

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils as ec_utils


def b64url(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


def main() -> int:
    try:
        return _run()
    except Exception as exc:
        # Any failure (bad key, network, API error, parsing) must let the
        # caller fall back to the pubspec build number. Log the real reason
        # to stderr so the workflow output shows why the query failed;
        # the caller currently discards it (2>/tmp/...), see workflow.
        print(f"resolve_build_number.py failed: {type(exc).__name__}: {exc}", file=sys.stderr)
        return 3


def _run() -> int:
    p8, key_id, issuer, bundle_id = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

    # Build an ES256 JWT signed with the App Store Connect API key.
    now = int(time.time())
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    payload = {"iss": issuer, "iat": now, "exp": now + 1200}
    header_b64 = b64url(json.dumps(header, separators=(",", ":")).encode())
    payload_b64 = b64url(json.dumps(payload, separators=(",", ":")).encode())
    signing_input = f"{header_b64}.{payload_b64}".encode()

    key = serialization.load_pem_private_key(p8.encode(), password=None)
    der_sig = key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
    r, s = ec_utils.decode_dss_signature(der_sig)
    # ES256 signatures must be exactly 64 bytes (32 per integer). r/s are
    # zero-padded on the left; the original code used the integer's bit length,
    # which produced short signatures and got 401s from App Store Connect.
    sig_b64 = b64url(
        r.to_bytes(32, "big") + s.to_bytes(32, "big")
    )
    jwt = f"{signing_input.decode()}.{sig_b64}"

    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com/v1/builds"
        f"?filter[bundleId]={bundle_id}&limit=200&sort=-version",
        headers={"Authorization": f"Bearer {jwt}"},
    )
    with urllib.request.urlopen(req) as r:
        data = json.loads(r.read().decode())

    versions = []
    if data and data.get("data"):
        for b in data["data"]:
            v = b.get("attributes", {}).get("version")
            if isinstance(v, int):
                versions.append(v)

    if not versions:
        return 3

    print(max(versions) + 1)
    return 0


if __name__ == "__main__":
    sys.exit(main())
