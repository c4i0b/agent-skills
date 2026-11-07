# Base images by use case

Selection guide for the Containerfile base, validated by live tests
(Nov 2026, 9 test agents; sizes unpacked and indicative — re-measure
before optimizing). Evidence reports: `/tmp/opencode/img-test/` (volatile;
the findings below are the durable part).

## Decision rules

0. Freshness check (quick, before using): verify the image/tag still exists
   and is the current major (e.g. `podman manifest inspect`, release notes).
   Use the latest stable. If a newer base than this doc's tables exists,
   prefer it and send a one-line update to this file.
1. Two different questions: a **tooling** base (shell + package manager to
   bake the toolchain) vs a **runtime** base (ships an artifact). The
   distroless family is runtime-only — no shell, no package manager.
2. Pin for reproducibility: official images by stable/major tag, never a
   moving `latest` in FROM. Chainguard free tier serves ONLY
   `latest`/`latest-dev` — pin by **digest** or builds drift. For exact
   toolchain pinning nothing beat nix (`-I nixpkgs=<rev>`): byte-identical
   store paths across fresh containers.
3. glibc vs musl decides more than size: manylinux wheels and prebuilt
   binaries assume glibc. Wolfi family = small AND glibc. Alpine per
   language images each lack something different (see table) — musl is
   fine only for static payloads or verified musllinux deps.
4. Prefer slim base + install-at-build over fat images: layer cache makes
   rebuilds cheap, and you get exactly the toolchain you need.
5. Registry quirks: `quay.io/redhatubi` and `quay.io/almalinux` refuse
   anonymous pulls; Rocky 10 lives at `docker.io/rockylinux/rockylinux:10`
   (`library/rockylinux` is stale at 9.3); CentOS Stream tags are `stream10`
   not `centos-stream10`.

## Freshness (checked Nov 2026 — prefer these, tables below may lag)

Current majors: Debian stable = **trixie** (13, glibc 2.41; bookworm =
oldstable) · Alpine = **3.24** · Node LTS = **26** (`node:26-alpine` exists)
· Python = **3.15** · Go = **1.27** · Rust = **1.99** · `ubi10` and
distroless **debian13** tags are available alongside the -9/-debian12 rows
below. Validated numbers reference the tags we tested — when using a newer
major, re-run the quick sufficiency checks and update this file.

## Tooling bases — general

| Image | Size | Verdict |
|---|---:|---|
| `cgr.dev/chainguard/wolfi-base` (digest-pinned) | 19 MB | **recommended default**: glibc 2.44 + apk; prebuilt glibc binaries and glibc-only wheels run |
| `debian:bookworm-slim` | 78 MB | **recommended** when Debian parity or glibc 2.36 matters; `build-essential` in ~10 s |
| `nixos/nix:latest` | 593 MB→~871 MB | **recommended when exact pinning matters**: `-I nixpkgs=<rev>` gives byte-identical toolchains across fresh containers; GC line is mandatory (2.3 GB→871 MB); sandbox works rootless with defaults. Note: `:minimal` and `ghcr.io/determinatesystems/nix` do NOT exist |
| `registry.fedoraproject.org/fedora:rawhide` | 398 MB | **recommended** when the target IS Fedora/rpm (python3 no longer in base) |
| `registry.access.redhat.com/ubi9` | 219 MB | acceptable: dnf, enterprise parity |
| `alpine:3.22` + apk | 9 MB+ | acceptable only for static/pure payloads: musl |
| distroless family, `ubi9-micro`, `glibc-dynamic` | 3–24 MB | **avoid** for tooling: no shell and/or no package manager |

## Tooling bases — per language (all tested)

| Language | Alpine route | wolfi-base + apk | Chainguard `-dev` | Pick |
|---|---|---|---|---|
| Python | `python:3.15-alpine` 56 MB: six/uvloop ok, **opencv fails, no compiler** | **85 MB**: six/pillow/cryptography/opencv/uvloop ALL pass (`python-3.13`+`py3.13-pip`) | 667 MB: all pass | **wolfi+apk** (smallest with the whole manylinux ecosystem) |
| Node | `node:22-alpine` 171 MB: sharp ok (musl prebuilds!), **node-gyp fails (no python)** | **166 MB** (`nodejs-24`+`npm`): sharp ok, node-gyp ok after `apk add python3 gcc g++ make`; npm 12 gates install scripts (`npm install-scripts approve`) | 755 MB: all pass | **wolfi+apk** (smaller than alpine, glibc prebuilds) |
| Go | `golang:1.27-alpine` 266 MB: **static builds ideal, CGO fails (no gcc since 1.27)**; prebuilt glibc dies | 240 MB (go+git, go 1.27/gcc 16) | 754 MB: CGO ok | **wolfi+apk**; alpine fine for pure static Go |
| Rust | `rust:1-alpine` 1.04 GB (musl native) | 1.08 GB: needs explicit `build-base`, no musl-dev; rustup-musl route fights apk cargo | 1.1 GB: cargo ok | **`-dev`**; or debian `rust:slim-bookworm` + `rustup target add x86_64-unknown-linux-musl` for static musl binaries (runs anywhere) |

