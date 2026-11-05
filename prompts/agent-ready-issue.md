# Agent-ready issue

Use when you hand a change to an agent that will work with nobody to
ask: a factory, a scheduled agent, a background subagent, or a ticket
someone else's agent picks up. There are two halves. The issue is what
you write. The working contract is what the agent follows.

## The issue

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

## The working contract

Paste it into the repo's `CLAUDE.md` or `AGENTS.md`, or into the
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

- **"Done when" is the goal the agent can check itself against.** It's
  [verifiable-goal-before-code](../modules/verifiable-goal-before-code/index.md)
  written into the ticket, so the goal survives the hand-off.
- **"A reading I picked" surfaces gaps between the ticket and the
  code.** In Tessl's workshop the issue said a game with no default
  export "gets no booth", but the code throws. The factory wrote what
  the code does, flagged the difference, and noted that changing it
  would be a one-line edit.
- **"Noticed, not changed" keeps scope and feeds the next ticket.**
  It's the same posture as [scope-guard.md](scope-guard.md), in the
  agent's words.
- **"What I didn't verify" keeps the PR honest.** The same PR said it
  hadn't run a review with the new lens, so the lens wasn't backtested.
  The next test showed why that mattered.
- **The issue is the unit of work everywhere downstream.** A label
  starts Tessl's factory on it, and their just-in-time board queue pulls
  it from **Ready** only when **In progress** has a free slot. A board
  of tickets in this shape is what a board-driven agent needs.

## Source

The issue shape comes from the carnival's issue templates. The working
contract comes from its `AGENTS.md` section "Working on an issue". Both
are from the "Build your own software factory" workshop, AI Native
DevCon NYC, 2026-11-02. Copies, plus the PR that picked a reading, are
in the vault:
[software-factory-workshop.md](https://github.com/ChrisKornaros/vault/blob/main/notes/software/agentic-engineering/ai-devcon-nyc-2026/software-factory-workshop.md).
