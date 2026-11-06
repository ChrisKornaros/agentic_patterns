#!/usr/bin/env python3
"""PreToolUse re-read guard — vendored companion for no-cat-head-via-bash.

This is the portable copy of the H2 re-read-collapse hook, bundled with
the module so a host repo that vendors `no-cat-head-via-bash` gets a
runnable hook (not just prose). Wire it from the host's
`.claude/settings.json` per the module's index.md "Companion files"
section — the shape is shipped in
`templates/_shared/claude-settings.example.json`.

    Canonical source (kept in sync; edit there first, then re-copy):
    case-studies/agentic-optimization-research/experiments/
    h2-re-read-collapse/tool/pre_read_guard.py

Why it lives here too: a host vendors the module directory only, never
the experiment scaffolding, so the script has to travel with the module
to be usable. This mirrors how stay-in-project-tree and no-sudo-as-shortcut
ship a `settings-snippet.json` companion.

---

Tracks per-session Read calls and blocks redundant re-reads of files the
session has already read and not modified since. Edit/Write/MultiEdit
calls mark a file as "modified", so the *next* Read of that file is
allowed (legitimate post-edit re-read).

A Read is a *range*: `offset`/`limit` name the lines it asks for, no
offset and no limit means the whole file, and `pages` names a PDF page
range. The guard records the ranges read per file and blocks only a Read
whose range lies entirely inside what was already read (adjacent ranges
merge). Reading the first 200 lines and then `offset=200` for the rest
is two different reads and both run; asking for lines 1–100 again is the
redundant re-read. (agentic_patterns issue #12, 2026-11-06: keying on the
path alone blocked the second half of every large file.)

State is per-session JSON at:

    $H2_STATE_DIR/<session_id>.json
    (default: ~/.cache/agentic_metrics/h2-re-read-tracker/)

The hook fails open: any unexpected condition (malformed payload, I/O
error, exception in decision logic) returns exit 0 so the tool call
proceeds. The block path is reserved for the *intended* case — a
redundant re-read of an unmodified file.

Before blocking, the hook verifies against the session *transcript* that
this run actually executed a read of the file (block only on positive
confirmation — see ``_executed_read_in_session``). This defends against
session-id carryover on --resume/--continue, where the per-session state
file persists and would otherwise block a first/only read the agent never
loaded (the ~47% SPURIOUS_NO_PRIOR false positives the 2026-06-11 audit
found).

Disable for one session by setting H2_REREAD_GUARD_DISABLED=1 in the
shell that launches Claude Code.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path


STATE_DIR = Path(
    os.environ.get(
        "H2_STATE_DIR",
        os.path.expanduser("~/.cache/agentic_metrics/h2-re-read-tracker"),
    )
)

_DISABLED_TRUTHY = {"1", "true", "yes", "on"}
DISABLED = os.environ.get("H2_REREAD_GUARD_DISABLED", "").lower() in _DISABLED_TRUTHY


def _state_path(session_id: str) -> Path:
    safe = "".join(c if c.isalnum() or c in "-_." else "_" for c in session_id)
    return STATE_DIR / f"{safe}.json"


def load_state(session_id: str) -> dict:
    path = _state_path(session_id)
    if not path.exists():
        return {"files": {}}
    try:
        return json.loads(path.read_text())
    except Exception:
        return {"files": {}}


def save_state(session_id: str, state: dict) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    path = _state_path(session_id)
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, separators=(",", ":")))
    tmp.replace(path)


def _mtime_ns(file_path: str) -> int | None:
    """Current mtime of file_path in nanoseconds, or None if it can't be stat'd.

    A None means "no external-change signal available" (file missing, perms,
    etc.) — callers treat that conservatively and fall back to the prior
    tracked-tool behaviour.
    """
    try:
        return os.stat(file_path).st_mtime_ns
    except OSError:
        return None


def _executed_read_in_session(transcript_path: str | None, file_path: str) -> bool:
    """True iff the session transcript shows a Read of file_path that actually
    *executed* — a Read ``tool_use`` whose id has a matching non-error
    ``tool_result``.

    This is the guard against **session-id carryover**: ``--resume`` /
    ``--continue`` reuse a session_id, so the per-session state file on disk can
    hold an entry this run never created. Replaying state alone then blocks a
    file the agent has *not* loaded — the ~47% ``SPURIOUS_NO_PRIOR`` false
    positives the 2026-06-11 audit found. The transcript is the ground truth for
    "did *this* run read it", so we confirm against it before blocking.

    The contract is **block only on positive confirmation**: this returns True
    only when it can prove a genuine prior executed read, and False for every
    other case (no transcript, unreadable, unparseable, or simply not found).
    That keeps the failure mode aligned with the hook's fail-open philosophy —
    an unverifiable re-read is allowed, never blocked.

    Two cases are deliberately excluded from "executed":

    * The **current pending Read** — PreToolUse fires before it runs, so its
      ``tool_use`` may already be in the transcript, but it never has a result
      yet.
    * A Read that was **itself blocked** earlier — it carries an ``is_error``
      result, so its content never loaded; a retry should be allowed.
    """
    if not transcript_path:
        return False
    try:
        read_ids: set[str] = set()
        ok_result_ids: set[str] = set()
        with open(transcript_path, encoding="utf-8") as fh:
            for line in fh:
                # Cheap pre-filter: skip lines that can't carry either block.
                if '"tool_use"' not in line and '"tool_result"' not in line:
                    continue
                try:
                    rec = json.loads(line)
                except Exception:
                    continue
                content = (rec.get("message") or {}).get("content")
                if not isinstance(content, list):
                    continue
                for block in content:
                    if not isinstance(block, dict):
                        continue
                    btype = block.get("type")
                    if btype == "tool_use" and block.get("name") == "Read":
                        if (block.get("input") or {}).get("file_path") == file_path:
                            bid = block.get("id")
                            if bid:
                                read_ids.add(bid)
                    elif btype == "tool_result" and not block.get("is_error"):
                        rid = block.get("tool_use_id")
                        if rid:
                            ok_result_ids.add(rid)
        return bool(read_ids & ok_result_ids)
    except Exception:
        return False


def _requested_range(tool_input: dict) -> tuple[int, int | None]:
    """The line range a Read asks for, as (start, end) inclusive; end None = to EOF.

    No offset and no limit is the whole file. A non-numeric or non-positive
    value falls back to the open-ended reading, which can only *allow* more.
    """
    offset, limit = tool_input.get("offset"), tool_input.get("limit")
    if offset is None and limit is None:
        return 1, None
    try:
        start = max(int(offset), 1) if offset is not None else 1
    except (TypeError, ValueError):
        start = 1
    try:
        count = int(limit) if limit is not None else 0
    except (TypeError, ValueError):
        count = 0
    return (start, start + count - 1) if count > 0 else (start, None)


def _covered(ranges: list, want: tuple[int, int | None]) -> bool:
    """True iff every line of ``want`` lies inside the union of ``ranges``.

    ``ranges`` is a list of [start, end] pairs with end None for "to EOF";
    touching or overlapping pairs merge first, so [1,200] + [201,None]
    covers the whole file.
    """
    spans = sorted(((int(a), b) for a, b in ranges), key=lambda r: r[0])
    merged: list[list] = []
    for a, b in spans:
        if merged and (merged[-1][1] is None or a <= merged[-1][1] + 1):
            if merged[-1][1] is not None:
                merged[-1][1] = None if b is None else max(merged[-1][1], b)
        else:
            merged.append([a, b])
    s, e = want
    return any(a <= s and (b is None or (e is not None and e <= b)) for a, b in merged)


def _fresh_entry(reads: int, mtime_ns: int | None, want: tuple, pages) -> dict:
    """A state entry for a file as of a read that is allowed to proceed."""
    return {
        "reads": reads,
        "modified_since_read": False,
        "read_mtime_ns": mtime_ns,
        "ranges": [] if pages is not None else [list(want)],
        "pages": [str(pages)] if pages is not None else [],
    }


def decide(payload: dict) -> tuple[int, str]:
    """Pure decision function.

    Returns (exit_code, stderr_message). Exit 0 = allow; exit 2 = block.
    """
    session_id = payload.get("session_id") or "unknown"
    tool_name = payload.get("tool_name") or ""
    tool_input = payload.get("tool_input") or {}
    file_path = tool_input.get("file_path") or ""

    if not file_path or tool_name not in {"Read", "Edit", "Write", "MultiEdit"}:
        return 0, ""

    state = load_state(session_id)
    files = state.setdefault("files", {})
    entry = files.get(file_path)
    want = _requested_range(tool_input)
    pages = tool_input.get("pages")  # a PDF page range, its own axis

    if tool_name == "Read":
        if entry is not None and not entry.get("modified_since_read", False):
            # Already read, and no tracked Edit/Write/MultiEdit since. Before
            # blocking, check the file's mtime: an external edit (the IDE,
            # another process, a git op) bumps mtime *without* going through a
            # tracked tool, and the harness's own edit-freshness check will then
            # demand a fresh Read before it lets an Edit through. Blocking that
            # re-read deadlocks the two freshness models against each other, so
            # treat an mtime newer than the one recorded at read-time as a
            # legitimate external modification and allow the re-read.
            cur_mtime = _mtime_ns(file_path)
            prev_mtime = entry.get("read_mtime_ns")
            if cur_mtime is not None and prev_mtime is not None and cur_mtime > prev_mtime:
                files[file_path] = _fresh_entry(entry.get("reads", 0) + 1, cur_mtime, want, pages)
                save_state(session_id, state)
                return 0, ""
            # Ranged read (issue #12): a range not yet covered is new content,
            # not a re-read. An entry from before ranges were tracked counts
            # as a whole-file read.
            if pages is not None:
                already = str(pages) in (entry.get("pages") or [])
            else:
                already = _covered(entry.get("ranges") or [[1, None]], want)
            if not already:
                if pages is not None:
                    entry.setdefault("pages", []).append(str(pages))
                else:
                    entry.setdefault("ranges", [[1, None]] if "ranges" not in entry else []).append(list(want))
                entry["reads"] = entry.get("reads", 0) + 1
                save_state(session_id, state)
                return 0, ""
            # Carryover guard: the state entry says "already read", but state is
            # keyed by session_id and survives --resume/--continue, so it may be
            # a leftover this run never created. Only block if the transcript
            # proves *this* session actually executed a read of the file;
            # otherwise reseed from the current read and allow (the
            # SPURIOUS_NO_PRIOR false-positive fix — see audit 2026-06-11).
            if not _executed_read_in_session(payload.get("transcript_path"), file_path):
                files[file_path] = _fresh_entry(1, cur_mtime, want, pages)
                save_state(session_id, state)
                return 0, ""
            # Redundant re-read of an unmodified file → block.
            if pages is not None:
                asked = f"pages {pages}"
            elif want == (1, None):
                asked = "the whole file"
            else:
                asked = f"lines {want[0]}–{want[1] if want[1] is not None else 'end'}"
            msg = (
                f"[h2-re-read-guard] BLOCKED: '{file_path}' was already read "
                f"earlier in this session ({asked} is inside what you have "
                f"read) and has not been modified by Edit/Write/MultiEdit "
                f"since. The prior content is still in your context — refer "
                f"to it instead of re-reading. A Read with an offset/limit "
                f"outside the lines already read is allowed.\n"
                f"\n"
                f"(An external edit that bumped the file's mtime is detected "
                f"automatically and would not be blocked — so its content "
                f"really is unchanged since you read it.) If you still have a "
                f"specific reason to re-read, set "
                f"H2_REREAD_GUARD_DISABLED=1 in the shell that launched "
                f"Claude Code, or see the module's index.md for context."
            )
            return 2, msg
        # First read OR re-read after an intervening modification. Record the
        # mtime of the version being read so a later external edit is detectable.
        prev_reads = entry.get("reads", 0) if entry else 0
        files[file_path] = _fresh_entry(prev_reads + 1, _mtime_ns(file_path), want, pages)
        save_state(session_id, state)
        return 0, ""

    # Edit / Write / MultiEdit: mark file as modified, always allow.
    if entry is None:
        files[file_path] = {"reads": 0, "modified_since_read": True}
    else:
        entry["modified_since_read"] = True
    save_state(session_id, state)
    return 0, ""


def main() -> int:
    if DISABLED:
        return 0

    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0  # malformed payload → fail open

    try:
        exit_code, stderr_msg = decide(payload)
    except Exception:
        return 0  # any unexpected error → fail open

    if stderr_msg:
        print(stderr_msg, file=sys.stderr)
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
