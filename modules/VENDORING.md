# Vendoring modules into a host repo

A step-by-step guide for adopting one or more modules from this
repo into a separate project, so the same workflow rules (and
their wording) apply across repos and across cold Claude
sessions.

> **Audience:** future-Chris standing up a new repo (or
> retrofitting an existing one) and wanting `git-flow-session-end`,
> `git-flow-no-direct-main`, etc. to fire consistently — not
> just live as informal habits.

The authoritative composition spec is
`03-instruction-modules` §4.
This file is the practical recipe.

---

## Quickstart: pick a mode

Most adoptions go through one of three tools defined in
`05-import-workflow`.
The numbered recipe below is the substrate — what the tools automate
under the hood, and the fallback when a tool isn't a fit.

| Mode | Primary invocation | Fallback invocation | When |
|---|---|---|---|
| **A. Script** | [../scripts/install-modules.sh](../scripts/install-modules.sh) | — | You already know which modules you want. |
| **B. Bootstrap** | `/bootstrap-repo` slash command (shim at `bootstrap-repo`) | Paste [../prompts/bootstrap-host-repo.md](../prompts/bootstrap-host-repo.md) into a fresh session | Fresh repo; want Claude to help choose modules from the archetype. |
| **C. Retrofit-audit** | `/audit-repo` slash command (shim at `audit-repo`) | Paste [../prompts/retrofit-audit.md](../prompts/retrofit-audit.md) into a session | Existing repo with informal habits to formalize. Read-only — produces a proposal, not a `cp -R`. |

**Mode A — run from the canonical repo:**

```sh
scripts/install-modules.sh ~/code/host-repo git-flow-session-end git-flow-no-direct-main
```

Copies the modules, writes/updates `MODULES.md` idempotently, and
prints a ready-to-paste **Composed modules** snippet for the host's
`CLAUDE.md`. It also **vendors the paired skills** (§9): any skill in
`skills/` whose frontmatter `module:` names an installed module is
copied into `<host>/.claude/skills/<name>/` and recorded in
`SKILLS.md` — so a prompt-module never lands without its runnable
shim. Standalone skills that back no module are added with
`--skill <name>` (and `--no-skills` opts out of the auto-pairing).
Re-running at the same canonical commit is a no-op; a newer commit
updates the existing row in place (no duplicates). The script does
*not* touch the host's `CLAUDE.md` or `.claude/settings.json` — §§4–6
below stay manual (or get handled by Mode B).

**Mode B — type `/bootstrap-repo` in any Claude Code session in the
target repo.** The slash command lives under
`~/.claude/commands/` (vendored from
`bootstrap-repo`),
so it works from any repo without per-project setup. It resolves the
canonical repo to the `~/.cache/` GitHub mirror (refresh-or-clone,
ignoring any local checkout — GitHub `main` is the single source of
truth), reads [../prompts/bootstrap-host-repo.md](../prompts/bootstrap-host-repo.md),
and follows it: senses the archetype, surfaces a module shortlist via
`AskUserQuestion`, calls Mode A, wires `CLAUDE.md` and
`.claude/settings.json` per §§4–6, and opens a PR following the host's
git-flow. If the slash command isn't installed on the machine you're
on, paste the prompt directly as the fallback.

**Mode C — type `/audit-repo` in any session in an existing repo.**
Same shim pattern (canonical at
`audit-repo`),
read-only by design: Claude inventories the host's current rules,
cross-references the module library, and returns a four-bucket
proposal table. No `cp -R` runs until you start a separate
`/bootstrap-repo` session to act on it. Fallback: paste
[../prompts/retrofit-audit.md](../prompts/retrofit-audit.md) directly.

**Installing the slash commands on a new machine:** see
`dotfiles/README`. The recipe is a single
``link-dotfiles`` run, which
symlinks the tracked files into `~/.claude/`. The shims handle the
canonical-repo path resolution themselves, so adoption is one command
followed by zero configuration.

