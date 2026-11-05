# Bootstrap host repo (Mode B of import workflow)

Use at the **start of a fresh Claude Code session in a target host
repo** to vendor in a coherent set of modules from the canonical
`agentic_optimization_research` repo. This is Mode B of the import
workflow per
[roadmap/05-import-workflow.md §5](https://github.com/ChrisKornaros/agentic_optimization_research/blob/main/roadmap/05-import-workflow.md#5-mode-b--the-bootstrap-prompt).

## How to invoke

**Primary — slash command.** If `/bootstrap-repo` is installed under
`~/.claude/commands/` (one-line adoption from
`dotfiles/README`), just type
`/bootstrap-repo` in any Claude Code session in the target repo. The
shim resolves the canonical path and reads this prompt for you. The
shim canonical source lives at
`bootstrap-repo`.

**Fallback — paste the prompt body below.** The prompt is
**self-contained**: paste it into a session in the host repo (not the
canonical repo). Claude won't have the canonical `CLAUDE.md`
auto-loaded — the prompt tells it where to look.

```
You are bootstrapping this repo's agent context from the
`agentic_optimization_research` module library. The goal is a host
repo whose `CLAUDE.md` composes vendored modules, `MODULES.md`
records what's installed, `.claude/skills/` carries the runnable
skill shims with `SKILLS.md` recording them, and
`.claude/settings.json` matches the guardrails the modules assume —
produced in ONE session, ending in a PR I review and merge.

Inputs you should resolve up front (use AskUserQuestion if any are
unclear):
  - Path to the canonical `agentic_optimization_research` checkout.
    The `/bootstrap-repo` shim resolves this to the GitHub mirror at
    `~/.cache/agentic_optimization_research` (Step 0). If you're
    pasting this prompt by hand instead, point at wherever your clone
    lives (e.g. `~/vault/projects/agentic_optimization_research`) or
    refresh the same cache the shim uses.
  - Whether the host already has any of: `CLAUDE.md`,
    `.claude/settings.json`, `modules/`, `MODULES.md`. If so, this
    is "extend the wiring" not "bootstrap a virgin repo."
  - Branch name to do the work on. Default `chore/bootstrap-modules`
    if the repo follows GitHub Flow.

Then, in order:

1. **Sense the archetype.** Read `package.json`, `pyproject.toml`,
   `Cargo.toml`, top-level dirs. Decide whether the repo looks like
   an application, a library, a data pipeline, a CLI/ops tool, a
   discord-bot-shaped service, etc. Map to a `templates/<archetype>/`
   folder in the canonical repo if one fits — that folder's
   `CLAUDE.md` is the closest reference shape.

2. **Survey what's there.** If `CLAUDE.md` or `.claude/settings.json`
   already exist, read them. If `modules/` already exists, read
   `MODULES.md` (or note that the ledger is missing). Decide
   bootstrap-vs-extend before proposing anything.

3. **Detect the dogfooding case.** If the host IS the canonical repo
   (its root `CLAUDE.md` references `agentic_optimization_research`
   as a meta-repo, or its `modules/` is the canonical source), STOP
   and explain — there's nothing to vendor into a source.

4. **Read the canonical module list.** From the canonical checkout,
   read `modules/README.md` and the frontmatter of each
   `modules/<name>/index.md` (`type`, `scope`, `dependencies`,
   `applies_when`, `version`). Build a candidate list.

5. **Propose a module set via AskUserQuestion (multiSelect).** Pre-
   check defaults by archetype. The near-universal baseline — pre-
   check for *every* archetype: the git-flow family
   (`git-flow-no-direct-main`, `git-flow-session-end`, and its three
   day-to-day companions `git-flow-branch-naming`,
   `auto-commit-on-branch-done`, `ask-merged-via-popup`),
   `smoke-before-commit` (any repo with a verifier),
   `phase-kickoff`, the scope-of-action pair (`stay-in-project-tree`,
   `no-sudo-as-shortcut`, for any host where the agent has shell
   access), and `no-cat-head-via-bash` (any host with the standard
   Read/Edit/Write tool surface — note it's `lifecycle: experimental`
   when you surface it). Then the archetype-specific adds: Python
   repos add `python-uv-only`; data-shaped repos add
   `duckdb-default-store`; repos that deploy to a host whose arch
   differs from the dev machine's add `deploy-target-arch`.
   Don't hardcode this list as exhaustive — step 4 read the live
   `modules/README.md`, so pre-check anything there whose
   `applies_when:` matches the archetype, and let these defaults be
   the floor, not the ceiling. Resolve declared `dependencies:` — if
   a chosen module depends on one that isn't checked, surface and
   re-confirm.

5b. **Offer the standalone skills (second AskUserQuestion,
   multiSelect).** Skills that *back a module* come for free — the
   install script auto-vendors any skill whose frontmatter `module:`
   names a module you chose in step 5 (e.g. `session-wrapup` rides
   along with `git-flow-session-end`, `phase-kickoff` with its module).
   You only need to ask about the *standalone* skills that back no
   module: read `skills/*/SKILL.md` frontmatter, list the ones with no
   `module:` field (today: `scope-guard`, `constraint-check`,
   `explain-back`, `minimal-repro`, `plane-board-ops`), and pre-check `scope-guard` — the
   one the done-definition names alongside `/session-wrapup`. Whatever
   Chris checks becomes the `--skill <name>` list for step 6. If
   `skills/` is absent from the canonical checkout, skip this step.

5c. **Offer the runnable tools (third AskUserQuestion, multiSelect).**
   Read `tools/*/mcp-entry.json` in the canonical checkout — each is a
   vendorable tool (an MCP server). Today the only one is `search-docs`
   (BM25 doc-retrieval; surfaces as `mcp__search_docs__search`).
   Pre-check it for any **doc-heavy / markdown-rich** repo — which is
   most of them, and `content_manager` especially. Whatever Chris checks
   becomes the `--tool <name>` list for step 6. If `tools/` is absent
   from the canonical checkout, skip this step. **Carry forward:** a
   vendored MCP tool is inert unless it's *discoverable* — step 8 wires
   its `.mcp.json` entry **and** adds the CLAUDE.md "prefer it over grep"
   nudge, because H1 proved a silently-registered server gets zero
   adoption.

6. **Execute the install.** If
   `scripts/install-modules.sh` exists in the canonical checkout,
   call it with the host path, the resolved module list, a
   `--skill <name>` flag per standalone skill chosen in step 5b, and a
   `--tool <name>` flag per tool chosen in step 5c. The script copies
   the modules, auto-pairs each module's backing skill into
   `<host>/.claude/skills/`, vendors the standalone skills and the tools
   (into `<host>/.claude/tools/`, pruning `.venv`/`__pycache__`), and
   writes `MODULES.md`, `SKILLS.md`, and `TOOLS.md`. If the script is
   absent, fall back to the manual recipe in `modules/VENDORING.md`
   §§3-4, §9, and §10 (cp -R the module/skill/tool dirs, upsert the
   ledgers). Capture stdout — the Composed-modules snippet is what step 7
   needs, and the follow-up checklist names the vendored skills **and the
   `.mcp.json` snippet for each vendored tool** (which step 8 merges in).

7. **Wire the host's `CLAUDE.md`.** If missing, create a minimal
   one using `modules/VENDORING.md` §4 shape (one-paragraph repo
   description, `## Composed modules` table from step 6's snippet,
   `## Project-specific` placeholder). If it exists, add a
   `## Composed modules` section near the top — don't overwrite
   project-specific content. For each `workflow`-type module
   installed, also paste its short-form steps inline per
   `modules/VENDORING.md` §5 (the short form is the load-bearing
   copy; the link is the canonical reference). **Write (and leave)
   the file as a map, not the territory** — short orientation +
   pointers, target well under ~200 lines, detail in lazy surfaces
   with a trigger of matched strength per
   `modules/claude-md-as-map/index.md`. That budget covers the whole
   eager chain, so count the lines the host inherits first (the
   user-level `~/.claude/CLAUDE.md`, plus any ancestor directory's
   `CLAUDE.md` when the host is nested under another repo). The host's
   own file gets what's left. If the host's existing
   CLAUDE.md is already over that, note it in the follow-up
   checklist rather than growing it further. **If you vendored a tool
   in step 5c, add the discoverability nudge here too** — a one-line
   "prefer `search_docs` over `grep` for rule/doc lookup" under
   `## Conventions` (or near the top). H1 showed a silently-registered
   MCP server gets zero adoption; the nudge is what makes the agent
   reach for it.

