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

Two benefits:

1. Produces the artifact you'd want in the PR body anyway — paste the
   answer into the PR description.
2. Surfaces shaky understanding fast. If the agent can't articulate
   why it chose this approach, or names an "alternative" that's
   actually the same approach, that's a signal to dig deeper or ask
   for a rewrite.

The "as if I'm reviewing the PR cold" framing prevents the agent from
relying on what it already said earlier in the session. It has to
write a self-contained explanation.
