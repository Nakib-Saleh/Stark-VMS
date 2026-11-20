# Roadmap

Phase numbers are permanent IDs. Never renumber. Never delete a phase.
A phase that is no longer wanted is marked superseded or cancelled, not removed.
(One-time exception: phases were renumbered on 2026-11-20 before the roadmap was first committed. The rule applies from the first commit on.)

**Status values:** planned · in progress · shipped · superseded by [N] · cancelled

Each phase = one `feature/*` branch → PR into `dev` (ADR-0003). Phases that need a
decision get an ADR before code. Tests per CLAUDE.md §3 ship inside the phase.

**Execution order (Assignment 1):** 0 → 1 → 2 → 3 → 4 → **7** → 5 → 6 → 8. Numbers are IDs;
dependencies set the order. Phase 7 only needs 4, so the new UI lands before migrations and
deploy, and nothing is tested against the starter UI for long.

## Definition of done (every phase, before its PR merges)
- Every screen has loading, empty and error states. No blank page, no endless spinner.
- Server errors (400/409) appear next to the field they belong to, in plain words.
- Submit buttons are disabled while saving (no double-create). Form input survives a failed save.
- Destructive actions ask for confirmation.
- Works at phone width; interactive elements have accessible labels.
- From Phase 4 on, every screen a phase adds or changes is built to DESIGN.md. After Phase 7 no phase relies on the starter UI.
- Quality gate green; tests for any auth, access-rule, mutation or delete logic it touches.
- Public ADR (first-person, humanized) + private note for any decision made; HANDOFF.md updated.

---

## Assignment 1 — rebuild the core VMS (release: tag `assignment-1` on `main`)

### Phase 0 — Foundation · shipped
Depends on: —
Delivers: monorepo, STACK.md, quality gate verified against real failures, CI, ADRs 0001–0003, this roadmap
Demo: no

### Phase 1 — Configuration from environment · shipped
Depends on: 0
Delivers: DB URL/user/password and allowed origins read from env vars with local defaults; `.env.example`; ADR
Demo: no

### Phase 2 — Harden the vehicle API · shipped
Depends on: 1
Delivers: request/response DTOs instead of entity, page `size` cap, case-insensitive unique vehicle number at DB level, 400/409 tests; add `company` field to vehicles (course field list, transcripts.md:488)
Demo: no

### Phase 3 — Page response shape · planned
Depends on: 2
Delivers: ADR-0002 implemented (Spring Page fields + `hasNext`), API test for all seven fields, API.md updated; starter list screen adapted to the new shape so it keeps working until Phase 7
Demo: no

### Phase 4 — Login + new UI foundation (backend + frontend) · planned
Depends on: 2
Delivers: ADR on session approach; Spring Security on every endpoint, hashed passwords, seeded user; tests as unauthenticated user. Frontend foundation to DESIGN.md: theme tokens and bundled fonts, URL-based routing with auth-guarded routes (routing package decided at /plan), public landing page (`/`, what it is + Sign in + GitHub link, no demo credentials), sign-in screen, app frame (left menu, top bar with user and sign out), not-found page. The starter vehicle screens sit inside the new frame until Phase 7.
Working assumption (agreed 2026-11-20, confirm in ADR): own auth in Spring Security, no Clerk/Auth0/Supabase Auth (login is a graded skill on a Spring course). Bearer token in the `Authorization` header, not a cookie (Netlify and Render are different domains). Spring Security's built-in JWT support, no extra library. No public sign-up: admin seeded at setup.
Demo: yes

### Phase 5 — Schema migrations · planned
Depends on: 4
Delivers: Flyway replaces `ddl-auto=update` (baseline migration for current tables); ADR
Demo: no

### Phase 6 — Deploy · planned
Depends on: 5
Delivers: ADR on production DB; Flutter Web on Netlify, API on Render; CORS locked to the Netlify origin; health-check endpoint; live smoke check
Working assumption (agreed 2026-11-20, confirm in ADR): MySQL in production too, on a free managed MySQL host (e.g. Aiven, TiDB Cloud), to keep the local and production databases identical. Re-verify free-tier limits before choosing; Render free Postgres was rejected as it may expire. Handle Render free-tier sleep (slow first request) with a "waking up the server" state in the app and a README note.
Demo: yes

### Phase 7 — Vehicle screens in the new design · planned
Depends on: 4 (built right after 4, before 5 and 6)
Delivers: vehicle list (number-plate rows, search, status filter, skeleton loading), register / edit pages with live plate preview and field-level errors (Company field in the form), detail panel, remove-with-confirmation, all to DESIGN.md with their own URLs. Starter screens and the unused counter template deleted. Before/after screenshots in the PR.
Demo: yes

