# ADR-0003: Use `main` for submissions and `dev` for ongoing work

Status: Accepted · Date: 2026-11-20

## Context

The instructors will review Assignment 1 while I'm building Assignment 2. Netlify and Render redeploy whenever `main` changes, so whatever is on `main` is also what's on the live link. I need unfinished work to stay away from both.

## Options I considered

Committing straight to `main` would put half-built features in front of reviewers. Trunk-based development works well for larger teams, but it relies on feature flags and a very strong test suite to hide unfinished work, which is more than this project needs. Full GitFlow, with release and hotfix branches, is too much ceremony for one developer.

## Decision

I keep two long-lived branches. `main` holds what I've submitted and is what gets deployed. `dev` is where I work.

Each piece of work gets a short branch off `dev` (for example `feature/login`) and goes back in through a pull request, so CI checks it and there's a record of why it changed. When an assignment is finished I merge `dev` into `main` and tag it (`assignment-1`, `assignment-2`), so the exact submitted version is always one click away.

The first commit on `main` is the starter code exactly as I received it. Comparing it with any later commit shows what I built myself.

If a serious bug turns up in a submitted version, I fix it on a `hotfix/` branch off `main` and merge it into both `main` and `dev`.

## Consequences

Every change goes through a pull request, which is slower than committing directly. Hotfixes have to be merged back into `dev` as well, or the two branches drift apart.
