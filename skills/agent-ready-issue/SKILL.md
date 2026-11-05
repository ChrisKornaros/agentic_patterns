---
name: agent-ready-issue
description: "Writes a ticket an unattended agent can ship (What should change + a Done-when checklist), and the working contract the agent follows (stay inside the issue, state the reading it picked, say what it didn't verify). Use when handing work to a factory, a scheduled or background agent, or a board an agent pulls from."
version: 1.0.0
source: prompts/agent-ready-issue.md
tags: [workflow, agentic-optimization-research]
---

# Agent-ready issue

Use when an agent will do the work with nobody to ask. Draft the issue
from what the person wants, and ask them only for what you can't infer:
the outcome, and how they'd check it. Canonical text and the evidence
are in [prompts/agent-ready-issue.md](../../prompts/agent-ready-issue.md).

The issue:

```markdown
### What should change?

<The change in a few sentences: what, where, and why it matters. Name
the files or areas if you know them. If the change needs a file the
agent normally leaves alone, say so: "this issue asks for a
<file> change".>

### Done when

- [ ] <an observable result, checkable without you>
- [ ] <…>
- [ ] <the repo's check command> passes.
```

The working contract, for the repo's `CLAUDE.md` / `AGENTS.md` or the
agent's kickoff:

```
You're working on an issue with nobody around to answer questions.

- Treat its "Done when" as the checklist.
- Stay inside the issue. If you notice something else wrong, such as a
  stale doc or a weak test, don't fix it: note it in the PR so it can
  get its own issue.
- If something is unclear, pick the simplest reading that keeps the
  house rules, and say which reading you picked.
- Leave <protected paths> alone unless the issue asks for them.
- Don't add dependencies.
- Before you finish, run <check command>, and make sure every doc you
  touched still matches the code.
- In the PR say what changed, how to try it, "A reading I picked" for
  each judgment call, what you didn't verify, and end with
  `Closes #<n>`.
```

## Why this works

"Done when" carries a checkable goal through the hand-off. "A reading I
picked" is what surfaced the gap between Tessl's workshop ticket and the
code it described. Full rationale is in
[prompts/agent-ready-issue.md](../../prompts/agent-ready-issue.md).
