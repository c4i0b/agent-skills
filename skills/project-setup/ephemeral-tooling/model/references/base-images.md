# Base images by use case

Selection guide for the Containerfile base, validated by live tests
(9 test agents, Nov 2026). Sizes are unpacked and indicative — re-measure
before optimizing.

## Decision rules

1. A **tooling** base (shell + package manager to bake the toolchain) is a
   different question from a **runtime** base (ships an artifact).
   Distroless is runtime-only — no shell, no package manager.
2. Tag policy: **default to `latest`**. Pin a major only when
   reproducibility demands it — then verify it is the current major
   (`podman manifest inspect`) and keep the Freshness list below current.
   Chainguard free tier serves only `latest`/`latest-dev` (digest-pin when
   repeating). For exact toolchain pinning nothing beats nix
   (`-I nixpkgs=<rev>`): byte-identical store paths across fresh
   containers.
3. glibc vs musl decides more than size: manylinux wheels and prebuilt
   binaries assume glibc. Wolfi family = small AND glibc. Alpine
   per-language images each lack something different (see table); musl is
   fine only for static payloads or verified musllinux deps.
4. **Use the minimal image that covers the need** (the anti-pattern has a
   name: **archive-collecting** — starting big "to be safe"): start from
   the smallest
   base and install exactly what is missing (`apk`/`apt` at build time —
   layer cache makes rebuilds cheap). Balance check: if what you must
   install approaches the prebuilt image's delta, the minimal base stops
   paying — take the prebuilt (Rust: 1.08 GB composed vs 1.10 GB prebuilt
   → prebuilt wins; Python: 85 MB vs 667 MB → composed wins). Judge on
   final size, install complexity and who owns the package list.
5. Registry quirks: `quay.io/redhatubi` and `quay.io/almalinux` refuse
   anonymous pulls; Rocky 10 lives at `docker.io/rockylinux/rockylinux:10`
   (`library/rockylinux` is stale at 9.3); CentOS Stream tags are
   `stream10` not `centos-stream10`.

## Freshness

Policy: **use `latest`**; a pinned major must be the CURRENT one below —
if it is not listed or is outdated, use `latest` and update this list.
Current majors (Nov 2026): Debian stable = **trixie** (13) ·
Alpine = **3.24** · Node LTS = **26** · Python = **3.15** · Go = **1.27**
· Rust = **1.99** · ubi = **10** / distroless **debian13** (the generic
rows above float with these).

## Tooling bases — general

| Image | Size | Verdict |
|---|---:|---|
| `cgr.dev/chainguard/wolfi-base` (digest-pinned) | 19 MB | **recommended default**: glibc + apk; prebuilt glibc binaries and glibc-only wheels run |
| `debian:stable-slim` | 78 MB | **recommended** when Debian parity matters; `build-essential` in ~10 s |
| `nixos/nix:latest` | 593 MB→~871 MB | **recommended when exact pinning matters**; the GC line is mandatory (2.3 GB→871 MB); sandbox works rootless with defaults. `:minimal` and `ghcr.io/determinatesystems/nix` do not exist |
| `registry.fedoraproject.org/fedora:rawhide` | 398 MB | **recommended** when the target IS Fedora/rpm (python3 no longer in base) |
| `registry.access.redhat.com/ubi` (current major) | 219 MB | acceptable: dnf, enterprise parity |
| `alpine:latest` + apk | 9 MB+ | acceptable only for static/pure payloads: musl |
| distroless family, `ubi-micro`, `glibc-dynamic` | 3–24 MB | **avoid** for tooling: no shell and/or no package manager |

## Tooling bases — per language

| Language | Alpine route | wolfi-base + apk | Chainguard `-dev` | Pick |
|---|---|---|---|---|
| Python | `python:3-alpine` 56 MB: six/uvloop ok, **opencv fails, no compiler** | **85 MB**: six/pillow/cryptography/opencv/uvloop all pass (`python-3`+`py3-pip`) | 667 MB: all pass | **wolfi+apk** (smallest with the whole manylinux ecosystem) |
| Node | `node:lts-alpine` 171 MB: sharp ok (musl prebuilds), **node-gyp fails (no python)** | **166 MB** (`nodejs`+`npm`): sharp ok; node-gyp needs `apk add python3 gcc g++ make`; npm gates install scripts (`npm install-scripts approve`) | 755 MB: all pass | **wolfi+apk** (smaller than alpine, glibc prebuilds) |
| Go | `golang:1-alpine` 266 MB: **static builds ideal, CGO fails (no gcc)**; prebuilt glibc dies | 240 MB (go+git) | 754 MB: CGO ok | **wolfi+apk**; alpine fine for pure static Go |
| Rust | `rust:1-alpine` 1.04 GB (musl native) | 1.08 GB: needs explicit `build-base`, no musl-dev; rustup-musl route fights apk cargo | 1.1 GB: cargo ok | **`-dev`**; or `rust:1-slim` + `rustup target add x86_64-unknown-linux-musl` for static musl binaries (runs anywhere) |

