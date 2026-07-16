---
name: git-flow-session-end
type: workflow
scope: repo
lifecycle: stable
dependencies:
  - git-flow-no-direct-main
  - auto-commit-on-branch-done
  - ask-merged-via-popup
  - smoke-before-commit
evidence:
  - playbook.md#141-workflow-rules-codified-mid-cycle
  - git-workflow.md#the-session-end-loop
  - 02-workflow-patterns.md#1-auto-commit--auto-pr-at-end-of-branch-session
  - 02-workflow-patterns.md#3-askuserquestion-answer--merge-confirmation-not-a-request-to-wait
applies_when:
  - host follows GitHub Flow (sessions = one branch = one PR)
  - human is available to merge during the session
version: 4
---

# Git Flow — session-end loop

## Rule

A coding session ends with the PR merged into `main`, the local
`main` updated, and a fixed-format **Session end** summary
printed to the human. When the branch's scope is met and
verified, the agent's next response runs, in one turn:

1. sync the project's tracking docs to reality (human-readable
   requirements/roadmap/bug docs *and* the AI-facing
   `CLAUDE.md` status lines)
2. commit → push → `gh pr create`
3. pop the merge question via `AskUserQuestion`

No "ready to commit?" stall. The merge confirmation arrives via
the popup; the sync + branch-delete sequence and the closing
**Session end** summary run in the response after that.

## Why

The "ready to commit?" turn was a round-trip with no information
in it — the agent had everything it needed to proceed, and the
human's "yes" was reflexive. The product-use-tracker v3 cycle
(case study §1.4.1)
counted the cost and made the auto-shape a rule:
[[git-flow-no-direct-main]] is the safety net, so sitting on
uncommitted work is friction, not safety. The popup-for-merge
half exists for the same reason: a turn that ends with the
agent waiting for "merged" forces a session restart and burns
the prompt cache; a popup keeps the session warm and gives the
human a one-click answer.

Folding the doc-sync step *into* the session-end sequence
(rather than letting it drift into the next session) keeps the
human-readable requirements doc and the AI-facing `CLAUDE.md`
honest: status flips, test notes, and "what changed" land in the
same PR as the code. Future-you reading the PR a quarter later
gets a faithful snapshot, not a code diff plus archaeology.

The fixed-format **Session end** summary at the close exists
because the previous freeform "Done." gave the human no
consistent place to look for what just happened. A stable shape
is scannable and survives across repos without retraining.

## How to apply

When the branch goal is met and verified (smoke green, tests
passing, acceptance criteria observable), execute these steps
**in one response**:

1. **Sync the tracking docs to reality — before committing.**
   Update both layers in the same diff as the code:
   - **Human-readable tracking** — the requirements / roadmap /
     enhancements / bugfixes doc(s) the host repo uses (common
     names: `REQUIREMENTS.md`, `ROADMAP.md`, `ENHANCEMENTS.md`,
     `BUGFIXES.md`, `playbook.md`). Flip statuses (🔴/🟡/🟢,
     `in-progress` → `done`), add a one-line outcome, and note
     any *important* observation from testing/development that
     would otherwise be lost (a surprise, a deferred sub-task,
     a constraint discovered mid-branch). Skip mechanical
     play-by-play.
   - **`CLAUDE.md` status lines** — the root `CLAUDE.md` (and
     any subdir `CLAUDE.md` that touches changed folders).
     Update the Layout / Status tables, the "Composed modules"
     ledger if a module was vendored or bumped, and any rule
     whose wording is now stale.

   If nothing meaningful changed in either layer, say so in the
   commit body (`Docs: no status changes — pure code refactor`)
   rather than silently skipping. The check happened.

   If the host vendors [[session-handoff]], its **kickoff emit**
   (`.claude/next-session.md`) is written *here too*, alongside the
   doc-sync — so the next-session handoff is `git add`ed into the same
   commit and rides this PR, not left as a stray change on `main`. (The
   memory-triage half of that module runs *after* the merge; see step
   6.)
2. **Commit + push + open PR in one response.** `git add` →
   `git commit` → `git push -u origin <branch>` →
   `gh pr create` with title, body, and the
   *Delivered + Verified* footer (see
   `git-workflow`).
   Print the PR URL.
3. **Pop the merge question via `AskUserQuestion`, not by
   ending the turn.** Phrasing:

   > PR is up: `<url>`. Merge it in the GitHub UI when you're
   > ready. Has it been merged?
   >
   > Options: **Merged** · **Not yet** · **Changes requested /
   > closed without merge**

   The popup answer *is* the merge confirmation — no
   intermediate "waiting on your merge" turn. The third option
   covers "I'm going to review and request changes" — the agent
   stays on the branch and awaits the human's notes rather than
   running cleanup.
4. **Verify before syncing — always, regardless of channel.**
   Whether the answer came in via the popup or via free-text
   ("merged" / "approved" / "go ahead"), run
   `gh pr view <N> --json state,mergedAt` *before* the destructive
   sync sequence. If `state != "MERGED"`:
   - say so in one line and re-pop `AskUserQuestion`
   - do **not** run `git switch main && git pull && git branch
     -d <branch>` on an unverified claim
   - the cost of one extra `gh` call is trivial; the cost of
     deleting the branch + pulling a `main` without the work
     requires force-push to recover, and force-push is on the
     deny list
5. **Sync and clean up** (only after `state == "MERGED"`
   confirmed):
   ```sh
   git switch main
   git pull --ff-only
   git branch -d <branch>     # safe delete — refuses if unmerged
   git fetch --prune
   ```
