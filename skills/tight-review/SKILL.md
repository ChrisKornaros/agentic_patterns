---
name: tight-review
description: "Reviews a diff/PR for structural issues first — behavior changes, smoke gaps, missed call-site updates — holding style nits and improvements until after. Use when you want a focused correctness review of a change before merging."
version: 1.0.0
source: prompts/tight-code-review.md
module: tight-code-review
tags: [review, agentic-optimization-research]
---

# Tight code review

Use to get a focused review of a diff or PR without burying the
structural issues under style nits. Canonical text is the
[tight-code-review](../../modules/tight-code-review/index.md) module.

```
Read this diff: <branch | PR # | file path>. Don't suggest
improvements yet. First, tell me:

  (1) what behavior changed,
  (2) what could break that isn't covered by smoke,
  (3) any place where the change should also have touched another file
      but didn't.

After I respond, then suggest improvements if you want.
```

## Why this works

"Don't suggest improvements yet" is load-bearing — without it, the
structural issue (a half-applied refactor, a missing call-site update)
gets buried under "prefer f-strings here." The three questions surface
the high-value review content first. Full rationale in the
[tight-code-review module](../../modules/tight-code-review/index.md) /
[prompts/tight-code-review.md](../../prompts/tight-code-review.md).
