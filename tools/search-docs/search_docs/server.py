"""MCP stdio server exposing `search` over a host repo's markdown corpus.

Registered in the host repo's `.mcp.json`; Claude Code launches it on
session start. The tool name surfaces in the warehouse as
`mcp__search_docs__search`.

Corpus root is auto-detected (nearest ancestor with `.git` + `CLAUDE.md`)
or set via `SEARCH_DOCS_REPO_ROOT`; repo-specific subtrees are dropped via
`SEARCH_DOCS_EXCLUDE_PREFIXES`. Tool description is intentionally neutral —
see the H1 experiment README §7 "Tool description bias" for the rationale.
"""

from __future__ import annotations

from mcp.server.fastmcp import FastMCP

from search_docs.bm25 import Index
from search_docs.corpus import load_corpus

mcp = FastMCP("search_docs")

# Build the index once at server start. The repo's markdown corpus is
# small enough (~1.5 MB, ~140 files) that an in-memory rebuild on every
# launch is faster than maintaining an on-disk cache.
_index: Index | None = None


def _get_index() -> Index:
    global _index
    if _index is None:
        _index = Index(load_corpus())
    return _index


@mcp.tool()
def search(query: str, k: int = 5) -> list[dict]:
    """Search the repo's markdown corpus with BM25 lexical retrieval.

    Returns up to `k` chunks ranked by relevance. Each chunk is a
    section of a markdown file (split by H1/H2 headings). Use this
    instead of `Bash grep` when looking for a rule, module, agent
    definition, playbook lesson, or case-study excerpt by topic
    rather than by a known string.

    Args:
      query: Natural-language or keyword query. Lexical, not semantic
        — exact terms matter.
      k: Max number of results to return (default 5).

    Returns:
      A list of {path, heading, score, excerpt} dicts, highest score
      first. `path` is repo-relative; follow up with a `Read` call if
      the excerpt isn't enough.
    """
    results = _get_index().search(query, k=k)
    return [
        {"path": r.path, "heading": r.heading, "score": round(r.score, 3), "excerpt": r.excerpt}
        for r in results
    ]


def main() -> None:
    # Warm the index synchronously so the first tool call doesn't pay
    # the build cost. Failures here surface at server start, not at
    # first-use.
    _get_index()
    mcp.run()


if __name__ == "__main__":
    main()
