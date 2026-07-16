---
name: phase-kickoff
description: "Opens a roadmap-phase session with an orient → plan → confirm loop before any code — what gets built, files touched, expected smoke output, end-of-phase shape. Use when starting a new roadmap phase. Shims the phase-kickoff module."
version: 1.0.0
source: prompts/phase-kickoff.md
module: phase-kickoff
tags: [workflow, agentic-optimization-research]
---

# Phase kickoff

Use at the start of a session implementing a roadmap phase. Canonical
text is the [phase-kickoff](../../modules/phase-kickoff/index.md) module.

```
We're starting Phase <X> from REQUIREMENTS_V<N>.md. Read §<phase-section>
(the phase spec) and §2 (the load-bearing constraint), then summarize
back to me:

  (1) what you're going to build,
  (2) which files you'll touch,
  (3) what the smoke output should look like when it's done,
  (4) what you'll do at end of phase — confirm: branch, code,
      smoke green, commit, push, gh pr create, then AskUserQuestion
      for the post-merge action (no idle "ready to commit?" turn).

If this phase touches a new external substrate (a third-party API,
a data source you haven't used before, a service with rate limits
or paid metering), run /substrate-preflight first.

Don't write code yet.
```

## Why this works

Forces an explicit orient → plan → confirm → implement loop; asking
for the expected smoke output catches "building X but actually Y"
mismatches before they cost a session. Full rationale in the
[phase-kickoff module](../../modules/phase-kickoff/index.md) /
[prompts/phase-kickoff.md](../../prompts/phase-kickoff.md).
