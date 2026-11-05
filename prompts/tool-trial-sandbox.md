# Tool-trial sandbox

Use before you install a third-party agent tool, plugin or CLI to try
it: a workshop, a vendor demo, a weekend experiment.
[substrate-preflight.md](substrate-preflight.md) asks whether to build
on something. This prompt keeps the trial away from everything you
already build on.

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

## Rules for the trial

1. **Trial repos only.** Never run a tool's `init`, `enable` or
   `install` in a real repo.
2. **A GitHub App gets one repo.** Pick **Only select repositories**,
   then the trial repo.
3. **Nothing private in public repos,** and a tool's transcripts count
   as private.
4. **Pause scheduled jobs before you leave.** They keep running, and
   spending, after the session ends.
5. **Run the teardown list when you're done,** and check off each item.

An env file for step 1, from the trial this came from:

```sh
export SANDBOX="$HOME/<trial-name>"
export CLAUDE_CONFIG_DIR="$SANDBOX/profile"
case ":$PATH:" in
  *":$SANDBOX/tools/bin:"*) ;;
  *) export PATH="$SANDBOX/tools/bin:$PATH" ;;
esac
case "$PROMPT" in
  "(<trial-name>) "*) ;;
  *) PROMPT="(<trial-name>) $PROMPT" ;;
esac
```

## Why this works

These are from AI Native DevCon NYC, 2026-11-02, where three agent
tools were trialled in one day.

- **A clean profile isn't enough by itself.** The Tessl CLI, run once
  in a plain terminal, appended `@../.tessl/RULES.md` to
  `~/.claude/CLAUDE.md`. That file is a symlink into this repo, so the
  line loaded in every normal session until teardown. The diff in step
  (2) is what catches it.
- **Every tool wrote into the agent's context:**
  - `tessl init` wrote MCP config for three agents, plus `.agents/`,
    `.github/skills/` and an `AGENTS.md` edit.
  - Entire wrote 11 Claude Code hooks, three git hooks, and managed
    blocks in `CLAUDE.md` and `AGENTS.md`. The blocks failed the repo's
    own formatter check.
  - nWave wrote `CLAUDE.md` and `AGENTS.md`, and its upgrade left dead
    hooks that its own `doctor` didn't flag.
- **Uploads are a default.** Entire pushes full session transcripts to
  your git remote. With that on, three went to a public fork. Redaction
  reported 0 hits, and the transcripts still carried an email address
  and an org ID. `entire checkpoint list --outgoing` would have shown
  them before the push.
- **Scheduled jobs outlive the session.** Tessl's loops keep spending
  credits until they're paused. A paused loop also drops events
  silently: a label added while it was paused never started a run.
- **A teardown list written in advance makes cleanup a checklist,** not
  an investigation of what the tools left behind.

## Source

The run sheet, the sandbox setup and the teardown are in the vault:
[ai-devcon-nyc-2026/index.md](https://github.com/ChrisKornaros/vault/blob/main/notes/software/agentic-engineering/ai-devcon-nyc-2026/index.md).
