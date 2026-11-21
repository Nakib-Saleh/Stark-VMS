# Walkthrough: Phase 6, deploy (PostgreSQL on Supabase)

Medium: terminal and HTTP client against the local backend first, then against the live API
(Render) and the live site (Netlify); Chrome for the `[You]` checks. `<api>` = the Render URL,
`<site>` = the Netlify URL, `<ref>` = the Supabase project ref. (Phase 5's walkthrough: commit 9a54b92.)

## Setup only you can do (accounts and secrets; Claude can't sign up for you)

S1. [You] Supabase: new project, region Singapore, strong database password (keep it to yourself).
    Project Settings → Data API: turn the Data API **off**. Connect → "Session pooler": give Claude the
    host and user (`postgres.<ref>`) only.
S2. [You] Render: New → Web Service → this GitHub repo, branch `main`, root directory `backend`,
    runtime Docker, instance Free, health check path `/api/health`. Environment: `DB_URL` (Claude gives
    you the exact value), `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET` (Claude generates one),
    `ADMIN_PASSWORD` (12+ characters, your choice), `CORS_ALLOWED_ORIGINS=https://<site>`.
S3. [You] Netlify: create an empty site (no Git link) and a personal access token. GitHub → Settings →
    Secrets and variables → Actions: secrets `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID`, variable
    `API_BASE_URL=https://<api>/api`.

## Local: PostgreSQL instead of MySQL

1. [Claude] Start a new local Postgres container `stark-postgres` (localhost only) and the backend on it.
   **Expect:** Flyway creates schema `stark` and migrates to version 1; admin and 20 demo vehicles seeded; nothing in `public`.
    ✅ `Successfully applied 1 migration to schema "stark", now at version v1`; `Created admin 'admin'`; 20 vehicles, 1 user, 0 tables in `public`.
2. [Claude] Backend tests (`gradlew test`) against local Postgres.
   **Expect:** all pass (36 + new), including the race test where the database itself refuses a duplicate.
    ✅ 38 tests, 0 failures (2 new health tests; race test now also checks the message names `uk_vehicles_vehicle_number`).
3. [Claude] Insert `dha-metro-ga-11-1001` (lower case, an existing number) straight into the table with `psql`.
   **Expect:** refused by `uk_vehicles_vehicle_number`. Uniqueness ignores case in the database, not only in the service.
    ✅ `ERROR: duplicate key value violates unique constraint "uk_vehicles_vehicle_number"`; also `ADMIN` user refused by `uk_users_username`.
4. [Claude] Insert a vehicle with year 1800 and one with status `FLYING` with `psql`.
   **Expect:** both refused by check constraints.
    ✅ refused by `ck_vehicles_manufacturing_year` and `ck_vehicles_status`.
5. [Claude] API smoke on local: sign in, list, search `q=toyota`, `q=%`, status counts, create, duplicate (409 with `errors.vehicleNumber`), update, delete.
   **Expect:** same responses as on MySQL in Phases 2–7; `q=%` matches nothing (wildcards stay literal).
    ✅ list 200; `q=toyota` 7; `q=%` 0; counts 200 `{AVAILABLE:12,IN_USE:5,MAINTENANCE:2,INACTIVE:1}`; create 201; lower-case duplicate 409 with `errors.vehicleNumber`; update 200; delete 204.

## Local: ready to ship

6. [Claude] `GET /api/health` with no token.
   **Expect:** 200 `{"status":"up"}`; nothing else (no versions, no database details).
    ✅ 200 `{"status":"up"}`.
7. [Claude] `GET /api/healthz` and `GET /api/vehicles` with no token.
   **Expect:** 401 for both. Opening health opened exactly one path.
    ✅ 401, 401.
8. [Claude] Start the backend with `PORT=9123`.
   **Expect:** listens on 9123; without `PORT` it stays on 9001.
    ✅ `:9123/api/health` 200 while the default instance kept serving `:9001`.
9. [Claude] Build the backend Docker image and run it on the local Postgres with `--memory=512m`.
   **Expect:** starts, `/api/health` 200; startup time noted from "Started … in N s".
    ✅ `Started StarkGroupVmsApplication in 6.251 seconds`; health 200; memory 246 MiB / 512 MiB.
10. [Claude] `flutter build web --dart-define=API_BASE_URL=http://localhost:9001/api`; search the built JavaScript for `localhost:9001`, `JWT`, `password`.
    **Expect:** builds; only the API address is found; `_redirects` is in `build/web`.
    ✅ built; `localhost:9001` found, no secret or password strings; `build/web/_redirects` present. Local JWT secret and admin password not found in repo or build.
11. [Claude] Gate: `bash scripts/quality-ratchet.sh` (now includes `flutter build web`); CI on `dev` green with the Postgres service.
    **Expect:** all checks at or below baseline.

## Live

12. [Claude] After the merge to `main`: GitHub Actions run for `main`.
    **Expect:** quality job green, then the Netlify deploy job green.
13. [Claude] Render deploy log.
    **Expect:** Flyway `Successfully applied 1 migration` on Supabase, admin created, 20 demo vehicles, "Started".
14. [Claude] `GET https://<ref>.supabase.co/rest/v1/vehicles` with the project's public anon key.
    **Expect:** refused (Data API off, and the tables aren't in `public` anyway). The database is only reachable through our API.
15. [Claude] `GET https://<api>/api/health` after 20+ minutes idle, timed.
    **Expect:** 200; time recorded (the cold start the waking notice covers).
16. [Claude] Sign in with `curl` against `<api>`, then `GET /api/vehicles?size=5` with the token.
    **Expect:** 200 token; 200 page with `totalElements: 20`.
17. [Claude] Same request with `Origin: https://<site>`, and with `Origin: https://evil.example`.
    **Expect:** first has `Access-Control-Allow-Origin: https://<site>`; second has none (403 on preflight).
18. [Claude] Six wrong sign-ins for one username, each with a different made-up `X-Forwarded-For`.
    **Expect:** the sixth is 429. Faking the forwarded address doesn't get around the lock.
19. [Claude] `GET https://<site>/vehicles/3` and `https://<site>/no-such-page` (raw HTTP).
    **Expect:** both 200 with the app's `index.html`, not Netlify's 404 page.
20. [Claude] Search the repo and the built site for the JWT secret, DB password and admin password.
    **Expect:** none found.

## In the real app (Claude leaves the local backend running and gives you both URLs)

21. [You] Open `<site>` after the API has been idle 20+ minutes (Claude tells you when). Click **Sign in**.
    **Expect:** within about 3 seconds a dark notice bottom-right, "Waking up the server…", with a
    spinner. It goes away by itself when the server answers. No error first.
22. [You] Sign in with `admin` and the password you set in S2. Open a vehicle, edit it, save.
    **Expect:** same as locally; the toast appears; refreshing on `/vehicles/<id>` stays on that page.
23. [You] Chrome DevTools → Network → "Offline", reload `<site>/login`, wait.
    **Expect:** the notice changes to "Can't reach the server. Check your connection." with **Try again**;
    set back to "No throttling", click it: the notice goes away.
