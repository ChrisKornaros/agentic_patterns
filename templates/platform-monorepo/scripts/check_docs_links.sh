#!/usr/bin/env bash
# check_docs_links.sh — the repo's "build": every relative markdown link
# in every tracked *.md file must resolve on disk. Run before committing
# doc changes and in CI on every PR — a docs→wiki publish job should
# only ever run after this passes on the default branch.
#
# Checked:  [label](relative/path.md), [label](dir/), [label](file.md#anchor)
#           — resolved against the linking file's directory; the #anchor
#           part is stripped (heading anchors are not validated).
# Skipped:  absolute URLs (any scheme://, mailto:), pure in-page anchors
#           ([x](#section)).
# Known limitation: links inside fenced code blocks are NOT excluded —
# keep illustrative links in code blocks scheme-qualified (https://…)
# or expect them to be checked.
#
# Exit 0 when every relative link resolves; 1 otherwise.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_ROOT"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    files=$(git ls-files '*.md')
else
    files=$(find . -name '*.md' -not -path './.git/*' | sed 's|^\./||')
fi
if [ -z "$files" ]; then
    echo "check_docs_links: no markdown files yet — nothing to check."
    exit 0
fi

broken=0
checked=0
while IFS= read -r f; do
    dir=$(dirname "$f")
    while IFS= read -r target; do
        [ -n "$target" ] || continue
        rel="${target%%#*}"
        [ -n "$rel" ] || continue                      # pure #anchor
        case "$rel" in
            *://*|mailto:*) continue ;;                # external
        esac
        checked=$((checked + 1))
        if [ ! -e "$dir/$rel" ]; then
            echo "BROKEN: $f -> $target"
            broken=$((broken + 1))
        fi
    done < <(grep -o '\[[^]]*\]([^)]*)' "$f" 2>/dev/null \
             | sed 's/^.*](\([^)]*\))$/\1/' || true)
done <<< "$files"

echo "check_docs_links: $checked relative links checked, $broken broken."
[ "$broken" -eq 0 ]
