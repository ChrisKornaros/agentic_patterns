# clew

The commit-to-session trailer. A `prepare-commit-msg` git hook appends
`Clew: <session-id>` to every commit made from a Claude Code session,
read from the `CLAUDE_CODE_SESSION_ID` that Claude Code sets in each
Bash command a session runs. A commit made by hand gets nothing. The
warehouse's `commits-import` then joins each commit to its session, so
for any commit you can see the session, its turns, its tool calls and
its cost, and for any session its commits. Daedalus's provenance
primitive (`roadmap/15` D7),
named for the ball of thread Ariadne gave Theseus.

## Install

```sh
# from the agentic_optimization_research root; once per machine, per repo
tools/clew/install.sh ~/vault ~/vault/projects/agentic_optimization_research \
    ~/vault/projects/product_use_tracker ~/vault/projects/content_manager
tools/clew/install.sh --check <repo>...        # exit 1 if any repo lacks it
tools/clew/install.sh --uninstall <repo>...
```

The hook lives in the repo's `.git/hooks/` (shared by its worktrees),
not in the repo, so each machine that commits from sessions installs it
itself. An existing `prepare-commit-msg` hook is kept as
`prepare-commit-msg.pre-clew` and runs first; a tool that installs its
own hook later (Entire keeps ours as `.pre-entire`) chains the same way;
`--check` and `--uninstall` look in both places, and a re-install under
Entire is a no-op.

## Read it back

```sh
git log --format='%h %(trailers:key=Clew,valueonly) %s'
```

```sh
# load a repo's commits into the warehouse (sessions table joins on session_id)
cd metrics/warehouse
uv run warehouse commits-import --repo ~/vault/projects/product_use_tracker --since 2026-11-01
```

## What it does not do

- Store a transcript. Entire's checkpoint stores one beside the
  commit; the Clew stores the id only and relies on the warehouse (and
  the transcript archive) for the rest.
- Tell attended from unattended. The warehouse's `sessions.entrypoint`
  does that after the join.
- Fire outside a session. No `CLAUDE_CODE_SESSION_ID`, no trailer.
- Survive a hooks-path override. `git -c core.hooksPath=.git/hooks
  commit` from a worktree points at a path that is not a directory
  there (`.git` is a file), so git runs no hook and the commit silently
  has no trailer. Seen on CM #164, 2026-11-04. Leave `core.hooksPath`
  alone; a worktree already shares the main checkout's hooks.
