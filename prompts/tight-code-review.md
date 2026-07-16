# Tight code review

Use to get a focused review of a diff or PR without burying the
structural issues under style nits.

```
Read this diff: <branch | PR # | file path>. Don't suggest
improvements yet. First, tell me:

  (1) what behavior changed,
  (2) what could break that isn't covered by smoke,
  (3) any place where the change should also have touched another file
      but didn't.

After I respond, then suggest improvements if you want.
```

## Why this works

The "don't suggest improvements yet" clause is load-bearing. Without
it, you get a laundry list of style nits and the structural issue (a
half-applied refactor, a missing call-site update) gets buried under
"prefer f-strings here" suggestions. Forcing the agent through three
specific questions surfaces the high-value review content first.
