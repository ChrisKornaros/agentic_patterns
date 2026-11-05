# search-docs — BM25 doc-retrieval MCP server

A tiny [MCP](https://modelcontextprotocol.io) stdio server that exposes a
single `search` tool over a repo's markdown corpus, ranked with BM25
(lexical, not semantic). Registered in a repo's `.mcp.json`, Claude Code
launches it on session start and the tool surfaces to the agent — and in
the warehouse — as `mcp__search_docs__search`.

It exists to give the agent a **topic-lookup** alternative to reflexive
`Bash grep`: "find the rule/module/playbook lesson about X" rather than
"find the literal string X". The H1
experiment
is the evidence trail for *why* — including the sobering
RESULT
that a silently-registered MCP tool sat at **zero adoption**. The fix
(surface it in the host `CLAUDE.md`) is part of what a bootstrap must
carry, not an afterthought — see *Discoverability* below.

## The tool surface

```text
search(query: str, k: int = 5) -> list[
  { path: str, heading: str, score: float, excerpt: str }
]
```

Each result is a markdown *section* (files are chunked by H1/H2 heading).
`path` is repo-relative; `excerpt` is the first ~400 chars of the section
body. Follow up with a `Read` on the path if the excerpt isn't enough.

## Configuration (all optional env)

The defaults make the server **generic across repos** — point it at any
repo and it just works. Three env knobs tune it for a specific host:

| Env var | Default | Effect |
|---|---|---|
| `SEARCH_DOCS_REPO_ROOT` | auto-detect | Corpus root. Auto-detection walks up from the package to the nearest ancestor with both `.git` and `CLAUDE.md`. Set this when that heuristic doesn't fit. |
| `SEARCH_DOCS_EXCLUDE_PREFIXES` | *(none)* | `os.pathsep`- or comma-separated repo-relative path prefixes to skip wholesale (e.g. generated data, frozen experiment dumps). This repo passes `metrics/warehouse/experiments/`. |
| `SEARCH_DOCS_SMOKE_FILE` | *(none)* | Default queries file for the `smoke` CLI subcommand (a positional arg overrides it). |

`.git`, `.obsidian`, `__pycache__`, `node_modules`, and `.venv` are always
skipped.

### How this repo wires it (`.mcp.json`)

```json
"search_docs": {
  "command": "uv",
  "args": ["--directory", "tools/search-docs", "run", "search-docs-server"],
  "env": { "SEARCH_DOCS_EXCLUDE_PREFIXES": "metrics/warehouse/experiments/" }
}
```

When `/bootstrap-repo` vendors this into a host repo (B2 part 2) it
copies the package to `<host>/.claude/tools/search-docs/` and writes the
equivalent block pointed at that path.

## CLI (sanity checks, not the runtime path)

```sh
cd tools/search-docs
uv run search-docs query "how does git flow work" -k 3
# Run a pinned query/expectation set (repo-specific, not shipped here):
SEARCH_DOCS_EXCLUDE_PREFIXES="metrics/warehouse/experiments/" \
  uv run search-docs smoke \
  ../../case-studies/agentic-optimization-research/experiments/h1-bash-grep-replacement/smoke_queries.json
```

The `smoke` set is **repo-specific evidence**, so it lives with the H1
experiment, not in the tool. Its pinned expectations were frozen against
the 2026-05-27 corpus; as a repo's docs grow, exact top-3 hits drift —
that's expected for a frozen sanity set, not a tool regression.

## Discoverability — the load-bearing caveat

H1 proved the mechanism is worthless if the agent never reaches for it.
A vendored deployment is only "done" when the host's `CLAUDE.md` carries a
one-line *"prefer `search_docs` over `grep` for rule/doc lookup"* nudge
**and** the project-scoped MCP server is approved on every machine that
runs sessions there. `/bootstrap-repo` is responsible for both; don't ship
the server silently.

## Layout

```
search-docs/
├── README.md            # this file (human)
├── CLAUDE.md            # agent-scoped notes
├── pyproject.toml       # search-docs / search-docs-server entrypoints
├── uv.lock
└── search_docs/
    ├── __init__.py
    ├── __main__.py      # CLI: query / smoke
    ├── corpus.py        # markdown walker + chunker + exclude config
    ├── bm25.py          # ranker wrapper (rank_bm25)
    └── server.py        # MCP stdio server
```
