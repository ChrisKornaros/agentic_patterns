---
name: status-emoji-discipline
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - 02-workflow-patterns.md
  - playbook.md#141-workflow-rules-codified-mid-cycle
version: 1
---

# Status-emoji discipline

## Rule

Use one consistent status vocabulary across the repo's tracking tables —
🟢 live/done/complete · 🟡 partial/in-progress · 🔴 stub/not-started —
and define the legend once where the tables live. Flip a status *inside
the same feature PR that does the work*, alongside the **Delivered** and
**Verified** notes; never open a separate chore PR just to flip an
emoji.

## Why

A shared three-state vocabulary keeps roadmaps, layout tables, and
work-logs scannable at a glance instead of each doc inventing its own
"done"-ness. The flip-in-the-feature-PR half is the load-bearing
discipline: in the master case study a v2 item shipped 🔴 and earned a
follow-up `chore/e4-flip-status` PR of pure overhead, after which the
rule became "the status entry ships green with Delivered + Verified in
the same PR that lands the work"
(`playbook/02` §4,
case study §1.4.1).
A status that lags the work is either a lie or a second PR; both are
avoidable.

## How to apply

- **Adopt the three states verbatim** where they fit: 🟢 / 🟡 / 🔴 with
  a one-line legend next to the first table that uses them.
- **Bundle the flip with the work.** The roadmap/CHANGELOG/layout-table
  status change is a hunk in the feature PR, not a successor PR.
- **Pair the green with evidence.** A 🟢 carries a one-line **Delivered**
  outcome and a **Verified** note (how it was checked) in the same diff.
- **If nothing's status changed, say so** in the commit body rather than
  silently skipping the tracking-doc sync.

## Anti-patterns

- A `chore/flip-status` PR whose only diff is 🔴 → 🟢.
- Mixing vocabularies (✅/⬜ in one table, 🟢/🔴 in the next) so "done"
  can't be grepped or scanned consistently.
- Landing the work in one PR and the status flip in another "to keep the
  diff clean" — it just doubles the review surface.
- Marking a row 🟢 with no Delivered/Verified line, so a reader can't
  tell what "done" actually delivered.

## This rule is working if

- No PR in the history exists solely to change a status emoji.
- Every 🟢 in a tracking table has a Delivered + Verified line landed in
  the same PR.
- A reader can scan any status table and read its states without a
  per-table legend lookup.

## Related

- [[git-flow-session-end]] — its step 3 ("sync the tracking docs before
  the wrap-up commit") is where this flip happens.
- [[auto-commit-on-branch-done]] — the feature PR this flip rides on.
- [[docs-two-layer]] — the human-facing docs whose legibility this
  vocabulary protects.
