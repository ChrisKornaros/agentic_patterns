---
name: session-handoff
type: workflow
scope: repo
lifecycle: stable
dependencies:
  - git-flow-session-end
evidence:
  - playbook/README.md#quick-reference-card
  - prompts/phase-kickoff.md
  - knowledge/lessons-log.md
applies_when:
  - host follows the git-flow-session-end loop
  - work spans multiple sessions and/or multiple projects
version: 3
---

# Session handoff — knowledge capture + next-session kickoff

## Rule

This module adds two knowledge-capture steps to the
[[git-flow-session-end]] loop, **split across the commit boundary** so
each output lands in the right place:

1. **Kickoff emit — *before* the commit.** Write a roadmap-grounded
   next-session prompt to `.claude/next-session.md`, *then* `git add` it
   alongside the doc-sync so it rides the **feature branch's PR** (the
   same diff the merge popup confirms). The commit then says both what
   shipped *and* what's next.
2. **Memory triage — *after* the merge sync.** Decide what was learned
   this session and route it: *project-specific* state → the per-project
   memory store; *transferable* lessons → the cross-project
   `knowledge/` inbox. This is
   human-gated and produces no feature-branch artifact, so it runs after
   the merge, before the Session end summary.

This is the layer [[git-flow-session-end]] deliberately leaves out: it
owns the git mechanics; this module owns the *knowledge* that crosses
the session boundary.

## Why

