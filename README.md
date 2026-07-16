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
| `scripts/` | This repo's own tooling — the publish pipeline that produces everything above |

Directories appear as content is published; the table describes the
full intended shape.

## How this repo is published

This is a **one-way published artifact**. Content is exported from a
private research repo by [`scripts/publish.sh`](scripts/publish.sh)
using an explicit allowlist, sanitized, and committed as
`sync from source @ <short-sha>`. The private repo stays canonical:

- **Never edit exported content here** — changes land upstream and
  arrive with the next publish run.
- Only this repo's own docs and tooling (this README, `scripts/`) are
  edited in place.

## License

MIT — see [LICENSE](LICENSE). Reuse freely; attribution appreciated.
