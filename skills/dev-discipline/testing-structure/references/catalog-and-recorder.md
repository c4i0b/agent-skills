# Recorded fixtures: catalog and recorder

The technique behind offline self-sufficiency for repos that consume
external APIs: record real upstream output ONCE into a versioned fixture
library, then derive every test layer from it. Live e2e becomes a rare
smoke, never a CI dependency. Core principle: **fixtures are recorded,
tests are built** — hand-crafted payloads only for scenarios that cannot be
captured (errors, retro-corrections, synthetic math).

## Durability classes (the table that makes record-once viable)

Class every fixture by whether it rots, and pin assertions accordingly:

| Fixture class | Rots? | Policy |
|---|---|---|
| Historical/raw records (past events) | No | Record once; assert exact values |
| Event logs, immutable metadata | Almost never | Record once; assert exact |
| Derived/anchored values (e.g. factors anchored at latest) | **Yes** (restated) | Never assert from recordings — crafted pairs |
| Snapshots of moving values (prices, quotes) | **Yes** | Shape-only: keys/types/ranges, never values |

## Catalog as the single source of truth

`tests/fixtures/catalog.yaml`: one entry per recording; the recorder
iterates it. Adding a fixture = adding an entry + running the recorder
once. Cover the input space deliberately (asset classes, error shapes,
calendars) — each entry says WHY it exists.

## Recorder pattern

- `scripts/record_fixtures.py` reads the catalog, hits the real upstream,
  writes raw (pre-serialization) structures to `tests/fixtures/library/`.
- Runs in the dev container with network, on demand — never in CI.
- A bump workflow (`just snapshot-fixtures` / `diff-fixtures`) records and
  shape-diffs against the committed library.

## Refresh on dependency bumps, not the calendar

Upstream minor bumps are not cosmetic (parsers and shapes ship in minors).
On every minor/major bump of the upstream client: re-record, then
**shape-diff** against committed fixtures — the diff is the review
artifact; column sets, index dtypes, metadata keys and error shapes
changing are upstream-shape changes the code must absorb BEFORE the
upgrade merges.

## Seam choice

Cut at a stable seam (a factory/port the code already owns), not
necessarily at the HTTP layer. HTTP record/replay (vcrpy et al.) breaks
when the client impersonates TLS or rejects cached sessions — the seam
above the client is stable and cheap. Prefer seams that exist because of
rule 3 (refactor for testability) over seams retrofitted by the recorder.

## Validated example

`finance/docs/yfinance-service/fixtures.md` (private repo) — catalog,
durability table, refresh trigger and the failure classes recorded realism
guards against.
