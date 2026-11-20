---
name: bug
description: Diagnose a bug from captured evidence. Two-round localisation limit.
disable-model-invocation: true
argument-hint: [what went wrong — paste the error output, logs and repro steps]
---

## Working tree

!`git status --short 2>/dev/null || true`

## Recent changes

!`git log --oneline -5 2>/dev/null || true`

## Reported

$ARGUMENTS

## Protocol

**Step 1 — check the evidence is sufficient.** You need reproduction steps plus the
evidence `STACK.md` lists for this stack. Typically that means:

- UI fault: the console output and the failing network request and response.
- Service or API fault: the server logs, and the request and response.
- CLI or script fault: the exact command, the full output and the exit code.
- Mobile or desktop fault: the device or OS, and the crash log or stack trace.

If anything material is missing, say exactly what to capture and stop. Don't start
searching the codebase to make up for missing evidence.

If a tool is available that can reproduce the fault itself (a browser automation or
devtools MCP, a test runner, the CLI itself), capture the evidence yourself: reproduce
it, read the error with its stack trace, read the failing request, and take a screenshot
of the broken state where that applies. Then diagnose.

**Step 2 — localise, with a hard limit of two rounds of tool use.** Use LSP symbol
navigation first. If the repository has a code graph (Graphify), use `graphify query` and
`graphify path`. Text search is the last resort, not the first.

**Step 3 — reach one of two outcomes.**
- Localised: state the root cause in one or two sentences, then the minimal fix. Apply
  the simplicity ladder to the fix. A bug fix is not a licence to refactor.
- Not localised: STOP. Give the exact logging or instrumentation lines to add, where
  they go, and what to look for in the output. Don't keep searching.

Never report a probable cause as a confirmed one. If you're inferring rather than
observing, say so.
