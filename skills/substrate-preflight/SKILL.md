---
name: substrate-preflight
description: "Runs the rate-limit / cost / ToS / kill-switch / local-alternative checklist before committing work to a third-party substrate. Use when a phase is about to depend on an external API, paid/metered service, or rate-limited source."
version: 1.0.0
source: prompts/substrate-preflight.md
module: substrate-preflight
tags: [guardrail, agentic-optimization-research]
---

# Substrate pre-flight

Use *before* committing a phase to a third-party substrate — an
external API, a data source, a service with rate limits or paid
metering, any vendor surface you haven't load-bearing-tested. Canonical
text is the [substrate-preflight](../../modules/substrate-preflight/index.md)
module.

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

## Why this works

External substrate decisions are the most expensive class of
mid-phase reversal — a ~5-minute pre-flight avoids a redo PR (the PUT
B2 → B2-redo when a 10 req/min limit met a search-as-you-type UX).
Question (5) is the cost-discipline anchor; (7) is the leverage
question. Full rationale in the
[substrate-preflight module](../../modules/substrate-preflight/index.md) /
[prompts/substrate-preflight.md](../../prompts/substrate-preflight.md).
