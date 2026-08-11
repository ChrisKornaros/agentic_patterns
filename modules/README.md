# modules/

Portable instruction modules — frontmatter-tagged markdown files
that any host repo can vendor into its `CLAUDE.md` (or per-role
`CLAUDE.md`) without copy-pasting rule text.

> **Status:** 🟡 partial. 30 modules extracted —
> the v1 pilot covered one of each shape (`guardrail`, `workflow`,
> `prompt`), the tech-stack-defaults umbrella from
> `06-tech-stack-defaults`
> adds three more (`python-uv-only`, `duckdb-default-store`,
> `arm64-target-arch`), the scope-of-action guardrail family
> now covers both `stay-in-project-tree` (where the agent acts)
> and `no-sudo-as-shortcut` (with what authority), and the
> file-access guardrail family adds `no-cat-head-via-bash`
> (bundled with H2 per
> `h2-re-read-collapse/README`),
> and the day-to-day git-flow family
> (`08-pre-content-manager-optimization`
> track A1) adds the four guardrails/workflows a fresh repo composes
> first — `git-flow-branch-naming`, `smoke-before-commit`,
> `auto-commit-on-branch-done`, `ask-merged-via-popup` — and the
> project-integration family (`secrets-no-plaintext`,
> `external-api-adapter-boundary`, `no-live-external-in-tests`,
> `adr-per-major-decision`), extracted ahead of the `content_manager`
> build that is their forcing case, plus the session-end knowledge
> layer `session-handoff` and the per-edit coding-discipline family
> (`assumptions-before-code`, `minimum-code-first`,
> `surgical-diffs-only`, `verifiable-goal-before-code`) — the
> library's first external-source modules, adapted from Andrej
> Karpathy's coding guidelines.
> Finally, the `10-fable-window-finalization`
> A4 extraction tail closes four more — the `substrate-preflight` and
> `tight-code-review` prompt modules (which retire the
> skill-first/module-later half-state by giving the two skills a
> `module:` to auto-pair on) plus the `docs-two-layer` and
> `status-emoji-discipline` doc/tracking guardrails — and
> `12-progressive-disclosure-context-slimming`
> S6 adds `claude-md-as-map`, the measured (H5) map-not-territory
> guardrail for the eager CLAUDE.md chain, and
> `13-teaching-agent-framework` S1 adds the
> teaching family (`guide-dont-solve`, `grounded-explanations`,
> `hint-ladder`) — the tutor stance for learning repos.
> The full backlog and migration plan live in
> `03-instruction-modules` §5.

## What lives here

| Path | Purpose |
|---|---|
| `frontmatter` | Field-by-field reference for the module frontmatter. Authoritative spec text lives in `03-instruction-modules`; this file is the short reference. |
| `VENDORING` | Step-by-step recipe for adopting one or more of these modules in a host repo — `MODULES.md` ledger, host `CLAUDE.md` shape, permission-settings, update flow. |
| `<name>/index.md` | One module per directory. Directory layout leaves room for companion files (settings snippets, examples) as types grow. |

## Modules in this repo

### v1 pilot

| Module | Type | Source rule extracted from | Status |
|---|---|---|---|
| [git-flow-no-direct-main](git-flow-no-direct-main/index.md) | guardrail | `git-workflow`, `common-guardrails` §Never | 🟢 stable |
| [git-flow-session-end](git-flow-session-end/index.md) | workflow | `git-workflow` §The session-end loop | 🟢 stable · ships optional hook enforcers: `Stop` (`session_end_guard.py`) + a `PreToolUse` wrap-up nudge on `gh pr create` (`pre_pr_wrapup_nudge.py`, the H5 §4 trigger-strengthening) via `settings-snippet.json` |
| [phase-kickoff](phase-kickoff/index.md) | prompt | [prompts/phase-kickoff.md](../prompts/phase-kickoff.md) | 🟢 stable |

### Tech-stack defaults

Per `06-tech-stack-defaults` —
the stable per-stack tooling picks that should be enforced at
agent runtime instead of relearned every project.

