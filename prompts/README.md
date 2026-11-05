# Prompts

Reusable prompt templates for common workflow moments. Extracted from
the master case study §9. Each prompt is a short markdown file with a
template body — copy, fill the angle-bracket placeholders, paste into
your session.

## When to reach for these

| Moment | Prompt |
|---|---|
| Opening a session — sync, read the handoff, plan before code | [session-start.md](session-start.md) |
| Starting work on a phase | [phase-kickoff.md](phase-kickoff.md) |
| Ending a session that shipped something | [session-wrapup.md](session-wrapup.md) |
| Reviewing a diff or PR | [tight-code-review.md](tight-code-review.md) |
| Reviewing a PR where every finding should be real, or writing a house-rules review lens | [lens-review.md](lens-review.md) |
| Checking whether docs, rules or tests have drifted, report-only | [maintenance-sweep.md](maintenance-sweep.md) |
| Handing a ticket to an agent that will work with nobody to ask | [agent-ready-issue.md](agent-ready-issue.md) |
| Trying a third-party agent tool, plugin or CLI | [tool-trial-sandbox.md](tool-trial-sandbox.md) |
| About to do something that might violate a constraint | [constraint-check.md](constraint-check.md) |
| Before committing a phase to a third-party substrate (API, data source, vendor service) | [substrate-preflight.md](substrate-preflight.md) |
| Bootstrapping a fresh host repo with the canonical modules | [bootstrap-host-repo.md](bootstrap-host-repo.md) — or `/bootstrap-repo` slash command (shim: `bootstrap-repo`) |
| Auditing an existing host repo against the canonical modules (read-only proposal) | [retrofit-audit.md](retrofit-audit.md) — or `/audit-repo` slash command (shim: `audit-repo`) |
| Kicking off the `content_manager` project (one-time, day-one checklist) | `content-manager-kickoff` |
| Asking the agent not to scope-creep | [scope-guard.md](scope-guard.md) |
| You don't fully follow a change the agent made | [explain-back.md](explain-back.md) |
| Debugging — before any fix | [minimal-repro.md](minimal-repro.md) |
| Starting a learning session (agent as tutor, not producer) | `tutor-kickoff` |
| Stuck on a practice problem — asking for a hint, not the answer | `hint-ladder` |

## Conventions

- Angle brackets `<like-this>` are placeholders. Fill them in before
  sending.
- The prompts are deliberately short. They're meant to be pasted at
  the start of a turn, not as the whole turn.
- Each prompt has a "why this works" note at the bottom. Read once;
  ignore on subsequent uses.

## Source

These are condensed from the master case study at
`playbook` §9.
That file has the longer rationale.
