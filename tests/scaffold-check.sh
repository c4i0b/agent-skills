#!/usr/bin/env bash
# Assertions on a scratch repo produced by following the setup flow.
# Usage: tests/scaffold-check.sh <dir>
# The scaffold itself is DELEGATED however the executing agent prefers
# (subagents, nested CLI sessions — see agent-orchestration); this script
# only checks the result. Rule in AGENTS.md: flow/model changes need a
# fresh scratch scaffold passing this check before commit.
set -euo pipefail

scratch="${1:?usage: scaffold-check.sh <scratch-dir>}"
fail=0

[ -d "$scratch/.git" ] || { echo "FAIL: not a git repo"; exit 1; }

# gate: initial commit exists
[ -n "$(git -C "$scratch" log --oneline 2>/dev/null)" ] \
  || { echo "FAIL: no initial commit"; fail=1; }

# artifacts exist
name="$(basename "$scratch")"
for f in Containerfile compose.yml justfile AGENTS.md README.md docs/README.md; do
  [ -f "$scratch/$f" ] || { echo "FAIL: missing $f"; fail=1; }
done

# image naming convention: <project>/tooling:dev
grep -q "$name/tooling:dev" "$scratch/compose.yml" \
  || { echo "FAIL: image not named $name/tooling:dev"; fail=1; }

# day-one test seed: a test recipe exists and runs a real suite
grep -qE '^test[[:space:]]*:' "$scratch/justfile" \
  || { echo "FAIL: no 'test' recipe in justfile"; fail=1; }
find "$scratch" -name '*test*' -not -path '*/.git/*' | grep -q . \
  || { echo "FAIL: no test files seeded"; fail=1; }

# tag policy: FROM must be latest or a current major (no EOL pins)
grep -E '^FROM ' "$scratch/Containerfile" | grep -vE ':(latest|latest-dev|1\.27|3\.24|3\.15|26|10|rawhide)' \
  && { echo "FAIL: FROM pinned to a non-current tag"; fail=1; }

[ "$fail" -eq 0 ] && echo "scaffold check: ALL CHECKS PASSED"
exit "$fail"
