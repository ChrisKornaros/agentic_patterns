# Lens review

Use to review a diff or PR through a few named lenses, each with a
written threshold, in place of one open-ended "review this". It pairs
with [tight-code-review.md](tight-code-review.md): tight-review asks
three structural questions, and a lens says what to look for, how to
look, what *not* to report, and how to report it.

```
Review <branch | PR # | diff> through these lenses, one pass per lens:

  1. Correctness and data integrity: edge cases in changed logic; writes
     that can be lost, duplicated or left half-finished; contracts at a
     boundary whose two sides ship separately.
  2. Security and privacy: an untrusted input that reaches a sensitive
     operation, or data disclosed to someone not entitled to it. Name
     the actor, the input and the sink, or don't report it.
  3. Scale and resilience: cost that grows with load or data; what a
     slow, duplicate or missing response does.
  4. Maintainability: a name, comment or type that promises what the
     code doesn't do; a helper the codebase already has.
  5. House rules: the rules in the CLAUDE.md / AGENTS.md chain that
     governs the changed files, from the repo root down.

Report only what crosses a lens's threshold in a realistic input or
state. Don't report what lint, types or tests already enforce, style
preferences, or code the change didn't touch.

For each finding: file and line, the input or state that triggers it,
the consequence as the code makes it (not a worse one), the smallest
fix, and "should fix" or "advisory".

End with a count per lens of what you considered and dropped, and why:
low confidence, pre-existing, not caused by this change, or below
threshold. "No findings" is a fine result.
```

Run it in a session or subagent that didn't write the change. The
reviewer should be a different identity from the author.

## Write a house-rules lens

When a repo's own rules matter enough to review against, give them a
lens file of their own, scoped to the paths they govern:

```markdown
---
name: review-<repo>-house-rules
description: Review a change for <the rules, by number, in CLAUDE.md>. Use as one lens in a review.
---

# Review lens: <repo> house rules

## Scope
- **<Rule>**: what it checks, in the code's terms (the export, the call, the value).

## Method
Where to start reading, and what to follow: the call to its callers,
the export to its registry, the value back to its source.

## Threshold
Report a change that breaks a rule, with its consequence stated as the
code makes it.

Do not report:
- code outside <paths>;
- values derived from the rule's own source;
- test data;
- anything lint, the type-checker or the tests already enforce;
- rules another lens covers.

## Reporting
- The rule, file and line, and the value or call that breaks it.
- The consequence, as the code makes it, not a worse one.
- The fix.
```

## Test a lens before you trust it

Seed one break on a throwaway branch **without telling the reviewer**:
no issue text, commit message or comment that says the break is
allowed. Check the lens reports it. A lens you haven't seen fire hasn't
been tested.

Review reads diffs, so it never sees a break that's already in the
code. Sweep for those with [maintenance-sweep.md](maintenance-sweep.md).

## Why this works

- **The threshold and the "do not report" list keep the reviewer quiet
  and right.** On Tessl's factory, lenses in this shape gave 2 findings
  across 11 pull requests. Both were real, one a frame-timing bug that
  changed scores, and the other nine reviews came back clean.
- **"As the code makes it, not a worse one" stops severity inflation.**
  The reviewer corrected the house-rules lens's own consequence wording
  against the scores module, in the pull request that added the lens.
- **A reviewer reads intent from the change around it.** Told by the
  issue that a literal colour "overrides" the house rule, it called the
  break intentional and reported nothing. Hence the silent seed. It's
  the same lesson as the 2026-10-30 entry in
  lessons-log.md: prove a check can say
  no.
- **The dropped count makes "no findings" auditable.** Tessl's reviewer
  runs a similar pipeline: candidates, then assessed, then dropped for a
  named reason, then surfaced.

## Source

Distilled from the four default lenses in `tessl/code-review@0.5.0` and
the house-rules lens written during the "Build your own software
factory" workshop, AI Native DevCon NYC, 2026-11-02. The workshop note,
the full lens copies and the review threads are in the vault:
[software-factory-workshop.md](https://github.com/ChrisKornaros/vault/blob/main/notes/software/agentic-engineering/ai-devcon-nyc-2026/software-factory-workshop.md).
