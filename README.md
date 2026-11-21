# Stark VMS

A vehicle register for Stark Group office staff: sign in, see every vehicle as its Bangladeshi
number plate, search and filter, register, edit and remove vehicles.

- **Live site:** https://\<site\>.netlify.app
- **API:** https://\<api\>.onrender.com/api (contract in [docs/API.md](docs/API.md))

> **First visit can be slow.** The API runs on Render's free plan, which puts it to sleep after
> 15 minutes without visitors. The first request then takes up to a minute while it wakes up.
> The site shows "Waking up the server…" during that time. The database (Supabase, free plan)
> pauses after a week without use. If the site says it can't reach the server for longer than a
> minute, the project owner has to resume the database from the Supabase dashboard.

## Stack

| Part | Built with | Hosted on |
|---|---|---|
| Web app | Flutter Web (Dart), Riverpod, Dio + Retrofit, shadcn_ui, go_router | Netlify |
| API | Java 21, Spring Boot 4 (Web MVC, Data JPA, Validation, Security), JWT sign-in | Render (Docker) |
| Database | PostgreSQL 17, schema managed by Flyway | Supabase |

Design decisions are recorded in [docs/adr/](docs/adr/). The visual design rules are in
[DESIGN.md](DESIGN.md).

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
