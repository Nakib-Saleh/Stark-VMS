# Walkthrough: Phase 1, configuration from environment

Medium: HTTP client (`curl.exe` in PowerShell) plus the browser for the last step.
Run from the repo root in PowerShell. Start each step from a stopped backend unless it says otherwise.

## Defaults (no environment variables set)

1. `docker start stark-mysql`, then `cd backend; .\gradlew.bat bootRun`.
   **Expect:** log ends with `Started StarkGroupVmsApplication` on port 9001. No env vars were needed.
2. `curl.exe -i http://localhost:9001/api/vehicles?page=0"&"size=2`
   **Expect:** `200`, JSON with two vehicles. Same data as before this phase.
3. Allowed origin preflight:
   `curl.exe -i -X OPTIONS http://localhost:9001/api/vehicles -H "Origin: http://localhost:8686" -H "Access-Control-Request-Method: GET"`
   **Expect:** `200` and header `Access-Control-Allow-Origin: http://localhost:8686`.
4. Any other localhost port is also allowed locally (Flutter picks a random port):
   repeat step 3 with `Origin: http://localhost:53771`.
   **Expect:** `200`, `Access-Control-Allow-Origin: http://localhost:53771`.
5. A foreign site is refused (tested as the unauthorised caller):
   repeat step 3 with `Origin: https://evil.example`.
   **Expect:** `403`, body `Invalid CORS request`, **no** `Access-Control-Allow-Origin` header.
6. Same foreign origin on a real request:
   `curl.exe -i http://localhost:9001/api/vehicles -H "Origin: https://evil.example"`
   **Expect:** `403`, no vehicle data.

## Overrides (environment variables win)

7. Stop the backend. `$env:CORS_ALLOWED_ORIGINS = "https://stark-vms.netlify.app"`, then `bootRun` again.
   Repeat step 3 with `Origin: https://stark-vms.netlify.app`.
   **Expect:** `200` with that origin echoed back.
8. Still with that variable set, repeat step 3 with `Origin: http://localhost:8686`.
   **Expect:** `403`. Setting the variable replaces the local default; it does not add to it.
9. Stop. `Remove-Item Env:CORS_ALLOWED_ORIGINS; $env:DB_PASSWORD = "wrong-on-purpose"`, then `bootRun`.
   **Expect:** startup fails with `Access denied for user 'root'` in the log. Proves the password comes from the environment.
   The log must **not** print the password value.
10. `Remove-Item Env:DB_PASSWORD`, `bootRun` again. **Expect:** starts normally (back to defaults).

## Nothing secret in the repo

11. Open `backend/src/main/resources/application.properties`.
    **Expect:** every datasource and CORS value is a `${NAME:default}` placeholder; the only defaults are localhost values and an empty local password.
12. `.env.example` at the repo root lists every variable with a one-line purpose and no real values.

## The app still works end to end

13. With the backend running (step 1, no env vars set), in a second terminal: `cd frontend; flutter run -d chrome` (random port, no extra flags).
    ✅ 2026-11-21, confirmed by the developer: vehicle list loads in Chrome.
    If the backend is not running, Dio reports a "connection error" that mentions CORS; that wording is Dio's generic guess, not a CORS refusal.
    **Expect:** vehicle list loads with data. DevTools Network tab shows `/api/vehicles` with status 200 and no CORS error in the console.
14. Push the branch. **Expect:** CI green (backend tests run against the CI MySQL service using the defaults).
