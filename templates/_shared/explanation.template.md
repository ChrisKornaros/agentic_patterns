# Explanation template — how agents explain things to Chris

> **What this is.** The one output format for **any agent explaining or
> summarizing something for Chris**: Claude in a session, an agent
> executing a roadmap, or a Hermes profile writing a vault summary. Chris
> reads the bullets, then expands them into his own prose if he chooses.
> **Agents never write the prose.**
>
> Calibrated against Chris's own note style (surveyed 2026-07-03):
> hierarchical bullets, **bolded key terms** with inline definitions,
> examples nested under the concept with literal commands and values in
> bold, a header per topic, zero paragraphs. Designed in the vault
> (`requirements/explanation-template.md`, locked 2026-07-03) and promoted
> here per its adoption plan, so this file is canonical and the vault doc
> points to it.

## The template

```markdown
# <Topic — what this page explains in one breath>

## TL;DR

- <the single most important takeaway>
- <second takeaway>
- <optional third — never more>

## Key Terms

- **<term>** — <one-line definition>
  - <optional clarifying sub-bullet or contrast with a nearby term>
- **<term>** — <one-line definition>

## The Core Idea

- <the mental model, top-level claim first>
  - <supporting detail>
  - <supporting detail>
- <second top-level point if the idea has two legs>

## How It Works

- <step or mechanism>
  - **Example:**
    - **<literal command / value / config>**
    - <what it does, one line>
- <next step or mechanism>
  - <caveat or gotcha, marked **Watch-out:** when it can bite>

## What This Means for Me

- <implication or action, phrased for Chris's setup specifically>
- <what to do next, if anything>

## Open Questions

- <anything unresolved, half-formed is fine>

## Sources

- <name> — <one-line hook: why it's listed>
```

## Rules

1. **Bullets only — no prose paragraphs anywhere.** If a bullet needs three
   sentences, it's two bullets.
2. **Bold is semantic, not decorative:** key terms on first definition,
   literal commands/values/filenames in examples, and the `**Example:**` /
   `**Watch-out:**` markers. Nothing else bold.
3. **Max nesting depth 3.** Deeper means the structure is wrong — promote to
   a new `##` section.
4. **Sections are droppable, not reorderable.** A short explanation might be
   just TL;DR + Core Idea + What This Means for Me. Never add new section
   types; never shuffle the order.
5. **Key Terms only for terms actually used later on the page** — it's a
   reading aid, not a glossary dump. Skip the section if there's nothing to
   define.
6. **"What This Means for Me" is mandatory** in any summary an agent produces
   unprompted (e.g. Hermes vault digests) — it's the section that makes the
   page worth opening.
7. **Where output lands:** in-chat explanations just use the format; written
   summaries go to the area of the notes store the content belongs to
   (usually the vault's `notes/`), tagged per that store's taxonomy.
8. **Chris owns prose.** If Chris expands a page into prose, the agent's
   bullets move under a `## Source notes` heading or get replaced — agents
   never "improve" Chris's prose additions back into bullets.

## Where it's carried

- **Hermes profiles** carry the rule, not the skeleton, in their memory
  seeds and `SOUL.md` files under
  `profiles`:
  research and writing hold the full rule, pm, coding and ops a two-line
  form (`roadmap/11` §6).
