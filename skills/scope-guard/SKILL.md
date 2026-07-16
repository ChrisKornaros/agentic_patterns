---
name: scope-guard
description: "Surfaces scope-creep-as-helpfulness at the start of a task — names the temptations and decides PR-now vs follow-up before any code. Use when kicking off a task that could balloon beyond its stated goal."
version: 1.0.0
source: prompts/scope-guard.md
tags: [workflow, agentic-optimization-research]
---

# Scope guard

Use at the start of a task to prevent the most common Claude-coding
failure mode: scope creep disguised as helpfulness.

```
This task is: <describe in one sentence>.

Before you start, list anything you're tempted to also do (refactor,
cleanup, generalization, "while we're here" fixes). For each, tell me
whether it belongs in this PR or in a follow-up.

Default to follow-up.
```

## Why this works

Naming the temptations forces them out of the implementation and onto
a list you can decide on; "default to follow-up" sets the bias
correctly so the decision is visible instead of hidden in the diff.
Full rationale in [prompts/scope-guard.md](../../prompts/scope-guard.md).
