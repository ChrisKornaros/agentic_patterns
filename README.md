# agentic_patterns

A tested, reusable subset of my personal research and development
repos: instruction modules, agent skills, prompts, and project
templates for working with coding agents. Everything here has been
exercised in real projects before being published.

## Layout

| Path | What it holds |
| --- | --- |
| `modules/` | Portable instruction modules — one guardrail or convention per module, written to be vendored into a host repo |
| `skills/` | Agent skills (slash commands) — packaged workflows an agent follows verbatim |
| `prompts/` | Standalone prompt documents behind the skills, usable without the skill wrapper |
| `templates/` | Project scaffolding for common project shapes |
| `tools/` | Runnable agent tools: a BM25 doc-retrieval MCP server, a headless one-job-per-worktree runner for `claude -p`, the commit-to-session trailer hook, and a library catalog generator |
| `experiments/` | Curated example outputs from the source repo's experiments — pre-registered designs, blinded-rating artifacts, result stats |
| `scripts/` | The publish pipeline that produces everything above (native to this repo), beside the exported vendoring and check scripts: `install-modules.sh` vendors modules, skills and tools into a host repo with ledgers; `check_links.sh` and `check_modules.sh` are the verify step |

Directories appear as content is published; the table describes the
full intended shape.

## How this repo is published

This is a **one-way published artifact**. Content is exported from a
private research repo by [`scripts/publish.sh`](scripts/publish.sh)
using an explicit allowlist, sanitized, and committed as
`sync from source @ <short-sha>`. The private repo stays canonical:

- **Never edit exported content here** — changes land upstream and
  arrive with the next publish run.
- Only this repo's own docs and tooling (this README, the publish
  pipeline under `scripts/`) are edited in place.

## Vendoring from here

This repo is laid out so it can be vendored *from*: copy it at a
pinned commit into your own private library, adapt the texts there,
and run `scripts/install-modules.sh` from that copy against each
repo that should carry the modules. The script derives the
"pulled from" line of the ledgers it writes from the copy's own
`origin` remote, so the ledgers name your library, not this one. The
full contract is [modules/VENDORING.md](modules/VENDORING.md).

## License

MIT — see [LICENSE](LICENSE). Reuse freely; attribution appreciated.
