---
name: tool-trial-sandbox
description: "Sets up a sandbox before trying a third-party agent tool, plugin or CLI: a clean CLAUDE_CONFIG_DIR profile, a snapshot of every agent-context file the tool could write, its upload defaults and opt-outs, and the teardown list, then diffs the context after every install. Use before a workshop, vendor demo or experiment installs anything."
version: 1.0.0
source: prompts/tool-trial-sandbox.md
tags: [guardrail, workflow, agentic-optimization-research]
---

# Tool-trial sandbox

Use before any trial tool is installed. Canonical text, the env-file
example and the evidence are in
[prompts/tool-trial-sandbox.md](../../prompts/tool-trial-sandbox.md).

```
I want to try <tool> (<link>) for <purpose>. Before installing anything:

  (1) Set up a sandbox: a folder outside every real repo, and an env
      file that points the agent at a clean profile (CLAUDE_CONFIG_DIR)
      and puts the tool's binaries on PATH. Every trial command runs in
      a terminal that sourced it, and the prompt shows that it did.
  (2) Snapshot the agent context the tool could write to: ~/.claude/
      (CLAUDE.md, settings.json, skills, commands), and in the trial
      repo CLAUDE.md, AGENTS.md, .claude/, .mcp.json, .github/ and the
      git hooks.
  (3) Read what the tool sends off the machine by default: transcripts
      or session uploads, telemetry, background daemons, backfill of
      past sessions. Find the opt-out for each.
  (4) Write the teardown list now: every binary, config folder,
      account, GitHub App, remote repo and scheduled job the trial will
      create.

After every install or setup command, diff (2) and tell me what
changed. Before any push to a remote, list what would upload.
```

The trial's rules: trial repos only; a GitHub App gets one repo; nothing
private in public repos, and transcripts count as private; pause
scheduled jobs before you leave; run the teardown list at the end.

## Why this works

All three tools trialled at one workshop day wrote into the agent's
context. One wrote past the clean profile into the global `CLAUDE.md`.
Another pushed full transcripts to a public remote by default. Full
evidence is in
[prompts/tool-trial-sandbox.md](../../prompts/tool-trial-sandbox.md).
