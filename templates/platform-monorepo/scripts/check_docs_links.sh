#!/usr/bin/env bash
# check_docs_links.sh — the repo's "build": every relative markdown link
# in every tracked *.md file must resolve on disk, and every #heading
# anchor into a markdown file must name a real heading. Run before
# committing doc changes and in CI on every PR — a docs→wiki publish job
# should only ever run after this passes on the default branch.
#
# Checked:  [label](relative/path.md), [label](dir/) — resolved against
#           the linking file's directory.
#           [label](file.md#heading), [label](#heading) — the anchor must
#           be a heading slug the target defines, or an explicit
#           <a id="…"> / <a name="…"> tag in it.
# Skipped:  absolute URLs (any scheme:, mailto: included); line anchors
#           (#L42, #L10-L20); anchors on non-markdown targets; anything
#           inside a fenced code block or an inline `code span`.
#
# Slugs follow GitHub's rules: the heading's rendered text, lowercased,
# punctuation dropped, each space -> `-`, repeats suffixed -1, -2, ...
# Other hosts slug differently (GitLab, for one, collapses a run of
# hyphens into one). If yours does, adapt heading_slugs() below or run
# with --no-anchors. ATX headings only (`## Foo`), not setext.
#
# Needs bash 3.2+ and perl 5.
#
# Exit 0 when every relative link (and its anchor) resolves; 1 otherwise.
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

check_anchors=1
while [ $# -gt 0 ]; do
    case "$1" in
        --no-anchors) check_anchors=0 ;;
        -h|--help)
            echo "Usage: scripts/check_docs_links.sh [--no-anchors]"
            echo "  --no-anchors  check that link targets exist; skip #heading validation"
            exit 0 ;;
        *)  echo "check_docs_links: unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

if ! command -v perl >/dev/null 2>&1; then
    echo "check_docs_links: perl not found — install perl 5 to run this check." >&2
    exit 2
fi

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

# Pull out links from one markdown file. Emits "<lineno>US<target>US<anchor>"
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

# Emit every anchor a markdown file defines, one per line: the slug of each
# ATX heading plus any explicit <a id|name="..."> tag. Frontmatter and
# fenced code are skipped.
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
# two parallel arrays (bash 3.2 has no associative arrays).
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

broken=0
checked=0
anchors=0
while IFS= read -r f; do
    dir=$(dirname "$f")
    while IFS=$'\x1f' read -r lineno target anchor; do
        # Skip absolute-URL schemes (http:, https:, mailto:, ...).
        [[ "$target" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*: ]] && continue
        checked=$((checked + 1))

        # No target = in-page anchor, which resolves against the file itself.
        if [ -z "$target" ]; then
            resolved="$f"
        else
            resolved="$dir/$target"
        fi
        if [ ! -e "$resolved" ]; then
            echo "BROKEN: $f:$lineno -> $target"
            broken=$((broken + 1))
            continue
        fi

        # Heading anchors only: into a markdown file, not a line anchor.
        [ "$check_anchors" -eq 1 ] || continue
        [[ -n "$anchor" && -f "$resolved" && "$resolved" == *.md ]] || continue
        [[ "$anchor" =~ ^L[0-9]+(-L[0-9]+)?$ ]] && continue
        anchors=$((anchors + 1))
        if ! has_anchor "$resolved" "$anchor"; then
            echo "BROKEN: $f:$lineno -> $target#$anchor  (no such heading)"
            broken=$((broken + 1))
        fi
    done < <(extract_links "$f")
done <<< "$files"

echo "check_docs_links: $checked relative links checked ($anchors #anchors), $broken broken."
[ "$broken" -eq 0 ]
