---
name: testing-structure
description: Structure a repo's test suite. Test pyramid with coverage without overlap, cheapest-test-first, refactoring code to enable cheap tests (modularity as a consequence), offline by default with live/API layers opt-in. Oracle quality (independent-path expected values, value-attributed assertions for keyed series). Includes the recorded-fixtures catalog/recorder technique for repos consuming external APIs. Use when creating or reworking a test suite.
---

# Testing structure

Applicability: any repo with tests. The recorded-fixtures part applies only
when the repo consumes external APIs/services — skip it for self-contained
tooling (a spec repo needs none of this).

## Core rules

0. **Test-first, always** — a development-policy rule, restated here
   because it decides when tests exist: written or adjusted before or with
   the implementation (see
   [development-policy](../development-policy/SKILL.md)).
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
   - **capability-probe skip** (anti-pattern): a test needing an external
     binary that silently self-degrades when it is absent (`if
     !tool_exists() { return; }`, or a stub fallback inside the code
     under test). Red: a suite of 287 green while its validation path
     was never exercised. Every such test guarded on the missing binary
     except one, and that one caught the bug. A missing binary at test
     time means exactly one of two things: Containerfile bug (bake it)
     or live dependency (explicit marker). Never probe-and-return.
5. **Determinism at outputs, realism at inputs.** Goldens are regenerated
   deliberately (frozen by e.g. `as_of`) — a golden that changes on every
   run pins nothing. Where realism matters (upstream library shapes), feed
   recorded data, never hand-crafted "realistic" payloads: a crafted
   payload encodes what we THINK upstream returns, which is exactly what
   we are wrong about. Realism extends to derived data: a crafted input
   sequence (e.g. returns fed to a math kernel) is a crafted payload.
   - **same-brain oracle** (anti-pattern): an expected value hand-computed
     by the implementation's author follows the same mental model as the
     code and certifies its bugs — test-first becomes mutual confirmation,
     not verification. For numeric kernels derive the oracle through an
     independent path: apply the inverse operation (forward-chain from
     returns to test a reverse-chain from prices), or feed recorded real
     data and compare by key. Red: a quant kernel bridging synthetic
     bars with the wrong proxy return; the hand-computed literal used the
     same wrong date convention as the code, its comment narrating the bug
     as intended behavior.
6. **Assert value-attributed invariants, not only shift-invariant ones.**
   Ordering, counts, telescoping products and relative levels are
   **shift-invariant**: they still pass when values are relabeled onto the
   wrong keys (dates, ids). Every transform that produces or reshapes a
   keyed series gets at least one assertion binding an output value to its
   key, with explicit attention at seams (synthetic-to-real boundaries,
   composition joins). If the series has a downstream consumer, one test
   consumes it as the consumer does (compare by key against the series'
   own inputs) — that is a distinct behavior from the transform's math,
   not overlap under rule 2. Red: an entire suite green under a
   one-day relabeling of returns; the covariance consumer silently
   misaligned by one trading day against the rest of the universe.
7. **Repo consumes external APIs?** Read
   [catalog-and-recorder.md](references/catalog-and-recorder.md): record
   once into a versioned fixture library, derive every layer from it,
   refresh on dependency bumps (not the calendar).

## Validated example

`finance/docs/yfinance-service/testing-strategy.md` and
`fixtures.md` (private repo) — the full pyramid, markers config, durability classes and
recorder in production use, including the bugs the realism rule caught
(NaN tails, non-dict metadata, calendar divergence between exchanges),
and an oracle-contamination bug (off-by-one synthetic-history bridge
certified by a same-brain oracle, every assertion shift-invariant —
the red behind rules 5 and 6).
