# Walkthrough: Phase 4, login + new UI foundation

Medium: HTTP client against the real backend (port 9001, local Docker MySQL); headless Chrome
screenshots of a release build for public pages; the real app in Chrome for the signed-in flow.
`[Claude]` steps are run by Claude and marked ✅/❌ with evidence. `[You]` steps need a person;
Claude leaves the backend and the app running for them. (Phase 3's walkthrough: commit c2dfdaa.)

## Locked by default (tested as an outsider)

1. [Claude] Without a token: `GET /api/vehicles`, `GET /api/vehicles/1`, `POST`, `PUT /api/vehicles/1`, `DELETE /api/vehicles/1`
   **Expect:** every one `401`, JSON body in the usual error shape, message "Sign in to continue". Nothing deleted (row count unchanged).
    ✅ GET/GET id/POST/PUT/DELETE all 401 "Sign in to continue"; vehicle rows 21 → 21.
2. [Claude] With a made-up or tampered token (`Authorization: Bearer abc`, and a real token with one character changed)
   **Expect:** `401` each time.
    ✅ made-up token 401, tampered token 401 (expired token: AuthIntegrationTest).
3. [Claude] CORS preflight with no token (`OPTIONS /api/vehicles` from `http://localhost:8686`)
   **Expect:** `200` with `Access-Control-Allow-Origin` (a browser must be able to ask before it has a token). Foreign origin still `403`.
    ✅ localhost preflight 200 with Access-Control-Allow-Origin; evil.example 403, no ACAO.
## Signing in

4. [Claude] First start on a database with no users, `ADMIN_PASSWORD` unset
   **Expect:** log line says an admin `admin` was created with a generated password and how to set your own. Restart: no new user, no password in the log.
    ✅ first start: "Created admin 'admin' with generated password" (once). Restart: 0 new admins, password not in log, 1 user row, old password still signs in.
5. [Claude] `SELECT username, password_hash FROM users`
   **Expect:** one row; hash starts with `$2` (BCrypt). The plain password appears nowhere in the database.
    ✅ one row, hash `$2a$10$…`; plain password absent from a full table dump.
6. [Claude] `POST /api/auth/login` with a wrong password
   **Expect:** `401`, message "That username and password don't match". Same message for an unknown username (no hint which was wrong).
    ✅ wrong password and unknown user both 401 "That username and password don't match".
7. [Claude] Five wrong passwords in a row, then a sixth attempt, even with the right password
   **Expect:** sixth gets `429`, message says to try again in 15 minutes. A different client address is not blocked.
    ✅ 6th attempt 429 "Too many failed sign-in attempts. Try again in 15 minutes." (throwaway username); other address unaffected (AuthIntegrationTest).
8. [Claude] Correct login
   **Expect:** `200` with `token`, `expiresAt` (8 hours ahead) and `username`. The token then works: `GET /api/vehicles` → `200`; `GET /api/auth/me` → `200` with the username.
    ✅ 200, expiresAt +8h, GET /api/vehicles 200, /api/auth/me {username: admin}.
9. [Claude] Automated tests: expired token → `401`; every vehicle endpoint refuses an anonymous caller; login throttle resets after the wait.
   **Expect:** all pass locally; CI green on the pushed branch.
    ✅ local: backend 33/33 (8 new auth tests), frontend 4/4 (new `frontend_test` gate check, verified with a planted failure). CI: checked after push.
10. [Claude] `JWT_SECRET` unset → warning in the log that tokens won't survive a restart; set → no warning. Neither value ever printed.
    ✅ warning "JWT_SECRET is not set: using a random signing key…" present; generated password printed exactly once.
## Public pages (headless screenshots of a release build)

11. [Claude] `/` at desktop (1440px) and phone (400px) width
    **Expect:** landing page to DESIGN.md: navy hero, large number plate, "Sign in" button, no horizontal scroll at 400px. Fonts are Archivo / Public Sans / Barlow Condensed, not a fallback.
    ❌ blocked: headless Chrome renders the release build blank (no console errors; virtual and real-time waits both blank). Not yet localised; the app renders in real Chrome via `flutter run` (log clean). Checked by the developer in steps 15–19 instead.
12. [Claude] `/login` at both widths
    **Expect:** sign-in form with labelled fields and one "Sign in" button; no demo credentials shown.
    ❌ blocked, same as step 11.
13. [Claude] `/vehicles` while signed out, and `/no-such-page`
    **Expect:** first lands on `/login`; second shows a not-found page with a way back home.
    ❌ blocked, same as step 11. Redirect logic covered by frontend tests (signed-out /vehicles → /login?next=…).
14. [Claude] `flutter analyze` no new issues; `flutter build web` succeeds.
    ✅ `flutter analyze`: 7 issues, all pre-existing starter imports (down from 8); `flutter build web --release` built.
## In the app (Claude leaves the backend and the app running, and gives you the admin password)

15. [You] On the landing page: watch the plate change a few times. Click **Sign in**.
    **Expect:** the plate flips to the next vehicle every few seconds; Sign in opens the sign-in page.
    ⏳ not reported by the developer at commit time (2026-11-21). Only the landing page top bar was reviewed; its Sign in button alignment was fixed.
16. [You] Sign in with a wrong password, then the right one.
    **Expect:** wrong → a red message above the form, your username still filled in; the button shows a spinner while checking. Right → you land on the vehicle list inside the new frame (navy side menu with Vehicles highlighted, Dashboard and Drivers marked "Soon", your name and Sign out at the bottom).
    ⏳ not reported by the developer at commit time (2026-11-21). Only the landing page top bar was reviewed; its Sign in button alignment was fixed.
17. [You] Reload the browser tab.
    **Expect:** still signed in, same page.
    ⏳ not reported by the developer at commit time (2026-11-21). Only the landing page top bar was reviewed; its Sign in button alignment was fixed.
18. [You] Click **Sign out**, then type `/vehicles` in the address bar.
    **Expect:** sign-out returns you to the landing page with a "Signed out" note; `/vehicles` sends you to sign in, and after signing in you land back on `/vehicles`.
    ⏳ not reported by the developer at commit time (2026-11-21). Only the landing page top bar was reviewed; its Sign in button alignment was fixed.
19. [You] Make the window phone-narrow.
    **Expect:** side menu becomes a top bar; nothing cut off or scrolling sideways.
    ⏳ not reported by the developer at commit time (2026-11-21). Only the landing page top bar was reviewed; its Sign in button alignment was fixed.