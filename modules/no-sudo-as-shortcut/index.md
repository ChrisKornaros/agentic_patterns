---
name: no-sudo-as-shortcut
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - playbook.md#141-workflow-rules-codified-mid-cycle
  - 07-anti-patterns.md#13-sudo-as-a-shortcut-around-the-actual-fix
  - common-guardrails.md#never-without-explicit-human-approval
applies_when:
  - any session on a host where the agent has shell access (local dev box, dev container, deploy target)
version: 2
---

# No `sudo` as a shortcut around the actual fix

## Rule

When a permissions, ownership, or locked-resource error surfaces,
the **first** question is *"what process is meant to own this state,
and can we let it run?"* — not *"can we `sudo` past it?"*

Elevated permissions (`sudo`, `su`, `chown`, `chmod 777`, `launchctl`
/ `systemctl` as root, anything inside a `sudo -i` shell) are
allowed **only** when both conditions hold:

1. The scenario is **named in the project's permissions doc**
   (`PERMISSIONS.md` or the equivalent the project uses), with the
   reason elevation is correct rather than masking a bug.
2. The human has confirmed the specific action in this session.

Standing approval doesn't carry across actions: one authorized
`sudo systemctl restart app.service` doesn't authorize a follow-up
`sudo chown -R …`. If the named scenario isn't already in the
permissions doc, the agent's job is to **stop and surface the
underlying issue in chat** — never to add the scenario unilaterally
just to clear its own path.

`sudo`-equivalent escalations (running the agent itself as root,
shelling into a root container, `docker exec --user 0`, swapping to
a privileged k8s context) count as the same rule.

## Why

The shape that keeps recurring: a permissions or ownership error
surfaces (a root-owned file, a bound port, a locked WAL) and the
tempting "fix" is `sudo chown` / `sudo kill`. But the actual fix is
usually that some process is *supposed* to own and clean up that
state — letting that process run is the correct path. `sudo` masks
the underlying issue, leaves an unreviewed state change behind,
and trains the team to reach for elevated permissions instead of
diagnosing root cause.

The product-use-tracker case study
(§1.4.1)
codified this after a root-owned `instance/tracker.db.wal` on the
production Pi almost got "fixed" with `sudo chown`. The actual fix
was `docker compose start app`, which let DuckDB consume its own
WAL and re-emit it with the right ownership. The `sudo chown`
would have worked for that one boot, then re-broken on the next
container restart — the bug was that the app wasn't running, not
that the file had the wrong owner.

The companion guardrail
[[stay-in-project-tree]] covers *where* the agent acts; this one
covers *with what authority*. Together they bound "scope of
action" — the class of failure where an agent technically completes
a task but leaves the host in a state nobody reviewed.

## How to apply

- **Before typing `sudo`, ask the diagnosis question.** What
  process is meant to own this state? Has it crashed, or has it
  never been started? Can starting it produce the state we want
  for free? `sudo` is a substitute for understanding; the
  understanding is the actual work.
- **Check the project's permissions doc.** If `PERMISSIONS.md`
  (or the project equivalent) names the scenario and authorizes
  elevation for it, run the command and reference the doc in
  the chat turn. If it doesn't, stop.
- **Treat `chown`, `chmod 777`, and "root-equivalent" container
  exec the same as `sudo`.** They have the same effect on the
  reviewability of host state. `Bash(sudo:*)`, `Bash(su:*)`,
  `Bash(chown:*)`, and `Bash(chmod 777:*)` are on the deny list
  in this repo's
  `settings` for that
  reason; the
  [`settings-snippet.json`](settings-snippet.json) ports the
  same denies to host repos.
- **When `sudo` *is* genuinely the right answer, document it.**
  Add the named scenario to the project's permissions doc *in the
  same PR* as the action, so the next session doesn't have to
  re-decide. "Run once, never write it down" is what made the
  rule necessary in the first place.
- **Pair with the
  [[stay-in-project-tree]] installer pattern.** If the elevation
  is needed for a host-system change (systemd unit, sysctl, package
  install), that change belongs in `deploy/install-*.sh`. The agent
  edits the script in the repo; the human runs it with the
  elevation the script needs. The elevation is then reviewable,
  reproducible, and revertible from `git`.

## Anti-patterns

- **`sudo chown -R $USER:$USER <path>`** to clear a root-owned
  file the app produced. The app is supposed to own its own
  state; if it doesn't, the app isn't running correctly. Start
  the app instead.
- **`sudo kill -9 <pid>`** on a process whose owner you don't
  recognize, "to free the port." That process is probably the
  thing you're trying to debug; killing it deletes the evidence
  of why the port was held.
- **`sudo rm` on a "stale" lockfile, WAL, or socket.** Lockfiles
  exist because the owning process expects to clean them up. If
  it didn't, the question is why it crashed — `sudo rm` papers
  over the crash and produces a corrupt-recovery path on next
  boot.
- **`chmod 777 <dir>`** because "the app can't write here." The
  fix is the right owner + the right mode (typically `750` or
  `770` with a group), not world-writable. World-writable
  directories are also a security finding in most compliance
  regimes.
- **`docker exec --user 0` (or `kubectl exec` into a privileged
  pod) to "just edit one file"** inside a container instead of
  rebuilding the image with the correct content. The "one file"
  is gone on the next deploy and was never reviewed.
- **Adding `NOPASSWD` sudoers entries** so the agent can run
  elevated commands without prompting. The prompt is the gate;
  removing it removes the rule.
- **`sudo -i` followed by a sequence of "small" commands** to
  avoid typing `sudo` repeatedly. The shell session is
  unreviewable as a unit; if each command needed elevation it
  needed its own justification.

## Companion files

- [`settings-snippet.json`](settings-snippet.json) — a portable
  deny-list snippet a host repo can paste into its
  `.claude/settings.json` to enforce this rule at the permission
  layer. Pairs with the snippet shipped by
  [[stay-in-project-tree]]; together they cover the scope-of-action
  guardrail family at the settings layer. The
  `enforced_by:` frontmatter field is still future work (see
  `03-instruction-modules` §8).
  **Fixed in v2 (2026-09-29):** v1's `Bash(kubectl exec * --user=root:*)`
  mixed `*` with the trailing `:*` prefix syntax, so it was matched as
  a literal prefix and never fired. It's now
  `Bash(kubectl exec * --user=root*)`. A host that vendored v1 should
  re-vendor.

## Related

- [[stay-in-project-tree]] — the matching scope-of-action
  guardrail on *where* the agent acts; the two together cover
  unreviewed host-state changes.
- [[git-flow-no-direct-main]] — the matching guardrail on the
  remote / shared-history side. Direct-to-`main` and
  `sudo`-as-shortcut are the same failure shape applied to
  different surfaces: "skip the review gate to clear my path."
