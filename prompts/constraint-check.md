# Constraint check

Use before any change that touches the load-bearing constraint —
DuckDB single-writer, deploy invariants, threading model, anything
that's been named in `CLAUDE.md` or `REQUIREMENTS_V<N>.md` §2.

```
Here's the change I'm about to make: <one-paragraph description>.

Does it violate the <name-the-constraint> constraint, or any other
constraint named in CLAUDE.md or REQUIREMENTS_V<N>.md §2?

If yes, explain how. If no, confirm and move on.
```

## Why this works

Constraint violations are the most expensive class of bug in
agent-assisted development — they don't trip smoke; they only show
up in production. A 30-second explicit check before each
constraint-adjacent change is cheap insurance.

The phrasing "confirm and move on" matters: it tells the agent that
"no violation" is a complete, acceptable answer. Without that, you
get longer rationalizations that hedge.
