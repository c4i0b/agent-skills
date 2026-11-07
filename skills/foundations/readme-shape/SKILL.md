---
name: readme-shape
description: Write or rework a repo README for humans. Universal shape (intro, usage/install, how it works, development with host prerequisites) plus per-repo-kind variants. Includes the style rules (English, no em dashes, no semicolons, short paragraphs). Use when creating a README or reorganizing an existing one.
---

# README shape

The README is for **humans first**; agents have AGENTS.md and docs/. A
reader must answer in one screen: what is this, how do I use it, how do I
work on it.

## Universal skeleton

1. Intro (2-3 short paragraphs): what the repo is and its current state.

Good: "Market data and portfolio analytics stack, run with podman compose.
Phase 1 is live: yfinance-service serves deterministic daily EOD history."
Bad: "This project is a revolutionary solution that leverages cutting-edge
technology to empower users in the financial domain." (No information, no
state, no shape.)

2. Usage / Install: the shortest path to something working.
3. How it works: 3-5 bullets of architecture or flow, linking docs/ for
   detail instead of inlining it.
4. Development: explicit host prerequisites (what the host must have and
   what runs in containers/tools), a handful of aligned commands, links to
   docs/.

## Style rules (strict)

Follow [writing-style](../writing-style/SKILL.md) — English only, no em
dashes, no semicolons, short paragraphs and bullets. README-specific:
machine-generated regions (delimited by markers) are never hand-edited and
must not bury the first screen.

## Variants

Pick by repo kind, or ask when ambiguous:

- [service-app.md](references/service-app.md) — an app or service stack
- [package-monorepo.md](references/package-monorepo.md) — a monorepo
  shipping packages for a package manager

## Validated examples

- `fedora-packages/README.md` (package monorepo)
- `finance/README.md` (service app)
