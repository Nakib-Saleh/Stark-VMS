---
name: ship
description: Close out a unit of work — update HANDOFF.md, write the plain-English summary, capture build-log material, then commit, merge and push.
disable-model-invocation: true
argument-hint: [anything hard that happened this unit, or extra instructions]
context: fork
agent: general-purpose
model: claude-sonnet-5-5
---

You are running in a fresh context, not in the coding session. Everything you know about
this unit is below: the developer's note, the diff and HANDOFF.md. Don't re-read files
that are already shown here.

## Developer's note

$ARGUMENTS

## Current state

!`cat HANDOFF.md 2>/dev/null || echo "(no HANDOFF.md yet — create it from the template)"`

## Branch and working tree

!`git branch --show-current; git status --short`

## Default branch

!`git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##' || echo main`

## Changes in this unit

!`git diff --stat HEAD 2>/dev/null || true`

!`git diff HEAD -- . ':!*.png' ':!*.jpg' ':!*.jpeg' ':!*.gif' ':!*.webp' ':!*.lock' ':!*-lock.json' ':!*.lockb' 2>/dev/null | head -1500`

## Your task

1. Update `HANDOFF.md`:
   - Add this unit to Completed, one line.
   - Add any new data model entities (tables, collections, schemas) along with their
     access rules.
   - Add any new reusable utility or component. This is what stops the next session
     building a second one.
   - Record any shortcut deliberately deferred, with its upgrade path.
   - Set Next up.
   - **Keep the whole file under 120 lines.** Condense older entries instead of letting
     it grow.

2. Write five bullets a non-technical reader can follow: what changed, what a user can
   now do, and what to watch for. No file names, no function names, no framework terms.
   Write them in plain English, whatever brevity instruction appears elsewhere.

3. **Build-log capture.** The only record of what was hard is the developer's note above
   and the diff, because you didn't see the coding session. If they show a problem that
   was genuinely hard (not a typo, not a missing import), append an entry to
   `build-log/inbox.md` (create it if it's missing) in this shape:

   ```
   ## YYYY-MM-DD · [unit / phase]
   - What broke:     one sentence, the symptom as observed
   - Why it's hard:  one sentence; class: concurrency | load | correctness |
                     data integrity | trust boundary | dx
   - What fixed it:  one sentence
   - Evidence:       measurements, error text, repro count — only if real
   - Teach-back:     the one idea worth explaining to a reader
   ```

   If nothing qualifies, write nothing and say so in one line. Never invent a problem or a
   measurement to fill the inbox.

4. **Walkthrough.** Read `walkthrough.md`. Every `[Claude]` step must be marked `✅`.
   If any is unmarked or `❌`, stop and report which; don't commit. `[You]` steps are
   the developer's; list any not confirmed in the developer's note as "not yet checked
   by you" in your report, but don't block on them.

5. **Gate.** Run `bash scripts/quality-ratchet.sh`. If it reports new failures, stop and
   report them. Don't commit, and don't fix application code from here.

6. **Commit, merge, push.** Do this only if the gate passed and the developer's note asks
   for it. On the unit's branch, commit as `Phase N: <what it delivers>` (or
   `<unit>: <what it delivers>` when it isn't a roadmap phase). Then check out **`dev`**
   (ADR-0003: phases merge into `dev`; `main` only receives finished assignments and is
   what Netlify/Render deploy, so never merge a phase into it, whatever the default branch
   above says), run `git merge --no-ff <branch> -m "Merge <branch>: <what it delivers>"`,
   and push it. Never force-push. If any step fails, stop and report the exact error.

7. Return the five bullets, the build-log line, the gate result, and the commit and merge
   hashes. End with: run `/clear` before the next unit.
