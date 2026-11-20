# ADR-0001: Keep backend and frontend in one repository

Status: Accepted · Date: 2026-11-20

## Context

Stark VMS has a Spring Boot backend and a Flutter Web frontend. I'm building both on my own, and every feature I have planned (drivers, documents, maintenance, dashboard) changes both sides.

Most of those features need a change to the API and to the screen that uses it at the same time. If the two changes live in different repositories, they can be merged at different times, and the app is broken in between. I wanted a setup where they can't drift apart.

## Options I considered

1. Two repositories. This makes sense when separate teams own each side, with their own release cycles or access rights. For me it would mean two pull requests per feature and two places to keep in sync.
2. One repository with `backend/` and `frontend/`. An API change and the client code that depends on it land in the same commit, and I get one README, one CI pipeline and one decision log. Netlify and Render can both deploy from a subfolder, so hosting isn't a problem.
3. Git submodules. I ruled these out. They bring the coordination cost of two repos plus extra tooling to learn.

## Decision

I'm using one repository with `backend/`, `frontend/` and `docs/adr/` at the root.

My rule of thumb is that repository boundaries should follow team boundaries. I'm one person building features end to end, so keeping everything in one place keeps the API contract and the app that uses it in step.

## Consequences

CI has to set up both Java and Flutter.

If the submission turns out to need separate repositories, I can pull each folder out with `git subtree split` and keep its history. So this is an easy decision to reverse.
