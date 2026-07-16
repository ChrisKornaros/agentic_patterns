---
name: phase-kickoff
type: prompt
scope: task
lifecycle: stable
dependencies: []
evidence:
  - prompts/phase-kickoff.md
  - case-studies/product-use-tracker/playbook.md#141-workflow-rules-codified-mid-cycle
  - playbook/02-workflow-patterns.md#1-auto-commit--auto-pr-at-end-of-branch-session
applies_when:
  - host has a roadmap or requirements doc with phase sections
  - session is implementing a phase, not exploring or debugging
version: 1
---

# Phase kickoff

## Rule

At the start of a session that's implementing a roadmap phase,
paste the kickoff prompt below before any code is written. It
forces an explicit *orient → plan → confirm → implement* loop
and pre-commits the agent to the auto-PR shape at end of phase.

## Why

Without the kickoff, Claude tends to jump to code on the wrong
premise. The case study repeatedly showed sessions where 20+
minutes of edits happened against a misread spec — a one-turn
"summarize what you're about to build" upfront catches the
mismatch before it costs a session. Step (4) — pre-committing
to the auto-PR shape — was added in the v3 cycle
(case study §1.4.1)
after every phase started ending with a redundant "ready to
commit?" round-trip; baking the wrap-up into the kickoff makes
the [[git-flow-session-end]] shape implicit instead of explicit.

## How to apply

Paste this at the start of the session, filling in `<X>`,
`<N>`, and the phase section ID:

```
We're starting Phase <X> from REQUIREMENTS_V<N>.md. Read
§<phase-section> (the phase spec) and §2 (the load-bearing
constraint), then summarize back to me:

  (1) what you're going to build,
  (2) which files you'll touch,
  (3) what the smoke output should look like when it's done,
  (4) what you'll do at end of phase — confirm: branch, code,
      smoke green, commit, push, gh pr create, then
      AskUserQuestion for the post-merge action (no idle
      "ready to commit?" turn).

If this phase touches a new external substrate (a third-party
API, a data source you haven't used before, a service with rate
limits or paid metering), run substrate-preflight.md first.

Don't write code yet.
```

The agent's response should be a short numbered list answering
(1)–(4). If it skips a number or starts writing code, re-prompt
with "Answer (3) before any edits."

## Anti-patterns

- Skipping the kickoff because the phase looks small. The
  smaller the phase, the cheaper the kickoff — it's 30 seconds
  of orientation, not a process tax.
- Letting the agent answer (1) and (2) but skip (3). The
  expected smoke output is the most load-bearing item; it
  forces the agent to think about acceptance criteria, not just
  scope.
- Modifying step (4). The auto-PR shape is the whole point of
  baking it in at kickoff — softening it ("commit if you want")
  brings back the "ready to commit?" stall.

## Related

- [[git-flow-session-end]]
- [[substrate-preflight]]
- [[session-wrapup]]