The single biggest waste in agent work is **re-deriving state** at the
start of a session — the playbook's quick-reference card names it
(#8: *"each session ends with the repo in a state where the next
session can resume cleanly"*; #10: *"the biggest waste is re-deriving
state"*). Two distinct kinds of state leak across the boundary, and
each needs its own destination:

- **What we learned.** Per-project memory is siloed by design, so a
  *transferable* lesson learned in one project is invisible to the
  next. Without a shared inbox it's lost the moment the session ends.
  The `knowledge/` tier is that shared
  place; routing into it at session-end is the only reliable moment
  (the lesson is freshest, and the agent is already reflecting).

- **Where we're going.** A cold-start session re-reads the roadmap and
  guesses the next unit of work. A handoff file written while the
  context is still warm — *grounded in the roadmap, not invented* —
  collapses that orient cost to a single read.

The grounded-and-persisted shape is what distinguishes this from the
anti-pattern [[git-flow-session-end]] forbids. That rule bans a
*guessed-from-context prose* next-step appended to the Session end
block — noise that scrolls away unread. A handoff that is (a) sourced
from the roadmap / version-planning doc and (b) written to a file the
next session loads is the opposite: durable, checkable, and inert if
ignored rather than misleading.

**Why the kickoff rides the feature-branch commit.** The emit runs
*before* the commit, not after the merge, so `.claude/next-session.md`
is part of the PR's diff — the commit records what shipped *and* what's
next, the way a good hand-written commit does. (Writing it *after* the
merge, the original v1 shape, left the kickoff as an uncommitted change
sitting on a freshly-synced `main` — orphaned from the work that
produced it, and only swept up incidentally by the *next* session's
first PR.) Memory triage stays after the merge precisely because it has
no feature-branch artifact: it proposes per-project memory (a separate,
human-gated store) and — in this repo — appends to `knowledge/`, neither
of which belongs in the code PR.

## How to apply

The two steps run at **different points** in the [[git-flow-session-end]]
loop, on either side of the commit:

| Step | When | Why there |
|---|---|---|
| **1. Kickoff emit** | *Before* the commit — with the doc-sync (step 1 of [[git-flow-session-end]]), so it's `git add`ed into the feature branch and rides the PR | It produces a tracked file; that file belongs in the same diff as the work |
| **2. Memory triage** | *After* the merge is verified and `main` synced (steps 4–5), **before** the Session end summary | It's human-gated and writes to stores outside the code PR |

### 1. Kickoff emit → `.claude/next-session.md` (before the commit)

Overwrite (don't append to) `.claude/next-session.md` with a
ready-to-run kickoff for the next unit of work, **derived from the
host's roadmap / version-planning doc** — not from conversational
recall. Shape:

```markdown
# Next session — <YYYY-MM-DD>

- **Source:** <roadmap/phase doc + section this is drawn from>
- **Suggested branch:** `<feat|docs|chore>/<slug>`

## Do
1. <first concrete step>
2. ...

## To run / verify
- <commands or checks the next session will need>

## Open questions / watch-outs
- <anything unresolved that the next session should decide first>

---
*Generated at session-end by the session-handoff module. If the roadmap
has moved on, trust the roadmap over this file.*
```

**Cap it at ~40 lines, and link rather than inline.** The file is
injected verbatim into the next session's opening context (by the
companion hook below), so every line spends always-loaded budget — the
pre-cap norm was an ~11KB injection, a whole CLAUDE.md's worth of
tokens (roadmap/12 §5 S2).
The kickoff is a *pointer to* the next unit, not the plan itself: name
the roadmap section and link it (`roadmap/NN §X`) instead of restating
its steps, rationale, or history. A draft running past ~40 lines is
almost always restating the planning doc — cut to links until it fits.

If the roadmap genuinely has no clear next unit (e.g. a track just
closed), write that — `## Do\n- Pick the next track from <roadmap doc>;
nothing is pre-selected.` — rather than guessing one. The file may be
empty of direction; it must never be *invented* direction.

Then `git add .claude/next-session.md` so it's committed in the same
[[git-flow-session-end]] step-2 commit as the code and the doc-sync —
the kickoff is part of the PR, not a stray change left on `main`.

The next session reads this file first (host `CLAUDE.md` convention, or
the optional companion hook below).

### 2. Memory triage (after the merge sync)

Reflect on the session and sort what's worth keeping:

| What | Destination |
|---|---|
| Project state, a gotcha tied to *this* codebase, a preference about *this* repo | the **per-project** memory store (`~/.claude/projects/<key>/memory/`) — propose before saving |
| A transferable workflow, a recurring failure mode, a "we work better when…" lesson | append to `knowledge/lessons-log.md` in the inbox format (`CLAUDE`) |
| A portable guardrail already crisp enough to be a rule | write it straight as a [module](../) |
| Nothing meaningful | say so — "no handoff knowledge this session" — don't invent |

Anything touching *how Chris works* is **proposed, not saved silently**
— same human-gate as the [[git-flow-session-end]] memory step.

## Reading the handoff next session

The write side is useless if nothing reads it. Three mechanisms, in
increasing order of agency:

- **Convention (baseline).** The host `CLAUDE.md` carries a line: *"At
  session start, if `.claude/next-session.md` exists, read it before
  planning."* Agent-honored; zero infrastructure.
- **`/session-start` command (deliberate, manual).** The active read-side
  mirror of `/session-wrapup` — a named command the human invokes to open
  a session: it `git pull`s, reads this file (or falls back to the
  roadmap), and runs an orient → plan → confirm gate before any code.
  Unlike the hook below it can *act* (sync the remote, decide
  resume-vs-fresh on an interrupted branch), not just inject text. Lives
  at [prompts/session-start.md](../../prompts/session-start.md) /
  [skills/session-start/SKILL.md](../../skills/session-start/SKILL.md).
- **Companion `SessionStart` hook (enforcement, optional).** This module
  ships an optional `SessionStart` hook,
  [`session_handoff_kickoff.py`](session_handoff_kickoff.py), wired via
  [`settings-snippet.json`](settings-snippet.json). On every session
  start it surfaces `.claude/next-session.md` into the opening context,
  making the read **mechanical** rather than agent-honored — the same
  upgrade [[git-flow-session-end]]'s Stop hook is to *its* prompt. It is
  deliberately inert when there's nothing to surface: a no-op (no output)
  when the file is absent, and it **fails open** on any error, so it can
  never wedge a cold start. Disable for a session with
  `SESSION_HANDOFF_KICKOFF_DISABLED=1`. Wire it where cold-start
  adherence matters; the convention above is the floor when you don't.

## Companion files

| File | Role |
|---|---|
| [`session_handoff_kickoff.py`](session_handoff_kickoff.py) | The `SessionStart` hook — reads the payload on stdin and injects `.claude/next-session.md` via `hookSpecificOutput.additionalContext`. No-ops when the file is absent; fails open. |
| [`settings-snippet.json`](settings-snippet.json) | Paste-ready `hooks.SessionStart` entry that runs the hook, guarded with `[ -f ] || exit 0` so it's a safe no-op until the module is vendored. Merge into the host's `.claude/settings.json` (VENDORING.md §6). |

Vendoring this module via `scripts/install-modules.sh`
`cp -R`s both files in and the run notice points back here to wire the
hook — and the Mode-B example settings
(`claude-settings.example.json`)
already pre-wires the `SessionStart` block, so `/bootstrap-repo` auto-wires
it. On Chris's own machines the hook is wired **user-globally** in
`dotfiles/.claude/settings.json`
(promoted there 2026-06-04 after repo-scoped dogfooding), so it fires in
every repo with this module vendored.

## Anti-patterns

- **Inventing a next step the roadmap doesn't support.** The kickoff is
  a *distillation* of the planning doc, not the agent's guess. An empty
  "pick from the roadmap" is correct when nothing is queued.
- **Restating the roadmap in the kickoff instead of linking it.** Blows
  the ~40-line cap and double-spends context: the next session loads the
  restatement *and* reads the roadmap it mirrors. Link the section;
  inline only what the link can't carry (branch slug, verify commands).
- **Appending the kickoff to the chat Session end block instead of the
  file.** That's the scroll-away failure [[git-flow-session-end]] bans;
  the persisted file is the whole point.
- **Dumping project-specific state into `knowledge/`.** It pollutes the
  cross-project inbox. Project state belongs in per-project memory.
- **Saving a "how Chris works" lesson without proposing it first.**
- **Treating an inbox entry as published.** It's an uncited candidate
  until it graduates into a cited playbook essay or module.

## Related

- [[git-flow-session-end]] — the git mechanics this runs after
- knowledge/ inbox — the capture destination
- [prompts/phase-kickoff.md](../../prompts/phase-kickoff.md) — the shape the emitted kickoff feeds
