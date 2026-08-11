---
name: git-flow-branch-naming
type: guardrail
scope: repo
lifecycle: stable
dependencies:
  - git-flow-no-direct-main
evidence:
  - git-workflow.md#branch-naming
  - playbook.md#141-workflow-rules-codified-mid-cycle
applies_when:
  - repo follows GitHub Flow (sessions = one branch = one PR)
version: 1
---

# Git Flow — branch naming

## Rule

Every feature branch is named so the slug *is* the pointer back to
the planning artifact that scoped it. Use one of these prefixes,
branching from `main`:

- `feat/phase-<a-g>-<slug>` — a roadmap phase
- `feat/e<N>-<slug>` — an enhancement (mirrors `ENHANCEMENTS.md` E#)
- `fix/<N>-<slug>` — a bug fix (mirrors `BUGFIXES.md` #)
- `chore/<slug>` — infrastructure, deps, tooling
- `docs/<slug>` — documentation only

A repo without phase/enhancement logs uses the bare `feat/<slug>` /
`fix/<slug>` / `chore/<slug>` / `docs/<slug>` forms. The point is the
*prefix discipline*, not the phase numbers.

## Why

The branch name is the cheapest possible link between the work and
the artifact that justified it. When a session opens on
`feat/phase-c-notifier`, the agent immediately knows to read the
phase-C section of the roadmap — no archaeology, no asking. The
product-use-tracker case study
(§1.4.1)
ran this convention across its whole lifecycle; the prefix told
every cold session which tracking doc to load, and the `fix/<N>` /
`feat/e<N>` numbers reconciled the branch against the
`BUGFIXES.md` / `ENHANCEMENTS.md` row it closed in the same PR.

## How to apply

- **Pick the prefix from the work's *source*, not its size.** A
  one-line fix that closes `BUGFIXES.md` #7 is `fix/7-<slug>`, not
  `chore/`.
- **Branch before the first edit.** This pairs with
  [[git-flow-no-direct-main]] — `git switch -c <branch>` runs while
  `HEAD` is still on a clean `main`.
- **Keep the slug short and human-readable** — 2–4 words,
  kebab-case, describing the change (`feat/e12-csv-export`, not
  `feat/e12-stuff`).
- **Match the number to the log row** for `fix/<N>` and `feat/e<N>`
  so the branch, the PR, and the closed log entry all line up.

## Anti-patterns

- A generic `feat/updates` or `chore/misc` branch that says nothing
  about what it carries — the slug stops being a pointer.
- Numbering a `fix/` branch with a made-up number that doesn't
  match any `BUGFIXES.md` row.
- Using `feat/` for a pure docs change (or `docs/` for code) —
  the prefix is the first thing a reviewer reads to set expectations.
- Renaming a branch mid-session so it no longer matches the PR /
  log row it was created to close.

## Related

- [[git-flow-no-direct-main]]
- [[git-flow-session-end]]
