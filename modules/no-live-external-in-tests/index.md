---
name: no-live-external-in-tests
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - 04-testing-verification.md#live-db-never-mutated-in-tests--tmp-duckdb-fixtures
  - common-guardrails.md#never-without-explicit-human-approval
applies_when:
  - project's tests could otherwise reach a real external system (live DB, third-party API, production endpoint)
version: 1
---

# Tests never touch a live external system

## Rule

Tests never call a live external system — not a third-party API, not
the production database, not a real OAuth/publish endpoint, not a
webhook receiver in the wild. They run against isolated fixtures
(a per-test tmp DuckDB, a fake/recorded adapter, a local stub server)
so the suite is deterministic, offline-runnable, and incapable of
mutating real state or spending real quota. A test that needs to
exercise the real service is a *manual* check, run deliberately and
labelled as such — never part of the default `pytest` run.

## Why

The repo already enforces the database corner of this: tests use an
isolated fixture (per-test tmp DuckDB via `conftest.py`), never the
live DB
(`04-testing-verification` §Live DB never mutated in tests;
`common-guardrails` §Never).
This module generalizes that proven rule from "the DB" to "any
external system," because the failure shape is identical: a test that
reaches a live dependency is non-deterministic (it fails when the
network blips), destructive (it can mutate real data), and expensive
(it burns API quota or rate limit, sometimes irreversibly).

The `content_manager` project is the forcing case for the API half.
Its tests could, if careless, publish a real video to YouTube,
consume the `≤1 published post per platform per day` budget, or burn
a TikTok upload — side effects no test should ever have. The
[[external-api-adapter-boundary]] is what makes the rule cheap to
follow: because every platform sits behind an adapter interface,
tests inject a fake adapter and never construct the real SDK client
at all.

## How to apply

- **Databases:** per-test tmp DuckDB (or in-memory) via a fixture;
  never point a test at the deploy's `.duckdb` file or a shared dev
  DB.
- **External APIs:** inject a fake adapter at the
  [[external-api-adapter-boundary]] seam, or record/replay real
  responses (VCR-style cassettes) checked into the repo with secrets
  scrubbed. The real SDK client is never constructed in a default
  test run.
- **Outbound side effects** (publish, send, charge, push): the fake
  records that the call *would* have happened and asserts the
  arguments — it does not perform it.
- **Genuinely need the live service?** Mark it: a `@pytest.mark.live`
  (deselected by default) or a separate `scripts/check_live.sh` run
  by hand. Document the credential and quota cost in its docstring.
- **Smoke scripts** ([[smoke-before-commit]]) test wiring against
  fixtures/stubs too — a smoke that hits prod isn't a smoke, it's a
  deploy probe.

## Anti-patterns

- A test that constructs the real API client because "it's just a
  read." Reads still need a live token, count against rate limits,
  and fail offline.
- Pointing the test suite at a shared "dev" database that other work
  also writes — tests stop being isolated and start being flaky.
- A "test" that actually publishes to a sandbox/real account and
  leaves artifacts behind to clean up manually.
- Hitting a third-party API in CI and treating intermittent 5xxs as
  flaky-test noise to retry, rather than as a dependency that
  shouldn't be in the suite.
- Recording a cassette with a live secret baked into the saved
  request/response. Scrub it before committing (ties back to
  [[secrets-no-plaintext]]).

## Related

- [[external-api-adapter-boundary]] — the seam tests substitute at;
  the adapter is what makes "no live API in tests" a one-line fake
  injection instead of deep mocking.
- [[smoke-before-commit]] — the verification gate this protects: a
  smoke that stays offline is one you can run on every commit.
- [[secrets-no-plaintext]] — tests that never hit the live service
  never need the real secret; recorded fixtures are scrubbed.
- `no-live-db-in-tests` (sketched in
  `03-instruction-modules` §5)
  — the database-only sibling; this module supersedes its scope by
  covering any external system, so the sketch row folds in here.
