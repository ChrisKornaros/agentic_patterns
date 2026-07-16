---
name: verifiable-goal-before-code
type: workflow
scope: repo
lifecycle: experimental
dependencies: []
applies_when:
  - the task produces code whose behavior can be exercised by running something (a test, a command, an observable output)
version: 1
---

# Verifiable goal before code

## Rule

Before implementing, restate the task as a goal whose completion can
be **verified by running something** — a test, a command, an
observable behavior — not by rereading the code and judging it
plausible. Where the repo's test setup makes it natural, write the
failing test first. State a brief plan whose steps each carry their
own verify check, then loop — implement, run, fix — until the check
is green. Done means *demonstrated*, not *written*.

## Why

Adapted from the "Goal-driven execution" principle in
[Andrej Karpathy's coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills)
(via [the X post](https://x.com/karpathy/status/2015883857489522876)
that published them). "Looks right" is the agent failure mode this
targets: code that reads plausibly and was never run. The library
already owns the *back* half of verification — [[smoke-before-commit]]
gates the commit, [[no-live-external-in-tests]] keeps the runs safe —
but nothing upstream forces the *task itself* to be framed as
something checkable. This module is that front half: it turns "make X
work" into "this command exits green," so each step of the work has a
pass/fail answer instead of a vibe.

## How to apply

- **Open the task by writing the success check down:** "done when
  `<command>` shows `<observable result>`." If no such sentence can
  be written, the task isn't understood yet — that's an
  [[assumptions-before-code]] moment, not a reason to start typing.
- **Test-first when it fits the repo:** if a test suite exists and
  the change is testable, write the failing test before the
  implementation and let it define done. Don't force it where the
  repo has no harness — a runnable command or a `--help` smoke is a
  legitimate check too.
- **Per step, name the check:** a plan step is "add the parser —
  verify: `uv run python -m py_compile …` + the new unit test," not
  "add the parser."
- **Loop until green, then stop.** A red check means fix and re-run,
  not narrate around it. A green check means the step is done —
  resist gold-plating past it (that's [[minimum-code-first]]'s
  territory).
- **Hand off to [[smoke-before-commit]]** as the final gate: the
  per-step checks verify the work as it lands; the smoke verifies
  the tree before the commit.

## Anti-patterns

- Declaring a change done because the diff "looks correct," without
  one run of anything.
- A plan whose steps have no verify column — pure construction, no
  observation.
- Writing the test *after* the implementation, shaped to pass it
  (the test confirms the code instead of the goal).
- Skipping verification because the harness is missing, instead of
  naming the cheapest runnable check that does exist.
- Looping on a red check by weakening the check.

## This rule is working if

- Transcripts open tasks with a "done when…" line, and close them by
  quoting the green run.
- Every plan step pairs a build action with a check that was
  actually executed.
- "It should work" disappears from hand-offs, replaced by command
  output.

## Related

- [[smoke-before-commit]] — the back half: this module frames and
  verifies the work in flight; that one gates the commit.
- [[no-live-external-in-tests]] — keeps the verify runs themselves
  safe.
- [[assumptions-before-code]] — when no verifiable goal can be
  stated, the gap is an unsurfaced assumption.
- [[minimum-code-first]] / [[surgical-diffs-only]] — the sibling
  guardrails in the per-edit discipline family.
