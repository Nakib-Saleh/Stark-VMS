---
name: verify
description: Run the project's quality gate — the checks configured for this stack — and fix what this change broke. Run before every commit.
allowed-tools: Bash(bash scripts/quality-ratchet.sh *) Bash(git diff *) Bash(git status *)
model: claude-sonnet-5-5
---

## Gate result

!`bash scripts/quality-ratchet.sh 2>&1 || true`

## Changed files

!`git status --short 2>/dev/null || true`

## Your task

The commands and stack-specific rules are in `STACK.md`, which is loaded through `CLAUDE.md`.

1. If the gate above says it isn't configured, stop and tell the developer to run `/stack`.
2. If the gate reports new failures, fix only those. Leave pre-existing baseline failures
   alone unless the developer asks.
3. If this change touched routing, config, build settings, schemas or anything else that
   only fails at build time, run the **build** command from `STACK.md`.
4. If this change touched an area covered by a stack-specific rule (schema, auth,
   env vars, security rules), check the change against each of those rules and fix any
   breach before passing.
5. If the change touched an area that `CLAUDE.md` §3 says must be tested, run the **test**
   command from `STACK.md`.
6. Re-run the gate until it passes.
7. Report in one line: passed, or what's still failing and why.
