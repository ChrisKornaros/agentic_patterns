# platform-monorepo template

A starter kit for a **docs + code platform monorepo** whose agent
surface is a plain `AGENTS.md` contract — built for environments
*without* the Claude Code runtime (no hooks, skills, or
`settings.json` layer): IDE coding assistants, other-vendor agents, or
locked-down corporate tooling. Convention enforcement moves from the
agent runtime to the platform: branch permissions, a PR-description
template, and CI.

The shape: business-area directories at the root, a map-not-territory
agent contract, conventions vendored from the public
[agentic_patterns](https://github.com/ChrisKornaros/agentic_patterns)
library with a provenance ledger, and a link-integrity check as the
repo's "build." The structure derives from
[claude-md-as-map](../../modules/claude-md-as-map/index.md) and
[docs-two-layer](../../modules/docs-two-layer/index.md).

## What's inside

| File | What it is |
|---|---|
| [AGENTS.template.md](AGENTS.template.md) | The root agent contract — a one-screen map: conventions table, inline short-form workflow, named prompts, area pointers |
| [CONVENTIONS.template.md](CONVENTIONS.template.md) | The provenance ledger — source pin line + rule-level deviations only (wording adaptation is expected, not logged) |
| [docs/conventions/vendor-manifest.txt](docs/conventions/vendor-manifest.txt) | Which conventions to vendor; read by the vendor script. Ships with the day-one set; Tier-2 entries commented out |
| [scripts/vendor-conventions.sh](scripts/vendor-conventions.sh) | Vendors/re-vendors convention texts + prompts from an `agentic_patterns` clone, stamps provenance headers, refreshes the ledger pin, audits dependencies |
| [scripts/check_docs_links.sh](scripts/check_docs_links.sh) | The verifier: every relative markdown link resolves. Wire into CI on every PR |
| [tree.txt](tree.txt) | Recommended directory layout |

## How to use

```sh
# 1. Copy the template into the new repo root (or an existing monorepo)
cp -r templates/platform-monorepo/ ../platform-repo/
cd ../platform-repo/

# 2. Clone the conventions source somewhere local, then vendor
git clone https://github.com/ChrisKornaros/agentic_patterns.git ~/src/agentic_patterns
scripts/vendor-conventions.sh --source ~/src/agentic_patterns

# 3. Instantiate the contract files
mv AGENTS.template.md AGENTS.md
mv CONVENTIONS.template.md CONVENTIONS.md
#    …then fill every {{PLACEHOLDER}} and adapt the vendored texts in
#    docs/conventions/ for your platform (issue keys, UI names, tooling).

# 4. Verify
scripts/check_docs_links.sh
```

Then wire the platform layer — this template's equivalent of an agent
runtime's permission rules:

1. **Branch permissions** on the default branch: no direct pushes;
   merge via PR only, by a human.
2. **PR-description template** carrying a fixed-format session-summary
   section (replaces an end-of-session hook).
3. **CI**: `check_docs_links.sh` on every PR; docs→wiki publish (if you
   have one) on merge to the default branch only.

## Re-vendoring later

Re-run `scripts/vendor-conventions.sh --source <clone>` with the clone
checked out at the newer commit. Existing files are never clobbered —
local adaptation is expected — so updates land as `<name>.md.new`
files to diff and merge by hand. The ledger's pin line updates
automatically; record any *rule-level* deviation in the Deviations
table.

## Departures from this library's other templates

- **No `.claude/settings.json`** — there is no agent-runtime
  enforcement layer in the target environment; the platform enforces.
- **`AGENTS.md`, not `CLAUDE.md`** — the emerging cross-vendor
  contract filename. If your agent auto-loads a different filename,
  make that file a one-line pointer to `AGENTS.md` and keep
  `AGENTS.md` canonical. Either way, open every session with the
  kickoff prompt, which begins "read `AGENTS.md` first" — auto-load is
  a bonus, not the mechanism.
- **The verifier is link integrity**, not a smoke test — for a
  docs-heavy repo, resolving cross-references *is* the build.
