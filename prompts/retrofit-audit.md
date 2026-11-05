# Retrofit audit (Mode C of import workflow)

Use at the **start of a Claude Code session in an existing host
repo** that has informal conventions you want to formalize against
the canonical module library. This is Mode C of the import workflow
per
[roadmap/05-import-workflow.md §6](https://github.com/ChrisKornaros/agentic_optimization_research/blob/main/roadmap/05-import-workflow.md#6-mode-c--the-retrofit-audit-prompt).

Unlike [bootstrap-host-repo.md](bootstrap-host-repo.md) (Mode B),
this prompt is **read-only by default**. It produces a *proposal
diff*, not a `cp -R`. The human decides whether to accept; if so,
the actual installation runs through Mode B.

## How to invoke

**Primary — slash command.** If `/audit-repo` is installed under
`~/.claude/commands/` (one-line adoption from
`dotfiles/README`), just type
`/audit-repo` in any Claude Code session in the target repo. The
shim resolves the canonical path and reads this prompt for you. The
shim canonical source lives at
`audit-repo`.

**Fallback — paste the prompt body below** into a session in the host
repo.

```
You are auditing this repo against the canonical
`agentic_optimization_research` module library. The goal is a
read-only proposal that names which informal rules in this repo
could be formalized as vendored modules and which existing rules
should stay host-specific.

DO NOT install anything. DO NOT edit `CLAUDE.md`,
`.claude/settings.json`, `modules/`, or `MODULES.md`. The audit's
final step is a *next-session plan*, not an apply.

Inputs you should resolve up front (use AskUserQuestion if any are
unclear):
  - Path to the canonical `agentic_optimization_research` checkout.
    The `/audit-repo` shim resolves this to the GitHub mirror at
    `~/.cache/agentic_optimization_research` (Step 0). If you're
    pasting this prompt by hand instead, point at wherever your clone
    lives (e.g. `~/vault/projects/agentic_optimization_research`) or
    refresh the same cache the shim uses.
  - Scope of the audit: just root `CLAUDE.md`, or root + every
    subdirectory `CLAUDE.md` + `agents/_shared/` + `templates/_shared/`
    + `prompts/`? Default: full scope.

Then, in order:

1. **Inventory the host's current rules.** Read the host's root
   `CLAUDE.md`, every subdirectory `CLAUDE.md` you find, the
   allow + deny lists in `.claude/settings.json`, and any inline
   rules in `agents/_shared/`, `templates/_shared/`, `prompts/` if
   those folders exist. Extract a flat list of behavioral rules
   (numbered, one rule per line) — what the host claims to enforce,
   in its own words. Also record the **eager-chain line count** (root
   `CLAUDE.md` plus any ancestor CLAUDE.md that auto-loads for a
   session in this repo): if it exceeds ~200 lines, flag
   `claude-md-as-map` as a candidate in step 3 — the map-not-territory
   slimming is itself a vendorable rule, and the audit table should
   say which inline sections are duplicates of (or candidates for)
   modules rather than genuinely local content.

2. **Inventory the module library.** From the canonical checkout,
   read `modules/README.md` and the frontmatter of every
   `modules/<name>/index.md` (`type`, `scope`, `dependencies`,
   `applies_when`). For each module, note the rule it formalizes
   in one sentence.

3. **Cross-reference into a four-bucket table.** For each rule
   surfaced in step 1, place it in exactly one bucket:

     - **Already modular** — host's `CLAUDE.md` or `MODULES.md`
       references a vendored module that covers this rule. No
       action needed.
     - **Implicit, module exists** — host enforces the rule
       informally (in prose, in a subdir `CLAUDE.md`, in a
       deny-list entry) but a canonical module already
       formalizes it. *Candidate for vendoring.*
     - **Implicit, no module yet** — host has a rule worth
       generalizing, but no canonical module covers it. *Candidate
       for a PR against the canonical repo* (extract the rule into
       a new module, then vendor it back).
     - **Host-specific, leave alone** — genuinely local: a project
       gotcha, a path quirk, a deploy detail. Not a candidate for
       modularization. Note why so the next audit doesn't re-litigate.

4. **Surface the four-bucket table as markdown** in the chat. One
   row per rule. Include a column for the canonical module name (or
   "—" if none). For "Implicit, no module yet" rows, name the
   `modules/_spec/frontmatter.md` `type` you'd propose (guardrail /
   workflow / prompt / role / gotcha).

5. **Propose a next-session plan.** Three options, presented as a
   short numbered list (NOT AskUserQuestion — the human reads the
   table first, then chooses):
     a. **Vendor the "Implicit, module exists" rows.** Suggest the
        exact `scripts/install-modules.sh <host> <module>...`
        invocation, then suggest running
        [bootstrap-host-repo.md](bootstrap-host-repo.md) (Mode B)
        in a fresh session to finish the wiring (CLAUDE.md +
        settings).
     b. **PR the "Implicit, no module yet" rules into the canonical
        repo first.** For each candidate, draft a one-line module
        name and `type:`. The new modules land in the canonical
        repo, then this host vendors them via (a).
     c. **Do nothing now.** Save the audit table as a note in this
        repo for a later session. The retrofit can sit; the docs
        won't drift faster than the canonical repo's module set
        does.

6. **Stop.** End the session with the audit table and the three
   options. DO NOT begin editing even if the human says "go" — that
   handoff belongs in a new session running Mode B or a canonical-
   repo PR session, both of which start clean.

If during step 1 you find that the host has ZERO informal rules
(no `CLAUDE.md`, no `.claude/settings.json`) — the right tool is
Mode B, not this audit. Surface that and stop.

If during step 1 you find that the host already vendors most or
all canonical modules with up-to-date source commits — the audit's
output is small by construction; report "no significant drift" and
stop.
```

## Why this works

The audit has a bigger judgment surface than the bootstrap — it has
to *interpret* informal rules ("we always smoke before merging")
and decide whether they match an existing module's formalization,
deserve a new module, or are genuinely host-local. Wrapping that
judgment in a separate prompt (instead of a flag on Mode B) keeps
the bootstrap streamlined for the "I know what I want" case and
forces the audit to slow down for human review.

Three load-bearing design choices:

- **Read-only by default, even on "go".** Step 6 is explicit: the
  audit produces a proposal, not a transaction. The installation
  itself runs through Mode B with a clean session, so the human
  sees Mode B's `AskUserQuestion` popup and gets the per-module
  defaults review on top of the audit's recommendations.
- **Four buckets, not three.** "Implicit, no module yet" is the
  bucket that surfaces gaps in the canonical module library
  itself — i.e., the audit isn't just "what should this host
  adopt?" but "what should the canonical repo learn from this
  host?" Without that bucket, audits become one-way.
- **No `AskUserQuestion` at step 5.** Module *selection* (Mode B,
  step 5) benefits from a popup — small set, mostly defaults.
  Audit *acceptance* benefits from the human reading a table and
  thinking, then typing a follow-up. Different decision surfaces
  → different UI.

The two no-op exits (zero rules → use Mode B; no drift → "no
significant drift") keep the audit from spinning up a full table
when a smaller report is the honest answer.

Cross-refs:
- `05-import-workflow` §6 — the contract this prompt implements
- [prompts/bootstrap-host-repo.md](bootstrap-host-repo.md) — Mode B, what step 5(a)+(b) hand off to
- [scripts/install-modules.sh](../scripts/install-modules.sh) — Mode A, the script step 5(a) suggests invoking
- [modules/_spec/frontmatter.md](../modules/_spec/frontmatter.md) — the `type:` taxonomy step 4 uses when proposing new modules
- `audit-repo` — the `/audit-repo` slash command shim (primary invocation)
- `dotfiles/README` — how to install the shim on a new machine
