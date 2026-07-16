# Minimal repro (debugging)

Use when a bug has been reported, **before** any fix is written.

```
The bug is: <description, including how you noticed it>.

Before writing any fix:

  (1) Write the minimal reproduction — a single command or file edit
      that triggers it.
  (2) Tell me what the *expected* behavior is and where in the code
      that expectation is encoded.
  (3) Only then propose the fix.
```

## Why this works

Skipping the repro is the single most common debugging failure mode.
Without one, you "fix" something that wasn't broken, or fix one
manifestation while the root cause stays.

Forcing the agent to point at *where in the code* the expectation is
encoded (step 2) catches the case where there's no encoded expectation
— meaning the bug isn't a bug, it's an undefined behavior that needs
a spec decision first.
