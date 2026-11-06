#!/usr/bin/env bash
# install-modules.sh — Mode A of the import workflow.
#
# Vendors one or more modules from this canonical repo into a host repo
# per roadmap/05-import-workflow.md §4. Idempotent: re-running at the
# same source commit is a no-op; a newer commit re-copies the module
# and updates the row in MODULES.md in place (no duplicates).
#
# The script does NOT write to the host's CLAUDE.md or
# .claude/settings.json — those edits need judgment and stay manual.
# A ready-to-paste Composed-modules snippet is printed to stdout
# along with a follow-up checklist.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CANONICAL_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

usage() {
    cat <<'USAGE'
Usage: scripts/install-modules.sh [flags] <host-repo-path> <module> [<module>...]

Vendors one or more modules from this canonical repo into a host repo.
Any skill in skills/ whose frontmatter `module:` names an installed
module is vendored alongside it (into <host>/.claude/skills/), so a
prompt-module never lands without its runnable shim. Standalone skills
that back no module (e.g. scope-guard) are added with --skill. Runnable
tools from tools/ (e.g. the search-docs MCP server) are added with
--tool; they land in <host>/.claude/tools/ and the script prints a
ready-to-merge .mcp.json snippet (it does not edit .mcp.json itself).
See roadmap/05-import-workflow.md §4 for the full contract.

Flags:
  --skill <name>  Also vendor this skill, even if it backs no installed
                  module. Repeatable.
  --tool <name>   Vendor this tool from tools/<name>/ into the host's
                  .claude/tools/<name>/. Repeatable.
  --no-skills     Don't auto-vendor the skills paired with installed
                  modules (modules only).
  --dry-run       Print the plan; make no changes.
  --force         Overwrite an existing module/skill/tool copy and bypass
                  override protection (sentinel file or Override column).
                  The override record survives: the Override note and any
                  .override sentinel are kept, so re-apply the local change
                  or clear the note by hand.
  -h, --help      This message.

Examples:
  scripts/install-modules.sh ~/code/new-thing git-flow-session-end git-flow-no-direct-main
  scripts/install-modules.sh --skill scope-guard ~/code/new-thing git-flow-session-end
  scripts/install-modules.sh --tool search-docs ~/code/new-thing smoke-before-commit
  scripts/install-modules.sh --dry-run ../other-repo phase-kickoff
USAGE
}

err()  { printf 'error: %s\n' "$*" >&2; }
warn() { printf 'warn: %s\n'  "$*" >&2; }

