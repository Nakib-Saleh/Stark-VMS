# Stark VMS

A vehicle register for Stark Group office staff: sign in, see every vehicle as its Bangladeshi
number plate, search and filter, register, edit and remove vehicles.

- **Live site:** https://stark-vms-0991.netlify.app
- **API:** https://stark-vms-api-tf5n.onrender.com/api (contract in [docs/API.md](docs/API.md))
- **Release:** tag `assignment-1` is the Assignment 1 submission.

> **First visit can be slow.** The API runs on Render's free plan, which puts it to sleep after
> 15 minutes without visitors. The first request then takes up to a minute while it wakes up.
> The site shows "Waking up the server…" during that time. The database (Supabase, free plan)
> pauses after a week without use. If the site says it can't reach the server for longer than a
> minute, the project owner has to resume the database from the Supabase dashboard.

## Assignment 1: where each requirement is

| Requirement | Where to see it |
|---|---|
| Login | `/login`. Wrong password gets one plain message; 5 failures lock the account for 15 minutes. Every API call checks the token ([ADR-0005](docs/adr/0005-login-and-sessions.md)). |
| Vehicle list | `/vehicles`: number plates, server-side search and status filter, numbered pages kept in the address. |
| Add / register vehicle | **Register vehicle** (`/vehicles/new`), with a live plate preview. |
| Edit vehicle | Open a vehicle, then **Edit vehicle** (`/vehicles/:id/edit`). |
| Delete vehicle | Open a vehicle, then **Remove** and confirm. |
| Duplicate vehicle number | Refused with 409. The message sits under the number field with a link to the existing vehicle. Case doesn't matter, and the database enforces it too, so two people saving at once can't create one. |
| Flutter Web + Spring Boot + SQL + REST | See [Stack](#stack) and [docs/API.md](docs/API.md). |
| Real database data | Every vehicle comes from PostgreSQL through the API; the app holds no vehicle data of its own. On first start, the server adds 20 demo vehicles as ordinary database rows, so there is something to explore. |

## Stack

| Part | Built with | Hosted on |
|---|---|---|
| Web app | Flutter Web (Dart), Riverpod, Dio + Retrofit, shadcn_ui, go_router | Netlify |
| API | Java 21, Spring Boot 4 (Web MVC, Data JPA, Validation, Security), JWT sign-in | Render (Docker) |
| Database | PostgreSQL 17, schema managed by Flyway | Supabase |

The visual design rules are in [DESIGN.md](DESIGN.md).

## Decision records

Each significant choice is written up in [docs/adr/](docs/adr/):

| # | Decision |
|---|---|
| [0001](docs/adr/0001-monorepo.md) | Keep backend and frontend in one repository |
| [0002](docs/adr/0002-page-response-shape.md) | Return both page formats from the vehicle list |
| [0003](docs/adr/0003-branching.md) | Use `main` for submissions and `dev` for ongoing work |
| [0004](docs/adr/0004-config-from-environment.md) | Read database and CORS settings from environment variables |
| [0005](docs/adr/0005-login-and-sessions.md) | Sign in with Spring Security and short-lived bearer tokens |
| [0006](docs/adr/0006-routing-and-session-storage.md) | Real page addresses with go_router, and the session kept in Hive |
| [0007](docs/adr/0007-schema-migrations.md) | Manage the database schema with Flyway migrations |
| [0008](docs/adr/0008-hosting-and-postgres.md) | Host on Netlify, Render and Supabase, and move to PostgreSQL |

## Run it locally

You need JDK 21, Flutter (stable), and Docker. Commands are for Windows PowerShell.

```powershell
# 1. Database (first time only: create the container)
docker run -d --name stark-postgres -p 127.0.0.1:5432:5432 -e POSTGRES_HOST_AUTH_METHOD=trust -e POSTGRES_DB=stark_group_vms -v stark-postgres-data:/var/lib/postgresql/data postgres:17
# later runs:
docker start stark-postgres

# 2. API on http://localhost:9001
cd backend
.\gradlew.bat bootRun

# 3. Web app (in a second terminal)
cd frontend
flutter pub get
flutter run -d chrome
```

On first start the API creates the tables, adds 20 demo vehicles and an `admin` user. With
`ADMIN_PASSWORD` unset, it prints a generated password once in its log. The local database
container only accepts connections from this computer.

## Configuration

The API reads its settings from environment variables. The full list, with explanations, is in
[.env.example](.env.example). Production values are set in Render's dashboard, never in the
repository:

| Variable | What it is |
|---|---|
| `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` | Database connection (Supabase session pooler, TLS required) |
| `JWT_SECRET` | Signs sign-in tokens; 32+ random characters |
| `ADMIN_USERNAME`, `ADMIN_PASSWORD` | First admin, created when no user exists yet |
| `CORS_ALLOWED_ORIGINS` | The website addresses allowed to call the API |
| `PORT` | Set by Render |

The web app has one build setting, `API_BASE_URL`, which isn't a secret:

```powershell
flutter build web --dart-define=API_BASE_URL=https://<api>.onrender.com/api
```

## Tests and checks

```powershell
cd backend;  .\gradlew.bat test      # needs the local database running
cd frontend; flutter analyze; flutter test
```

GitHub Actions runs the same checks on every push, against a fresh PostgreSQL.

## Deployment

- `main` is what's live. `dev` is where work happens, and feature branches merge into `dev`.
- **API:** Render builds `backend/Dockerfile` from `main` and switches over once `/api/health` answers.
- **Web app:** after the checks pass on `main`, GitHub Actions builds the Flutter app and publishes
  it to Netlify. This needs the repository secrets `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID`,
  and the repository variable `API_BASE_URL`.
