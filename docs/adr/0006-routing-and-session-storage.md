# ADR-0006: Real page addresses with go_router, and the session kept in Hive

Status: Accepted · Date: 2026-11-21

## Context

The starter app had one screen and the address never changed, so refreshing on a form lost your place and you couldn't link to anything. Login also means some pages must send signed-out visitors to the sign-in page and then back where they were going. And the app needs somewhere to keep the sign-in token so a reload doesn't sign you out (ADR-0005).

## Options I considered

For routing, Flutter's own Router API can do all of this but takes a lot of hand-written code for the redirects. `go_router` is maintained by the Flutter team and handles nested layouts and redirects out of the box. For storage, keeping the token only in memory signs you out on every reload. Adding `shared_preferences` would mean another package, while `hive_ce` was already in the starter and unused.

## Decision

I added `go_router`. Pages have real paths: `/`, `/login`, `/vehicles`, and a not-found page for anything else. These are plain paths with no `#`, so the host has to serve `index.html` for every path; that's a Netlify rewrite in Phase 6. Signed-in pages share a frame with the side menu. A signed-out visitor to an app page is sent to `/login?next=...` and returned there after signing in. `next` only ever points at one of our own paths, never at another site.

The token, username and expiry are kept in a Hive box, which the browser stores in IndexedDB. The box is opened before the app starts, so a signed-in user never sees a signed-out flash.

## Consequences

The redirects in the app are only for convenience. The server still refuses every API call without a valid token. Deploying needs the SPA rewrite rule, or deep links like `/vehicles` return a 404. In Phase 7 the starter's add and edit screens get their own URLs.
