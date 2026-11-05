"""BM25 index over markdown chunks. Thin wrapper around rank_bm25."""

from __future__ import annotations

import re
from dataclasses import dataclass

from rank_bm25 import BM25Okapi

from search_docs.corpus import Chunk, excerpt

TOKEN_RE = re.compile(r"[A-Za-z0-9_]+")

# Small English stopword list — kept inline so the package has no NLTK dep.
# Aim is to drop the noisiest function words; tuning is deferred.
STOPWORDS = frozenset(
    """
    a an and are as at be by for from has have how i if in is it its of on or
    so such than that the their then there these they this to via was were what
    when where which who why will with you your into about over out up not no do
    does did done can could should would may might must shall will also been being
    """.split()
)


def tokenize(text: str) -> list[str]:
    return [
        t for t in (m.group(0).lower() for m in TOKEN_RE.finditer(text))
        if len(t) > 1 and t not in STOPWORDS
    ]


@dataclass(frozen=True)
class SearchResult:
    path: str
    heading: str
    score: float
    excerpt: str


class Index:
    def __init__(self, chunks: list[Chunk]) -> None:
        if not chunks:
            raise ValueError("Index built over empty corpus")
        self.chunks = chunks
        docs = [tokenize(f"{c.heading}\n{c.body}") for c in chunks]
        # rank_bm25 chokes on completely empty docs; substitute a sentinel
        # so the chunk still exists but is unranked.
        self._docs = [d or ["__empty__"] for d in docs]
        self._bm25 = BM25Okapi(self._docs)

    def search(self, query: str, k: int = 5) -> list[SearchResult]:
        q = tokenize(query)
        if not q:
            return []
        scores = self._bm25.get_scores(q)
        # argsort descending; take top-k with score > 0
        ranked = sorted(range(len(scores)), key=lambda i: scores[i], reverse=True)
        out: list[SearchResult] = []
        for idx in ranked:
            score = float(scores[idx])
            if score <= 0:
                break
            c = self.chunks[idx]
            out.append(
                SearchResult(
                    path=c.path,
                    heading=c.heading,
                    score=score,
                    excerpt=excerpt(c.body),
                )
            )
            if len(out) >= k:
                break
        return out
