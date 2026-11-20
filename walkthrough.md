# Walkthrough: Phase 3, page response shape

Medium: HTTP client against the real backend (port 9001, local Docker MySQL), plus one check in the app.
`[Claude]` steps are run by Claude and marked ✅/❌ with evidence. `[You]` steps need a person in the app;
Claude leaves the backend and `flutter run` going for them. (Phase 2's walkthrough: commit ddf822a.)

## The seven fields

1. [Claude] `GET /api/vehicles?page=0&size=3`
   **Expect:** `200` with exactly `content`, `number`, `size`, `totalElements`, `totalPages`, `last`, `hasNext` (in that order).
   `number` 0, `size` 3, `content` has 3 items, `last` false, `hasNext` true.
   ✅ 200, keys in order content→hasNext; number 0, size 3, 3 items, last false, hasNext true.
2. [Claude] Count rows in MySQL (`SELECT COUNT(*) FROM vehicles`) and compare.
   **Expect:** `totalElements` equals the row count; `totalPages` = row count ÷ 3, rounded up.
   ✅ MySQL 21 rows = totalElements 21; totalPages 7 = ceil(21/3).
3. [Claude] Request the final page (`page = totalPages - 1`).
   **Expect:** `last` true, `hasNext` false, `content` holds the remainder (1–3 items).
   ✅ page 6: last true, hasNext false, 3 items.
4. [Claude] Request a page past the end (`page=99`).
   **Expect:** `200`, `content` empty, `last` true, `hasNext` false, `number` 99, `totalElements` unchanged. Documented as "no error, empty page".
   ✅ page 99: 200, content [], last true, hasNext false, number 99, totalElements 21.
5. [Claude] Walk every page with `size=3` and collect ids.
   **Expect:** every vehicle appears exactly once, newest first (ids descending). No gaps, no repeats.
   ✅ 7 pages → 21 ids, 21 unique, strictly descending.

## Unchanged behaviour

6. [Claude] `?size=101` and `?page=-1`
   **Expect:** still `400` with the Phase 2 messages.
   ✅ size=101 → 400 "Page size must be between 1 and 100"; page=-1 → 400 "Page number can't be negative".
7. [Claude] `docs/API.md` exists and documents every endpoint, the page shape with all seven fields, and the 400/404/409 error shape.
   ✅ docs/API.md: all 5 endpoints, 7-field page table, error shape with `errors`, 400/403/404/409; enum values checked against the code.
8. [Claude] Backend tests pass locally; CI green on the pushed branch.
   ✅ local: 25/25 tests (2 new integration: seven fields vs MySQL count, page past the end); gate PASS. CI: checked after push.

## In the app

9. [You] Claude leaves the backend and the app running in Chrome. Reload the app's browser tab, then scroll the vehicle list to the bottom.
   **Expect:** more vehicles load as you scroll until all of them are shown, with no error message. The total at the top matches.
   ✅ 2026-11-21, confirmed by the developer: all 21 loaded.
