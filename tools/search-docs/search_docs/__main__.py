"""CLI smoke entrypoint.

Usage:
    uv run search-docs query "your query here"
    uv run search-docs smoke <queries.json>   # run a query/expectation set
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from search_docs.bm25 import Index
from search_docs.corpus import load_corpus


def build_index() -> Index:
    chunks = load_corpus()
    return Index(chunks)


def cmd_query(args: argparse.Namespace) -> int:
    index = build_index()
    results = index.search(args.query, k=args.k)
    if not results:
        print("(no results)")
        return 1
    for i, r in enumerate(results, 1):
        print(f"{i:>2}. [{r.score:6.2f}] {r.path}  §{r.heading}")
        print(f"    {r.excerpt[:200]}")
    return 0


def cmd_smoke(args: argparse.Namespace) -> int:
    smoke_path = args.queries or os.environ.get("SEARCH_DOCS_SMOKE_FILE")
    if not smoke_path:
        print(
            "smoke: provide a queries file as a positional arg or via "
            "SEARCH_DOCS_SMOKE_FILE. The query/expectation set is repo-specific "
            "(e.g. the H1 experiment's smoke_queries.json), not shipped with the "
            "tool.",
            file=sys.stderr,
        )
        return 2
    spec = json.loads(Path(smoke_path).read_text())
    index = build_index()
    passed = 0
    for q in spec["queries"]:
        results = index.search(q["query"], k=3)
        top3_paths = {r.path for r in results}
        hit = bool(top3_paths & set(q["expect_any_of"]))
        passed += int(hit)
        marker = "PASS" if hit else "FAIL"
        print(f"[{marker}] {q['query']!r}")
        for r in results:
            tag = "*" if r.path in q["expect_any_of"] else " "
            print(f"   {tag} [{r.score:6.2f}] {r.path}  §{r.heading}")
        if not hit:
            print(f"   expected any of: {q['expect_any_of']}")
    total = len(spec["queries"])
    print(f"\n{passed}/{total} passed (criterion: >=4/5)")
    return 0 if passed >= 4 else 1


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="search-docs")
    sub = parser.add_subparsers(dest="cmd")

    p_q = sub.add_parser("query", help="Search the corpus (default subcommand)")
    p_q.add_argument("query", nargs="+", help="Query string")
    p_q.add_argument("-k", type=int, default=5, help="Top-k results (default 5)")
    p_q.set_defaults(func=cmd_query)

    p_s = sub.add_parser("smoke", help="Run a query/expectation set from a JSON file")
    p_s.add_argument(
        "queries",
        nargs="?",
        default=None,
        help="Path to a smoke queries JSON (else SEARCH_DOCS_SMOKE_FILE)",
    )
    p_s.set_defaults(func=cmd_smoke)

    # Allow bare `search-docs "query string"` without explicit subcommand.
    args, extras = parser.parse_known_args(argv)
    if args.cmd is None:
        if not (argv if argv is not None else sys.argv[1:]):
            parser.print_help()
            return 2
        args = p_q.parse_args(argv)
    if args.cmd == "query":
        args.query = " ".join(args.query)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
