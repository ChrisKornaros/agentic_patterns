---
name: session-wrapup
description: "Runs the end-of-branch / post-merge wrap-up — auto-commit + PR, the merge popup, verify-before-sync, the CLAUDE.md / memory catch-up, and the session handoff (cross-project lesson capture + next-session kickoff). Use when finishing a branch or closing out a working session. Shims the git-flow-session-end + session-handoff modules."
version: 1.2.0
source: prompts/session-wrapup.md
module: git-flow-session-end
tags: [workflow, agentic-optimization-research]
---

# Session wrap-up

Use when a branch's goal is met (or just after a merge) to run the
session-end loop. The canonical workflow is the
[git-flow-session-end](../../modules/git-flow-session-end/index.md)
module; this skill is its mid-session trigger.

## A. End-of-branch (smoke green, no PR yet)

Just do it — don't ask "ready to commit?". First write the next-session
kickoff (the [session-handoff](../../modules/session-handoff/index.md)
emit, see D-1) into `.claude/next-session.md` so it rides this PR, then:

```
# Overwrite .claude/next-session.md with the roadmap-grounded kickoff (D-1).
git add -A                          # includes .claude/next-session.md
git commit -m "<scoped message>"   # status emoji flips 🔴→🟢 INSIDE this PR
git push -u origin <branch>
gh pr create --title "..." --body "...<Delivered + Verified footer>"
# Then, same response: AskUserQuestion — Merged / Not yet /
# Changes requested.
```

## B. Post-merge (sync sequence)

```
# Verify first — always, regardless of channel:
gh pr view <N> --json state,mergedAt
# Only on state == "MERGED":
git switch main && git pull --ff-only && git branch -d <branch> && git fetch --prune
```

If `state != "MERGED"`, say so and re-pop — don't sync.

## C. After the sync — the catch-up checklist

```
We just merged PR #<N>. Before we end (or start the next branch):

1. If a roadmap/REQUIREMENTS status wasn't flipped inside the PR, fix
   it now as a follow-up — and flag the missed flip as a workflow miss.
2. If anything in CLAUDE.md is now stale (module status, gotchas, a new
   rule), update it. If the rule generalizes, note it for the research repo.
3. If you learned something about how I work, PROPOSE a memory entry —
   don't save it without showing me first.
```

## D. Session handoff — knowledge across the boundary

Backed by the [session-handoff](../../modules/session-handoff/index.md)
module. Its two halves run on **either side of the commit**:

**D-1. Kickoff emit — *before* the commit (in section A).** Overwrite
`.claude/next-session.md` with a kickoff **grounded in the roadmap /
planning doc** (not conversational recall): source section, suggested
branch, the steps, what to run, open questions. **Cap it at ~40 lines;
link the roadmap section instead of restating it** (the file is injected
verbatim at next session start — module has the full rule). If nothing's
queued, say "pick from the roadmap" — never invent direction. Write it
before `git add` so it lands in this PR.

**D-2. Memory triage — *after* the sync, before the Session end block.**
Project-specific state → that project's per-project memory store.
*Transferable* lesson (a workflow, a recurring failure mode, "we work
better when…") → append to the cross-project inbox
`lessons-log`. Anything
about how I work → **propose**, don't save silently.

Then print the fixed-format **Session end** block from the module.

## Why this works

The wrap-up is the most-skipped step; making it a named, surfaced
action keeps the next session from re-deriving "what just happened."
Full rationale in [prompts/session-wrapup.md](../../prompts/session-wrapup.md)
and the [git-flow-session-end](../../modules/git-flow-session-end/index.md) module.
