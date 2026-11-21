# Stark VMS API

Base URL: `http://localhost:9001/api` locally, `https://stark-vms-api-tf5n.onrender.com/api` live
(ADR-0008). JSON in, JSON out. All timestamps are Dhaka local date-times without zone
(`2026-11-21T00:52:51.01384`); the live server runs on Asia/Dhaka time.

Browsers may only call the API from the origins in `CORS_ALLOWED_ORIGINS` (ADR-0004).
Every endpoint except sign-in and the health check needs `Authorization: Bearer <token>` (ADR-0005). Without a valid
token the answer is `401` with message "Sign in to continue".

## Sign in

`POST /auth/login` (open)

```json
{ "username": "admin", "password": "..." }
```

`200`:

```json
{ "token": "eyJ...", "expiresAt": "2026-11-21T03:20:56.912Z", "username": "admin" }
```

The token is valid for 8 hours. Send it on every other request as `Authorization: Bearer <token>`.
Signing out is done by the client forgetting the token.

| Status | When |
|---|---|
| `400` | `username` or `password` missing (`errors.username` / `errors.password`) |
| `401` | Wrong username or password (same message for both: "That username and password don't match") |
| `429` | 5 wrong passwords for this username from this address: "Too many failed sign-in attempts. Try again in N minutes." |

`GET /auth/me` → `200` `{ "username": "admin" }` for a valid token.

## Health

`GET /health` (open) → `200` `{ "status": "up" }` once the server is running. Nothing else is
reported (no version, no database state). Render's health check and the web app's "waking up"
notice use it. On the free plan the first request after 15 idle minutes can take up to a minute.

## Endpoints

| Method | Path | Success | Errors |
|---|---|---|---|
| `GET` | `/vehicles?page=0&size=10&q=&status=` | `200` page of vehicles, newest first | `400` bad `page`/`size`/`q`/`status` |
| `GET` | `/vehicles/status-counts?q=` | `200` vehicles per status, e.g. `{"AVAILABLE": 13, "IN_USE": 5, "MAINTENANCE": 2, "INACTIVE": 1}` (every status present, `0` included) | `400` bad `q` |
| `GET` | `/vehicles/{id}` | `200` vehicle | `404` |
| `POST` | `/vehicles` | `201` created vehicle | `400` validation, `409` duplicate number |
| `PUT` | `/vehicles/{id}` | `200` updated vehicle | `400`, `404`, `409` |
| `DELETE` | `/vehicles/{id}` | `204` no body | `404` |

## List: query parameters

| Parameter | Default | Rule |
|---|---|---|
| `page` | `0` | Zero-based, `0` or more. A page past the end returns `200` with empty `content`. |
| `size` | `10` | `1` to `100`. |
| `q` | none | Optional search text, up to 100 characters. Matches vehicles whose number, brand, model, company or driver name contains it, ignoring case. `%` and `_` are plain characters. Empty means no search. |
| `status` | none | Optional: `AVAILABLE`, `IN_USE`, `MAINTENANCE` or `INACTIVE` (any case). Anything else is `400` with `errors.status`. |

`q` and `status` combine. `status-counts` takes the same `q`, so its numbers add up to `totalElements` of the list with that `q` and no `status`.

## Page shape

Field names are a contract (ADR-0002): new fields may be added, existing ones are never renamed.

```json
{
  "content": [ { "...vehicle..." } ],
  "number": 0,
  "size": 10,
  "totalElements": 20,
  "totalPages": 2,
  "last": false,
  "hasNext": true
}
```

| Field | Meaning |
|---|---|
| `content` | The vehicles on this page |
| `number` | This page's index, zero-based (echoes `page`) |
| `size` | Requested page size (echoes `size`) |
| `totalElements` | Vehicles across all pages |
| `totalPages` | Number of pages at this size (`0` when there are no vehicles) |
| `last` | `true` on the final page, and on any page past the end |
| `hasNext` | `true` when another page follows. Always the opposite of `last`. |

## Vehicle (response)

```json
{
  "id": 16,
  "vehicleNumber": "CTG-METRO-GA-11-9001",
  "vehicleType": "CAR",
  "company": "Stark Logistics",
  "brand": "Toyota",
  "model": "Axio Hybrid",
  "manufacturingYear": 2021,
  "color": "Pearl",
  "fuelType": "HYBRID",
  "seatingCapacity": 5,
  "driverName": "Faruk Ahmed",
  "driverPhone": "+8801711000016",
  "status": "AVAILABLE",
  "createdAt": "2026-11-20T22:18:43.674601",
  "updatedAt": "2026-11-20T22:18:43.674601"
}
```

`company` is `null` for vehicles registered before it existed.

## Vehicle (request body for `POST` and `PUT`)

Server-owned fields (`id`, `createdAt`, `updatedAt`) are ignored if sent.

| Field | Required | Rule |
|---|---|---|
| `vehicleNumber` | yes | ≤ 50 chars. Stored trimmed, single-spaced, upper case. Unique regardless of case. |
| `vehicleType` | yes | `CAR` `SUV` `MICROBUS` `VAN` `TRUCK` `PICKUP` `BUS` `MOTORCYCLE` |
| `company` | no | ≤ 100 chars |
| `brand` | yes | ≤ 100 chars |
| `model` | yes | ≤ 100 chars |
| `manufacturingYear` | no | 1900 to next year |
| `color` | no | ≤ 50 chars |
| `fuelType` | yes | `PETROL` `OCTANE` `DIESEL` `CNG` `LPG` `HYBRID` `ELECTRIC` |
| `seatingCapacity` | no | 1 to 100 |
| `driverName` | no | ≤ 100 chars |
| `driverPhone` | no | ≤ 20 chars |
| `status` | no | `AVAILABLE` (default on create) `IN_USE` `MAINTENANCE` `INACTIVE`. On update, omitted keeps the current status. |

## Errors

Every error has the same shape. `errors` appears when a specific field is at fault, so a
client can show the message next to that field.

```json
{
  "timestamp": "2026-11-21T00:52:51.2",
  "status": 409,
  "error": "Conflict",
  "message": "DHA-METRO-GA-11-1234 is already registered",
  "errors": { "vehicleNumber": "DHA-METRO-GA-11-1234 is already registered" }
}
```

| Status | When |
|---|---|
| `400` | Validation failed (one `errors` entry per field), bad `page`/`size`, unreadable JSON |
| `401` | No token, or a token that is malformed, tampered with or expired: "Sign in to continue" |
| `403` | Browser call from an origin not in the allowed list (body `Invalid CORS request`) |
| `404` | No vehicle with that id |
| `409` | Vehicle number already registered (also when two saves race and the database catches it) |
| `429` | Sign-in locked for 15 minutes after repeated wrong passwords |
