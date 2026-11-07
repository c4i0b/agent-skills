#!/usr/bin/env bash
# Every relative markdown link in the repo's skills, README and AGENTS.md
# must resolve. Catches breakage from renames/moves before commit.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

while IFS= read -r f; do
  dir="$(dirname "$f")"
  while IFS= read -r link; do
    target="${link%\#*}"
    [ -n "$target" ] || continue
    case "$target" in
      http*|mailto*) continue ;;
    esac
    if [ ! -e "$dir/$target" ]; then
      echo "FAIL: $f -> $target"
      fail=1
    fi
  done < <(grep -hoE '\]\([^)]+\)' "$f" | sed 's/^\](//; s/)$//')
done < <(find "$root/skills" -name '*.md'; echo "$root/README.md"; echo "$root/AGENTS.md")

[ "$fail" -eq 0 ] && echo "links check: ALL LINKS RESOLVE"
exit "$fail"
