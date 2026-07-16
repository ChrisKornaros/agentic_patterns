# Scope guard

Use at the start of a task to prevent the most common
Claude-coding failure mode: scope creep disguised as helpfulness.

```
This task is: <describe in one sentence>.

Before you start, list anything you're tempted to also do (refactor,
cleanup, generalization, "while we're here" fixes). For each, tell me
whether it belongs in this PR or in a follow-up.

Default to follow-up.
```

## Why this works

Asking the agent to *name* the temptations forces them out of the
implementation and onto a list you can decide on. "Default to
follow-up" sets the bias correctly — most extras don't belong in the
current PR, and the agent will otherwise default toward including them
because they look "easy."

When something does genuinely belong in the current PR (the change
won't compose without it), the agent will say so explicitly and you
can approve. The decision is visible instead of hidden in the diff.
