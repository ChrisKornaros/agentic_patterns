---
name: constraint-check
description: "Checks a proposed change against the load-bearing constraints named in CLAUDE.md / REQUIREMENTS §2 before it lands. Use when a change touches a single-writer DB, deploy invariant, threading model, or other stated invariant."
version: 1.0.0
source: prompts/constraint-check.md
tags: [guardrail, agentic-optimization-research]
---

# Constraint check

Use before any change that touches the load-bearing constraint —
DuckDB single-writer, deploy invariants, threading model, anything
named in `CLAUDE.md` or `REQUIREMENTS_V<N>.md` §2.

```
Here's the change I'm about to make: <one-paragraph description>.

Does it violate the <name-the-constraint> constraint, or any other
constraint named in CLAUDE.md or REQUIREMENTS_V<N>.md §2?

If yes, explain how. If no, confirm and move on.
```

## Why this works

Constraint violations are the most expensive bug class in
agent-assisted development — they don't trip smoke, they only show up
in production. "Confirm and move on" tells the agent that "no
violation" is a complete answer, avoiding hedged rationalizations.
Full rationale in [prompts/constraint-check.md](../../prompts/constraint-check.md).
