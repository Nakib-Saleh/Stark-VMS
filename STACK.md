# Stack
*Mode: detect · Decided: 2026-11-20 · Source: repo (instructor starter code)*

## Choice
| Layer | Choice | Version | Why |
|---|---|---|---|
| Frontend | Flutter Web, Dart | Dart ≥3.13.4, Flutter ≥3.47 | Course requirement; starter code |
| State | flutter_riverpod | 3.5.0 | Starter code |
| HTTP client | dio + retrofit (codegen) | 5.11.1 / 4.10.0 | Starter code |
| UI kit | shadcn_ui | 0.59.0 | Starter code |
| Backend | Java, Spring Boot (Web MVC, Data JPA, Validation), Lombok | Java 21 · Boot 4.1.2 | Course requirement; starter code |
| Build | Gradle wrapper | 9.8.2 | Starter code |
| Database | MySQL | 8.4 (local Docker, CI service) | Starter code (`application.properties`) |
| Tests | JUnit 5 + MockMvc · flutter_test | via Boot / SDK | Starter code |
| Hosting | Netlify (web) · Render (API) | — | Course; production DB is an open ADR |

## Commands
Run from repo root in Git Bash. PowerShell: replace `bash gradlew` with `.\gradlew.bat`.
| Purpose | Command |
|---|---|
| install | `cd frontend && flutter pub get` (backend: Gradle fetches on first build) |
| local DB | `docker start stark-mysql` (container created once at setup, localhost-only, empty root password to match starter config) |
| dev / run | `cd backend && bash gradlew bootRun` · `cd frontend && flutter run -d chrome` |
| codegen | `cd frontend && dart run build_runner build --delete-conflicting-outputs` |
| typecheck | `cd backend && bash gradlew compileJava compileTestJava --console=plain` |
| lint | `cd frontend && flutter analyze` |
| test | `cd backend && bash gradlew test --console=plain` · `cd frontend && flutter test` |
| build | `cd backend && bash gradlew bootJar` · `cd frontend && flutter build web` |
| gate | `bash scripts/quality-ratchet.sh` |

## Facts other skills read
- Has a UI: yes
- Acceptance-test medium: browser (Chrome) for the app; HTTP client (curl/Postman) for the API
- Evidence for bugs: browser DevTools console + Network tab (request/response), Flutter debug console, Spring Boot log with full stack trace
- Docs: Spring Boot https://docs.spring.io/spring-boot/ · Flutter https://docs.flutter.dev · Riverpod https://riverpod.dev · shadcn_ui https://flutter-shadcn-ui.mariuti.com · dio/retrofit https://pub.dev

## Where things live
- Backend root: `backend/src/main/java/com/example/stark_group_vms/` (controller, service, repository, entity, dto, exception, config)
- Backend config: `backend/src/main/resources/application.properties` · tests: `backend/src/test/java/...`
- Frontend entry: `frontend/lib/main.dart` · API base URL: `frontend/lib/config/api_config.dart`
- Frontend: `lib/network/` (Dio + Retrofit), `lib/repositories/`, `lib/providers/` (Riverpod), `lib/screens/`, `lib/widgets/`, `lib/models/`

## Stack-specific rules (non-negotiable)
- Flutter Web ships every line of Dart to the browser: no secrets or credentials in `frontend/`. `--dart-define` is for non-secret config (API URL) only.
- Authorization is enforced in Spring on every endpoint, never only by hiding UI in Flutter.
- Controllers take request DTOs with `@Valid`, never JPA entities; responses are DTOs too.
- CORS lists explicit origins from config, never `*`.
- DB credentials and token secrets come from environment variables; `application.properties` holds placeholders only.
- List endpoints cap `size`; uniqueness rules are enforced by a DB constraint, not only a service-level check.
- `*.g.dart` files are regenerated with build_runner after model/API changes, never hand-edited.
