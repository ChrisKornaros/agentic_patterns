---
name: substrate-preflight
type: prompt
scope: task
lifecycle: stable
dependencies: []
evidence:
  - prompts/substrate-preflight.md
  - case-studies/product-use-tracker/playbook.md#142-the-b2--b2-redo-lesson--mid-phase-re-architecture-is-ok
  - playbook/07-anti-patterns.md#11-external-paid-surface-introduced-without-a-pre-locked-cost-discipline
applies_when:
  - a phase is about to depend on an external API, paid/metered service, or rate-limited source
  - the vendor surface hasn't been load-bearing-tested in this repo yet
version: 1
---

# Substrate pre-flight

## Rule

Before committing a phase to a third-party substrate — an external API,
a data source, a service with rate limits or paid metering, any vendor
surface you haven't load-bearing-tested — run the seven-question
pre-flight pass below *before any code is written*. If any of (1)–(4) is
"unknown," (5) is "request handler with no guard," or (7) is "yes and
cheaper," reconsider the substrate before implementing.

## Why

External substrate decisions are the most expensive class of mid-phase
reversal: their constraints (rate limits, ToS, cost) only surface when
traffic hits them, by which point the surrounding code already assumes
the substrate. A ~5-minute pre-flight is the cheap insurance against a
redo PR — in the master case study, PUT's Smart Add B2 became B2-redo
when OpenFoodFacts' 10 req/min REST limit met a search-as-you-type UX
that needed ~30 req/min in practice
(case study §1.4.2,
playbook/07 #11).
Question (5) is the cost-discipline anchor — a paid call from a request
handler is the anti-pattern, a queued job with bounded concurrency is
the pattern. Question (7) is the leverage question: a local mirror
refreshed periodically often beats a live API for read-mostly use even
before the rate-limit math. Full rationale in
[prompts/substrate-preflight.md](../../prompts/substrate-preflight.md).

## How to apply

Paste this before committing the phase, filling in `<X>` and
`<substrate>`:

```
Before we commit Phase <X> to using <substrate>, do a pre-flight pass:

  (1) What's the rate limit (req/sec, req/min, req/day)? Cite the
      vendor's docs URL.
  (2) What's the cost per call (or per token, per byte, per row)?
      What's the free-tier ceiling?
  (3) Does the vendor's terms of service forbid the access pattern
      we'd use (search-as-you-type, scraping, redistribution)?
  (4) What's the failure mode when the limit is hit — soft throttle,
      hard 429, IP ban, account suspension?
  (5) Where in our code would the call originate? If from a request
      handler, what stops a runaway loop?
  (6) What's the kill-switch? A settings toggle, an env var, a flag?
  (7) Is there a self-hosted or local alternative (a mirror, a bulk
      download, a periodic refresh) that gives ~80% of the value
      without the live dependency?

If any of (1)–(4) is "unknown" or (5) is "request handler with no
guard" or (7) is "yes and cheaper," reconsider before writing code.
```

- The answers to (5)–(6) are the cost-discipline artifact — write them
  down (an ADR or a short discipline doc) *before* implementation, the
  way PUT's Amazon PA-API discipline doc was authored ahead of the code.
- Treat "unknown" on (1)–(4) as a blocker, not a footnote: the unknown
  is exactly the constraint that bites later.

## Anti-patterns

- Skipping the pre-flight because the API "looks simple" — the simple
  ones are where the undocumented rate limit hides.
- Wiring a paid or rate-limited call directly into a request handler
  with no queue, cap, or kill-switch.
- Answering (7) with "no" without actually checking for a bulk download
  or mirror — the local alternative is the cheapest substrate when it
  exists.
- Discovering the rate limit from a production 429 instead of from the
  vendor's docs.

## This rule is working if

- Every phase that introduces an external surface has the seven answers
  recorded *before* the implementing diff.
- No paid/rate-limited call originates from a request handler without a
  documented guard.
- "Unknown" on (1)–(4) reliably stops the phase rather than shipping.

## Related

- [[phase-kickoff]] — its kickoff prompt routes a phase to this
  pre-flight when it touches a new substrate.
- [[external-api-adapter-boundary]] — where the surviving substrate's
  calls get fenced once the pre-flight clears it.
- [[no-live-external-in-tests]] — the test-time companion: the live
  substrate is never exercised from the test suite.
