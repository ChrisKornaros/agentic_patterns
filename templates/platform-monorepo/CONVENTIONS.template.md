<!-- Rename to CONVENTIONS.md when instantiating. The pin line below is
rewritten automatically by scripts/vendor-conventions.sh — keep its
vendor-pin comment intact. -->

# Conventions ledger

All conventions under `docs/conventions/` are vendored from [agentic_patterns](https://github.com/ChrisKornaros/agentic_patterns) @ `{{COMMIT}}` ({{DATE}}) and adapted for this environment. <!-- vendor-pin -->

Vendoring is one-way: copies are **adapted in place** for this
environment (platform names, issue keys, tooling), but the *rules* stay
the source's. Only rule-level deviations are recorded below — wording
adaptation is expected and not logged. To re-vendor at a newer source
commit, run `scripts/vendor-conventions.sh --source <path-to-clone>`
and merge the `.new` files it writes.

## Deviations

| Convention / dependency | Status | Substitution |
|---|---|---|
| `ask-merged-via-popup` | not vendored | The source rule assumes an in-session confirmation popup (an agent-runtime feature). Here a human merges PRs in the {{PLATFORM}} UI; the agent never merges. |
| `auto-commit-on-branch-done` | not vendored | The source rule's safety net is agent-runtime deny rules. Here agents commit only after the verify command passes, and merging stays human-only via branch permissions. |
| `{{convention}}` | adapted | {{What rule-level change was made, and why.}} |

## Enforcement map

Conventions enforce at the platform layer, not agent goodwill:

| Rule | Enforced by |
|---|---|
| No direct commits to the default branch | Branch permissions on {{PLATFORM}} |
| Human-only merge | Merge checks / repo permissions |
| Session summary on every PR | PR-description template |
| Links resolve | CI: `scripts/check_docs_links.sh` on every PR |
| Docs published to {{WIKI}} | CI, on merge to the default branch only |
