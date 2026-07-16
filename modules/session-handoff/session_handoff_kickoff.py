#!/usr/bin/env python3
"""SessionStart hook — surface the session-handoff kickoff into context.

Vendored companion for the `session-handoff` module. It fires at session
start and, if a committed `.claude/next-session.md` exists (the
roadmap-grounded kickoff the previous session's session-handoff step wrote),
injects its contents into the new session's opening context. This makes the
*read* side of the handoff mechanical rather than agent-honored — the same
upgrade git-flow-session-end's Stop hook is to *its* prompt.

It is deliberately inert when there's nothing to surface, so it adds no noise
to an ordinary cold start:

  - No-op (no output) when `.claude/next-session.md` is absent, so it's safe
    to wire before any handoff has ever been written.
  - Fails OPEN: any error (bad payload, unreadable file, an exception) simply
    surfaces no context. A SessionStart hook that crashes on its own bug
    shouldn't be able to wedge a session.

Disable for a session with SESSION_HANDOFF_KICKOFF_DISABLED=1.

SessionStart-hook contract: reads the payload JSON on stdin; emits
`{"hookSpecificOutput": {"hookEventName": "SessionStart",
"additionalContext": ...}}` on stdout (exit 0) to inject context, or nothing
(exit 0) to add none.
"""
from __future__ import annotations

import json
import os
import sys


_TRUTHY = {"1", "true", "yes", "on"}
DISABLED = os.environ.get("SESSION_HANDOFF_KICKOFF_DISABLED", "").lower() in _TRUTHY

HANDOFF_REL = os.path.join(".claude", "next-session.md")

_PREAMBLE = (
    "The previous session left this roadmap-grounded kickoff in "
    "`.claude/next-session.md` (written by the session-handoff module). "
    "Read it before planning. If the roadmap has since moved on, trust the "
    "roadmap over this file.\n\n"
)


def _emit(context: str) -> None:
    """Inject `context` into the new session, then exit."""
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": context,
            }
        },
        sys.stdout,
    )
    sys.exit(0)


def main() -> None:
    if DISABLED:
        sys.exit(0)

    # The payload carries `cwd`; read it best-effort but never depend on it.
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        payload = {}

    project_dir = (
        os.environ.get("CLAUDE_PROJECT_DIR")
        or payload.get("cwd")
        or os.getcwd()
    )
    handoff = os.path.join(project_dir, HANDOFF_REL)

    try:
        with open(handoff, "r", encoding="utf-8") as fh:
            body = fh.read().strip()
    except OSError:
        sys.exit(0)  # no handoff file → nothing to surface

    if not body:
        sys.exit(0)

    _emit(_PREAMBLE + body)


if __name__ == "__main__":
    main()
