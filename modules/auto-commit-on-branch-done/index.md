---
name: auto-commit-on-branch-done
type: workflow
scope: repo
lifecycle: stable
dependencies:
  - git-flow-no-direct-main
  - smoke-before-commit
evidence:
  - playbook.md#141-workflow-rules-codified-mid-cycle
  - 02-workflow-patterns.md#1-auto-commit--auto-pr-at-end-of-branch-session
  - common-guardrails.md#always
applies_when:
  - repo follows GitHub Flow (sessions = one branch = one PR)
version: 1
---

# Auto-commit on branch done

## Rule

When the branch's scope is met and verified — smoke green, tests
passing, acceptance criteria observable — the agent's **next
response** runs `git add` → `git commit` → `git push -u origin
<branch>` → `gh pr create`, in one turn. It does not stop to ask
"ready to commit?" or "should I open the PR?" Those are the agent's
job once the work is done, verified, and the tracking docs are
synced. The human-merge gate is the safety net; sitting on
committed-but-unpushed work is friction, not safety.

## Why

The "ready to commit?" turn is a round-trip with no information in
it: the agent already has everything it needs to proceed, and the
human's "yes" is reflexive. The product-use-tracker v3 cycle
(§1.4.1,
PUT PR #32) counted the cost and made the auto-shape a rule. It is
only safe *because* [[git-flow-no-direct-main]] denies
`gh pr merge` and `git push origin main` — a person still has to
click merge in the GitHub UI, so the agent committing and pushing a
branch can't ship anything unreviewed. The
playbook write-up
frames it as: the gate that makes auto-commit safe is the merge
gate, not a commit-confirmation gate.

## How to apply

- **Wait for the green signal first.** [[smoke-before-commit]] is
  the precondition — don't auto-commit a tree you haven't verified.
- **Sync the tracking docs in the same diff** before committing the
  wrap-up: flip status emoji (🔴→🟢), add the one-line outcome,
  update `CLAUDE.md` status lines. The status flip ships *inside*
  the feature PR, never as a follow-up chore PR.
- **Commit + push + open the PR in one response.** `gh pr create`
  with a title, body, and the *Delivered + Verified* footer; print
  the PR URL.
- **Then hand off via [[ask-merged-via-popup]]** — don't end the
  turn waiting for a free-text reply.

## Anti-patterns

- Ending the turn with a clean, verified branch and a "ready for me
  to commit?" question. The branch is done; commit it.
- Committing locally but not pushing / not opening the PR, leaving
  the work stranded on the machine.
- Flipping the status emoji in a separate follow-up PR instead of
  inside the feature PR that earned the flip.
- Treating auto-commit as license to skip the human-merge gate by
  pushing to `main` directly — the gate is what makes auto-commit
  safe.

## Related

- [[git-flow-session-end]]
- [[git-flow-no-direct-main]]
- [[smoke-before-commit]]
- [[ask-merged-via-popup]]
