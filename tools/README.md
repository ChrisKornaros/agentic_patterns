# tools/ — runnable agent tools

Small, **runnable** tools the agent uses *during* a session — as distinct
from `metrics/` (which measures Claude usage after the fact) and
`tools-stack/` (opinions, not code). Each tool here is self-contained,
vendorable into a host repo, and has its own `README.md` (human) +
`CLAUDE.md` (agent) pair. Tools come in two shapes: **MCP servers** (wired
into a host's `.mcp.json` via `mcp-entry.json`) and plain **REST CLIs** we
own (run directly, vendored by copying the dir).

| Tool | Status | Role |
|---|---|---|
| [search-docs/](search-docs/) | 🟢 live | BM25 doc-retrieval MCP server (`mcp__search_docs__search`) over a repo's markdown. Promoted here from the H1 experiment in B2 (`roadmap/08` §B2); parameterized so `/bootstrap-repo` can wire it into any host repo. |
| `plane` | 🟢 live | Zero-dependency REST CLI (stdlib `urllib`) for [Plane Cloud](https://app.plane.so) — the Product Owner agent's board surface. Projects, issues, states, cycles, modules, and epics, read and write, all verified live (first write round-trip 2026-06-08). Token from Bitwarden via `bw`. Not an MCP server — vendored by copy. Successor: the `agentic_administration` Plane adapter (`14-agentic-administration` D10); retiring this CLI is Chris's call. |
| [library-catalog/](library-catalog/) | 🟢 live | Generates the vault library's `CATALOG.md` from every reference page's frontmatter and checks pages against the page contract (`--check --strict` is the verify step). The file an agent reads first to find a library page; its **Wanted** section is the library's queue. Daedalus's vault tier (`roadmap/15` §5). Not an MCP server. |
| [headless-runner/](headless-runner/) | 🟢 live | One `claude -p` job in its own worktree, the launching environment scrubbed so the transcript reads `sdk-cli`, the JSON result wrapped in an envelope and loaded by `warehouse headless-import`; the worktree removed, unpushed work kept on its branch. Daedalus's factory runtime for the Epoch-I trial (`roadmap/15` §7, D8). One bash file, not an MCP server. |
| [clew/](clew/) | 🟢 live | The commit-to-session trailer: a `prepare-commit-msg` hook that appends `Clew: <session-id>` to every commit made from a Claude Code session, plus `install.sh` (install / `--check` / `--uninstall`, per repo, per machine). Read back with `warehouse commits-import`. Daedalus's provenance primitive (`roadmap/15` D7). Two POSIX shell files, no dependencies, not an MCP server. |

## The vendoring contract (`mcp-entry.json`)

A tool is **vendorable** when it ships an `mcp-entry.json` declaring how
it wires into a host's root `.mcp.json`:

```json
{
  "server_key": "search_docs",
  "server": {
    "command": "uv",
    "args": ["--directory", "__DIR__", "run", "search-docs-server"]
  }
}
```

[`scripts/install-modules.sh --tool <name>`](../scripts/install-modules.sh)
copies the tool to `<host>/.claude/tools/<name>/` (pruning
`.venv`/`__pycache__`), substitutes `__DIR__` → `.claude/tools/<name>`,
records a `TOOLS.md` ledger row, and prints the `{server_key: server}`
snippet to merge into the host's `.mcp.json`. Keeping the server key +
entrypoint in `mcp-entry.json` (canonical to the tool) lets the script
stay tool-agnostic. The full recipe — including the **two** required
wirings (`.mcp.json` to run, the CLAUDE.md nudge to be used) — is
[modules/VENDORING.md §10](../modules/VENDORING.md#10-vendor-the-runnable-tools).

## Why this is its own folder

The `search_docs` server began life inside the
H1 experiment
— but an experiment dir is *frozen-in-time evidence*, and a tool we want
to keep evolving and vendor into new repos needs a stable home. B2
promoted it here and generalized the corpus root + excludes so the same
package serves this repo and any host that bootstraps it.
