# H3 — session-log retrieval vs curated memory (experiment output)

Example output from a pre-registered agent-tooling experiment: **does
giving a coding agent a retrieval tool over its own past session
transcripts improve answers to historical-recall questions, compared
to a curated memory layer alone?**

Three conditions (memory-only baseline · +BM25 · +dense embeddings)
ran the same 20 frozen prompts on the same model, differing only in
tool surface. Responses were scored 0–2 by a single rater **blinded to
condition**, against success bars registered and merged before any
condition ran.

| File | What it is |
| --- | --- |
| [quick-hits.md](quick-hits.md) | The headline numbers and methodology takeaways |
| [rating-sheet.example.md](rating-sheet.example.md) | The actual blinded rating sheet the rater worked from (one prompt redacted) |

**Provenance.** Produced in the private research repo this repo is
published from; the full design doc, harness code, per-cell scores,
and threats-to-validity analysis live there. This directory is a
curated example of what the experiment *output* looks like — shared
because blinded-rating artifacts for agent evals are rarely shown in
public. Raw transcripts and the retrieval corpus stay private (they
contain real session content); one prompt (P18) is redacted for
personal research reasons.
