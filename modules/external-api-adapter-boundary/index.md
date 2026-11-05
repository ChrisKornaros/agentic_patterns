---
name: external-api-adapter-boundary
type: guardrail
scope: repo
lifecycle: experimental
dependencies: []
evidence:
  - 03-design-patterns.md#the-seven-patterns
  - web.md#patterns-to-keep-framework-agnostic
  - 14-agentic-administration.md
applies_when:
  - project integrates ≥1 third-party API or SDK (payments, social platforms, LLM providers, storage)
version: 2
---

# Wrap each external API behind an adapter — depend on your interface, not their SDK

## Rule

Every third-party API or SDK gets a thin adapter module that exposes
an **internal, project-shaped interface**; the rest of the codebase
depends on that interface, never on the vendor SDK directly. The
adapter is the only place that imports the vendor library, knows its
auth dance, maps its error types to the project's, and translates its
payloads to/from the project's own models. When a second platform
(or a vendor's v2 API) shows up, it implements the same interface —
callers don't change.

## Why

This is the "thin routes, thick services" / framework-agnostic
service-layer pattern
(`03-design-patterns` §The seven patterns,
patterns 1 and 4), pushed out to the *vendor* edge: the same way a
web route shouldn't carry business logic, application code shouldn't
carry vendor-SDK shapes. The repo already states the
auth-specific corner of this — "no hand-rolled auth; use a proven
library"
(`web` §Patterns to keep, framework-agnostic) —
the adapter boundary generalizes it: a proven library is fine, but
it lives behind your interface so swapping or upgrading it isn't a
codebase-wide edit.

The `content_manager` project is the forcing case. It publishes to
YouTube, Instagram, and TikTok, each with a different SDK, auth model,
and quirk (TikTok is upload-as-draft, not direct-post). Building it
"vertically, one platform at a time" only works if each platform sits
behind a shared publish interface; otherwise the YouTube-specific
shape leaks into the scheduler, the DB layer, and the website-embed
step. The website integration is itself an adapter (a `site/` module
that edits a local Quarto clone, commits, and pushes) over the same
boundary — proof the pattern isn't social-media-specific.

## How to apply

- **Adding an integration:** create `adapters/<vendor>.py` (or a
  package) that imports the SDK and exposes verbs in the project's
  language — `publish(post) -> PublishResult`, not
  `youtube.videos().insert(...)`. Callers import the adapter, not
  `googleapiclient`.
- **Define the interface from the project's needs, not the vendor's.**
  The method signatures describe what *your app* does ("publish a
  recipe video"), so a second vendor can satisfy them. If you find
  yourself naming methods after the vendor's endpoints, the boundary
  is in the wrong place.
- **Map errors at the boundary.** The adapter catches vendor
  exceptions and raises the project's own (`PublishRejected`,
  `RateLimited`) so callers never `except googleapiclient.HttpError`.
- **Secrets enter here.** The adapter is the consumer of the
  [[secrets-no-plaintext]] boundary — it asks `secrets.get(...)`; the
  rest of the code asks the adapter.
- **Tests target the interface.** Because callers depend on your
  interface, tests inject a fake adapter — which is exactly what
  [[no-live-external-in-tests]] requires, and the adapter boundary is
  what makes it cheap.

### Verify against the vendor, not your reading of it (v2)

A fake, a filter or a recorded vendor fact is a *claim about the
vendor*. Offline tests prove the claim is self-consistent, not that
it's true. Four habits keep the claims honest. They come from the
agentic_administration build, where the Plane, Jira and Confluence
adapters each went through a live conformance run
(`roadmap/14` §3.1–§3.6b):

- **Know which rules your fake has seen live.** A fake transport built
  from the vendor's docs tests your reading of the docs. Mark each of
  its rules as *seen live* or *only read* (a header comment is enough).
  Feed every surprise from a live run back into the fake in the same
  PR. Seen four times across three adapters:
  - Plane's slash-less 301 and its two label shapes surfaced only live.
  - The Jira fake refused a sub-task under an epic that live Jira took.
  - The Jira fake left a moved story's sub-tasks behind; live Jira
    carried them.
  - The Confluence fake didn't know that page ids aren't in creation
    order.
- **Check a read-side filter with a known hit and a known miss.**
  "200, empty" fits a working filter and an ignored parameter equally
  well. Plane's search ignored `external_id` entirely, and an
  idempotency lookup had been built on the empty answer. Ask for a
  record you know exists (expect exactly it), then for a wrong value
  (expect nothing).
- **Read the vendor's own SDK before probing live.** Its route strings
  are the vendor's current map, and a missing client method is evidence
  of a missing endpoint. The live probe then confirms known paths
  instead of guessing: 68 known Plane paths, and the only 404 was the
  one guessed URL.
- **Date the vendor facts.** "No official X exists" and "the API has no
  Y" are true *on a date*. Write a "verified against <date / SDK
  version>" next to each one, and re-check them before a successor
  builds on them. Three months after the Plane CLI's premise was
  recorded, an official MCP server, an epics-model change and a route
  rename had all landed.

## Anti-patterns

- `import stripe` (or `googleapiclient`, `instagrapi`, …) in a route
  handler, a model, or the scheduler. The vendor is now welded to
  that layer.
- An "adapter" whose methods mirror the vendor's endpoints 1:1
  (`create_media_container`, `publish_media_container`). That's a
  passthrough, not a boundary — the vendor's shape still dictates
  your callers.
- Catching vendor exception types outside the adapter. A vendor
  library upgrade that renames an exception now breaks call sites.
- One giant `integrations.py` that branches on `if platform ==
  "youtube"` internally. Each platform is its own adapter behind the
  shared interface; the dispatch lives above them, not inside one
  file.
- Returning the vendor's raw response object to callers. Translate to
  a project model so the response schema isn't a hidden dependency.

## Related

- [[secrets-no-plaintext]] — the adapter is where credentials are
  read; the two boundaries stack.
- [[no-live-external-in-tests]] — the adapter interface is the seam
  tests substitute at; this module is what makes that substitution
  clean.
- [[duckdb-default-store]] — the persistence boundary's sibling; both
  keep an external dependency (a DB engine, a vendor API) from
  spreading through the codebase.
