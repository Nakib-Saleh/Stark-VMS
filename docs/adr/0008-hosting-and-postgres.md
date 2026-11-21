# ADR-0008: Host on Netlify, Render and Supabase, and move to PostgreSQL

Status: Accepted · Date: 2026-11-21

## Context

The course asks for the web app on Netlify and the API on Render. That left the database. I had planned to stay on MySQL with a free managed host so local and production would match. When I checked, Aiven had stopped creating free MySQL databases on 6 November 2026 and is switching off the remaining ones on 21 December. TiDB Cloud still has a free tier, but it's only MySQL-compatible: it ignores CHECK constraints by default, among other differences. Render's own free Postgres expires after a month.

## Options I considered

- **TiDB Cloud Starter.** Free, and the code barely changes. But it isn't really MySQL, so "it works locally" would stop meaning "it works live".
- **Aiven's paid MySQL plan.** Real MySQL, but it costs money every month for a course project.
- **PostgreSQL on Supabase.** Free with 500 MB, a real PostgreSQL. It means rewriting the one migration and changing the local database.

I chose Supabase. Hosted Postgres there is the same database I run locally in Docker and in CI, and the app only touches it through JPA, one migration and two repository queries.

## Decision

**Database.** PostgreSQL 17 locally (Docker container `stark-postgres`), in CI (service container) and on Supabase. `V1__baseline.sql` is rewritten for Postgres. That's safe here: it had only ever run on my local database, which I rebuilt. The rules stay the same:

- MySQL's `ENUM` columns become text columns with a `CHECK` listing the allowed values.
- MySQL's collation made the unique vehicle number ignore case. Postgres compares case-sensitively, so the unique index is on `UPPER(vehicle_number)`, and usernames are unique on `LOWER(username)`.
- The duplicate-number race used to be recognised by MySQL's "Duplicate entry" wording. It's now recognised by the index name, `uk_vehicles_vehicle_number`.

All tables live in their own schema, `stark`, not `public`. Supabase publishes the `public` schema through its Data API, and I don't want a second way into the data that skips my API's sign-in. The Data API is also switched off in the project settings.

The API connects through Supabase's **session pooler**, with TLS required (`sslmode=require`). The direct connection only works over IPv6, which Render's free plan doesn't have. The transaction pooler breaks prepared statements and Flyway's lock. The pool is capped at 5 connections.

**API.** Render runs the Docker image in `backend/Dockerfile` and deploys `main`. It sets `PORT`, which the app reads, and it waits for `GET /api/health` before it switches traffic over. That endpoint is open to anyone and answers only `{"status":"up"}`. The app reads the visitor's address with Tomcat's own forwarded-header handling, which trusts only the entry Render's proxy added, so a fake `X-Forwarded-For` can't get around the sign-in lockout.

**Web.** A GitHub Actions job builds the Flutter app and publishes it to Netlify after the quality checks pass on `main`. Netlify's builders don't have Flutter. The API address is set at build time (`--dart-define=API_BASE_URL`). It isn't a secret, since everything in a Flutter web app ships to the browser. `web/_redirects` sends every path to `index.html` so the app's own URLs work on refresh.

**Demo data.** The 20 demo vehicles are seeded on the live site too, so anyone reviewing it has something to look at.

## Consequences

- Render's free API sleeps after 15 minutes without visitors and takes up to a minute to wake. The app warns about this: any request still waiting after 3 seconds shows a "Waking up the server…" notice until the server answers. If it can't be reached at all, the notice offers "Try again". Requests may now wait up to 90 seconds.
- Supabase's free project pauses after a week without requests. Someone has to resume it from the Supabase dashboard, and free projects have no automatic backups.
- Each new migration is plain PostgreSQL. Adding a status, type or fuel value means a migration that replaces its `CHECK`.
- Secrets live only in Render's dashboard (database password, `JWT_SECRET`, `ADMIN_PASSWORD`) and in GitHub secrets (Netlify token and site ID).
