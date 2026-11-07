#!/usr/bin/env bash
# Scaffold smoke: proves the setup flow still produces a conforming repo.
# Run after ANY change to a flow or to model/references (AGENTS.md rule).
set -euo pipefail

scratch="$(mktemp -d /tmp/opencode/skill-smoke.XXXXXX)"
trap 'rm -rf "$scratch"' EXIT

cd "$scratch"
opencode run "Set up a NEW project in this directory: a small Go CLI called
smoke that prints OK, with one unit test. Follow the skill at
/home/caio/Projects/agent-skills/skills/ephemeral-tooling/setup/SKILL.md —
read it and everything it points to, then do what it says. Finish with the
skill's validation gate." >/dev/null

fail=0
step() { echo "$1"; }

# gate: initial commit exists
[ -n "$(git -C "$scratch" log --oneline 2>/dev/null)" ] \
  || { step "FAIL: no initial commit"; fail=1; }

# artifacts exist
for f in Containerfile compose.yml justfile AGENTS.md README.md docs/README.md; do
  [ -f "$scratch/$f" ] || { step "FAIL: missing $f"; fail=1; }
done

# image naming convention: <project>/tooling:dev
grep -q 'smoke/tooling:dev' "$scratch/compose.yml" \
  || { step "FAIL: image not named smoke/tooling:dev"; fail=1; }

# tag policy: FROM must be latest or the current major (no EOL pins)
grep -E '^FROM ' "$scratch/Containerfile" | grep -vE ':(latest|latest-dev|1\.27|3\.24|3\.15|26|10|rawhide)' \
  && { step "FAIL: FROM pinned to a non-current tag"; fail=1; }

[ "$fail" -eq 0 ] && echo "scaffold smoke: ALL CHECKS PASSED"
exit "$fail"
