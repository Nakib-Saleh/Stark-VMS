# Walkthrough: Phase 2, harden the vehicle API

Medium: HTTP client (`curl`) against the real backend on port 9001 with the local Docker MySQL,
plus one browser check. `[Claude]` steps are run by Claude and marked ✅/❌ with evidence.
`[You]` steps need a person in the app; Claude leaves the backend and `flutter run` going for them.
(Phase 1's walkthrough is in git history: commit 3eb5060.)

## Reading the list

1. [Claude] `GET /api/vehicles?page=0&size=10`
   **Expect:** `200`; every item has a `company` key (null for rows created before this phase).
   ✅ 200, 10 items, every item has `company` (null on pre-Phase-2 rows).
2. [Claude] `GET /api/vehicles?size=100` → `200`. `GET /api/vehicles?size=101` and `?size=0`
   **Expect:** `400`, `message` says the page size must be between 1 and 100.
   ✅ size=100 → 200; size=101 and size=0 → 400 "Page size must be between 1 and 100".
3. [Claude] `GET /api/vehicles?page=-1`
   **Expect:** `400`, `message` says the page number can't be negative (not the old generic "Invalid request payload").
   ✅ 400 "Page number can't be negative".

## Creating

4. [Claude] `POST /api/vehicles` with a valid body, `company: "Stark Logistics"` and vehicle number `"  dha-metro-ga-11-1234 "`
   **Expect:** `201`; stored and returned as `DHA-METRO-GA-11-1234` (trimmed, upper case); `company` echoed back.
   ✅ 201, stored as `DHA-METRO-GA-11-1234`, company "Stark Logistics".
5. [Claude] `POST` again with `"Dha-Metro-Ga-11-1234"`
   **Expect:** `409`; `errors.vehicleNumber` explains the number is already registered.
   ✅ 409, errors.vehicleNumber = "DHA-METRO-GA-11-1234 is already registered".
6. [Claude] `POST` a new vehicle that also sends `id: 999`, `createdAt: "2000-01-01T00:00:00"`
   **Expect:** `201`; `id` is a new server id (not 999) and `createdAt` is now. Client can't set server fields.
   ✅ 201, id 27 (not 999), createdAt 2026-11-21T00:52:51.
7. [Claude] `POST` with brand missing, `manufacturingYear: 1800`, `seatingCapacity: 0`, a 300-character model
   **Expect:** `400`; `errors` has one plain-English message each for `brand`, `manufacturingYear`, `seatingCapacity`, `model`.
   ✅ 400 with messages for brand, model, manufacturingYear, seatingCapacity.

## Updating

8. [Claude] `PUT` another vehicle to `dha-metro-ga-11-1234`
   **Expect:** `409` with `errors.vehicleNumber`.
   ✅ 409, errors.vehicleNumber set.
9. [Claude] `PUT` the step-4 vehicle with its own number in lower case and a new colour
   **Expect:** `200`; colour changed, number still `DHA-METRO-GA-11-1234` (editing doesn't trip over itself).
   ✅ 200, colour "Midnight Blue", number unchanged.

## The database enforces it, not only the code

10. [Claude] Insert `dha-metro-ga-11-1234` straight into MySQL, bypassing the API (`docker exec stark-mysql mysql ... INSERT ...`)
    **Expect:** MySQL refuses: `Duplicate entry`. Proves uniqueness holds even if the code check is skipped or two saves race.
    ✅ MySQL: ERROR 1062 Duplicate entry 'dha-metro-ga-11-1234' for key 'vehicles.UKpy3agdr9g5molxe2mj30p9i8i'.
11. [Claude] Automated test that saves a lower-case duplicate through the repository (skipping the service check)
    **Expect:** rejected by the database; and the API turns that rejection into `409`, not `500`.
    ✅ VehicleApiIntegrationTest.databaseRejectsCaseVariantDuplicateEvenWithoutTheServiceCheck + VehicleControllerTest.createVehicle_databaseRejectsDuplicate_returns409WithFieldError pass.

## Cleanup and gate

12. [Claude] `DELETE` the vehicles created above → `204`; `GET` one of them → `404`.
   ✅ DELETE 204 ×2; GET after delete 404.
13. [Claude] Backend tests all pass locally; CI green on the pushed branch.
   ✅ local: 23/23 tests pass (7 new integration, 2 new controller). CI: checked after push.

## In the app

14. [You] Claude leaves the backend and the app running. In the app click **Add Vehicle**, type the number of a vehicle already in the list but in lower case (for example `dha-metro-ga-11-1001`), fill the rest, press save.
    **Expect:** the form shows an "already registered" error and keeps what you typed. Change the number to something new, save: the vehicle appears at the top of the list in upper case.
    ✅ 2026-11-21, confirmed by the developer.
