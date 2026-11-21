# ADR-0002: Return both page formats from the vehicle list

Status: Accepted · Date: 2026-11-20 · Implemented in Phase 3 (2026-11-21); contract documented in `docs/API.md`

## Context

I found two instructor sources that disagree on what the paginated vehicle list should return. The backend assignment note from Naimul asks for the Spring Page fields: `content`, `number`, `size`, `totalElements`, `totalPages` and `last`. The starter code and `API.md` shared on 11/16 return `content`, `hasNext` and `totalElements`, and the Flutter app is built around `hasNext`. The official course document doesn't specify either.

## Options I considered

1. Switch to the Spring Page fields only. This matches the written note, but it breaks the frontend, and I'd be wrong if the starter code was the newer intent.
2. Keep `hasNext`. No work, but it ignores the backend instructor's written spec.
3. Return all of the Spring Page fields and keep `hasNext` too.

I also decided against returning Spring's `Page` object directly. Recent Spring versions warn that its JSON shape isn't stable, and it leaks internals like `pageable` and `sort`.

## Decision

I'm going with option 3. My `PagedResponse` record returns `content`, `number`, `size`, `totalElements`, `totalPages`, `last` and `hasNext`.

Adding fields can't break a client that reads the old ones, while swapping them always breaks somebody. I don't need to guess which source is right to ship this.

## Consequences

`hasNext` is redundant with `last`. Once I hear back from the instructors, removing whichever field isn't needed is a one-line change. An API test checks that all seven fields are present.