8. **Wire `.claude/settings.json` (and hooks).** If missing, copy
   `templates/_shared/claude-settings.example.json` from the
   canonical repo wholesale. If it exists, surgically add the denies +
   hooks the chosen modules assume — *which ones depend on which
   modules you installed in step 6*. Each module enforces itself
   through one of three mechanisms (see `modules/VENDORING.md` §6 for
   the full table); read each installed module's `## Companion files`
   section to find which it uses:
     - **Baked into the example** — git-flow modules → `gh pr merge`,
       `git push origin main`, `git push --force` (the load-bearing
       trio). Already in the example settings.
     - **`settings-snippet.json` companion** — `no-sudo-as-shortcut`
       (sudo/su/chown/chmod 777 + privileged docker/kubectl) and
       `stay-in-project-tree` (out-of-tree paths: `/etc`, `/usr`,
       `/var`, `~/.ssh`, `~/.aws`, `~/.config/gh`, shell rc files,
       `~/.claude/`). After `cp -R`, merge each module's
       `modules/<name>/settings-snippet.json` `deny` array in. The
       install script's follow-up checklist names which installed
       modules ship one.
     - **Hook companion** — `no-cat-head-via-bash` ships
       `pre_read_guard.py`; keep the example settings' `hooks` block
       (a `PreToolUse` guard on `Read|Edit|Write|MultiEdit`, written
       to no-op until the module is present). The example also wires
       `git-flow-session-end`'s `session_end_guard.py` (`Stop`) and
       `session-handoff`'s `session_handoff_kickoff.py` (`SessionStart`);
       `git-flow-session-end`'s `pre_pr_wrapup_nudge.py` (`PreToolUse`)
       comes from its `settings-snippet.json`.
   **Before copying any hook, read the user-level
   `~/.claude/settings.json`.** User and project hooks merge rather
   than override, so a hook the machine already runs (a SessionStart
   hand-off kickoff, a Stop guard, a re-read guard) fires twice if the
   project repeats it. Leave those out, and record the omission in a
   `_comment` in the host's settings and in `MODULES.md`, so they get
   re-added if the repo is ever run without those user settings.
   Don't loosen anything already denied. If an installed module names
   denies/hooks not listed above, prefer the module body over this
   list — it's the canonical source, and `modules/VENDORING.md` §6 may
   lag newer modules.

   **Wire vendored tools into `.mcp.json` (if step 5c installed any).**
   Each tool is registered as a project-scoped MCP server. Merge the
   `.mcp.json` snippet the install script emitted (step 6 follow-up
   checklist) into the host's root `.mcp.json` under `mcpServers` —
   create the file with `{ "mcpServers": { … } }` if missing. The
   snippet already points `--directory` at `.claude/tools/<name>/`. A
   host may add an `env` (e.g. `SEARCH_DOCS_EXCLUDE_PREFIXES`) to drop
   generated/vendored subtrees from the corpus. This is the wiring that
   actually makes the tool run; the CLAUDE.md nudge (step 7) is what
   makes the agent *use* it — do both, per `modules/VENDORING.md` §10.

