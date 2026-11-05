#!/usr/bin/env bash
# smoke.sh — the platform monorepo's verifier, for a person and for a
# runner job. Four steps, in the order a fresh copy of the template
# fails them:
#
#   1/4 contract   AGENTS.md and CONVENTIONS.md exist (not the
#                  .template files); CLAUDE.md, if present, includes
#                  AGENTS.md; .claude/settings.json, if present, parses.
#   2/4 fill-ins   no {{PLACEHOLDER}} left in the contract files or the
#                  settings; each one is named with its file and line.
#   3/4 links      scripts/check_docs_links.sh.
#   4/4 areas      every row of the Areas table in AGENTS.md names a
#                  directory that exists and a verify command that
#                  passes, run from the repo root.
#
# A fresh copy exits 2 at step 1 or 2 and says what to fill in. A real
# failure (a broken link, a failing area command) exits 1. Green is 0.
# Wire into CI on every PR beside the link check; a headless runner job
# runs it before it commits (smoke-before-commit).
#
# Needs bash 3.2+ (macOS ships it) and whatever check_docs_links.sh
# needs. JSON parsing uses jq or python3, whichever exists; neither
# present is a note, not a failure. SMOKE_SKIP_AREAS=1 skips step 4 for
# a docs-only change.

set -u

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_ROOT" || exit 1

fill_ins=0
failed=0
note()    { printf '  %s\n' "$*"; }
fillin()  { printf '  FILL IN  %s\n' "$*"; fill_ins=$((fill_ins + 1)); }
failure() { printf '  FAIL     %s\n' "$*"; failed=$((failed + 1)); }

# ---- 1/4 contract files --------------------------------------------
echo "smoke: 1/4 contract files"
for pair in "AGENTS.md:AGENTS.template.md" "CONVENTIONS.md:CONVENTIONS.template.md"; do
    want=${pair%%:*}; tmpl=${pair##*:}
    if [ -f "$want" ]; then
        note "ok   $want"
    elif [ -f "$tmpl" ]; then
        fillin "rename $tmpl to $want and fill its placeholders"
    else
        failure "$want is missing (and so is $tmpl)"
    fi
done

if [ -f CLAUDE.md ]; then
    if grep -q '^@AGENTS\.md[[:space:]]*$' CLAUDE.md; then
        note "ok   CLAUDE.md includes AGENTS.md"
    else
        failure "CLAUDE.md exists but has no '@AGENTS.md' include line; AGENTS.md is the contract, CLAUDE.md only includes it"
    fi
else
    note "none CLAUDE.md (fine without a Claude Code seat; the runtime layer adds it)"
fi

if [ -f .claude/settings.json ]; then
    if command -v jq >/dev/null 2>&1; then
        if jq -e . .claude/settings.json >/dev/null 2>&1; then
            note "ok   .claude/settings.json parses (jq)"
        else
            failure ".claude/settings.json is not valid JSON (jq)"
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if python3 -c 'import json,sys; json.load(open(sys.argv[1]))' .claude/settings.json 2>/dev/null; then
            note "ok   .claude/settings.json parses (python3)"
        else
            failure ".claude/settings.json is not valid JSON (python3)"
        fi
    else
        note "skip .claude/settings.json: neither jq nor python3 found to parse it"
    fi
    # Each hook script the settings name should either exist (vendored)
    # or be guarded fail-open; report which, so a missing module is a
    # known no-op rather than a surprise.
    grep -o '\$CLAUDE_PROJECT_DIR/modules/[^"]*\.py' .claude/settings.json 2>/dev/null \
        | sed 's|^\$CLAUDE_PROJECT_DIR/||' | sort -u | while IFS= read -r script; do
        if [ -f "$script" ]; then
            note "ok   hook script vendored: $script"
        else
            note "noop hook script not vendored yet (fail-open): $script"
        fi
    done
else
    note "none .claude/settings.json (fine without a Claude Code seat)"
fi

# ---- 2/4 placeholders ----------------------------------------------
echo "smoke: 2/4 placeholders"
ph_files=""
for f in AGENTS.md CONVENTIONS.md CLAUDE.md README.md .claude/settings.json; do
    [ -f "$f" ] && ph_files="$ph_files $f"
done
if [ -n "$ph_files" ]; then
    # shellcheck disable=SC2086
    hits=$(grep -n -o '{{[^}]*}}' $ph_files 2>/dev/null || true)
    if [ -n "$hits" ]; then
        printf '%s\n' "$hits" | while IFS= read -r line; do
            fillin "$line"
        done
        # the while ran in a subshell; count again in this one
        fill_ins=$((fill_ins + $(printf '%s\n' "$hits" | wc -l | tr -d ' ')))
    else
        note "ok   no {{placeholders}} left in:$ph_files"
    fi
fi

if [ "$fill_ins" -gt 0 ]; then
    echo "smoke: $fill_ins thing(s) to fill in before the rest can run (listed above as FILL IN)."
    exit 2
fi

# ---- 3/4 links -----------------------------------------------------
echo "smoke: 3/4 links"
if [ -x scripts/check_docs_links.sh ]; then
    if scripts/check_docs_links.sh; then
        note "ok   links resolve"
    else
        failure "scripts/check_docs_links.sh reported broken links (see above)"
    fi
else
    failure "scripts/check_docs_links.sh is missing or not executable"
fi

# ---- 4/4 areas -----------------------------------------------------
echo "smoke: 4/4 areas"
if [ "${SMOKE_SKIP_AREAS:-0}" = "1" ]; then
    note "skip SMOKE_SKIP_AREAS=1"
elif [ -f AGENTS.md ]; then
    # Rows of the table under '## Areas': | `dir/` | `dir/AGENTS.md` | `command` |
    rows=$(awk '
        /^## /       { in_areas = ($0 ~ /^## Areas/) ; next }
        in_areas && /^\|/ {
            if ($0 ~ /^\|[-| ]*$/) next          # separator row
            if (tolower($0) ~ /\| *area *\|/) next # header row
            print
        }' AGENTS.md)
    if [ -z "$rows" ]; then
        note "none no rows in the Areas table of AGENTS.md"
    fi
    area_count=0
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        area_count=$((area_count + 1))
        dir=$(printf '%s' "$row" | awk -F'|' '{print $2}' | tr -d '` ' )
        cmd=$(printf '%s' "$row" | awk -F'|' '{print $4}' | sed 's/^[ `]*//; s/[ `]*$//')
        if [ ! -d "$dir" ]; then
            failure "area '$dir' is listed in AGENTS.md but the directory does not exist"
            continue
        fi
        if [ -z "$cmd" ] || [ "$cmd" = "-" ]; then
            note "none $dir: no verify command listed"
            continue
        fi
        if (cd "$REPO_ROOT" && sh -c "$cmd") >/dev/null 2>&1; then
            note "ok   $dir: $cmd"
        else
            failure "$dir: verify command failed: $cmd"
        fi
    done <<EOF_ROWS
$rows
EOF_ROWS
    [ "$area_count" -gt 0 ] && note "$area_count area row(s) checked"
fi

# ---- result --------------------------------------------------------
if [ "$failed" -gt 0 ]; then
    echo "smoke: $failed failure(s)."
    exit 1
fi
echo "smoke: green"
