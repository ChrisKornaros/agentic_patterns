---
name: lens-review
description: "Reviews a diff/PR through five named lenses (correctness, security, scale, maintainability, the repo's own house rules), each with a threshold and a do-not-report list, and reports consequences as the code makes them. Use for a thorough pre-merge review that stays quiet unless something is real, or to write and test a house-rules lens for a repo."
version: 1.0.0
source: prompts/lens-review.md
tags: [review, agentic-optimization-research]
---

# Lens review

Use for a pre-merge review where every finding should be real. Run it
in a session or subagent that didn't write the change. Canonical text,
the house-rules lens template and the evidence are in
[prompts/lens-review.md](../../prompts/lens-review.md).

```
Review <branch | PR # | diff> through these lenses, one pass per lens:

  1. Correctness and data integrity: edge cases in changed logic; writes
     that can be lost, duplicated or left half-finished; contracts at a
     boundary whose two sides ship separately.
  2. Security and privacy: an untrusted input that reaches a sensitive
     operation, or data disclosed to someone not entitled to it. Name
     the actor, the input and the sink, or don't report it.
  3. Scale and resilience: cost that grows with load or data; what a
     slow, duplicate or missing response does.
  4. Maintainability: a name, comment or type that promises what the
     code doesn't do; a helper the codebase already has.
  5. House rules: the rules in the CLAUDE.md / AGENTS.md chain that
     governs the changed files, from the repo root down.

Report only what crosses a lens's threshold in a realistic input or
state. Don't report what lint, types or tests already enforce, style
preferences, or code the change didn't touch.

For each finding: file and line, the input or state that triggers it,
the consequence as the code makes it (not a worse one), the smallest
fix, and "should fix" or "advisory".

End with a count per lens of what you considered and dropped, and why:
low confidence, pre-existing, not caused by this change, or below
threshold. "No findings" is a fine result.
```

To test a lens, seed one break on a throwaway branch without telling
the reviewer it's allowed, and check the lens reports it.

## Why this works

A threshold and a "do not report" list keep a reviewer quiet and right:
in this shape, Tessl's lenses gave 2 findings across 11 PRs, both real.
"As the code makes it" stops severity inflation. Full rationale and the
house-rules lens template are in
[prompts/lens-review.md](../../prompts/lens-review.md).
