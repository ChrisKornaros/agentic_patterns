#!/usr/bin/env python3
"""Stop hook — session-end workflow guard.

Vendored companion for the `git-flow-session-end` module. It fires when the
agent tries to *end a turn* and nudges it back onto the session-end loop in
the two objective, high-value states the loop most often gets dropped in:

  1. **PR merged, cleanup skipped.** A PR for a branch is MERGED but the
     agent is still sitting on the feature branch. → reminds it to verify,
     sync `main`, delete the branch, and print the Session end summary.
  2. **Hand-off without the popup.** A PR for a branch is OPEN and that
     repo's working tree is clean + fully pushed (the hand-off point). →
     reminds it to confirm the merge via an `AskUserQuestion` popup rather
     than ending the turn in prose.

**Cross-repo aware.** The check runs against *every git repo the session
actually touched* — not just `cwd`. The candidate set is `cwd` plus every
repo reached via a `cd <dir>` or `git -C <dir>` in the transcript's Bash
calls (resolved to their toplevel, deduped). This closes the blind spot
where a session rooted in repo A (sitting on a clean `main`) does its
branch+PR work in repo B: the cwd-only check saw A's clean `main` and
allowed the stop, so the hand-off/cleanup nudge never fired.

Everything else allows the stop. The guard is conservative on purpose, so
it adds no friction to ordinary turns:

  - Per repo, does nothing on the default branch, a detached HEAD, outside a
    git repo, or on a branch with no pushed counterpart (early WIP).
  - Does NOT call `gh` for a repo while it has uncommitted or unpushed
    changes — you're still working there — so it adds zero latency to
    mid-work stops. A `gh pr view` happens only for a repo that is clean and
    synced, i.e. at the moments a hand-off/cleanup is actually due.
  - Fails OPEN: any error (no `gh`, no network, malformed payload, an
    unreadable transcript, an exception) allows the stop. A guard that
    blocks a session on its own bug is worse than a missed nudge.
  - Honors `stop_hook_active`: once it has nudged within a continuation it
    steps aside, so it can never loop. Each fresh user turn re-arms it.

Disable for a session with SESSION_END_GUARD_DISABLED=1.

Stop-hook contract: reads the payload JSON on stdin; emits
`{"decision":"block","reason":...}` on stdout (exit 0) to nudge, or nothing
(exit 0) to allow.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys

# Cap how many distinct repos we probe per stop, to bound latency in the
# (rare) case a session hopped across many repos.
_MAX_REPOS = 8

# `cd <dir>` or `git -C <dir>` targets in a shell command — quoted or bare.
_DIR_RE = re.compile(
    r"""(?:\bcd|\bgit\s+-C)\s+            # cd / git -C
        (?:"([^"]+)"|'([^']+)'|([^\s;&|]+))  # "quoted" | 'quoted' | bare
    """,
    re.VERBOSE,
)


_TRUTHY = {"1", "true", "yes", "on"}
DISABLED = os.environ.get("SESSION_END_GUARD_DISABLED", "").lower() in _TRUTHY


def _allow() -> None:
    """Permit the stop: no output, exit 0."""
    sys.exit(0)


def _block(reason: str) -> None:
    """Nudge the agent to continue, with `reason` fed back to the model."""
    json.dump({"decision": "block", "reason": reason}, sys.stdout)
    sys.exit(0)


def _git(repo: str, *args: str) -> str | None:
    """Run a git command in `repo`; return stripped stdout, or None on failure."""
    try:
        out = subprocess.run(
            ["git", "-C", repo, *args],
            capture_output=True, text=True, timeout=5,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    return out.stdout.strip() if out.returncode == 0 else None


def _default_branch(repo: str) -> str:
    """Best-effort default-branch name (main/master), via origin/HEAD."""
    ref = _git(repo, "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD")
    if ref:
        return ref.rsplit("/", 1)[-1]  # refs/remotes/origin/main -> main
    for name in ("main", "master"):
        if _git(repo, "rev-parse", "--verify", "--quiet",
                f"refs/remotes/origin/{name}") is not None:
            return name
    return "main"


def _gh_pr(repo: str, branch: str):
    """Return (state, number, url) for the branch's PR, or None on any failure."""
    try:
        out = subprocess.run(
            ["gh", "pr", "view", branch, "--json", "state,number,url"],
            capture_output=True, text=True, timeout=10, cwd=repo,
        )
    except (OSError, subprocess.SubprocessError):
        return None
    if out.returncode != 0:
        return None
    try:
        data = json.loads(out.stdout)
    except (json.JSONDecodeError, ValueError):
        return None
    return data.get("state"), data.get("number"), data.get("url")


