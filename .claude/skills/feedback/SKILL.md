---
name: feedback
description: Turn client feedback into roadmap changes without rewriting or renumbering the plan.
disable-model-invocation: true
argument-hint: [what the client said]

---

## Current roadmap

!`cat ROADMAP.md 2>/dev/null || echo "(no ROADMAP.md)"`

## What has shipped

!`cat HANDOFF.md 2>/dev/null || echo "(no HANDOFF.md)"`

## Client feedback

$ARGUMENTS

## Your task

Do not edit `ROADMAP.md` yet. Do not write code.

**Step 1 — classify each item separately.** Feedback usually bundles several requests of
different kinds, and they need different handling:

| Kind | Handling |
|---|---|
| **Additive** — new behaviour, nothing existing changes | Append a new phase |
| **Modifies planned** — changes a phase that has not shipped | Edit that phase in place; it has no history to protect |
| **Modifies shipped** — changes behaviour already delivered | New phase that supersedes the old one. **Flag this.** |
| **Cancels** — drops something planned | Mark cancelled; check what depended on it |

**Step 2 — check the blast radius on the plan itself.** For each item, ask whether it
invalidates a phase that is planned but not yet built. This is the question nobody asks
and the reason plans drift: a client request that changes a data model can quietly make
three unbuilt phases wrong, and nobody notices until those phases are built.

**Step 3 — output a ROADMAP DECISIONS block.** Stop here and wait for approval.

```
## ROADMAP DECISIONS
- Additive:            [item] → new phase [N]
- Modifies shipped:    [item] → phase [N] supersedes phase [M]
- Modifies planned:    [item] → edits phase [N] in place
- Cancelled:           [item] → phase [N], depended on by [list]
- Planned phases now invalidated: [N, N] — [why, one line each]
- Open question for the client: [anything genuinely ambiguous]
```

**Step 4 — on approval, edit `ROADMAP.md` under these rules, without exception:**

- **Append only.** New phases take the next free number. Never renumber anything.
- **Never delete a phase.** Mark it `superseded by [N]` or `cancelled`.
- **Never edit a shipped phase's description.** It is a record of what was built.
- Update `Depends on:` lines on invalidated phases, and keep every dependency pointing at a
  lower number.
- Add one line to the Change log: what was asked for, what it produced.

**Step 5 — if anything was classified "modifies shipped", say so explicitly.** That is the
trigger condition for OpenSpec. Once feedback starts changing delivered behaviour rather than
adding to it, delta-based specs are worth the setup, because the roadmap alone can no longer
answer what the system currently does.

**On an existing codebase with no `ROADMAP.md`:** every request is effectively "modifies
shipped". Classify and gate it the same way, then let OpenSpec hold the delta instead of
`ROADMAP.md`. If a request changes the stack itself, update `STACK.md` through `/stack`.

Then stop. Implementation starts with `/plan` on the next phase or change, as usual.
