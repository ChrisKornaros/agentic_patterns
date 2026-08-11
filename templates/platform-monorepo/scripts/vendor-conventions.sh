#!/usr/bin/env bash
# vendor-conventions.sh — copy convention texts + prompts from a local
# clone of https://github.com/ChrisKornaros/agentic_patterns into
# docs/conventions/, stamping a provenance header and pinning the source
# commit in CONVENTIONS.md.
#
# First run: writes docs/conventions/<name>.md directly.
# Re-run over existing files: local adaptation is expected, so the
# script never clobbers them — a changed upstream lands as
# <name>.md.new to diff and merge by hand (delete the .new when done).
# --force overwrites instead (only safe before you have adapted).
#
# Usage: scripts/vendor-conventions.sh [--source <path>] [--force]
#   --source <path>  Path to an agentic_patterns clone, checked out at
#                    the commit to vendor (default: $AGENTIC_PATTERNS_DIR)
#   --force          Overwrite existing files instead of writing .new
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEST_DIR="$REPO_ROOT/docs/conventions"
PROMPTS_DEST="$DEST_DIR/prompts"
MANIFEST="$DEST_DIR/vendor-manifest.txt"
LEDGER="$REPO_ROOT/CONVENTIONS.md"

SOURCE="${AGENTIC_PATTERNS_DIR:-}"
FORCE=0
while [ $# -gt 0 ]; do
    case "$1" in
        --source) SOURCE="${2:?--source needs a path}"; shift 2 ;;
        --force)  FORCE=1; shift ;;
        -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "vendor-conventions: unknown argument: $1" >&2; exit 2 ;;
    esac
done

fail() { echo "vendor-conventions: ERROR: $*" >&2; exit 1; }

[ -n "$SOURCE" ] || fail "no source clone given. Clone \
https://github.com/ChrisKornaros/agentic_patterns and pass \
--source <path> (or set AGENTIC_PATTERNS_DIR)."
[ -d "$SOURCE/modules" ] || fail "'$SOURCE' does not look like an agentic_patterns clone (no modules/)."
[ -f "$MANIFEST" ] || fail "manifest not found: $MANIFEST"

PIN=$(git -C "$SOURCE" rev-parse --short HEAD 2>/dev/null) \
    || fail "cannot read HEAD of '$SOURCE' — is it a git clone?"
if ! git -C "$SOURCE" diff --quiet 2>/dev/null; then
    echo "vendor-conventions: WARNING: source clone is dirty — pin $PIN may not match what you copy." >&2
fi
TODAY=$(date +%F)

# Manifest → array (comments / blanks stripped)
modules=()
while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [ -n "$line" ] || continue
    modules+=("$line")
done < "$MANIFEST"
[ "${#modules[@]}" -gt 0 ] || fail "manifest is empty."

mkdir -p "$DEST_DIR" "$PROMPTS_DEST"
new=0; to_merge=0; unchanged=0

# place <src-file> <dest-file> <provenance-rel-path>
# Compares bodies only (line 2 onward), so the dated header on an
# already-vendored copy doesn't force a spurious .new.
#
# Relative links written for the source repo's layout are rewritten for
# the flat docs/conventions/ layout here. Links to things this
# environment doesn't have (skills, hook/settings companion files) are
# left as-is on purpose — check_docs_links.sh flags them, and each flag
# is an adaptation to make by hand (usually: drop the sentence).
place() {
    local src=$1 dest=$2 rel=$3 tmp
    tmp=$(mktemp)
    printf '<!-- vendored from agentic_patterns/%s @ %s on %s — adapt in place; record rule-level deviations in CONVENTIONS.md -->\n' \
        "$rel" "$PIN" "$TODAY" > "$tmp"
    case "$dest" in
        */prompts/*)
            # prompt → module: ../modules/<name>/index.md → ../<name>.md
            sed -E 's|\]\(\.\./modules/([A-Za-z0-9_-]+)/index\.md|](../\1.md|g' \
                "$src" >> "$tmp" ;;
        *)
            # module → module: ../<name>/index.md → <name>.md
            # module → prompt: ../../prompts/<f>.md → prompts/<f>.md
            sed -E -e 's|\]\(\.\./([A-Za-z0-9_-]+)/index\.md|](\1.md|g' \
                   -e 's|\]\(\.\./\.\./prompts/|](prompts/|g' \
                "$src" >> "$tmp" ;;
    esac
    if [ ! -f "$dest" ] || [ "$FORCE" = 1 ]; then
        mv "$tmp" "$dest"
        new=$((new + 1)); echo "  new:     ${dest#"$REPO_ROOT"/}"
    elif cmp -s <(tail -n +2 "$tmp") <(tail -n +2 "$dest"); then
        rm -f "$tmp"
        unchanged=$((unchanged + 1))
    else
        mv "$tmp" "$dest.new"
        to_merge=$((to_merge + 1)); echo "  merge:   ${dest#"$REPO_ROOT"/}.new"
    fi
}

echo "vendor-conventions: source pin $PIN — ${#modules[@]} conventions + prompts"

for name in "${modules[@]}"; do
    src="$SOURCE/modules/$name/index.md"
    [ -f "$src" ] || fail "module '$name' not found at modules/$name/index.md in the source."
    place "$src" "$DEST_DIR/$name.md" "modules/$name/index.md"
done

for src in "$SOURCE"/prompts/*.md; do
    base=$(basename "$src")
    [ "$base" = "README.md" ] && continue
    place "$src" "$PROMPTS_DEST/$base" "prompts/$base"
done

# Dependency audit: a vendored convention that names an unvendored one
# needs either the dependency vendored too, or a substitution row in
# CONVENTIONS.md.
for name in "${modules[@]}"; do
    deps=$(awk '/^dependencies:/ {f=1; next} f && /^  - / {print $2; next} f {exit}' \
        "$SOURCE/modules/$name/index.md")
    for dep in $deps; do
        found=0
        for m in "${modules[@]}"; do
            [ "$m" = "$dep" ] && { found=1; break; }
        done
        [ "$found" = 1 ] || echo "  NOTE:    '$name' depends on '$dep' (not in manifest) — record the substitution in CONVENTIONS.md"
    done
done

# Refresh the ledger's pin line (the line tagged <!-- vendor-pin -->).
if [ -f "$LEDGER" ] && grep -q 'vendor-pin' "$LEDGER"; then
    sed -i.bak "s|^.*<!-- vendor-pin -->.*\$|All conventions under \`docs/conventions/\` are vendored from [agentic_patterns](https://github.com/ChrisKornaros/agentic_patterns) @ \`$PIN\` ($TODAY) and adapted for this environment. <!-- vendor-pin -->|" "$LEDGER"
    rm -f "$LEDGER.bak"
    echo "  pin:     CONVENTIONS.md → $PIN"
else
    echo "  NOTE:    no CONVENTIONS.md with a '<!-- vendor-pin -->' line found — copy CONVENTIONS.template.md first (pin is $PIN)."
fi

echo "vendor-conventions: done — $new written, $to_merge to merge, $unchanged unchanged."
if [ "$to_merge" -gt 0 ]; then
    echo "vendor-conventions: diff each .new against its neighbor, fold the upstream change into your adapted copy, delete the .new."
fi
echo "vendor-conventions: now run scripts/check_docs_links.sh — remaining broken links are source-layout references (skills, hook companions, unvendored conventions) to adapt or drop by hand."
