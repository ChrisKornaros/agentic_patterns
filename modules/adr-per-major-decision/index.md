---
name: adr-per-major-decision
type: workflow
scope: repo
lifecycle: experimental
dependencies: []
evidence:
  - 03-design-patterns.md#the-seven-patterns
  - REQUIREMENTS_AI.template.md
applies_when:
  - a decision is hard to reverse, shapes downstream architecture, or is likely to be re-questioned later
version: 1
---

# Record a short ADR for every major, hard-to-reverse decision

## Rule

When a decision is load-bearing — it constrains the architecture, is
expensive to reverse, or will predictably get re-litigated ("why
DuckDB and not Postgres?", "why upload-as-draft for TikTok?") — write
a short Architecture Decision Record before moving on. An ADR is a
numbered, dated, append-only markdown file under `docs/adr/` (or the
project's equivalent) with four parts: **context** (the forces),
**decision** (what was chosen), **status** (proposed / accepted /
superseded), and **consequences** (what this commits us to). ADRs are
immutable once accepted — a reversal is a *new* ADR that supersedes
the old one, not an edit. Minor, easily-reversed choices don't need
one; the bar is "hard to undo or sure to be re-asked."

## Why

This repo already pushes "make decisions derivable and cited": name
the load-bearing constraint and make every choice visibly flow from
it, and pick one canonical place for a fact and document it
(`03-design-patterns` §The seven patterns,
patterns 2 and 4). The dual-spec requirements pattern takes the same
shape for invariants — the AI-facing spec records numbered, stable
invariants and a risk register rather than prose that drifts
(`REQUIREMENTS_AI.template`).
An ADR is the *per-decision* version of that discipline: it captures
the reasoning at the moment of choice, so the "why" survives past the
session that decided it.

The `content_manager` project is the forcing case. Its requirements
carry a list of "key decisions / hard constraints (**do not
relitigate**)" — TikTok-is-hybrid-by-design, DuckDB-not-SQLite,
Bitwarden-not-Keychain, YouTube-as-Brand-Account, ≤5 hashtags, ≤1
post/platform/day. Each of those is exactly an ADR: a constraint that
was argued once, is costly to revisit, and that a future session (or
agent) will otherwise re-open from zero. Without a record, "do not
relitigate" depends on memory; with one, the agent reads the ADR and
moves on.

## How to apply

- **Trigger:** you're about to commit to something hard to reverse —
  a storage engine, an auth model, a vendor, a data-flow direction, a
  cross-cutting constraint. Before you build on it, write the ADR.
- **File:** `docs/adr/NNNN-short-slug.md`, zero-padded sequential
  number, kebab-case slug. Append-only — never renumber, never delete.
- **Shape:** Context → Decision → Status → Consequences. Keep it to a
  screen; an ADR is a paragraph each, not a design doc.
- **Reversing:** add a new ADR that states the change and marks the
  old one `superseded by NNNN`; flip the old one's status to
  `superseded`. The history stays legible.
- **Link from the spec:** the requirements / `CLAUDE.md` "do not
  relitigate" constraints each cite their ADR, so the rule and its
  rationale are one click apart.
- **Don't over-apply:** a reversible implementation choice (which
  helper function, which test name) is not an ADR. The cost of the
  record should be paid back by the cost of re-deciding.

## Anti-patterns

- Burying the decision and its rationale in a commit message or a
  Slack/chat thread, where it's unsearchable six weeks later and a new
  session re-derives (or contradicts) it.
- Editing an accepted ADR in place when the decision changes. The
  record of *what we used to think and why we moved* is the point;
  supersede, don't overwrite.
- Writing an ADR for every trivial choice until the folder is noise
  and nobody reads it. Reserve it for load-bearing, hard-to-reverse
  calls.
- A "decision log" that's just a flat list of one-liners with no
  context or consequences — it records *that* a choice was made, not
  enough to evaluate whether to revisit it.
- Letting the requirements doc and the ADRs disagree. The ADR is the
  reasoning; the spec's constraint cites it. They move together.

## Related

- [[ask-merged-via-popup]] — both are "capture the decision at the
  decision point" workflows; this one for architecture, that one for
  the merge gate.
- [[duckdb-default-store]] — a default that, when overridden, is
  exactly the kind of choice that earns an ADR ("we graduated to
  Postgres because…").
- [[external-api-adapter-boundary]] — vendor choices behind an
  adapter are common ADR subjects ("why this SDK, this auth model").
