# headless-runner

One `claude -p` job in its own worktree, with its result in the
warehouse. Daedalus's factory runtime for the Epoch-I trial
(`roadmap/15` §7,
D8): the run stays on the Claude subscription, hooks still fire, so the
Stop hook ingests the transcript like any session, and the JSON result
the CLI prints (`session_id`, `total_cost_usd`, turns, per-model usage,
the final text) goes into `headless_runs` through
`warehouse headless-import`. One shell file, no dependencies beyond
`claude`, `git`, `python3` and `uv` for the import.

## Use

```sh
# from the agentic_optimization_research root, or anywhere with the path
tools/headless-runner/run.sh --repo ~/vault/projects/product_use_tracker \
    --prompt-file /path/to/issue-prompt.md --max-budget-usd 15 --open-pr

tools/headless-runner/run.sh --repo . --model haiku --max-budget-usd 0.50 \
    -- "Reply with exactly the word OK."

tools/headless-runner/run.sh --help
```

What one run does, in order:

1. Names the job `hr-<utc stamp>-<4 hex>` and adds `.claude/worktrees/`
   to the repo's `.git/info/exclude`, which Claude Code does not do, so
   the main checkout's `git status` stays clean.
2. Scrubs the launching environment: every `CLAUDE*`, `AI_AGENT`,
   `VSCODE_*` and `TERM_PROGRAM*` variable. Without this a job started
   from an editor session inherits that editor's entrypoint and the
   transcript says `claude-vscode`; scrubbed, it says `sdk-cli`.
3. Runs `claude -p --worktree <job> --output-format json
   --permission-mode acceptEdits` from the repo root with the prompt on
   stdin, with one `--allowedTools` argument per pattern in the repo's
   own `permissions.allow` list (see Permissions) plus anything in
   `--allowed-tools`. `--model` and `--max-budget-usd` pass through. The
   worktree is `.claude/worktrees/<job>` on branch `worktree-<job>`,
   from the repo's current `HEAD`.
