# Phase kickoff

Use at the start of a session that's implementing a roadmap phase.

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
or paid metering), run substrate-preflight.md first.

Don't write code yet.
```

## Why this works

Forces an explicit orient → plan → confirm → implement loop. Without
it, Claude tends to skip to code, sometimes against the wrong premise.
Asking for the expected smoke output catches "I think I'm building X
but actually I'm building Y" mismatches before they cost a session.

Step (4) was added 2026-05-23 after the v3 cycle revealed that
"ready to commit?" stalls cost a round-trip per phase. Pre-committing
to the auto-PR shape at kickoff makes the wrap-up implicit; the agent
just executes the script.

Cross-ref: `02-workflow-patterns` §`Updated/1`.
