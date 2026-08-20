> **Example artifact.** This is the actual blinded rating sheet from a
> retrieval experiment (see this directory's README for design and
> results): 20 historical-recall prompts, each with a reference answer
> and three shuffled, condition-anonymized agent responses (R1–R3).
> The rater filled a separate ratings.csv without access to the
> label→condition key. One prompt (P18) is redacted for personal
> research reasons; everything else is verbatim.

# H3 blinded rating sheet — 2026-08-19

Rubric: 0 = wrong/missing, 1 = partially correct, 2 = correct + actionable.
Score each response in ratings.csv (same labels). Do NOT open
blind_key.json until ratings.csv is complete.

## P01 — Why did the metrics warehouse move off DuckDB to Postgres-on-Pi?

**Reference answer:** DuckDB is single-writer; concurrent session-log ingest (the live Stop hook firing from overlapping sessions) needs concurrent writes, so the warehouse moved to Postgres running in Docker on the Pi.

### P01-R1

Found the answer directly in the repo docs.

**Why: single-writer, single-Mac limitation.** The original warehouse was a local DuckDB file (`warehouse.duckdb`) on your Mac. DuckDB is embedded/single-writer/single-process, which fit its original ad-hoc analytics use — but once the Stop hook started ingesting session data live after every Claude Code session, that model broke down: a local file can't be written to concurrently from multiple machines, and history was tied to whichever Mac held the file, not durable independent of any one machine.

Postgres-on-Pi (later ms01) solved both: one canonical store the Stop hook can write to live without single-writer file-locking coordination, with durable history that survives regardless of which laptop is in use.

The migration happened in **PR #36** — DuckDB warehouse path (`warehouse.duckdb`, `schema.sql`, `loader.py`, and the `init`/`load`/`query`/`info` CLI subcommands) was fully retired once Postgres-on-Pi held parity with it, and the `duckdb` dependency was dropped from `pyproject.toml` (bumped to 0.2.0).

Note: DuckDB itself wasn't abandoned as a tool — it's still kept around (and still in the permissions allowlist) for ad-hoc Parquet/CSV analytics; it's just no longer the warehouse's storage path. Documented in `metrics/warehouse/README.md:17-21` and `roadmap/01-data-collection.md:117-122`.

### P01-R2

I have enough to answer directly now.

## Why the warehouse moved from DuckDB to Postgres-on-Pi

**The core reason: the warehouse needed to become a networked, always-on, multi-client store, and DuckDB is architecturally embedded/single-process.**

- DuckDB was the deliberate starting default (per `modules/duckdb-default-store`) — analytical workload, single developer, zero server overhead. It worked fine while the warehouse was a local `.duckdb` file that Chris queried by hand on the Mac.
- The requirement changed: Chris wanted the warehouse to live persistently on his Ubuntu Pi as the canonical store, reachable **over LAN from the Mac** so Claude Code sessions could ingest automatically at session-end (via a Stop hook) without a manual `warehouse load` step — and, longer-term, reachable by other writers too (Hermes, the Pi-hosted agent, plus ad-hoc `psql` access).
- That's exactly the graduation trigger the module documents explicitly: *"You need multiple processes writing concurrently"* / *"you're deploying to multiple environments and want [network] access."* An embedded, single-writer, single-process file format like DuckDB has no client-server protocol — you can't have the Mac remotely write to a `.duckdb` file sitting on the Pi. Postgres does that natively.