def _toplevel(path: str) -> str | None:
    """Resolve `path` to its git worktree toplevel, or None if not a repo."""
    if not path:
        return None
    expanded = os.path.expanduser(os.path.expandvars(path))
    return _git(expanded, "rev-parse", "--show-toplevel")


def _transcript_dirs(transcript_path: str | None) -> list[str]:
    """Extract `cd`/`git -C` target dirs from the transcript's Bash calls.

    Best-effort and fail-open: an unreadable or malformed transcript yields
    no extra candidates (the cwd check still runs). Order-preserving so the
    nearest-in-time repos are probed first under the _MAX_REPOS cap.
    """
    if not transcript_path:
        return []
    try:
        with open(transcript_path, "r", encoding="utf-8", errors="replace") as fh:
            blob = fh.read()
    except OSError:
        return []
    seen: dict[str, None] = {}
    for m in _DIR_RE.finditer(blob):
        target = m.group(1) or m.group(2) or m.group(3)
        if target and target not in seen:
            seen[target] = None
    return list(seen)


def _candidate_repos(payload: dict) -> list[str]:
    """Every git repo this session plausibly touched: cwd + transcript dirs.

    Returns deduped worktree toplevels, capped at _MAX_REPOS.
    """
    raw = [payload.get("cwd") or os.getcwd()]
    raw.extend(_transcript_dirs(payload.get("transcript_path")))
    repos: dict[str, None] = {}
    for path in raw:
        top = _toplevel(path)
        if top and top not in repos:
            repos[top] = None
            if len(repos) >= _MAX_REPOS:
                break
    return list(repos)


def _check_repo(repo: str) -> str | None:
    """Return a nudge reason for `repo`, or None if it's in a fine state."""
    if _git(repo, "rev-parse", "--is-inside-work-tree") != "true":
        return None

    branch = _git(repo, "rev-parse", "--abbrev-ref", "HEAD")
    if not branch or branch == "HEAD":  # no branch / detached HEAD
        return None

    default = _default_branch(repo)
    if branch == default:
        return None

    # A PR can only exist once the branch is pushed; skip early WIP.
    if _git(repo, "rev-parse", "--verify", "--quiet",
            f"refs/remotes/origin/{branch}") is None:
        return None

    # Still actively working (uncommitted or unpushed) — don't call gh, don't nag.
    dirty = bool(_git(repo, "status", "--porcelain"))
    ahead = _git(repo, "rev-list", "--count", f"origin/{branch}..HEAD")
    ahead_n = int(ahead) if (ahead and ahead.isdigit()) else 0
    if dirty or ahead_n > 0:
        return None

    pr = _gh_pr(repo, branch)
    if not pr:
        return None
    state, number, url = pr
    where = os.path.basename(repo)

    if state == "MERGED":
        return (
            f"PR #{number} ({branch}) in `{where}` is MERGED but the "
            f"session-end cleanup hasn't run. Per the git-flow-session-end "
            f"loop: verify with `gh pr view {number} --json state,mergedAt`, "
            f"then `git -C {repo} switch {default} && "
            f"git -C {repo} pull --ff-only && git -C {repo} branch -d {branch} "
            f"&& git -C {repo} fetch --prune`, and print the fixed-format "
            f"Session end summary. If you already did this, you may stop."
        )

    if state == "OPEN":
        return (
            f"PR #{number} in `{where}` is open and unmerged ({url}); that "
            f"repo's tree is clean and pushed, so this is the hand-off point. "
            f"Per the git-flow-session-end loop, confirm the merge with an "
            f"AskUserQuestion popup (Merged / Not yet / Changes requested) "
            f"instead of ending the turn in prose. If the human has explicitly "
            f"deferred the merge, acknowledge that and you may stop."
        )

    return None


def main() -> None:
    if DISABLED:
        _allow()

    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        _allow()

    # Already nudged once this continuation — step aside so we never loop.
    if payload.get("stop_hook_active"):
        _allow()

    # Check every repo the session touched; block on the first one that's
    # at a hand-off/cleanup point. (cwd is checked first.)
    for repo in _candidate_repos(payload):
        reason = _check_repo(repo)
        if reason:
            _block(reason)

    _allow()


if __name__ == "__main__":
    main()
