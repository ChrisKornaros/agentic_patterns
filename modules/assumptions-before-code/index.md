---
name: assumptions-before-code
type: guardrail
scope: repo
lifecycle: experimental
dependencies: []
applies_when:
  - the request is non-trivial and admits more than one reasonable interpretation, or rests on assumptions the human hasn't confirmed
version: 1
---

# Assumptions before code

## Rule

Before writing code on a non-trivial request, surface the thinking
the implementation will rest on: state the load-bearing assumptions
explicitly in chat; if the request admits more than one reasonable
interpretation, present the interpretations and ask instead of
silently picking one; if a simpler path than the requested approach
exists, say so before implementing the requested one; and if the
request is genuinely unclear, stop and ask — a wrong guess shipped
as a finished diff costs more than a question.

## Why

Adapted from the "Think before coding" principle in
[Andrej Karpathy's coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills)
(via [the X post](https://x.com/karpathy/status/2015883857489522876)
that published them). The failure mode it targets: an agent
optimizing for *looking productive* over *being right* picks one
interpretation silently, implements it confidently, and the human
discovers the mismatch only after reviewing a finished diff — the
most expensive possible point. The library's existing planning
surfaces don't catch this: the
[session-start skill](../../skills/session-start/SKILL.md) and
[[phase-kickoff]] operate at session/phase granularity, while
ambiguity shows up per-edit, mid-task. This module is the per-edit
slice.

## How to apply

- **Before the first edit of a task, name what you're assuming** —
  one or two "I'm assuming X / reading this as Y" lines in chat is
  enough. If the human is not watching live, lead the work with them
  so the eventual review starts from the stated frame.
- **When two readings of the request are both plausible, present
  both and ask** (`AskUserQuestion` where available) rather than
  implementing the likelier one. One interpretation being *likelier*
  is not the same as the other being *unreasonable*.
- **Push back once, briefly, when a simpler path exists.** "The
  requested X works, but Y gets the same result with less machinery —
  want Y?" Then implement whichever the human picks without
  relitigating.
- **Calibrate: don't over-ask.** Choices with a conventional default
  or answers derivable from the codebase aren't assumptions — decide
  them, mention the decision, and move on. The rule covers choices
  that change what gets built, not trivia.

## Anti-patterns

- Silently picking one of several reasonable interpretations and
  building it.
- Burying assumptions in code comments or the PR description instead
  of surfacing them *before* the code exists.
- "I went ahead and assumed X" — the assumption announced after the
  diff, when correcting it means rework.
- Implementing the complicated requested approach while privately
  knowing a simpler one exists, to avoid friction.
- Over-correcting into asking about everything — flooding the human
  with questions whose answers are conventional defaults or sit in
  the codebase.

## This rule is working if

- Interpretation corrections happen in chat **before** code exists,
  not in review comments after.
- Transcripts contain "I'm assuming…" / "two readings, which one?"
  lines that get confirmed or corrected cheaply.
- Rework-after-review shrinks: diffs stop being rejected for solving
  the wrong problem.

## Related

- [[verifiable-goal-before-code]] — the companion workflow: once the
  interpretation is settled, frame it as a verifiable goal.
- [[minimum-code-first]] / [[surgical-diffs-only]] — the sibling
  guardrails in the per-edit discipline family, bounding what gets
  written and what gets touched.
- [[phase-kickoff]] — the same surfacing instinct at phase
  granularity.
- The [scope-guard skill](../../skills/scope-guard/SKILL.md) — the
  PR-boundary cousin: it surfaces scope temptations at task start;
  this module surfaces interpretation/assumption gaps.
