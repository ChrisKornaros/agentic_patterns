# Quick hits — does session-log retrieval beat curated memory?

Headline numbers from a pre-registered, blinded comparison of an agent
answering historical-recall questions with and without a
session-transcript retrieval tool. Design and context:
[README.md](README.md); the rater-facing artifact:
[rating-sheet.example.md](rating-sheet.example.md).

## Setup

- **20 held-out prompts** about real past decisions across five
  projects, frozen **11 weeks before the run**; 0–2 rubric
  (wrong / partial / correct+actionable).
- **3 conditions, only the tool surface differs:** curated-memory
  baseline · +BM25 retrieval · +dense retrieval (bge-small), over a
  **7,059-turn frozen corpus** of the same user's real session logs.
- Same mid-tier model everywhere (claude-sonnet-5), same system-prompt
  nudge, seed-fixed run order, single rater **blinded to condition**;
  success bars registered and merged **before** any scoring.

## Results

- **Baseline is hard to beat: 1.65/2 mean, 16/20 perfect answers** —
  curated memory + repo docs + doc-search already carries most recall.
- **Hypothesis falsified as registered:** +BM25 scored **+0.10** and
  +dense **−0.05** vs a pre-registered **+0.4** success bar (and a
  +0.2 "doesn't reliably help" floor).
- **The bottleneck was adoption, not ranking.** Despite the nudge, the
  agent invoked retrieval in only **5/20 (BM25)** and **4/20 (dense)**
  runs — and dense never invoked it on any prompt the baseline missed.
  A tool can't rescue a miss it isn't consulted on.
- **Rescue signal, honestly attributed:** BM25 recovered all 3 baseline
  misses, but only **1 of 3** recoveries coincided with actual tool
  calls — with one run per cell, the rest is indistinguishable from
  sampling variance.
- **Lexical ≥ semantic here.** Dense embeddings never beat BM25
  anywhere they were used, on a corpus full of distinctive vocabulary
  (project names, tool names, error strings).
- **Retrieval was ~9% cheaper per prompt** (modeled $0.227 vs $0.249):
  retrieved excerpts displace exploratory tool calls.
- **Ops:** 60 runs ≈ 35 min wall-clock, ≈ $15 total modeled cost, one
  max-turns retry.

## Methodology quick hits

- **Freeze on ingest time, not event time.** An event-time corpus
  freeze failed the pre-registered relevance smoke set 2/5 — a bulk
  backfill of old sessions, landing one day *after* registration, had
  inserted pre-freeze-*timestamped* turns the registration never saw.
  Filtering on arrival time reproduced the registration-day corpus
  exactly (to the turn) and the smoke set passed 5/5 with zero
  re-curation.
- Pre-registration merged before outcomes existed; the answer key was
  moved out of the agent's reachable tree during runs; harness
  sessions were excluded from the corpus they evaluate; auto-memory
  was snapshot-pinned across all 60 runs.
- A falsified headline with attributable sub-findings beats an
  unfalsifiable win: the follow-ups (auto-inject vs agent-choice
  adoption experiment; n≥3 sampling on the miss set; lexical-only v1)
  are all sharper questions than the original.
