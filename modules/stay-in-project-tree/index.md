---
name: stay-in-project-tree
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - playbook.md#141-workflow-rules-codified-mid-cycle
  - common-guardrails.md#never-without-explicit-human-approval
  - settings.json
applies_when:
  - any session, any host repo (this is a universal scope rule)
version: 2
---

# Stay inside the project tree

## Rule

The agent's reads, edits, writes, and shell commands resolve to
paths inside **one of three places**:

1. The repo's **working tree** (everything under the project root).
2. The repo's own **`.claude/`** directory (settings, hooks, local
   logs that this project owns).
3. The **per-project Claude state directory** at
   `~/.claude/projects/<this-project's-hash>/` (where Claude Code
   puts session logs, todos, and the auto-memory store for *this*
   project by design).

Anything else — `/etc`, `/usr`, `/var`, `/tmp`, another repo's
working tree, the user's home dotfiles (`~/.zshrc`, `~/.gitconfig`,
`~/.bashrc`), the user's global Claude config (`~/.claude/settings.json`,
`~/.claude/commands/`), credential stores (`~/.ssh`, `~/.aws`,
`~/.config/gh`), or a production host's system config — is
**off-limits without explicit, per-action human authorization in
chat**. Standing approval doesn't carry across actions: if the
human said "ok, look at `~/.aws/config`" once, that doesn't
authorize editing it.

Host-system changes (systemd units, crontabs, PATH, package
manager state, `/etc/hosts`, kernel sysctls) are made **only
via an installer script committed inside the repo**
(`deploy/install-*.sh` is the canonical name). The agent edits
the script in the tree; a human runs it. The rule is "if it
changed the host, it's in git."

## Why

The "production deployment is just a checkout" mindset quietly
turns the host into an unreviewed working tree. Edits to
`~/.zshrc`, `/etc/systemd/system/*.service`, a crontab, or a
package manager's global state look fine at the moment but leave
no audit trail, don't roll back with `git revert`, and don't
reproduce on the next host. The
case study §1.4.1
codified the in-repo installer pattern after a host-scope rule
violation on the production Pi created drift that wasn't
recoverable from `git`. The installer pattern keeps host changes
reviewable, reproducible, and revertible — the same properties
the PR workflow gives to code changes.

The credential paths (`~/.ssh`, `~/.aws`, `~/.config/gh`) are
denied for **reads too**, not just writes — "I just want to
check the key type / verify the format" is the canonical excuse
that ends with secrets in a transcript.

## How to apply

- **Before any non-trivial path operation, ask: is this path
  inside the working tree, the repo's `.claude/`, or this project's
  `~/.claude/projects/<hash>/`?** If no, stop and surface the
  intent in chat before acting.
- **For host-system changes on a real host: edit a script under
  `deploy/` and ask the human to run it.** Never `ssh prod ...`
  followed by an out-of-tree edit, even for a one-liner.
- **For "I need to set a global tool config" requests
  (`~/.gitconfig`, `~/.zshrc`, shell PATH, `~/.npmrc`, etc.):
  prefer a project-scoped equivalent** (`.envrc`, repo-local
  `.gitconfig` via `git config --local`, a `.tool-versions` file,
  a `uv`-managed venv) over touching the global file.
- **The per-project auto-memory dir is fair game** — it's at
  `~/.claude/projects/<hash>/memory/` and Claude Code scopes it
  to this project. Treat it like an extension of the repo, not
  an outside location.
- **Sensitive paths (`~/.ssh`, `~/.aws`, `~/.config/gh`,
  `~/.gitconfig` for global identity) are denied for both read
  and write.** If a task genuinely requires one, the human pastes
  the relevant value into chat or runs the command themselves.

## Anti-patterns

- **Editing `~/.zshrc` (or any shell rc) to add a PATH entry**
  because a tool installed a binary somewhere weird. Fix the
  install path with the repo's tool (`uv tool install`, a script
  under `deploy/`), don't mutate the user's shell config.
- **`sudo vi /etc/systemd/system/<app>.service` on a production
  host** to fix a typo. The service file must live under
  `deploy/` in the repo; the installer script copies it into
  place.
- **`crontab -e` on a production host** to add a backup job. The
  cron entry belongs in `deploy/install-cron.sh` (or equivalent),
  committed and reviewed.
- **Reading `~/.ssh/id_rsa` "to check the key type"** or
  `~/.aws/credentials` "to see which profile is set." Both are
  denied; the human supplies whatever metadata the task actually
  needs.
- **Modifying `~/.gitconfig` to set `user.email` or `user.name`**.
  The system instruction "NEVER update the git config" is global
  — if a project needs a different identity, set it with
  `git config --local` from inside the repo.
- **Cloning a sibling repo into `/tmp/` and editing it** to "test
  something quickly." `/tmp/` is outside the tree; the test
  belongs as a fixture inside the repo or in a properly-named
  sibling project the human knows about.
- **Touching `~/.claude/settings.json` (the *global* Claude config)
  from inside a project session.** That's the `update-config`
  skill's territory and needs to be an explicit action, not a
  drive-by edit.

## Companion files

- [`settings-snippet.json`](settings-snippet.json) — a portable
  deny-list snippet a host repo can paste into its
  `.claude/settings.json` to enforce this rule at the permission
  layer. Modules can ship `enforced_by:` metadata in a future
  spec version (see
  `03-instruction-modules` §8);
  for now the snippet is alongside the prose.
  **Anchor gotcha (fixed in v2):** in `Read`/`Edit`/`Write` rules a
  single leading `/` is relative to the settings source, not the
  filesystem root, so v1's `Read(/etc/**)` denied `<repo>/etc/**`
  and blocked nothing. System directories take `//` (`Read(//etc/**)`);
  credential stores take `~/`, which resolves per machine. A host
  that vendored v1 should re-vendor. Found by the
  agentic_administration build repo, 2026-09-25.
  **`Edit`, not `Write` (2026-09-29):** only `Edit(path)` rules are
  matched by file permission checks, and they cover every
  file-editing tool. The snippet's 15 `Write(...)` twins never fired,
  and each had an `Edit(...)` twin, so they were dropped. That changes
  no behaviour, so there's no version bump. A headless `claude -p`
  from a repo root prints any rule it can't match (a free settings
  lint).

## Related

- [[git-flow-no-direct-main]] — the matching guardrail on the
  remote / shared-history side.
- [[no-sudo-as-shortcut]] — the sibling guardrail on elevated
  permissions; the two together cover "scope of action" failures.
