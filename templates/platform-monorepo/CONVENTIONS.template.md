<!-- Rename to CONVENTIONS.md when instantiating. The pin line below is
rewritten automatically by scripts/vendor-conventions.sh — keep its
vendor-pin comment intact. -->

# Conventions ledger

All conventions under `docs/conventions/` are vendored from [agentic_patterns](https://github.com/ChrisKornaros/agentic_patterns) @ `{{COMMIT}}` ({{DATE}}) and adapted for this environment. <!-- vendor-pin -->

This ledger covers the convention *texts*. With a Claude Code seat, the
modules installed under `modules/` and the skills under `.claude/skills/`
are pinned in `MODULES.md` and `SKILLS.md`, written by the meta-repo's
`install-modules.sh`, not here.

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
| Links resolve, placeholders filled, each area's smoke passes | CI: `scripts/smoke.sh` on every PR |
| Docs published to {{WIKI}} | CI, on merge to the default branch only |

With a Claude Code seat the runtime layer enforces the same rules a
second time, in the session; the platform layer stays the floor:

| Rule | Enforced by |
|---|---|
| No push to the default branch, no force push, no merge by the agent | `.claude/settings.json` deny rules (the git-flow trio) |
| Nothing outside the project tree; no elevation | deny rules from `stay-in-project-tree` and `no-sudo-as-shortcut` |
| Hand-off read at session start; the session-end loop run | hooks the `session-handoff` and `git-flow-session-end` modules ship |
| Smoke before every commit | the allow list: `scripts/smoke.sh` and each area's command run without a prompt, so a runner job can run them |