4. Reads the worktree back: the branch it ended on, its head, commits
   ahead of the base, whether the head reached a remote, and any other
   local branch the agent created from the base. With `--open-pr`, a
   branch with commits of its own that is not on a remote is pushed to
   `origin` and a PR opened on it with `gh`, titled by the first
   commit's subject, body = the agent's final report plus a footer
   naming the job, the `gh` user assigned so the PR shows at
   github.com/pulls (a PR you neither authored nor are assigned to
   doesn't). The PR URL goes into the envelope.
5. Writes the envelope `<out-dir>/<job>.json`, `{"job": {…}, "result":
   {…}}`, beside the raw `<job>.result.json`, `<job>.err` and
   `<job>.prompt.txt`. The default folder is
   `~/.cache/agentic_metrics/headless/`.
6. Imports the envelope with `uv run --project metrics/warehouse
   warehouse headless-import --result <envelope>`. The file stays on disk
   either way, and `headless-import --dir <folder>` re-imports a folder;
   the job name is the key, so re-runs upsert.
7. Unlocks and removes the worktree (a finished session leaves it
   locked). The `worktree-<job>` branch is deleted only when it has no
   commits of its own or its head is on a remote; unpushed work stays on
   the branch and is reported. Other branches the agent made are left
   alone and named.

Exit code: `claude`'s, or 2 for a usage error, or 3 when `claude` is not
on `PATH`.

## Permissions

A headless run cannot answer a prompt, so a tool the permission mode
does not allow is refused and the result's `permission_denials` says so
(the runner prints them). Three things decide what runs, observed on
PUT 2026-11-04:

- **The repo's allow list is not read.** A headless session treats the
  checkout as untrusted unless its path has `hasTrustDialogAccepted` in
  `~/.claude.json`, and a worktree path never does; it then ignores
  every `permissions.allow` entry in the repo's `.claude/settings.json`
  (60 ignored, 28 refusals in the first run, including
  `scripts/smoke.sh`, `git add` and `uv run pytest`). So the runner
  reads that list itself and passes each pattern as its own
  `--allowedTools` argument. `--no-repo-allow` turns that off.
- **The `ask` tier is a "no".** A pattern in `permissions.ask` is
  refused whatever `--allowedTools` says. PUT asks on every `git push`,
  which is why pushing and opening the PR are the runner's `--open-pr`
  step, run outside the session, and not something the agent is asked
  to do. Deny rules apply as written.
- **Built-in safe commands run regardless:** `git status`, `git log`,
  `git diff`, `grep`, `ls`, `mkdir -p` and the like need no rule.

`acceptEdits` covers file edits in the worktree. `--permission-mode
bypassPermissions` exists for a host where the worktree is the sandbox
(the home server); it is not the default.

## What a run looks like in the warehouse

```sql
SELECT job, repo, num_turns, commits, pushed, pushed_branch,
       ROUND(reported_cost_usd::numeric, 4) AS reported,
       ROUND(modeled_cost_usd::numeric, 4)  AS modeled,
       entrypoint
FROM headless_run_costs ORDER BY started_at DESC LIMIT 10;
```

The transcript lands under the worktree's own project slug
(`…-product-use-tracker--claude-worktrees-hr-…`), so group factory
runs by `headless_runs.repo`, not by `sessions.project_slug`. The Clew
hook lives in the repo's `.git/hooks/`, which worktrees share, so a
commit the job makes carries its session id and `commits-import` joins
it ([tools/clew](../clew/)).

## The first two runs on PUT (2026-11-04)

**Second, issue #49, no intervention.** With the allow list passed
through and `--open-pr`: 29 turns, 220 s, $2.32 reported and $2.32
modeled; one commit (a two-line fix, three tests, a `BUGFIXES.md`
entry) pushed by the runner and PUT #52 opened by it from the agent's
report, which arrived in the PR-body shape the contract asks for.
Smoke green on the branch from a detached worktree (108 tests, 14
routes). Four refusals remained, all `ask`-tier: `mv` and `rm` on a
backup copy the agent made of `app.py`, and one `&&` compound. The
agent worked around them with the editor and said so.

**First, issue #48, one intervention.**

The smoke-coverage gap from E8. 46 turns, 497 s, the CLI
reported $3.60 (list price) against $2.93 modeled by the warehouse for
the same session; one commit, exactly the issue's diff, carrying both
the Clew and `Co-Authored-By`. The agent could not run smoke or push
(the two findings above), so the operator ran smoke on the branch from
a detached worktree (105 tests, 14 routes, `SMOKE PASS`) and opened
PR #51 with the agent's own report: the run's one human intervention
(H-D2 allows one). `--open-pr` and the allow-list passthrough came out
of that run.

## The CM queue (2026-11-05)

Nine agent-ready issues, one job each from the Mac, CM `main` pulled
between jobs: CM #177–#185, all merged the same afternoon. 18–35
turns, $1.28–$2.74 a job (reported = modeled on every row), 3–6.5 min
a job and 39 min of runner time in all, zero interventions, every PR
body in the contract's shape; the per-PR table and the H-D2 reading
are in the
readout §2.
Three things the queue taught:

- **A shared record file serialises the queue.** CM's contract has
  every change append an entry to `docs/worklog.md`, so two jobs from
  the same base conflict at merge time. Merging between jobs (the
  first six) avoids it; running unattended from one base (the last
  three) needs the append re-applied before the second and third
  merges. Done here with a merge commit from `main` per branch and the
  branch's own entry re-appended: no history rewrite, the runner's
  commit and its Clew untouched. The real fix is a per-PR record, or
  the PR body as the record, decided before a queue runs unattended.
- **Chaining jobs from an editor session.** `setsid` does not exist
  on macOS, so a `nohup setsid … &` driver dies at once and silently;
  one background runner call per job, chained on its completion
  notice, worked. "One job at a time per repo" (below) stands.
- **The ask tier, seen fifteen times.** All `ask`-tier: compound
  `&&`/`;` greps, `sed -i` on a source file (the agents' own mutation
  probes, which they then made with the editor and reverted),
  `git checkout --`/`git restore` on that probe, and a heredoc append
  to the worklog. None cost a run; each was worked around and
  reported. The final reply is posted verbatim: #177 led with a status
  sentence before `## What changed`.

## Writing the prompt

Use [prompts/agent-ready-issue.md](../../prompts/agent-ready-issue.md):
the issue's "What should change" and "Done when", then the working
contract (stay inside the issue, run the repo's check command, say
which reading you picked, end the PR with `Closes #n`). Say that the
worktree is fresh: no venv, no local database, no memory store (the
memory symlink is keyed by the main checkout's path), and the branch
rule the repo uses for its PRs. Tell the agent to commit on a branch
named by that rule and to put the PR body in its final reply; with
`--open-pr` the runner pushes and opens the PR from that reply. The
contract used on PUT is in the AOR hand-off for unit 5.

## Known limits

- `--bare` is slated to become the `-p` default; when it does, hooks
  stop firing in headless runs and this envelope is the only record
  (`roadmap/15` §12).
- `total_cost_usd` is the CLI's list-price figure
  (`costBasis: "list"`), which on a subscription is a comparison number,
  not a bill. `headless_run_costs` puts it beside the warehouse's own
  modeled cost for the same session.
- One job at a time per repo is the safe assumption: two runs share the
  repo's `.git` and the Stop hook's queue, and nothing here serialises
  them.
