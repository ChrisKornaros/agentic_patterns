# Session wrap-up

The wrap-up has two forms depending on whether the entry to it is
*end-of-branch* (PR opened, awaiting merge) or *post-merge* (you've
just synced main).

## A. End-of-branch (smoke green, no PR yet)

Don't actually paste this — the v3-cycle rule is that the agent
should *just do it* when the branch goal is met. First write the
next-session kickoff (§D-1) so it rides this PR, then:

```
# Overwrite .claude/next-session.md with the roadmap-grounded kickoff (§D-1).
git add -A                          # includes .claude/next-session.md
git commit -m "<scoped message>"
git push -u origin <branch>
gh pr create --title "..." --body "..."
# Then, in the same response, AskUserQuestion with post-merge
# options ("Sync + start next phase", "Sync only — stop here",
# "Not yet").
```

No "ready to commit?" turn. The status emoji in
`ENHANCEMENTS.md` / `BUGFIXES.md` flips 🔴 → 🟢 *inside this PR*,
not a follow-up chore PR — and so does the next-session handoff.

## B. Post-merge (sync sequence)

If the entry was the AskUserQuestion popup answer ("Merged"), no
verification needed — proceed:

```
git switch main && git pull --ff-only && git branch -d <branch> && git fetch --prune
```

If the entry was a free-text claim ("I merged it") in a later
turn, verify first:

```
gh pr view <N> --json state,mergedAt
```

If `state != "MERGED"`, say so briefly and re-prompt — don't sync.

## C. After the sync — the checklist

Paste this once main is up-to-date:

```
We just merged PR #<N>. Before we end (or start the next branch):

1. If this phase has a roadmap entry in REQUIREMENTS_V<N>.md and the
   status wasn't flipped inside the PR, fix that now and ship as a
   follow-up — but flag the missed flip as a workflow miss.
2. If anything about CLAUDE.md is now stale (module status, gotchas,
   new rule discovered), update it. If the rule is generalizable,
   note it for the research-repo catch-up.
3. If you learned something about how I work or what I prefer, propose
   a memory entry. Don't save it without showing me first.
```

## D. Session handoff — knowledge across the boundary

Canonical rule: the [session-handoff](../modules/session-handoff/index.md)
module. Its two halves run on **either side of the commit** — the per-session
git loop deliberately leaves both out:

1. **Kickoff emit — *before* the commit (§A).** Overwrite
   `.claude/next-session.md` with a next-session prompt **grounded in the
   roadmap / version-planning doc** — source section, suggested branch,
   concrete steps, what to run, open questions. If nothing is queued, write
   "pick from the roadmap" rather than inventing a step. **Cap the file at
   ~40 lines; link the roadmap section rather than restating it** — it is
   injected verbatim into the next session's opening context (full rule in
   the module). Write it before `git add` so it rides this PR (the commit
   then says what shipped *and* what's next).
2. **Memory triage — *after* the sync, before the Session end block.** Sort
   what was learned: *project-specific* → the per-project memory store;
   *transferable* (a workflow, a recurring failure mode, a "we work better
   when…" lesson) → append to the cross-project inbox
   `lessons-log` in its entry
   format. Anything about how Chris works is *proposed*, not saved silently.

The next session reads `.claude/next-session.md` first (host `CLAUDE.md`
convention).

## Why this works

The most-skipped step in a session is wrap-up. Skipping it means the
*next* session pays the cost of re-deriving "what was just done." This
prompt makes the wrap-up an explicit, named action with a checklist.
Step 3 specifically asks the agent to *propose* a memory entry before
saving — keeps memory hygiene under human control.

The split into A/B/C was added 2026-05-23 after the v3 cycle clarified
that the *end-of-branch* moment and the *post-merge* moment are
distinct, that the verify-merge-claims step matters, and that the
status flip belongs inside the feature PR — not the wrap-up.

The handoff (§D) was split across the commit on 2026-06-05: the
**kickoff emit** moved *before* the commit so `.claude/next-session.md`
rides the feature-branch PR (mirroring a good hand-written commit, which
records what shipped *and* what's next), while **memory triage** stays
*after* the merge — it's human-gated and writes to stores outside the
code PR. Previously both ran post-merge, which orphaned the kickoff as an
uncommitted change on a freshly-synced `main`. See the
[session-handoff module](../modules/session-handoff/index.md) (v2).

Cross-refs:
- playbook/02-workflow-patterns.md §Updated/1–4
- playbook/07-anti-patterns.md #12
