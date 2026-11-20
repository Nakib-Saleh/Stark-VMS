# Engineering Rules

## Stack
@STACK.md

If `STACK.md` does not exist yet, run `/stack` before anything else. Never assume a stack.

## 1. PLAN GATE
Never write implementation code before presenting a DECISIONS block and receiving
approval. Ten lines maximum:

- Approach chosen:
- Simpler approach rejected, and why it fails:
- Existing utilities/components being reused:
- New dependencies / tables / env vars added:
- What this makes harder later:

## 2. SIMPLICITY LADDER
Before writing any function, component or module, stop at the first rung that holds:

1. Does this need to exist at all? Skip unrequested options and speculative abstractions.
2. Is it already in this codebase? Check HANDOFF.md and existing utilities first.
3. Does the standard library or language do it?
4. Does the platform do it? (Native web APIs and HTML elements; the OS or runtime's own APIs.)
5. Does an already-installed dependency do it? Never add a package for a few lines.
6. Can it be one readable line?
7. Only then: the minimum that works.

Never cut security, auth checks, input validation, accessibility or error handling.
When you take a deliberate shortcut, mark it inline with a comment naming its upgrade
path, e.g. `shortcut: native date input; swap for a picker if range select is needed`.

## 3. TESTS
Write automated tests only for: authentication boundaries, role-based access checks,
data mutations, payments, and destructive deletions. Do not write tests for
presentational code, layout or copy. If it will not run in CI, do not write it.

## 4. DEBUG
Evidence before theory. Never speculate without error output, a stack trace, logs or a
request/response payload. You have a maximum of TWO rounds of tool use to localise a fault.
Use LSP symbol navigation before any text search. If the cause is not confirmed within
two rounds, STOP and state the exact instrumentation needed. Do not keep searching.

## 5. BLAST RADIUS
Read a file before editing it. State every file a change will touch before touching it.

## 6. SECURITY (non-negotiable)
- Every data store enforces access control at the data layer, not only in the UI or route.
- Access rules are tested as an unauthorised user, not only as the owner.
- No secret in client-shipped code, public env vars, or the repository.
- Validate every input that crosses a trust boundary.
- The stack-specific rules in STACK.md are part of this section.

## 7. CLOSE OUT
Every completed unit of work updates HANDOFF.md and produces five bullets a
non-technical client can read: no file names, no function names, no framework terms.

## 8. OUTPUT STYLE
Lead with the answer. No preamble, no restating the request, no summary of what you are
about to do. Code blocks and exact errors in full; prose short.
