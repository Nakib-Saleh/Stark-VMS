---
name: stack
description: Pre-phase. Decide the tech stack from the project story (new project) or detect it from the repo (existing project), then write STACK.md and configure the quality gate. Run first — before /design-brief and /roadmap.
disable-model-invocation: true
argument-hint: [path to the project story / requirements doc — omit on an existing codebase]
---

## Project story

!`if [ -n "$ARGUMENTS" ] && [ -f "$ARGUMENTS" ]; then cat "$ARGUMENTS"; else echo "(no story file given)"; fi`

## Repository signals

!`ls -A 2>/dev/null | head -50`

!`for f in package.json pyproject.toml requirements.txt Pipfile go.mod Cargo.toml pom.xml build.gradle build.gradle.kts composer.json Gemfile pubspec.yaml mix.exs deno.json Package.swift; do [ -f "$f" ] && echo "== $f" && head -50 "$f"; done; ls *.csproj *.sln 2>/dev/null; true`

## Existing STACK.md

!`cat STACK.md 2>/dev/null || echo "(none yet)"`

## Your task

Do not write application code or scaffold the project during this skill.

**Step 1 — pick the mode.**

- **Detect** — the repository already has a manifest or source code. Write down what is
  actually used, with versions taken from the manifest or lockfile. Do not propose a
  migration or a "better" stack. Anything you can't tell from the files becomes a
  question, not a guess.
- **Choose** — a new project with only a story. Go on to Step 2.

**Step 2 (Choose only) — get the constraints from the story first, then pick tools.**
List the requirements that actually decide the stack, each tied to a line in the story:
platform(s) (web, mobile, desktop, CLI, API, worker), shape of the data and whether it's
multi-tenant, auth and roles, realtime, offline, SEO, payments, integrations, expected
scale, hosting or budget limits, compliance. If the story doesn't say which stacks the
developer already knows well, ask. A familiar stack beats a theoretically better one.

Then choose for each layer: language, framework/runtime, data store, auth, UI/styling
(if there is a UI), hosting, package manager, test runner. Use boring, well-documented
tools by default. Every choice has to trace back to a constraint. If the only reason for a
choice is "it's popular", it's a default, not a decision.

**Step 3 — output a STACK DECISIONS block, then stop and wait for approval.**

```
## STACK DECISIONS
- Mode:              detect | choose
- Platform(s):       [web / mobile / CLI / API / …]
- Stack:             [one line, e.g. "Python 3.12 · FastAPI · Postgres · htmx"]
- Driven by:         [the 2–4 story constraints that decided it]
- Rejected:          [alternative] — [why it fails a constraint], one per major layer
- Has a UI:          yes | no   (decides whether /design-brief runs)
- Existing design:   none | present in [files]   (detect mode only)
- Open questions:    [anything the story or repo leaves genuinely ambiguous]
```

**Step 4 — once approved, write these files:**

1. **`STACK.md`** at the repo root, using this shape. Keep it under 60 lines, because
   `CLAUDE.md` imports it and it loads on every message.

   ```markdown
   # Stack
   *Mode: detect | choose · Decided: [date] · Source: [story path | repo]*

   ## Choice
   | Layer | Choice | Version | Why |
   |---|---|---|---|

   ## Commands
   | Purpose | Command |
   |---|---|
   | install | |
   | dev / run | |
   | typecheck | |
   | lint | |
   | test | |
   | build | |

   ## Facts other skills read
   - Has a UI: yes | no
   - Acceptance-test medium: browser | terminal | HTTP client | device
   - Evidence for bugs: [what to capture: browser console + network, server logs, CLI output, crash log…]
   - Docs to check before using an unfamiliar API: [library → Context7 id or official docs URL]

   ## Where things live
   - [entry points, routes/handlers, data access, UI primitives — paths]

   ## Stack-specific rules (non-negotiable)
   - [only rules this stack needs; max 8 lines]
   ```

   Stack-specific rules are the traps this stack makes easy to fall into. Some examples:
   Supabase means every table gets RLS in its migration, and views get
   `security_invoker = true` because they bypass RLS by default. Next.js means no secret in
   a `NEXT_PUBLIC_` variable. Django means never `mark_safe` user input and keep CSRF on.
   Firebase means security rules get tested with the emulator as an unauthorised user.
   Write the ones that apply and leave the rest out.

2. **`scripts/quality-checks.sh`**, copied from `scripts/quality-checks.example.sh` with
   the checks for this stack filled in. Every check needs a command and a regex that
   matches exactly one line per issue. If the tool is installed, run it once and confirm
   the regex counts correctly. A regex that matches nothing makes the gate always pass.
   Set `BUILD_CMD` if the stack has a build step.

3. **`.claude/settings.json`**: add `permissions.allow` entries for this stack's
   typecheck, lint, test and build commands. Leave the existing entries as they are.

4. **`.github/workflows/ci.yml`**: replace the marked toolchain block with the setup
   action and install command for this stack.

5. **`HANDOFF.md`**: replace the placeholder paths under "Reusable utilities" with this
   stack's real ones (or the ones it will have, in choose mode).

**Step 5 — finish.** Tell the developer the next step:

- Detect mode: run `bash scripts/quality-ratchet.sh --baseline` now. Then `/design-brief`
  if Has a UI is yes, otherwise `/feedback` or `/plan` for the next change.
- Choose mode: `/design-brief` if Has a UI is yes, then `/roadmap [story]`. Record the
  baseline at the end of Phase 0, once the scaffold exists and the tools run.

State in one or two sentences what you were least sure about.
