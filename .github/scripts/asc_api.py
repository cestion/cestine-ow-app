#!/usr/bin/env python3
"""Minimal App Store Connect API client shared by the iOS build scripts.

Only what the workflow actually needs: an ES256 JWT signed with the .p8 key,
a JSON request helper that surfaces Apple's error detail, and the
bundle-id -> numeric app id lookup that every other query depends on.

Extracted from resolve_build_number.py when testflight_distribute.py needed
the same three things. The JWT in particular has two non-obvious requirements
(the aud claim, fixed-width r/s) that were each a 401 before being fixed --
worth getting right in one place rather than two.
"""
import base64
import json
import time
import urllib.error
import urllib.request

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils as ec_utils

API_ROOT = "https://api.appstoreconnect.apple.com"


class AscError(Exception):
    """An API call Apple rejected, with its detail message if it gave one."""

    def __init__(self, status, detail):
        super().__init__(f"HTTP {status}: {detail}")
        self.status = status
        self.detail = detail


def _b64url(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()


class AscClient:
    def __init__(self, p8: str, key_id: str, issuer: str):
        self._key = serialization.load_pem_private_key(p8.encode(), password=None)
        self._key_id = key_id
        self._issuer = issuer

    def _token(self) -> str:
        # Minted per request rather than cached: Apple caps token lifetime at
        # 20 minutes and testflight_distribute.py polls for longer than that
        # while a build processes. Signing is microseconds; a token expiring
        # mid-wait is a 401 with nothing to show for the wait.
        now = int(time.time())
        header = {"alg": "ES256", "kid": self._key_id, "typ": "JWT"}
        # Apple requires aud="appstoreconnect-v1"; without it every request is
        # rejected with 401. exp must be within 20 minutes of iat.
        payload = {
            "iss": self._issuer,
            "iat": now,
            "exp": now + 900,
            "aud": "appstoreconnect-v1",
        }
        header_b64 = _b64url(json.dumps(header, separators=(",", ":")).encode())
        payload_b64 = _b64url(json.dumps(payload, separators=(",", ":")).encode())
        signing_input = f"{header_b64}.{payload_b64}".encode()

        der_sig = self._key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
        r, s = ec_utils.decode_dss_signature(der_sig)
        # ES256 signatures must be exactly 64 bytes (32 per integer). r/s are
        # zero-padded on the left; using the integer's own bit length produced
        # short signatures and got 401s from App Store Connect.
        sig_b64 = _b64url(r.to_bytes(32, "big") + s.to_bytes(32, "big"))
        return f"{signing_input.decode()}.{sig_b64}"

    def request(self, method: str, path: str, body=None):
        """Call the API. Returns the parsed body, or None for 204 responses."""
        url = path if path.startswith("http") else API_ROOT + path
        headers = {"Authorization": f"Bearer {self._token()}"}
        data = None
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(url, data=data, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req) as resp:
                raw = resp.read()
                return json.loads(raw.decode()) if raw else None
        except urllib.error.HTTPError as exc:
            # Apple returns {"errors":[{"title","detail",...}]}. The bare status
            # is rarely enough to act on -- 409 alone could be a wrong app, an
            # already-attached build, or a build that is still processing.
            raw = exc.read().decode(errors="replace")
            detail = raw
            try:
                errs = json.loads(raw).get("errors") or []
                if errs:
                    detail = "; ".join(
                        filter(None, (e.get("detail") or e.get("title") for e in errs))
                    )
            except ValueError:
                pass
            raise AscError(exc.code, detail) from None

    def app_id(self, bundle_id: str) -> str:
        # /v1/builds has no filter[bundleId] -- passing one there returns 200
        # with an empty data array (silently), which is why the build number
        # query used to always fail. Every query goes through the numeric id.
        data = self.request("GET", f"/v1/apps?filter[bundleId]={bundle_id}&limit=1")
        entries = (data or {}).get("data") or []
        if not entries:
            raise AscError(404, f"no app found for bundle id {bundle_id}")
        return entries[0]["id"]
