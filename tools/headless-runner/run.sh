#!/usr/bin/env bash
# headless-runner — one `claude -p` job in its own worktree, its result in the warehouse.
#
#   tools/headless-runner/run.sh --repo <checkout> [options] -- <prompt>
#   tools/headless-runner/run.sh --repo <checkout> --prompt-file <file> [options]
#
# What one run does, in order:
#   1. names the job (hr-<utc stamp>-<4 hex>) and makes sure the repo's
#      .git/info/exclude hides .claude/worktrees/;
#   2. scrubs the launching environment (CLAUDE*, AI_AGENT, VSCODE_*,
#      TERM_PROGRAM*) so the child is a plain CLI session, not a child of
#      the editor it was started from, and records entrypoint 'sdk-cli';
#   3. runs `claude -p --worktree <job> --output-format json …` from the
#      repo root, prompt on stdin, stdout to <out-dir>/<job>.result.json;
#   4. reads the worktree back: branch, head, commits ahead of base, and
#      whether the head reached a remote; writes the envelope
#      <out-dir>/<job>.json = {"job": {...}, "result": {...}};
#   5. imports the envelope with `warehouse headless-import` (the envelope
#      stays on disk either way; `--dir` re-imports later);
#   6. unlocks and removes the worktree. The worktree-<job> branch is
#      deleted only when it has no commits of its own or its head is on a
#      remote; unpushed work stays on the branch and is reported. Any
#      other branch the agent created is left alone and named.
#
# Options
#   --repo <path>              the git checkout to run in (required)
#   --prompt-file <file>       read the prompt from a file (else after --)
#   --name <job>               job name instead of hr-<stamp>-<hex>
#   --model <model>            passed to claude --model
#   --max-budget-usd <usd>     passed to claude --max-budget-usd
#   --permission-mode <mode>   claude --permission-mode (default acceptEdits)
#   --allowed-tools <list>     extra claude --allowedTools patterns, comma-separated
#   --no-repo-allow            don't pass the repo's own permissions.allow list
#   --out-dir <dir>            envelopes (default ~/.cache/agentic_metrics/headless)
#   --open-pr                  after the run, push the branch the worktree
#                              ended on (if it has commits of its own and is
#                              not on a remote) and open a PR on it with
#                              `gh`, body = the agent's final report, the
#                              `gh` user assigned so it shows at github.com/pulls
#   --keep-worktree            leave the worktree in place
#   --no-import                skip the warehouse import
#   --                         everything after is the prompt
#
# Permissions: a headless session treats the repo as untrusted unless its
# path has hasTrustDialogAccepted in ~/.claude.json, and then ignores every
# permissions.allow entry in the repo's .claude/settings.json (observed
# 2026-11-04: 60 entries ignored, 28 refusals in one run). So the runner
# reads that allow list itself and passes each pattern as its own
# --allowedTools argument, plus anything in --allowed-tools. Deny rules
# still apply on their own. A pattern in permissions.ask is answered "no"
# in a headless session whatever --allowedTools says (PUT asks on every
# `git push`), which is why the push and the PR are a runner step,
# --open-pr, not something the agent is asked to do.
#
# Environment: WAREHOUSE_DIR (default <this repo>/metrics/warehouse),
# WAREHOUSE_PG_HOST (else ~/.config/agentic_metrics/warehouse.env, as the
# Stop hook reads it), HEADLESS_OUT_DIR. Exit code: claude's, or 2 for a
# usage error, or 3 when claude could not start.

set -u

usage() { sed -n '2,44p' "$0" | sed 's/^# \{0,1\}//'; }

REPO=""; PROMPT_FILE=""; JOB=""; MODEL=""; BUDGET=""; PERM_MODE="acceptEdits"
ALLOWED=""; OUT_DIR="${HEADLESS_OUT_DIR:-$HOME/.cache/agentic_metrics/headless}"
KEEP=0; NO_IMPORT=0; PROMPT=""; REPO_ALLOW=1; OPEN_PR=0

while [ $# -gt 0 ]; do
    case "$1" in
        --repo) REPO="$2"; shift 2 ;;
        --prompt-file) PROMPT_FILE="$2"; shift 2 ;;
        --name) JOB="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --max-budget-usd) BUDGET="$2"; shift 2 ;;
        --permission-mode) PERM_MODE="$2"; shift 2 ;;
        --allowed-tools) ALLOWED="$2"; shift 2 ;;
        --out-dir) OUT_DIR="$2"; shift 2 ;;
        --keep-worktree) KEEP=1; shift ;;
        --open-pr) OPEN_PR=1; shift ;;
        --no-import) NO_IMPORT=1; shift ;;
        --no-repo-allow) REPO_ALLOW=0; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; PROMPT="$*"; break ;;
        *) echo "run.sh: unknown option $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [ -n "$PROMPT_FILE" ]; then
    [ -r "$PROMPT_FILE" ] || { echo "run.sh: cannot read $PROMPT_FILE" >&2; exit 2; }
    PROMPT="$(cat "$PROMPT_FILE")"
