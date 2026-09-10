#!/usr/bin/env python3
"""Normalize `dart analyze` / `flutter analyze` output for base-vs-head diffing.

The point of the analyzer-diff job is to answer "did this change introduce new
problems, and did it fix any?" — not "did the line numbers move?". A raw textual
diff of analyzer output reports every finding in a shifted file as both new and
fixed, which buries the real signal.

So we blank out the line:col of every `path.dart:LINE:COL` reference and collapse
runs of whitespace. If a finding is still present but moved 40 lines down, its
signature is unchanged and it does not appear as a change.

We deliberately do *not* try to parse the severity/message/code fields apart:
the separator character and field order have varied across analyzer versions, and
a regex that assumes one shape silently produces garbage on another. Rewriting
positions is shape-independent.

Reads analyzer output on stdin (stdout + stderr already merged), writes one
signature per line to stdout.

Usage: analyzer_diff_normalize.py < analyzer.log > signatures.txt
"""

import re
import sys

# `file.dart:12:5` → `file.dart:_`. Also covers `file.dart:12` (no column).
_POSITION = re.compile(r"(\.dart):\d+(?::\d+)?")
_ANSI = re.compile(r"\x1b\[[0-9;]*m")
_WHITESPACE = re.compile(r"\s+")

# A real diagnostic carries both a `.dart` location and a snake_case code, and
# begins with a severity word. Progress chatter ("Analyzing story_app…",
# "4 issues found.") satisfies at most one of those, so all three are required.
_SEVERITY = re.compile(r"^\s*(error|warning|info|fatal|hint)\b", re.IGNORECASE)
_CODE = re.compile(r"\b[a-z][a-z0-9]*(?:_[a-z0-9]+)+\b")
_LOCATION = re.compile(r"\.dart:\d+")


def normalize(line: str) -> "str | None":
    line = _ANSI.sub("", line)
    if not _LOCATION.search(line):
        return None
    line = _POSITION.sub(r"\1:_", line)
    line = _WHITESPACE.sub(" ", line).strip()
    if not _SEVERITY.search(line) or not _CODE.search(line):
        return None
    return line


def main() -> None:
    seen = set()
    for raw in sys.stdin:
        sig = normalize(raw)
        if sig:
            seen.add(sig)
    for sig in sorted(seen):
        print(sig)


if __name__ == "__main__":
    main()
