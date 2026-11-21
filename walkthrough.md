# Walkthrough: Phase 7, vehicle screens in the new design

Medium: HTTP client against the real backend (port 9001, local Docker MySQL, 21 seeded vehicles);
the real app in Chrome for the screens. `[Claude]` steps are run by Claude and marked ✅/❌ with
evidence. `[You]` steps need a person; Claude leaves the backend and `flutter run -d chrome`
running and gives you the admin password. (Phase 4's walkthrough: commit f806f50.)

## Search and status filter on the server

1. [Claude] Without a token: `GET /api/vehicles?q=toyota`, `GET /api/vehicles?status=MAINTENANCE`, `GET /api/vehicles/status-counts`
   **Expect:** each `401` "Sign in to continue".
    ✅ all three 401 "Sign in to continue".
2. [Claude] Signed in: `GET /api/vehicles?q=toyota&size=100`
   **Expect:** `200`; every row has "toyota" (any case) in its number, brand, model, company or driver name; `totalElements` equals the row count; a vehicle without "toyota" anywhere is absent.
    ✅ 200, 8 rows, every one contains toyota; totalElements 8 = rows; the 13 non-matching vehicles absent.
3. [Claude] `GET /api/vehicles?status=MAINTENANCE&size=100`, then `?status=NOPE`
   **Expect:** first: only Maintenance rows. Second: `400` with a message naming the allowed statuses (not a stack trace).
    ✅ 2 rows, all Maintenance; `NOPE` → 400 "Status must be one of [AVAILABLE, IN_USE, MAINTENANCE, INACTIVE]".
4. [Claude] `GET /api/vehicles/status-counts` and `?q=toyota`
   **Expect:** one count per status; the counts add up to `totalElements` of the same unfiltered (or same `q`) list call.
    ✅ {AVAILABLE 13, IN_USE 5, MAINTENANCE 2, INACTIVE 1} = 21 = totalElements; with q=toyota 8 = 8.
5. [Claude] `GET /api/vehicles?q=` (empty) and `?q=` with 101 characters
   **Expect:** empty = whole fleet; over 100 characters = `400`. `size=101` still `400`.
    ✅ empty q → 21 (whole fleet); 101 chars → 400 "Search text must be 100 characters or fewer"; size=101 → 400.
6. [Claude] Automated tests: anonymous caller refused on the new endpoint and parameters; search + status combine; counts agree with the list.
   **Expect:** backend and frontend suites pass locally; CI green on the pushed branch.
    ✅ local: backend 36/36 (3 new search/count tests on real MySQL + 3 new anonymous checks), frontend 6/6. CI: `quality` green on `dev` 3c7d02e (run 44868082861).

## Pages and code

7. [Claude] Router tests: signed out, `/vehicles/new`, `/vehicles/5`, `/vehicles/5/edit`, `/vehicles?page=2`
   **Expect:** each goes to `/login?next=<that URL>`; after sign-in, back to the same URL including `?page=2`.
    ✅ router test "every vehicle page goes to sign-in, keeping the full address" passes for all four URLs; the existing test covers the return trip.
8. [Claude] Starter screens and the counter template are gone; nothing imports them; the infinite-scroll package is removed.
   **Expect:** no references found; `flutter analyze` shows fewer issues than the committed baseline; `flutter build web` succeeds.
    ✅ no references left; `infinite_scroll_pagination` and unused `material_ui` removed; `flutter analyze` 0 issues (baseline 7, lowered to 0); `flutter build web --release` built.
9. [Claude] `dart run build_runner build` after adding Company to the vehicle model
   **Expect:** generated files rebuilt, none hand-edited; a saved Company comes back from `GET /api/vehicles/{id}`.
    ✅ build_runner wrote 8 outputs; POST with company "Walkthrough Co" → 201, GET returns it, cleanup DELETE 204.

## In the app (Claude leaves the backend and the app running)

10. [You] Sign in. On **Vehicles**, look at the register, then click **Next ›** and **2**.
    **Expect:** each row starts with a number plate (`DHAKA METRO-GA` over `11-1001`); status is a coloured dot plus a word. Changing page shows grey placeholder rows shaped like the register, the address bar shows `?page=2`, "Showing 11–20 of 21 vehicles" matches the rows you see. Reload: still page 2. Browser Back: page 1.
    ✅ developer, 2026-11-21: all as expected.
11. [You] Type `toyota` in search, then click the **Maintenance** chip. Then click **Clear search and filter** (or the **All** chip and the search's clear button).
    **Expect:** the list narrows; the chip's count, "Showing … of N" and the page numbers all say the same N. Clearing returns to all 21 on page 1. Search for `zzzz`: an empty message with **Clear search and filter**.
    ✅ developer, 2026-11-21: all as expected.
12. [You] Click a row (also try Tab to a row, then Enter; then Escape).
    **Expect:** a panel slides in from the right with the large plate, status, all facts; the address bar shows `/vehicles/<id>`; Escape or the close button closes it and the list is where you left it.
    ✅ developer, 2026-11-21: all as expected (after fixing the panel's screen-reader setting that threw an assertion on row click).
13. [You] Click **Register vehicle**. Pick a city and class, type `119001` in the number.
    **Expect:** the plate preview updates as you type and the dash appears by itself (`11-9001`). Submit empty: each required field says what to fill in, next to it. Fill it in and click **Register vehicle**: the button shows a spinner and "Registering", then you're back on the list with the new row flashing pale blue and a toast "Registered DHAKA METRO-… …".
    ✅ developer, 2026-11-21: all as expected.
14. [You] Register another vehicle with the same plate.
    **Expect:** under the number field: already registered, with a link that opens that vehicle. Everything you typed is still there.
    ✅ developer, 2026-11-21: all as expected.
15. [You] Open a vehicle, click **Edit vehicle**, change the Company, **Save changes**.
    **Expect:** URL `/vehicles/<id>/edit`; spinner "Saving"; toast "Saved …"; the row flashes; the panel shows the new Company.
    ✅ developer, 2026-11-21: all as expected.
16. [You] Open a vehicle, click **Remove**. Press Enter straight away. Then click Remove again and **Remove vehicle**.
    **Expect:** the dialog shows the plate; Enter keeps the vehicle ("Keep vehicle" is focused). Removing slides the row away, a toast says "Removed …", the counts and "Showing … of N" drop by one together.
    ✅ developer, 2026-11-21: all as expected.
17. [You] In Chrome DevTools → Network, set **Slow 4G**, then change page, open a row, and save an edit.
    **Expect:** placeholder rows while the page loads, placeholders in the panel while it loads, a spinner on the save button. Nothing ever shows a blank page or a lone spinner in the middle.
    ✅ developer, 2026-11-21: all as expected.
18. [You] Make the window phone-narrow.
    **Expect:** rows stack (plate on top), pagination reads "‹ Previous · Page 2 of 3 · Next ›", the form is one column, nothing scrolls sideways.
    ✅ developer, 2026-11-21: all as expected.
