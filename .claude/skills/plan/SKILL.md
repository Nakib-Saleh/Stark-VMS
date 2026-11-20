---
name: plan
description: Produce an implementation plan ending in a DECISIONS gate. Stops before writing code.
disable-model-invocation: true
argument-hint: [phase number or unit of work]
---

## Project state

!`cat HANDOFF.md 2>/dev/null || echo "(no HANDOFF.md yet)"`

## Roadmap position

!`sed -nE "/^### Phase $ARGUMENTS /,/^(### |## |---)/{/^### Phase $ARGUMENTS /p;/^(### |## |---)/!p}" ROADMAP.md 2>/dev/null | grep . || echo "(no matching phase — treating the argument as a free-form unit of work)"`

## Working tree

!`git status --short 2>/dev/null || true`

## Your task

Plan this unit of work: $ARGUMENTS

The stack, commands and stack-specific rules come from `STACK.md`, which is loaded through
`CLAUDE.md`. `DESIGN.md` is not loaded up front, to keep context small. **If the unit adds
or changes anything a user sees, read `DESIGN.md` before planning.** Never invent a colour,
size or radius.

1. **Docs, not memory.** If the unit uses an API you're not sure of, check the docs source
   listed in `STACK.md` (Context7 or official docs) before planning. Check the installed
   version in the manifest or lockfile. Don't guess at an API.
2. **Reuse.** Check the reusable utilities in the project state above. Reuse before creating.
3. **If the unit adds or changes anything a user sees or uses** (a screen, a command, an
   endpoint's responses), design it to these rules before planning any code. They are
   not optional polish. A plan that misses them is wrong.

   **a. Obvious, never a puzzle.** A first-time user can use it without working anything out.
   - Every control or command says what it does, in words or with a labelled icon. No
     meaning carried only by colour, position or hover.
   - Every filter, toggle or mode shows its current state and a visible way back
     ("All", "Clear", "Hide"). "Do it again to undo" is allowed only as an extra.
   - Shortcuts are extras. Anything a shortcut does also has a visible control.
   - Indicators (progress, ticks, counts) always agree with what the user just did. If two
     of them could disagree, derive both from one value.
   - Every empty, loading and error state says what happened and what to do next. On CLIs
     and APIs, that applies to error messages and exit codes.
   - Don't remove placeholder controls a later phase will wire up. Label them honestly.

   **b. Every action answers at once.** Navigation, submits and long operations show
   immediate feedback: a loading state shaped like the destination, a progress indicator, a
   spinner on a slow command. Use the project's existing loading and progress primitives
   from `HANDOFF.md`, or the stack's own convention for them. Never build a second one. List
   in the plan which destinations are new and what feedback each one shows.
4. **Acceptance test.** Write or update `walkthrough.md`: numbered steps a person follows
   in the acceptance-test medium from `STACK.md` (browser, terminal, HTTP client, device),
   each with its expected result. For user-facing units, include steps that check rule 3a
   (undo every filter or toggle the visible way, and confirm indicators agree after acting)
   and rule 3b (trigger each new destination or slow action on a throttled or slow path).

   **Tag every step `[Claude]` or `[You]`.** The developer does not have time to run
   scripted steps. `[Claude]` is the default: anything a command can drive and check
   (HTTP calls, curl/PowerShell, env-var restarts, log greps, tests, CI status, file
   checks, headless screenshots). `[You]` is only for steps that need a person in the
   real UI: clicking through Flutter screens, judging how something looks or feels,
   keyboard/screen-reader use, throttled-network feel. Keep `[You]` steps few, short
   and grouped at the end, each saying exactly what to click and what to look for.
   A `[You]` step must never depend on the developer starting servers: say "Claude
   leaves the backend running" and do so.
5. Output the DECISIONS block from `CLAUDE.md`. Ten lines maximum.

**STOP after the DECISIONS block.** Don't write or modify any application code until the
developer approves. If the simplicity ladder makes you rethink the approach while you
write the block, say so instead of going ahead.

## After approval: when the build is done

Before asking to commit, **run every `[Claude]` step in `walkthrough.md` yourself**, in
order, against the real running app (not only the test suite). Mark each step in the
file `✅` or `❌` with one line of evidence (status code, header, log line). Fix any `❌`
that this unit caused, then re-run it. Then start whatever the `[You]` steps need (backend,
`flutter run`), leave it running, and hand the developer only the `[You]` list. The unit
is not done until the developer reports back on the `[You]` steps.
