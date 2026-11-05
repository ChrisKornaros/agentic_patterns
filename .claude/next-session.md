# Next session — the shelf's tooling is exported; steady state again

> Updated 2026-11-05 (`chore/export-shelf-tooling`). This repo is
> PUBLIC — keep every committed file (including this one) free of
> private-repo specifics.

## State as of this handoff

- **The export now carries the vendoring chain's tooling** (sync @
  source `e5ef4c6`): `scripts/install-modules.sh`, `check_links.sh`,
  `check_modules.sh`; `modules/VENDORING.md` and `modules/_spec/`;
  `tools/` (search-docs, headless-runner, clew, library-catalog);
  the maintenance-sweep / lens-review / agent-ready-issue /
  tool-trial-sandbox skills and prompts, the bootstrap and
  retrofit-audit prompts; the example settings and the explanation
  template; five more guardrail modules. 24 modules in all.
- **`scripts/` is now mixed:** `publish.sh`, the allowlist and
  `check_links.ignore` are native; the three scripts above are
  exported. `CLAUDE.md` says which is which.
- **Verified from a fresh clone of this branch:** `install-modules.sh
  --dry-run` plans a module, a standalone skill and the search-docs
  tool with no missing path; a real install writes ledgers whose
  "pulled from" line names this repo (the script derives it from the
  clone's `origin`); `check_modules.sh` passes on the 24 modules;
  `check_links.sh` passes with `experiments/**` ignored (its example
  output links against the source tree by design).
- **Only tools with an `mcp-entry.json` vendor by `--tool`** (today:
  search-docs). The runner, the Clew and the catalog run from the
  library checkout itself, which is how the downstream pattern uses
  them.

## Queued next

Nothing is queued. Demand-driven, as before:

1. **Allowlist growth** on demand: add to
   `scripts/publish-allowlist.txt`, re-run `scripts/publish.sh`, then
   run both check scripts here before opening the PR.
2. **The source repo's template work** (its roadmap/16 unit 3) will
   arrive as a later sync of `templates/`.

## Conventions

See `CLAUDE.md`. Publishing is always `scripts/publish.sh` — never
hand-copy content.
