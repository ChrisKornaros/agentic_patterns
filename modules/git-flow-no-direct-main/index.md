---
name: git-flow-no-direct-main
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - playbook.md#141-workflow-rules-codified-mid-cycle
  - git-workflow.md
  - common-guardrails.md#never-without-explicit-human-approval
applies_when:
  - repo has a remote
  - repo has a deployed surface OR more than one developer
version: 1
---

# Git Flow — no direct commits to `main`

## Rule

`main` is the deployable / shippable branch. Never push to it
directly, never force-push to it, and never run `gh pr merge`
from the agent — the human merges in the GitHub UI as the
approval gate. All work happens on feature branches and lands
through a pull request.

## Why

The PR + human-merge sequence is the only step in the workflow
where a person *has to* look at the change before it ships.
Bypassing it — even for a "small fix" — turns the merge gate
into folklore. The product-use-tracker case study
(§1.4.1)
codified `gh pr merge` on the deny list specifically because the
human's click is the approval that creates a reviewable history.
Force-push and direct-to-main both delete that history.

## How to apply

- **Start every session on a feature branch.** If `HEAD` is on
  `main`, pick a branch name (`feat/`, `fix/`, `chore/`, `docs/`)
  and run `git switch -c <branch>` *before* the first edit.
- **Open the PR via `gh pr create`.** Print the URL. Do not run
  `gh pr merge` — it's on the deny list in
  `settings` by design.
- **Hand the merge to the human.** Use the
  [[ask-merged-via-popup]] workflow (when extracted) or its
  prose equivalent today: pop an `AskUserQuestion` with
  Merged / Not yet / Cancelled options, don't end the turn
  waiting for a free-text reply.
- **Refuse the `--admin` / `--force` workaround.** If something
  is genuinely blocking a merge, fix the blocker, don't bypass
  the gate.

## Anti-patterns

- Pushing a "small fix" or doc tweak directly to `main` to skip
  the PR step.
- `git push --force` or `git push --force-with-lease` to `main`
  to rewrite shared history.
- Running `gh pr merge --admin` to skip a failing required check
  instead of fixing the check.
- Committing to `main` locally first, then "remembering" to make
  a branch — the branch should exist before the first edit.

## Related

- [[git-flow-session-end]]
- [[git-flow-branch-naming]]
- [[ask-merged-via-popup]]
