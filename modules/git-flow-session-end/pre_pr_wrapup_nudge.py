#!/usr/bin/env python3
"""PreToolUse hook — wrap-up-surface nudge on `gh pr create`.

Vendored companion for the `git-flow-session-end` module, added as the
H5 follow-up (RESULT §4 item 3). H5 measured that sessions ship their
end-of-session PR without loading any wrap-up surface — 33–40%
follow-rate on the `session-wrapup` pointer classes — even though the
*workflow* is mostly executed correctly via hooks and priors. Per the
trigger-strength ladder (roadmap/12 §3), a bare pointer doesn't get
read; this hook gives the pointer a decision-time trigger.

Mechanism: when the agent issues a Bash `gh pr create` and **no wrap-up
surface has loaded this session**, inject a one-line reminder via the
non-blocking `additionalContext` channel:

    {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                            "additionalContext": "<nudge>"}}

No `permissionDecision` is emitted — the PR creation proceeds
untouched; the nudge lands next to the tool result, in time for the
post-PR half of the loop (docs-sync check, merge popup, cleanup,
Session end summary).

"Wrap-up surface loaded" means exactly the H5 pointer-target list
(`pointer_targets.json`, class `session-wrapup`), checked against
*actual transcript events* — not a raw substring search, which would
false-positive on the CLAUDE.md text quoted into every transcript (the
H2 lesson: block/nudge only on positive confirmation):

  - a `Skill` tool_use with skill == "session-wrapup"
  - a `Read` tool_use whose file_path ends with
    modules/git-flow-session-end/index.md or session-wrapup/SKILL.md
    (covers both `skills/` and vendored `.claude/skills/` layouts)
  - a user-typed `/session-wrapup` (a `<command-name>` block)

**Once per session** (marker file keyed on `session_id`), so a session
that creates several PRs is nudged only on the first. Fails OPEN: any
error → no output, exit 0, the tool call proceeds.

State: $WRAPUP_NUDGE_STATE_DIR/<session_id>.nudged
       (default: ~/.cache/agentic_metrics/wrapup-nudge/)
Disable for a session with WRAPUP_NUDGE_DISABLED=1.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

STATE_DIR = Path(
    os.environ.get(
        "WRAPUP_NUDGE_STATE_DIR",
        os.path.expanduser("~/.cache/agentic_metrics/wrapup-nudge"),
    )
)

_TRUTHY = {"1", "true", "yes", "on"}
DISABLED = os.environ.get("WRAPUP_NUDGE_DISABLED", "").lower() in _TRUTHY

# H5 pointer-target suffixes for the session-wrapup class. The SKILL.md
# suffix is layout-agnostic: matches skills/session-wrapup/SKILL.md and
# .claude/skills/session-wrapup/SKILL.md alike.
_READ_SUFFIXES = (
    "modules/git-flow-session-end/index.md",
    "session-wrapup/SKILL.md",
)
_SKILL_NAME = "session-wrapup"

NUDGE = (
    "No wrap-up surface has been loaded this session, and you are creating "
    "a PR. Before handing off, load the session-end loop — the "
    "/session-wrapup skill if this repo vendors it, else "
    "modules/git-flow-session-end/index.md — and run the steps you haven't "
    "done yet: docs synced to reality (CHANGELOG/roadmap/ledger), verify "
    "scripts run, the merge confirmed via an AskUserQuestion popup (not "
    "prose), post-merge cleanup, and the fixed-format Session end summary. "
    "(One-time per-session reminder; part of the git-flow-session-end "
    "module.)"
)


def _marker_path(session_id: str) -> Path:
    safe = "".join(c if c.isalnum() or c in "-_." else "_" for c in session_id)
    return STATE_DIR / f"{safe}.nudged"


def _mark_nudged(session_id: str) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    _marker_path(session_id).touch()


def _tool_use_blocks(entry: dict):
    """Yield tool_use content blocks from one transcript JSONL entry."""
    message = entry.get("message")
    if not isinstance(message, dict):
        return
    content = message.get("content")
    if not isinstance(content, list):
        return
    for block in content:
        if isinstance(block, dict) and block.get("type") == "tool_use":
            yield block


def _user_text(entry: dict) -> str:
    """Concatenated text of a user entry (for the <command-name> check)."""
    if entry.get("type") != "user":
        return ""
    message = entry.get("message")
    if not isinstance(message, dict):
        return ""
    content = message.get("content")
    if isinstance(content, str):
        return content
    parts = []
    if isinstance(content, list):
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text") or "")
    return "\n".join(parts)


def _wrapup_surface_loaded(transcript_path: str | None) -> bool:
    """True if any H5 session-wrapup target demonstrably loaded.

    Checks real transcript events only (tool_use blocks and user-typed
    slash commands); never a raw substring scan of the whole blob.
    Unreadable transcript → False (we'd rather nudge once than miss).
    """
    if not transcript_path:
        return False
    try:
        fh = open(transcript_path, "r", encoding="utf-8", errors="replace")
    except OSError:
        return False
    with fh:
        for line in fh:
            try:
                entry = json.loads(line)
            except (json.JSONDecodeError, ValueError):
                continue
            if not isinstance(entry, dict):
                continue
            for block in _tool_use_blocks(entry):
                name = block.get("name") or ""
                tool_input = block.get("input") or {}
                if not isinstance(tool_input, dict):
                    continue
                if name == "Skill" and tool_input.get("skill") == _SKILL_NAME:
                    return True
                if name == "Read":
                    path = tool_input.get("file_path") or ""
                    if path.endswith(_READ_SUFFIXES):
                        return True
            text = _user_text(entry)
            if "<command-name>" in text and _SKILL_NAME in text:
                return True
    return False


def decide(payload: dict) -> str | None:
    """Return the nudge to inject, or None. Marks the session on fire."""
    if payload.get("tool_name") != "Bash":
        return None
    tool_input = payload.get("tool_input") or {}
    command = tool_input.get("command") or "" if isinstance(tool_input, dict) else ""
    if "gh pr create" not in command:
        return None

    session_id = payload.get("session_id") or "unknown"
    if _marker_path(session_id).exists():
        return None
    if _wrapup_surface_loaded(payload.get("transcript_path")):
        return None

    _mark_nudged(session_id)
    return NUDGE


def main() -> int:
    if DISABLED:
        return 0

    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0  # malformed payload → fail open

    try:
        nudge = decide(payload)
    except Exception:
        return 0  # any unexpected error → fail open

    if nudge:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "additionalContext": nudge,
            }
        }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
