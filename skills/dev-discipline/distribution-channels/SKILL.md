---
name: distribution-channels
description: Reference for repos that ship beyond their git tag/registry — packaging channels such as community repos, distro packages, app stores. Boundary model (downstream, CI-gated, manual-first), the CI-as-gate enforcement pattern, the repo-level channel inventory, and throwaway container-based validation environments. Per-channel references ship with validated examples. Use when a repo adds or releases to a packaging channel.
---

# Distribution channels

Reference, not flow: the
[release flow](../release/SKILL.md) decides when channels are
consulted (at `plan` time); this skill holds what each channel needs.
The channel inventory — which channels a repo ships to and each one's
state — lives in the repo, like tag policy; this skill holds the
mechanisms. Per-channel knowledge lives in
[references/](references/), one file per channel family.

## Boundary: every channel is downstream, CI-gated, or manual-first

| Kind | What drives it | At plan/publish time |
|---|---|---|
| downstream | the publish event itself (a channel workflow on `release: published`) or external automation (a distro repo's auto-bump bot) | nothing; verify the tail ran |
| CI-gated | branch CI builds the channel, so the exact-SHA publish gate fail-closes on a stale one | fix before publish, only if CI is red |
| manual-first | a human (accounts, keys, review queues) | reported as outside the publish boundary; never scripted around |

1. Channels never grow the release script. A channel whose artifact
   hash derives from content becomes a CI job: the existing exact-SHA
   CI gate then refuses to publish with a stale hash — zero script
   changes (**CI-as-gate**).
2. Published-history-immutable extends to channels: never force-push a
   channel's own repository; package/distro repositories follow their
   own immutability conventions.
3. Channel automation can ship before the channel account exists: gate
   the workflow on a repo variable, default off, and arm it when the
   account does.
4. Prefer release-pinned channels (version and hashes in one
   expression, advanced by the release event): no hash can go stale
   between releases by construction, so no bump flow ever owns a
   channel fix. Rolling-main channels are the exception — they are
   CI-gated by necessity, and their bump flow must carry the hash fix
   itself when token events leave the PR gate blind.

## CI-as-gate

Enforce a channel invariant by adding it to branch CI instead of
teaching the release script, so the publish gate's exact-SHA CI check
fail-closes on it. The natural fit is content-derived hashes (vendor
and dependency hashes, source checksums): they go stale in specific,
predictable ways, and CI already builds the artifact that proves them.
What CI cannot build (an external review queue, a store submission)
cannot be CI-gated: it is manual-first by definition. And the gate is
blind on branches whose events do not trigger workflows (token-driven
automation): there the rule inverts — the automation that causes the
drift must carry the fix itself, on its own branch, before merging
(red: a token-driven bump PR auto-merged with a stale channel hash
and zero red checks, because neither the PR's events nor the merge
triggered CI).

## Validation environments

Validate each channel where its users live, in a throwaway
container-based environment, then discard it; full recreate recipes
are repo-level (the repo's docs/). These are instances of the
[ephemeral-tooling
model](../../project-setup/ephemeral-tooling/model/SKILL.md): the
host stays clean, the environment is disposable, and privileged
escapes (mock) get a dedicated service. The recurring shape: distro
container + the channel's own build tool + `--nodeps`-style escapes
for dependencies the local resolver cannot see. Channel-specific
gotchas (sandbox masks, cache gaps, expected-warning noise) live in
each reference below.

## Channels

Each reference ships with a real validated example — no speculation;
new channel families (deb/rpm, flatpak, app stores) are candidates
until a real repo ships there.

| Channel | Reference | Validated in |
|---|---|---|
| AUR | [references/aur.md](references/aur.md) | topmatic (Nov 2026) |
| Nix (nixpkgs + repo package + NUR) | [references/nix.md](references/nix.md) | topmatic (Nov 2026) |
| COPR | [references/copr.md](references/copr.md) | fedora-packages (Nov 2026) |
