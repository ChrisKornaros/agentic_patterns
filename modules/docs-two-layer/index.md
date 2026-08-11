---
name: docs-two-layer
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - 01-documentation-stack.md
  - playbook.md#2-the-documentation-stack
version: 1
---

# Docs in two layers

## Rule

Split a repo's top-level docs by *reader*, never merge them into one
file. `README.md` is for humans (what is this, how do I run it, what
does it do); `CLAUDE.md` is for the agent (what must I not violate,
where do things live, how do I verify). When a project is implemented
from a spec, the requirements doc splits the same way: a prose
`REQUIREMENTS_V<N>.md` (rationale humans review and argue with) and a
dense, declarative `REQUIREMENTS_AI.md` contract the agent implements
from without re-deriving the reasoning. Keep the split files in sync, or
don't split.

## Why

One `README.md` that tries to onboard humans, brief the agent, list the
gotchas, and document the API does all of them badly because the readers
have different needs
(`01-documentation-stack`,
case study §2).
The agent's biggest waste is re-deriving state every session; a prose
spec forces it to re-infer the invariants each time, while a declarative
contract states them once, by id, so a diff can be checked against each.
The `content_manager` project authored both halves before any code — a
prose `requirements.md` and an AI-optimized `requirements_ai.md` with
numbered invariants, a constraint table, and a risk register — and is
the worked instance the pattern generalized from.

## How to apply

- **Two top-level docs, always:** `README.md` (humans) and `CLAUDE.md`
  (agent). Don't fold agent rules into the README or human onboarding
  into `CLAUDE.md`.
- **Route by question:** "what/how-do-I-run" → README; "what-must-I-not-
  violate / where-things-live / how-to-verify" → CLAUDE.md.
- **Split the spec only when re-derivation is expensive.** Below a few
  invariants and integrations, keep a single `REQUIREMENTS_V<N>.md` —
  the split earns its keep once the invariant count and integration
  surface make re-inference costly.
- **The prose file is where decisions are made; the contract is
  re-synced from it.** A stale contract is worse than a single file
  because the agent trusts it.

## Anti-patterns

- A single `README.md` carrying human onboarding, agent guardrails, and
  the gotcha list at once.
- An `REQUIREMENTS_AI.md` that drifts from its prose source — the agent
  implements the stale contract as if it were current.
- Splitting a tiny project's spec into two files nobody keeps in sync,
  manufacturing drift where a single doc would have held.

## Related

- [[adr-per-major-decision]] — the decision log the prose requirements
  layer points back to.
- [[status-emoji-discipline]] — the status vocabulary the human-facing
  docs and roadmap use to stay legible.
