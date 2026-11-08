# Variant: a CLI tool

For a command-line tool shipped to users (package manager, crates.io,
distro package). Validated example:
[`topmatic/README.md`](https://github.com/c4i0b/topmatic).

Skeleton, top to bottom:

- Title + one line saying what the tool does, in the user's words
- Badges (version, license) only when they carry live information
- A screenshot or demo line when the tool is interactive
- Why: bullets on the problem solved and the main trade-offs
- Requirements: hard host constraints (OS, runtime version, scheduler)
- Install: package manager first, from source second, each version
  note tied to the constraint that motivated it
- Usage: first run plus the 2-3 commands covering daily use
- Development: per the universal skeleton, host prerequisites explicit
  (what the host provides, what runs in the tooling container)

Differences from the other variants:

- The first screen sells the tool, not the repo: users decide to
  install before they decide to read
- Requirements beat features: a tool needing a specific host scheduler
  or runtime says so before install
- No architecture section unless the tool is a daemon
