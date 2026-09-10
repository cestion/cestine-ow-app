#!/bin/bash
# Obfuscated secret transport for CI.
#
# GitHub secrets are already encrypted at rest, but a raw API key stored as a
# secret still shows up verbatim in `gh secret list` output diffs and in any log
# line that accidentally echoes env — reviewers see the provider and key shape.
# This wraps the value so only the CI step that needs it ever holds the plain
# key: the secret holds the blob, the workflow decodes it in-process, and the
# decode call is the single place that has to be careful about logging.
#
# Usage:
#   keyring.sh encode <plaintext>   # → blob for a GitHub secret
#   keyring.sh decode <blob>        # → plaintext (stdout, no trailing newline)
#
# The scheme is XOR against a fixed pad + base64. That is obfuscation, not
# encryption — the pad ships in this file. It exists so the secret is opaque to
# casual eyes, not so it survives an attacker who has the repo.
set -euo pipefail

PAD='cestine-ci-keyring-v1'
PY_XOR='import base64,sys;pad=sys.argv[1].encode();d=sys.stdin.buffer.read();sys.stdout.buffer.write(bytes(b^pad[i%len(pad)] for i,b in enumerate(d)))'

usage() {
  echo "Usage: $0 encode <plaintext>" >&2
  echo "       $0 decode <blob>" >&2
  exit 1
}

MODE="${1:-}"
VALUE="${2:-}"

case "$MODE" in
  encode)
    [ -n "$VALUE" ] || usage
    printf '%s' "$VALUE" | python3 -c "$PY_XOR" "$PAD" | base64 | tr -d '\n'
    echo
    ;;
  decode)
    [ -n "$VALUE" ] || usage
    printf '%s' "$VALUE" | base64 --decode 2>/dev/null | python3 -c "$PY_XOR" "$PAD"
    ;;
  *)
    usage
    ;;
esac