**When to fall back to the manual recipe (§§1–8 below):**

- The script or prompts fail in a way you need to debug.
- You're vendoring into a repo on a host where bash + the canonical
  checkout aren't both available.
- You're learning what these tools actually do — read §§1–8
  end-to-end; it's the source of truth.

---

## 1. Pick a vendoring mechanism

| Mechanism | When | Tradeoff |
|---|---|---|
| **Copy** (snapshot) | Default. One human, a few repos. | Drifts from canonical until you re-copy. |
| **Git submodule** | Multi-person team, real release cadence. | Submodules have sharp edges; many devs avoid them. |
| **Symlink** | Single operator, *and* the library sits at the same path on every machine (e.g. a vault repo synced to `~/vault` across hosts). Edits flow instantly with no copy to drift. | The link dangles wherever that path isn't present — CI, a collaborator's clone. |

v1 default: **copy**. The rest of this guide assumes copy, and so does
the tooling — Mode A and Mode B both copy under the hood.

Copy is the default because this doc gets vendored into *other* repos,
some of which leave your machines (CI, a collaborator's laptop), and a
copy resolves everywhere. The [ledger](#2-set-up-the-host-directory-layout)
is what keeps copy's drift visible instead of silent.

Symlink is not wrong — it's the *freshest* option for a single operator
whose canonical library is reachable at the same path on every machine
(the cross-machine vault-sync setup defuses the usual "breaks on another
machine" knock). But it stays a deliberate, hand-wired opt-out: the
scripts copy, so symlinking is something you do yourself, knowing the
repo will never leave that boundary. See the "Vendoring" section of the
`aor-modules` guide for the full single-operator argument.

## 2. Set up the host directory layout

In the host repo, create:

```
modules/                         # vendored copies live here
  <module-name>/index.md         # one directory per module
MODULES.md                       # the ledger — what's vendored, at what version, from where
```

`MODULES.md` is a flat, hand-maintained markdown table. A
minimal starting shape:

```markdown
# Vendored modules

Pulled from
[agentic_optimization_research/modules/](https://github.com/ChrisKornaros/agentic_optimization_research/tree/main/modules).
When a module's canonical version bumps, re-copy and update the
row here. Local overrides go in the **Override** column.

| Module | Version | Source commit | Copied at | Override |
|---|---|---|---|---|
| git-flow-no-direct-main | 1 | `aa6c9a4` | 2026-05-25 | — |
| git-flow-session-end | 2 | `<commit>` | 2026-05-25 | — |
```

The ledger is the contract: if a future reader (human or agent)
sees a rule that surprises them, the ledger says where it came
from and whether it's been bent locally.

## 3. Copy the modules in

> **Mode A automates this section** —
> [../scripts/install-modules.sh](../scripts/install-modules.sh) handles
> the `cp -R` and the `MODULES.md` row append idempotently. The steps
> below are the manual equivalent.

For each module you want, copy the whole directory (so any
companion files come along):

```sh
# from the host repo root
mkdir -p modules
cp -R /path/to/agentic_optimization_research/modules/git-flow-session-end modules/
cp -R /path/to/agentic_optimization_research/modules/git-flow-no-direct-main modules/
# repeat per module
```

**The script re-points links; `cp -R` doesn't.** A module's links are
written for this repo, where `../../` reaches `prompts/`, `roadmap/`,
`case-studies/` and the rest. A host has only what it vendored. So the
script rewrites each `../` and `../../` link in the copied `index.md`.
A link to a module or skill the host vendored points at the host's
copy. Anything else points at the canonical file on GitHub. After a
manual copy those links stay broken until the script is re-run.

Then add a row to `MODULES.md` for each one, filling in the
source commit hash:

```sh
# get the source commit (run from agentic_optimization_research)
git rev-parse --short HEAD
```

## 4. Wire the host's `CLAUDE.md` to the modules

> **Mode B handles this section** —
> [../prompts/bootstrap-host-repo.md](../prompts/bootstrap-host-repo.md)
> either creates `CLAUDE.md` from scratch or surgically adds a
> Composed-modules section to an existing one, then continues into §§5
> and 6. Mode A *prints* the snippet to stdout but won't paste it
> (placement is a judgment call); the steps below cover the manual
> paste.

This is the step that makes vendored modules actually take
effect. A host repo's root `CLAUDE.md` should have a `Composed
modules` section near the top — Claude auto-loads `CLAUDE.md`
at session start, so any module linked from it is implicitly
loaded too.

Minimal shape:

```markdown
# {{ project }} — agent notes

[One paragraph: what is this repo, what's it for.]

## Composed modules

The agent rules for this repo are assembled from modules
vendored under `modules` (see `MODULES`
for versions and any local overrides):

| Module | Type | Why it's here |
|---|---|---|
| git-flow-no-direct-main | guardrail | Branch hygiene — no commits to main |
| git-flow-session-end | workflow | End-of-session loop: doc sync → commit → PR → popup → cleanup → fixed-format summary |

## Project-specific

[Things that are only true here: gotchas, layout, verification
command, archetype-specific rules. These don't belong in modules.]
```

**Do not paste the module text into `CLAUDE.md`.** The link is
load-bearing; pasting makes drift inevitable and silences the
`MODULES.md` ledger.

## 5. Mirror the workflow's "short form" inline

> **Mode B handles this section** — for each `workflow`-type module
> installed, the bootstrap prompt pastes the short-form steps into
> `CLAUDE.md` next to the Composed-modules table.

The session-end module is long — 150+ lines. To make it fire
*reliably* across cold sessions, also paste a numbered short
form of the workflow steps directly into `CLAUDE.md` (or a
subsection of it), and link to the canonical module for detail.
The short form is the "always loaded, always top-of-mind"
copy; the module is the "go here when you need the why."

The pattern looked like this repo's own
CLAUDE.md §Git workflow —
9 numbered steps, the fixed-format **Session end** block at the
bottom, and a one-line "canonical rule lives in
[modules/git-flow-session-end/index.md](git-flow-session-end/index.md)"
pointer at the top.

> **2026-09-29:** this repo's root `CLAUDE.md` no longer carries that
> short form. The `12-progressive-disclosure-context-slimming`
> slimming (2026-07-14) replaced it with a pointer backed by the
> `/session-wrapup` skill and the module's hooks (§6). Weigh a host's
> short form against [claude-md-as-map](claude-md-as-map/index.md).

Why both copies: a link alone gets ignored when Claude is mid-task
and reaching for the most recently loaded context. The numbered
short form is the thing that actually steers behavior; the
module is the thing that survives wording changes without a
re-paste.

When the canonical module's *steps* change (not just wording),
re-paste the short form. When only the prose around the steps
changes, only re-copy `modules/<name>/index.md` — `CLAUDE.md`
stays stable.

## 6. Inherit the matching permission settings (and hooks)

> **Mode B handles this section** — either copies
> [../templates/_shared/claude-settings.example.json](../templates/_shared/claude-settings.example.json)
> wholesale when the host has no settings file, or surgically adds the
> deny rules + hooks the chosen modules assume to an existing one.

A module enforces itself at the settings layer through **one of three
mechanisms**, and which applies depends on the module:

| Mechanism | Modules that use it | What to do |
|---|---|---|
| **Baked into the example settings** | `git-flow-no-direct-main`, `git-flow-session-end` | Already present in [claude-settings.example.json](../templates/_shared/claude-settings.example.json) — the deny trio below. Nothing per-module to copy. |
| **`settings-snippet.json` companion** | `stay-in-project-tree`, `no-sudo-as-shortcut`, `python-uv-only` | After `cp -R` brings the module dir over, merge that module's `modules/<name>/settings-snippet.json` `deny` entries into the host's `.claude/settings.json`. |
| **Hook companion** | `no-cat-head-via-bash` (`pre_read_guard.py`, `PreToolUse`), `git-flow-session-end` (`session_end_guard.py`, `Stop`; `pre_pr_wrapup_nudge.py`, `PreToolUse` on `gh pr create`), `session-handoff` (`session_handoff_kickoff.py`, `SessionStart`) | Wire the hook the module names on the event in its `## Companion files` section, using that module's `settings-snippet.json`. Each ships a `[ -f ] || exit 0` fail-open shape, so the wiring is a safe no-op until the module is vendored. |

This three-mechanism split is the contract; **the module body is the
canonical source** when this table lags a newer module. Always read
each installed module's `## Companion files` section after vendoring —
if it names a `settings-snippet.json` or a hook script, wire it.

**The git-flow deny trio (baked into the example):**

- `gh pr merge` must be **denied** (the human merges in the
  GitHub UI — the whole "ask via popup" pattern depends on
  this).
- `git push origin main` must be **denied** (no direct commits
  to main is the *safety net* that lets auto-commit be safe).
- `git push --force` must be **denied** (recovery from a wrong
  cleanup sync needs force-push; denying it forces the agent to
  verify before destroying state).
- `gh pr create`, `gh pr view`, `git push -u origin <branch>`,
  `git switch`, `git pull --ff-only`, `git branch -d` must be
  **allowed** (the auto-commit + cleanup sequence has to run
  without prompting on every step, or the friction returns).

**The scope-of-action denies (snippet companions).** If you vendored
`stay-in-project-tree` or `no-sudo-as-shortcut`, their
`settings-snippet.json` files carry the out-of-tree path denies
(`/etc`, `/usr`, credential stores, shell rc files, the global Claude
config) and the elevation denies (`sudo`, `su`, `chown`, `chmod 777`,
privileged `docker`/`kubectl` exec) respectively. Merge those `deny`
arrays in; the example settings already includes a starter subset, but
the snippets are the fuller, canonical list. A Python host that vendored
`python-uv-only` merges its snippet too: it denies package installs
outside `uv.lock` and the non-uv env tools. The example settings carry
none of it, since not every host is Python.

**Lint and trip-test right after the merge, not at §7.** A permission
rule the CLI can't parse is silently dead, and a snippet merge is where
they get in (two content_manager PRs, #158 and #159, each found a batch
of dead rules weeks after the merge that wrote them). So, in the same
sitting: run a fresh `claude -p "read /etc/hostname"` from the host root
and read its stderr, which lists every rule it could not match (the free
lint, the same one [§7](#7-verify-the-wiring-on-first-session) runs on
the first session); then trip **one** deny from the batch you just merged
and see it refused. Fix the rule, not the test, until both pass.

**The re-read guard (hook companion).** If you vendored
`no-cat-head-via-bash`, the example settings' `hooks` block wires its
`pre_read_guard.py` (guarded with `[ -f ] || exit 0`, so it's a no-op
until the module is present). Keep the block; delete it only if you
don't want the runtime re-read guard.

**The session-handoff kickoff (hook companion).** If you vendored
`session-handoff`, the example settings' `hooks` block already wires its
`session_handoff_kickoff.py` on `SessionStart` (guarded with
`[ -f ] || exit 0`, so it's a no-op until the module is present). It
surfaces a committed `.claude/next-session.md` into the opening context so
the next cold-start session resumes without re-deriving state; the script
also fails open, so it's inert until both the module *and* a handoff file
exist. Keep the block; delete it only if you don't want the handoff
auto-surfaced. (The module's `settings-snippet.json` carries the same
entry for hosts that started from a bare settings file rather than the
example.)

**Unless the machine already runs them.** User-level and project hooks
merge rather than override. So if `~/.claude/settings.json` already
wires a module's hook machine-wide, the project copy makes it fire
twice: two processes per event, and on a blocking hook two denials
(seen with the re-read guard on content_manager, 2026-11-04). Check
`~/.claude/settings.json` for each hook a module ships *before* pasting
the project block. Still vendor the script, so the host is complete on
a machine without the dotfiles, but leave the duplicate block out and
record why in the host's settings `_comment` and the `MODULES.md`
Override column.

A starting point is
[../templates/_shared/claude-settings.example.json](../templates/_shared/claude-settings.example.json).
Copy → adjust → drop in the host's `.claude/settings.json`.
Note any deviations in `MODULES.md` under the **Override**
column.

## 7. Verify the wiring on first session

Open a fresh Claude session in the host repo. Confirm that:

- Claude reads `CLAUDE.md` at session start and the `Composed
  modules` table is visible in the loaded context.
- A small test branch (e.g., `chore/test-session-end`) with a
  trivial edit runs the full session-end loop: doc sync →
  commit → push → `gh pr create` → `AskUserQuestion` popup,
  ending with the fixed-format **Session end** block after
  merge + cleanup.
- **Each guard fires.** A deny rule that never fires looks exactly
  like one that works, so trip one forbidden action per rule family.
  A fresh `claude -p "read /etc/hostname"` from the host root should
  be refused, and its stderr lists every permission rule it can't
  match (a free lint). Check any new ignore rule with `git check-ignore -v` on
  a path it must ignore *and* one it must leave tracked
  (`playbook/04` §Test a pattern both ways).

If the loop skips a step, that's a wiring problem in `CLAUDE.md`
or `.claude/settings.json`, not a Claude problem — fix the host,
not the module.

## 8. Updating modules later

When this canonical repo bumps a module's version:

1. Re-copy: `cp -R /path/to/canonical/modules/<name> modules/` — or
   re-run [../scripts/install-modules.sh](../scripts/install-modules.sh)
   at the newer canonical commit, which handles steps 1–2
   idempotently (the row updates in place, not duplicated).
2. Update the row in `MODULES.md` (new version, new source
   commit, new `copied_at`).
3. If the *steps* changed, re-paste the short form into
   `CLAUDE.md`.
4. Open a `chore/refresh-modules` PR in the host repo so the
   bump is reviewable and the **Delivered + Verified** footer
   records what was refreshed.

Don't auto-update across multiple modules in one PR if the
short-form re-paste involves judgment calls — one module per
PR makes the diff readable.

## 9. Vendor the paired skills

> **Mode A automates this section** —
> [../scripts/install-modules.sh](../scripts/install-modules.sh) vendors
> the paired + standalone skills alongside the modules. The steps below
> are the manual equivalent, and the fallback the bootstrap prompt
> (Mode B) points at when the script is absent.

A reusable convention lives at up to three layers (see
[../skills/README.md](../skills/README.md)): the **canonical text**
(`prompts/<name>.md` or a `prompt`-type module), the **runtime skill**
(`skills/<name>/SKILL.md`), and Chris's personal **machine-global
command**. A vendored module is only half-wired without its skill —
the module is the rule, the skill is the surface that makes the agent
*reach for* it mid-session. So whenever you vendor a module, vendor its
backing skill too.

**The module↔skill link.** A skill that shims a module declares it in
frontmatter: `module: <module-name>`. The install script reads that
field — for every installed module, it copies any skill whose `module:`
matches into the host's `.claude/skills/<name>/`. Skills that back **no**
module (`scope-guard`, `constraint-check`, `explain-back`,
`minimal-repro`, `plane-board-ops`) are standalone; vendor those explicitly with
`--skill <name>`.

**Where skills land — and why no `CLAUDE.md` paste.** Unlike modules
(which only take effect because `CLAUDE.md` links them, per §4), Claude
Code **auto-surfaces** anything under `.claude/skills/`. So the wiring
is just the file on disk plus a `SKILLS.md` ledger row — no
Composed-modules-style paste, no short-form mirror. Don't add skills to
the `CLAUDE.md` modules table.

**Links sit one level deeper.** The script re-points a skill's links the
same way it does a module's (§3). The difference is that the copy sits
at `.claude/skills/<name>/`, one level below `skills/<name>/` here, so
a link to a vendored module gains a `../`. The manual recipe below
skips this step.

**The `SKILLS.md` ledger** mirrors `MODULES.md`, with one extra column
recording which module each skill backs:

```markdown
# Vendored skills

Pulled from
[agentic_optimization_research/skills/](https://github.com/ChrisKornaros/agentic_optimization_research/tree/main/skills).
Each skill is a thin SKILL.md shim, vendored into `.claude/skills/<name>/`.
Local overrides go in the **Override** column.

| Skill | Version | Source commit | Copied at | Backs module | Override |
|---|---|---|---|---|---|
| session-wrapup | 1.0.0 | `<commit>` | 2026-06-03 | git-flow-session-end | — |
| scope-guard | 1.0.0 | `<commit>` | 2026-06-03 | — | — |
```

**Manual recipe** (when the script isn't available):

```sh
# from the host repo root, per skill you want
mkdir -p .claude/skills
cp -R /path/to/agentic_optimization_research/skills/session-wrapup .claude/skills/
# then add a SKILLS.md row with the source commit (run from canonical):
git rev-parse --short HEAD
```

**Override protection** works exactly like modules: a host-local
`.claude/skills/<name>/.override` sentinel (or a non-empty Override
column) makes the script refuse to clobber a customized skill unless you
pass `--force`.

## 10. Vendor the runnable tools

> **Mode A automates this section** —
> [../scripts/install-modules.sh](../scripts/install-modules.sh) vendors
> a tool with `--tool <name>`. The steps below are the manual
> equivalent, and the fallback the bootstrap prompt (Mode B) points at
> when the script is absent.

Some conventions aren't text at all — they're **runnable tools** the
agent uses mid-session. The canonical example is
[../tools/search-docs/](../tools/search-docs/), a BM25 doc-retrieval MCP
server that surfaces as `mcp__search_docs__search`. These live in
[../tools/](../tools/) and are opt-in (there's no module to auto-pair
them to): vendor one with `--tool <name>`.

**A tool needs *two* wirings, and they're separate on purpose:**

1. **To run** — an entry in the host's root `.mcp.json` so Claude Code
   launches the server. The tool declares its own wiring in a
   `mcp-entry.json` (server key + command + a `__DIR__` placeholder);
   the install script substitutes the vendored path and prints the
   ready-to-merge snippet. It does **not** edit `.mcp.json` for you —
   like `CLAUDE.md` and `settings.json`, that stays a judgment edit.
2. **To be used** — a one-line *"prefer `search_docs` over `grep` for
   rule/doc lookup"* nudge in the host's `CLAUDE.md`. This is not
   optional polish: H1
   found a silently-registered MCP server sat at **zero adoption** —
   present in the toolset but invisible at decision time. A tool with
   wiring #1 but not #2 runs and is never called.

**Where tools land — and the `TOOLS.md` ledger.** The package is copied
to `<host>/.claude/tools/<name>/` (with `.venv`/`__pycache__` pruned).
The corpus root auto-detects the host (nearest ancestor with `.git` +
`CLAUDE.md`); a host can pass `env` in its `.mcp.json` (e.g.
`SEARCH_DOCS_EXCLUDE_PREFIXES`) to drop generated/vendored subtrees. The
ledger mirrors `MODULES.md`:

```markdown
# Vendored tools

Pulled from
[agentic_optimization_research/tools/](https://github.com/ChrisKornaros/agentic_optimization_research/tree/main/tools).
Each tool is a runnable agent tool (e.g. an MCP server), vendored into
`.claude/tools/<name>/` and wired into the host `.mcp.json`.

| Tool | Version | Source commit | Copied at | Override |
|---|---|---|---|---|
| search-docs | 0.2.0 | `<commit>` | 2026-06-03 | — |
```

**A tool's docs get their links re-pointed too.** The script re-points
the links in a tool's top-level `.md` files as it does a skill's (§9),
since the copy also sits one level deeper than `tools/<name>/` here.
The manual recipe below skips this step.

**Manual recipe** (when the script isn't available):

```sh
# from the host repo root, per tool you want
mkdir -p .claude/tools
cp -R /path/to/agentic_optimization_research/tools/search-docs .claude/tools/
rm -rf .claude/tools/search-docs/.venv
find .claude/tools/search-docs -name __pycache__ -type d -prune -exec rm -rf {} +
# add a TOOLS.md row with the source commit (run from canonical):
git rev-parse --short HEAD
# then merge tools/search-docs/mcp-entry.json's {server_key: server}
# (with __DIR__ → .claude/tools/search-docs) into .mcp.json, and add the
# "prefer search_docs over grep" nudge to CLAUDE.md.
```

**Override protection** works like modules/skills: a host-local
`.claude/tools/<name>/.override` sentinel (or a non-empty Override
column) makes the script refuse to clobber a customized tool unless you
pass `--force`.

## Anti-patterns

- **Linking without pasting the short form.** The link gets
  ignored once Claude is deep in a task. The numbered short
  form in `CLAUDE.md` is what actually steers behavior.
- **Pasting the full module body into `CLAUDE.md`.** Drift is
  guaranteed; `MODULES.md` becomes a lie.
- **Skipping `MODULES.md`.** Six months later, no one knows
  whether a surprising rule came from a vendored module, was
  overridden locally, or is just stale.
- **Vendoring modules without locking down the matching
  permission rules.** The session-end module assumes
  `gh pr merge` is denied; without that, the "popup-for-merge"
  pattern silently degrades to "agent merges, human reviews
  after."
- **Editing vendored module text in place** (instead of in the
  canonical repo). The next re-copy clobbers the edit. If a
  module needs a host-local change, override in
  `CLAUDE.md` and note it in `MODULES.md`.
- **Vendoring a `prompt`-type module without its skill.** The module
  is the rule; the skill is what makes the agent reach for it. A module
  with no surfaced shim is a rule nobody invokes. Let the script
  auto-pair it (§9), or `cp -R` the skill manually.
- **Pasting a skill into the `CLAUDE.md` Composed-modules table.**
  Skills are auto-surfaced from `.claude/skills/` — a table row does
  nothing but invite drift. The `SKILLS.md` ledger is their only
  provenance record.
- **Vendoring a tool without its discoverability nudge.** A
  `search_docs`-style MCP server that's registered in `.mcp.json` but
  never mentioned in `CLAUDE.md` gets zero adoption (H1's finding) — the
  agent reaches for its reflexive `grep` instead. The `.mcp.json` entry
  makes it *run*; the CLAUDE.md nudge makes it *get used*. Ship both.

## Related

- `03-instruction-modules` — full spec
- `05-import-workflow` — spec for the three modes (script + two prompts) layered on top of this recipe
- [../scripts/install-modules.sh](../scripts/install-modules.sh) — Mode A: the script that automates §§3–4 + §9 (skill vendoring) idempotently
- [../skills/README.md](../skills/README.md) — the skills library §9 vendors from
- [../prompts/bootstrap-host-repo.md](../prompts/bootstrap-host-repo.md) — Mode B: bootstrap prompt for fresh repos
- [../prompts/retrofit-audit.md](../prompts/retrofit-audit.md) — Mode C: read-only retrofit audit for existing repos
- `bootstrap-repo` — `/bootstrap-repo` slash command shim (Mode B primary invocation)
- `audit-repo` — `/audit-repo` slash command shim (Mode C primary invocation)
- `dotfiles/README` — how to vendor the shims into `~/.claude/` on a new machine
- [README.md](README.md) — modules index in this repo
- [_spec/frontmatter.md](_spec/frontmatter.md) — frontmatter reference
- [../templates/_shared/claude-settings.example.json](../templates/_shared/claude-settings.example.json) — starting permission set
- `recommended-setup` — worked example of vendoring into a fresh repo
