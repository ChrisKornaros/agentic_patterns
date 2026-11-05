#!/usr/bin/env bash
# check_links.sh — doc-integrity smoke for this repo's markdown cross-links.
#
# Converts the "verification is a manual readthrough" promise in CLAUDE.md
# into a runnable gate: scan every tracked *.md file, pull out each inline
# markdown link [label](target) (images included), and assert the relative
# targets actually resolve on disk. A broken cross-reference fails the run.
#
# What it checks:
#   - Relative links:  [x](../foo.md), [x](./bar/), [x](baz.md#anchor)
#     resolved against the *linking file's* directory.
#   - Directory targets (trailing slash) are checked as directories.
#   - Heading anchors into markdown, in-page ([x](#section)) or cross-file
#     ([x](baz.md#section)): the anchor must be a GitHub heading slug the
#     target defines (lowercase, punctuation dropped, each space -> `-`,
#     `-1`/`-2` suffixes on repeats) or an explicit <a id|name="..."> tag.
#     ATX headings only (`## Foo`); the repo has no setext ones.
#
# What it skips (by design):
#   - Absolute-URL links (http://, https://, mailto:, any scheme://).
#   - Anchors on non-markdown or directory targets, and GitHub line anchors
#     (#L42, #L10-L20) — only heading anchors are validated.
#   - Anything inside a fenced code block (``` / ~~~) or an inline `code span`
#     — those are illustrative, not real links.
#   - Reference-style definitions ([ref]: target) — none exist in this repo;
#     re-evaluate if that changes.
#   - Links from sources matched by scripts/check_links.ignore — intentional
#     exceptions (deploy-relative vendored skills, template placeholders).
#     Each ignore entry is documented in place.
#
# Out-of-repo links: a handful of links climb into the vault parent
# (e.g. ../../../requirements/, ../../../.env.example). This repo always lives
# inside Chris's vault (see root CLAUDE.md "Conventions"), so those resolve on
# disk and pass. Running this script outside the vault would flag them — that
# is not a supported context.
#
# Exit status: 0 if every relative link (and its anchor) resolves, 1 if any
# are broken.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

