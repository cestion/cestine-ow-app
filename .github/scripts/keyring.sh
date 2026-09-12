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

# Decode failures used to be invisible: base64's stderr is suppressed (below) and
# every caller in ci.yml only tested for an empty result, so a bad blob surfaced
# as a bare `exit 1` with no log line, or as an opaque 401 from the API. Say what
# is actually wrong and how to fix it.
bad_blob() {
  {
    echo "keyring: decode 失败 —— $1"
    echo "  MINIMAX_KEY_BLOB 里要存的是 'keyring.sh encode <明文key>' 的输出,不是明文 key 本身。"
    echo "  重新生成:  read -rs KEY && .github/scripts/keyring.sh encode \"\$KEY\""
  } >&2
  exit 3
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
    # Validate the blob before decoding. Secrets pasted through the web UI pick up
    # trailing newlines and stray spaces (base64 tolerates newlines, not spaces),
    # and a blob truncated mid-copy still decodes — to a *prefix* of the real key,
    # which then fails as an indistinguishable 401. Both are worth naming exactly.
    CLEAN=${VALUE//[[:space:]]/}
    case "$CLEAN" in
      *[!A-Za-z0-9+/=]*) bad_blob 'blob 含 base64 以外的字符(存的多半是明文 key)' ;;
    esac
    [ $(( ${#CLEAN} % 4 )) -eq 0 ] \
      || bad_blob "blob 长度 ${#CLEAN} 不是 4 的倍数,复制时被截断了"

    # Buffer the result rather than streaming it to stdout. GNU base64 writes the
    # bytes it managed to parse *before* hitting an invalid character and only
    # then exits non-zero, so streaming let a secret that holds the plaintext key
    # put XOR garbage on stdout; callers saw a non-empty value, sent it as the API
    # key, and got back a 401 with no hint about the real cause.
    PLAIN=$(printf '%s' "$CLEAN" | base64 --decode 2>/dev/null | python3 -c "$PY_XOR" "$PAD") \
      || bad_blob 'blob 不是合法 base64'
    case "$PLAIN" in
      '')             bad_blob '解出来是空值' ;;
      *[![:print:]]*) bad_blob '解出来含不可打印字符,说明它不是本脚本 encode 出来的 blob' ;;
    esac
    printf '%s' "$PLAIN"
    ;;
  *)
    usage
    ;;
esac
