# search-docs — agent notes

Scoped context for working **on** the `search_docs` server. For *using*
it, just call `mcp__search_docs__search` — it's registered in this repo's
`.mcp.json`. Human-facing detail is in [README.md](README.md).

## What this is

A vendorable BM25 doc-retrieval MCP server. Canonical home is here under
`tools/`; it was promoted out of the
H1 experiment
in B2 so it can keep evolving and be vendored into host repos. The
experiment dir stays frozen evidence — don't fold tool changes back there.

## Rules for editing here

1. **Keep it generic by default.** No repo-specific paths in the code.
   Anything host-specific (excludes, corpus root, smoke file) is an env
   knob read in [corpus.py](search_docs/corpus.py) / `__main__.py`, set by
   the consumer's `.mcp.json`. The default behavior must work against an
   arbitrary repo.
2. **Never rename the server or tool.** The server is `search_docs` and
   the tool is `search`, so the warehouse records
   `mcp__search_docs__search`. Renaming silently breaks every adoption
   metric and the H1/H2 analyses that key on that string.
3. **The corpus is byte-identical to the old default when the exclude
   env matches.** `exclude_prefixes()` with
   `SEARCH_DOCS_EXCLUDE_PREFIXES=metrics/warehouse/experiments/` reduces
   to the pre-B2 hardcoded constant — keep that equivalence so historical
   comparisons stay valid.
4. **Verify with the CLI smoke**, not the running server (which needs a
   Claude Code restart to pick up changes):
   ```sh
   cd tools/search-docs
   SEARCH_DOCS_EXCLUDE_PREFIXES="metrics/warehouse/experiments/" \
     uv run search-docs smoke \
     ../../case-studies/agentic-optimization-research/experiments/h1-bash-grep-replacement/smoke_queries.json
   ```
   The pinned expectations drift as the corpus grows (frozen at
   2026-05-27); judge ranking *quality*, not an exact pass count.
5. **Bump `version` in [pyproject.toml](pyproject.toml)** on any
   behavior change — the vendoring ledger (`SKILLS.md`-style `TOOLS.md`
   downstream, B2 part 2) pins to it.

## Why BM25, not embeddings

Lexical retrieval is dependency-light (`rank_bm25`, no model download),
deterministic, and fast to rebuild in-memory at server start. The dense
alternative is the separate H3 line
(search-sessions),
which is intentionally a different experiment.