usage() {
    cat <<'USAGE'
Usage: scripts/check_links.sh

Scan every tracked *.md file and assert each relative markdown link resolves
on disk, and each #heading anchor into markdown names a real heading. Run it
before committing doc changes, or as a CI smoke. Prints the
broken links (if any) and a summary; exits non-zero when any link is broken.

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

# Load intentional exceptions. Each ignore line is "<source-glob>" or
# "<source-glob>\t<target-regex>": a link is skipped when its source file
# matches the glob and (if present) its target matches the regex. Blank lines
# and #-comments are ignored.
IGNORE_FILE="$SCRIPT_DIR/check_links.ignore"
ignore_globs=() ignore_regexes=()
if [[ -f "$IGNORE_FILE" ]]; then
    while IFS=$'\t' read -r glob regex || [[ -n "$glob" ]]; do
        [[ -z "$glob" || "$glob" == \#* ]] && continue
        ignore_globs+=("$glob")
        ignore_regexes+=("${regex:-}")
    done < "$IGNORE_FILE"
fi

# True if (file, target) matches any ignore entry.
is_ignored() {
    local file="$1" target="$2" i
    for i in "${!ignore_globs[@]}"; do
        # shellcheck disable=SC2053  # glob match is intentional, not literal
        if [[ "$file" == ${ignore_globs[$i]} ]]; then
            local re="${ignore_regexes[$i]}"
            if [[ -z "$re" || "$target" =~ $re ]]; then
                return 0
            fi
        fi
    done
    return 1
}

# Pull out links from a single markdown file. Emits "<lineno>US<target>US<anchor>"
# (US = \x1f, so an empty target survives `read`) per link, skipping fenced
# code blocks and inline code spans. The target capture stops at whitespace,
# ')', or '#', so titles are dropped; an empty target is an in-page anchor.
extract_links() {
    perl -ne '
        if (/^\s*(```|~~~)/) { $fence = !$fence; next }
        next if $fence;
        s/`[^`]*`//g;                       # drop inline code spans
        while (/\[[^\]]*\]\(\s*([^)\s#]*)(?:#([^)\s]*))?/g) {
            my ($target, $anchor) = ($1, $2 // "");
            print "$.\x1f$target\x1f$anchor\n" if length "$target$anchor";
        }
    ' "$1"
}

# Emit every anchor a markdown file defines, one per line: GitHub's slug of
# each ATX heading (github-slugger rules — the heading's rendered text,
# lowercased, minus everything but letters, marks, digits, `_`, `-` and
# spaces, each space -> `-`, repeats suffixed -1, -2, ...) plus any explicit
# <a id|name="..."> tag. Frontmatter and fenced code are skipped.
heading_slugs() {
    perl -CSD -ne '
        if ($. == 1 && /^---\s*$/) { $front = 1; next }
        if ($front) { $front = 0 if /^---\s*$/; next }
        if (/^\s*(```|~~~)/) { $fence = !$fence; next }
        next if $fence;
        print "$1\n" while /<a\s[^>]*?\b(?:id|name)="([^"]+)"/g;
        next unless /^ {0,3}#{1,6}\s+(.*\S)/;
        my $text = $1;
        $text =~ s/\s+#+$//;                         # closing ### sequence
        my @code;                                    # code spans render verbatim
        $text =~ s/`([^`]*)`/push @code, $1; "\0$#code\0"/ge;
        $text =~ s{</?[A-Za-z][A-Za-z0-9-]*(?:\s+[A-Za-z_:][\w.:-]*(?:\s*=\s*(?:[^\s"\x27=<>`]+|\x27[^\x27]*\x27|"[^"]*"))?)*\s*/?>}{}g;
        $text =~ s/!?\[([^\]]*)\]\([^)]*\)/$1/g;     # links render as their label
        # _emph_ / __strong__ delimiters vanish; intraword snake_case stays.
        $text =~ s/(?<![\p{L}\p{N}_])_+(?=\S)|(?<=\S)_+(?![\p{L}\p{N}_])//g;
        $text =~ s/\0(\d+)\0/$code[$1]/g;
        (my $slug = lc $text) =~ s/[^\p{L}\p{M}\p{N}\p{Pc} -]//g;
        $slug =~ tr/ /-/;
        my $base = $slug;
        $slug = "$base-" . ++$seen{$base} while exists $seen{$slug};
        $seen{$slug} = 0;
        print "$slug\n";
    ' "$1"
}

# True if markdown file $1 defines anchor $2. Slugs are cached per file in
# two parallel arrays: macOS ships bash 3.2, which has no associative arrays.
slug_files=() slug_lists=() slug_n=0
has_anchor() {
    local i
    for ((i = 0; i < slug_n; i++)); do
        if [[ "${slug_files[$i]}" == "$1" ]]; then break; fi
    done
    if ((i == slug_n)); then
        slug_files[$i]=$1
        slug_lists[$i]=$'\n'"$(heading_slugs "$1")"$'\n'
        slug_n=$((slug_n + 1))
    fi
    [[ "${slug_lists[$i]}" == *$'\n'"$2"$'\n'* ]]
}

broken=0 checked=0 anchors=0 files=0 ignored=0

while IFS= read -r file; do
    files=$((files + 1))
    dir=$(dirname "$file")

    while IFS=$'\x1f' read -r lineno target anchor; do
        # Skip absolute-URL schemes (http:, https:, mailto:, ...).
        [[ "$target" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*: ]] && continue

        if is_ignored "$file" "$target"; then
            ignored=$((ignored + 1))
            continue
        fi

        checked=$((checked + 1))

        # Resolve against the linking file's directory; the filesystem
        # collapses any ../ segments for us. No target = in-page anchor.
        if [[ -z "$target" ]]; then
            resolved="$file"
        elif [[ "$target" == /* ]]; then
            resolved="$target"
        else
            resolved="$dir/$target"
        fi

        if [[ ! -e "$resolved" ]]; then
            printf '  BROKEN  %s:%s -> %s\n' "$file" "$lineno" "$target"
            broken=$((broken + 1))
            continue
        fi

        # Heading anchors only: into a markdown file, not a GitHub line anchor.
        [[ -n "$anchor" && -f "$resolved" && "$resolved" == *.md ]] || continue
        [[ "$anchor" =~ ^L[0-9]+(-L[0-9]+)?$ ]] && continue
        anchors=$((anchors + 1))
        if ! has_anchor "$resolved" "$anchor"; then
            printf '  BROKEN  %s:%s -> %s#%s  (no such heading)\n' \
                "$file" "$lineno" "$target" "$anchor"
            broken=$((broken + 1))
        fi
    done < <(extract_links "$file")
done < <(git ls-files '*.md')

echo
if [[ $broken -eq 0 ]]; then
    printf 'ok: %d links (%d #anchors) checked across %d files, all resolve (%d ignored).\n' \
        "$checked" "$anchors" "$files" "$ignored"
    exit 0
fi
printf 'FAIL: %d broken link(s) of %d checked (%d #anchors) across %d files (%d ignored).\n' \
    "$broken" "$checked" "$anchors" "$files" "$ignored"
exit 1
