# ADR-0005: Sign in with my own Spring Security and short-lived bearer tokens

Status: Accepted · Date: 2026-11-21

## Context

The course requires login, and the instructors told us to protect the vehicle endpoints so nobody can call them without signing in. The frontend will live on Netlify and the API on Render, which are different domains. Only Stark Group staff use the app, so there's no public sign-up.

## Options I considered

A hosted auth service (Clerk, Auth0, Supabase Auth) would work, but login is one of the skills this Spring course grades, so I wanted to build it in Spring Security myself. A session cookie is Spring's default, but across two domains it needs cross-site cookie settings and CSRF protection. HTTP Basic would send the password with every request and has no real way to sign out.

## Decision

Spring Security protects every `/api` route. The only open ones are `POST /api/auth/login` and CORS preflight requests. Passwords are stored as BCrypt hashes in a `users` table.

Signing in returns a JWT signed with HS256 that's valid for 8 hours, about one working shift. I use Spring's own JWT support (the OAuth2 resource server starter) rather than a third-party library. The app sends the token in the `Authorization` header, so no cookie and no CSRF token are involved. The signing key comes from `JWT_SECRET`, which must be at least 32 characters. If it isn't set, the server makes a random key at startup and logs a warning, which is fine locally but means everyone is signed out on restart.

The first admin is created when the users table is empty. The username comes from `ADMIN_USERNAME` and the password from `ADMIN_PASSWORD`. If that's not set, a random password is generated and printed once in the log, so no password ever lives in the code.

Wrong passwords and unknown usernames get the same message and take the same time, so the reply doesn't reveal which accounts exist. After 5 wrong passwords from the same address for the same username, that pair is locked out for 15 minutes. Keying on both means an attacker can't lock the real admin out from somewhere else.

The app keeps the token in the browser, so reloading the page doesn't sign you out. When the server rejects a token, the app signs out and says the session ended.

## Consequences

Signing out only forgets the token on that device. A stolen token keeps working until it expires, at most 8 hours, because the server doesn't keep a list of sessions. Any script running in the page could read the stored token. Flutter Web draws to a canvas and doesn't insert untrusted HTML, so I accept that risk for now. The lockout is kept in memory, so it resets when the server restarts and wouldn't be shared if I ran more than one server. Adding roles later (Phase 17) means putting a role in the token.
