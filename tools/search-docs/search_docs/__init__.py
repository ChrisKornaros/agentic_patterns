"""BM25 retrieval over a repo's markdown — vendorable doc-search package."""

from search_docs.corpus import Chunk, load_corpus
from search_docs.bm25 import Index, SearchResult

__all__ = ["Chunk", "Index", "SearchResult", "load_corpus"]