fi
[ -n "$REPO" ] || { echo "run.sh: --repo is required" >&2; exit 2; }
[ -n "$PROMPT" ] || { echo "run.sh: no prompt (use --prompt-file or -- <prompt>)" >&2; exit 2; }
command -v claude >/dev/null 2>&1 || { echo "run.sh: claude not on PATH" >&2; exit 3; }

REPO="$(cd "$REPO" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)" \
    || { echo "run.sh: --repo is not a git checkout" >&2; exit 2; }
REPO_NAME="$(basename "$REPO")"
GIT_COMMON="$(git -C "$REPO" rev-parse --git-common-dir)"
case "$GIT_COMMON" in /*) ;; *) GIT_COMMON="$REPO/$GIT_COMMON" ;; esac

_here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
WAREHOUSE_DIR="${WAREHOUSE_DIR:-$(cd "$_here/../../metrics/warehouse" 2>/dev/null && pwd)}"
_env_file="${WAREHOUSE_ENV_FILE:-$HOME/.config/agentic_metrics/warehouse.env}"
if [ -z "${WAREHOUSE_PG_HOST:-}" ] && [ -r "$_env_file" ]; then
    # shellcheck disable=SC1090
    . "$_env_file"
fi

if [ -z "$JOB" ]; then
    _hex="$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')"
    JOB="hr-$(date -u +%Y%m%dT%H%M%SZ)-${_hex}"
fi
case "$JOB" in *[!A-Za-z0-9._-]*) echo "run.sh: job name may use [A-Za-z0-9._-] only" >&2; exit 2 ;; esac

mkdir -p "$OUT_DIR"
RESULT_FILE="$OUT_DIR/$JOB.result.json"
ERR_FILE="$OUT_DIR/$JOB.err"
ENVELOPE="$OUT_DIR/$JOB.json"
PROMPT_SHA="$(printf '%s' "$PROMPT" | shasum -a 256 | cut -d' ' -f1)"
PROMPT_FILE_OUT="$OUT_DIR/$JOB.prompt.txt"
printf '%s' "$PROMPT" > "$PROMPT_FILE_OUT"

# Keep the main checkout's `git status` clean: worktrees live under
# .claude/worktrees/, which Claude Code does not add to the exclude file.
_exclude="$GIT_COMMON/info/exclude"
mkdir -p "$(dirname "$_exclude")"
grep -qxF '.claude/worktrees/' "$_exclude" 2>/dev/null || echo '.claude/worktrees/' >> "$_exclude"

BASE_BRANCH="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
BASE_SHA="$(git -C "$REPO" rev-parse HEAD)"
STARTED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# The scrub: every variable the launching Claude Code or editor set.
# Without it the child records the editor's entrypoint ('claude-vscode')
# and runs as a child session of this one.
SCRUB=""
for _v in $(env | grep -oE '^(CLAUDE[A-Za-z0-9_]*|AI_AGENT|VSCODE_[A-Za-z0-9_]*|TERM_PROGRAM[A-Za-z0-9_]*)=' | tr -d '='); do
    SCRUB="$SCRUB -u $_v"
done

set -- -p --worktree "$JOB" --output-format json --permission-mode "$PERM_MODE"
[ -n "$MODEL" ]   && set -- "$@" --model "$MODEL"
[ -n "$BUDGET" ]  && set -- "$@" --max-budget-usd "$BUDGET"
# One --allowedTools argument per pattern: the repo's own allow list (the
# headless session won't read it, see the header) and then --allowed-tools.
ALLOW_FILE="$REPO/.claude/settings.json"
if [ "$REPO_ALLOW" -eq 1 ] && [ -r "$ALLOW_FILE" ]; then
    while IFS= read -r _pat; do
        [ -n "$_pat" ] && set -- "$@" --allowedTools "$_pat"
    done <<EOF_ALLOW
$(python3 -c 'import json,sys
try:
    for p in json.load(open(sys.argv[1])).get("permissions", {}).get("allow", []): print(p)
except Exception: pass' "$ALLOW_FILE")
EOF_ALLOW
fi
if [ -n "$ALLOWED" ]; then
    _old_ifs="$IFS"; IFS=','
    for _pat in $ALLOWED; do
        _pat="$(printf '%s' "$_pat" | sed 's/^ *//;s/ *$//')"
        [ -n "$_pat" ] && set -- "$@" --allowedTools "$_pat"
    done
    IFS="$_old_ifs"
