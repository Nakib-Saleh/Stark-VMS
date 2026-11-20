---
name: roadmap
description: Turn a project story / requirements document into a phased roadmap with forward-only dependencies. New projects only; runs after /stack and /design-brief.
disable-model-invocation: true
argument-hint: [path to the project story / requirements document]
---

## Requirements document

!`if [ -n "$ARGUMENTS" ] && [ -f "$ARGUMENTS" ]; then cat "$ARGUMENTS"; else echo "(no file given — ask for the story path)"; fi`

## Design

!`if [ -f DESIGN.md ]; then echo "DESIGN.md exists — direction is locked."; else echo "(no DESIGN.md)"; fi`

## Your task

Produce `ROADMAP.md`, following the template in the repository. Do not write any code.
The stack is already decided in `STACK.md`. Plan within it and don't reopen it. If
`STACK.md` is missing, stop and ask for `/stack` first.

On an existing codebase, don't use this skill. Inventing a phase sequence after the
fact documents history nobody asked for. Route each change through `/feedback` instead.

**Step 1 — features.** Identify the major and minor subsystems this product needs.
Anything the requirements leave genuinely ambiguous goes down as an explicit question,
not as a silent assumption.

**Step 2 — phases.** Sequence the work under three hard constraints:

- **Forward-only dependencies.** A phase may depend only on lower-numbered phases. If you
  find yourself wanting a backward dependency, the phases are in the wrong order. Reorder
  them now, while that costs nothing.
- **Demo-centric.** At least one phase in every three must deliver something a person can
  try out: a screen, a command, an endpoint they can call. Mark it `Demo: yes`. Demos are
  the only source of real feedback in this loop, so treat this as a hard constraint.
- **Phase 0 is the foundation.** It scaffolds the project on the chosen stack and gets the
  quality gate running with its baseline recorded. If the project has a UI, it also builds
  the first screen shell from `DESIGN.md`.

**Step 3 — size check.** A phase that can't be built and verified in one working session
is too large, so split it. If a phase's `Delivers:` line can't be written in terms a user
would see, it's probably infrastructure that belongs inside another phase.

**Step 4 — output `ROADMAP.md`**, then stop. In two or three sentences, say what you were
unsure about, so the developer knows where to look hardest.

The developer reads this document in full. It's the only long document in the project
that gets read, so write it for a human.
