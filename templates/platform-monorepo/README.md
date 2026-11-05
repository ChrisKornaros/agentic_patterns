# platform-monorepo template

A starter kit for a **docs + code platform monorepo** whose agent
surface is a plain `AGENTS.md` contract. It serves two kinds of user
from one contract:

- **Seatless** — IDE coding assistants, other-vendor agents, or
  locked-down corporate tooling with no Claude Code runtime. Convention
  enforcement lives in the platform: branch permissions, a
  PR-description template, and CI. This is the template as first built.
- **With a Claude Code seat** — the same contract, plus an optional
  **runtime layer**: a one-line `CLAUDE.md` that includes `AGENTS.md`,
  a `.claude/settings.json` composed from the permission and hook
  snippets the vendored modules ship, and the modules themselves
  installed from a meta-repo with ledgers. The runtime enforces what
  the platform already enforces; it removes nothing from the seatless
  path.

The shape: business-area directories at the root, a map-not-territory
agent contract, conventions vendored from the public
[agentic_patterns](https://github.com/ChrisKornaros/agentic_patterns)
library with a provenance ledger, and `scripts/smoke.sh` as the
repo's "build." The structure derives from
[claude-md-as-map](../../modules/claude-md-as-map/index.md) and
[docs-two-layer](../../modules/docs-two-layer/index.md).

## What's inside

| File | What it is |
|---|---|
| [AGENTS.template.md](AGENTS.template.md) | The root agent contract — a one-screen map: conventions table, inline short-form workflow, named prompts, area pointers. Canonical for every agent and vendor |
| [CLAUDE.md](CLAUDE.md) | The runtime layer's contract file: one `@AGENTS.md` include line so a Claude Code session loads the same contract. Inert without a seat |
| [CONVENTIONS.template.md](CONVENTIONS.template.md) | The provenance ledger for the convention *texts* — source pin line + rule-level deviations only (wording adaptation is expected, not logged) |
| [.claude/settings.json](.claude/settings.json) | The runtime layer's permissions and hook enforcers, composed block by block from the modules' settings snippets; each block names its source. The allow list is the factory's contract (below) |
| [docs/conventions/vendor-manifest.txt](docs/conventions/vendor-manifest.txt) | Which conventions to vendor; read by the vendor script. Ships with the day-one set; Tier-2 entries commented out |
| [scripts/vendor-conventions.sh](scripts/vendor-conventions.sh) | Vendors/re-vendors convention texts + prompts from an `agentic_patterns` clone, stamps provenance headers, refreshes the ledger pin, audits dependencies |
| [scripts/check_docs_links.sh](scripts/check_docs_links.sh) | Every relative markdown link resolves, and every `#heading` anchor names a real heading (GitHub slug rules; `--no-anchors` for a host that slugs differently). Needs bash 3.2+ and perl |
| [scripts/smoke.sh](scripts/smoke.sh) | The gate: contract files renamed, no `{{placeholder}}` left, the link check, then each area's verify command from the Areas table. A fresh copy exits 2 and names what to fill in. Wire into CI on every PR |
| [tree.txt](tree.txt) | Recommended directory layout, both routes |

## How to use

```sh
# 1. Copy the template into the new repo root (or an existing monorepo)
cp -r templates/platform-monorepo/ ../platform-repo/
cd ../platform-repo/

# 2. Clone the conventions source somewhere local, then vendor the texts
git clone https://github.com/ChrisKornaros/agentic_patterns.git ~/src/agentic_patterns
scripts/vendor-conventions.sh --source ~/src/agentic_patterns

# 3. Instantiate the contract files
mv AGENTS.template.md AGENTS.md
mv CONVENTIONS.template.md CONVENTIONS.md
#    …then fill every {{PLACEHOLDER}} and adapt the vendored texts in
#    docs/conventions/ for your platform (issue keys, UI names, tooling).

# 4. Verify — a fresh copy exits 2 here and lists every placeholder left
scripts/smoke.sh
```

Then wire the platform layer — the enforcement every user gets, seat
or not:

1. **Branch permissions** on the default branch: no direct pushes;
   merge via PR only, by a human.
2. **PR-description template** carrying a fixed-format session-summary
   section (replaces an end-of-session hook).
3. **CI**: `scripts/smoke.sh` on every PR (it runs the link check);
   docs→wiki publish (if you have one) on merge to the default branch
   only.

### With a Claude Code seat: the runtime layer

Skip this section for a seatless repo; delete `CLAUDE.md` and
`.claude/settings.json` or leave them, they are inert. With a seat:

```sh
# 5. Install the modules from your meta-repo (the organisation's pinned
#    copy of agentic_patterns, or a clone of agentic_patterns itself).
#    install-modules.sh writes MODULES.md and SKILLS.md here, with the pin.
<meta-repo>/scripts/install-modules.sh . \
    git-flow-no-direct-main git-flow-branch-naming secrets-no-plaintext \
    assumptions-before-code verifiable-goal-before-code minimum-code-first \
    surgical-diffs-only smoke-before-commit claude-md-as-map docs-two-layer \
    session-handoff git-flow-session-end no-cat-head-via-bash

# 6. Lint the settings in the same sitting, then trip one deny
claude -p "read /etc/hostname"      # stderr lists any rule it could not parse

# 7. Verify again: the hook scripts now show as vendored, not fail-open
scripts/smoke.sh
```

What the layer adds, and the rule for each piece:

- **`CLAUDE.md` is one line, `@AGENTS.md`.** `AGENTS.md` stays the
  contract for everyone; the include is how a seat's session loads it.
  Never put a rule in `CLAUDE.md`.
- **`modules/` is the enforcement half; `docs/conventions/` stays the
  text everyone reads.** The vendor script brings adapted *texts* for
  the `AGENTS.md` map to cite; `install-modules.sh` brings the same
  modules' runnable halves (hook scripts, settings snippets) and their
  paired skills, pinned in `MODULES.md` and `SKILLS.md`. A module's
  `index.md` under `modules/` is the pristine source at the pin; the
  adaptation lives in `docs/conventions/` and its deviations in
  `CONVENTIONS.md`. Two ledgers, two mechanisms, no hand copies.
- **`.claude/settings.json` carries only what the modules ship**, plus
  this repo's own allow list. Each deny block and each hook names the
  snippet it came from, so a re-vendor is a diff. Every hook is
  guarded with `[ -f ] || exit 0` and fails open, so the file is safe
  before the modules arrive and on a machine without them. If the seat
  holder's own `~/.claude/settings.json` already wires one of the
  hooks, leave that block out here and say so in `MODULES.md`'s
  Override column, or it fires twice.
- **The allow list is the factory's contract.** A headless runner job
  (one `claude -p` per worktree, the prompt an agent-ready issue)
  passes the repo's `permissions.allow` through and treats anything at
  `ask` as a refusal. So every command a job needs is allowed
  (`scripts/smoke.sh`, each area's verify command, `git add`, `git
  commit`, a push of its own branch), and what must stay a human's
  (merge, the default branch, force push) is denied, not asked. No
  host CLI is assumed: the runner pushes with plain git, and the PR is
  opened by the runner where a CLI exists or by the seat holder from
  the pushed branch where it does not.
- **Area skills live here until a second repo wants one.** A business
  area's own skill is a directory under the root `.claude/skills/`
  with the area in its name (`<area>-<name>/`), named in that area's
  `AGENTS.md` delta, and absent from `SKILLS.md`, which lists installed
  skills only. When another repo needs it, it moves to the meta-repo's
  `skills/`, loses anything repo-specific, and comes back through
  `install-modules.sh` with a ledger row that replaces the local copy.
  Two areas of one repo share a root-level skill without promotion.
- **The hand-off is `.claude/next-session.md` on both routes.** The
  seatless user reads it by hand at session start; the seat's
  `SessionStart` hook surfaces it. One path, so a repo with both kinds
  of user has one hand-off.
- **A managed policy that forbids hooks** moves enforcement back to
  the platform layer (the seatless shape) and keeps everything else;
  delete the `hooks` block and say so in `MODULES.md`.

## Re-vendoring later

Two mechanisms, one per ledger:

- **The texts** (`docs/conventions/`, pinned in `CONVENTIONS.md`):
  re-run `scripts/vendor-conventions.sh --source <clone>` with the
  clone at the newer commit. Existing files are never clobbered —
  local adaptation is expected — so updates land as `<name>.md.new`
  files to diff and merge by hand. The pin line updates automatically;
  record any *rule-level* deviation in the Deviations table.
- **The modules and skills** (`modules/`, `.claude/skills/`, pinned in
  `MODULES.md` and `SKILLS.md`): re-run `install-modules.sh` from the
  meta-repo at its newer pin. A local change is protected by a
  sentinel file or an Override row and survives the re-vendor; after a
  module whose settings snippet changed, replace that block in
  `.claude/settings.json` with the snippet's current array and lint
  again.

## Departures from this library's other templates

- **`AGENTS.md`, not `CLAUDE.md`, is canonical** — the cross-vendor
  contract filename. `CLAUDE.md` here is only the include. For a
  different agent that auto-loads a different filename, make that file
  the same one-line pointer. Either way, open every session with the
  kickoff prompt, which begins "read `AGENTS.md` first" — auto-load is
  a bonus, not the mechanism.
- **The runtime layer is optional and additive.** The other templates
  assume a Claude Code seat; this one works without it, and the
  `.claude/settings.json` it ships is composed from module snippets
  rather than being a tailored copy of the shared example.
- **The verifier is a docs gate** — contract, placeholders, links,
  then each area's own command — not a server boot: for a docs-heavy
  monorepo, resolving cross-references *is* the build, and each area
  brings its own smoke.
