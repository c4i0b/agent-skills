# README: service app

For a repo that runs an app or service stack.

- Intro: what the service(s) do and the current phase; name the single
  entrypoint service if there is one.
- Usage: start the stack (`podman compose up --build -d` or equivalent),
  one `curl`/health check, then where state lives (named volumes, never the
  repo) and where the wire spec is documented.
- How it works: one service per directory, who owns external access (e.g.
  the single gateway to the upstream API), dev/runtime parity, where
  decisions are recorded.
- Development: host prerequisites first (e.g. `just` and `podman`, optional
  tools), then the gate command, one-service test, lifecycle and smoke
  recipes. Link the dev-workflow doc, the service README and the docs index.

Validated example: `/home/caio/Projects/finance/README.md`.
