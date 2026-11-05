#!/bin/sh
# Install, check or remove the Clew prepare-commit-msg hook in repos.
#
#   tools/clew/install.sh <repo> [<repo> ...]
#   tools/clew/install.sh --check <repo> [<repo> ...]      # exit 1 if any is missing
#   tools/clew/install.sh --uninstall <repo> [<repo> ...]
#
# The hook goes into each repo's hooks directory (shared by its
# worktrees). An existing prepare-commit-msg hook is kept as
# prepare-commit-msg.pre-clew and runs first. Per machine: the hook
# lives in .git/, not in the repo, so run this on every machine that
# commits from Claude Code sessions.
set -eu

here="$(cd "$(dirname "$0")" && pwd)"
src="$here/prepare-commit-msg"

mode=install
case "${1:-}" in
    --check) mode=check; shift ;;
    --uninstall) mode=uninstall; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
esac
[ $# -gt 0 ] || { echo "usage: $0 [--check|--uninstall] <repo> [<repo> ...]" >&2; exit 2; }

rc=0
for repo in "$@"; do
    if ! hooks="$(git -C "$repo" rev-parse --path-format=absolute --git-path hooks 2>/dev/null)"; then
        echo "$repo: not a git repository" >&2
        rc=1
        continue
    fi
    dst="$hooks/prepare-commit-msg"
    case "$mode" in
        check)
            if [ -x "$dst" ] && grep -q "Clew" "$dst"; then
                echo "$repo: installed"
            elif [ -x "$dst.pre-entire" ] && grep -q "Clew" "$dst.pre-entire"; then
                echo "$repo: installed (chained under Entire's hook)"
            else
                echo "$repo: missing"
                rc=1
            fi
            ;;
        uninstall)
            if [ -f "$dst" ] && grep -q "Clew" "$dst"; then
                rm -f "$dst"
                if [ -f "$dst.pre-clew" ]; then
                    mv "$dst.pre-clew" "$dst"
                    echo "$repo: removed; previous hook restored"
                else
                    echo "$repo: removed"
                fi
            elif [ -f "$dst.pre-entire" ] && grep -q "Clew" "$dst.pre-entire"; then
                rm -f "$dst.pre-entire"
                echo "$repo: removed from under Entire's hook"
            else
                echo "$repo: nothing to remove"
            fi
            ;;
        install)
            mkdir -p "$hooks"
            if [ -f "$dst.pre-entire" ] && grep -q "Clew" "$dst.pre-entire"; then
                echo "$repo: already installed (chained under Entire's hook)"
                continue
            fi
            if [ -f "$dst" ] && ! grep -q "Clew" "$dst"; then
                mv "$dst" "$dst.pre-clew"
                echo "$repo: existing hook kept as prepare-commit-msg.pre-clew"
            fi
            cp "$src" "$dst"
            chmod +x "$dst"
            echo "$repo: installed"
            ;;
    esac
done
exit $rc
