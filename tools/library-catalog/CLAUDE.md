# tools/library-catalog — agent notes

One module, `library_catalog/__main__.py`, one dependency (PyYAML), run
with `uv run --project tools/library-catalog library-catalog`. Human
intro: [README.md](README.md).

- **It writes one file,** `library/CATALOG.md` in the vault. Nothing
  else. Never hand-edit that file; fix the page's frontmatter and
  regenerate.
- **The contract it checks is the vault's,** in
  `requirements/vault-library.md` D3. Change the rule there first, then
  `REQUIRED_KEYS` / `LEVELS` / `AUTHORS` here, in the same PR as the
  vault PR that changes the rule.
- **Keep `--check` reproducible:** no timestamps or environment-specific
  text in the rendered output.
- **Verify:** run `--check --strict` against `~/vault` after any change
  here, and `uv run --project tools/library-catalog library-catalog --help`
  still prints.
- **Stays stdlib plus PyYAML.** A frontmatter parser written by hand
  breaks on the nested `sources` list; PyYAML is the one dependency
  worth having.
