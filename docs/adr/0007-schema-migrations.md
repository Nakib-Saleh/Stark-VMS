# ADR-0007: Manage the database schema with Flyway migrations

Status: Accepted · Date: 2026-11-21 · The MySQL details (ENUM columns, `SHOW CREATE TABLE`) are superseded by ADR-0008, which moved the database to PostgreSQL

## Context

The starter code let Hibernate build the tables (`ddl-auto=update`). On every startup it compared the entity classes with the database and added whatever was missing. That got me going quickly, but it only ever adds. If I rename a field, Hibernate creates a new empty column and leaves the data in the old one. If I remove a field, the column stays. It never shortens a column or moves data. And because nothing is written down, the schema on Render would be whatever the last deploy happened to leave there, with no file anyone could review in a pull request.

## Options I considered

Keeping `ddl-auto=update` meant keeping all of that. Liquibase does the job, but its changes are usually written in XML or YAML, and it brings rollbacks and diffing that I don't need yet. Flyway runs plain SQL files named `V1__...sql`, `V2__...sql` in order and records which ones each database has run. Spring Boot starts it automatically before JPA. It's the smallest tool that solves the problem.

The tables already existed, so I also had to decide how my local database joins Flyway. Flyway's `baseline-on-migrate` would mark it as "already at version 1" and keep the data. But that setting would also quietly accept any other non-empty database I pointed the app at by mistake, and old databases would keep Hibernate's random key names while new ones got mine. No production database exists yet, and my local data is demo data the app re-seeds, so I recreated the local database once instead.

## Decision

Flyway now owns the schema. `V1__baseline.sql` creates `vehicles` and `users` exactly as Hibernate had built them: same columns, types, required fields, unique vehicle number and username, and the year check. The unique keys and the year check get readable names (`uk_vehicles_vehicle_number`, `uk_users_username`, `ck_vehicles_manufacturing_year`). I checked V1 by building an empty database from it and comparing `SHOW CREATE TABLE` with the old tables. Only those names differ.

Hibernate is set to `ddl-auto=validate`. It no longer changes anything, and it refuses to start if an entity and a table disagree.

## Consequences

Every schema change is now a new numbered SQL file, committed together with the entity change. A file that has already run can't be edited: Flyway stores a checksum and stops the app if it changes. Adding a new status, vehicle type or fuel type needs a migration too, because those columns are MySQL `ENUM`s.

Mistakes show up at startup, not on the first request. When I dropped a column by hand, the app refused to start with "missing column [company] in table [vehicles]". CI starts from an empty MySQL, so every CI run also proves the migrations can build the schema from nothing.