## Runtime bases

| Artifact | Image | Size | Verdict |
|---|---|---:|---|
| Static Go/Rust | `gcr.io/distroless/static-debian12` | 3 MB | **recommended** |
| CGO Go / TLS | `gcr.io/distroless/base-debian12` | 22 MB | **recommended** (CA certs verified live) |
| C++ | `gcr.io/distroless/cc-debian12` | 25 MB | **recommended** |
| Static + tiny + shell | `alpine:3.22` | 9 MB | recommended |
| Self-contained Python/JS | `distroless/python3-debian12` (55 MB) / `nodejs22-debian12` (149 MB) | | acceptable: no pip/npm, copy the artifact in |
| Enterprise | `registry.access.redhat.com/ubi9/ubi-micro` | 24 MB | acceptable |

Clean handoff: build in `debian:bookworm-slim`, run in distroless-debian12
(same glibc 2.36). Debug shell-less runtimes via `:debug` or
`kubectl debug`.

## EL compat test targets (EPEL/RHEL family)

Not tooling bases: containers to test artifacts against the EL toolchain
generation and simulate the end user.

| Image | Verdict |
|---|---|
| `quay.io/centos/centos:stream10` | **recommended primary** EPEL10 target: rpm 4.19.1/dnf 4.20/glibc 2.39; CRB off by default |
| `docker.io/library/almalinux:10` | **recommended secondary**: CRB enabled by default; `10-minimal` ends at the same 136 packages after bootstrap — skip it |
| `docker.io/rockylinux/rockylinux:10` | acceptable (equivalent to alma) |
| EL9 family | acceptable but pointless without epel-9 consumers; `library/rockylinux:9` upstream-frozen — avoid |

End-user simulation (verified): `dnf -y install dnf-plugins-core && dnf copr
enable <owner>/<project> && dnf -y install <pkg>`; packages with EPEL deps
also need `dnf -y install epel-release`. Nuance: rpm < 4.20 does NOT
hard-fail on macros in comments — it **expands them silently** (including
`%(shell)`, which executes); the danger is silent expansion, not a parse
error.

## Windows targets (from Linux)

Windows containers cannot run on a Linux kernel (verified: PE binaries and
no /etc/passwd). From Linux you can cross-compile and smoke-test:

| Route | Cost | Verdict |
|---|---|---|
| `debian:bookworm-slim` + `gcc-mingw-w64-x86-64` | 639 MB, 14.5 s cold | **recommended** cross-compile toolchain |
| Go `GOOS=windows` | trivial (2 s); CGO via mingw CC works | recommended |
| Rust windows-gnu | rustup alone cannot link (missing import libs); needs mingw + `CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER`; xwin/lld-link route for MSVC | acceptable |
| zig cc tarball (`zig cc -target x86_64-windows-gnu`) | 50 MB toolchain | acceptable bonus |
| Wine smoke (`wine-core wine-common` on fedora) | 3.03 GB (full wine 5.57 GB) | acceptable: runs built .exe headless; warm the prefix at build time (10–40 s first run), `WINEDEBUG=-all`, writable `$HOME` |

Escape hatches for real Windows containers: Windows VM, GitHub Actions
Windows runners, AKS Windows nodes.

## One-shot / throwaway CI tools

| Image | Verdict |
|---|---|
| `nixery.dev/<packages>` | **recommended for one-shots**; **avoid as a base**: channel tags ignored (unstable moves), amd64-only, FAQ says not for production; pin by digest when repeating; self-host with `NIXERY_PKGS_REPO` pinned is the only safe dependence |
| `cgr.dev/chainguard/bash` / `busybox` / `git` | acceptable step bases |

## Debunked along the way (do not re-litigate)

- wolfi is musl — **false**: glibc 2.44 by design.
- musllinux wheels never install on glibc — **false** (uvloop installed a
  manylinux cp313 wheel on wolfi; per-wheel reality).
- `golang:*-alpine` ships gcc — **no longer** (1.27 dropped it; CGO needs
  `apk add gcc musl-dev`).
- `node:*-alpine` cannot run sharp — **false**: sharp ships musl prebuilds;
  the real gap is node-gyp source deps (no python in the image).
- `rust:1-alpine` does not exist — **it does** (and is still not the best
  route; see table).
- rpm < 4.20 breaks the spec parse on macros in comments — **no**: it
  silently expands (and executes `%(shell)`).
