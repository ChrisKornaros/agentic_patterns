#!/usr/bin/env bash
# One-way export from the private research repo into this public mirror.
#
# Pipeline: refresh mirror -> rsync allowlist into staging -> link
# sanitization + resolution check -> deny-grep gate (on the sanitized
# tree, i.e. what ships) -> copy into working tree -> one commit:
# "sync from source @ <short-sha>".
#
# Requires a local, gitignored .publish-denylist at the repo root
# (grep -E patterns, one per line; blank lines and # comments ignored).
# The patterns themselves are private — never commit that file.
set -euo pipefail

SOURCE_URL="https://github.com/ChrisKornaros/agentic_optimization_research.git"
CACHE="${HOME}/.cache/agentic_optimization_research"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ALLOWLIST="${REPO_ROOT}/scripts/publish-allowlist.txt"
DENYLIST="${REPO_ROOT}/.publish-denylist"

die() { echo "publish: ERROR: $*" >&2; exit 1; }

[ -f "$DENYLIST" ] || die ".publish-denylist not found at repo root — it is local-only and required. Seed it before publishing."
[ -f "$ALLOWLIST" ] || die "allowlist not found: $ALLOWLIST"

branch="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)"
[ "$branch" != "main" ] || die "refusing to publish on main — switch to a review branch first."
git -C "$REPO_ROOT" diff --quiet && git -C "$REPO_ROOT" diff --cached --quiet \
  || die "working tree not clean — commit or stash first so the sync is one commit."

# --- 1. Refresh the mirror (throwaway cache, hard reset to origin/main) ---
if [ -d "$CACHE/.git" ]; then
  git -C "$CACHE" fetch origin main
  git -C "$CACHE" reset --hard origin/main --quiet
else
  mkdir -p "$(dirname "$CACHE")"
  git clone "$SOURCE_URL" "$CACHE"
fi
src_sha="$(git -C "$CACHE" rev-parse --short HEAD)"
echo "publish: source at ${src_sha}"

# --- 2. Export allowlisted paths into staging ---
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT

allowed_paths=()
while IFS= read -r line; do
  line="${line%%#*}"
  line="$(echo "$line" | xargs)"   # trim
  [ -n "$line" ] || continue
  case "$line" in
    /*|*..*) die "allowlist entries must be repo-relative without '..': $line" ;;
  esac
  [ -e "$CACHE/$line" ] || die "allowlisted path missing in source: $line"
  allowed_paths+=("$line")
done < "$ALLOWLIST"
[ "${#allowed_paths[@]}" -gt 0 ] || die "allowlist is empty."

for p in "${allowed_paths[@]}"; do
  mkdir -p "$staging/$(dirname "$p")"
  rsync -a --exclude '.git' "$CACHE/$p" "$staging/$(dirname "$p")/"
done

# --- 3. Link sanitization + resolution check ---
python3 - "$staging" <<'PYEOF'
import os, re, sys

staging = sys.argv[1]
link_re = re.compile(r'\[([^\]]*)\]\(([^)\s]+)\)')

def is_external(t):
    return t.startswith(('http://', 'https://', 'mailto:', '#'))

stripped = 0
for root, _, files in os.walk(staging):
    for name in files:
        if not name.endswith('.md'):
            continue
        path = os.path.join(root, name)
        with open(path, encoding='utf-8') as f:
            text = f.read()

        def fix(m):
            global stripped
            label, target = m.group(1), m.group(2)
            if is_external(target):
                return m.group(0)
            rel = target.split('#')[0]
            if not rel:
                return m.group(0)
            resolved = os.path.normpath(os.path.join(os.path.dirname(path), rel))
            if os.path.commonpath([staging, os.path.abspath(resolved)]) == staging \
               and os.path.exists(resolved):
                return m.group(0)
            stripped += 1
            # Link points outside the export: keep text, drop link. If the
            # label is itself a path, collapse it to a backticked basename
            # so no private-repo path ships as prose.
            l = label.strip()
            if l == target or ('/' in l and re.fullmatch(r'[\w./#-]+', l)):
                base = os.path.basename((rel or target).rstrip('/'))
                return '`{}`'.format(os.path.splitext(base)[0] or 'link')
            return label

        new = link_re.sub(fix, text)
        if new != text:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new)

# resolution check: no dangling relative link may remain
dangling = []
for root, _, files in os.walk(staging):
    for name in files:
        if not name.endswith('.md'):
            continue
        path = os.path.join(root, name)
        with open(path, encoding='utf-8') as f:
            text = f.read()
        for m in link_re.finditer(text):
            target = m.group(2)
            if is_external(target):
                continue
            rel = target.split('#')[0]
            if not rel:
                continue
            resolved = os.path.normpath(os.path.join(os.path.dirname(path), rel))
            if not os.path.exists(resolved):
                dangling.append(f"{os.path.relpath(path, staging)} -> {target}")

if dangling:
    print("publish: ERROR: dangling links after sanitization:", file=sys.stderr)
    for d in dangling:
        print(f"  {d}", file=sys.stderr)
    sys.exit(1)

print(f"publish: link check passed ({stripped} private-pointing link(s) stripped)")
PYEOF

# --- 4. Deny-grep gate (runs on the sanitized tree — what actually ships) ---
have_patterns=0
while IFS= read -r pat; do
  [ -n "$pat" ] && [ "${pat:0:1}" != "#" ] || continue
  have_patterns=1
  if hits="$(grep -rEl -- "$pat" "$staging" 2>/dev/null)"; then
    echo "publish: deny pattern matched in export:" >&2
    echo "$hits" | sed "s|^$staging/|  |" >&2
    die "deny-grep gate failed (pattern not echoed — it is private)."
  fi
done < "$DENYLIST"
[ "$have_patterns" -eq 1 ] || die ".publish-denylist contains no patterns — refusing to publish unguarded."
echo "publish: deny-grep gate passed"

# --- 5. Copy into the working tree and commit ---
for p in "${allowed_paths[@]}"; do
  mkdir -p "$REPO_ROOT/$(dirname "$p")"
  rsync -a --delete "$staging/$p" "$REPO_ROOT/$(dirname "$p")/"
done

git -C "$REPO_ROOT" add -A -- "${allowed_paths[@]}"
if git -C "$REPO_ROOT" diff --cached --quiet; then
  echo "publish: no changes since last sync — nothing to commit."
else
  git -C "$REPO_ROOT" commit -m "sync from source @ ${src_sha}"
  echo "publish: committed sync from source @ ${src_sha}"
fi
