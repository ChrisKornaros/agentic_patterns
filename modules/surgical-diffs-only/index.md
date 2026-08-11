---
name: surgical-diffs-only
type: guardrail
scope: repo
lifecycle: experimental
dependencies: []
applies_when:
  - the task edits existing code (as opposed to greenfield files)
version: 1
---

# Surgical diffs only

## Rule

Every changed line must trace directly to the request. Touch only
what the task needs; match the existing style, naming, and comment
density of the file you're in, even where you'd have chosen
differently. Don't refactor, reformat, rename, or otherwise
"improve" adjacent code or comments while you're in there. Remove
only orphans **your own change created** (an import your deletion
unreferenced, a helper only your removed code called); pre-existing
dead code gets *mentioned in chat*, never deleted as a drive-by.

## Why

Adapted from the "Surgical changes" principle in
[Andrej Karpathy's coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills)
(via [the X post](https://x.com/karpathy/status/2015883857489522876)
that published them). Drive-by improvements feel like free value but
cost double: they bloat the diff the human must review (burying the
actual change in noise), and they make `git blame` and `git revert`
lie — reverting "the bug fix" now also reverts an unrelated rename.
The reviewer's trust depends on the diff meaning what the PR title
says. The [scope-guard skill](../../skills/scope-guard/SKILL.md)
names these temptations at task kickoff; this module is the
edit-time rule for the ones that survive into the diff anyway.

## How to apply

- **Apply the trace test before staging:** read each hunk of
  `git diff` and name the phrase in the request that demands it. A
  hunk with no phrase gets reverted or moved to a follow-up.
- **Match the file, not your taste.** Existing quote style,
  formatting quirks, naming scheme, comment density — consistency
  within the file beats global correctness of style.
- **Found dead code, a stale comment, or a refactor opportunity?
  Say so in chat** ("`foo()` at `bar.py:120` looks dead — follow-up
  to remove?") and leave it untouched in the diff.
- **Clean up only your own debris.** If your change orphaned an
  import, a fixture, or a helper, removing it *is* part of the
  request. If it was orphaned before you arrived, it isn't.

## Anti-patterns

- Reformatting a whole file (or letting a formatter do it) when the
  request changed three lines of it.
- Renaming variables, "modernizing" idioms, or rewriting comments in
  code the request didn't touch.
- Deleting pre-existing dead code "while I was in the file."
- Fixing an unrelated bug you noticed, silently, inside the same
  diff — report it; fix it in its own branch.
- A `fix: typo in error message` PR whose diff stat touches nine
  files.

## This rule is working if

- A reviewer can map **every hunk** in `git diff` to a phrase in the
  request.
- `git diff --stat` touches only files the request names or directly
  implies.
- "While I was here…" appears in chat as a follow-up proposal, never
  in the diff as a hunk.

## Related

- [[minimum-code-first]] — the sibling guardrail: that one bounds
  the *new code written*; this one bounds the *existing code
  touched*.
- [[assumptions-before-code]] / [[verifiable-goal-before-code]] —
  the rest of the per-edit discipline family.
- [[git-flow-branch-naming]] — the "unrelated fix gets its own
  branch" half of the discipline lands there.
- The [scope-guard skill](../../skills/scope-guard/SKILL.md) — the
  kickoff-time checklist that catches these temptations before
  editing starts.
