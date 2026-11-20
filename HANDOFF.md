# Project State

*Updated: repo restructure (ADR-0001) · Status: green*

## Completed
- Restructured into a monorepo: `backend/` (Spring Boot), `frontend/` (Flutter Web), `docs/adr/`. `git init` on `main`, nothing committed yet.
- ADR-0001 (one repo) written: private note in `.internal/decisions/`, public in `docs/adr/0001-monorepo.md` (reviewed, final, first-person voice).

## Data model — entities and access rules
- `vehicles` (MySQL, `ddl-auto=update`): no access control yet; no auth exists on backend or frontend.

## Reusable utilities and components — CHECK BEFORE CREATING ANYTHING NEW
- Data access / clients: `frontend/lib/network/` (Dio + Retrofit), `frontend/lib/repositories/`
- Auth helpers: none yet
- State: `frontend/lib/providers/` (Riverpod)
- UI primitives: `frontend/lib/widgets/` (shadcn_ui)
- Backend errors: `backend/.../exception/GlobalExceptionHandler.java`

## Conventions specific to this project
- Decision records are two-tier: private teaching note in `.internal/decisions/NNNN-*.md` (git-ignored), short public ADR in `docs/adr/NNNN-*.md` run through `humanize-md`, written in the user's first-person voice ("I"), never a third-party voice, committed with the code it governs. Shared numbering.
- `Guides/` (course material) is git-ignored.

## Next up
- User reviews ADR-0001 public copy; then run `/stack` (detect mode: existing codebase, two toolchains).
- Open review findings to turn into ADRs: pagination contract mismatch (`hasNext` vs spec's Spring Page shape, a requirements question), no login anywhere, entity used as request body, `@CrossOrigin("*")`, unbounded page size, case-sensitive unique constraint, status enum vs Assignment 2, driver fields on vehicle, document storage on Render's temporary disk, MySQL availability on Render.

## Known shortcuts deferred
- none yet
