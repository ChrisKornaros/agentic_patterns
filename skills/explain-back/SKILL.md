---
name: explain-back
description: "Explains a just-made change as a cold PR review — why this approach, alternatives considered, test plan, non-obvious invariants. Use when you've accepted a change you don't fully understand and want it justified before moving on."
version: 1.0.0
source: prompts/explain-back.md
tags: [review, agentic-optimization-research]
---

# Explain back

Use after Claude makes a change you don't fully understand.

```
Explain the change you just made as if I'm reviewing the PR cold. Walk
me through:

  - why this approach,
  - what alternatives you considered,
  - what the test plan should be.

If there's a non-obvious invariant the code relies on, name it.
```

## Why this works

Produces the artifact you'd want in the PR body anyway, and surfaces
shaky understanding fast — if the agent can't articulate why it chose
this approach (or names a fake "alternative"), dig deeper. The "cold
review" framing forces a self-contained explanation. Full rationale in
[prompts/explain-back.md](../../prompts/explain-back.md).
