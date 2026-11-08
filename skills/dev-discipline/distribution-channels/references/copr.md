# COPR (Fedora build service)

A push-triggered channel where the git repo IS the package source:
COPR clones it, produces SRPMs via `.copr/Makefile` and rebuilds
through a webhook on every push — no submission, no artifact upload.
Validated in fedora-packages (RPM spec monorepo, Fedora stable +
Rawhide + EPEL, Nov 2026). Works for an app repo shipping itself, or a
package collection shipping many.

## Boundary classification

Downstream of push, not of the release: the webhook rebuilds when a
commit touches the package's directory. COPR builds are not GitHub
Actions runs, so the release publish gate's exact-SHA CI check does
not see them — a COPR channel supplements CI, it cannot replace it as
the publish gate.

## The srpm contract (`.copr/Makefile`)

- COPR invokes `make -f .copr/Makefile srpm outdir=... spec=...` with
  cwd in the package directory, and `spec=` points at the
  **subdirectory**, not the .spec file. The Makefile resolves both —
  do not simplify it away.
- The SRPM builder chroot has an **arbitrary architecture** (aarch64
  observed): source URLs must never depend on the build arch — ship
  one `Source` per arch and select with `%ifarch`.
- `_disable_source_fetch 0` is what lets rpmbuild download URL
  sources (COPR sets it; the Makefile defines it for local parity).
- Source payloads are already-compressed tarballs: rpm's default
  zstd-19 burns ~9x the CPU for zero size win — level 1 is
  size-identical.

## Webhook semantics (verified in COPR source)

- A push rebuilds a package only if the commit touches files under
  its package directory. Empty commits trigger nothing.
- Pushes made with `GITHUB_TOKEN` trigger the COPR webhook but do NOT
  re-trigger GitHub Actions workflows (the inverse of the usual
  direction).
- Webhook is push events only, `application/json`, from COPR
  Settings → Integrations.
- Register a new package with the project before pushing, or the
  first push triggers nothing and the build must be poked by hand.

## Owners and identity

GitHub and COPR/FAS owners can differ; clone URLs use the GitHub
owner, COPR project paths use the FAS owner. Mixing them fails the
SRPM build with an auth prompt (`could not read Username for
'https://github.com'`).

## Build validation policy

- COPR is the only build validator: run the repo's local checks, push,
  let the webhook build. Never reproduce with mock preemptively —
  mock (with network, matching the project's chroots) is the escape
  hatch for inconclusive failure logs only.
- Do not block waiting for builds; poll status when finishing a task.
- When `fedora-review` is enabled on the project, builds run slower
  than usual — expected, not a hang.
- Chroots do not auto-branch: after a major EPEL release, re-run
  project setup (new chroot rebuilds nothing — poke builds once).

## Validation environment (ephemeral-tooling model)

Packaging work runs in the repo's tooling container, never on the
host: a Fedora base matching the project's top chroot, the full
toolchain baked (copr-cli, rpmdevtools, vendor tooling), copr-cli
credentials mounted read-only from the host, and an ephemeral HOME so
the copr-cli session cache dies with each run (stale sessions never
401) — the
[ephemeral-tooling model](../../../project-setup/ephemeral-tooling/model/SKILL.md).

- mock needs real privilege (CAP_SYS_ADMIN for buildroot mounts): a
  dedicated `privileged: true` compose service, never the everyday
  tooling container — the model's escalation rule.
- A one-off SRPM parity check needs no repo tooling image at all
  (validated: crunch SRPM built in a plain fedora container, host
  untouched): copy the package dir plus `.copr/Makefile`, run the
  srpm target inside the distro container with `rpm-build` + `make`,
  HOME elsewhere. `_disable_source_fetch 0` then downloads URL
  sources in-container — the tarball lands in the package dir
  (sourcedir), so work on a copy or clean it after.

## Versioning rules

- Never bump Release/changelog for a build that never completed: a
  failed build never delivered the version.
- Never add Epoch to skip or downgrade a release; use an explicit
  override the automation respects (a marked commit message).

## Diagnosing failures

Builds have two stages, each with its own log under
`download.copr.fedorainfracloud.org/results/<owner>/<project>/`:
`srpm-builds/<id>/builder-live.log.gz` (a failure here never reaches
the chroots) and `<chroot>/<id>-<pkg>/builder-live.log.gz` (+ root,
build logs alongside). Gotchas:

- CDN cache trap: a plain curl can return a DIFFERENT build's log —
  send a cache-buster header and sanity-check the spec name in the
  output.
- Compile failures print BEFORE the mass of succeeding lines (an
  `exec: "g++" not found` near line 2500 of a log whose tail looks
  like a silent OOM): grep the whole log for `error:`-class patterns
  before concluding a kill.
- `tarfile.ReadError: not a gzip file` means Source0 fetched a forge
  error page, not a tarball — usually a tag/branch name collision; pin
  to `archive/refs/tags/v<ver>/…`.
- A noarch package failing every chroot with arch-dependent binaries
  means ELFs/wasm/platform dirs in the payload — strip them in
  `%install`.
