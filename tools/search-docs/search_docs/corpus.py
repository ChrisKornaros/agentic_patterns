"""Walk the repo, find markdown files, chunk by H1/H2 sections."""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator

EXCLUDE_DIR_NAMES = {".git", ".obsidian", "__pycache__", "node_modules", ".venv"}
# Repo-relative path prefixes (posix) to skip wholesale. Empty by default so
# the tool is generic across host repos; a consumer sets
# SEARCH_DOCS_EXCLUDE_PREFIXES (os.pathsep- or comma-separated) in its
# `.mcp.json` env to drop repo-specific subtrees — e.g. this repo passes
# `metrics/warehouse/experiments/` so frozen experiment data doesn't drown
# the rule corpus.
DEFAULT_EXCLUDE_PREFIXES: tuple[str, ...] = ()
HEADING_RE = re.compile(r"^(#{1,2})\s+(.+?)\s*$", re.MULTILINE)


def exclude_prefixes() -> tuple[str, ...]:
    """Path prefixes to skip, from SEARCH_DOCS_EXCLUDE_PREFIXES or the default.

    Accepts os.pathsep- or comma-separated entries; each is normalized to a
    single trailing slash so prefix matching against `rel_dir + "/"` is exact.
    """
    raw = os.environ.get("SEARCH_DOCS_EXCLUDE_PREFIXES")
    if not raw:
        return DEFAULT_EXCLUDE_PREFIXES
    parts = [p.strip() for chunk in raw.split(os.pathsep) for p in chunk.split(",")]
    return tuple(p.rstrip("/") + "/" for p in parts if p)


@dataclass(frozen=True)
class Chunk:
    path: str
    heading: str
    body: str


def find_repo_root(start: Path | None = None) -> Path:
    here = (start or Path(__file__)).resolve()
    for parent in (here, *here.parents):
        if (parent / ".git").exists() and (parent / "CLAUDE.md").exists():
            return parent
    raise RuntimeError(
        "Could not locate repo root (looked for sibling .git + CLAUDE.md). "
        "Set SEARCH_DOCS_REPO_ROOT to override."
    )


def repo_root() -> Path:
    override = os.environ.get("SEARCH_DOCS_REPO_ROOT")
    if override:
        return Path(override).resolve()
    return find_repo_root()


def iter_markdown_files(
    root: Path, exclude: tuple[str, ...] | None = None
) -> Iterator[Path]:
    prefixes = exclude_prefixes() if exclude is None else exclude
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDE_DIR_NAMES]
        rel_dir = Path(dirpath).relative_to(root).as_posix()
        if rel_dir != "." and any(
            (rel_dir + "/").startswith(prefix) for prefix in prefixes
        ):
            dirnames[:] = []
            continue
        for name in filenames:
            if name.endswith(".md"):
                yield Path(dirpath) / name


def chunk_markdown(path: str, text: str) -> list[Chunk]:
    headings = list(HEADING_RE.finditer(text))
    if not headings:
        body = text.strip()
        if not body:
            return []
        return [Chunk(path=path, heading=Path(path).name, body=body)]

    chunks: list[Chunk] = []
    preamble_end = headings[0].start()
    preamble = text[:preamble_end].strip()
    if preamble:
        chunks.append(Chunk(path=path, heading=Path(path).name, body=preamble))

    for i, match in enumerate(headings):
        heading = match.group(2).strip()
        body_start = match.end()
        body_end = headings[i + 1].start() if i + 1 < len(headings) else len(text)
        body = text[body_start:body_end].strip()
        if body:
            chunks.append(Chunk(path=path, heading=heading, body=body))
    return chunks


def load_corpus(root: Path | None = None) -> list[Chunk]:
    base = root or repo_root()
    chunks: list[Chunk] = []
    for md_path in iter_markdown_files(base):
        rel = md_path.relative_to(base).as_posix()
        try:
            text = md_path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        chunks.extend(chunk_markdown(rel, text))
    return chunks


def excerpt(body: str, max_chars: int = 400) -> str:
    body = body.strip()
    if len(body) <= max_chars:
        return body
    cut = body[:max_chars].rsplit(" ", 1)[0]
    return cut + "…"