### Phase 8 — Assignment 1 release · planned
Depends on: 6, 7
Delivers: end-to-end walkthrough (login → list → add → duplicate rejected → edit → delete), README with live links and ADR index, merge `dev` → `main`, tag `assignment-1`
Demo: yes

## Assignment 2 — advanced fleet management (release: tag `assignment-2`)

Order follows dependencies: change the vehicle's own shape first, then add things
that hang off it, then features that read across everything.

### Phase 9 — Vehicle status rework (A2 #5) · planned
Depends on: 8
Delivers: ADR reconciling starter statuses (AVAILABLE/IN_USE/MAINTENANCE/INACTIVE) with required ACTIVE/INACTIVE/MAINTENANCE; migration of existing rows; status change UI
Demo: yes

### Phase 10 — Drivers and assignment (A2 #8, #9) · planned
Depends on: 9
Delivers: driver CRUD, assign/change a vehicle's driver, migrate `driverName`/`driverPhone` off vehicles; ADR on the relationship (can a driver have several vehicles?)
Demo: yes

### Phase 11 — Search, filter, sort (A2 #6, #7) · planned
Depends on: 10
Delivers: server-side search by vehicle number and other fields, filter by status/type/driver, sort, paginated; matching list UI
Demo: yes

### Phase 12 — Maintenance records and history (A2 #3, #4) · planned
Depends on: 9
Delivers: record date, type, cost, vendor, notes; per-vehicle history view; maintenance status interplay decided in ADR
Demo: yes

### Phase 13 — Document upload (A2 #1) · planned
Depends on: 6
Delivers: ADR on file storage (Render disk is temporary); upload/download/delete with type and size validation; access-controlled
Demo: yes

### Phase 14 — Document expiry tracking (A2 #2) · planned
Depends on: 13
Delivers: expiry dates, expired / expiring-soon indicators computed server-side; threshold decided in ADR
Demo: yes

### Phase 15 — Dashboard and summary (A2 #10) · planned
Depends on: 10, 12, 14
Delivers: totals (vehicles, active, under maintenance), document expiry and maintenance stats via aggregate queries
Demo: yes

### Phase 16 — Assignment 2 release · planned
Depends on: 11, 15
Delivers: full E2E walkthrough, README update, merge `dev` → `main`, tag `assignment-2`
Demo: yes

## Stretch (only after 16; pick at most 2–3)

Scored by: usefulness to a real fleet manager × visibility to a judge ÷ effort and risk.

### Phase 17 — Roles: admin vs viewer · planned
Depends on: 16
Delivers: server-enforced roles; viewers read-only; tests as each role
Demo: yes

Candidates (not committed, become phases only when chosen):
- Activity history: who changed what and when (fleet records get audited)
- Expiry reminders, in-app and maybe email (builds on Phase 14)
- Export to CSV (managers live in spreadsheets; cheap)
- Rejected for now: dark mode, animations (low value for this user)

---

## Change log

Newest first. One line per change. This is the "why did that change?" record.

- 2026-11-21 — user worried that leaving all UI to Phase 7 means testing on the old UI and breakage late → UI built as we go: Phase 4 takes the design foundation (theme, fonts, routing, landing, sign-in, app frame), Phase 7 narrowed to vehicle screens and runs right after 4 (order 3 → 4 → 7 → 5 → 6 → 8); Phase 3 keeps the starter list working; definition of done requires new-design screens from Phase 4 on.

- 2026-11-20 — user asked for a rebuilt frontend with landing page and login, "make it our own, not AI slop" → Phase 7 changed from refine to full redesign + landing page + app frame + per-page URLs; Phase 4 adds URL routing; Phase 2 adds Company field; design brief to be written before Phase 1 code. Landing page is our addition, not a course requirement.

- 2026-11-20 — user asked about UI refinement and extensions → added definition of done, Phase 7 (UX pass) before the Assignment 1 release, stretch candidates; renumbered once before first commit (old 7–16 → 8–17)
- 2026-11-20 — user asked "local management or a service like Supabase/Clerk?" → recorded working assumptions on phases 4 (own Spring auth) and 6 (managed MySQL)
- 2026-11-20 — initial roadmap from Assignment 1 + 2 requirements and starter-code review → added 0–16. Instructor questions (one repo vs two; page shape) unanswered: proceeding with ADR-0001 and ADR-0002 as decided.
