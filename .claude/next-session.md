# Next session — post-pipeline follow-ups

> Updated 2026-07-15 after the publish-pipeline session. This repo is
> PUBLIC — keep every committed file (including this one) free of
> private-repo specifics.

## State as of this handoff

The publish pipeline and first curated export shipped in the
`feat/publish-pipeline` PR:

- `scripts/publish.sh` — one-way export: mirror refresh → allowlist
  rsync into staging → link sanitization + resolution check →
  deny-grep gate (on the sanitized tree, i.e. exactly what ships) →
  one `sync from source @ <short-sha>` commit. Refuses to run on
  `main`, on a dirty tree, without a local `.publish-denylist`, or
  with an empty one.
- `scripts/publish-allowlist.txt` — committed; first curated set =
  session-loop, guardrail, and debugging bundles + area READMEs
  (32 files from source `6e8578a`).
- `.publish-denylist` — local-only and gitignored, by design. Seeded
  and verified in-session (every pattern match-tested, zero false
  positives; final tree grep clean).

## Queued next (small, in rough order)

1. **Private repo pointer note** — separate PR *there*: "public
   mirror: agentic_patterns, published by its script — never edit the
   mirror directly" + memory update. (Was step 4 of the original
   handoff; still open.)
2. **Back up the denylist privately** — it exists only on this
   machine; losing it silently weakens future publishes. A copy in a
   private store (vault) is enough.
3. **Cosmetic pass upstream (optional)** — bare path mentions in
   source prose (not markdown links) pass through the sanitizer
   untouched; they leak no secrets, only internal doc names. Fix in
   the source repo if it bothers, not here.
4. **Allowlist growth** — add bundles as blog posts need them; edit
   `scripts/publish-allowlist.txt`, re-run the script.

## Conventions

Branch + PR, Chris merges in the GitHub UI; no direct pushes to main.
Publishing is always `scripts/publish.sh` — never hand-copy content.
