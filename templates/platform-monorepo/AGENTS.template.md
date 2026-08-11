<!-- Rename to AGENTS.md when instantiating. Keep this file a map: one
screenful of rules and pointers (see docs/conventions/claude-md-as-map.md).
If a section outgrows a paragraph, move the content to docs/ and point at
it. Paths below are backticked, not linked, until the vendor script has
created them — linkify as you instantiate. -->

# {{PROJECT_NAME}} — agent contract

{{One paragraph: what this repo is, which business areas it holds, and
that agents work across all areas from this single contract. Area
contracts carry deltas only.}}

**Read `docs/next-session.md` first if it exists** — it is the hand-off
from the previous session.

## Conventions

The rules for this repo are the adapted conventions under
`docs/conventions/` — provenance and deviations in `CONVENTIONS.md`.
Load the file before acting in its area.

| Convention | Type | Why it's here |
|---|---|---|
| `docs/conventions/git-flow-no-direct-main.md` | guardrail | No commits to the default branch — ever; humans merge PRs in the {{PLATFORM}} UI |
| `docs/conventions/git-flow-branch-naming.md` | guardrail | Branches are `feat\|fix\|docs\|chore/{{JIRA_KEY}}-<nnn>-<slug>` so issue links resolve automatically |
| `docs/conventions/secrets-no-plaintext.md` | guardrail | Secrets never in plaintext — redacted `*.example` only; applies to docs and runbooks, not just code |
| `docs/conventions/assumptions-before-code.md` | discipline | State assumptions out loud before coding |
| `docs/conventions/verifiable-goal-before-code.md` | discipline | Name how the change will be verified before writing it |
| `docs/conventions/minimum-code-first.md` | discipline | Smallest change that meets the goal |
| `docs/conventions/surgical-diffs-only.md` | discipline | No drive-by refactors; diffs stay reviewable |
| `docs/conventions/smoke-before-commit.md` | guardrail | Run the area's verify command before any commit |
| `docs/conventions/claude-md-as-map.md` | structure | This file stays a map, not the territory |
| `docs/conventions/docs-two-layer.md` | structure | `README.md` for humans, `AGENTS.md` for agents — everywhere, both short, never merged |

## Workflow — short form

(The canonical texts live in `docs/conventions/`; these numbered steps
are the always-loaded copy. If the canonical steps change, re-paste
them here — a link alone gets ignored mid-task.)

1. Read `docs/next-session.md` if present. Confirm the goal and how it
   will be verified before editing anything.
2. Branch from the default branch:
   `feat|fix|docs|chore/{{JIRA_KEY}}-<nnn>-<slug>`. Never commit to it
   directly.
3. State your assumptions and the verifiable goal; write the minimum
   code first; keep diffs surgical.
4. Before every commit: run the touched area's verify command (see
   Areas below) and `scripts/check_docs_links.sh` if docs changed.
5. Commit, push the branch, open a PR using the PR template, and fill
   in its session-summary section.
6. A human merges in the {{PLATFORM}} UI. Never merge, and never push
   the default branch.
7. After the merge: delete the branch and rewrite
   `docs/next-session.md` with what the next session needs to know.

## Prompts

Reusable prompts live in `docs/conventions/prompts/` — paste them into
the agent at the named moment (a prompt that is never named here is
never used):

- `session-start.md` — open **every** session with it; it begins by
  reading this file and `docs/next-session.md`
- `session-wrapup.md` — the end-of-session loop (step 5–7 above)
- `scope-guard.md` — before coding anything with creep potential
- `tight-code-review.md` — self-review before requesting review

See the folder for the full set.

## Areas

Area contracts carry only deltas — never restate root rules here or
there.

| Area | Contract | Verify command |
|---|---|---|
| `{{area-a}}/` | `{{area-a}}/AGENTS.md` | `{{command}}` |
| `{{area-b}}/` | `{{area-b}}/AGENTS.md` | `{{command}}` |

## Verify

`scripts/check_docs_links.sh` — every relative markdown link must
resolve; CI runs it on every PR. The docs→{{WIKI}} publish runs on
merge to the default branch only.
