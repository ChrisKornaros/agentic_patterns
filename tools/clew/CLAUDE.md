# tools/clew — agent notes

Two POSIX shell files, no dependencies: `prepare-commit-msg` (the hook)
and `install.sh` (installs it into repos' hooks directories). Human
intro: [README.md](README.md). The loader that reads the trailer is
`metrics/warehouse/warehouse/commits.py` (`warehouse commits-import`).

- **The trailer key is `Clew`, the value is the session id, nothing
  else.** Attended versus unattended comes from the warehouse join, not
  a second trailer. Don't add keys here without a roadmap/15 decision.
- **The hook must stay silent without a session id.** A hand commit
  never gains a trailer. Keep the `[ -n "$sid" ] || exit 0` line first
  after chaining.
- **Chaining is two-way.** Ours runs a kept `.pre-clew` hook first;
  Entire later keeps ours as `.pre-entire`. Never overwrite a foreign
  hook; `install.sh` renames it.
- **`--if-exists replace`** keeps an amend from stacking two trailers.
- **Verify:** install into a scratch repo, commit once with
  `CLAUDE_CODE_SESSION_ID=test`, read it back with
  `git log -1 --format='%(trailers:key=Clew,valueonly)'`; commit once
  without the variable and see no trailer; `install.sh --check` on the
  scratch repo exits 0.