fi

echo "headless-runner: job $JOB in $REPO ($BASE_BRANCH @ ${BASE_SHA:0:7})"
# shellcheck disable=SC2086
( cd "$REPO" && printf '%s' "$PROMPT" | env $SCRUB claude "$@" ) > "$RESULT_FILE" 2> "$ERR_FILE"
EXIT=$?
FINISHED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Read the worktree back before anything is removed.
WT="$REPO/.claude/worktrees/$JOB"
WT_BRANCH=""; HEAD_SHA=""; COMMITS=0; PUSHED=false; PUSHED_BRANCH=""; OTHER_BRANCHES=""
if [ -d "$WT" ]; then
    WT_BRANCH="$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
    HEAD_SHA="$(git -C "$WT" rev-parse HEAD 2>/dev/null || true)"
    if [ -n "$HEAD_SHA" ]; then
        COMMITS="$(git -C "$WT" rev-list --count "$BASE_SHA..$HEAD_SHA" 2>/dev/null || echo 0)"
        git -C "$REPO" fetch -q --all 2>/dev/null || true
        PUSHED_BRANCH="$(git -C "$REPO" branch -r --contains "$HEAD_SHA" 2>/dev/null | head -1 | sed 's/^[ *]*//')"
        if [ "$COMMITS" -gt 0 ] && [ -n "$PUSHED_BRANCH" ]; then PUSHED=true; else PUSHED_BRANCH=""; fi
    fi
    OTHER_BRANCHES="$(git -C "$REPO" for-each-ref --format='%(refname:short)' refs/heads \
        --contains "$BASE_SHA" 2>/dev/null | grep -vxF -e "$BASE_BRANCH" -e "worktree-$JOB" | tr '\n' ' ' | sed 's/ $//')"
fi

PR_URL=""; PR_ERROR=""
if [ "$OPEN_PR" -eq 1 ] && [ -d "$WT" ] && [ "$COMMITS" -gt 0 ] && [ "$PUSHED" = false ] \
   && [ -n "$WT_BRANCH" ] && [ "$WT_BRANCH" != "HEAD" ]; then
    if git -C "$WT" push -u origin "$WT_BRANCH" >> "$ERR_FILE" 2>&1; then
        PUSHED=true; PUSHED_BRANCH="origin/$WT_BRANCH"
        echo "headless-runner: pushed $WT_BRANCH"
        _title="$(git -C "$WT" log -1 --format=%s)"
        _body="$OUT_DIR/$JOB.pr-body.md"
        python3 - "$RESULT_FILE" "$_body" "$JOB" <<'PYBODY'
import json, sys
from pathlib import Path
result_file, body_file, job = sys.argv[1:]
try:
    text = (json.loads(Path(result_file).read_text(encoding="utf-8")).get("result") or "").strip()
except Exception:
    text = ""
footer = (f"\n\n---\nOpened by the headless runner for job `{job}` "
          "(tools/headless-runner in agentic_optimization_research). The body above is the agent's final report.\n\n"
          "🤖 Generated with [Claude Code](https://claude.com/claude-code)\n")
Path(body_file).write_text((text or "(the agent left no report)") + footer, encoding="utf-8")
PYBODY
        if command -v gh >/dev/null 2>&1; then
            if PR_URL="$(git -C "$WT" rev-parse --show-toplevel >/dev/null && cd "$WT" && gh pr create --base "$BASE_BRANCH" --head "$WT_BRANCH" --title "$_title" --body-file "$_body" --assignee @me 2>>"$ERR_FILE")"; then
                echo "headless-runner: PR $PR_URL"
            else
                PR_URL=""; PR_ERROR="gh pr create failed (see $ERR_FILE)"; echo "headless-runner: $PR_ERROR" >&2
            fi
        else
            PR_ERROR="gh not on PATH; branch pushed, no PR"; echo "headless-runner: $PR_ERROR" >&2
        fi
    else
        PR_ERROR="push failed (see $ERR_FILE)"; echo "headless-runner: $PR_ERROR" >&2
    fi
elif [ "$OPEN_PR" -eq 1 ]; then
    echo "headless-runner: --open-pr: nothing to push (commits=$COMMITS pushed=$PUSHED branch=${WT_BRANCH:-none})"
fi

python3 - "$ENVELOPE" "$RESULT_FILE" "$ERR_FILE" "$PROMPT_FILE_OUT" <<'PY' \
    "$JOB" "$REPO_NAME" "$REPO" "$BASE_BRANCH" "$BASE_SHA" "$WT_BRANCH" "$HEAD_SHA" \
    "$COMMITS" "$PUSHED" "$PUSHED_BRANCH" "$OTHER_BRANCHES" "$STARTED_AT" "$FINISHED_AT" \
    "$EXIT" "$MODEL" "$PERM_MODE" "$ALLOWED" "$PROMPT_SHA" "$(hostname -s)" "$PR_URL" "$PR_ERROR"