| Module | Type | Source rule extracted from | Status |
|---|---|---|---|
| python-uv-only | guardrail | `ops`, `playbook` | 🟢 stable |
| duckdb-default-store | guardrail | `storage` §Default: DuckDB | 🟢 stable |
| arm64-target-arch | gotcha | `ops`, `tools-stack/README` | 🟢 stable |

### Scope-of-action

Guardrails covering where the agent is allowed to act on the
filesystem and which capabilities count as "elevated."
`stay-in-project-tree` bounds *where*; `no-sudo-as-shortcut`
bounds *with what authority*. The two together cover the class of
failure where an agent technically completes a task but leaves the
host in a state nobody reviewed.

| Module | Type | Source rule extracted from | Status |
|---|---|---|---|
| stay-in-project-tree | guardrail | `common-guardrails` §Never ("Reach outside the repo's working tree"), `settings` deny-list | 🟢 stable |
| no-sudo-as-shortcut | guardrail | `common-guardrails` §Never ("Reach for `sudo` as a shortcut"), `07-anti-patterns` #13, `settings` deny-list | 🟢 stable |

### File-access surface

The companion family that the H2 re-read-collapse experiment
(per `h2-re-read-collapse/README`)
exercises from two angles: a runtime hook on the `Read` tool plus a
prose guardrail closing the Bash-cat workaround the hook can't see.

| Module | Type | Source rule extracted from | Status |
|---|---|---|---|
| no-cat-head-via-bash | guardrail | `2026-05-27-pre-obsidian/README` baseline (~25% of Bash spend), root CLAUDE.md "Avoid using this tool to run `cat`/`head`/..." guidance | 🟡 experimental |

### Day-to-day git-flow

The guardrails and workflow modules a fresh repo composes first,
extracted per `08-pre-content-manager-optimization`
track A1 so `content_manager`'s bootstrap assembles a complete set
instead of falling back to hand-written rules. The two workflow
modules are companions to (and `dependencies:` of)
[git-flow-session-end](git-flow-session-end/index.md) — it
orchestrates the loop; they own the auto-commit and merge-popup
slices. [session-handoff](session-handoff/index.md) sits the other
way round — it `depends:` on `git-flow-session-end` and runs *after*
the loop, adding the cross-session knowledge layer (lesson capture +
next-session kickoff).

