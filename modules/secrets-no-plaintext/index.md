---
name: secrets-no-plaintext
type: guardrail
scope: repo
lifecycle: stable
dependencies: []
evidence:
  - common-guardrails.md#never-without-explicit-human-approval
  - ops.md#secrets
applies_when:
  - project authenticates to any external service (API key, OAuth token, DB password, signing key)
version: 1
---

# Secrets never land in plaintext — read them through one boundary

## Rule

No secret — API key, OAuth refresh token, DB password, signing key,
webhook secret — is ever committed, hard-coded, or written to a
plaintext file the agent creates. Secrets live in a dedicated secret
store (a secrets manager, an `age`-encrypted file, or a host `.env`
that is git-ignored and never committed), and the application reads
them through **one** module — a `core/secrets.py`-style boundary —
not by reaching for `os.environ[...]` scattered across the codebase.
Only redacted `*.example` files are committed. Reading an existing
secret to *use* it is fine; printing it, echoing it, logging it, or
pasting it into chat or a commit is not.

## Why

The agentic guardrails already forbid touching secrets, credentials,
or `.env*` files without explicit human approval
(`common-guardrails` §Never),
and the ops stack documents where they're allowed to live — a
git-ignored host `.env`, or `age`-encrypted files in git for rotated
multi-host secrets, never bare env vars on a shared CI host
(`ops` §Secrets).
What those two don't yet state portably is the *single-boundary*
half: the rule that secret access funnels through one module so the
storage backend is swappable and the audit surface is one file.

The `content_manager` project is the forcing case. It authenticates
to YouTube, Instagram, and TikTok and decided — as a hard "do not
relitigate" constraint — that secrets come from Bitwarden (Secrets
Manager, with the `bw` CLI vault as the documented fallback) behind a
`core/secrets.py` boundary, bootstrapped by a single OS env var. That
shape generalizes: the store can be Bitwarden, `age`, or a host
`.env`, but the application only ever calls `secrets.get("name")`.
Hard-coding even one key, or scattering `os.environ` reads, both
re-couples the code to a backend and multiplies the places a secret
can leak into a commit, a log line, or chat.

## How to apply

- **Picking up secrets:** read them through the project's secrets
  module (`core/secrets.py` or equivalent). If one doesn't exist yet
  and the project needs more than a single key, propose creating it
  before sprinkling `os.environ` reads.
- **Local config:** non-secret runtime config goes in a git-ignored
  `.env` parsed by Pydantic Settings (or equivalent); the actual
  secret *values* go in the secret store, not the `.env`, unless the
  host `.env`-as-store pattern is the documented choice for that repo.
- **Committing:** only `*.example` files with redacted placeholders.
  Verify `.gitignore` covers `.env`, `*.key`, `*.pem`, and the secret
  store's local cache before the first commit.
- **Never emit a secret:** don't `echo`/`print`/log a key to confirm
  it loaded — assert its presence (`assert key, "BW_TOKEN unset"`)
  without printing the value. Don't paste a real token into chat to
  ask about it; redact it.
- **Bootstrap token:** the one credential that *must* start as an env
  var (the token that unlocks the store itself) is the documented
  exception — set it in the host environment, never in tracked files.

## Anti-patterns

- `API_KEY = "sk-live-..."` hard-coded "just to get it working." It
  ships to git history and can't be rotated cleanly.
- `os.environ["YT_TOKEN"]` read in five modules. Now the storage
  backend is welded into five files instead of one.
- Committing a real `.env` and "fixing it later" with a force-push.
  The secret is already in history; rotation is the only fix.
- `print(f"loaded key: {key}")` to debug. The value is now in the
  transcript, the terminal scrollback, and possibly a log file.
- Putting secrets in plain environment variables on a shared CI
  runner with no vault — flagged directly in
  `ops` §Secrets.

## Related

- [[stay-in-project-tree]] — secrets often live just outside the tree
  (a host `.env`, `~/.config/...`); the two pair on "don't reach for
  the credential file directly."
- [[external-api-adapter-boundary]] — the adapter that wraps an
  external API is the natural consumer of the secrets boundary; the
  adapter asks `secrets.get(...)`, the rest of the code asks the
  adapter.
- [[no-live-external-in-tests]] — if tests never hit the live
  service, they never need the real secret either.
