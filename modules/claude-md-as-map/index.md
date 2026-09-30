---
name: claude-md-as-map
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - 12-progressive-disclosure-context-slimming.md
  - RESULT.md
  - RESULT.md
  - 2026-08-20-h5-remeasure/README.md
applies_when:
  - the host has always-loaded agent context (CLAUDE.md / AGENTS.md chain) that has grown past ~200 lines, or is being written fresh
version: 1
---

# CLAUDE.md as map, not territory

## Rule

The always-loaded agent context (root `CLAUDE.md` plus any ancestor
files) is a **map**: short orientation plus pointers. Detail lives in
lazily-loaded surfaces — modules, skills, subdirectory `CLAUDE.md`,
path-scoped `.claude/rules/`, linked notes. Two hard constraints:

1. **Target under ~200 lines** for the whole eager chain, and never
   cut a rule to get there — every removed line must be a duplicate,
   history, or rationale, *or* move to a lazy surface **with a trigger
   of matched strength**.
2. **A bare link is not a trigger.** Before demoting a rule, place it
   on the trigger-strength ladder: must-happen → hook; relevant-in-a
   -situation → skill description or path-scoped rule; background →
   linked note. A must-happen rule demoted to a plain link **will be
   executed from memory until it silently isn't** — measured, not
   assumed (see Why).

## Why

Ballooning eager context saturates the instruction budget before the
first prompt (instruction-following degrades roughly linearly with
instruction count — IFScale, arXiv 2507.11538; Anthropic's memory docs
now say target <200 lines per CLAUDE.md). The slimming pattern was
executed and then **measured** as roadmap/12 + experiment H5 in the
source repo:

- Outcome: the eager chain fell 403 → 225 lines across two repos and
  deterministic adherence incidents *fell* (1.42 → 0.90 and
  1.24 → 0.59 per session) — the map did not regress behavior
  (H5 RESULT).
- Mechanism: **pointers without decision-time triggers do not get
  read.** Classes backed by a hook or an injected file were followed
  80–91% of the time; bare-link classes ran 11–33%. Adherence held
  anyway because hooks, handoffs, and priors carried the rules — but
  that is insurance the map author must *build*, not assume. This is
  H1's finding
  (a passive pointer produced zero adoption until a hook surfaced it)
  recurring at the map level.
- Confirmation, one iteration later: strengthening the two failing
  classes with a tier-1 hook lifted follow rates 40%→67% and 33%→91%
  (2026-08-20 re-measure)
  — before/after evidence for the trigger-strength ladder at both
  ends. The one class still low sat behind a rules file that mostly
  never injected on the host clone: a trigger you don't verify as
  *deployed* is a bare link with extra steps.

## How to apply

- **Audit by disposition table.** For each section of the current
  file: keep (orientation, house rules that fit in one line each),
  point (duplicated workflow text → the canonical module/skill),
  demote (rationale, history → notes/CHANGELOG), or delete
  (stale). Record the table in the slimming PR.
- **Pair every demotion with its trigger** from the ladder before
  cutting the inline text, and prefer the strongest trigger the rule's
  failure cost justifies: hooks for must-happen loops, skill
  descriptions / `.claude/rules/` with `paths:` globs for
  situation-scoped rules, plain links only for
  available-when-curious background.
- **Load-mechanics literacy:** `@path` imports are eager (save
  nothing); plain links are lazy; subdirectory `CLAUDE.md` and
  `.claude/rules/` load on file touch; skills load frontmatter-only
  until triggered. Keep pointer targets one level deep and give any
  reference file >100 lines a table of contents.
- **Measure after slimming** where the host has the rig for it:
  deterministic incident checks pre/post (commits to main, missing
  docs-sync, banned commands) and pointer-follow rates. Where it
  doesn't, at minimum list which rules moved to which surface, and
  watch the next sessions for the moved rules being violated.

## Anti-patterns

- Slimming by deletion — cutting rules outright to hit a line target
  and calling it progressive disclosure.
- Demoting a must-happen workflow to a plain markdown link with no
  hook or skill trigger ("the agent can always read it").
- `@import`ing the detail back in — the line count drops, the token
  cost doesn't.
- Restating a canonical module's text in the map instead of pointing
  at it (drift guaranteed).
- Treating "the sessions still behave" as proof the pointers are being
  read — H5 shows behavior can hold while reads run near zero; know
  which insurance (hook, handoff, priors) is actually carrying each
  rule.

## This rule is working if

- The eager chain stays under ~200 lines through feature work, without
  a rules-were-lost incident traceable to a demotion.
- Every demotion PR names the lazy surface *and* the trigger for each
  moved rule.
- Where measured, deterministic adherence incidents do not rise after
  a slimming pass, and must-happen rules show a tier-1/2 trigger
  rather than depending on agent-initiated reads.

## Related

- [[docs-two-layer]] — the sibling doc-structure guardrail (human
  README vs agent CLAUDE.md); this module governs the *agent* layer's
  size and shape.
- [[session-handoff]] — the ≤40-line kickoff cap is this same rule
  applied to the injected handoff.
- [[git-flow-session-end]] — the canonical example of a workflow that
  lives in a module and is *pointed at*, never restated, by host maps.
- Source design + measurement: `12-progressive-disclosure-context-slimming`,
  H5.
