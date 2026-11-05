# library-catalog

Generates the vault library's `CATALOG.md` from every reference page's
frontmatter, and checks each page against the page contract. The
catalog is the file an agent reads first when it needs a library page
(vault `requirements/vault-library.md` D7); its **Wanted** section lists
the prerequisite pages that don't exist yet, which is the library's own
queue of what to write next. Part of Daedalus's vault tier
(`roadmap/15` §5).

## Run

```sh
# from the agentic_optimization_research root
uv run --project tools/library-catalog library-catalog --vault ~/vault            # regenerate CATALOG.md
uv run --project tools/library-catalog library-catalog --vault ~/vault --check    # verify: exit 1 if stale
uv run --project tools/library-catalog library-catalog --vault ~/vault --strict   # exit 1 on a contract violation
```

Regenerate in every vault PR that adds or changes a page, and commit the
result with the page. `--check --strict` is the verify step.

## What it reads and writes

- **Reads** `library/**/*.md`, skipping `index.md`, `CATALOG.md` and
  files starting with `_` (templates). A file counts as a page when its
  frontmatter has `type: reference`.
- **Checks** the contract: every required key present (`type`, `title`,
  `date`, `tags`, `level`, `author`, `prereqs`, `covers`, `sources`),
  `level` in foundation / core / advanced, `author` in agent / chris /
  course, `reference` among the tags, 5–8 `covers` questions, every
  source with a `title` and a `fetched` date. Violations print as
  warnings; `--strict` makes them fail the run.
- **Writes** `library/CATALOG.md`: one row per page (path, title,
  level, author, tags, the first `covers` question), then **Wanted**.
  No timestamp in the output, so `--check` is reproducible.

## Not here

The pages themselves: factory jobs write those. Search over the library
(`search-docs/` pointed at `library/`) is a later step.
