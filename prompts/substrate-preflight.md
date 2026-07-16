# Substrate pre-flight

Use *before* committing a phase to a third-party substrate — an
external API, a data source, a service with rate limits or paid
metering, any vendor surface you haven't load-bearing-tested.

```
Before we commit Phase <X> to using <substrate>, do a pre-flight pass:

  (1) What's the rate limit (req/sec, req/min, req/day)? Cite the
      vendor's docs URL.
  (2) What's the cost per call (or per token, per byte, per row)?
      What's the free-tier ceiling?
  (3) Does the vendor's terms of service forbid the access pattern
      we'd use (e.g., search-as-you-type, scraping, redistribution)?
  (4) What's the failure mode when the limit is hit — soft throttle,
      hard 429, IP ban, account suspension?
  (5) Where in our code would the call originate? If from a request
      handler, what stops a runaway loop?
  (6) What's the kill-switch? A settings toggle, an env var, a
      feature flag?
  (7) Is there a self-hosted or local alternative (a mirror, a
      bulk download, a periodic refresh) that gives ~80% of the
      value without the live dependency?

If any of (1)–(4) is "unknown" or (5) is "request handler with no
guard" or (7) is "yes and cheaper," reconsider before writing code.
```

## Why this works

External substrate decisions are the most expensive class of
mid-phase reversal — they tend to discover constraints (rate limits,
ToS, costs) only when traffic hits them. The pre-flight is a
~5-minute cost to avoid a redo PR (case study §1.4.2: PUT's B2 → B2-redo
when OpenFoodFacts' 10 req/min limit met a search-as-you-type UX
that needed ~30 req/min in practice).

Question (5) is the cost-discipline anchor: PUT's Amazon PA-API
discipline doc (case study §1.4.3) is the artifact (5)–(6) produce
*before* implementation. A request-handler-originated paid API call
is the anti-pattern; queued jobs with bounded concurrency is the
pattern.

Question (7) is the leverage question. A local DuckDB FTS mirror
refreshed weekly is often a better substrate than a live API for
read-mostly use cases, even before the rate-limit math.

Cross-refs:
- playbook/02-workflow-patterns.md §Updated/5
- playbook/07-anti-patterns.md #11
- case-studies/product-use-tracker/playbook.md §1.4.2–§1.4.3