DRY_RUN=0
FORCE=0
NO_SKILLS=0
ARGS=()
EXTRA_SKILLS=()
EXTRA_TOOLS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)   DRY_RUN=1; shift ;;
        --force)     FORCE=1;   shift ;;
        --no-skills) NO_SKILLS=1; shift ;;
        --skill)     [[ $# -ge 2 ]] || { err "--skill needs a name"; exit 2; }
                     EXTRA_SKILLS+=("$2"); shift 2 ;;
        --tool)      [[ $# -ge 2 ]] || { err "--tool needs a name"; exit 2; }
                     EXTRA_TOOLS+=("$2"); shift 2 ;;
        -h|--help)   usage; exit 0 ;;
        --)          shift; while [[ $# -gt 0 ]]; do ARGS+=("$1"); shift; done ;;
        --*)         err "unknown flag: $1"; usage >&2; exit 2 ;;
        *)           ARGS+=("$1"); shift ;;
    esac
done

if [[ ${#ARGS[@]} -lt 2 ]]; then
    err "need host-repo-path and at least one module name"
    usage >&2
    exit 2
fi

HOST=${ARGS[0]}
MODULES=("${ARGS[@]:1}")

# ── 1. Validate inputs ──────────────────────────────────────────────
if [[ ! -d $HOST ]]; then
    err "host path does not exist or is not a directory: $HOST"
    exit 1
fi
HOST=$(cd "$HOST" && pwd)

if ! (cd "$HOST" && git rev-parse --git-dir >/dev/null 2>&1); then
    err "host is not a git repo: $HOST"
    exit 1
fi

for m in "${MODULES[@]}"; do
    if [[ ! -f "$CANONICAL_ROOT/modules/$m/index.md" ]]; then
        err "module not found in canonical repo: $m"
        err "  expected: $CANONICAL_ROOT/modules/$m/index.md"
        exit 1
    fi
done

for s in "${EXTRA_SKILLS[@]:-}"; do
    [[ -n $s ]] || continue
    if [[ ! -f "$CANONICAL_ROOT/skills/$s/SKILL.md" ]]; then
        err "skill not found in canonical repo: $s"
        err "  expected: $CANONICAL_ROOT/skills/$s/SKILL.md"
        exit 1
    fi
done

for t in "${EXTRA_TOOLS[@]:-}"; do
    [[ -n $t ]] || continue
    if [[ ! -f "$CANONICAL_ROOT/tools/$t/mcp-entry.json" ]]; then
        err "tool not found or not vendorable in canonical repo: $t"
        err "  expected: $CANONICAL_ROOT/tools/$t/mcp-entry.json"
        err "  (a vendorable tool declares its .mcp.json wiring in mcp-entry.json)"
        exit 1
    fi
done

# ── 2. Capture source commit + date ────────────────────────────────
SOURCE_COMMIT=$(cd "$CANONICAL_ROOT" && git rev-parse --short HEAD)
TODAY=$(date +%Y-%m-%d)
# Where the ledgers say the copies came from. Derived from the canonical
# root's own origin remote, so a downstream copy of this library (a
# vendored meta-repo running this script against its team repos) writes
# ledgers that name itself, not this repo. Falls back to this repo when
# there is no remote. The web-path shape (`tree/main`, `blob/main`) is
# the one GitHub, GitLab and Gitea share; other hosts get the plain repo
# URL instead of a path they will not serve.
_origin=$(cd "$CANONICAL_ROOT" && git remote get-url origin 2>/dev/null || true)
case "$_origin" in
    git@*:*)   _origin="${_origin#git@}"; _origin="https://${_origin%%:*}/${_origin#*:}" ;;
    ssh://*)   _origin="https://${_origin#ssh://}"; _origin="${_origin/#https:\/\/git@/https://}" ;;
esac
_origin="${_origin%/}"; _origin="${_origin%.git}"
if [[ $_origin == https://* ]]; then
    CANONICAL_WEB=$_origin
else
    CANONICAL_WEB=https://github.com/ChrisKornaros/agentic_optimization_research
fi
CANONICAL_NAME=${CANONICAL_WEB##*/}
# Deep links (`tree/main`, `blob/main`) only on hosts known to serve that
# shape; any other host gets the plain repo URL, which every host serves
# (roadmap/16 D13: a Bitbucket meta-repo got `tree/main` links its host
# would not resolve, 2026-11-05).
case "${CANONICAL_WEB#https://}" in
    github.com/*|gitlab.*|*.gitlab.*|codeberg.org/*|gitea.*|*.gitea.*)
        CANONICAL_TREE=$CANONICAL_WEB/tree/main
        CANONICAL_BLOB=$CANONICAL_WEB/blob/main ;;
    *)  CANONICAL_TREE=$CANONICAL_WEB
        CANONICAL_BLOB=$CANONICAL_WEB ;;
esac

# Ledger headers (everything up to and including the table separator).
MODULES_HEADER='# Vendored modules

Pulled from ['"$CANONICAL_NAME"'/modules/]('"$CANONICAL_TREE"'/modules).
When a module'"'"'s canonical version bumps, re-copy and update the row here. Local overrides go in the **Override** column.

| Module | Version | Source commit | Copied at | Override |
|---|---|---|---|---|'

SKILLS_HEADER='# Vendored skills

Pulled from ['"$CANONICAL_NAME"'/skills/]('"$CANONICAL_TREE"'/skills).
Each skill is a thin SKILL.md shim, vendored into `.claude/skills/<name>/` — auto-paired with the module it backs, or added standalone. Local overrides go in the **Override** column.

| Skill | Version | Source commit | Copied at | Backs module | Override |
|---|---|---|---|---|---|'

TOOLS_HEADER='# Vendored tools

Pulled from ['"$CANONICAL_NAME"'/tools/]('"$CANONICAL_TREE"'/tools).
Each tool is a runnable agent tool (e.g. an MCP server), vendored into `.claude/tools/<name>/` and wired into the host `.mcp.json`. Local overrides go in the **Override** column.

| Tool | Version | Source commit | Copied at | Override |
|---|---|---|---|---|'

# ── 3. Helpers ──────────────────────────────────────────────────────

# get_frontmatter_field <file> <field>
# Prints the first occurrence of `<field>:` inside the leading `---` block
# of <file> (a module's index.md or a skill's SKILL.md).
get_frontmatter_field() {
    [[ -f $1 ]] || return 0
    awk -v field="$2:" '
        /^---[[:space:]]*$/ { fm = !fm; if (!fm) exit; next }
        fm && index($0, field) == 1 {
            v = $0
            sub("^" field "[[:space:]]*", "", v)
            print v
            exit
        }
    ' "$1"
}

# get_pyproject_version <pyproject.toml>
# Prints the first `version = "X"` under [project] in a pyproject.toml.
# Tools carry no frontmatter, so their version comes from packaging metadata.
get_pyproject_version() {
    [[ -f $1 ]] || return 0
    awk '
        /^\[project\]/ { inproj = 1; next }
        /^\[/          { inproj = 0 }
        inproj && /^version[[:space:]]*=/ {
            v = $0
            sub(/^version[[:space:]]*=[[:space:]]*/, "", v)
            gsub(/["'"'"']/, "", v)
            print v
            exit
        }
    ' "$1"
}

# emit_mcp_snippet <mcp-entry.json> <host-relative-dir>
# Prints a {server_key: server} object for the host's .mcp.json, with the
# __DIR__ placeholder in args replaced by the vendored dir. Uses jq when
# present; otherwise prints a manual-merge instruction.
emit_mcp_snippet() {
    local entry=$1 reldir=$2
    if command -v jq >/dev/null 2>&1; then
        jq --arg dir "$reldir" \
           '{ (.server_key): (.server | (.args |= map(if . == "__DIR__" then $dir else . end))) }' \
           "$entry"
    else
        echo "     (jq not found — in $entry replace __DIR__ with \"$reldir\","
        echo "      then merge { <server_key>: <server> } into the host's .mcp.json)"
    fi
}

# skills_for_module <module>
# Prints the directory name of every skill in the canonical skills/
# library whose frontmatter `module:` field names <module>. The
# module→skill pairing that lets a prompt-module never land without its
# runnable shim (roadmap/08 C1 part 2).
skills_for_module() {
    local module=$1 skill_md backing
    [[ -d "$CANONICAL_ROOT/skills" ]] || return 0
    for skill_md in "$CANONICAL_ROOT"/skills/*/SKILL.md; do
        [[ -f $skill_md ]] || continue
        backing=$(get_frontmatter_field "$skill_md" module)
        if [[ $backing == "$module" ]]; then
            basename "$(dirname "$skill_md")"
        fi
    done
}

# get_existing_override <ledger_path> <name> [col]
# Prints the trimmed Override column of an existing row, or empty. The
# Override cell is col 6 in MODULES.md and col 7 in SKILLS.md (which
# carries an extra "Backs module" column); pass <col> for the latter.
get_existing_override() {
    local file=$1 module=$2 col=${3:-6}
    [[ -f $file ]] || return 0
    # `|| true` so a no-match grep (exit 1) doesn't trip pipefail/set -e
    # when adding a brand-new module to an existing ledger.
    { grep -E "^\| \[$module\]" "$file" 2>/dev/null || true; } | head -1 | awk -F'|' -v col="$col" '
        NF >= col {
            v = $col
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", v)
            print v
        }
    '
}

# override_note <existing_override>
# The Override cell to write back: the existing note if there is one
# (so --force keeps the record of a local change), else "—".
override_note() {
    local v=${1:-}
    if [[ -z $v || $v == "-" ]]; then v="—"; fi
    printf '%s' "$v"
}

# recopy <src> <dest>
# Replace <dest> with a fresh copy of <src>, keeping a .override
# sentinel if <dest> had one (a --force re-copy mustn't erase it).
recopy() {
    local src=$1 dest=$2 saved=""
    if [[ -f $dest/.override ]]; then
        saved=$(mktemp)
        cp "$dest/.override" "$saved"
    fi
    rm -rf "$dest"
    cp -R "$src" "$dest"
    if [[ -n $saved ]]; then mv "$saved" "$dest/.override"; fi
}

# relink <vendored .md> <canonical parent dir> <path to host root>
# Canonical links are written for this repo's layout, but a host holds
# only what it vendored, and skills and tools sit one level deeper there
# (.claude/skills/<name>/, not skills/<name>/). Re-point each ../ or
# ../../ link by its canonical target: a module or skill the host
# vendored links to the host copy; anything else (prompts/, roadmap/,
# knowledge/, case-studies/, a module the host didn't vendor) links to
# the canonical file on GitHub. Links that already reach the host copy
# are left as written.
relink() {
    local md=$1 canon_dir=$2 to_root=$3 dir content target canon rest name local_path new
    dir=$(dirname "$md")
    content=$(<"$md")
    while IFS= read -r target; do
        case $target in
            ../../*) canon=${target#../../} ;;
            *)       canon=$canon_dir/${target#../} ;;
        esac
        rest=${canon#*/}
        name=${rest%%/*}
        local_path=""
        if [[ $canon == modules/* && -d $HOST/modules/$name ]]; then
            local_path=$canon
        elif [[ $canon == skills/* && -d $HOST/.claude/skills/$name ]]; then
            local_path=.claude/$canon
        fi
        if [[ -z $local_path ]]; then
            new=$CANONICAL_BLOB/$canon
        elif [[ $dir/${target%%#*} -ef $HOST/${local_path%%#*} ]]; then
            continue
        else
            new=$to_root$local_path
        fi
        content=${content//"]($target)"/"]($new)"}
    done < <(grep -oE '\]\(\.\./(\.\./)?[^./)][^)]*\)' "$md" | sed -E 's/^\]\((.*)\)$/\1/' | sort -u)
    printf '%s\n' "$content" > "$md"
}

# upsert_row <ledger_path> <name> <new_row> <header>
# Replaces an existing row for <name> in place; appends if missing.
# Creates the file with <header> (which must end at the table's
# separator line) if it doesn't exist. Rows are matched by the leading
# `| [<name>]` cell, shared by both the modules and skills ledgers.
upsert_row() {
    local file=$1 module=$2 new_row=$3 header=$4
    local tmp marker
    tmp=$(mktemp)
    marker=$(mktemp)

    if [[ ! -f $file ]]; then
        { printf '%s\n' "$header"; printf '%s\n' "$new_row"; } > "$file"
        rm -f "$marker" "$tmp"
        return
    fi

    awk -v mod="$module" -v new="$new_row" -v marker="$marker" '
        BEGIN { replaced = 0 }
        $0 ~ ("^\\| \\[" mod "\\]") {
            print new
            replaced = 1
            next
        }
        { print }
        END { if (replaced) print "y" > marker }
    ' "$file" > "$tmp"

    if [[ ! -s $marker ]]; then
        printf '%s\n' "$new_row" >> "$tmp"
    fi
    rm -f "$marker"
    mv "$tmp" "$file"
}

# ── 4. Check overrides + assemble plan ──────────────────────────────
REFUSED=()
PLAN=()
for m in "${MODULES[@]}"; do
    sentinel="$HOST/modules/$m/.override"
    existing_override=$(get_existing_override "$HOST/MODULES.md" "$m")
    is_overridden=0
    reason=""
    if [[ -e $sentinel ]]; then
        is_overridden=1
        reason="sentinel file modules/$m/.override"
    elif [[ -n $existing_override && $existing_override != "—" && $existing_override != "-" ]]; then
        is_overridden=1
        reason="MODULES.md Override column: '$existing_override'"
    fi

    if [[ $is_overridden -eq 1 && $FORCE -eq 0 ]]; then
        warn "refusing to overwrite $m ($reason); pass --force to override"
        REFUSED+=("$m")
        continue
    fi

    version=$(get_frontmatter_field "$CANONICAL_ROOT/modules/$m/index.md" version)
    type=$(get_frontmatter_field "$CANONICAL_ROOT/modules/$m/index.md" type)
    if [[ -z $version ]]; then
        err "module $m: missing 'version:' in frontmatter"
        exit 1
    fi
    if [[ -z $type ]]; then
        err "module $m: missing 'type:' in frontmatter"
        exit 1
    fi
    PLAN+=("$m|$version|$type|$(override_note "$existing_override")")
done

if [[ ${#PLAN[@]} -eq 0 ]]; then
    err "no modules to install (all refused or empty plan)"
    exit 1
fi

# ── 5. Execute (or print plan) ──────────────────────────────────────
echo
echo "Canonical:     $CANONICAL_ROOT"
echo "Source commit: $SOURCE_COMMIT"
echo "Host:          $HOST"
echo "Date:          $TODAY"
[[ $DRY_RUN -eq 1 ]] && echo "Mode:          DRY RUN (no writes)"
echo

for entry in "${PLAN[@]}"; do
    IFS='|' read -r m version type keep <<< "$entry"
    dest="$HOST/modules/$m"
    new_row="| [$m](modules/$m/index.md) | $version | \`$SOURCE_COMMIT\` | $TODAY | $keep |"

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "would copy:    $CANONICAL_ROOT/modules/$m → $dest (re-pointing links)"
        echo "would upsert:  $HOST/MODULES.md"
        echo "               $new_row"
    else
        mkdir -p "$HOST/modules"
        recopy "$CANONICAL_ROOT/modules/$m" "$dest"
        upsert_row "$HOST/MODULES.md" "$m" "$new_row" "$MODULES_HEADER"
        echo "installed module: $m (v$version, type=$type)"
        if [[ $keep != "—" ]]; then warn "kept $m's Override note '$keep': re-apply the local change or clear the note"; fi
    fi
done

# ── 5b. Vendor paired + standalone skills ───────────────────────────
# A prompt-module never lands without its runnable shim: every skill
# whose frontmatter `module:` names an installed module is vendored
# alongside it, plus any --skill names. Skills land in the host's
# .claude/skills/<name>/ — Claude Code auto-surfaces them there, so
# (unlike modules) they need no CLAUDE.md paste.
SKILL_SET=()
add_skill() {  # dedup append
    local existing
    for existing in "${SKILL_SET[@]:-}"; do
        [[ $existing == "$1" ]] && return 0
    done
    SKILL_SET+=("$1")
}

if [[ $NO_SKILLS -eq 0 ]]; then
    for entry in "${PLAN[@]}"; do
        IFS='|' read -r m _ _ <<< "$entry"
        while IFS= read -r s; do
            [[ -n $s ]] && add_skill "$s"
        done < <(skills_for_module "$m")
    done
fi
for s in "${EXTRA_SKILLS[@]:-}"; do
    [[ -n $s ]] && add_skill "$s"
done

SKILL_PLAN=()
SKILL_REFUSED=()
for s in "${SKILL_SET[@]:-}"; do
    [[ -n $s ]] || continue
    sentinel="$HOST/.claude/skills/$s/.override"
    existing_override=$(get_existing_override "$HOST/SKILLS.md" "$s" 7)
    is_overridden=0
    reason=""
    if [[ -e $sentinel ]]; then
        is_overridden=1
        reason="sentinel file .claude/skills/$s/.override"
    elif [[ -n $existing_override && $existing_override != "—" && $existing_override != "-" ]]; then
        is_overridden=1
        reason="SKILLS.md Override column: '$existing_override'"
    fi
    if [[ $is_overridden -eq 1 && $FORCE -eq 0 ]]; then
        warn "refusing to overwrite skill $s ($reason); pass --force to override"
        SKILL_REFUSED+=("$s")
        continue
    fi
    sversion=$(get_frontmatter_field "$CANONICAL_ROOT/skills/$s/SKILL.md" version)
    sbacks=$(get_frontmatter_field "$CANONICAL_ROOT/skills/$s/SKILL.md" module)
    [[ -z $sversion ]] && sversion="?"
    [[ -z $sbacks ]] && sbacks="—"
    SKILL_PLAN+=("$s|$sversion|$sbacks|$(override_note "$existing_override")")
done

for entry in "${SKILL_PLAN[@]:-}"; do
    [[ -n $entry ]] || continue
    IFS='|' read -r s sversion sbacks keep <<< "$entry"
    dest="$HOST/.claude/skills/$s"
    new_row="| [$s](.claude/skills/$s/SKILL.md) | $sversion | \`$SOURCE_COMMIT\` | $TODAY | $sbacks | $keep |"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "would copy:    $CANONICAL_ROOT/skills/$s → $dest (re-pointing links)"
        echo "would upsert:  $HOST/SKILLS.md"
        echo "               $new_row"
    else
        mkdir -p "$HOST/.claude/skills"
        recopy "$CANONICAL_ROOT/skills/$s" "$dest"
        upsert_row "$HOST/SKILLS.md" "$s" "$new_row" "$SKILLS_HEADER"
        echo "installed skill: $s (v$sversion, backs $sbacks)"
        if [[ $keep != "—" ]]; then warn "kept skill $s's Override note '$keep': re-apply the local change or clear the note"; fi
    fi
done

# ── 5c. Vendor runnable tools ───────────────────────────────────────
# Tools (e.g. the search-docs MCP server) are opt-in via --tool. They
# land in the host's .claude/tools/<name>/ and need a .mcp.json entry to
# run — the script prints that snippet but doesn't edit .mcp.json, which
# (like CLAUDE.md/settings.json) stays a judgment edit. .venv/__pycache__
# are pruned from the copy so a local checkout's virtualenv doesn't ride
# along.
TOOL_PLAN=()
TOOL_REFUSED=()
for t in "${EXTRA_TOOLS[@]:-}"; do
    [[ -n $t ]] || continue
    sentinel="$HOST/.claude/tools/$t/.override"
    # TOOLS.md has the same column count as MODULES.md, so Override is the
    # default awk field (6) — no explicit column arg.
    existing_override=$(get_existing_override "$HOST/TOOLS.md" "$t")
    is_overridden=0
    reason=""
    if [[ -e $sentinel ]]; then
        is_overridden=1
        reason="sentinel file .claude/tools/$t/.override"
    elif [[ -n $existing_override && $existing_override != "—" && $existing_override != "-" ]]; then
        is_overridden=1
        reason="TOOLS.md Override column: '$existing_override'"
    fi
    if [[ $is_overridden -eq 1 && $FORCE -eq 0 ]]; then
        warn "refusing to overwrite tool $t ($reason); pass --force to override"
        TOOL_REFUSED+=("$t")
        continue
    fi
    tversion=$(get_pyproject_version "$CANONICAL_ROOT/tools/$t/pyproject.toml")
    [[ -z $tversion ]] && tversion="?"
    TOOL_PLAN+=("$t|$tversion|$(override_note "$existing_override")")
done

for entry in "${TOOL_PLAN[@]:-}"; do
    [[ -n $entry ]] || continue
    IFS='|' read -r t tversion keep <<< "$entry"
    dest="$HOST/.claude/tools/$t"
    reldir=".claude/tools/$t"
    new_row="| [$t]($reldir/) | $tversion | \`$SOURCE_COMMIT\` | $TODAY | $keep |"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "would copy:    $CANONICAL_ROOT/tools/$t → $dest (pruning .venv/__pycache__, re-pointing links)"
        echo "would upsert:  $HOST/TOOLS.md"
        echo "               $new_row"
        echo "would emit:    .mcp.json snippet for $reldir"
    else
        mkdir -p "$HOST/.claude/tools"
        recopy "$CANONICAL_ROOT/tools/$t" "$dest"
        rm -rf "$dest/.venv"
        find "$dest" -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true
        upsert_row "$HOST/TOOLS.md" "$t" "$new_row" "$TOOLS_HEADER"
        echo "installed tool: $t (v$tversion) → $reldir"
        if [[ $keep != "—" ]]; then warn "kept tool $t's Override note '$keep': re-apply the local change or clear the note"; fi
    fi
done

# ── 5d. Re-point vendored links ─────────────────────────────────────
# Runs once every module, skill and tool in this run has landed, so a
# link from one to another vendored in the same run counts as local.
# A tool's docs are its top-level .md files.
if [[ $DRY_RUN -eq 0 ]]; then
    for entry in "${PLAN[@]}"; do
        relink "$HOST/modules/${entry%%|*}/index.md" modules ../../
    done
    for entry in "${SKILL_PLAN[@]:-}"; do
        [[ -n $entry ]] || continue
        relink "$HOST/.claude/skills/${entry%%|*}/SKILL.md" skills ../../../
    done
    for entry in "${TOOL_PLAN[@]:-}"; do
        [[ -n $entry ]] || continue
        for md in "$HOST/.claude/tools/${entry%%|*}"/*.md; do
            [[ -f $md ]] || continue
            relink "$md" tools ../../../
        done
    done
fi

# ── 6. Print Composed-modules snippet ───────────────────────────────
echo
echo "─── Composed-modules snippet (paste into <host>/CLAUDE.md) ───"
echo
echo "| Module | Type | Why it's here |"
echo "|---|---|---|"
for entry in "${PLAN[@]}"; do
    IFS='|' read -r m version type _ <<< "$entry"
    echo "| [$m](modules/$m/index.md) | $type | [describe why] |"
done

# ── 7. Follow-up checklist ──────────────────────────────────────────
echo
echo "─── Follow-up checklist ───"
echo
echo "1. Paste the snippet above into <host>/CLAUDE.md under a '## Composed modules' section."
echo "2. For any 'workflow'-type module, also paste its short-form steps inline — see modules/VENDORING.md §5."
echo "3. If <host>/.claude/settings.json doesn't exist, copy templates/_shared/claude-settings.example.json from the canonical repo and tighten the deny list per the modules you adopted."

# Surface the settings/hook companions the installed modules ship, so
# the deny-list + hooks wiring (VENDORING.md §6) isn't silently skipped.
snippet_mods=()
hook_mods=()
for entry in "${PLAN[@]}"; do
    IFS='|' read -r m _ _ <<< "$entry"
    [[ -f "$CANONICAL_ROOT/modules/$m/settings-snippet.json" ]] && snippet_mods+=("$m")
    # Any .py companion is a hook script (e.g. no-cat-head-via-bash/pre_read_guard.py).
    if compgen -G "$CANONICAL_ROOT/modules/$m/"'*.py' >/dev/null 2>&1; then
        hook_mods+=("$m")
    fi
done
if [[ ${#snippet_mods[@]} -gt 0 ]]; then
    echo "4. These modules ship a settings-snippet.json — merge each one's 'deny' entries into <host>/.claude/settings.json (VENDORING.md §6):"
    for m in "${snippet_mods[@]}"; do
        echo "     - modules/$m/settings-snippet.json"
    done
fi
if [[ ${#hook_mods[@]} -gt 0 ]]; then
    echo "5. These modules ship a hook script — wire the matching hook (PreToolUse / Stop / SessionStart, per each module's '## Companion files') in <host>/.claude/settings.json using its settings-snippet.json (fail-open shape; VENDORING.md §6):"
    for m in "${hook_mods[@]}"; do
        echo "     - modules/$m/ (see its index.md '## Companion files')"
    done
fi

# Surface the vendored skills. Unlike modules, they need no CLAUDE.md
# paste — Claude Code auto-surfaces anything under .claude/skills/.
if [[ ${#SKILL_PLAN[@]} -gt 0 && -n ${SKILL_PLAN[0]:-} ]]; then
    echo "6. Vendored skills (auto-surfaced from <host>/.claude/skills/ — no CLAUDE.md paste needed; tracked in SKILLS.md):"
    for entry in "${SKILL_PLAN[@]}"; do
        IFS='|' read -r s sversion sbacks _ <<< "$entry"
        if [[ $sbacks == "—" ]]; then
            echo "     - $s (standalone)"
        else
            echo "     - $s (pairs with module $sbacks)"
        fi
    done
fi

# Surface the vendored tools. Unlike skills, a tool needs a .mcp.json
# entry to run — emit it here for the user/bootstrap to merge, plus the
# discoverability nudge H1 showed is load-bearing (a silently-registered
# MCP server gets zero adoption).
if [[ ${#TOOL_PLAN[@]} -gt 0 && -n ${TOOL_PLAN[0]:-} ]]; then
    echo "7. Vendored tools — copied into <host>/.claude/tools/ (tracked in TOOLS.md). Each needs a .mcp.json entry to run; merge the snippet(s) below into the host's .mcp.json \"mcpServers\" object:"
    for entry in "${TOOL_PLAN[@]}"; do
        [[ -n $entry ]] || continue
        IFS='|' read -r t tversion _ <<< "$entry"
        echo "     - $t:"
        emit_mcp_snippet "$CANONICAL_ROOT/tools/$t/mcp-entry.json" ".claude/tools/$t" | sed 's/^/         /'
    done
    echo "   Then carry the discoverability fix: add a one-line 'prefer search_docs over grep for rule/doc lookup' note to <host>/CLAUDE.md, and approve the project-scoped MCP server on every machine that runs sessions there. Per the H1 RESULT, a tool that's invisible at decision time gets zero adoption."
fi

# Non-zero exit if any module, skill, or tool was refused, even though
# others succeeded.
if [[ ${#REFUSED[@]} -gt 0 || ${#SKILL_REFUSED[@]} -gt 0 || ${#TOOL_REFUSED[@]} -gt 0 ]]; then
    echo
    [[ ${#REFUSED[@]} -gt 0 ]] && err "${#REFUSED[@]} module(s) refused: ${REFUSED[*]}"
    [[ ${#SKILL_REFUSED[@]} -gt 0 ]] && err "${#SKILL_REFUSED[@]} skill(s) refused: ${SKILL_REFUSED[*]}"
    [[ ${#TOOL_REFUSED[@]} -gt 0 ]] && err "${#TOOL_REFUSED[@]} tool(s) refused: ${TOOL_REFUSED[*]}"
    exit 1
fi
