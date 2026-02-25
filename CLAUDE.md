# CLAUDE.md

Master Behavior Guide and Skill Loader for the StreamWatch UI (Flutter)

> **Repo topology:** `streamwatch-ui/` is its own git repo. API work happens in
> `../streamwatch-api/` (also its own git repo). Cross-repo architecture source
> of truth: `d:/tmzwatch/projects/streamwatch/CLAUDE.md`.


# 1. Behavior Contract

Before performing any coding, planning, refactoring, generation, or analysis in this repository, you must:

1. Load all skills listed in Section 2.
2. Follow the Project Workflow system in Section 3.
3. Apply all loaded skills to every task unless Kevin explicitly overrides them.
4. Never begin coding until a PLAN markdown file is produced and approved.
5. Always emit a TASK_STATUS_UPDATE block when a project task's status changes.
6. Ensure code, naming, state management, and UI structure follow the repo's patterns.
7. Keep all actions scoped to a named project task.
8. Follow Evidence and Proof Standards (Section 12) for all verification tasks.

If a required skill file is missing, ask whether to create it.


# 2. Skill Loader (Required for Every Run)

Before doing any work, load the following skills.

> **Path note:** `global/skills/` below refers to the suite-wide skills directory
> at the absolute path `d:/tmzwatch/global/skills/`. It is NOT inside this repo.

## Core Skills (from d:/tmzwatch/global/skills/)

* `d:/tmzwatch/global/skills/project_workflow.md`
* `d:/tmzwatch/global/skills/code_style.md`
* `d:/tmzwatch/global/skills/naming_conventions.md`
* `d:/tmzwatch/global/skills/logging_principles.md`
* `d:/tmzwatch/global/skills/testing_principles.md`

## Flutter Skills (from d:/tmzwatch/global/skills/)

* `d:/tmzwatch/global/skills/flutter_patterns.md`
* `d:/tmzwatch/global/skills/bloc_patterns.md`

## Repo-Specific Skills (local to this repo)

* `skills/repo_structure.md`

If a skill is missing or incomplete, propose adding or modifying it before proceeding.

---

# 3. Project Workflow (Applies to All Work in This Repo)

Every task in this repo must follow the Project Task Lifecycle.

## 3.1 Task Statuses

Every project task is always in exactly one of these:

* `PLAN_DRAFT`
* `IN_EXECUTION`
* `REVIEW_READY`
* `APPROVED`

## 3.2 Required Markdown Files per Task

All tasks must maintain three files inside `/docs`:

* `docs/<project_name>_plan.md`
* `docs/<project_name>_execution.md`
* `docs/<project_name>_review.md`

## 3.3 Workflow Steps

1. PLAN_DRAFT — Generate `<project_name>_plan.md` using the workflow template.
2. IN_EXECUTION — Implement the approved plan. Log work into `<project_name>_execution.md`.
3. REVIEW_READY — Produce `<project_name>_review.md` with evidence.
4. APPROVED — Kevin approves. Task is complete.

No code should be written outside this lifecycle.

## 3.4 Required Status Update Block

Every time the task's status changes, append this block:

```
TASK_STATUS_UPDATE:
tool_name=StreamWatch_UI
project_name=<slug>
status=<status>
plan_path=docs/<project_name>_plan.md
execution_path=docs/<project_name>_execution.md
review_path=docs/<project_name>_review.md
```

## 3.5 All Work Must Be Attached to a Project Task

No free-floating commits or code changes.
Every change begins with a named project.

---

# 4. StreamWatch UI System Summary

StreamWatch UI is a Flutter web application that:

* Displays transcription jobs and their status
* Provides video/URL ingest with metadata overrides
* Shows real-time job progress via polling (WebSocket planned)
* Renders transcripts with speaker attribution
* Plays back source media via signed S3 URLs
* Manages collections, users, and video type controls

This is a pure client. It never connects to Aurora PostgreSQL directly. All data flows through the Go API.

---

# 5. Architecture (UI Perspective)

```
Flutter Web App (browser)
  -> HTTPS
API Gateway
  -> Lambda (Go API)
     -> Aurora PostgreSQL
     -> S3 (signed URLs for media)
```

Key constraints:

* No secrets in Flutter. No DB credentials. No AWS keys.
* All data access goes through the public REST API.
* Media bytes are never fetched through the API; UI uses signed S3 URLs.
* API base URL is set at build time via `--dart-define`.

---

# 6. Configuration

## Build-Time Flags (--dart-define)

| Flag | Default | Purpose |
|------|---------|---------|
| `API_BASE_URL` | `http://localhost:8081` | API endpoint |
| `ENV` | `development` | Environment: development, staging, production |
| `AUTH_REQUIRED` | `true` | Enable/disable auth gate |
| `DEV_ASSUME_ADMIN` | `true` | Stub admin session in dev mode |

Config is loaded via two classes:

* `lib/utils/config.dart` — `Config` singleton (primary, used by service locator)
* `lib/config/app_config.dart` — `AppConfig` static (legacy, used by `ApiService`)

Both default to `http://localhost:8081` when `API_BASE_URL` is not provided.

**WARNING:** If you omit `--dart-define=API_BASE_URL` in a production build, the UI will try to connect to `localhost:8081` and fail silently.

## Production Values (Do Not Guess)

| Resource | Value |
|----------|-------|
| API Gateway | `https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com` |
| CloudFront UI | `https://dpoqt8yacebtf.cloudfront.net` |
| CloudFront Distribution ID | `EE0PAJB58A75G` |
| S3 UI Bucket | `streamwatch-frontend-dev-259270188737` |

---

# 7. Running Locally