It was a deliberate, planned migration, not a reactive fix — decided explicitly in a 2026-05-26 planning turn (Chris answered "Postgres on Pi" as the recommended engine when asked where the warehouse should live), then executed as a clean 3-PR sequence: **PR 1** schema + Docker compose on the Pi, **PR 2** Mac-side `psycopg` loader (port of the DuckDB loader) + failover queue, **PR 3** wiring the Stop hook globally so every session ingests live. The legacy DuckDB path (`warehouse.duckdb`, `schema.sql`, `init/load/query/info` subcommands) was retired once Postgres reached parity (PR #36) — DuckDB is still fine for ad-hoc Parquet analytics, just no longer the warehouse's system of record.

### P01-R3

## Why the warehouse moved from DuckDB to Postgres-on-Pi

**The core driver was concurrency + durability, not analytics performance.** DuckDB was a local file on the Mac — inherently single-writer, and its state lived and died with that one machine. Once the Stop hook was built to ingest session data live at the end of every Claude Code session, that model broke down: the hook needed a store it could write to without coordinating against a local exclusive file lock, and one that persisted independent of any single Mac.

Postgres running on the Pi (and later ms01) solved both problems:
- **Live multi-writer ingest** — the Stop hook backgrounds a write via `nohup` without blocking session exit, and doesn't fight a single-writer file lock.
- **Durable, machine-independent history** — the data survives Mac changes/restarts since it's centralized on always-on hardware.
- **Network resilience** — an idempotent ingest design with a fail-over queue (`~/.cache/agentic_metrics/queue.jsonl`, drained via `warehouse retry`) if the Pi is briefly unreachable.

The migration happened around **2026-05-26** across a few PRs (schema, Mac-side ingest, Stop hook wiring), and DuckDB was formally retired shortly after once Postgres had held parity — the reasoning per the retirement commit was that the DuckDB-on-Mac path had become "dead weight" once the Pi path was proven live.

Worth noting: DuckDB itself wasn't a bad choice for what it was doing (analytical queries over per-session token/tool data were "exactly its sweet spot" per the old README) — it was the *architecture* (local-only, single-writer) that stopped fitting once live cross-session ingest became a requirement, not the query engine's analytical capability.

Source: `roadmap/01-data-collection.md` (lines ~87–122), `metrics/warehouse/README.md`, and commits f902a2d / 698613a / 270bea4 / f53025a.

## P02 — What is the canonical home for a portable instruction rule that's shared across roles and repos?

**Reference answer:** A module at modules/<name>/index.md with frontmatter; once extracted there, agents/_shared, templates/_shared and prompts reference it rather than duplicating the rule.

### P02-R1

The canonical home is **`modules/<name>/index.md`** in the `agentic_optimization_research` repo — Chris's portable instruction-module system (spec: `roadmap/03-instruction-modules.md`).

The rule: once a cross-repo guardrail/behavior is extracted into a module, every other repo (vault, project CLAUDE.md files, templates, etc.) *references* that module rather than restating or duplicating the rule. Modules are versioned there and vendored into consuming repos via `install-modules.sh` / `/bootstrap-repo`. Examples already in use: `git-flow-session-end`, `session-handoff`.

### P02-R2

The canonical home for a portable instruction rule shared across roles/repos is a **module** — `modules/<name>/index.md` in the `agentic_optimization_research` repo.

The convention (per that repo's `CLAUDE.md`, house rule #6): once a rule is extracted into a module, everything else — other repos, `CLAUDE.md` files, skills, etc. — *references* it rather than duplicating the text. This is the "vendoring" model: host repos pull the module in (e.g. via `/bootstrap-repo`), but GitHub's `agentic_optimization_research` repo stays the single source of truth. The same reference-not-copy idea applies inside `templates/_shared/` for shared snippets.

### P02-R3

The canonical home is `modules/<name>/index.md` in the **agentic_optimization_research** repo.

Per that repo's `CLAUDE.md`: "Modules are canonical for portable rules (`modules/<name>/index.md`...): once extracted, everything else references the module, never duplicates it." The vault's `CLAUDE.md` echoes this: "a cross-repo guardrail's rule lives in its module; everything else references it."

So the pattern is: write the rule once in its module, and every consuming repo (vault, host repos, templates) links/references it rather than restating it. Examples already in use: `git-flow-session-end` and `session-handoff` are both vendored/referenced this way rather than copied.

## P03 — How does the H2 experiment stop the agent from re-reading a file it already read?

**Reference answer:** A PreToolUse hook on Read tracks per-session reads and blocks (exit 2) a redundant re-read of a file already read and not modified since via Edit/Write/MultiEdit; a legitimate post-edit re-read is allowed.

### P03-R1

## H2 mechanism: `pre_read_guard.py` (PreToolUse hook)

It's a **PreToolUse hook** (part of the `no-cat-head-via-bash` module, code at `modules/no-cat-head-via-bash/pre_read_guard.py`, canonical copy under `case-studies/.../experiments/h2-re-read-collapse/tool/`) that intercepts `Read`/`Edit`/`Write`/`MultiEdit` calls and tracks per-session file state.

**Core logic:**
1. It keeps per-session JSON state at `~/.cache/agentic_metrics/h2-re-read-tracker/<session_id>.json`, recording for each file path: number of reads, whether it's been modified since the last read, and the mtime at read-time.
2. On a `Read` call: if the file was already read in this session **and** hasn't been modified since (no tracked `Edit`/`Write`/`MultiEdit`), it **exits code 2** (blocks the tool call) with a stderr message telling the agent the content is already in context and to refer to it instead.
3. `Edit`/`Write`/`MultiEdit` calls mark the file `modified_since_read = True`, so the *next* Read after an edit is allowed (legitimate post-edit re-read).

**Two false-positive guards baked in** (added after a 2026-06-11 audit found ~47% spurious blocks):
- **mtime check**: if the file's current mtime is newer than the mtime recorded at read-time, treat it as an external edit (IDE, git, another process) and allow the re-read rather than block.
- **Transcript verification (`_executed_read_in_session`)**: since state is keyed by `session_id` and survives `--resume`/`--continue`, stale state could block a read the current run never actually performed. Before blocking, it scans the session transcript for a `Read` `tool_use` of that exact file with a matching non-error `tool_result`. It only blocks on positive confirmation — otherwise it reseeds state and allows the read.

The hook **fails open** everywhere else (malformed payload, I/O errors, exceptions all return exit 0/allow) — blocking is reserved strictly for the confirmed redundant-re-read case. It can be disabled per-session via `H2_REREAD_GUARD_DISABLED=1`.

Per my memory, this was re-measured post-fix on 2026-08-01: 0 of 107 blocks were spurious across both machines, so the block log is currently trusted as a clean "saved re-read" signal (~2.2 saved re-reads per active session).

### P03-R2

## H2 mechanism: a `PreToolUse` hook on `Read`

H2 (`case-studies/agentic-optimization-research/experiments/h2-re-read-collapse/`) uses a small stdlib-only Python script, `tool/pre_read_guard.py`, wired as a **PreToolUse** hook matching `Read|Edit|Write|MultiEdit`. It maintains per-session state at `~/.cache/agentic_metrics/h2-re-read-tracker/<session_id>.json`:

```json
{
  "files": {
    "/abs/path/file.md": { "reads": 1, "modified_since_read": false }
  }
}
```

**Decision logic per tool call:**
- `Read` on a file already recorded as read *and not modified since* → **hard block**: hook exits 2 with a `BLOCKED:` stderr message, the tool call never executes.
- `Read` on a new file, or one flagged modified → record it and allow.
- `Edit`/`Write`/`MultiEdit` → mark that file `modified_since_read: true`, always allow (so a legitimate post-edit re-read isn't blocked).
- Everything else → no-op.

It's a **hard block**, not a soft reminder, because the pre-obsidian baseline showed the agent ignores Claude Code's existing "file already in context" system reminder and re-reads anyway — the experiment tested whether a stronger intervention (deny the tool call) would actually change behavior.

**Two refinements it needed to be trustworthy:**
1. **mtime check** — it records each file's mtime at read time and permits a re-read if the mtime has since advanced, so external edits (editor saves, `git pull`) aren't mistaken for redundant re-reads.
2. **Positive confirmation via transcript scan** (landed 2026-06-11) — before blocking, it scans the session's `transcript_path` for an actual executed `Read` `tool_use`/`tool_result` of that exact file in *this* session, via `_executed_read_in_session`. This fixed a false-positive bug where `--resume`/`--continue` sessions reused a `session_id` and carried over stale state, blocking first-ever reads.

There's also an escape hatch, `H2_REREAD_GUARD_DISABLED=1`, for debugging the hook itself. It fails open on any internal error (exit 0), and it doesn't catch `Bash(cat file)` workarounds — that gap is targeted separately by the bundled `no-cat-head-via-bash` module.

**Outcome:** partially confirmed → after the FP fix, the 2026-08-01 post-fix audit found 0/107 spurious blocks over 7 weeks, so the block log is now a trustworthy signal (~2.2 saved re-reads per active session). The hook stays on in production.

### P03-R3

## The mechanism (`pre_read_guard.py`, part of the `no-cat-head-via-bash` module)

It's a **`PreToolUse` hook** that fires on `Read`/`Edit`/`Write`/`MultiEdit` calls, with per-session state at `~/.cache/agentic_metrics/h2-re-read-tracker/<session_id>.json`:

1. **On `Read`**: if the hook has already recorded a read of that `file_path` in this session, and no `Edit`/`Write`/`MultiEdit` has touched it since, it **exits code 2** (blocks the tool call) with a stderr message telling the agent the content is already in context — refer back to it instead of re-reading.
2. **On `Edit`/`Write`/`MultiEdit`**: marks the file `modified_since_read = True`, so the *next* Read of it is allowed (legitimate post-edit re-read).
3. Two safety checks before it actually blocks:
   - **mtime check** — if the file's on-disk mtime is newer than what was recorded at read-time (an external edit outside the tracked tools — IDE, another process, git), it allows the re-read rather than blocking, to avoid deadlocking against the harness's own edit-freshness check.
   - **Transcript confirmation** (`_executed_read_in_session`) — before blocking, it verifies against the actual session transcript that *this* run really executed a Read of the file (a `Read` `tool_use` with a matching non-error `tool_result`). This exists because state is keyed by `session_id`, which persists across `--resume`/`--continue`; without this check, stale state could block a file the current run never actually loaded. It only blocks on positive proof — everything else (no transcript, unparseable, not found) fails open.
4. **Escape hatch**: `H2_REREAD_GUARD_DISABLED=1` in the launching shell disables it for that session.

This was the source of the false-positive saga in your memory (`h2-hook-false-positive-rate.md`): the transcript-confirmation step (#3) was added 2026-06-11 specifically to fix a ~47% spurious-block rate from session-id carryover, and a 2026-08-01 re-audit confirmed 0/107 blocks were spurious post-fix.

## P04 — What's the retrieval approach behind the H1 bash-grep-replacement tool, and is it lexical or semantic?

**Reference answer:** search_docs is a BM25 (lexical, not semantic) MCP stdio server over the repo's markdown, chunked by H1/H2 headings; it's meant to replace Bash grep for topic lookups.

### P04-R1

Confirmed by `tools/search-docs/search_docs/bm25.py` — the H1 tool (the `search_docs` MCP server that replaces ad-hoc grep for rule/doc lookup) is built on **BM25**, a pure lexical/keyword-matching algorithm (term-frequency/inverse-document-frequency over the markdown corpus). It's not semantic — no embeddings, no vector similarity.

That's the opposite end of the spectrum from the H3 session-log-retrieval work in this same repo, which is a semantic/dense-embedding approach (`bge-small` vectors via `rebuild_index.py`). H1 = lexical BM25 for doc/rule lookup; H3 = semantic embeddings for session-log retrieval — two different hypotheses being tested with two different retrieval strategies.

### P04-R2

Confirmed by the file `search_docs/bm25.py` — this is BM25, a **lexical** (term-frequency/inverse-document-frequency) retrieval algorithm, not semantic/embedding-based.

**H1's tool**: `mcp__search_docs__search`, an MCP server (`tools/search-docs/`) that indexes the repo's markdown corpus and ranks matches with **BM25** — classic keyword/term-overlap scoring, no embeddings involved. It's meant to replace ad-hoc `grep`/`rg` for topic-based rule/doc lookup (literal-string and code searches still go through `Grep`), reinforced by a PreToolUse grep-nudge hook.

This is distinct from the H3 work on your current branch (`feat/h3-comparison-run`), which is dense/**semantic** retrieval via embeddings (`bge-small`) over session logs — a different hypothesis and a different corpus (session transcripts, not the docs library).

### P04-R3

The H1 tool is **`search_docs`** (`mcp__search_docs__search`), a BM25-based MCP server that indexes the repo's markdown corpus — it's **lexical**, not semantic.

Key details from your setup:
- It replaces ad-hoc `grep`/`rg` for rule and doc lookup by topic — literal-string and code searches still go through `Grep`/`rg` directly.
- BM25 is a sparse/lexical scoring algorithm (term-frequency + inverse-document-frequency over tokenized text), not embeddings — no vector index, no dense retrieval.
- A `PreToolUse` hook nudges the model toward `search_docs` instead of grep when the query looks topical rather than literal, via the non-blocking `additionalContext` channel on stdout.
- Lives at `tools/search-docs/` in `agentic_optimization_research`.

This is the deliberate contrast with **H3** (the session-log-retrieval spike), which is dense/semantic — embeddings via `bge-small`, snapshotted to `bge-small.npy` + `chunks.jsonl`. H1 and H3 are two different retrieval experiments in your research: H1 lexical (BM25) for doc/rule lookup, H3 semantic (embeddings) for session-log Q&A, with the §6.3 comparison run (your current branch, `feat/h3-comparison-run`) set up to evaluate H3 against a baseline.

## P05 — Why is `gh pr merge` denied in this repo's settings, and how is a PR supposed to land?

**Reference answer:** The human merge in the GitHub UI is the safety gate, so the agent is denied gh pr merge; the agent opens the PR, asks whether it merged, and only syncs main after verifying state == MERGED.

### P05-R1

Because Chris's git-flow convention keeps merge authority human-only: he merges PRs himself in the GitHub UI, not via CLI/agent. That's stated explicitly in this repo's `CLAUDE.md`:

> `.claude/settings.json` allows the day-to-day autonomy commands and denies remote-`main` mutation, destructive ops, paths outside the repo, and `gh pr merge` — a task needing a denied command is a chat discussion, not a deny-list edit.

And under session shape: "Chris merges in the GitHub UI." My memory backs this up too — the `feedback_auto_commit_and_pr_on_branch_done` entry notes "the human-merge gate is the real safety," and `feedback_ask_merged_via_popup` says the agent should ask whether the PR was merged (via popup) rather than merging it or assuming so.

So the flow is: agent commits, pushes, opens the PR, then stops and asks Chris (via the wrap-up popup) — Chris clicks merge in GitHub himself. It's a deliberate one-way authority split, not an oversight, and per the repo's own guidance a denied command like this is meant to be raised in conversation rather than edited around in the deny-list.

### P05-R2

`gh pr merge` is denied in this repo's `.claude/settings.json` because Chris merges every PR himself in the GitHub UI — that's a deliberate house rule, not an oversight. The workflow (per the git-flow-session-end module, run via `/session-wrapup`) is: branch → verify → docs sync → open the PR → then a "merge popup" step asks Chris to confirm it's merged in the UI → verify-merged → cleanup → session summary.

The settings file allows day-to-day autonomy (branching, committing, opening PRs) but denies remote-`main` mutation, destructive ops, paths outside the repo, and `gh pr merge` specifically. If a task seems to need one of those denied commands, the convention is to raise it as a chat discussion with Chris rather than edit the deny-list yourself.

### P05-R3

`gh pr merge` is deny-listed by design, not oversight — `.claude/settings.json` line 157 blocks it, and the config's own `_comment_purpose` spells out why: *"PR merges happen manually in the GitHub UI; this config intentionally denies `gh pr merge` so the human stays in the loop."*

This matches the project `CLAUDE.md` convention: **Chris merges every PR himself in the GitHub UI.** The agent's job stops at `gh pr create` (which *is* allowed); everything after — review, merge, cleanup — is Chris's call, since merging to `main` is a hard-to-reverse, shared-state action. The session-wrapup flow closes the loop by asking Chris "merged?" via a popup (never just ending the turn in prose) rather than assuming or forcing the merge itself.

## P06 — How does Hermes API cost get into the warehouse given it's an individual (non-Org) account?

**Reference answer:** The Admin-API billing-sync is parked (Org-only); the live path is a manual Anthropic Console CSV export loaded via `warehouse billing-import --kind usage|cost --csv`, nudged by a monthly ops Telegram reminder.

### P06-R1

Because Chris's Anthropic account is an **individual account, not an Org**, the Admin API (which would allow automated billing pulls) isn't available — you can't mint an `sk-ant-admin…` key, so the automated `billing-sync` puller in `metrics/warehouse/warehouse/anthropic_billing.py` stays dormant (correct code, just unused).

Instead, cost gets in via a **manual CSV export path** (built 2026-05-31, PR #68):

1. Chris periodically exports two CSVs from the Anthropic Console:
   - **Usage CSV** (`claude_api_tokens_*.csv`) — uses API model IDs, carries `api_key` (lights up the leak-detection lens) → loads into `anthropic_usage`.
   - **Cost CSV** (`claude_api_cost_*.csv`) — uses **display-name** models (e.g. "Claude Opus 4.7", needs `model_aliases` rows) and reports `cost_usd` in **dollars**, not cents (opposite convention from the Admin path) → loads into `anthropic_cost`.
2. He runs `uv run warehouse billing-import --kind usage|cost --csv <file>` (per [[warehouse-billing-import-invocation]] memory) into the **same** tables the automated path would have used, so downstream views (`anthropic_spend_by_key`, `cost_reconciliation`) are unaffected by which path fed them.
3. There's a designed-but-not-yet-built monthly Telegram reminder (host systemd timer on the Pi/ms01, via the ops `notify_telegram` helper) to nudge Chris to actually do the export — this is the one still-open piece of that ops reminder.

One nuance: even if the Admin API were ever available, `billing-sync` is designed to run **laptop-side only** — an admin key must never live on the Pi/ms01, since Hermes's dashboard stores keys and is auth-less.

### P06-R2

Since Chris's Anthropic account is an **individual account, not an Org**, the Admin API (which would let an `sk-ant-admin…` key auto-pull billing data) isn't available — so the automated puller (`billing-sync` in `metrics/warehouse/warehouse/anthropic_billing.py`) exists in the codebase but is **dormant**, and Chris deliberately chose not to set up an Org to unlock it.

The actual cost path is manual:

1. **Export two CSVs from the Anthropic Console** — Usage CSV (`claude_api_tokens_*.csv`) and Cost CSV (`claude_api_cost_*.csv`). They have different shapes: Usage uses raw API model IDs and carries `api_key` (so per-key leak tracking works); Cost uses display-name models (e.g. "Claude Opus 4.7", requiring `model_aliases` rows) and reports `cost_usd` in **dollars**, not cents (opposite of the Admin-API path, which is in cents).
2. **Load them via the built importer**: `warehouse billing-import --kind usage|cost --csv <file>` (shipped in PR #68, 2026-05-31), which writes into the same `anthropic_usage`/`anthropic_cost` tables the dormant Admin-API path would have used, so downstream views didn't need to change.
3. This is a **monthly manual chore** — there's a designed-but-maybe-not-yet-built ops reminder (`hermes-ops-billing-reminder`, a host systemd timer that Telegram-nudges Chris to run the export) since there's no agent cron path (ops has no gateway to run one).

Two related memory notes worth knowing: `billing-sync`, if ever revived, would have to run laptop-side, not on the Pi (an admin key must never live on the Pi since Hermes's dashboard is auth-less and stores keys). Also, the Console can emit split line items sharing the same dimensional key (e.g. real $0.02 + $1.17 Haiku-output split on 2026-05-29) — the importer's `_aggregate()` sums them intentionally, since a naive per-row hashed-key upsert would drop one.

Note: this reflects a decision from 2026-05-30/31 (~80 days old) — worth a quick check that `billing-import` still behaves this way if you're about to rely on it for something consequential.

### P06-R3

Because Hermes runs under an individual Anthropic account (not an Org account), the Admin API isn't available, so there's no automated cost-ingest path. The cost data instead flows in manually: Chris exports the usage/cost CSV from the Anthropic Console, then runs the warehouse's `billing-import` command to load it in. There's also a monthly ops reminder pinged via Telegram so this doesn't get missed.

Relatedly, because that billing data isn't live/automated, Hermes self-prices its own API usage in the interim (tracked in `state.db`) rather than relying on the warehouse import for real-time cost figures — worth noting there was also a dated-Haiku pricing bug in that self-pricing path that had to be corrected for.

## P07 — What are the Hermes profiles and which one can run scheduled crons?

**Reference answer:** Five profiles (pm, coding, research, ops, writing). The scheduler is bundled in the gateway, and only a messaging-enabled profile (pm) has a live gateway — so only pm can run crons; workers can't self-schedule.

### P07-R1

Found it — the memory system has a clear, well-documented answer to this.

## Hermes profiles

Five profiles: **pm, coding, ops, research, writing** (each gets its own `~/.hermes/profiles/<profile>/state.db`; `writing` has historically had near-zero activity).

## Which one can run scheduled crons: **`pm`**

The cron scheduler is bundled *inside the gateway process* (banner literally reads "Messaging platforms + cron scheduler"). A gateway only stays running for a profile with an **enabled messaging platform** — and per the Hermes design (HERMES_PLAN §7), only `pm` has messaging (Telegram) enabled. So:

- Every other profile has no live gateway → no scheduler → crons never fire, not on schedule and not even via manual `hermes -p <profile> cron run` (it just enqueues to a tick that never arrives).
- Verified live on the Pi (2026-05-29) via `hermes gateway list` — only `pm` showed up.

**Consequence for workers:** a worker profile (coding/ops/research) can't self-schedule. The two supported patterns are:
1. **Host-level scheduling** — a systemd timer on the Pi, used for things like ops maintenance (docker-parity checks, pg backup) that write status files `pm` later reads and relays to Telegram.
2. **`pm`-owned cron that delegates** — `pm` schedules the job and dispatches it to a worker via `kanban_create(assignee=<profile>)` (the real profile-dispatch mechanism — `delegate_task` does *not* work for this, since it spawns a generic child with no profile, skills, or memory loaded).

Worth flagging: these memories are ~80 days old (dated late May/early June, current date is 2026-08-19), so if you're about to act on this — e.g. wiring a new scheduled job — I'd verify against `~/.hermes/config.yaml` and `hermes gateway list` on the Pi first rather than trusting this as current state.

### P07-R2

Hermes runs **five profiles**: `pm`, `research`, `coding`, `writing`, and `ops` (defined in `agents/hermes/HERMES_PLAN.md`).

**Only `pm` can run scheduled crons.** The cron scheduler is bundled into the gateway process itself, and a gateway only stays running for a profile with an enabled messaging platform — `pm` is the only profile with messaging enabled (Telegram originally, Discord since the July 2026 ms01 move). The other four profiles have messaging disabled by design, so they have no running gateway and thus no scheduler: their crons never fire, whether on schedule or via a manual `hermes -p <profile> cron run` (which just enqueues to a tick that never arrives). This was verified live on the Pi 2026-05-29 (`hermes gateway list` showed only `pm` as live) and killed an earlier "ops in-container cron" design.

The workaround for scheduling a worker's job: either move it to the **host** as a systemd timer (what `ops`'s maintenance jobs do), or make it a **`pm` cron that dispatches to the worker** via a kanban card (`pm` can schedule itself; it just can't directly schedule another profile's own gateway).

### P07-R3

I have the full answer now from `agents/hermes/HERMES_PLAN.md`.

**The five Hermes profiles:**

1. **`pm`** — owns the Telegram chat; classifies incoming requests and dispatches work to worker profiles via `/kanban create --assignee <profile>`. Never writes code.
2. **`research`** — repo reads + literature review.
3. **`coding`** — code changes + PRs.
4. **`writing`** — docs/READMEs/blog content.
5. **`ops`** — Pi/Docker/backups, host status checks.

**Only `pm` can run scheduled crons.** The reason is structural, not a config choice: Hermes bundles the cron scheduler *into the gateway process* ("Messaging platforms + cron scheduler"), and a gateway only stays alive for a profile with an **enabled messaging platform**. By design (§7 of HERMES_PLAN), `pm` is the only profile with Telegram enabled — every other profile has messaging disabled, so it has no running gateway and therefore no scheduler. A worker's cron never fires, whether on schedule or via manual `hermes -p <p> cron run` (verified on the Pi 2026-05-29: `hermes gateway list` showed only `pm` live).

The workaround for "a worker needs to run on a schedule" is one of two paths:
- **Host-level**: a systemd timer on the Pi itself (used for ops monitoring/alerting), or
- **`pm`-routed**: a `pm` cron that dispatches to the worker via kanban (`kanban_create(assignee=<profile>)`) — a worker can be *delegated to* on a schedule, but can't *schedule itself*.

One related gotcha worth flagging: `delegate_task` is **not** the dispatch mechanism to a real profile — it spawns a generic, memory-less child with no profile skills. The real profile-aware dispatch is `kanban_create(assignee=<profile>)`, proven live 2026-05-30.

## P08 — What does the modeled Hermes cost reconcile to against the billed key, and why don't we trust Hermes's own cost number?

**Reference answer:** Self-priced modeled cost reconciles to ~3.7% of the billed hermes-pi key; Hermes's own number is ~80% low because the dated-Haiku pricing bug reports $0 for every Haiku run, so the design self-prices the reliable token rollups instead.

### P08-R1

I have what's needed to answer directly from memory.

**Reconciliation result:** From the Phase C baseline run (2026-05-31, PR #72, covering 05-27–05-31 on the live Pi warehouse), the warehouse's self-priced/modeled cost came to **$21.53**, against the billed `hermes-pi` API key's actual **$20.77** — a **~3.7% gap**. That's close enough that the modeled-cost pipeline (token rollups × the warehouse's own `model_prices`) was judged trustworthy for per-run cost analysis.

**Why Hermes's own cost number isn't trusted:** Hermes self-reports `estimated_cost_usd` via `agent/usage_pricing.py`, which prices by an exact `(provider, model-string)` lookup. Its Haiku price-table entry uses the **undated** string `claude-haiku-4-5`, but Hermes actually records sessions under the **dated** `claude-haiku-4-5-20251001`, and the model-name normalizer strips the `anthropic/` prefix and dot-notation but *not* the trailing date suffix — so the lookup misses and every Haiku session self-reports `cost_status="unknown"` / **$0**. Since the fleet is Haiku-default, that means almost all of Hermes's self-reported cost is silently zeroed (the baseline run's $4.14 self-report total was just two early Opus-default runs, nowhere close to the real ~$20–21). Opus pricing was also inconsistently applied (correct 05-27, missed 05-28 due to a routing/env quirk).

Given that, the warehouse treats Hermes's own cost field only as a `hermes_*` comparison column, never as ground truth — it instead self-prices the *reliable* token-count rollups from each profile's `state.db` against the warehouse's own `model_prices` table, and validates that against the real Anthropic Console billing export (the actual $ on the `ANTHROPIC_API_KEY` powering Hermes). This bug was root-caused and write-up'd for a possible upstream report to Nous Research, but Chris decided **2026-08-01 to close it as won't-file** (not wanting to add to the flood of AI-assisted OSS issues) — the self-pricing workaround is the permanent posture, not a stopgap.

One caveat carried in the same memory: Opus session cache-token rollups were flagged as possibly over-counting vs. billed (Haiku reconciled cleanly, Opus less certain) — that was noted as something to fix before fully trusting per-run Opus dollar figures, and I don't have a record of that being resolved.

### P08-R2

I have this from memory directly.

**Reconciliation result:** In the Phase C baseline run (PR #72, captured 2026-05-31, covering 05-27→05-31), the warehouse's self-priced modeled cost came to **$21.53**, against the billed `hermes-pi` API key's actual charge of **$20.77** — a gap of about **3.7%**. That's close enough to treat per-run modeled dollars as trustworthy.

**Why Hermes's own cost number is untrusted:** Hermes prices its own runs via `agent/usage_pricing.py`, which keys its price table on exact model strings. Its Haiku entry is the *undated* `claude-haiku-4-5`, but the sessions it's actually pricing use the *dated* `claude-haiku-4-5-20251001`. The model-name normalizer strips the `anthropic/` prefix and dot notation but never strips the trailing date suffix, so every Haiku session fails the price lookup and silently reports `cost_status="unknown"`, `$0`. Since Haiku is the fleet default (pm dominates and is Haiku-default), this meant almost all of Hermes's self-reported spend was wrong-low — the $4.14 Hermes self-reported for that baseline window was just two early Opus runs before the fleet defaulted to Haiku, not real total spend.

Because of that bug, the warehouse design keeps Hermes's `estimated_cost_usd` only as `hermes_*` comparison/gap columns and instead **self-prices the reliable token rollups** (from each profile's `state.db` `sessions` table) against its own `model_prices` table, then reconciles that modeled number against the real Anthropic Admin/Console billing export (Phase A) as ground truth — which is where the $21.53 vs $20.77 comparison came from.

One caveat still flagged from that same baseline: Opus session cache-token rollups were suspected to over-count vs billed (Haiku reconciled cleanly, Opus didn't), so per-run Opus dollar figures weren't yet fully trusted at that point — Haiku was the well-validated case.

Separately: this dated-Haiku bug was drafted as an upstream bug report for Nous Research but Chris closed it **won't-file** on 2026-08-01 (doesn't want to add to the flood of AI-assisted issues on OSS repos) — the self-pricing workaround in the warehouse is the permanent fix, not a stopgap.

### P08-R3

Found the exact reconciliation figure in the `hermes-statedb-phase-b` memory (Phase C baseline, PR #72, 2026-05-31).

**The reconciliation:** self-priced modeled cost = **$21.53** vs. billed `hermes-pi` key = **$20.77**, over the window 05-27→05-31 — a gap of about **3.7%**. That's close enough that the warehouse team treated per-run modeled $ as trustworthy.

**Why Hermes's own cost number isn't trusted:** a pricing bug in Hermes's own `agent/usage_pricing.py`. It keys its price table on the *undated* model string `claude-haiku-4-5`, but every Haiku session in `state.db` actually records the *dated* string `claude-haiku-4-5-20251001`. `_normalize_anthropic_model_name` strips the `anthropic/` prefix and dot notation but never strips the trailing date suffix, so the lookup misses for every Haiku run → `cost_status="unknown"`, `cost_source="none"`, self-reported `$0`. Since Haiku is the fleet default, this silently zeroed out the vast majority of Hermes's own cost accounting (the Phase C baseline's self-reported total was only $4.14 — just two early Opus default runs). Opus 4.7 pricing was separately broken on 05-28 for an unrelated reason (empty `ANTHROPIC_TOKEN` routed it to a non-`anthropic` provider).

Because the *token counts* in `state.db` are reliable even though Hermes's self-priced dollar figure isn't, the warehouse instead ingests raw tokens and prices them itself against `model_prices` (its own rate table), keeping Hermes's `estimated_cost_usd` only as a `hermes_*` comparison column — never as the source of truth. This self-pricing workaround was later made permanent: Chris decided not to file the bug upstream with Nous Research (closed won't-file, 2026-08-01) to avoid adding to the flood of AI-assisted issues on OSS repos; the analysis is preserved in `agents/hermes/UPSTREAM_BUGS.md`.

## P09 — Where does the cost leak from Hermes 'spending while idle' come from, and how was it fixed?

**Reference answer:** An hourly pm pr-await-merge-reminder LLM cron (~$70/mo pm cron class, ~92% that one job) was the unattended spend; it was paused then rebuilt as a zero-LLM-cost agentless host systemd timer that pings Telegram only when the await-merge PR set changes.

### P09-R1

## The Hermes idle-spend leak

**Source:** The pm profile's own scheduler — specifically the **hourly `pr-await-merge-reminder` cron** (job id `8e49d7292050`, running every hour via `0 * * * *` as a full LLM agent job). Each fire spawned sub-sessions and reloaded the pm context (MEMORY.md + system prompt) even when there was nothing to report — a NOOP "no stale PRs" check burning input/output/cache tokens 24×/day. Self-priced from the profile's `state.db` (since the stored cost columns read $0 due to a separate Haiku pricing bug), this alone came to **~$70/month (~$2.40/day)** and accounted for ~92% of the agent-cron fires.

**Fix (2026-06-01, PR #74 then #75):**
1. **Paused first** (2026-05-31) via `docker exec hermes hermes cron pause 8e49d7292050` as an immediate stop-gap.
2. **Replaced entirely** with an *agentless* host systemd timer — `pr-await-merge-reminder.sh` + `hermes-ops-pr-reminder.{service,timer}` — which just shells `gh search prs` and pings Telegram only when the PR set changes. Zero LLM invocation. The old cron job was then `cron remove`d for good.
3. **Audited the remaining pm crons** and found the two daily LLM crons (`roadmap-daily-sync`, `workstream-status-nudge`) had *never actually worked* — cron sandbox disables the agent memory store, so they either errored or hallucinated. Chris had both removed too.

End state: the pm profile runs **zero LLM crons**. This became the project's standing default — cheap deterministic gate, escalate to an LLM only on a real signal (see the `default-agentless-gate-pattern` memory). Lesson baked in: a green `last_status: ok` only proves the run didn't crash, not that it did anything useful — audit actual cron output before trusting it.

### P09-R2

## The leak

The idle-cost leak was Hermes's **pm profile scheduler crons**, dominated by an **hourly** `pr-await-merge-reminder` job (`0 * * * *`). Each fire spawned an agent/LLM session that reloaded the pm's full context (MEMORY.md + system prompt) just to check "any stale PRs?" — a NOOP result still burned input/output/cache tokens 24×/day. Self-priced from the per-profile `state.db` sessions table (Haiku rates, since state.db's own cost columns read $0 due to a pricing bug), it came out to **~$70/month (~$2.4/day)** across ~300 cron sessions in 3 days, with that hourly job responsible for ~92% of agent-cron fires.

## The fix

Two-stage, both merged:

1. **2026-05-31** — paused the hourly job (`docker exec hermes hermes cron pause 8e49d7292050`) as an immediate stop-gap.
2. **2026-06-01, PR #74** — replaced it with a fully **agentless host systemd timer**: a shell script (`pr-await-merge-reminder.sh` + a `.service`/`.timer` pair) that runs `gh search prs` and pings Telegram directly, only when the open-PR set changes. Zero LLM invocation. The old cron job was `cron remove`d entirely.

While auditing, two other daily pm crons (`roadmap-daily-sync`, `workstream-status-nudge`) turned out to have **never worked** — the cron sandbox disables agent memory, so every run silently emitted "memory is not available" or hallucinated content despite reporting `status: ok`. Chris had them removed too (PR #75, 2026-06-01), leaving the pm profile with **zero LLM crons**.

This became the project's standing default going forward: cheap deterministic checks run as host-level agentless jobs, and an LLM agent is only invoked on a real signal — captured as the [default-agentless-gate-pattern](default-agentless-gate-pattern.md) memory.

### P09-R3

## The Hermes idle-spend leak (found 2026-05-31)

**Root cause:** the `pm` profile's scheduler had LLM-backed cron jobs firing on their own, dominated by an **hourly** `pr-await-merge-reminder` job (`0 * * * *`). Each fire spawned a full agent sub-session that reloaded the pm's memory/system prompt just to check for stale PRs — so even a NOOP "nothing to report" run burned input+output+cache tokens, 24×/day. Self-priced from `state.db` (Haiku 4.5 rates), this one cron alone was **~$70/month (~$2.4/day)** across ~300 sessions in 3 days — roughly 92% of all agent-cron fires.

**Fix, in two stages:**
1. **2026-05-31** — immediately paused the offending job via `docker exec hermes hermes cron pause 8e49d7292050` as a stopgap.
2. **2026-06-01 (PR #74)** — replaced it with an **agentless host systemd timer** instead of an LLM cron: a plain shell script (`pr-await-merge-reminder.sh` + a systemd `.service`/`.timer` pair) that runs `gh search prs` and pings Telegram directly, with zero LLM invocation. The old LLM cron job was `cron remove`d permanently.

While auditing, the same pass found the two remaining daily LLM crons (`roadmap-daily-sync`, `workstream-status-nudge`) had actually **never worked** — cron sessions can't access agent memory, so every run just emitted "memory is not available." Chris had those removed too rather than rebuilt. Net result: the `pm` profile now runs **zero LLM crons**.

This became the template for how background/scheduled work should be built going forward: a cheap deterministic check by default, with an LLM only invoked on a real signal — captured as the "default agentless-gate pattern."

## P10 — What's the project's default design pattern for recurring background work?

**Reference answer:** A cheap deterministic 'agentless gate', escalating to an LLM agent only on a real signal — the inverse anti-pattern is scheduling an LLM agent to poll for a deterministic condition.

### P10-R1

The default is the **agentless-gate pattern**: use a cheap, deterministic gate (script/check) to filter for a real signal, and only escalate to an LLM agent when that signal actually fires — rather than running an agent on every tick.

This was driven home by the Hermes cron cost leak incident: a pm agent's hourly `pr-await-merge-reminder` cron was burning ~$70/mo by invoking an LLM on every poll, even when idle. It was paused 2026-05-31 and rebuilt agentless (deterministic check) on 2026-06-01.

### P10-R2

The default is **"agentless gate, escalate-to-agent only on signal"**: recurring/scheduled work should run through a cheap, deterministic check (shell script, SQL, `gh`/`curl`) on a host scheduler for free, and only invoke an actual LLM agent when that check surfaces a real signal needing judgment. If the outcome is just a notification, skip the agent entirely. Unchanged conditions should dedupe rather than re-firing.

**Why:** Chris set this as the explicit default on 2026-06-01 after Hermes' always-on hourly PR-reminder LLM cron cost ~$60–66/mo for a job that was almost always a no-op — an always-on agent bills whether or not there's real work, and since no human is present to notice, the spend hides.

Canonical write-up: `playbook/03-design-patterns.md` pattern 8 (inverse documented as anti-pattern #14 in `07-anti-patterns.md`), with the Hermes ops host-timer bundle as the reference implementation.

### P10-R3

The default is the **agentless gate pattern**: a cheap, deterministic check (cron/script/threshold) handles the recurring work, and an LLM agent only gets invoked when that gate trips on a real signal — not on every tick.

This came out of the Hermes cron cost leak incident (a pm profile's hourly `pr-await-merge-reminder` cron was running a full agent every hour just to check PR status, costing ~$70/mo for mostly-idle checks). It was paused 2026-05-31 and rebuilt "agentless" on 2026-06-01. That incident is what generalized into the standing default for any new background/recurring work in this project.

## P11 — How does the embedding-cost spike decide whether to ship v0 with bge-small?

**Reference answer:** Pass criteria on the laptop: bge-small wall-clock <= 5 min, resulting .npy <= 50 MB, peak RSS <= 2 GB; if any threshold fails, the alternative model is motivated by the recorded numbers.

### P11-R1

The spike (run 2026-08-02 on ms01, documented in `case-studies/agentic-optimization-research/experiments/h3-session-log-retrieval/tool/spike_results.md`) judged bge-small against three pre-registered pass criteria from README §5:

- wall-clock ≤ 5 min (300s)
- `.npy` index size ≤ 50 MB
- peak RSS ≤ 2 GB

**Results on the 25K-turn corpus:** bge-small passed 2 of 3 — 36.6 MB `.npy` and 1.7 GB peak RSS — but wall-clock came in at 866s (~14.4 min), well over the 300s bar.

**Why it shipped anyway:** the 300s bar was calibrated against the much smaller June corpus (7K turns), and the corpus had grown ~3.5× by the time of the run. Reframed as per-turn throughput (~29 turns/s), that rate was judged fine — the *absolute* wall-clock target was stale, not the model's actual performance. The tradeoff was accepted with a concrete consequence: rebuild-on-start is ruled out, making the README §6 incremental indexer (keyed on `session_id, seq`) a hard prerequisite for v1.

**The alternative (nomic-embed) made the decision easier:** it was disqualified by extrapolation rather than completed — after 80 min it had only processed 21/781 batches, projecting to ~31 hours on that CPU, and its 768-dim output would have blown the 50 MB size bar too (~77 MB). So it wasn't a close call between two viable options; bge-small was the only model that cleared size/RSS at all, and its wall-clock miss was judged a stale-baseline artifact rather than disqualifying.

### P11-R2

The spike (`tool/spike_results.md`, run 2026-08-02 on ms01) used three pre-registered pass criteria from README §5, benchmarked against the actual 25K-turn warehouse corpus:

1. **Wall-clock** ≤ 5 min (300 s)
2. **Index size** (`.npy`) ≤ 50 MB
3. **Peak RSS** ≤ 2 GB

**bge-small results:** 36.6 MB index (pass), 1.7 GB peak RSS (pass), but 866 s wall-clock — nearly 3x over the 300 s bar (fail on paper).

**Decision logic — shipped anyway, with a caveat:** the wall-clock bar had been calibrated against the much smaller June corpus (7K turns); at ~29 turns/sec, bge-small's *per-turn* throughput was judged fine, and the 3.5x corpus growth (live ingest during the run) was the real cause of the miss, not the model. So the verdict was "chosen" but with an explicit consequence: rebuild-on-start is ruled out, and an incremental indexer (README §6) became a hard v1 prerequisite rather than a nice-to-have.

**The comparison that sealed it:** `nomic-embed` was run alongside it and disqualified by extrapolation — after 80 min it had only reached batch 21/781, projecting to ~31 hours on that CPU, and its 768-dim output would have blown the 50 MB size bar too (~77 MB). It wasn't worth completing. So the choice wasn't "bge-small cleanly passed" — it was "bge-small failed one soft-contextualized criterion; the alternative failed catastrophically," making bge-small the only viable v0 candidate.

One more wrinkle from that run: the pre-registered BM25 smoke set regressed 5/5 (June) → 0/5 on the grown corpus, which is why the next step (§6.3 comparison harness) has to exclude the in-flight session and treat smoke-query re-curation as a versioned amendment rather than a silent edit — noted in your `next-session.md` as design input for the branch you're currently on (`feat/h3-comparison-run`).

### P11-R3

The spike compared two candidate embedding models against three pre-set pass criteria (README §5): wall-clock ≤ 5 min (300s), `.npy` index size ≤ 50 MB, and peak RSS ≤ 2 GB — run against the live warehouse corpus on ms01 (24,997 turns, 30.5 MB text).

**Results (2026-08-02, reproduced across two runs):**

| Model | Wall-clock | .npy size | Peak RSS |
|---|---|---|---|
| `bge-small-en-v1.5` | 866 s (~14.4 min) | 36.6 MB ✅ | 1.7 GB ✅ |
| `nomic-embed` | ~31 h (extrapolated, killed early) | ~77 MB ❌ | — |

**Decision logic:**
- **bge-small** passed 2 of 3 bars (size, memory) and failed only wall-clock — but that 300s bar had been set against the much smaller June corpus (7K turns); at ~29 turns/sec throughput, the failure is explained by corpus growth (3.5×), not the model being slow per-turn. That was judged an acceptable/expected miss rather than a disqualifier.
- **nomic-embed** was disqualified outright by extrapolation: it was still on batch 21/781 after 80 minutes (~145 s/batch), projecting to ~31 hours total — not worth even finishing the run — and its 768-dim vectors would have blown the size budget too (~77 MB vs 50 MB cap).

So it wasn't a strict "pass all three bars" gate — it was relative: bge-small was the only viable option, and its one failure (wall-clock) was explained away by corpus growth rather than treated as disqualifying. The real cost of that decision was pushed downstream: rebuild-on-start became infeasible, making the §6 incremental indexer a hard prerequisite for v1.

## P12 — Why is the Hermes concurrency throttle (max_concurrent_children=1, dispatch_interval=120s) set the way it is?

**Reference answer:** To stay under the Tier-1 50K-ITPM Haiku rate limit — the binding constraint on this account — trading dispatch latency for zero RateLimitErrors rather than bumping the tier.

### P12-R1

The throttle exists because Hermes hit an Anthropic rate-limit incident, not for load-management reasons.

**What happened:** On 2026-05-29, Anthropic emailed that the org had exceeded the Haiku rate limit 69× in 24 hours. Root cause was background-review jobs (`thread=bg-review`) firing large prompts to Haiku concurrently — Hermes defaults every profile to Haiku, and the Pi-hosted account is Individual/Tier-1, where the binding constraint is Haiku 4.5's 50,000 input-tokens-per-minute limit.

**The fix, and why these specific values:** rather than pay the ~$40 credit to bump the account tier, Chris chose to throttle concurrency instead. His reasoning: bumping the tier only moves the ceiling — a runaway fan-out would just re-breach the new limit and cost more. So the config was set to:
- `delegation.max_concurrent_children: 1`
- `kanban.auto_decompose_per_tick: 1`
- `kanban.dispatch_interval_seconds: 120`

This caps concurrent child spawns to one at a time and spaces dispatch out to every 120 seconds, keeping burst token volume under the per-minute cap.

One caveat: this memory is 82 days old (dated 2026-05-29 incident, session id `82369e46`), and the config lives in `~/.hermes/config.yaml` (not repo-tracked) — if you're about to change these values, worth verifying the current live config on the host rather than trusting this as still-current state.

### P12-R2

This was an incident fix, not an upfront design choice — here's the full story:

**What happened (2026-05-29):** Anthropic emailed Chris that his Hermes-agent account had exceeded the Haiku rate limit 69 times in 24 hours. Diagnosis from the Pi logs (`~/.hermes/logs`) traced the 429s to `thread=bg-review` background-review jobs — several large prompts firing at Haiku concurrently, defaulted to Haiku for every profile (`model.default` in `config.yaml`).

**Why it's set this way:** Chris's Anthropic account is Individual/**Tier-1**, where Haiku 4.5's binding ceiling is **50,000 input-tokens/minute**. The runaway fan-out from delegated/kanban-dispatched children was blowing through that ceiling. Chris's explicit call was to **throttle rather than spend** — bumping to a higher tier (a $40 credit) would only move the ceiling, and a future runaway fan-out would just re-breach the new one and cost more. Throttling fixes the root cause (concurrent burst volume) rather than papering over it with more headroom.

**The specific values**, changed in `~/.hermes/config.yaml`:
- `delegation.max_concurrent_children`: 3 → **1** (serialize delegated children so they can't fan out concurrently)
- `kanban.auto_decompose_per_tick`: 3 → 1
- `kanban.dispatch_interval_seconds`: 60 → **120** (slow the kanban dispatcher's spawn rate)

This was captured as experiment `h-hermes-2-concurrency-throttle` (case-studies), which frames the tradeoff explicitly: the throttle trades latency for zero 429s, and relaxing it (raising concurrency / lowering the interval) produces a measurable rise in 429s — so it's a deliberate, tested latency-for-reliability trade, not just a guess. It's documented in the host README (`hosts/ms01/hermes/README.md:370-377`) as a troubleshooting reference, since `config.yaml` itself isn't repo-tracked.

### P12-R3

That throttle was an incident response, not a design choice made in advance.

**What happened:** On 2026-05-29, Anthropic emailed that Chris's Hermes Pi deployment had exceeded the Haiku rate limit 69 times in 24 hours. Hermes runs on Chris's **Individual/Tier-1** Anthropic account, where Haiku 4.5's binding constraint is **50,000 input-tokens-per-minute**. Every Hermes profile defaults to Haiku (`model.default` in `~/.hermes/config.yaml`), and the root cause was background-review jobs (`thread=bg-review`) firing large prompts to Haiku concurrently — a fan-out burst that blew through the per-minute ceiling.

**Why throttle instead of upgrading the tier:** Chris's explicit call was to fix the actual bottleneck rather than pay to move the ceiling. A $40 tier-upgrade credit would have raised the limit, but a runaway fan-out would just re-breach the new ceiling too and cost more in the process. Throttling concurrency addresses the cause; buying headroom just delays the same failure.

**The fix**, applied directly in `config.yaml` (not repo-tracked):
- `delegation.max_concurrent_children: 1`
- `kanban.auto_decompose_per_tick: 1`
- `kanban.dispatch_interval_seconds: 120`

Together these cap how many child tasks can run at once and space out kanban dispatch ticks, so bursts of Haiku calls get serialized instead of fanning out in parallel.

**Standing guidance for next time:** if Hermes hits a Haiku 429 again, check `~/.hermes/logs/errors.log` for the `thread=` field to identify what's fanning out, and adjust concurrency/dispatch throttles in `config.yaml` first — don't reflexively bump the account tier.

One caveat: this memory is 82 days old (dated back to the 2026-05-29 incident), so treat the exact current values in `~/.hermes/config.yaml` as something to verify live if you're about to act on them rather than just explain the history.

## P13 — Why is the Hermes dashboard gated off by default?

**Reference answer:** Leaving it on caused an s6-log lock-contention crash loop, so the dashboard is on-demand / gated off by default.

### P13-R1

The Hermes dashboard is gated off by default (only started on-demand via `docker compose --profile dashboard up -d dashboard`) because of a **lock-contention crash loop**:

- The dashboard reuses the same gateway image and its `/init` (s6) entrypoint, and both the gateway and dashboard containers bind the same `~/.hermes:/opt/data` volume.
- Since there's no dashboard-only mode in the image (`container_boot.py` always reconciles the per-profile gateways on boot), running the dashboard as a second always-on container spun up a *duplicate* log-supervision tree.
- The two containers' `s6-log` processes then fought over the same `logs/gateways/<profile>/lock` files, throwing `s6-log: fatal: unable to lock …: Resource busy` and crash-looping at ~160k log lines/day.

This was discovered 2026-05-29 (while separately diagnosing the Haiku 429 rate-limit incident — an unrelated fault found at the same time) and fixed in PR #54 by gating the dashboard behind a Compose `profiles: [dashboard]` key in `hosts/ubuntu-pi-server/hermes/docker-compose.override.yml`, so the normal `hermes.service` systemd unit only ever starts the gateway.

Practical upshot: bring the dashboard up only when you need the web UI, reach it via `ssh -L 9119:localhost:9119` (localhost-only, no auth), and stop it again when done — leaving it running still re-contends on the locks (cosmetic log spam), even though it no longer duplicates actual gateway processes.

### P13-R2

The Hermes dashboard is gated off by default because running it as a second always-on container caused a log-lock contention crash loop.

**The mechanism:** the dashboard reuses the same gateway Docker image and its `/init` (s6) entrypoint as the main Hermes gateway container, and both bind the same `~/.hermes:/opt/data` volume. There's no dashboard-only mode in the image — `container_boot.py` always reconciles the per-profile gateways on boot. So an always-on dashboard container spun up a *duplicate* log-supervision tree, and its `s6-log` processes fought the main gateway's `s6-log` processes over the same `logs/gateways/<profile>/lock` files — throwing `s6-log: fatal: unable to lock …: Resource busy` and crash-looping at roughly 160k log lines/day.

**The fix (PR #54):** the dashboard is gated behind a Compose `profiles: [dashboard]` key in `docker-compose.override.yml`, so the default `docker compose up -d` / `hermes.service` systemd unit only starts the gateway. You launch it on-demand with `docker compose --profile dashboard up -d dashboard`, reach it via `ssh -L 9119:localhost:9119` (localhost-only, no auth), and stop it (`docker compose stop dashboard`) when done — leaving it running still re-contends on the locks (cosmetic spam, not duplicate gateway processes, but still worth avoiding).

This was discovered 2026-05-29 while diagnosing an unrelated Haiku 429 rate-limit incident — the two issues turned out to be independent.

Note: this memory is from a while back and references the older `hosts/ubuntu-pi-server/hermes/` path — per your memory index, that host directory was renamed to `hosts/ms01/hermes/` on 2026-08-01, so if you need the current file path, check there first.

### P13-R3

The Hermes dashboard is gated behind an on-demand Compose profile because running it as a second always-on container causes a lock-contention crash loop.

**Root cause:** The dashboard reuses the same gateway image and `s6`-based `/init` entrypoint as the main gateway container, and both containers bind the same `~/.hermes:/opt/data` volume. Since the image always boots a full per-profile gateway log-supervision tree (no dashboard-only mode exists in `container_boot.py`), running two always-on containers meant both tried to supervise the same log files — their `s6-log` processes fought over the same `logs/gateways/<profile>/lock` files, throwing `s6-log: fatal: unable to lock …: Resource busy` and crash-looping at ~160k log lines/day.

**Fix (PR #54, found 2026-05-29):** gate the dashboard behind a Compose `profiles: [dashboard]` key in the override file, so the default `docker compose up -d` / `hermes.service` systemd unit only starts the gateway. The dashboard is launched on-demand with `docker compose --profile dashboard up -d dashboard`, accessed via SSH tunnel (`ssh -L 9119:localhost:9119`, localhost-only, no auth), then stopped when done (`docker compose stop dashboard`) — since even while running it re-contends on the locks (cosmetic log spam, not duplicate gateway processes, but still worth not leaving up).

This was discovered independently while investigating the separate Haiku 429 rate-limit incident — unrelated fault, same session.

## P14 — How is the Hermes coding profile fenced off from the host's secrets?

**Reference answer:** A split-mount fence (the §8 design) so the container can reach only the merged/working repo paths and secrets are unreachable in-container; it was deployed and verified live on the Pi.

### P14-R1

Confirmed the fence still holds on ms01 post-migration (audit found "§8 fence... intact"). I can answer directly.

## How the Hermes coding profile is fenced from host secrets

**The mechanism: a "split-mount fence"** — the gateway container's bind mounts were narrowed from one whole-home `rw` mount down to three narrow, purpose-scoped mounts in `docker-compose.override.yml`:

1. **`.../agentic_optimization_research:...:ro`** — skills source. Hermes only needs to *read* `SKILL.md` files, so it's read-only, which also blocks the agent from mutating its own skill definitions.
2. **`/home/chris/app:...:rw`** — the coding workspace. This is the *only* writable path in the container. Chris pre-clones repos here; the agent never clones on its own, so its GitHub PAT needs no extra clone scope.
3. **`/home/chris/.local/state/hermes-ops:...:ro`** — status files that ops/pm profiles read. This was briefly `rw` in anticipation of in-container restart-request writes, but once that feature (12c) shipped without needing an in-container writer, it was tightened to `ro` too — leaving the agent with **zero write surface outside `~/app`**.

**What this replaced:** originally the whole `/home/chris` directory was bind-mounted `rw` into the container (so the gateway could read in-repo `SKILL.md` files), which meant the agent could reach `~/.ssh/github_ecdsa` and `~/.config/gh/hosts.yml` directly.

**Credential posture on top of the mount fence:** a scoped fine-grained GitHub PAT (Contents+PRs read/write, Metadata read, restricted to the `~/app` repos) lives in `.env`, wired via `gh auth setup-git`, using HTTPS remotes — so the agent authenticates to GitHub without ever touching the host's SSH keys or `gh` config, both of which are now unreachable in-container.

**Caveat:** it's still one shared gateway container across all 5 Hermes profiles, so `~/app` is `rw` for all of them, not just `coding` — which repo a given profile should touch is enforced only by a soft "stay-in-project-tree" convention, not a hard container boundary.

**Status:** designed and merged 2026-05-29, deployed live and verified 2026-05-30 (confirmed via `docker inspect` — `~/.ssh` and `~/.config/gh` unreachable, ops-state rejects writes). It carried over cleanly through the Pi→ms01 migration — the 2026-08-01 post-move audit confirmed the fence is still intact on the new host with no drift.

### P14-R2

The Hermes `coding` profile is fenced off from host secrets via a **split-mount design** (documented in `HERMES_PLAN.md` §8, resolved on branch `feat/hermes-split-mount-fence`, and confirmed live on the Pi/ms01 host on 2026-05-30).

**Before:** the container had a single whole-home bind mount, `/home/chris:/home/chris:rw` — meaning the agent could read `~/.ssh/github_ecdsa` and `~/.config/gh/hosts.yml` directly.

**After — three narrow, same-path mounts** in `docker-compose.override.yml`, replacing the whole-home mount:
1. `.../agentic_optimization_research:...:ro` — skills source (only `SKILL.md` needs reading; read-only blocks self-mutation)
2. `/home/chris/app:...:rw` — the coding workspace; the **only** writable path in the container
3. `/home/chris/.local/state/hermes-ops:...:ro` — ops/pm status reads; originally `:rw` for a planned restart-bot writer, then tightened to `:ro` once that writer (12c/A2) was removed

**Result:** `~/.ssh`, `~/.config/gh`, `~/.gitconfig`, and other secrets outside `~/app` are simply not mounted into the container at all — unreachable, not just permission-denied. Verified via `docker inspect hermes` showing exactly those three mounts plus `/opt/data`, with `~/.ssh` and `~/.config/gh` confirmed absent in-container.

**GitHub auth** is handled separately via a scoped fine-grained PAT (`GITHUB_TOKEN` in `.env.example`, Contents+PRs read/write, Metadata read, limited to the `~/app` repos), wired with `gh auth setup-git` over HTTPS — so the agent authenticates without ever touching the host's SSH key or gh config.

**Residual scope:** it's one shared gateway container, so all 5 Hermes profiles share the same `~/app` rw mount (not just `coding`) — which profile touches which repo is still enforced only by the soft "stay-in-project-tree" guardrail, not a hard fence. Overall in-container write surface outside `~/app` is zero.

### P14-R3

## How Hermes' `coding` profile is fenced off from host secrets

**Before the fix:** the container had a single whole-home bind mount (`/home/chris:/home/chris:rw`), so `coding` (like all profiles) could read `~/.ssh/github_ecdsa`, `~/.config/gh/hosts.yml`, etc. — anything in the host home directory.

**The fence (§8 of `HERMES_PLAN.md`, PR #57 → branch `feat/hermes-split-mount-fence`, merged 2026-05-29, deployed live to the running container 2026-05-30):** the one broad mount was replaced with three narrow, same-path mounts in `docker-compose.override.yml`:

1. **`…/agentic_optimization_research → :ro`** — skills source; the gateway only needs to read `SKILL.md` files, so read-only blocks self-mutation.
2. **`/home/chris/app → :rw`** — the coding workspace; the *only* writable path in the container. Repos are pre-cloned here by Chris (the agent never clones), and it's shared with Chris's own edits, guarded only by a soft "start from clean `main`, refuse on dirty tree" rule.
3. **`/home/chris/.local/state/hermes-ops → :ro`** — status files the ops/pm profiles read. It was briefly `:rw` for planned restart-request writes, but once the 12c restart design removed the only in-container writer, it was tightened to `:ro` too.

GitHub auth was also re-scoped: instead of the container reading `~/.ssh`/`~/.config/gh` directly, it uses a scoped fine-grained PAT (`GITHUB_TOKEN` in `.env.example`, Contents+PRs read/write, Metadata read, limited to the `~/app` repos) wired via `gh auth setup-git` over HTTPS.

**Net effect:** `~/.ssh`, `~/.config/gh`, `~/.gitconfig`, and all other host secrets are unreachable inside the container — the agent's total write surface outside `~/app` is zero. Verified live via `docker inspect hermes` showing exactly the three narrow mounts + `/opt/data`.

**Caveat:** it's still one gateway container shared by all 5 profiles, so `~/app` is rw for *every* profile, not just `coding` — which profile touches which repo is enforced only by the soft "stay-in-project-tree" guardrail, not a hard fence.

## P15 — What's the difference between Hermes delegate_task and kanban_create for dispatching work to a specific profile?

**Reference answer:** delegate_task spawns a generic child with no profile; kanban_create(assignee=<profile>) is real profile-dispatch — so the design's dispatch model has to move off delegate_task to actually target a profile.

### P15-R1

Based on memory (confirmed 2026-05-30): `delegate_task` spawns a generic child agent with no profile attached — it's not real profile-dispatch. `kanban_create(assignee=<profile>)` is the actual mechanism for dispatching to a specific profile.

This was a notable finding because the design originally assumed `delegate_task` handled profile-based dispatch — the design's dispatch model needed to move off `delegate_task` and onto `kanban_create` once this was proven.

One caveat on relay behavior: the kanban notifier only relays card results back to Telegram if a `notify_subs` row exists. A human running `/kanban create` auto-subscribes, but pm's `kanban_create` tool call does **not** auto-subscribe — so agent-initiated kanban dispatches may not surface results back to Telegram unless that's handled separately.

### P15-R2

## `delegate_task` vs `kanban_create` for profile-targeted dispatch

**`delegate_task`** (spawns a generic child agent in the parent's own context) **cannot actually target a profile.** Its only param is `role: leaf|orchestrator` — no profile field. The child gets `skip_memory=True`, none of the target profile's `external_dirs` skills, and a broad default toolset (`terminal`, `file`, `web`) rather than that profile's narrowed one. So "delegate to ops" produces a generic agent with no ops skills/memory/docker access — in the proven test it just guessed (`which docker`, wrongly reported 0/0 containers).

**`kanban_create(assignee="<profile>")`** is the real dispatch mechanism. A background dispatcher (running in pm's gateway, ~60s tick) picks up ready cards and spawns a genuine `hermes -p <assignee>` worker — with that profile's actual skills, memory, and toolset, in an isolated workspace. Proven 2026-05-30: assigning to `ops` correctly ran the `host-ops-status` skill and returned the right container count, where `delegate_task` failed the identical question five times in a row.

Caveats worth knowing:
- Unknown assignee names are silently dropped — the card just sits `ready` forever, no error.
- Results only relay back to Telegram automatically if a `kanban_notify_subs` row exists. A **human** typing `/kanban create --assignee <p> ...` auto-subscribes the chat and gets the full agentless relay loop. The **pm agent's own `kanban_create` tool does not subscribe** — a pm-composed card is dispatched but never relayed back, since pm has no subscribe tool and no terminal.
- Design consequence: pm's job became composing the `/kanban create` slash command for Chris to send (not calling its own tool, and never using `delegate_task` for profile work).

Source: [[hermes-delegation-vs-kanban]] and [[hermes-kanban-relay-mechanism]] memories, both dated 2026-05-30/31 — flagged as 80+ days old, so worth a quick sanity check against current Hermes code if you're about to act on the specifics rather than just recalling the history.

### P15-R3

Based on my memory of past work on the Hermes agent system:

**`delegate_task`** spawns a generic child agent with **no profile** attached — it can't target a specific persona/role.

**`kanban_create(assignee=<profile>)`** performs **real profile-dispatch** — it actually routes the task to a specific named profile (e.g., `pm`). This was proven working on 2026-05-30.

The upshot at the time: the design's dispatch model needed to move off `delegate_task` and onto `kanban_create`, since only the latter gives genuine per-profile routing. There's a related wrinkle — `kanban_create` calls made by the `pm` profile itself don't auto-subscribe to the Telegram result-relay (unlike a human-initiated `/kanban create`, which does), because the gateway notifier only relays results when a `notify_subs` row exists.

If this still matters for current work, worth verifying against the live Hermes codebase/design docs since this reflects state from several months ago.

## P16 — What does the Tier-1 ingest Stop hook populate in the warehouse?

**Reference answer:** It parses the session log and (via psycopg) ingests sessions, session_turns and tool_calls into the Postgres warehouse on every session stop.

### P16-R1

The Tier-1 ingest Stop hook (`metrics/warehouse/hooks/stop_ingest.sh`) runs at the end of every Claude Code turn and parses the current session's JSONL, then loads it into the Pi-hosted Postgres warehouse via `warehouse ingest`. Specifically it populates:

- the **v2 session columns** (the per-session summary row)
- **`session_turns`** (one row per conversation turn)
- **`tool_calls`** (one row per tool invocation)

All rows are tagged `source='tier1_jsonl'` to distinguish them from other ingest tiers. Ingest is idempotent at the session grain (DELETE + INSERT in one transaction), so re-running on the same session is safe. If the Pi is unreachable, the hook queues the path to `~/.cache/agentic_metrics/queue.jsonl` and `warehouse retry` drains it later — the hook itself is detached (`nohup … &`) so a slow/offline Pi never adds latency to your turn.

This effectively made Tier 1 "live" — sessions land in the warehouse automatically as they happen, no manual `warehouse load` needed (per `metrics/warehouse/hooks/README.md` and `roadmap/01-data-collection.md`).

### P16-R2

Found it — this is about the `agentic_optimization_research` metrics warehouse, not Hermes. It's a documented, live piece of the project (`metrics/warehouse/hooks/stop_ingest.sh`), so I can answer directly from the repo docs.

**What the Tier‑1 Stop hook does:** `metrics/warehouse/hooks/stop_ingest.sh` fires on every Claude Code turn-stop, pulls `transcript_path` from the hook payload, and detaches (`nohup … &`) a call to `warehouse ingest --session-file <path> --queue-on-failure` against the Postgres warehouse (on ms01, formerly the Pi). This makes **Tier 1** (the JSONL session-log parser, in the three-tier model: Tier 1 = retrospective parsing, Tier 2 = live per-tool hooks, Tier 3 = SDK harness) run live with no manual load step.

**Tables it populates** (per `metrics/warehouse/README.md`):

| Table | Grain | Content |
|---|---|---|
| `sessions` | 1 row/session | token totals, duration, turn counts, model(s), cache hit ratio, git branch, entrypoint, CC version, `permission_mode_initial`, subagent_turn_count, `cache_creation_5m/1h_tokens` |
| `session_tool_calls` | 1 row/(session, tool) | per-tool call counts |
| `session_turns` | 1 row/logical turn | per-turn tokens, model, stop_reason, content JSON, sidechain flag, cwd, permission_mode, service_tier |
| `tool_calls` (`source='tier1_jsonl'`) | 1 row/`tool_use` block | tool name, input, output (joined from `tool_result`), `is_error`, `is_sidechain`, subagent_type; `duration_ms` stays NULL (that's Tier 2's job) |
| `session_compactions` | 1 row/compaction event | schema present, empty — no compaction events observed in JSONL yet |
| `session_prs` | 1 row/(session, PR) | PR number/repo/URL derived from `pr-link` events |

It never touches Tier 2 (`bash_commands`, per-tool latency) or Tier 3 (experiment tables) — those remain schema-only until their respective builds land. If ms01 is unreachable, rows queue at `~/.cache/agentic_metrics/queue.jsonl` for `warehouse retry` to drain later, and `WAREHOUSE_INGEST_SKIP` opts a session out entirely (used for harness/eval runs like the H3 comparison so the eval corpus doesn't ingest itself).

### P16-R3

The Tier-1 ingest Stop hook (`metrics/warehouse/hooks/stop_ingest.sh`, wired via `~/.claude/settings.json`) parses the current session's JSONL and pushes it into the Pi-hosted Postgres warehouse at the end of every turn. Specifically it populates, tagged `source='tier1_jsonl'`:

- The core session **v2 columns** (session metadata)
- **`session_turns`** — per-turn records
- **`tool_calls`** — including `subagent_type` extracted from `Agent`/`Task` tool_use input
- **`session_prs`** — deduped `(session, PR)` rows derived from `pr-link` events

It's idempotent at the session grain (re-ingesting replaces that session's Tier-1 rows in one transaction), runs detached via `nohup` so a slow Pi never adds turn latency, and queues to `~/.cache/agentic_metrics/queue.jsonl` (drained by `warehouse retry`) if the Pi is unreachable. Two things it does *not* populate: `git_sha_start` (parser-NULL, no SHA in JSONL) and `session_compactions` (wired but empty — no compaction events observed).

## P17 — What stack does the product-use-tracker case study use, and what was the headline tool-cost finding?

**Reference answer:** Flask + DuckDB, single-developer daily-use inventory tracker; the baseline found Bash + Read were the dominant tool-cost share (~37% combined) with a notable wasted-re-read fraction (~27%).

### P17-R1

**Stack:** Flask + DuckDB (single-writer), a Telegram bot (`bot.py`, running as a daemon thread — not a separate process, to respect DuckDB's single-writer constraint), a responsive PWA frontend, and self-hosted deploy via Docker + Raspberry Pi + Cloudflare Tunnel. Framework-agnostic mutations live in a `services.py` layer so both the web routes and the bot call the same code. Single developer, single real user, live production DB with no staging environment.

**Headline tool-cost finding:** pre-lock cost/rate-limit discipline *before* building against any external paid or rate-limited API — don't discover the constraint at runtime.

This came from two linked incidents in the v3 cycle (2026-05-19 → 05-23):
1. **OpenFoodFacts REST API (free) → B2-redo.** Smart Add's autofill hit OpenFoodFacts' search endpoint for type-as-you-type autocomplete, which tripped a 10 req/min/IP limit with real IP-ban risk. The fix was PR #22 ("B2-redo"): drop the REST calls entirely and mirror the data into a local DuckDB FTS index (`instance/off_mirror.duckdb`), refreshed manually via a script. Same UX, different substrate — and because the phase was small and isolated, the re-architecture was cheap (B2's original work wasn't reverted, just superseded).
2. **Amazon PA-API (paid) → pre-locked before D3.** Having been burned once, before writing any Amazon PA-API integration code, PR #38 landed *first* and documented the cost-per-call ceiling, the rate limit (1 req/sec, 8640/day free tier), a kill-switch setting, and a hard rule that PA-API calls only happen from a queued job, never a request handler.

The generalized lesson (case study §1.4.3): for any external paid/metered tool surface, **the cost-discipline doc is the first artifact you write, not the last** — the cost of a runaway loop or IP ban is much higher than the cost of writing the doc up front.

### P17-R2

**Stack:** Flask + DuckDB, single-developer/single-user personal app. v1 was a monolithic `app.py` (~1900 lines, server-rendered Jinja, no auth/API). v2 added a Telegram bot, a responsive PWA, and self-host deploy via Pi + Docker + Cloudflare (Cloudflare Tunnel as HTTP proxy only — explicitly not a DB writer). v3 added Smart Add (fuzzy autofill), reminders, bulk actions, and usage/reorder projections. DuckDB's single-writer constraint is the one architectural fact that drives nearly every design decision (bot runs as a thread, not a process; backups stop the app first; no scaling the app service).

**On "headline tool-cost finding" — two different things could be meant, and I want to be precise rather than guess:**

1. **If you mean the cost of external API tools the app itself calls** — this is the actual headline finding in the doc: the OpenFoodFacts REST API hit a hard 10 req/min rate limit with IP-ban risk almost immediately after Smart Add shipped (Phase B2), forcing a same-day rearchitecture (B2-redo) to a local DuckDB FTS mirror instead of live REST calls. That incident then generalized into a rule: **pre-lock cost/rate-limit discipline before any paid external API is touched**, applied proactively before the Amazon PA-API integration (cost ceiling, 1 req/sec rate limit, kill switch, "no API call from a request handler — only from a queued job," all documented *before* any implementation code was written).

2. **If you mean Claude/token cost** (tool-call cost, cost-per-phase, etc.) — the playbook explicitly says this was **not measured**. §13.1 ("Open questions") states: *"What's the real token cost per phase? I have wall-clock numbers (median 11 minutes between PR merges) but no token numbers. A future tool-instrumentation pass would measure this."* So there's no headline finding there — it's flagged as a known gap, not an answered question.

If you had a specific number or claim in mind, let me know and I'll track down where it actually lives (could be in a different case study or the warehouse metrics rather than this playbook).

### P17-R3

**Stack:** Flask + DuckDB (Python), single developer / single user, daily personal use. v1 was a monolithic `app.py` (~1900 lines) with server-rendered Jinja, no auth/API. v2 added a Telegram bot, a responsive PWA, and self-hosting via Docker + Cloudflare on a Pi.

**Headline tool-cost finding:** don't touch a paid or rate-limited external API until you've written the cost-discipline doc — the doc is the *first* artifact for that surface, not the last. Two data points back this:

1. **OpenFoodFacts REST (reactive case).** Phase B2 (Smart Add fuzzy autofill) shipped against the OFF REST search endpoint. Within hours it hit a hard 10 req/min/IP limit with real IP-ban risk — fatal for a type-as-you-type autocomplete UX. The fix was "B2-redo" (PR #22): drop OFF REST entirely, build a local DuckDB FTS mirror (`instance/off_mirror.duckdb`) refreshed by script instead. Same UX, different substrate, B2's history kept rather than reverted.
2. **Amazon PA-API (proactive case, applying the lesson).** Before any D3 implementation, PR #38 landed a pre-lock doc specifying the cost-per-call ceiling, the rate limit (1 req/sec, 8640/day free tier), a kill-switch, and "no PA-API call from a request handler — only from a queued job."

The playbook explicitly does *not* claim dollar/token cost numbers (§12.2/§13.1 call that out as unmeasured) — the "cost" finding here is about external-API rate/dollar cost discipline, not Claude usage cost.

## P18 — [Redacted]

*Prompt, reference answer, and all three responses redacted for
personal research reasons.*

## P19 — Why are Hermes ops/Pi-maintenance jobs run as host systemd timers instead of in-container agent crons?

**Reference answer:** Because the cron sandbox disables the agent's memory store and in-container crons proved unreliable/costly; deterministic ops maintenance runs as host systemd timers (agentless) instead.

### P19-R1

## Why Hermes ops/maintenance jobs run as host systemd timers, not in-container crons

**Root cause:** Hermes runs as an isolated Docker container on the Pi (for toolchain isolation + clean `systemctl` teardown). Its only binds are `/home/chris` and `~/.hermes -> /opt/data` — there's no `docker.sock`, no Postgres client, no host `apt` inside the container. So the ops crons from HERMES_PLAN §2.5 (docker-ps parity checks, pg backup, queue drain, apt dry-run) physically **can't run from inside the container** — the original design assumed a native-on-Pi Hermes with host shell access, which turned out to be wrong once it was containerized.

**Chris's decision (2026-05-28), Option A:**
- Mechanical host-ops jobs run as the **Pi's own systemd timers** — root-level host ops belong in the host scheduler, following a least-privilege / no-sudo-as-shortcut principle.
- Each timer writes a status file to `/home/chris/.local/state/hermes-ops/`, which *is* visible inside the container via the bind mount.
- Hermes itself is only the **judgment/notify layer**: it reads those status files and alerts Chris, routed through the `pm` profile (the only one with a live Telegram gateway) — it never touches `docker.sock` directly.

**Why it matters:** keeps the autonomous LLM agent sandboxed. Mounting `docker.sock` into the container would hand it root-equivalent control over every container on the Pi — an unacceptable privilege escalation for an autonomous agent.

**Extension to agent-initiated privileged actions** (the later "12c" restart design): the same split applies. The agent can only write a *data-only request* file under the bind mount; a **root-owned host responder** (living outside the agent-writable bind mount, e.g. `/usr/local/bin`) validates the request against a hardcoded allowlist and performs the actual privileged action (e.g. `docker restart`), scoped to restart-only, per-container allowlist, with a cooldown and no reflexive auto-restart.

One flag: this memory is from 2026-05-28/29 (~82 days old per the tool's own staleness warning), and your later memory `hermes-12c-restart-design` notes the restart mechanism was live-tested and confirmed working on the Pi as of 2026-05-29 — so the design held up in practice, but if you need current file/line specifics I'd verify against the actual hosts bundle before relying on it.

### P19-R2

**Sandboxing, not capability.** Hermes runs Pi-side as an isolated Docker container with only `/home/chris` and `~/.hermes` bound in — no `docker.sock`, no Postgres client, no host `apt`. So the mechanical ops jobs (docker-ps parity checks, pg backup, queue drain, apt dry-run) simply can't execute from inside the container in the first place.

Chris's decision (2026-05-28): **host systemd timers do the mechanical work**, each writing a status file to `/home/chris/.local/state/hermes-ops/` (visible in-container via the bind mount). Hermes then acts purely as the **judgment/notify layer** — it reads those status files and alerts Chris via the `pm` profile's Telegram gateway, never touching `docker.sock` directly.

The reasoning: mounting `docker.sock` into the container would hand the autonomous LLM agent root-equivalent control over every container on the Pi. Keeping root-level host ops in the host's own systemd scheduler (least-privilege, no-sudo-as-shortcut) keeps the agent sandboxed while still letting it report on and reason about host state.

This same split was later extended to agent-*initiated* privileged actions (the 12c container-restart design): the agent can only write a data-only request file; a root-owned responder living outside the agent-writable bind mount (e.g. `/usr/local/bin`) validates against a hardcoded allowlist before executing anything privileged — otherwise the agent could tamper with its own guardrails.

### P19-R3

## Why: sandboxing, not capability

Hermes runs on the Pi as an **isolated Docker container** — its only binds are `/home/chris` and `~/.hermes -> /opt/data`. Critically, there's **no `/var/run/docker.sock`, no Postgres client, no host `apt`** mounted in. So the ops crons from the original HERMES_PLAN §2.5 (docker-ps parity checks, pg backup, queue drain, apt dry-run) literally **can't execute from inside the container** — that design had implicitly assumed a native-on-Pi Hermes with host shell access, which isn't what got built.

**The decision (2026-05-28, Chris):** rather than give the container what it'd need to run these jobs itself, the mechanical host-ops jobs became the Pi's own **systemd timers** — following a least-privilege / no-sudo-as-shortcut principle (root-level host ops belong in the host scheduler). Each timer writes a status file under `/home/chris/.local/state/hermes-ops/`, which Hermes *can* see via the bind mount. Hermes's role is downgraded to the **judgment/notify layer**: it reads those status files and alerts Chris (routed through the `pm` profile, the only one with a live Telegram gateway) — it never touches `docker.sock` directly.

**The core reason:** mounting `docker.sock` into the container would hand the autonomous LLM agent root-equivalent control over every container on the Pi. Keeping the agent sandboxed was worth more than letting it self-schedule its own maintenance.

The same split later extended to agent-*initiated* privileged actions (the 12c restart design): the agent writes a data-only request file, and a separate root-owned host responder outside the agent-writable bind mount validates it against a hardcoded allowlist before executing anything privileged.

## P20 — What's the repo's stance on the default toolchain for a new Python utility?

**Reference answer:** FOSS-first, and uv-only for Python (no pip) — captured as a tech-stack-defaults module and used by the experiment tools themselves.

### P20-R1

The repo's stance is codified in **`modules/python-uv-only/index.md`** — a stable, repo-scoped guardrail:

**Rule:** `uv` is the sole Python environment/dependency manager. `uv add` for deps, `uv run` for execution, `uv lock` for locking. Never `pip`, `pipx`, `poetry`, `pdm`, `virtualenv`, or `python -m venv` — not even "just this once."

**Why:** reproducibility across machines (laptop ↔ Pi/ms01). `uv.lock` pins transitive deps with hashes; mixing in `pip install` silently bypasses the lockfile, producing "works on my laptop, breaks on the Pi" drift.

**How it applies to a new utility:**
- New repo/tool: `uv init` (not `python -m venv`)
- Add a dep: `uv add <pkg>`, commit `pyproject.toml` + `uv.lock` together
- Run anything (scripts, tests, linters): `uv run <cmd>`
- Global tool need (e.g. editor-integration `ruff`): `uv tool install`, not `pipx`
- If a library README says `pip install foo`, translate to `uv add foo`

This matches what's in your memory (`feedback_uv_run_not_python3.md`) but the module is the fuller, canonical version — evidence cited from `tools-stack/ops.md`, the product-use-tracker case study, and `roadmap/06-tech-stack-defaults.md`.

### P20-R2

The repo's canonical stance is codified in the `python-uv-only` guardrail module ([modules/python-uv-only/index.md](modules/python-uv-only/index.md)):

**`uv` is the sole Python toolchain — never `pip`, `poetry`, `pdm`, `virtualenv`, or bare `python -m venv`.**

- New repo/utility: `uv init` (or `uv venv`), not `python -m venv`.
- Add deps: `uv add <pkg>`, committing `pyproject.toml` + `uv.lock` together.
- Run anything (scripts, `pytest`, `ruff`, REPL): `uv run <cmd>` — never a bare `python`/`pytest`.
- Global tool needs: `uv tool install`, not `pipx`.
- If a library README says `pip install foo`, translate to `uv add foo`.

**Why:** reproducibility across Chris's machines (laptop ↔ Pi/ms01) — `uv.lock` pins transitive deps with hashes so the env resolves identically everywhere; mixing in `pip install` silently bypasses the lockfile, producing "works on my laptop, breaks on the Pi" drift.

This is `type: guardrail, scope: repo, lifecycle: stable` (v1), evidenced by `tools-stack/ops.md`, the product-use-tracker case study's CI smoke pattern, and `roadmap/06-tech-stack-defaults.md`. It applies whenever a project is Python and the host repo hasn't explicitly opted into a different toolchain — this lines up with the memory note ([feedback_uv_run_not_python3.md]) about always invoking this repo's own scripts via `uv run`.

### P20-R3

The repo's stance is codified as a stable guardrail module: **[`python-uv-only`](modules/python-uv-only/index.md)** — `uv` is the sole Python environment/dependency manager, applied whenever a project is Python and hasn't explicitly opted into something else.

Concretely:
- **Setup:** `uv init` (or `uv venv`), never `python -m venv`
- **Deps:** `uv add <pkg>`, committing `pyproject.toml` + `uv.lock` together — never `pip install`, `poetry`, `pdm`, or `pipx`
- **Running anything** (scripts, `pytest`, `ruff`, REPL): `uv run <cmd>`, never a bare `python`/`pytest`
- **Global tool installs** (e.g. editor-integration `ruff`): `uv tool install`, not `pipx`

**Why:** reproducibility across machines (Mac ↔ Pi). Mixing in `pip install` silently bypasses the lockfile — works on one machine, breaks on the other, and the drift isn't caught until deploy.

This lines up with an existing feedback memory you have (`feedback_uv_run_not_python3.md`) — that's the applied instance of this same module's rule.
