---
name: tight-code-review
type: prompt
scope: task
lifecycle: experimental
dependencies: []
applies_when:
  - reviewing a diff or PR for correctness before merge
version: 1
---

# Tight code review

## Rule

When reviewing a diff or PR, surface the *structural* issues before any
style feedback. Ask the reviewer (human or agent) three questions first
— what behavior changed, what could break that smoke doesn't cover, and
where the change should have touched another file but didn't — and
explicitly hold all "improvement" suggestions until those are answered.

## Why

The "don't suggest improvements yet" clause is load-bearing. Without it,
a review opens with a laundry list of style nits ("prefer f-strings
here") and the high-value finding — a half-applied refactor, a missing
call-site update, an untested edge — gets buried under the noise.
Forcing the review through three specific structural questions first
puts the things that actually break production at the top, where the
author reads them. Full rationale in
[prompts/tight-code-review.md](../../prompts/tight-code-review.md). Kept
`experimental` until this repo's own review sessions provide the
case-study evidence.

## How to apply

Paste this, filling in the diff reference:

```
Read this diff: <branch | PR # | file path>. Don't suggest
improvements yet. First, tell me:

  (1) what behavior changed,
  (2) what could break that isn't covered by smoke,
  (3) any place where the change should also have touched another file
      but didn't.

After I respond, then suggest improvements if you want.
```

- Answer all three before the first improvement suggestion. If the
  reviewer leads with style, re-prompt with "Answer (2) and (3) first."
- Question (3) is the highest-leverage one — missed call-site updates
  are the failure smoke is least likely to catch.

## Anti-patterns

- Opening a review with style/naming nits while a missing call-site
  update sits unmentioned three hunks down.
- Treating "what could break" as answered by "smoke passes" — the
  question is specifically about what smoke *doesn't* cover.
- Bundling the three structural answers and the improvement list into
  one undifferentiated dump, so the author can't tell which matters.

## This rule is working if

- Every review's first response is the three structural answers, no
  style feedback above them.
- Missed call-site updates and smoke gaps are named before f-string
  preferences.

## Related

- [[surgical-diffs-only]] — the edit-time discipline this review checks
  for: question (1) maps each hunk to a behavior change.
- [[smoke-before-commit]] — question (2) presumes a smoke exists to
  reason about its blind spots.
- The [scope-guard skill](../../skills/scope-guard/SKILL.md) — the
  kickoff-time sibling; this is the merge-time one.