```bash
# Install dependencies
flutter pub get

# Run in Chrome (connects to local API on :8081)
flutter run -d chrome

# Run in Chrome pointed at production API
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com

# Run with auth disabled (for UI-only dev)
flutter run -d chrome --dart-define=AUTH_REQUIRED=false

# Run API + UI together (from streamwatch/ parent):
D:\tmzwatch\projects\streamwatch\launch-streamwatch.bat
```

---

# 8. Deployment (CRITICAL)

```bash
# 1. Build with production API URL (REQUIRED)
flutter build web --release \
  --dart-define=API_BASE_URL=https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com \
  --dart-define=ENV=production

# 2. Sync to S3
aws s3 sync build/web s3://streamwatch-frontend-dev-259270188737/ --delete

# 3. Invalidate CloudFront cache
aws cloudfront create-invalidation --distribution-id EE0PAJB58A75G --paths "/*"
```

Or use the deploy script:
```powershell
.\scripts\deploy-frontend.ps1 -ApiBaseUrl https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com
```

---

# 9. API Integration

## Endpoints Used by UI

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v1/jobs` | GET | List jobs (with pagination, filters) |
| `/api/v1/jobs` | POST | Create new job (upload or URL ingest) |
| `/api/v1/jobs/{id}` | GET | Job detail |
| `/api/v1/jobs/{id}/chunks` | GET | Transcript chunks for a job |
| `/api/v1/jobs/{id}/download/transcript` | GET | Download transcript |
| `/api/v1/jobs/{id}/download/summary` | GET | Download summary |
| `/api/v1/jobs/{id}/media/stream` | GET | Signed media URL |
| `/api/v1/jobs/{id}/thumbnail` | GET | Job thumbnail |
| `/api/v1/me` | GET | Current user profile |
| `/api/v1/typecontrol/types` | GET/POST | Video type management |
| `/api/v1/ws/jobs/{id}` | WS | Real-time job updates |

## Auth

Token-based authentication via `token_store_web.dart`. Auth probe checks `GET /api/v1/jobs`.

## CORS

CORS is configured in API Gateway and in the Go API's `rs/cors` middleware. Verify
allowed origins in the API repo config before changing. If origins are restricted,
add the CloudFront domain (`https://dpoqt8yacebtf.cloudfront.net`) to the allowed
origins list in API Gateway.

---

# 10. Repository Layout (Preserve)

```
streamwatch-ui/
├── lib/
│   ├── main.dart              # App entry point
│   ├── app.dart               # Router + MaterialApp setup
│   ├── config/                # AppConfig (legacy)
│   ├── data/
│   │   ├── models/            # JSON-serializable data models
│   │   ├── providers/         # RestClient, TokenStore
│   │   └── sources/           # Data sources (API calls)
│   ├── features/              # Feature modules (BLoC pattern)
│   │   ├── <feature>/
│   │   │   ├── bloc/          # <feature>_bloc/event/state.dart
│   │   │   ├── views/         # <feature>_view.dart
│   │   │   ├── widgets/       # Feature-specific widgets
│   │   │   └── service_locator.dart
│   │   └── ...
│   ├── models/                # Legacy models (job.dart, cast.dart)
│   ├── pages/                 # Legacy pages (being migrated to features/)
│   ├── services/              # Legacy ApiService
│   ├── shared/                # Shared bloc (auth_session_bloc)
│   ├── themes/                # App theme, TMZ theme
│   └── utils/                 # Config, service_locator
├── test/                      # Widget and BLoC tests
├── assets/                    # Images, logos
├── docs/                      # Project task files (plan/execution/review)
├── scripts/                   # Deployment and utility scripts
├── infra/                     # CloudFormation templates
├── skills/                    # Skill system (Claude behavior)
├── CLAUDE.md                  # This file
├── pubspec.yaml               # Dependencies
├── analysis_options.yaml      # Dart linter rules
└── README.md                  # Project README
```

## Adding a New Feature

1. Create `lib/features/{name}/bloc/` with event, state, bloc files
2. Create `lib/features/{name}/views/{name}_view.dart`
3. Create `lib/features/{name}/service_locator.dart`
4. Register in `lib/utils/service_locator.dart`
5. Add route in `lib/app.dart`

---

# 11. Quality Bar

## Required Checks

Every change must run these checks and introduce no new issues vs baseline:

```bash
flutter analyze    # No NEW warnings/errors vs baseline
flutter test       # No NEW failures vs baseline
```

Pre-existing warnings and test failures are baselined. Changes must not increase the count.

## BLoC Conventions

* One BLoC per feature/screen.
* Events are past-tense or imperative (`JobsLoaded`, `LoadJobs`).
* States use Equatable for value equality.
* BLoCs are registered via GetIt in feature-level `service_locator.dart`.

## Model Conventions

* JSON models live in `lib/data/models/`.
* Use `fromJson` factory constructors.
* Keep backward compatible unless explicitly requested.

---

# 12. Evidence and Proof Standards

When performing verification or proof bundles:

* Never summarize command outputs. Paste literal output.
* If output is empty, write exactly: `(no output)`
* Before marking a proof bundle complete, create a numbered checklist mapping each criterion to pasted evidence.

Required proof for Flutter changes:

```bash
flutter analyze   # No new warnings/errors vs baseline
flutter test      # No new failures vs baseline
```

---

# 13. Interaction Rules

* Respect architecture boundaries (pure client, no secrets, API-only data access).
* Follow Flutter/Dart conventions and repo patterns.
* Avoid over-engineering.
* Prefer clarity over cleverness.
* Keep changes small, atomic, and logged in execution files.

---

End of CLAUDE.md
