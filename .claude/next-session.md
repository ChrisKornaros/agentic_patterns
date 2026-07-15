# Next session — build the publish pipeline + first curated export

> Written 2026-07-15 at repo creation. This repo is PUBLIC — keep every
> committed file (including this one) free of private-repo specifics.

## What this repo is

A one-way **published artifact**: the tested, reusable subset of a
private research repo (modules, skills, prompts, templates, subdir
READMEs), exported here with fresh history so it can be cited from
blog posts and a public portfolio. The private repo stays canonical;
nothing is ever edited here directly except this repo's own docs and
tooling. License: MIT (chosen over copyleft for reuse + attribution).

## Session scope, in order

1. **Skeleton polish** — README: what/why, layout table, "how this is
   published" note, license line. No content import yet.
2. **`scripts/publish.sh`** — the one-way export:
   - Refresh the local mirror of the private source repo (the
     cache-fetch recipe in the machine-global `~/.claude/CLAUDE.md`),
     then rsync an **explicit allowlist** (never a blocklist) into
     this working tree.
   - **Deny-grep gate**: fail the publish if any pattern from
     `.publish-denylist` matches the export. That file is
     **gitignored and stays local** (the patterns themselves are
     private: hostnames, absolute paths, email, infra names). Script
     hard-fails if the file is missing. Seed it in-session with Chris.
   - **Link sanitization**: rewrite/strip relative links that point
     into private-only areas of the source repo (its roadmap, case
     studies, notes); then run a link-resolution check over the
     exported tree so no dangling link ships.
   - Each run = one commit: `sync from source @ <short-sha>`.
3. **First curated export — STAGED, not pushed.** Ask Chris (popup)
   for the initial allowlist: start with the few modules/skills/
   prompts he'd cite in a blog post, not the whole library. Leave the
   result as a local branch for his review; he pushes/merges.
4. **Follow-up in the private repo (separate PR there):** pointer note
   ("public mirror: agentic_patterns, published by its script — never
   edit the mirror directly") + memory update.

## Conventions

Branch + PR, Chris merges in the GitHub UI; no direct pushes to main.
