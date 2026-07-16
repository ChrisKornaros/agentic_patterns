---
name: minimum-code-first
type: guardrail
scope: repo
lifecycle: experimental
dependencies: []
applies_when:
  - the task produces new code (any language, any size)
version: 1
---

# Minimum code first

## Rule

Write the minimum code that solves the stated problem — and nothing
ahead of it. No speculative features the request didn't ask for, no
abstraction with a single caller, no configuration surface nobody
asked to tune, no error handling for states that cannot occur. If the
more general version genuinely looks needed, say so in chat as a
follow-up proposal; don't build it on spec.

## Why

Adapted from the "Simplicity first" principle in
[Andrej Karpathy's coding guidelines](https://github.com/multica-ai/andrej-karpathy-skills)
(via [the X post](https://x.com/karpathy/status/2015883857489522876)
that published them). Agents over-deliver by default: a request for a
function comes back as a class hierarchy with a config object and
defensive guards for impossible inputs. Every unrequested line is a
line the human must review, a surface that can break, and a
generalization guess that's usually wrong. The
[scope-guard skill](../../skills/scope-guard/SKILL.md) catches this
at the PR boundary ("what else am I tempted to *add* to this PR");
this module is the inside-the-diff discipline — restraint within the
code being written, not the work being packaged.

## How to apply

- **Implement for the present caller.** A helper extracted for one
  call site is inlined code wearing a costume; extract when the
  second caller exists.
- **Hard-code what the request hard-codes.** Don't introduce a
  parameter, env var, or config key for a value nobody asked to
  vary; note in chat if you suspect it will need to vary later.
- **Handle the errors that can happen.** Guard inputs that cross a
  trust boundary (user input, external APIs, files); don't guard
  internal invariants the surrounding code already establishes.
- **When tempted to generalize, write the sentence instead of the
  code:** "this could be generalized to X if/when Y — follow-up?"
  Default the answer to follow-up.

## Anti-patterns

- A class (plus base class, plus factory) where the request said
  "a function."
- "While building X I also added support for Y, since it was easy" —
  speculative features riding along unrequested.
- A config option, CLI flag, or env var introduced "for
  flexibility" with exactly one value ever passed.
- `try/except` (or null checks) around code whose inputs the same
  diff fully controls.
- Building "the framework" for a category of problem when the task
  was one instance of it.

## This rule is working if

- Every function, branch, and parameter in the diff has a caller,
  trigger, or consumer **in the current request**.
- Generalization shows up in chat as follow-up proposals, not in the
  diff as unused flexibility.
- Diffs shrink: the human stops reviewing (and questioning) code that
  exists "for later."

## Related

- [[surgical-diffs-only]] — the sibling guardrail: this module
  bounds the *new code written*; that one bounds the *existing code
  touched*.
- [[assumptions-before-code]] / [[verifiable-goal-before-code]] —
  the rest of the per-edit discipline family.
- The [scope-guard skill](../../skills/scope-guard/SKILL.md) — the
  same restraint applied to PR packaging instead of code content.
