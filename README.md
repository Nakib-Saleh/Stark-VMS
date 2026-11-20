# Claude Code Workflow Template

A reusable, stack-agnostic AI development workflow: engineering rules, a rolling state
ledger, workflow skills, and a baseline-aware quality gate enforced at git and CI level.
The stack is decided per project by `/stack`. Nothing in the template assumes one.

## The flow

```
PRE-PHASE (once)
  /stack [story.md]        choose a stack from the story, or detect the repo's  → STACK.md, gate config
  /design-brief [story.md] only if there is a UI and no design yet              → DESIGN.md
  /roadmap [story.md]      new projects only                                    → ROADMAP.md (read it in full)

EVERY UNIT  (a phase on a new project, a change on an existing one)
  /clear → /plan [N] → read DECISIONS → build → /verify → /ship → run walkthrough.md → /clear

EVERY TIME THE CLIENT SPEAKS
  /feedback [what they said] → read ROADMAP DECISIONS → approve → /plan

BUGS
  /bug [evidence]          never prose; two-round limit, then instrumentation
```

Every gate (STACK, DECISIONS, ROADMAP DECISIONS) works the same way. The agent states
what it's about to do and what it's giving up, and you say yes or redirect. Reading one
takes about a minute, and it's the highest-leverage minute in the loop.

## Files

```
CLAUDE.md                       always-loaded rules; imports STACK.md
STACK.md                        created by /stack: stack, commands, stack-specific rules
DESIGN.md                       created by /design-brief (UI projects only)
ROADMAP.md                      append-only phases; numbers are permanent IDs
HANDOFF.md                      rolling project state, capped at 120 lines
walkthrough.md                  acceptance test, rewritten per unit
.claude/settings.json           model + permissions (/stack adds the stack's commands)
.claude/skills/                 stack · design-brief · roadmap · plan · verify · bug · ship · feedback · frontend-design
scripts/quality-ratchet.sh      generic baseline-aware gate
scripts/quality-checks.sh       per-stack checks (created by /stack from the .example)
.quality-baseline.json          current known-failure counts (commit it)
lefthook.yml                    pre-commit gate
.github/workflows/ci.yml        remote gate (/stack fills the toolchain block)
```

## Setup

**New project**
1. Copy the template in: `CLAUDE.md`, `HANDOFF.md`, `ROADMAP.md`, `.claude/`, `scripts/`,
   `lefthook.yml`, `.github/`.
2. Run `/stack path/to/story.md`, then `/design-brief` if the project has a UI, then `/roadmap`.
3. Phase 0 scaffolds the project. At the end of it, install Lefthook (`npx lefthook install`,
   `brew install lefthook` or `go install`) and record the baseline with
   `bash scripts/quality-ratchet.sh --baseline`, which should come out at zero.

**Existing codebase.** No application changes until step 5.
1. Copy the template in, then run `/stack` with no argument. It detects the stack and
   doesn't choose one.
2. Record the real baseline with `bash scripts/quality-ratchet.sh --baseline`. A non-zero
   count is expected here.
3. If the repo is large, build a code graph (Graphify). Then do a one-time security pass
   over the whole surface against `STACK.md`'s rules, because diff-based review only ever
   sees new code.
4. `/design-brief` extracts the design already in use instead of inventing one. Edit
   `STACK.md`, `DESIGN.md` and `HANDOFF.md` yourself afterwards, since the agent will
   happily write up an accidental pattern as a rule.
5. Skip `/roadmap`. Route the next change that was going to happen anyway through
   `/feedback` and then `/plan`.

> Don't treat day 0 as a cleanup project. The ratchet exists so you don't have to pay
> down legacy warnings before shipping anything.

## Why it's built this way

- **Nothing grades its own homework.** The agent plans and builds, and a gate that can
  fail says no. On a new project the ratchet is strict, because the baseline is zero. On
  an existing one it only fails on failures that weren't there before.
- **Context is the budget.** Every skill except `verify` sets `disable-model-invocation`,
  which keeps its description out of context. `STACK.md` stays under 60 lines because it
  loads on every message. Use `/clear` plus `HANDOFF.md` between units instead of `/compact`.
- **`verify` stays model-invocable on purpose.** Claude Code's commit flow runs a
  project skill named `verify` before committing.
- **Evidence beats search.** `/bug` won't search the codebase without captured evidence,
  and it stops after two rounds.
- **Decide the stack from the story.** The stack is picked from what the product actually
  needs, and the design comes after the product is understood. A choice made in a vacuum
  comes out as the statistical average.

## Triggered additions (wait for the symptom)

- **Graphify**: add it when the agent keeps running exploratory searches despite having
  LSP and evidence. On a large existing codebase that has already happened. Set
  `GRAPHIFY_QUERY_LOG_DISABLE=1` on client code.
- **OpenSpec**: add it the first time feedback changes behaviour that has already shipped.
  On an existing codebase that's immediate.

## Measuring it

Check `/usage` and `/skill-doctor` before you start and again after two weeks. Count
tool-use rounds per bug, since the two-round limit should hold. If the gate never fails
in two weeks, the checks are too loose.

If the tooling ever feels like overhead, strip it down to three things: a gate that can
fail, evidence before theory on bugs, and a minute spent on every DECISIONS block.
