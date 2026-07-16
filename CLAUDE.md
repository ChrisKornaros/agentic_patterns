# agentic_patterns — agent contract

Public (MIT), one-way curated mirror of a private research repo. This
file governs agent work *on the repo itself* — the publish tooling and
native docs — not the exported content.

**This repo is PUBLIC.** Every committed file — including this one and
`.claude/next-session.md` — must stay free of private-repo specifics
and private infra (hostnames, addresses, ports, key names).

## What's native vs exported

- **Native (editable here):** `README.md`, `LICENSE`, `CLAUDE.md`,
  `.gitignore`, `scripts/` (the publish pipeline + committed
  allowlist), `.claude/` (the session handoff).
- **Exported (never edit here):** `modules/`, `skills/`, `prompts/`,
  `templates/`. Changes land in the private source repo and arrive via
  the next publish run. A hand edit here is silently overwritten — and
  a hand-copied file skips the sanitizer and deny gate.

## Publishing rules

- Publishing is **always** `scripts/publish.sh` — never hand-copy
  content in. Growing the export means editing
  `scripts/publish-allowlist.txt` and re-running the script.
- `.publish-denylist` is **local-only and gitignored by design** — its
  patterns describe private infra. Never commit it or quote its
  contents in any committed file. It is backed up privately in the
  source repo; after editing the local file, sync that backup (the
  local file's header says where).
- The script refuses to run on `main`, on a dirty tree, or without a
  non-empty local `.publish-denylist`. Don't work around those guards.

## Git workflow

- `main` is the only long-lived branch; work on `chore|feat|docs/<slug>`.
- Branch + PR; **Chris merges in the GitHub UI** — never merge or push
  to `main` from here.
- **After `gh pr create`, prompt Chris with AskUserQuestion** (the
  merge popup: merged / not yet); on "merged", pull `main` and delete
  the branch. Don't end the turn on a bare PR URL.
- At session start, read `.claude/next-session.md` first if it exists.

## Verify changes

No build. For publish-pipeline changes, a dry run of
`scripts/publish.sh` on a scratch branch is the test. For docs, check
that relative links resolve and that nothing committed matches the
local denylist.
