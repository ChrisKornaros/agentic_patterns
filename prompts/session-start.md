# Session start

The active mirror of [session-wrapup](session-wrapup.md). Run it at the
*top* of a session instead of hand-writing a "where were we" prompt: it
syncs with the remote, reads the persisted handoff (or falls back to the
roadmap), and runs an orient → plan → confirm loop **before any code**.

This is the *read* side of the [session-handoff](../modules/session-handoff/index.md)
loop made into a deliberate action. The wrap-up writes
`.claude/next-session.md` into the feature-branch PR; this picks it up.

## The loop

### 1. Sync with the remote

```
git fetch
git status -sb          # which branch am I on? clean?
# If on the default branch and clean:
git pull --ff-only
```

If a **feature branch** is already checked out (an interrupted session),
say so and don't pull `main` over it — surface the in-progress branch and
ask whether to resume it or stash/branch fresh.

### 2. Read the handoff

- If ``next-session`` exists, read
  it first. (A `SessionStart` hook may have already surfaced it into
  context — read it deliberately anyway; the file is the source, the hook
  injection is a convenience.)
- If it's **absent or empty of direction**, fall back to the host's
  roadmap / version-planning doc and pick the next unit from there.
- The handoff is a *distillation written while context was warm*, not law.
  **If the roadmap has moved on since it was written, trust the roadmap**
  (the file's own footer says so).

### 3. Orient → plan → confirm (don't write code yet)

Compose [phase-kickoff](phase-kickoff.md): summarize back, before touching
anything,

1. what you're going to build,
2. which files you'll touch,
3. what the smoke / verify output should look like when it's done,
4. the end-of-branch shape (branch name per the host's naming rule, then
   the [session-wrapup](session-wrapup.md) loop).

If the unit touches a new external substrate (a third-party API, an
unfamiliar data source, a metered/rate-limited service), run
`/substrate-preflight` first.

### 4. Branch before the first edit

Once the plan is confirmed, `git switch -c <feat|docs|chore>/<slug>`
*before* editing — never start work on the default branch.

## Why this works

The single biggest waste in agent work is **re-deriving state** at the
start of a session ([session-handoff](../modules/session-handoff/index.md)
§Why). The wrap-up loop already collapses that cost by persisting a
roadmap-grounded handoff into the PR; `/session-start` is the matching
read action so the cost is actually *collected* rather than paid again.

It's distinct from the passive `SessionStart` hook on purpose. The hook
only *injects* the file's text into context — it can't `git pull`, can't
decide resume-vs-fresh on an interrupted branch, and can't run the
orient → plan → confirm gate. `/session-start` is the agent *doing* those
things, deliberately, as a named action a human can invoke. The hook is
the floor (it fires even when you forget); the command is the full
ritual.

Pairing it with `/session-wrapup` makes the session boundary symmetric:
one command to open, one to close, and a persisted file carrying the
intent between them.

Cross-refs:
- [session-handoff module](../modules/session-handoff/index.md) — the write side + the three read mechanisms
- [phase-kickoff](phase-kickoff.md) — the orient → plan → confirm loop this composes
- [session-wrapup](session-wrapup.md) — the closing mirror
