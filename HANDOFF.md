# Project State

*Updated: Phase 1 (config from environment) shipped · Status: green · GitHub: https://github.com/Nakib-Saleh/Stark-VMS (public; `main`, `dev` pushed). Actions had to be enabled by hand; first CI run green on `dev` 3e2a69d. `gh` CLI not installed, so merges are local `--no-ff` until it is.*

## Completed
- Restructured into a monorepo: `backend/` (Spring Boot), `frontend/` (Flutter Web), `docs/adr/`.
- Git: `main` = c29e196, untouched starter code + tooling (the baseline to diff against). `dev` = 3bd181c, ADRs 0001–0003. No remote yet. History was rewritten to strip AI attribution trailers; never add them (see memory).
- ADRs accepted: 0001 monorepo; 0002 page response returns Spring Page fields + `hasNext` (implement in Phase 3); 0003 branching (`main` = submitted/deployed, `dev` = work, `feature/*` PRs into dev, tag `assignment-N` on merge to main, `hotfix/*` off main merged into both).
- `/stack` done (detect mode): STACK.md, `scripts/quality-checks.sh`, `.github/workflows/ci.yml` (Java 21 + Flutter stable + MySQL 8.4 service), `.claude/settings.json`.
- Backend gate checks verified against planted failures: 1 compile error = 1 match (regex skips Gradle's indented repeat), 2 failing tests = 2 matches. 9/9 starter tests pass against Docker MySQL.
- ROADMAP.md written: phases 0–17, definition of done, stretch candidates. Working assumptions: own Spring Security auth with bearer JWT (Phase 4); managed MySQL in production (Phase 6).

- Quality gate fully verified, including `frontend_analyze` (format `  info - msg - lib\file.dart:1:1 - rule`; 3 planted issues counted as 3). Baseline committed: backend_compile 0, backend_test 0, frontend_analyze 8 (all `deprecated_member_use` on `package:flutter/material.dart` imports, deprecated after Flutter 3.47). Lefthook deliberately not installed (user's call); CI is the gate.

- Phase 1 (2026-11-21, `feature/env-config`): DB_URL / DB_USERNAME / DB_PASSWORD / CORS_ALLOWED_ORIGINS placeholders with local defaults in `application.properties`; `@CrossOrigin("*")` removed, replaced by `config/CorsConfig.java` (allowedOriginPatterns on `/api/**`, local default `http://localhost:[*],http://127.0.0.1:[*]`, env value replaces default, empty = allow none). `.env.example` at root. ADR-0004 + private note. Tests 14/14 (5 new CORS tests incl. foreign origin refused). walkthrough.md steps 2–9 verified live; step 13 (Flutter in Chrome) and 14 (CI) not yet run.

## Local environment (Windows, user's machine)
- JDK 21 (`C:\Program Files\Microsoft\jdk-21.0.13.102-hotspot`) alongside JDK 17; Gradle toolchain picks 21.
- MySQL 8.4 in Docker container `stark-mysql`, bound to 127.0.0.1:3306, empty root password, volume `stark-mysql-data`. Start with `docker start stark-mysql`. Windows `MySQL80` service stopped + set Manual (it held port 3306; user doesn't use it).
- Flutter 3.50.1 / Dart 3.14.0 at `C:\dev\flutter` (stable), on the user PATH. The first-run setup once hung on a stalled `git fetch --tags` to GitHub; killing it and re-running fixed it. If Flutter hangs at "Building flutter tool", check for a stuck `git fetch`.
- User's terminal is Windows PowerShell 5.1: give user-facing commands in PowerShell syntax (no `&&`).

## Data model — entities and access rules
- `vehicles` (MySQL, `ddl-auto=update`): no access control yet; no auth exists on backend or frontend.

## Reusable utilities and components — CHECK BEFORE CREATING ANYTHING NEW
- Data access / clients: `frontend/lib/network/dio_client.dart`, `frontend/lib/network/vehicle_api.dart` (Retrofit), `frontend/lib/repositories/vehicle_repository.dart`; backend `.../repository/VehicleRepository.java`
- Auth helpers: none yet
- State: `frontend/lib/providers/vehicle_providers.dart` (Riverpod)
- UI primitives: `frontend/lib/widgets/` (shadcn_ui): badges, delete dialog, detail sheet, row card
- Loading / progress feedback: skeletonizer + infinite_scroll_pagination in `frontend/lib/screens/vehicle_list_screen.dart`
- Config / CORS: `.../config/CorsConfig.java` (all `/api/**` CORS lives here; never add `@CrossOrigin`); env vars listed in `.env.example`
- Web-layer tests: `@WebMvcTest` is `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest`, mocks via `org.springframework.test.context.bean.override.mockito.MockitoBean` (Boot 4 packages; see `.../config/CorsConfigTest.java`)
- Shared helpers: backend errors `.../exception/GlobalExceptionHandler.java`; paging `.../dto/PagedResponse.java`; frontend config `frontend/lib/config/api_config.dart`
- (`...` = `backend/src/main/java/com/example/stark_group_vms`)

## Conventions specific to this project
- Claude acts as tech lead: plain-language options, pros/cons, recommendation; user approves. Label each decision "engineering call" or "requirements question".
- Decision records are two-tier: private teaching note in `.internal/decisions/NNNN-*.md` (git-ignored), short public ADR in `docs/adr/NNNN-*.md` run through `humanize-md`, written in the user's first-person voice ("I"), committed with the code it governs. Shared numbering. Next free number: 0005.
- Quote sources exactly (file:line, who, when) before saying "the spec says". The page-shape spec is Naimul's Discord note (`Guides/DiscordChat.txt:103-112`), not the official course doc.
- `Guides/` (course material) is git-ignored.
- Instructor questions sent, no reply yet: one repo vs two; page shape. Proceeding with ADR-0001/0002.

## Next up
0. DONE 2026-11-21: DESIGN.md written (direction "Number Plate"; prototype https://claude.ai/artifact/GoyQDDWuLnDdNH64Yu3qTS). Every UI phase reads tokens from it. The prototype also previews A2 ideas (Company field, paper expiry, ACTIVE/MAINTENANCE/INACTIVE). Next: start Phase 1.
1. (superseded by DESIGN.md) Run `/design-brief` for a full redesign (not a capture of the starter): Stark Group guideline as the base (left menu, deep/corporate blue, green = active, red = delete/errors, white cards), landing page, app frame. Keep shadcn_ui as the component kit. Pages and flow agreed 2026-11-20: landing `/`, `/login`, `/vehicles`, `/vehicles/new`, `/vehicles/:id`, `/vehicles/:id/edit`; A2 adds `/dashboard` (first page after sign-in), `/drivers`; documents and maintenance live as tabs on the vehicle detail page. No sign-up, no forgot-password.
   (Done 2026-11-20: ran the app with the user. API on 9001 returns 20 seeded vehicles; starter UI screenshot reviewed. Note: headless screenshots need a release build; the debug web-server stays blank.)
2. Push to GitHub: ask the user first (outward-facing). Check CI goes green on the first push.
3. Start Phase 1 (config from environment) on `feature/env-config` via the DECISIONS gate.

## Starter frontend review findings (2026-11-20, from code; not yet run visually)
- Search + status filter are client-side over loaded pages only (`frontend/lib/screens/vehicle_list_screen.dart:73-81`); misses unloaded vehicles. Proper fix = server-side search (Phase 11).
- Status summary counts computed from loaded vehicles only (`vehicle_list_screen.dart:408`), wrong once >1 page. Fix in Phase 7, or hide until Phase 15 dashboard.
- `frontend/lib/home_page.dart` is the unused Flutter counter template: delete (Phase 7).
- No Semantics/accessibility labels anywhere (Phase 7).
- No login screen, though the course videos reference an "existing" one. Requirements question sent: OK to build on the starter vs rebuild from scratch?

## Known shortcuts deferred
- `config/DataSeeder.java` seeds 20 demo vehicles whenever the table is empty, in every environment including production. Decide in Phase 6 (demo data on the live site, or local only).
- Frontend API base URL is hard-coded in `frontend/lib/config/api_config.dart`; make it a `--dart-define` in Phase 6.
- `scripts/quality-checks.sh` — no `flutter build web` in BUILD_CMD; add before Phase 6.
- (resolved) CI Flutter pinned to 3.50.1 to match local.
