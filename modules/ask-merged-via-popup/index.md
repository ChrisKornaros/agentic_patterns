---
name: ask-merged-via-popup
type: workflow
scope: repo
lifecycle: stable
dependencies:
  - git-flow-no-direct-main
evidence:
  - playbook.md#141-workflow-rules-codified-mid-cycle
  - 02-workflow-patterns.md#3-askuserquestion-answer--merge-confirmation-not-a-request-to-wait
  - common-guardrails.md#always
applies_when:
  - repo follows GitHub Flow (sessions = one branch = one PR)
  - human is available to merge during the session
version: 1
---

# Ask "merged?" via popup

## Rule

After opening the PR, the agent hands the merge to the human with an
`AskUserQuestion` popup — not by ending the turn in prose. The popup
asks whether the PR has been merged, with options **Merged** ·
**Not yet** · **Changes requested / closed without merge**. The
popup answer *is* the merge confirmation; there is no intermediate
"waiting on your merge" turn. Before acting on a "merged" answer
from *any* channel (popup click or free-text reply), run
`gh pr view <N> --json state,mergedAt` and proceed to cleanup only
on `state == "MERGED"`.

## Why

A turn that ends with the agent waiting for a free-text "merged"
reply forces a session restart and burns the prompt cache; a popup
keeps the session warm and gives the human a one-click answer. This
is the single most-dropped step of the session-end loop — the agent
opens the PR and then stops in prose ("let me know once it's
merged") instead of popping the question. The product-use-tracker v3
cycle (§1.4.1,
PUT PR #25) made the popup the rule and the
playbook write-up
records why: the popup answer carries the same information as a
free-text "yes" but without the cold restart.

The verify-before-sync half exists because both channels are
fallible — a human clicking "Merged" out of habit, or typing "yep
merged" about the wrong PR, will send the agent into the destructive
cleanup sequence. One `gh pr view` call is cheap insurance against
deleting a branch and pulling a `main` that lacks the work — a state
whose recovery needs force-push, which [[git-flow-no-direct-main]]
denies.

## How to apply

- **Pop the question immediately after `gh pr create`**, in the same
  response as the push (see [[auto-commit-on-branch-done]]). Phrasing:

  > PR is up: `<url>`. Merge it in the GitHub UI when you're ready.
  > Has it been merged?
  >
  > Options: **Merged** · **Not yet** · **Changes requested / closed
  > without merge**

- **On "Not yet"**, re-pop the same question after a short pause —
  don't end the turn.
- **On "Changes requested / closed without merge"**, stop the
  cleanup sequence and wait for the human's review notes; the branch
  is still live work.
- **On "Merged" (or any free-text merge claim)**, run
  `gh pr view <N> --json state,mergedAt` *before* the
  `git switch main && git pull --ff-only && git branch -d <branch>`
  sequence. If `state != "MERGED"`, say so in one line and re-pop.

## Anti-patterns

- Ending the turn with "let me know when it's merged" instead of
  popping `AskUserQuestion` — the silent miss that drops the rest of
  the loop.
- Treating a popup click or a free-text "merged" as ground truth and
  running cleanup without the `gh pr view` check.
- Running `git branch -d <branch>` on an unverified claim, losing the
  branch's work when the merge hadn't actually landed.

## Related

- [[git-flow-session-end]]
- [[auto-commit-on-branch-done]]
- [[git-flow-no-direct-main]]
