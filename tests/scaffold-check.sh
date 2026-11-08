#!/usr/bin/env bash
# Assertions on a scratch repo produced by following the setup flow.
# Usage: tests/scaffold-check.sh <dir>
# The scaffold itself is DELEGATED however the executing agent prefers
# (subagents, nested CLI sessions — see agent-orchestration); this script
# only checks the result. Rule in AGENTS.md: flow/model changes need a
# fresh scratch scaffold passing this check before commit.
#
# Red-green: every assertion below exists because its red was OBSERVED in
# a real run. New assertions must cite their red.
#   no initial commit  -> test 1 scaffold (everything staged, zero commits)
#   missing artifacts  -> test 1 (docs/ absent from gate)
#   image naming       -> test 1 (ad-hoc "timew-tooling:local")
#   non-current FROM   -> test 1 (golang:1.22, EOL minor in 2026)
#   no test recipe     -> gate gap: quality command was aspirational
#   build: silent no-op-> qw-gate run (image: without build: builds nothing)
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

# image naming convention: <project>/tooling:dev (project may differ from
# the scratch dir name, e.g. when the flow names the app)
grep -qE '[a-z0-9_-]+/tooling:dev' "$scratch/compose.yml" \
  || { echo "FAIL: image not named <project>/tooling:dev"; fail=1; }

# day-one test seed: a test recipe exists and runs a real suite
# (recipe may carry args: "test *args:" failed the old ^test\s*: grep)
grep -qE '^test([[:space:]]+[^:]*)?[[:space:]]*:' "$scratch/justfile" \
  || { echo "FAIL: no 'test' recipe in justfile"; fail=1; }
find "$scratch" -name '*test*' -not -path '*/.git/*' | grep -q . \
  || { echo "FAIL: no test files seeded"; fail=1; }

# tag policy: FROM must be latest or a current major (no EOL pins)
grep -E '^FROM ' "$scratch/Containerfile" | grep -vE ':(latest|latest-dev|1\.27|3\.24|3\.15|26|10|rawhide)' \
  && { echo "FAIL: FROM pinned to a non-current tag"; fail=1; }

[ "$fail" -eq 0 ] && echo "scaffold check: ALL CHECKS PASSED"
exit "$fail"
