---
name: no-cat-head-via-bash
type: guardrail
scope: repo
lifecycle: experimental
dependencies: []
evidence:
  - 2026-05-27-pre-obsidian/README.md
  - h2-re-read-collapse/README.md
applies_when:
  - host repo has the standard Read/Edit/Write tool surface (Claude Code, Claude Agent SDK)
version: 1
---

# Don't `cat`/`head`/`tail`/`sed`/`awk`/`echo` files via Bash

## Rule

Use the `Read` tool to read file contents. Use the `Edit` tool to
modify them. Use the `Write` tool to create or replace them. Do not
shell out to `cat`, `head`, `tail`, `sed`, `awk`, `tac`, `nl`, or
`echo >`/`cat <<EOF` for these operations — not "just to check the
last few lines," not "just to verify the edit landed," not "just to
preview the diff." The dedicated tools exist for these jobs and are
the surface the rest of the agent infrastructure (re-read tracking,
permission rules, transcript indexing) is built around.

The same applies to `printf`/`echo` for communication: produce text
as a regular assistant message instead of `echo`ing it through a
Bash call. The user reads the assistant's output directly; routing
text through Bash adds a tool-call cost and an extra round-trip for
no information gain.

## Why

The pre-obsidian baseline at
`2026-05-27-pre-obsidian/README`
classified Bash calls by regex and found:

| Bash subtype | Calls | % of Bash |
|---|---|---|
| grep/ripgrep | 485 | 25.0% |
| **cat/head/tail/sed/awk** | **483** | **24.9%** |
| git | 347 | 17.9% |
| ls/tree | 289 | 14.9% |

That's ~25% of all Bash spend running file-inspection commands the
`Read` tool already handles — despite the root `CLAUDE.md` for the
agentic-optimization-research repo explicitly saying *"Avoid using
this tool to run `cat`, `head`, `tail`, `sed`, `awk`, or `echo`
commands, unless explicitly instructed."* The guidance exists; live
adherence is poor. This module makes the rule portable and gives a
host repo a single bullet to cite in its `CLAUDE.md` rather than
restating the body each time.

The cost shape matters too: every Bash workaround also escapes the
H2 re-read guard (which only sees the `Read` tool), so a `cat file`
loop can silently re-read the same file dozens of times without
tripping the per-session cache reminder. The two interventions —
this module and the H2 hook — pair: the hook closes the `Read`-tool
hole, and this module closes the `Bash`-cat hole.

## How to apply

- **Reading any file:** `Read(file_path=…)`. Use `offset` + `limit`
  for large files (PDFs, generated logs) instead of `head` /
  `tail`.
- **Modifying any file:** `Edit(file_path, old_string, new_string)`
  or `MultiEdit` for batched changes. Never `sed -i`, never `awk`
  + redirect, never `python -c 'open(…).write(…)'`.
- **Creating a new file:** `Write(file_path, content)`. Not
  `cat <<EOF`, not `echo … >`.
- **Communicating with the user:** output text directly. Not
  `echo "done"`.
- **Verifying an edit landed:** the `Edit` tool errors if
  `old_string` isn't present, so a successful return is the
  verification. Don't follow up with `cat file | grep`.
- **Reasonable Bash exceptions** (allowed):
  - Inspecting *binary* output you can't see in `Read` —
    `xxd`, `file`, `od`. (Rare.)
  - Piping a *command's* output through `awk`/`sed`/`grep` —
    `git log | head -20`, `ls -la | awk '…'`. The pipe consumes
    transient output, not file content.
  - Reading a file that only exists transiently on a remote host
    over SSH (`ssh host 'cat /proc/…'`). Out-of-tree case.

## Anti-patterns

- `cat README.md` to "just peek." → `Read(file_path="README.md")`.
- `head -n 50 src/app.py` to scan the top. → `Read(file_path=…,
  limit=50)`.
- `tail -f log.txt` for a live tail in a one-shot agent turn. (Use
  a foreground/background Bash if you genuinely need streaming; for
  one-shot inspection, `Read` covers it.)
- `sed -i 's/foo/bar/' file` to rename across a file. →
  `Edit(file_path=…, old_string="foo", new_string="bar",
  replace_all=true)`.
- `echo "fixed the bug" >&2` or `printf "..." ` as a way to "say"
  something to the user. → just produce the text as the
  assistant's reply.
- `cat <<EOF > newfile.py … EOF`. → `Write(file_path=…,
  content=…)`.

## Companion files

- [`pre_read_guard.py`](pre_read_guard.py) — the H2 re-read guard, the
  runtime half of this rule. The prose above closes the **Bash-cat**
  hole (a behavioral guardrail — no deny-list entry, since
  `cat`-ing a *command's* output is a legitimate exception). This hook
  closes the **Read-tool** hole: it blocks a redundant re-read of a
  file already read and unmodified this session, so the cost the rule
  targets can't leak back in through repeated `Read` calls. The two
  pair — neither alone covers both surfaces.

  Wire it as a `PreToolUse` hook on `Read|Edit|Write|MultiEdit` in the
  host's `.claude/settings.json`. The paste-ready shape (with a
  missing-script fail-open guard, so it's safe to copy before the
  module is vendored) ships in
  [../../templates/_shared/claude-settings.example.json](../../templates/_shared/claude-settings.example.json).
  **Wire it once per machine, not once per repo.** User-level and
  project hooks merge, so if the machine's `~/.claude/settings.json`
  already runs this guard on the same matcher (the canonical
  `dotfiles/` set-up does, pointing at the H2 tool copy), a project
  block makes every `Read` spawn two guard processes and turns one block
  into two denials. Seen on content_manager, 2026-11-04: harmless there,
  but it stays harmless only while the two copies agree. Vendor the
  script anyway, so the host is complete on a machine without the
  dotfiles, and leave the project hook block out where the dotfiles
  wire it; say so in the host's `MODULES.md` Override column
  ([VENDORING §6](../VENDORING.md#6-inherit-the-matching-permission-settings-and-hooks),
  "Unless the machine already runs them").

  The script is stdlib-only and fails open on any unexpected condition;
  disable it for a session with `H2_REREAD_GUARD_DISABLED=1`. It records
  each file's mtime at read-time and allows a re-read whose mtime has since
  advanced, so an **external edit** (IDE save, `git pull`, another process)
  is treated as a real modification rather than blocked — which avoids a
  deadlock against the harness's own edit-freshness check. The
  canonical source is the H2 experiment tool
  (`pre_read_guard`);
  this is the vendored copy, kept in sync.

## Related

- [[stay-in-project-tree]] — the file-system scope guardrail; this
  one is the file-access *interface* guardrail. They pair: stay
  inside the tree *and* read/edit it through the right surface.
- [[no-sudo-as-shortcut]] — same "use the proper interface, not
  the convenient shortcut" pattern, applied to privilege.
