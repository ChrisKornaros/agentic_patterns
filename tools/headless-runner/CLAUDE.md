# headless-runner — agent notes

`run.sh` is one POSIX-leaning bash file: parse flags, scrub the
environment, run `claude -p --worktree`, read the worktree back, write
the envelope, import, clean up. Human doc: [README.md](README.md).
Loader: `headless`;
table and view at the end of
schema.postgres.sql.

- **Test it on a scratch repo, never on a real one.** `git init` a
  folder under the scratchpad, commit once, then run with `--model
  haiku --max-budget-usd 0.50 --out-dir <scratch>` and
  `WAREHOUSE_INGEST_SKIP=1` so the Stop hook keeps the test session out
  of the warehouse. A job on a real repo is a real-system write: it
  can commit, push and open a PR. Write the exact command up first.
- **The envelope is the contract with the loader.** Add a field to the
  `meta` dict in `run.sh` and to `parse_envelope` in `headless.py`
  together; `headless-import --dry-run` on the scratch envelopes is the
  check.
- **Don't delete work.** The cleanup deletes `worktree-<job>` only when
  it has no commits of its own or its head is on a remote. Keep it that
  way.
- **Permissions are three findings, not one flag.** The repo's allow
  list is ignored in a headless session (untrusted path), so the runner
  passes it as `--allowedTools`; the `ask` tier is a refusal, so the
  push and PR are the runner's `--open-pr` step; built-in safe commands
  run regardless. Test a permission change with a gated command
  (`python3 -c`), not `git log` or `mkdir`, which are auto-allowed.
- **The scrub list is deliberate.** `CLAUDE*`, `AI_AGENT`, `VSCODE_*`,
  `TERM_PROGRAM*`. Observed 2026-11-04: with only `CLAUDE*` scrubbed the
  child still recorded `claude-vscode`; with the editor's variables gone
  it recorded `sdk-cli`.
- **No real transcripts or results in this folder**
  (`metrics-no-real-session-data`):
  examples in docs are synthetic.