import json, sys
from pathlib import Path
(envelope, result_file, err_file, prompt_file, job, repo, repo_path, base_branch, base_sha,
 wt_branch, head_sha, commits, pushed, pushed_branch, other, started, finished,
 exit_code, model, perm, allowed, prompt_sha, host, pr_url, pr_error) = sys.argv[1:]
try:
    result = json.loads(Path(result_file).read_text(encoding="utf-8"))
    if not isinstance(result, dict):
        result = {"raw": result}
except Exception as e:
    result = None
err = Path(err_file).read_text(encoding="utf-8", errors="replace")[-4000:] if Path(err_file).exists() else ""
prompt = Path(prompt_file).read_text(encoding="utf-8")
meta = {
    "job": job, "repo": repo, "repo_path": repo_path, "host": host,
    "base_branch": base_branch, "base_sha": base_sha,
    "worktree_branch": wt_branch or None, "head_sha": head_sha or None,
    "commits": int(commits or 0), "pushed": pushed == "true",
    "pushed_branch": pushed_branch or None,
    "other_branches": other.split() if other else [],
    "started_at": started, "finished_at": finished, "exit_code": int(exit_code),
    "model": model or None, "permission_mode": perm, "allowed_tools": allowed or None,
    "prompt": prompt, "prompt_sha256": prompt_sha, "stderr_tail": err or None,
    "pr_url": pr_url or None, "pr_error": pr_error or None,
    "runner": "tools/headless-runner/run.sh",
}
Path(envelope).write_text(json.dumps({"job": meta, "result": result}, indent=2) + "\n", encoding="utf-8")
r = result or {}
cost = r.get("total_cost_usd")
print(f"headless-runner: exit={exit_code} session={r.get('session_id')} turns={r.get('num_turns')} "
      f"cost={'-' if cost is None else f'{cost:.4f}'} error={r.get('is_error', result is None)} "
      f"commits={commits} pushed={pushed} branch={wt_branch or '-'}")
denials = r.get("permission_denials") or []
if denials:
    print(f"headless-runner: {len(denials)} permission denial(s): " + "; ".join(
        f"{d.get('tool_name')}({str(d.get('tool_input', ''))[:60]})" for d in denials[:5]))
text = (r.get("result") or "").strip().replace("\n", " ")
if text:
    print("headless-runner: result: " + text[:240] + ("…" if len(text) > 240 else ""))
if result is None:
    print("headless-runner: no JSON result; stderr tail follows", file=sys.stderr)
    print(err[-800:], file=sys.stderr)
PY
echo "headless-runner: envelope $ENVELOPE"

if [ "$NO_IMPORT" -eq 0 ]; then
    if [ -n "$WAREHOUSE_DIR" ] && [ -d "$WAREHOUSE_DIR" ]; then
        if ! uv run --project "$WAREHOUSE_DIR" warehouse headless-import --result "$ENVELOPE" --timeout 10; then
            echo "headless-runner: import failed; re-import later with: uv run --project $WAREHOUSE_DIR warehouse headless-import --dir $OUT_DIR" >&2
        fi
    else
        echo "headless-runner: WAREHOUSE_DIR not found; envelope kept for --dir import" >&2
    fi
fi

if [ "$KEEP" -eq 0 ] && [ -d "$WT" ]; then
    git -C "$REPO" worktree unlock "$WT" >/dev/null 2>&1 || true
    if git -C "$REPO" worktree remove --force "$WT" >/dev/null 2>&1; then
        echo "headless-runner: worktree removed"
    else
        echo "headless-runner: could not remove $WT" >&2
    fi
    if git -C "$REPO" show-ref --verify -q "refs/heads/worktree-$JOB"; then
        _wt_head="$(git -C "$REPO" rev-parse "worktree-$JOB")"
        _ahead="$(git -C "$REPO" rev-list --count "$BASE_SHA..$_wt_head")"
        if [ "$_ahead" -eq 0 ] || git -C "$REPO" branch -r --contains "$_wt_head" 2>/dev/null | grep -q .; then
            git -C "$REPO" branch -D "worktree-$JOB" >/dev/null 2>&1 && echo "headless-runner: branch worktree-$JOB deleted"
        else
            echo "headless-runner: $_ahead unpushed commit(s) kept on branch worktree-$JOB"
        fi
    fi
    [ -n "$OTHER_BRANCHES" ] && echo "headless-runner: other local branch(es) from this base, left alone: $OTHER_BRANCHES"
fi

exit "$EXIT"
