# Project State

*Updated: Phase 6 (deploy) built on `feature/deploy`, local steps ✅; live steps wait on the developer's Supabase/Render/Netlify setup · Status: amber (not live yet) · GitHub: https://github.com/Nakib-Saleh/Stark-VMS (public; `main`, `dev` pushed). `gh` CLI not installed, so merges are local `--no-ff`. Claude files (`.claude/`, CLAUDE.md, HANDOFF, ROADMAP, walkthrough) are untracked + git-ignored before the merge to `main` (developer's call 2026-11-21; old history keeps them, not rewritten). The workflow README moved to `.internal/workflow-template-README.md`.*

## Completed
- Restructured into a monorepo: `backend/` (Spring Boot), `frontend/` (Flutter Web), `docs/adr/`.
- Git: `main` = c29e196, untouched starter code + tooling (the baseline to diff against). `dev` = 3bd181c, ADRs 0001–0003. No remote yet. History was rewritten to strip AI attribution trailers; never add them (see memory).
- ADRs accepted: 0001 monorepo; 0002 page response returns Spring Page fields + `hasNext` (implement in Phase 3); 0003 branching (`main` = submitted/deployed, `dev` = work, `feature/*` PRs into dev, tag `assignment-N` on merge to main, `hotfix/*` off main merged into both).
- `/stack` done (detect mode): STACK.md, `scripts/quality-checks.sh`, `.github/workflows/ci.yml` (Java 21 + Flutter stable + MySQL 8.4 service), `.claude/settings.json`.
- Backend gate checks verified against planted failures: 1 compile error = 1 match (regex skips Gradle's indented repeat), 2 failing tests = 2 matches. 9/9 starter tests pass against Docker MySQL.
- ROADMAP.md written: phases 0–17, definition of done, stretch candidates. Working assumptions: own Spring Security auth with bearer JWT (Phase 4); managed MySQL in production (Phase 6).

- Quality gate fully verified, including `frontend_analyze` (format `  info - msg - lib\file.dart:1:1 - rule`; 3 planted issues counted as 3). Baseline committed: backend_compile 0, backend_test 0, frontend_analyze 8, now 0 after Phase 7 (all `deprecated_member_use` on `package:flutter/material.dart` imports, deprecated after Flutter 3.47). Lefthook deliberately not installed (user's call); CI is the gate.

- Phase 1 (2026-11-21, `feature/env-config`): DB_URL / DB_USERNAME / DB_PASSWORD / CORS_ALLOWED_ORIGINS placeholders with local defaults in `application.properties`; `@CrossOrigin("*")` removed, replaced by `config/CorsConfig.java` (allowedOriginPatterns on `/api/**`, local default `http://localhost:[*],http://127.0.0.1:[*]`, env value replaces default, empty = allow none). `.env.example` at root. ADR-0004 + private note. Tests 14/14 (5 new CORS tests incl. foreign origin refused). walkthrough.md steps 2–9 verified live; step 13 (Flutter in Chrome) and 14 (CI) not yet run.

- Phase 2 (2026-11-21, `feature/harden-vehicle-api`): create/update take `dto/VehicleRequest` (all validation, plain-English messages, server fields absent); entity is persistence-only; numbers stored trimmed + upper case; page size 1–100 and page ≥ 0 give 400 with the real reason (`InvalidRequestException`); duplicates give 409 with `errors.vehicleNumber`, also when MySQL's unique key catches a race; nullable `company` (free text ≤100, optional until the Phase 7 form). Tests 23/23 (new `VehicleApiIntegrationTest` runs on real MySQL). Walkthrough steps 1–13 ✅ live.

- Phase 3 (2026-11-21, `feature/page-response-shape`): `PagedResponse` returns `content, number, size, totalElements, totalPages, last, hasNext` (ADR-0002 implemented; page past the end = 200 empty, `last: true`). `docs/API.md` written: endpoints, page shape, request rules, error shape. Flutter unchanged (its page model ignores the new fields). Tests 25/25. Walkthrough 1–8 ✅ live.

- Phase 4 (2026-11-21, `feature/login-ui-foundation`): Spring Security on all `/api/**` (open: `POST /api/auth/login`, OPTIONS); BCrypt `users` table; HS256 JWT 8h (`JWT_SECRET`, random + warning if unset); admin seeded when no users (`ADMIN_USERNAME`/`ADMIN_PASSWORD`, generated + logged once if unset); same message/time for wrong password vs unknown user; 5 failures per username+address → 429 for 15 min (in-memory). Frontend: go_router (path URLs), landing `/`, `/login`, app frame (navy menu, Dashboard/Drivers "Soon"), not-found; token in Hive box `session`; Dio adds the token, 401 → "session ended"; DESIGN.md tokens + bundled fonts. ADR-0005, ADR-0006. Gate gained `frontend_test` (4 tests). Backend 33/33. Walkthrough steps 1–10, 14 ✅; 11–13 (headless screenshots) blocked; 15–19 (developer's in-app checks) not reported at commit time. CI green on `dev` e65c0dc.

- Phase 7 (2026-11-21, `feature/vehicle-screens`): server-side `q` (number/brand/model/company/driver, contains, ignore case, wildcards literal, ≤100) + `status` on `GET /api/vehicles`, new `GET /api/vehicles/status-counts?q=` (pulled forward from Phase 11; type/driver filters and sort stay there). Frontend rebuilt to DESIGN.md: `/vehicles?page=&q=&status=` (1-based page in URL), `/vehicles/new`, `/vehicles/:id` (transparent panel route over the register), `/vehicles/:id/edit`; numbered pagination; chips with server counts; skeleton rows/panel/form; plate preview with City + Class pickers and auto-dash number (format checked in the form only); 409 links to the existing vehicle; remove dialog (Keep focused); toasts; fresh-row flash and removed-row slide. Papers column left out until Phase 14 (panel says "Not tracked yet"). Starter screens, counter template, `infinite_scroll_pagination`, `material_ui` deleted. Backend 36/36, frontend 6/6, `flutter analyze` 0 (baseline 7 → 0). Walkthrough 1–18 ✅ (developer checked 10–18 in Chrome). Bug found in the check: the panel's `Semantics(scopesRoute: true)` needs `explicitChildNodes: true` or Flutter asserts on row click; widget tests miss it because semantics are off in tests.

- Phase 6 (2026-11-21, `feature/deploy`, in progress): MySQL → PostgreSQL 17 (Supabase live; Aiven free MySQL retired 2026-11-06). V1 rewritten for Postgres (varchar+CHECK enums, upper/lower unique indexes, schema `stark`). `GET /api/health` (open, `{"status":"up"}`), `server.port=${PORT:9001}`, Hikari pool 5, forwarded headers `native`. `backend/Dockerfile` (temurin 21, SerialGC, ~250 MB, 6 s start). Frontend: `API_BASE_URL` dart-define, receive timeout 90 s, waking notice (`lib/network/server_wake.dart` + `widgets/server_wake_notice.dart`, fed by Dio callbacks, probe in `main()`), `web/_redirects`. CI: Postgres service, `deploy-web` job (main only, netlify-cli 27.16.2), gate runs `flutter build web`. README rewritten (no Claude mention). ADR-0008 + private note. Backend 38/38, frontend 6/6.

- Phase 5 (2026-11-21, `feature/schema-migrations`): Flyway owns the schema (`spring-boot-starter-flyway` + `flyway-mysql`, Flyway 12.4.0 managed by Boot). `V1__baseline.sql` transcribes the tables Hibernate had built (diffed with `SHOW CREATE TABLE`: only constraint names differ, now `uk_vehicles_vehicle_number`, `uk_users_username`, `ck_vehicles_manufacturing_year`). `ddl-auto=validate`. No `baseline-on-migrate`: the local DB was recreated once from V1 (demo data re-seeded, new admin password). ADR-0007 + private note. Backend 36/36. Walkthrough 1–9 ✅ (all [Claude]; no UI change).

## Local environment (Windows, user's machine)
- JDK 21 (`C:\Program Files\Microsoft\jdk-21.0.13.102-hotspot`) alongside JDK 17; Gradle toolchain picks 21.
- PostgreSQL 17 in Docker container `stark-postgres`, 127.0.0.1:5432, trust auth (no password, localhost only), volume `stark-postgres-data`, DB `stark_group_vms`, tables in schema `stark`. Start with `docker start stark-postgres`. Old `stark-mysql` container is unused since Phase 6 (delete when the developer agrees). Windows `MySQL80` service stopped + Manual.
- Flutter 3.50.1 / Dart 3.14.0 at `C:\dev\flutter` (stable), on the user PATH. The first-run setup once hung on a stalled `git fetch --tags` to GitHub; killing it and re-running fixed it. If Flutter hangs at "Building flutter tool", check for a stuck `git fetch`.
- User's terminal is Windows PowerShell 5.1: give user-facing commands in PowerShell syntax (no `&&`).

## Data model — entities and access rules
- `users` (Phase 4): `username` unique (≤50), `password_hash` BCrypt, `created_at`. No API to create users; only the seeder. Every `/api/**` route except sign-in requires a valid JWT (any signed-in user may do everything; roles are Phase 17).
- Schema is owned by Flyway (ADR-0007, ADR-0008): `backend/src/main/resources/db/migration/V<n>__<what>.sql`, PostgreSQL SQL, schema `stark`. Any entity change needs a new migration in the same commit; never edit one that has run (checksum stops startup). Hibernate only validates. Enum columns are varchar + `CHECK (... IN (...))`, so a new status/type/fuel value needs a migration that drops and re-adds the check.
- `vehicles` (Postgres): unique index `uk_vehicles_vehicle_number` on `UPPER(vehicle_number)` (GlobalExceptionHandler matches this name for the race → 409); `users`: unique `uk_users_username` on `LOWER(username)`. Readable and writable by any signed-in user. Supabase Data API off and nothing in `public`, so the API is the only way in.

## Reusable utilities and components — CHECK BEFORE CREATING ANYTHING NEW
- Data access / clients: `frontend/lib/network/dio_client.dart`, `frontend/lib/network/vehicle_api.dart` (Retrofit), `frontend/lib/repositories/vehicle_repository.dart`; backend `.../repository/VehicleRepository.java`
- Auth (backend): `.../config/SecurityConfig.java` (filter chain, BCrypt, JWT encoder/decoder, 401/403 via GlobalExceptionHandler), `.../auth/AuthController.java`, `LoginThrottle`, `AdminSeeder`. Tests: `@WithMockUser` for vehicle tests; `AuthIntegrationTest` for real tokens.
- Auth (frontend): `lib/auth/auth_controller.dart` (`authProvider`, `sessionBoxProvider`), `lib/router.dart` (`routerProvider`, `safeNext`), token added in `lib/network/dio_client.dart`
- New-design UI: `lib/theme/stark_tokens.dart` (colours, fonts, radius, motion, `StarkText`), `lib/theme/stark_theme.dart`, `lib/widgets/stark_page.dart` (`StarkPage`, `Spinner`, `Rule`), `number_plate.dart` (`NumberPlate`, sm/lg/xl), `brand.dart`, `app_frame.dart`. New files import `flutter/widgets.dart` + shadcn only, never Material (see private note 0005-0006).
- State: `frontend/lib/providers/vehicle_providers.dart`: `vehiclePageProvider(VehicleQuery)`, `statusCountsProvider(q)`, `vehicleProvider(id)` (all autoDispose, no auto-retry), `refreshVehicles(ref)` after any mutation, `rowMarkProvider` (fresh/leaving row), `vehicleFormProvider` (submit + server errors, `isConflict`)
- URLs: `lib/screens/vehicle_urls.dart` (`vehicleQueryFromUri`, `vehiclesUrl(query, path:)`, `firstPage`): every vehicle link keeps the register's page/search/filter
- UI primitives: `lib/widgets/labeled_field.dart` (`LabeledField`, label + error/hint; login uses it), `vehicle_status.dart` (`StatusMark`, `statusColor`), `register_pagination.dart`, `stark_toast.dart` (`showStarkToast`), `NumberPlate.preview` / `NumberPlate.spoken` / `NumberPlate.cities`, `motion(context, d)` in `stark_page.dart` (reduce motion → 0)
- Server waking / unreachable: `serverWakeProvider` (`lib/network/server_wake.dart`); any Dio request is tracked automatically, so never add a second slow-request indicator.
- Loading / progress feedback: skeletonizer wrapping the real widget with fake data (register, panel, form); `Spinner` + verb on busy buttons. Never a centred spinner.
- Page transitions: `_enterPage` / `_panelPage` in `lib/router.dart`
- Config / CORS: `.../config/CorsConfig.java` (all `/api/**` CORS lives here; never add `@CrossOrigin`); env vars listed in `.env.example`
- Web-layer tests: `@WebMvcTest` is `org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest`, mocks via `org.springframework.test.context.bean.override.mockito.MockitoBean` (Boot 4 packages; see `.../config/CorsConfigTest.java`)
- Request DTO + errors: `.../dto/VehicleRequest.java` (never bind the entity); `InvalidRequestException(message, fieldErrors)` → 400 and `DuplicateResourceException(field, message)` → 409, both rendered with `errors.<field>` so the UI can place them next to the field
- Real-DB tests: `VehicleApiIntegrationTest` (`@SpringBootTest` + `@AutoConfigureMockMvc` from `org.springframework.boot.webmvc.test.autoconfigure`; test data prefixed `TEST-IT-`, deleted after each test)
- Migrations: `backend/src/main/resources/db/migration/` (V1 = baseline). Proving a migration: drop schema `stark` in the local DB (`docker exec stark-postgres psql -U postgres -d stark_group_vms -c "DROP SCHEMA stark CASCADE"`), start the app, check `\d stark.<table>`.
- API contract: `docs/API.md`. Update it in the same commit as any endpoint, field or error change (Phase 4 adds Login).
- Shared helpers: backend errors `.../exception/GlobalExceptionHandler.java`; paging `.../dto/PagedResponse.java` (7 fields, add never rename); frontend config `frontend/lib/config/api_config.dart`
- (`...` = `backend/src/main/java/com/example/stark_group_vms`)

## Conventions specific to this project
- Claude acts as tech lead: plain-language options, pros/cons, recommendation; user approves. Label each decision "engineering call" or "requirements question".
- Decision records are two-tier: private teaching note in `.internal/decisions/NNNN-*.md` (git-ignored), short public ADR in `docs/adr/NNNN-*.md` run through `humanize-md`, written in the user's first-person voice ("I"), committed with the code it governs. Shared numbering. Next free number: 0009.
- Quote sources exactly (file:line, who, when) before saying "the spec says". The page-shape spec is Naimul's Discord note (`Guides/DiscordChat.txt:103-112`), not the official course doc.
- `Guides/` (course material) is git-ignored.
- Instructor questions sent, no reply yet: one repo vs two; page shape. Proceeding with ADR-0001/0002.

## Next up
1. Finish Phase 6: developer does walkthrough S1–S3, then Claude untracks Claude files, merges `dev` → `main`, pushes, runs live steps 12–20; developer runs 21–23. Then `/plan 8`.
- Design: DESIGN.md (direction "Number Plate", prototype https://claude.ai/artifact/GoyQDDWuLnDdNH64Yu3qTS). Pages: landing `/`, `/login`, `/vehicles`, `/vehicles/new`, `/vehicles/:id`, `/vehicles/:id/edit`; A2 adds `/dashboard` (first page after sign-in), `/drivers`; documents and maintenance as tabs on vehicle detail. No sign-up, no forgot-password.
- Phase 7 has no before/after screenshots (no PR: merged locally because `gh` isn't installed, and headless screenshots render blank). Add them when the first PR is opened.
- Headless screenshots of the Flutter app need a release build (`flutter build web` + static server); the debug web-server stays blank.

## Starter frontend review findings (2026-11-20, from code; not yet run visually)
- (resolved Phase 7) Search + status filter were client-side over loaded pages; now server-side.
- (resolved Phase 7) Status counts now come from the server (`status-counts`).
- (resolved Phase 7) Counter template deleted.
- (Phase 7) Vehicle screens have Semantics labels (rows, chips, pagination, panel, plate); keyboard: rows open on Enter/Space, Escape closes the panel. Not yet checked with a screen reader.
- No login screen, though the course videos reference an "existing" one. Requirements question sent: OK to build on the starter vs rebuild from scratch?

## Known shortcuts deferred
- Plate format (`CITY-METRO-CLASS-NN-NNNN`) is checked in the form only; the API still takes any number up to 50 characters (so `TEST-IT-` test plates and odd legacy rows still save). Add an `@Pattern` in `VehicleRequest` if every plate must match. Non-metro plates aren't supported by the form.
- Available and In use both show a green dot until the Phase 9 status rework.
- Panel scrim and floating shadow use `navy` with alpha (DESIGN.md has no scrim/shadow token yet); add tokens via `/feedback` if the look changes.
- Local admin password changed when the DB was recreated in Phase 5 (new one given to the developer in chat, not stored in the repo).
- Schema baseline keeps Hibernate's column sizes: `vehicle_number`, `brand`, `model`, `color`, driver fields are `varchar(255)` though the API caps them at 50/100. Tighten in a later migration after checking existing rows.
- Local backend run for the walkthrough uses a JWT_SECRET kept in Claude's scratchpad; restarting without it signs everyone out (as before).
- Headless Chrome screenshots of the release build render blank since Phase 4 (Hive/IndexedDB opened before runApp; no console errors). Real Chrome is fine. Instrument: console.log before/after `Hive.initFlutter`/`openBox`, capture headless console.
- Login throttle is in-memory (resets on restart, not shared across instances). Behind Render the address comes from `server.forward-headers-strategy=native` (Tomcat, rightmost untrusted X-Forwarded-For); live spoof check = walkthrough step 18.
- Signing out only forgets the token on the device; no server-side revocation (8h expiry).
- `config/DataSeeder.java` seeds 20 demo vehicles whenever the table is empty, live site included (developer's call 2026-11-21).
- (resolved) CI Flutter pinned to 3.50.1 to match local.