9. **Verify the wiring.** Run the smoke check from
   `modules/VENDORING.md` §7: does the host's `CLAUDE.md` render
   with the Composed-modules table? Does `MODULES.md` have one
   row per installed module with a real source commit? Does each
   vendored skill have a `<host>/.claude/skills/<name>/SKILL.md` and
   a `SKILLS.md` row? Skills are **not** pasted into `CLAUDE.md` —
   Claude Code auto-surfaces anything under `.claude/skills/`, so the
   ledger plus the file on disk is the whole wiring. For each vendored
   tool: is there a `<host>/.claude/tools/<name>/` dir, a `TOOLS.md`
   row, a matching `mcpServers` entry in `.mcp.json`, **and** the
   CLAUDE.md discoverability nudge? A tool missing its `.mcp.json` entry
   won't load; one missing the nudge loads but goes unused. Then trip each
   guard once (§7's last check): a headless `claude -p` asked to read a
   denied path must be refused. If anything's missing or silent, fix the
   host (not the modules/skills/tools) and re-verify.

10. **Open a PR.** Standard GitHub Flow per the modules just
    installed: commit, push, `gh pr create`, then surface
    AskUserQuestion("merged? — Merged / Not yet / Changes
    requested") and run the rest of the session-end loop. End with
    the fixed-format **Session end** block from the
    `git-flow-session-end` module.

DO NOT skip steps 2 or 3 (the "is this virgin or half-wired? is
this the canonical repo itself?" gates) — silently overwriting
existing context is the worst failure mode here.
```

## Why this works

This prompt operationalizes the manual recipe in
[modules/VENDORING.md](../modules/VENDORING.md) by giving Claude an
explicit orient → propose → execute → verify loop. The same shape
as [phase-kickoff.md](phase-kickoff.md), tuned for "bring a fresh
repo into the module ecosystem" instead of "implement a roadmap
phase."

Three load-bearing design choices:

- **AskUserQuestion at step 5, not free-text.** Module selection is
  the one judgment call that benefits from a popup — Chris can
  see all defaults at once, uncheck what doesn't fit, and the
  session stays continuous (no cold restart waiting on a reply).
- **The script is preferred but not required.** Step 6 calls
  `scripts/install-modules.sh` when present, falls back to the
  manual recipe otherwise. This means the prompt works even
  against a canonical checkout that pre-dates the script — useful
  when bootstrapping a host repo from an older snapshot.
- **Dogfooding gate at step 3.** Running this prompt inside the
  canonical repo itself would try to vendor modules from
  `modules/` into `modules/` — a silent no-op at best, a corrupted
  ledger at worst. Detect-and-stop is cheaper than detect-and-recover.
- **Skills auto-pair; only standalone ones need a question.** A
  prompt-module is inert without its runnable shim, so step 6's script
  vendors the backing skill alongside any module that has one — no
  extra judgment. Step 5b only surfaces the *standalone* skills (the
  ones backing no module) as a separate popup, so the common case
  stays one decision (the module set) and the skill set follows from
  it. This is the "a prompt-module never lands without its shim, and
  vice versa" guarantee from
  `roadmap/08` C1.
- **Tools need two wirings, and H1 is why.** A vendored MCP tool isn't
  done when its code lands — it needs an `.mcp.json` entry to *run* (step
  8) and a CLAUDE.md nudge to be *used* (step 7). The
  H1 RESULT
  found a silently-registered server sat at zero adoption: present but
  invisible at decision time. So unlike skills (auto-surfaced, one
  wiring), tools are deliberately two explicit steps — skipping the nudge
  ships a tool nobody calls.

Steps 7-8 are deliberately surgical (don't overwrite, don't loosen).
The bootstrap prompt operates on a real repo with real prior state;
treating its `CLAUDE.md` and settings as additive is the only safe
default.

Cross-refs:
- `05-import-workflow` §5 — the contract this prompt implements
- [modules/VENDORING.md](../modules/VENDORING.md) — the manual recipe behind step 6's fallback
- [scripts/install-modules.sh](../scripts/install-modules.sh) — Mode A, what step 6 prefers to call (now also vendors paired + `--skill` standalone skills)
- [../skills/README.md](../skills/README.md) — the skills library steps 5b/6 vendor from
- [../tools/README.md](../tools/README.md) — the tools library step 5c vendors from; each tool declares its `.mcp.json` wiring in `mcp-entry.json`
- [retrofit-audit.md](retrofit-audit.md) — Mode C, the read-only counterpart for existing repos with informal conventions
- `bootstrap-repo` — the `/bootstrap-repo` slash command shim (primary invocation)
- `dotfiles/README` — how to install the shim on a new machine
