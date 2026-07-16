# Next session — steady state, allowlist growth on demand

> Updated 2026-07-15 after the follow-ups session. This repo is
> PUBLIC — keep every committed file (including this one) free of
> private-repo specifics.

## State as of this handoff

All queued post-pipeline follow-ups are closed:

- **Repo contract** — `CLAUDE.md` added (PR #3): native-vs-exported
  boundary, publish rules, branch + PR + merge-popup workflow.
- **Denylist backed up privately** (PR in the source repo). The local
  `.publish-denylist` header says where; sync the backup after editing
  the local file.
- **Cosmetic path leak fixed sanitizer-side** (PR #4). The handoff had
  assumed bare paths in source prose; diagnosis showed the source was
  fully linked and the leaks were sanitizer artifacts — kept link
  labels embedding paths, plus frontmatter `evidence:` lists that
  can't hold links. `scripts/publish.sh` now collapses path tokens in
  kept labels and reduces frontmatter paths to `basename#anchor`.
  Verified with a full publish run (sync @ source `d14ced1`).

## Queued next

Nothing is queued. This repo is demand-driven from here:

1. **Allowlist growth** — when a blog post needs a bundle, add it to
   `scripts/publish-allowlist.txt` and re-run `scripts/publish.sh`.
2. **(Only if it ever bothers)** backticked code-span paths in source
   prose still ship verbatim — they're intentional module content, so
   any change is an upstream editorial call, not a sanitizer fix.

## Conventions

See `CLAUDE.md` (added this session). Publishing is always
`scripts/publish.sh` — never hand-copy content.
