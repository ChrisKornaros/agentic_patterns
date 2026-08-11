---
name: smoke-before-commit
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - 04-testing-verification.md#the-smoke-script--the-highest-leverage-100-lines
  - playbook.md#5-testing--verification-patterns
applies_when:
  - repo has a runnable verifier (smoke script, test suite, or build/compile step)
version: 1
---

# Smoke before commit

## Rule

Run the project's cheapest verifier and see it **green** before
committing the work-up and opening the PR. For most repos that's
`scripts/smoke.sh` (compile every source file, boot the server,
`curl` the key routes); for others it's `pytest -q`, `cargo check`,
`go vet`, or whatever the host's `CLAUDE.md` names as the verify
step. The commit happens *after* the green signal, not before — a
failed smoke run is a reason to fix, not a reason to commit "and
sort it out in CI."

## Why

A 60–100 line smoke script catches ~80% of the regressions a real
test suite would for ~5% of the cost: syntax errors (100%), import
errors (100%), route-registration breakage (100%), template render
errors (~80%)
(playbook §The smoke script).
Running it *before* the commit means a broken tree never reaches a
PR, so the human-merge gate reviews working code, not a guess. The
product-use-tracker case study
(§5)
made the smoke pass the local stand-in for CI — the verify loop
named explicitly in `CLAUDE.md` so the agent reaches for it instead
of hand-rolling curl loops.

## How to apply

- **Run the verifier the host names**, in this order when several
  exist: tests (`pytest -q tests/`) → compile/boot smoke → manual
  acceptance check. The smoke script should wrap the test step
  *before* the server-boot step so an isolated-DB fixture never
  races a live writer.
- **Treat a non-green result as blocking.** Fix the failure, re-run,
  *then* proceed to the [[auto-commit-on-branch-done]] sequence.
- **Pre-flight any side-channel the smoke owns** — a fixed port, a
  file lock, a daemon thread — and fail with a *named* error, not a
  downstream "connection refused" that looks like a route
  regression.
- **Quote the result in the PR's `Verified:` footer** so
  six-months-later-you knows the green was real (`Verified: smoke
  green — 16 pytest + boot + 4 routes 200`).

## Anti-patterns

- Committing first and "letting CI catch it" — CI is the second
  net, not the first, and the broken commit is already in the PR
  history.
- Skipping smoke because "the change is trivial" — trivial changes
  break imports and route registration as readily as large ones.
- Running smoke but committing despite a red result, planning to
  "fix it in the next commit."
- A smoke script that boots a server but never pre-flights its port,
  so a stray prior run surfaces as an opaque curl timeout.

## Related

- [[auto-commit-on-branch-done]]
- [[git-flow-session-end]]
- [[no-live-db-in-tests]]
