# skills/

Vendorable Claude Code **skills** — the runtime surface for the
reusable prompts in [../prompts/](../prompts/). A prompt only helps if
you remember it exists and paste it; a skill is auto-surfaced
mid-session (invoked as `/<name>` or model-selected by its
`description`). This folder promotes the highest-friction-relief
prompts into that shape, per
`08-pre-content-manager-optimization` track C1.

The layout mirrors the Hermes *writing*-profile skills
(`skills`):
one directory per skill, each holding a single `SKILL.md`.

## The reader

- **A future host repo's bootstrap.** `/bootstrap-repo` (via
  `install-modules`)
  vendors a chosen skill into the host's
  `.claude/skills/<name>/SKILL.md` alongside the canonical module it
  shims (so a `prompt`-type module never lands without its runnable
  surface, and vice versa). A skill that backs a module declares it in
  frontmatter (`module: <name>`); the install script auto-pairs on
  that field, and standalone skills are vendored with `--skill <name>`.
  This is C1 part 2, now live — see
  `VENDORING` §9.
- **Chris's own machine.** The two highest-value skills are also
  wired as live `/`-commands in
  `commands` —
  `scope-guard`, `session-wrapup`, and its read-side mirror
  `session-start` — so they fire this session forward without a per-repo
  install.

## Three layers, one source of truth

A reusable convention now exists at up to three layers. They are not
duplicates — each has a distinct job:

| Layer | File | Job |
|---|---|---|
| **Canonical text** | [../prompts/`<name>`.md](../prompts/) (or a `prompt`-type [../modules/](../modules/) entry) | The full rationale — *why this works*, evidence links, the history of the prompt's shape. The human-readable home. |
| **Runtime skill** | `skills/<name>/SKILL.md` | The operative block, in a form the agent can run mid-session. Frontmatter `source:` points back at the canonical text. |
| **Machine-global command** | `../dotfiles/.claude/commands/<name>.md` | Chris's personal live `/`-command shim (only the highest-value ones — currently `scope-guard`, `session-wrapup`, `session-start`). |

**What a skill inlines and what it doesn't.** A `SKILL.md` inlines the
short *operative* prompt block (so it runs without a network round-trip
to the canonical file) and links the canonical prompt via `source:` for
the full *Why this works* rationale. It does **not** copy the rationale
prose — that stays single-homed in `prompts/`. This matches the Hermes
`SKILL.md` precedent and keeps the canonical "why" un-duplicated.

## Skills in this repo

| Skill | `/`-command | Canonical source | Backing module |
|---|---|---|---|
| [scope-guard](scope-guard/SKILL.md) | `/scope-guard` | [prompts/scope-guard.md](../prompts/scope-guard.md) | — |
| [constraint-check](constraint-check/SKILL.md) | `/constraint-check` | [prompts/constraint-check.md](../prompts/constraint-check.md) | — |
| [session-wrapup](session-wrapup/SKILL.md) | `/session-wrapup` | [prompts/session-wrapup.md](../prompts/session-wrapup.md) | [git-flow-session-end](../modules/git-flow-session-end/index.md) |
| [session-start](session-start/SKILL.md) | `/session-start` | [prompts/session-start.md](../prompts/session-start.md) | [session-handoff](../modules/session-handoff/index.md) |
| [phase-kickoff](phase-kickoff/SKILL.md) | `/phase-kickoff` | [prompts/phase-kickoff.md](../prompts/phase-kickoff.md) | [phase-kickoff](../modules/phase-kickoff/index.md) |
| [substrate-preflight](substrate-preflight/SKILL.md) | `/substrate-preflight` | [prompts/substrate-preflight.md](../prompts/substrate-preflight.md) | [substrate-preflight](../modules/substrate-preflight/index.md) |
| [tight-review](tight-review/SKILL.md) | `/tight-review` | [prompts/tight-code-review.md](../prompts/tight-code-review.md) | [tight-code-review](../modules/tight-code-review/index.md) |
| [explain-back](explain-back/SKILL.md) | `/explain-back` | [prompts/explain-back.md](../prompts/explain-back.md) | — |
| [minimal-repro](minimal-repro/SKILL.md) | `/minimal-repro` | [prompts/minimal-repro.md](../prompts/minimal-repro.md) | — |
| plane-board-ops | — | `CONVENTIONS` | — (sources a tool doc, not a prompt) |

The `session-wrapup`, `session-start`, and `phase-kickoff` skills shim
modules that already exist; `substrate-preflight` and `tight-review` now
do too — their backing modules were extracted in
`roadmap/10` A4, closing the
"C1 surfaces the gap A1 fills" loop the roadmap named, so the install
script auto-pairs each of those five skills onto its module. `plane-board-ops` is the one skill whose `source:` is a **tool
doc** (`CONVENTIONS`) rather
than a `prompts/` entry — the canonical "why" for board conventions lives
with the tool, and the skill inlines the operative model; it backs no
module yet (extraction follows once the conventions settle).

## SKILL.md shape

```markdown
---
name: <kebab-case, matches the directory>
description: "One line — what it does + when to reach for it. Used for surfacing."
version: 1.0.0
source: prompts/<name>.md
module: <backing-module-name>   # optional — present only if this skill shims a module; the install script auto-pairs on it
tags: [workflow|guardrail|review, agentic-optimization-research]
---

# <Title>

Use when <trigger>.

​```
<the operative prompt block — what the agent should do>
​```

## Why this works

<one or two sentences; link the canonical source for the full rationale>
```

## Verify

No compiler yet. Manual checks:

- Every skill directory has a `SKILL.md` with `name:` matching the
  directory and a `source:` that resolves.
- The operative block is present (a skill with only prose doesn't run).
- The canonical `prompts/<name>.md` (or backing module) still exists.
- If a skill declares `module: <name>` in frontmatter, that module
  exists under [../modules/](../modules/) — the install script
  auto-pairs the skill onto it, so a dangling name silently drops the
  pairing.

## Related

- [../prompts/README.md](../prompts/README.md) — the canonical prompt library
- [../modules/README.md](../modules/README.md) — portable instruction modules
- `08-pre-content-manager-optimization` — the C1 track this folder implements
- `skills` — the `SKILL.md` precedent
