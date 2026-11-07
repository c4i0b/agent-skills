---
name: testing-structure
description: Structure a repo's test suite. Test pyramid with coverage without overlap, cheapest-test-first, refactoring code to enable cheap tests (modularity as a consequence), offline by default with live/API layers opt-in. Includes the recorded-fixtures catalog/recorder technique for repos consuming external APIs. Use when creating or reworking a test suite.
---

# Testing structure

Applicability: any repo with tests. The recorded-fixtures part applies only
when the repo consumes external APIs/services — skip it for self-contained
tooling (a spec repo needs none of this).

## Core rules

1. **Pyramid, ~70/20/10 unit/contract/integration, e2e ≈ 0 in CI** — a
   direction, not a quota: engineer the ratios only once the suite has
   mass. Cheap
   tests at the bottom, expensive at the top. Each layer has ONE distinct
   job: unit = pure logic, contract = what goes over the wire (goldens),
   integration = real code against fake inputs, live = real endpoints.
2. **Coverage without overlap.** A behavior is pinned at the CHEAPEST layer
   that can see it, and nowhere else. Testing the same behavior at two
   layers is a maintenance tax, not extra safety — every change pays it
   twice.
3. **Cheapest-test-first is an obligation on the code, not the suite.** If
   a behavior can only be verified at an expensive layer (network, DB,
   live API), that is a code smell: refactor FIRST — introduce seams
   (factories, injection, ports) so the behavior drops to a cheap layer.
   Not optional polish. Modularity is the structural consequence of this
   rule; code that resists cheap testing resists modularity.
4. **Offline by default.** The full suite runs without network, fast, in
   CI. Real API/endpoint is a rare opt-in layer: dedicated marker (e.g.
   `@pytest.mark.live`), deselected by default via config, one smoke per
   endpoint, never in CI.
5. **Determinism at outputs, realism at inputs.** Goldens are regenerated
   deliberately (frozen by e.g. `as_of`) — a golden that changes on every
   run pins nothing. Where realism matters (upstream library shapes), feed
   recorded data, never hand-crafted "realistic" payloads: a crafted
   payload encodes what we THINK upstream returns, which is exactly what
   we are wrong about.
6. **Repo consumes external APIs?** Read
   [catalog-and-recorder.md](references/catalog-and-recorder.md): record
   once into a versioned fixture library, derive every layer from it,
   refresh on dependency bumps (not the calendar).

## Validated example

`/home/caio/Projects/finance/docs/yfinance-service/testing-strategy.md` and
`fixtures.md` — the full pyramid, markers config, durability classes and
recorder in production use, including the bugs the realism rule caught
(NaN tails, non-dict metadata, calendar divergence between exchanges).
