# ADR-0004: Read database and CORS settings from environment variables

Status: Accepted · Date: 2026-11-21

## Context

The starter code had the database address, username and password written straight into `application.properties`, and the vehicle API accepted calls from any website (`@CrossOrigin("*")`). That's fine on my laptop, where MySQL runs in Docker with no password. It won't be fine on Render, where the database will have a real password and the only site that should call the API is my Netlify frontend. Once login exists, letting any website call the API in a signed-in browser becomes a real risk.

## Options I considered

Leaving the values in the file would mean committing the production password to git, or keeping a different copy of the file on the server. Spring Boot already maps environment variables such as `SPRING_DATASOURCE_PASSWORD` onto properties without any change to the file, but then the file still looks like it holds the real settings, and there's no equivalent for CORS. A library that loads a `.env` file adds a dependency for something Render's dashboard already does.

## Decision

`application.properties` now holds placeholders with a local default after the colon: `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` and `CORS_ALLOWED_ORIGINS`. With nothing set, `bootRun` works exactly as before against the local Docker database.

CORS moved out of the controller into one config class for all `/api/**` routes. The local default allows `localhost` and `127.0.0.1` on any port, because `flutter run` picks a random port each time. On Render I set `CORS_ALLOWED_ORIGINS` to the exact Netlify address. Setting it replaces the default instead of adding to it, so the live API doesn't answer browser calls from localhost. Any other origin gets a 403.

`.env.example` lists the four variables with no real values. Spring doesn't read that file; it's the checklist for setting up a host.

## Consequences

Deploying now needs all four variables set on Render. If I forget `CORS_ALLOWED_ORIGINS`, the API only accepts calls from localhost, so the live site breaks visibly instead of quietly accepting everyone. A wrong database password stops the app at startup with "Access denied" rather than failing on the first request. Tests cover the allowed localhost case, a refused foreign site, and an overridden origin list.
