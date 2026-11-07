# Base images by use case

Selection guide for the Containerfile base, validated by live tests
(Nov 2026; sizes are unpacked and indicative — re-measure before
optimizing). Evidence reports: `/tmp/opencode/img-test/` (volatile; the
findings below are the durable part).

## Decision rules

1. Two different questions: a **tooling** base (needs shell + package
   manager to bake the toolchain) vs a **runtime** base (ships an
   artifact). Never confuse them: distroless-family images have no shell
   and no package manager — they are runtime-only.
2. Pin for reproducibility: official images by stable/major tag, never a
   moving `latest` in FROM. Chainguard free tier serves ONLY
   `latest`/`latest-dev` — pin by **digest** or builds drift.
3. glibc vs musl matters more than size: prebuilt binaries, manylinux
   wheels and CGO assume glibc. The Wolfi family is glibc despite
   alpine-like size — that combination (small + glibc) is the sweet spot.
4. Prefer slim base + install-at-build over fat images: the model bakes
   the whole toolchain anyway, and layer cache makes rebuilds cheap.
5. Registries: `quay.io/redhatubi/*` refuses anonymous pulls
   (`unauthorized`) — use `registry.access.redhat.com/ubi9/*`.

## Tooling bases

| Image | Size | Verdict |
|---|---:|---|
| `cgr.dev/chainguard/wolfi-base:latest` (digest-pinned) | 19 MB | **recommended default**: glibc 2.44, apk; prebuilt glibc binaries and glibc-only wheels run; `apk add` the exact toolchain |
| `debian:bookworm-slim` | 78 MB | **recommended** when Debian/apt parity or matching glibc 2.36 matters; `build-essential` installs in ~10 s |
| `registry.fedoraproject.org/fedora:rawhide` | 398 MB | **recommended** when the target IS Fedora/rpm (validated in our repos); note python3 no longer in base |
| `registry.access.redhat.com/ubi9` | 219 MB | acceptable: dnf, enterprise parity |
| `docker.io/library/alpine:3.22` | 9 MB | acceptable only when everything is static: musl breaks prebuilt glibc binaries (Node dies even with gcompat) and glibc-only wheels (opencv) |
| `ghcr.io/astral-sh/uv:python3.12-bookworm` | 1.1 GB | acceptable for python-heavy tooling (uv+pip+gcc baked); prefer composing from wolfi/debian when image size matters |
| Chainguard `-dev` per-language (`python/go/node/rust:latest-dev`) | 0.7–1.1 GB | acceptable: everything works (manylinux, CGO, node-gyp, cargo) but latest-only free tier (digest-pin), tool entrypoints (`--entrypoint /bin/sh` for scripts) and default nonroot uid 65532 bite bind mounts |
| distroless family, `ubi9-micro`, `glibc-dynamic` | 3–24 MB | **avoid**: no shell and/or no package manager — cannot bake a toolchain |

## Runtime bases

| Artifact | Image | Size | Verdict |
|---|---|---:|---|
| Static Go/Rust (CGO off) | `gcr.io/distroless/static-debian12` | 3 MB | **recommended** |
| CGO Go / TLS-capable | `gcr.io/distroless/base-debian12` | 22 MB | **recommended** (CA certs verified with a live HTTPS fetch) |
| C++ binaries | `gcr.io/distroless/cc-debian12` | 25 MB | **recommended** (libstdc++ verified) |
| Static binaries, tiny + shell | `alpine:3.22` | 9 MB | recommended (runtime musl is fine for static payloads) |
| Python copy-in venv / prebundled JS | `distroless/python3-debian12` (55 MB) / `nodejs22-debian12` (149 MB) | | acceptable: no pip/npm — artifact must be self-contained |
| Enterprise parity | `registry.access.redhat.com/ubi9/ubi-micro` | 24 MB | acceptable (bash but zero package manager) |

Clean handoff trick: debian12-family images share glibc 2.36 — build in
`debian:bookworm-slim`, run in distroless-debian12, no compat surprises.
Debug story for shell-less runtimes: `:debug` variants (busybox) or
`kubectl debug`.

## One-shot / throwaway CI tools

| Image | Verdict |
|---|---|
| `nixery.dev/<packages>` (on-demand, e.g. `nixery.dev/shell/go`) | **recommended for one-shots**; **avoid as a base**: channel tags are ignored (unstable moves underneath), amd64-only, FAQ says not for production; pin by digest when repeating; self-hosting (`NIXERY_PKGS_REPO` pinned) is the only safe dependence |
| `cgr.dev/chainguard/bash` / `busybox` / `git` | acceptable step bases |
