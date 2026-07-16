---
name: session-start
description: "Opens a session deliberately — syncs with the remote, reads the persisted .claude/next-session.md handoff (or falls back to the roadmap), then runs an orient → plan → confirm loop before any code. Use at the start of a working session. The read-side mirror of /session-wrapup; shims the session-handoff module."
version: 1.0.0
source: prompts/session-start.md
module: session-handoff
tags: [workflow, agentic-optimization-research]
---

# Session start

Use at the *top* of a session instead of hand-writing "where were we."
Canonical text is [prompts/session-start.md](../../prompts/session-start.md);
this is the read-side surface of the
[session-handoff](../../modules/session-handoff/index.md) module
(`/session-wrapup` is the write side).

## 1. Sync with the remote

```
git fetch
git status -sb              # which branch? clean?
# If on the default branch and clean:
git pull --ff-only
```

If a feature branch is already checked out (interrupted session), say so —
don't pull `main` over it. Surface it and ask: resume, or stash/branch fresh.

## 2. Read the handoff

- Read `.claude/next-session.md` first if it
  exists (a `SessionStart` hook may have surfaced it — read it deliberately
  anyway).
- Absent / empty of direction → fall back to the host's roadmap / planning doc.
- The handoff is a warm-context distillation, not law. **If the roadmap has
  moved on, trust the roadmap.**

## 3. Orient → plan → confirm — don't write code yet

Compose [phase-kickoff](../phase-kickoff/SKILL.md). Summarize back first:

```
(1) what you'll build,
(2) which files you'll touch,
(3) what the smoke / verify output should look like when done,
(4) the end-of-branch shape — branch name per the naming rule, then the
    /session-wrapup loop.
```

New external substrate (third-party API, unfamiliar data source, metered
service)? Run `/substrate-preflight` first.

## 4. Branch before the first edit

Plan confirmed → `git switch -c <feat|docs|chore>/<slug>` *before* editing.

## Why this works

Collapses the start-of-session "re-derive state" cost the
[session-handoff](../../modules/session-handoff/index.md) module exists to
kill — it's the deliberate *read* of the handoff the wrap-up persisted into
the PR. Distinct from the passive `SessionStart` hook (which only injects the
file's text — it can't `git pull`, decide resume-vs-fresh, or run the
plan-gate). Full rationale in
[prompts/session-start.md](../../prompts/session-start.md).