Chainguard `-dev` images ship tool ENTRYPOINTs (cargo eats compose
commands): set `entrypoint: []` on the compose service, or
`--entrypoint /bin/sh` for direct runs. Default nonroot uid 65532 also
bites bind mounts (our `user: "0:0"` neutralizes it).

## Runtime bases

| Artifact | Image | Size | Verdict |
|---|---|---:|---|
| Static Go/Rust | `gcr.io/distroless/static-debian13` | 3 MB | **recommended** |
| CGO Go / TLS | `gcr.io/distroless/base-debian13` | 22 MB | **recommended** (CA certs verified) |
| C++ | `gcr.io/distroless/cc-debian13` | 25 MB | **recommended** |
| Static + tiny + shell | `alpine:latest` | 9 MB | recommended |
| Self-contained Python/JS | `distroless/python3-debian13` (55 MB) / `nodejs-debian13` (149 MB) | | acceptable: no pip/npm, copy the artifact in |
| Enterprise | `registry.access.redhat.com/ubi/ubi-micro` (current major) | 24 MB | acceptable |

Clean handoff: build in `debian:stable-slim`, run in the distroless of
the same Debian major (same glibc). Debug shell-less runtimes via
`:debug` or `kubectl debug`.

## EL compat test targets (EPEL/RHEL family)

Not tooling bases: containers to test artifacts against the EL toolchain
generation and simulate the end user:

```sh
dnf -y install dnf-plugins-core && dnf copr enable <owner>/<project> \
  && dnf -y install <pkg>    # + dnf -y install epel-release for EPEL deps
```

| Image | Verdict |
|---|---|
| `quay.io/centos/centos:stream10` | **recommended primary** EPEL10 target: rpm 4.19.1/dnf 4.20/glibc 2.39; CRB off by default |
| `docker.io/library/almalinux:10` | **recommended secondary**: CRB enabled by default; `10-minimal` ends at the same 136 packages after bootstrap — skip it |
| `docker.io/rockylinux/rockylinux:10` | acceptable (equivalent to alma) |
| EL9 family | acceptable but pointless without epel-9 consumers; `library/rockylinux:9` upstream-frozen — avoid |

Nuance: rpm < 4.20 does NOT hard-fail on macros in comments — it expands
them silently (including `%(shell)`, which executes). The danger is silent
expansion, not a parse error.

## Windows targets (from Linux)

Windows containers cannot run on a Linux kernel. From Linux, cross-compile
and smoke-test:

| Route | Cost | Verdict |
|---|---|---|
| `debian:stable-slim` + `gcc-mingw-w64-x86-64` | 639 MB, 14.5 s cold | **recommended** cross-compile toolchain |
| Go `GOOS=windows` | trivial; CGO via mingw CC works | recommended |
| Rust windows-gnu | rustup alone cannot link (missing import libs); needs mingw + `CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER`; xwin/lld-link route for MSVC | acceptable |
| zig cc tarball (`zig cc -target x86_64-windows-gnu`) | 50 MB toolchain | acceptable bonus |
| Wine smoke (`wine-core wine-common` on fedora) | 3.03 GB | acceptable: runs built .exe headless; warm the prefix at build time (10–40 s first run), `WINEDEBUG=-all`, writable `$HOME` |

Escape hatches for real Windows containers: Windows VM, GitHub Actions
Windows runners, AKS Windows nodes.

## One-shot / throwaway CI tools

| Image | Verdict |
|---|---|
| `nixery.dev/<packages>` | **recommended for one-shots**; **avoid as a base**: channel tags ignored (unstable moves), amd64-only; pin by digest when repeating; self-host with `NIXERY_PKGS_REPO` pinned is the only safe dependence |
| `cgr.dev/chainguard/bash` / `busybox` / `git` | acceptable step bases |

## Debunked along the way (do not re-litigate)

- wolfi is musl — **false**: glibc by design.
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
