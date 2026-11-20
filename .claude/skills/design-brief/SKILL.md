---
name: design-brief
description: Establish a design direction and lock tokens into DESIGN.md before any UI is built. Runs after /stack; skips itself when there is nothing to design.
disable-model-invocation: true
argument-hint: [path to the project story — optional]
---

## Stack

!`cat STACK.md 2>/dev/null || echo "(no STACK.md — run /stack first)"`

## Project story

!`if [ -n "$ARGUMENTS" ] && [ -f "$ARGUMENTS" ]; then cat "$ARGUMENTS"; else echo "(no story file given)"; fi`

## Existing design

!`cat DESIGN.md 2>/dev/null || echo "(no DESIGN.md yet)"`

## Your task

Do not write any UI code until Step 5.

**Step 0 — check whether there is anything to design.**

- No `STACK.md` → stop and tell the developer to run `/stack` first.
- `Has a UI: no` (API, CLI, library, worker) → stop. Say in one line that there is
  nothing to design, and that the next step is `/roadmap`.
- `DESIGN.md` already exists → stop. A direction is already locked, and changing it is
  feedback, so it goes through `/feedback`.
- The repository already has a design in use (theme files, a global stylesheet, a
  component library config) → **extract it, don't invent one.** Read the theme
  config and three representative screens, then write down the colours, typefaces,
  spacing and radii that are actually in use. A value that shows up only once or twice
  was probably an accident, not a rule. Skip to Step 4, and tell the developer to
  edit the result personally.

**Step 1 — interrogate.** Use the project story to answer what it can. Ask only what's
still missing, and wait for real answers. "Make it look modern" is not an answer.

1. What is this business actually like? One or two sentences, concrete.
2. Who uses this, and what state of mind are they in? (A rushed dispatcher and an anxious
   patient need different screens.)
3. Name two products whose look you want, **and why**. A reference without a reason
   gets copied at the surface instead of for the decision behind it.

**Step 2 — propose a written design plan** before any code, following the
`frontend-design` skill:
- A named direction you commit to. Not "clean and modern".
- 4–6 colour tokens, named after things in this project, not taken from a framework palette.
- Typefaces and their roles, chosen deliberately (or platform type styles, on native).
- Layout concept and spacing scale.
- Three specific things this design will NOT do, taken from the generic defaults.

Ground every choice in the subject from Step 1. A freight company and a medical portal
should not be able to swap designs.

**Step 3 — the developer reviews the plan, not a built screen.** Rejecting a palette
costs nothing. Rejecting a built screen costs a rebuild.

**Step 4 — once approved, write `DESIGN.md`.** Record the tokens in this stack's
native format: CSS custom properties, a Tailwind theme, Flutter `ThemeData`, SwiftUI
colour assets, Compose `MaterialTheme`, and so on. Every later unit reads tokens from
this file and never invents a new value.

**Step 5 — build the first screen shell** (landing page, main screen or app frame) with
those tokens and placeholder copy. Real copy waits until the product is defined. Take a
screenshot if you can, critique it against the brief, and fix anything that looks like a
default rather than a choice.
