#!/usr/bin/env python3

from __future__ import annotations

from datetime import date
import pathlib
import re
import sys

workflow_path = pathlib.Path(".github/workflows/build_release.yml")

# We want YYYY.#### (#### can be 1000+)
VERSION_RE = re.compile(r"^(?P<year>\d{4})\.(?P<seq>\d{4,})$")

def compute_next_version(current_version: str | None) -> str:
    current_year = date.today().year

    if current_version:
        m = VERSION_RE.match(current_version.strip())
        if m:
            stored_year = int(m.group("year"))
            stored_seq = int(m.group("seq"))
            if stored_year == current_year:
                return f"{current_year}.{stored_seq + 1}"
            return f"{current_year}.1000"

    return f"{current_year}.1000"

if not workflow_path.exists():
    print(f"Error: {workflow_path} not found", file=sys.stderr)
    sys.exit(1)

text = workflow_path.read_text(encoding="utf-8")

# Match:
# DOCKER_TARGET_RELEASE: 2025.1000
# DOCKER_TARGET_RELEASE: "2025.1000"
# DOCKER_TARGET_RELEASE: '2025.1000'
pattern = re.compile(
    r"(?m)^(?P<prefix>\s*DOCKER_TARGET_RELEASE:\s*)(?P<quote>['\"]?)(?P<ver>\d{4}\.\d{4,})(?P=quote)\s*$"
)

m = pattern.search(text)
if not m:
    print("Error: DOCKER_TARGET_RELEASE not found (or not in expected format) in workflow", file=sys.stderr)
    sys.exit(1)

old_version = m.group("ver")
new_version = compute_next_version(old_version)

def repl(match: re.Match) -> str:
    return f"{match.group('prefix')}{match.group('quote')}{new_version}{match.group('quote')}\n"

updated_text, n = pattern.subn(repl, text, count=1)
if n != 1:
    print("Error: unexpected number of replacements", file=sys.stderr)
    sys.exit(1)

workflow_path.write_text(updated_text, encoding="utf-8")

print(f"Updated DOCKER_TARGET_RELEASE from {old_version} to {new_version}")
