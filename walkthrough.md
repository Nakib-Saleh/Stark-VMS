# Walkthrough: Phase 5, schema migrations

Medium: terminal and HTTP client against the real backend (port 9001, local Docker MySQL).
No screen changes in this phase, so every step is `[Claude]`; Claude reports results and leaves
the backend running. (Phase 7's walkthrough: commit bc1c363.)

## The schema comes from a migration, not from Hibernate

1. [Claude] Start the backend on a brand-new empty database (`DB_URL` pointing at a throwaway `stark_vms_fresh`).
   **Expect:** log shows Flyway migrating to version 1, then the app starts; `flyway_schema_history` has one successful row for version 1; the seeders add the admin and 20 demo vehicles.
    ✅ `Migrating schema `stark_vms_fresh` to version "1 - baseline"` → `Successfully applied 1 migration`; history row v1 success=1; 20 vehicles seeded, admin created (on the next start: the first check script stopped the app on the "Started" line, before the seeders ran).
2. [Claude] Compare `SHOW CREATE TABLE` for `vehicles` and `users` on the fresh database with the tables Hibernate made before this phase.
   **Expect:** same columns, types, nullability, unique keys and year check; only the constraint names differ (readable names instead of Hibernate's random ones).
    ✅ `diff` of `SHOW CREATE TABLE` (old vs fresh): only `UKpy3agdr9…`→`uk_vehicles_vehicle_number`, `vehicles_chk_1`→`ck_vehicles_manufacturing_year`, `UKr43af9…`→`uk_users_username`.
3. [Claude] Search the startup log for `create table` / `alter table` coming from Hibernate.
   **Expect:** none. Hibernate only checks the schema (`ddl-auto=validate`) and never changes it.
    ✅ 0 `create table`/`alter table` lines in the startup log.
4. [Claude] Restart the backend on the same database.
   **Expect:** Flyway says the schema is up to date; no migration runs twice; vehicles added before the restart are still there.
    ✅ "Schema `stark_vms_fresh` is up to date. No migration necessary."; still 1 history row; a row inserted before the restart is still there.

## Mistakes are caught at startup, not at the first request

5. [Claude] On the throwaway database, drop the `company` column by hand, then start the backend.
   **Expect:** the app refuses to start with a schema-validation error naming the missing `company` column (not a 500 later on a vehicle request).
    ✅ refused: "Schema validation: missing column [company] in table [vehicles]"; nothing listening on 9001.
6. [Claude] Edit the applied version-1 migration file (one added space), start the backend, then undo the edit.
   **Expect:** the app refuses to start with a Flyway checksum mismatch for version 1. Applied migrations can't be changed silently.
    ✅ refused: "Migration checksum mismatch for migration version 1"; file restored (`cmp` identical) and jar rebuilt.

## The rules still hold on a migrated database

7. [Claude] On the fresh database: sign in, register `DHA-METRO-GA-77-0001`, then register `dha-metro-ga-77-0001`.
   **Expect:** `201`, then `409` "… is already registered" (the unique key from the migration, case-insensitive). Without a token: `401`.
    ✅ anonymous 401 "Sign in to continue"; 201 then 409 "DHA-METRO-GA-77-0001 is already registered"; a direct SQL insert of the lower-case duplicate fails `Duplicate entry … for key 'vehicles.uk_vehicles_vehicle_number'`.
8. [Claude] Move the local development database onto migrations (recreate it once, empty, and start the backend).
   **Expect:** version 1 applied, admin and 20 demo vehicles seeded, new admin password from the log works for sign-in; the throwaway database is dropped.
    ✅ local DB recreated: v1 applied, 20 vehicles + admin seeded, sign-in 200 with the new password; `stark_vms_fresh` dropped.
9. [Claude] Automated tests.
   **Expect:** backend suite passes locally (database built by the migration); CI green on the pushed branch, where MySQL starts empty, so CI proves the migration builds the schema from nothing.
    ✅ local: backend 36/36 on the migrated database. CI: `quality` green on `dev` c1b5a97 (run 44872596191), starting from an empty MySQL.