| Module | Type | Source rule extracted from | Status |
|---|---|---|---|
| [git-flow-branch-naming](git-flow-branch-naming/index.md) | guardrail | `git-workflow` §Branch naming | 🟢 stable |
| [smoke-before-commit](smoke-before-commit/index.md) | guardrail | `04-testing-verification` | 🟢 stable |
| [auto-commit-on-branch-done](auto-commit-on-branch-done/index.md) | workflow | `common-guardrails` §Always | 🟢 stable |
| [ask-merged-via-popup](ask-merged-via-popup/index.md) | workflow | `common-guardrails` §Always, `git-workflow` §The session-end loop | 🟢 stable |
| [session-handoff](session-handoff/index.md) | workflow | `playbook/README` §Quick-reference card (#8, #10), [prompts/phase-kickoff.md](../prompts/phase-kickoff.md), `lessons-log` | 🟢 stable · runs *after* `git-flow-session-end`: cross-project lesson capture into `knowledge` + roadmap-grounded `.claude/next-session.md` |

### Project-integration

The guardrails an application that integrates external services
composes — extracted ahead of the
`content_manager`
build, which is their forcing case (it authenticates to and publishes
on YouTube/Instagram/TikTok behind a secrets boundary, with a list of
"do not relitigate" decisions). These four codify the rules that
project surfaced; the citations are repo-internal so the modules stay
vendorable. Marked `experimental` where the rule generalizes an
existing one ahead of a published case study.

| Module | Type | Source rule extracted from | Status |
|---|---|---|---|
| [secrets-no-plaintext](secrets-no-plaintext/index.md) | guardrail | `common-guardrails` §Never, `ops` §Secrets | 🟢 stable |
| external-api-adapter-boundary | guardrail | `03-design-patterns` §The seven patterns, `web` §Patterns to keep | 🟡 experimental |
| no-live-external-in-tests | guardrail | `04-testing-verification` §Live DB never mutated, `common-guardrails` §Never | 🟢 stable |
| [adr-per-major-decision](adr-per-major-decision/index.md) | workflow | `03-design-patterns` §The seven patterns, `REQUIREMENTS_AI.template` | 🟡 experimental |

`no-live-external-in-tests` supersedes the sketched `no-live-db-in-tests`
scope — it covers any external system, the live DB included.

### Per-edit coding discipline

Guardrails on the code itself — what happens between "branch
created" and "smoke run," a layer the process/orchestration families
above don't touch. Adapted (not extracted) from
[Andrej Karpathy's coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills)
(published via [this X post](https://x.com/karpathy/status/2015883857489522876)) —
the library's first external-source modules, hence all
`experimental` until our own case-study evidence accrues. The
[scope-guard skill](../skills/scope-guard/SKILL.md) covers the
adjacent PR-boundary angle (what else gets *packaged*); these four
cover the inside-the-diff discipline. Each ships the
`## This rule is working if` success-marker section this family
introduced to the body-shape spec.

| Module | Type | Source rule adapted from | Status |
|---|---|---|---|
| [assumptions-before-code](assumptions-before-code/index.md) | guardrail | Karpathy guidelines §"Think before coding" | 🟡 experimental |
| [minimum-code-first](minimum-code-first/index.md) | guardrail | Karpathy guidelines §"Simplicity first" | 🟡 experimental |
| [surgical-diffs-only](surgical-diffs-only/index.md) | guardrail | Karpathy guidelines §"Surgical changes" | 🟡 experimental |
| [verifiable-goal-before-code](verifiable-goal-before-code/index.md) | workflow | Karpathy guidelines §"Goal-driven execution" (front half; [smoke-before-commit](smoke-before-commit/index.md) + no-live-external-in-tests already own the verify half) | 🟡 experimental |

### Extraction tail (roadmap/10 A4)

The four candidates the `10-fable-window-finalization`
A4 row called out — extracted together so the Fable window opened with
the library's pending tail closed. The two `prompt` modules were already
shipping as skills sourcing `prompts/` directly; extracting them lets
each skill declare a `module:` and **auto-pair** in
`install-modules`, retiring
the intentional skill-first/module-later half-state. The two guardrails
codify the doc/tracking conventions a fresh repo composes early.

| Module | Type | Source rule extracted from | Status |
|---|---|---|---|
| [substrate-preflight](substrate-preflight/index.md) | prompt | [../prompts/substrate-preflight.md](../prompts/substrate-preflight.md), [../skills/substrate-preflight/SKILL.md](../skills/substrate-preflight/SKILL.md) | 🟢 stable · skill auto-pairs via `module:` |
| [tight-code-review](tight-code-review/index.md) | prompt | [../prompts/tight-code-review.md](../prompts/tight-code-review.md), [../skills/tight-review/SKILL.md](../skills/tight-review/SKILL.md) | 🟡 experimental · skill auto-pairs via `module:` |
| [docs-two-layer](docs-two-layer/index.md) | guardrail | `01-documentation-stack`, `playbook` §2 | 🟢 stable |
| [status-emoji-discipline](status-emoji-discipline/index.md) | guardrail | `02-workflow-patterns` §4, `playbook` §1.4.1 | 🟢 stable |

### Context slimming (roadmap/12 S6)

The map-not-territory pattern, extracted at
`12-progressive-disclosure-context-slimming`
S6 after being executed (S1–S4, eager chain 403 → 225 lines) and
measured (H5). Ships `experimental` under a logged operator override:
H5's outcome primary held (incidents *fell* in both measured repos)
while its mechanism primary was refuted — bare pointers largely don't
get read — which is exactly the caveat the module's rule carries.
Promotion past `experimental` waits on the trigger-strengthening
re-measure named in the
H5 RESULT §4.
The strengthening itself landed 2026-08-01 (the module's
`pre_pr_wrapup_nudge.py` for both repos' wrap-up classes; a path-scoped
`.claude/rules/` pointer at `docs/agent-conventions.md` in
content_manager) — the re-measure window can open once both are merged.

| Module | Type | Source rule extracted from | Status |
|---|---|---|---|
| [claude-md-as-map](claude-md-as-map/index.md) | guardrail | `12-progressive-disclosure-context-slimming` §2–§4, H5 RESULT | 🟡 experimental |

### Teaching (roadmap/13 S1)

The tutor stance for learning repos — hosts where the agent's job is
to *teach*, not produce — per
`13-teaching-agent-framework`.
Domain-general by design: no module mentions any subject;
learner-owned paths and the domain's oracle are host-adapter content
in the host's own `CLAUDE.md`. Runtime surface: the
tutor and hint
skills (auto-pairing via `module:`) over
`tutor-kickoff` and
`hint-ladder`. All
`experimental` (external evidence base, no own-case-study yet — the
Karpathy-family precedent); each ships `## This rule is working if`
transcript-checkable markers, and the `BOTTOM-OUT:` marker makes the
answer-leak rate grep-able. First host: rust_book (S2).

| Module | Type | Source rule adapted from | Status |
|---|---|---|---|
| guide-dont-solve | guardrail | rust_book's division-of-labor rule, generalized; Bastani et al. RCT + LearnLM/Study Mode convergence (`roadmap/13` §2–§4) | 🟡 experimental |
| grounded-explanations | guardrail | learning-science core (concreteness fading, structure mapping, PS2 Pal) via `roadmap/13` §2/§4 | 🟡 experimental |
| hint-ladder | workflow | ITS hint taxonomy + assistance dilemma ([Koedinger & Aleven 2007](https://pact.cs.cmu.edu/pubs/Koedinger%20Aleven%2007.pdf)) via `roadmap/13` §2/§4 | 🟡 experimental |

### Pending extraction

The remaining candidates are the **role modules** — still scattered
across `agents` role definitions; they'll be extracted in
follow-up branches as the multi-agent team firms up (the `po/` flesh-out
in `10-fable-window-finalization` A2 is the
next forcing case). See
`08-pre-content-manager-optimization` §4-A1
for the `content_manager`-relevant history.

## How a host repo uses a module

The full composition rules live in
`03-instruction-modules` §4;
the short version:

1. **Vendor.** Copy the module directory into the host's
   `modules/<name>/` (v1 mechanism — submodule and symlink are
   options for later). Record `name`, `version`, `source`, and
   `copied_at` in the host's `MODULES.md` ledger.
2. **Reference.** Link to it from the host's root `CLAUDE.md`
   under a `## Composed modules` table. The link, not the rule
   text, is the load-bearing thing — when the canonical module
   evolves, re-vendor and the host inherits the update.
3. **Override locally only when needed.** Project-local
   `CLAUDE.md` content beats vendored modules (§4.3 of the spec).
   If the host overrides, note it in `MODULES.md` so a future
   reader knows the conflict was intentional.

## How a module earns its place

Same bar as
`common-guardrails` §"How rules earn their place here",
adapted for portability:

1. **Cross-project.** The rule has to plausibly apply to more
   than one host repo (otherwise it's project-specific and
   belongs in the host's `CLAUDE.md`, not here).
2. **Enforceable.** Phrased as a thing to do or not do, with
   concrete failure modes — not "be thoughtful about X."
3. **Cited.** `lifecycle: stable` modules MUST have at least one
   `evidence:` entry pointing to a case study or playbook essay.
   `lifecycle: experimental` modules can ship without evidence
   but get reviewed before promotion.

## Verify

There's no compiler yet (per spec §2 non-goals). Manual checks:

- Every module directory has an `index.md`.
- Every `index.md` has frontmatter with `name`, `type`, `scope`,
  `lifecycle`, `version`, and (for `lifecycle: stable`)
  `evidence:`.
- Every `name:` matches the directory name.
- Every `dependencies:` entry points to a module that exists in
  this directory.

`check_modules` asserts all
of these (including the `stable ⇒ evidence:` rule) and exits non-zero
on any violation — run it alongside `check_links.sh`.

## Cross-references

- Spec: `03-instruction-modules`
- Structural rationale: `04-structural-proposal` §3.2
- Where the rules currently live (source for extraction):
  `common-guardrails`,
  `git-workflow`,
  [../prompts/](../prompts/)