6. **Print the fixed-format Session end summary.** Always emit
   it, in this exact shape:

   ```markdown
   ## Session end

   - **Branch merged:** `<branch>` → `main` (PR #<n>)
   - **Delivered:** <one-line outcome — what shipped>
   - **Verified:** <how — smoke, tests, manual check>
   - **Docs synced:** <files touched, or "no status changes">
   - **Local state:** `main` up to date, `<branch>` deleted

   Session done.
   ```

   No *guessed-from-context* next step in this block — the
   next session's work is driven by the host's version-planning
   / phase doc, not by the agent's conversational recall. A
   *roadmap-grounded, persisted* handoff (a `.claude/next-session.md`
   sourced from the planning doc, plus cross-project lesson
   capture) is a separate, legitimate step — owned by the
   [[session-handoff]] module, which **straddles this loop**: its
   kickoff emit folds into step 1 (so the handoff rides the PR), and
   its memory-triage runs here, after the merge, before this summary.
   The ban here is on inventing prose that scrolls away, not on a
   durable handoff file.

If "Not yet" comes back from the popup, re-pop the same
question after a short pause rather than ending the turn. If
"Changes requested" comes back, stop the cleanup sequence
entirely and wait for the human's review notes — the branch is
still live work.

## Enforcement (optional Stop-hook companion)

The steps above are a *prompt* — they rely on the agent honoring them.
In long sessions the most-dropped step is the hand-off: opening the PR
and then **ending the turn in prose** ("let me know once it's merged")
instead of popping `AskUserQuestion`, which silently skips the popup and
often the post-merge cleanup too. Because that's an adherence gap, not a
knowledge gap, the durable fix is a *mechanism*, not a louder rule —
mirroring how [[git-flow-no-direct-main]] is enforced by a deny-list and
the file-access rule by a PreToolUse hook.

This module ships an optional `Stop` hook,
[`session_end_guard.py`](session_end_guard.py), wired via
[`settings-snippet.json`](settings-snippet.json). It fires when the agent
tries to end a turn and **nudges** (does not hard-block) in the two
objective states the loop gets dropped in:

| State (a touched repo's branch PR) | Trigger condition | Nudge |
|---|---|---|
| **MERGED** | tree clean + pushed, still on the feature branch | verify → sync `main` → delete branch → print Session end summary |
| **OPEN** | tree clean + fully pushed (the hand-off point) | confirm the merge via an `AskUserQuestion` popup, not prose |

The check runs against **every git repo the session touched** — `cwd` plus
every repo reached via a `cd <dir>` / `git -C <dir>` in the transcript's
Bash calls (deduped to their toplevels, capped). This closes the cross-repo
blind spot: a session *rooted* in repo A (sitting on a clean `main`) that
does its branch+PR work in repo B used to slip past a `cwd`-only check, so
the hand-off/cleanup nudge never fired.

It is deliberately conservative, to add no friction to ordinary turns:

- Per repo, no-ops on the default branch, a detached HEAD, outside a git
  repo, or a branch with no pushed counterpart (early WIP).
- **Skips the `gh` call entirely while the tree is dirty or unpushed** —
  you're still working — so mid-work stops cost nothing.
- **Fails open**: any error (no `gh`, no network, bad payload, an
  exception) allows the stop. A guard that wedges a session on its own
  bug is worse than a missed nudge.
- **Honors `stop_hook_active`**: it nudges at most once per continuation,
  so it can never loop; each fresh user turn re-arms it.

What it can and can't do: a Stop hook can re-surface the workflow at the
moment the agent is about to drop it, but it **cannot** force the agent to
call `AskUserQuestion` — that remains the agent's action. The hook turns a
silent miss into a visible, self-correcting prompt. Disable for a session
with `SESSION_END_GUARD_DISABLED=1`; if the human has explicitly deferred
the merge, the OPEN-state nudge says so and the agent may stop.

## Anti-patterns

- Committing the code first and "doing the docs in a follow-up
  PR." The doc sync belongs in the same diff; a follow-up PR
  almost never happens, and the requirements doc rots.
- Skipping the doc-sync step on the grounds that "the diff is
  self-documenting." The human-readable tracking doc is for the
  human reading six months later, not for the agent reading the
  diff today.
- Ending the turn with uncommitted work and a "ready to commit?"
  question. The branch is done; commit it.
- Ending the turn waiting for a free-text "merged" reply instead
  of popping `AskUserQuestion`.
- Acting on a "merged" answer (from either channel) without
  first running `gh pr view --json state,mergedAt`. The popup
  click and the chat reply are equally fallible.
- Running the sync sequence on an unverified "merged" claim,
  losing the branch's work in the process.
- Pushing to `main` directly to "save a step" when the PR
  workflow feels heavyweight for a small change.
- Replacing the fixed **Session end** block with freeform prose,
  or appending a *guessed* "recommended next prompt" to it — the
  human drives next-step selection from the version-planning doc.
  (A roadmap-grounded handoff *file* is fine — that's the
  [[session-handoff]] module's job, not freeform prose in the
  summary.)

## Related

- [[git-flow-no-direct-main]]
- [[ask-merged-via-popup]]
- [[auto-commit-on-branch-done]]
- [[smoke-before-commit]]
- [[docs-sync-before-commit]]
- [[session-handoff]] — the knowledge-capture + next-session handoff that straddles this loop (kickoff emit in step 1, memory-triage after the merge)
