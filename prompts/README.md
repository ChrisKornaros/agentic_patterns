# Prompts

Reusable prompt templates for common workflow moments. Extracted from
the master case study §9. Each prompt is a short markdown file with a
template body — copy, fill the angle-bracket placeholders, paste into
your session.

## When to reach for these

| Moment | Prompt |
|---|---|
| Starting work on a phase | [phase-kickoff.md](phase-kickoff.md) |
| Ending a session that shipped something | [session-wrapup.md](session-wrapup.md) |
| Reviewing a diff or PR | [tight-code-review.md](tight-code-review.md) |
| About to do something that might violate a constraint | [constraint-check.md](constraint-check.md) |
| Before committing a phase to a third-party substrate (API, data source, vendor service) | [substrate-preflight.md](substrate-preflight.md) |
| Bootstrapping a fresh host repo with the canonical modules | `bootstrap-host-repo` — or `/bootstrap-repo` slash command (shim: `bootstrap-repo`) |
| Auditing an existing host repo against the canonical modules (read-only proposal) | `retrofit-audit` — or `/audit-repo` slash command (shim: `audit-repo`) |
| Kicking off the `content_manager` project (one-time, day-one checklist) | `content-manager-kickoff` |
| Asking the agent not to scope-creep | [scope-guard.md](scope-guard.md) |
| You don't fully follow a change the agent made | [explain-back.md](explain-back.md) |
| Debugging — before any fix | [minimal-repro.md](minimal-repro.md) |

## Conventions

- Angle brackets `<like-this>` are placeholders. Fill them in before
  sending.
- The prompts are deliberately short. They're meant to be pasted at
  the start of a turn, not as the whole turn.
- Each prompt has a "why this works" note at the bottom. Read once;
  ignore on subsequent uses.

## Source

These are condensed from the master case study at
case-studies/product-use-tracker/playbook.md §9.
That file has the longer rationale.
