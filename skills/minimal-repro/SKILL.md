---
name: minimal-repro
description: "Forces a minimal reproduction plus an encoded expected-behavior check before any fix is proposed. Use when a bug is reported and you're tempted to jump straight to a fix."
version: 1.0.0
source: prompts/minimal-repro.md
tags: [workflow, agentic-optimization-research]
---

# Minimal repro (debugging)

Use when a bug has been reported, **before** any fix is written.

```
The bug is: <description, including how you noticed it>.

Before writing any fix:

  (1) Write the minimal reproduction — a single command or file edit
      that triggers it.
  (2) Tell me what the *expected* behavior is and where in the code
      that expectation is encoded.
  (3) Only then propose the fix.
```

## Why this works

Skipping the repro is the single most common debugging failure mode —
without one you "fix" something that wasn't broken. Step (2) catches
the case where there's no encoded expectation, meaning the bug is
undefined behavior needing a spec decision first. Full rationale in
[prompts/minimal-repro.md](../../prompts/minimal-repro.md).
