#!/usr/bin/env bash
# check_modules.sh — invariant smoke for the instruction modules.
#
# Converts the "manual checks" promise in modules/README.md §Verify into a
# runnable gate, alongside scripts/check_links.sh. For every module directory
# (modules/<name>/, excluding _-prefixed helper dirs like _spec), it asserts:
#
#   1. The directory has an index.md.
#   2. The frontmatter carries the required fields: name, type, scope,
#      lifecycle, version.
#   3. The `name:` value matches the directory name.
#   4. `lifecycle: stable` modules carry at least one `evidence:` entry.
#   5. Every `dependencies:` entry names a module that exists here.
#
# Exit status: 0 if every module passes, 1 if any assertion fails.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

usage() {
    cat <<'USAGE'
Usage: scripts/check_modules.sh

Assert every modules/<name>/index.md satisfies the frontmatter invariants
documented in modules/README.md §Verify. Run it before committing module
changes, or as a CI smoke. Prints each failure and a summary; exits non-zero
when any module is malformed.

Flags:
  -h, --help  This message.
USAGE
}

err() { printf 'error: %s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *)         err "unknown argument: $1"; usage >&2; exit 2 ;;
    esac
done

cd "$REPO_ROOT"

# Print the YAML frontmatter block (the lines between the opening and closing
# `---` fences). Empty output if the file doesn't open with a `---` fence.
frontmatter() {
    awk '
        NR==1 { if ($0 != "---") exit 0; infm=1; next }
        infm && /^---[[:space:]]*$/ { exit 0 }
        infm { print }
    ' "$1"
}

# Scalar value for a top-level key, quotes/whitespace trimmed. Empty if absent.
scalar() {
    sed -nE "s/^$2:[[:space:]]*//p" <<<"$1" | head -1 \
        | sed -E 's/^["'\'']//; s/["'\'']$//; s/[[:space:]]+$//'
}

# List items under a top-level YAML key (the `  - x` lines that follow it,
# stopping at the next unindented key). Empty for `key: []` or a missing key.
list_items() {
    awk -v key="$2" '
        $0 ~ "^" key ":" { inlist=1; next }
        inlist && /^[[:space:]]+-[[:space:]]*/ { sub(/^[[:space:]]+-[[:space:]]*/, ""); print; next }
        inlist && /^[^[:space:]#]/ { inlist=0 }
    ' <<<"$1"
}

fail=0 checked=0
report() { printf '  FAIL  %s: %s\n' "$1" "$2"; fail=$((fail + 1)); }

while IFS= read -r dir; do
    name=$(basename "$dir")
    [[ "$name" == _* ]] && continue   # _spec and other helper dirs aren't modules
    checked=$((checked + 1))

    index="$dir/index.md"
    if [[ ! -f "$index" ]]; then
        report "$name" "no index.md"
        continue
    fi

    fm=$(frontmatter "$index")
    if [[ -z "$fm" ]]; then
        report "$name" "index.md has no frontmatter block"
        continue
    fi

    for field in name type scope lifecycle version; do
        grep -qE "^$field:" <<<"$fm" || report "$name" "missing required field: $field"
    done

    nameval=$(scalar "$fm" name)
    [[ "$nameval" == "$name" ]] || report "$name" "name: '$nameval' != directory '$name'"

    if [[ "$(scalar "$fm" lifecycle)" == "stable" ]]; then
        [[ -n "$(list_items "$fm" evidence)" ]] || \
            report "$name" "lifecycle: stable but no evidence: entries"
    fi

    while IFS= read -r dep; do
        [[ -z "$dep" ]] && continue
        [[ -d "modules/$dep" ]] || report "$name" "dependency '$dep' is not a module here"
    done < <(list_items "$fm" dependencies)
done < <(find modules -mindepth 1 -maxdepth 1 -type d | sort)

echo
if [[ $fail -eq 0 ]]; then
    printf 'ok: %d modules checked, all invariants hold.\n' "$checked"
    exit 0
fi
printf 'FAIL: %d problem(s) across %d modules checked.\n' "$fail" "$checked"
exit 1
