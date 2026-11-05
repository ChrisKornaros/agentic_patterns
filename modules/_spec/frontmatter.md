# Module frontmatter — field reference

The authoritative spec is
`03-instruction-modules` §3.
This file is the short reference a module author reaches for
while writing.

## Required fields

| Field | Type | Notes |
|---|---|---|
| `name` | kebab-case string | Must match the parent directory name. Used in `dependencies:`, `[[wikilinks]]`, and host `MODULES.md` ledgers. |
| `type` | enum | `guardrail` \| `workflow` \| `prompt` \| `role` \| `gotcha`. Decides where the host loads the module. |
| `scope` | enum | `repo` (every session in the host), `role` (only when a role is active), `task` (only when invoked by a prompt). |
| `lifecycle` | enum | `stable` (battle-tested), `experimental` (in trial), `deprecated` (scheduled for removal — body explains the replacement). |
| `version` | integer | Bump on breaking changes (semantic meaning of the rule changes). Wording-only edits don't bump. |

## Conditionally required

| Field | When required | Notes |
|---|---|---|
| `evidence` | `lifecycle: stable` | List of repo-root-relative paths to the case study / playbook entries that earn the rule its place. Refused for `deprecated`. |

## Optional

| Field | Notes |
|---|---|
| `dependencies` | List of other module `name:` slugs this module assumes are loaded. Loader (humans, for v1) walks the graph. |
| `applies_when` | Free-text predicates describing when the rule is active (e.g., "repo has a remote"). The host decides whether they match; a future linter could parse them. |

## Body shape

Every module body has, in order:

1. `# {{ Title }}` — human-readable; usually `name` with spaces
   and Title Case.
2. `## Rule` — one paragraph. The thing to do or not do, phrased
   so a future reader can apply it without reading the rest.
3. `## Why` — one paragraph. The incident or hypothesis that
   earned the rule its place. Cite an evidence entry inline.
4. `## How to apply` — 2–5 bullets. Concrete. When the rule
   kicks in, what action it produces.
5. `## Anti-patterns` — bulleted list of common failure shapes.
6. `## This rule is working if` — *optional.* 1–3 observable
   success markers: things a reviewer could check in a diff,
   transcript, or session log to see the rule holding (e.g.
   "every hunk maps to a phrase in the request"). Stolen from
   the success-marker pattern in
   [Karpathy's coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills);
   first used by the per-edit coding-discipline family.
7. `## Related` — `[[wikilinks]]` to neighbor modules (use the
   `name:` slug). Empty list is fine for early modules.

## Example (minimal)

```markdown
---
name: example-rule
type: guardrail
scope: repo
lifecycle: experimental
version: 1
---

# Example Rule

## Rule

[One paragraph stating the rule.]

## Why

[One paragraph citing the motivating incident or constraint.]

## How to apply

- [bullet 1]
- [bullet 2]

## Anti-patterns

- [common failure 1]

## Related

- [[neighbor-module]]
```

## What goes in body links vs. `evidence:`

- `evidence:` — repo-root-relative paths. Machine-readable. The
  authoritative "this rule earned its place because of these."
- Body links — `../../`-relative markdown links. Human-readable
  in GitHub. Used for inline citations in `## Why`, neighbor
  links in `## Related`, and pointers to alternate
  implementations.

Same target, two encodings — the duplication is intentional
until a linter exists to render one from the other.
