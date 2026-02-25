# Repo Structure Skill (Flutter UI)

This skill defines the required folder and file organization for the StreamWatch UI repository.

The goal is:
- Predictable layout
- Clear separation of concerns (BLoC pattern)
- Consistent structure across TMZ Watch UIs
- Easy navigation for Kevin and Claude
- Zero ambiguity about where new code should live

These rules are mandatory.

---

# 1. Required Root Structure

```
streamwatch-ui/
├── lib/
│   ├── main.dart              # App entry point (bootstrap, runApp)
│   ├── app.dart               # MaterialApp, router, auth gate
│   ├── config/                # Legacy configuration (AppConfig)
│   ├── data/
│   │   ├── models/            # JSON-serializable data models
│   │   ├── providers/         # RestClient, TokenStore
│   │   └── sources/           # Data sources (one per API domain)
│   ├── features/              # Feature modules (BLoC pattern)
│   │   └── <feature>/
│   │       ├── bloc/          # <feature>_bloc/event/state.dart
│   │       ├── views/         # <feature>_view.dart
│   │       ├── widgets/       # Feature-specific widgets (optional)
│   │       └── service_locator.dart
│   ├── models/                # Legacy models (migrating to data/models/)
│   ├── pages/                 # Legacy pages (migrating to features/)
│   ├── services/              # Legacy API service (migrating to data/sources/)
│   ├── shared/                # Cross-feature shared code
│   │   └── bloc/              # Shared blocs (auth_session_bloc)
│   ├── themes/                # App theme, TMZ brand theme
│   └── utils/                 # Config singleton, service_locator
├── test/                      # Tests mirror lib/ structure
│   ├── data/
│   │   ├── models/            # Model unit tests
│   │   └── sources/           # Data source tests
│   ├── features/
│   │   └── <feature>/
│   │       ├── bloc/          # BLoC tests
│   │       └── views/         # Widget tests
│   └── widget_test.dart       # Default widget test
├── assets/                    # Static assets (logos, images)
├── docs/                      # Project task files (plan/execution/review)
├── scripts/                   # Deployment and utility scripts
├── infra/                     # CloudFormation templates
├── skills/                    # Skill system (Claude behavior)
├── CLAUDE.md                  # Master behavior + skill loader
├── README.md                  # Project README
├── pubspec.yaml               # Dependencies
└── analysis_options.yaml      # Dart linter rules
```

---

# 2. Directory Responsibilities

## 2.1 `lib/data/models/`
- JSON-serializable model classes
- `fromJson` factory constructors
- `toJson` methods where needed
- Use Equatable for value equality

## 2.2 `lib/data/providers/`
- `RestClient` — HTTP client wrapper (GET, POST, PUT, DELETE, multipart)
- `TokenStore` — Auth token persistence (web: sessionStorage)
- Low-level infrastructure, no business logic

## 2.3 `lib/data/sources/`
- One data source per API domain (e.g., `job_data_source.dart`, `collection_data_source.dart`)
- Each source takes a `RestClient` and exposes typed methods
- Handles JSON parsing and error mapping

## 2.4 `lib/features/<feature>/`
- One directory per feature/screen
- Contains `bloc/`, `views/`, optionally `widgets/`
- Contains `service_locator.dart` for GetIt registration
- BLoC is the only state management pattern

## 2.5 `lib/shared/`
- Cross-feature code (auth session bloc)
- Must be genuinely shared, not feature-specific

## 2.6 `lib/utils/`
- `config.dart` — Config singleton (dart-define flags)
- `service_locator.dart` — Top-level GetIt setup, calls feature service_locators

## 2.7 `lib/themes/`
- `tmz_theme.dart` — TMZ brand colors and constants
- `app_theme.dart` — MaterialApp theme data

## 2.8 Legacy directories (migrating)
- `lib/models/` — Old models, use `lib/data/models/` for new work
- `lib/pages/` — Old pages, use `lib/features/` for new work
- `lib/services/` — Old ApiService, use `lib/data/sources/` for new work
- `lib/config/` — Old AppConfig, use `lib/utils/config.dart` for new work

---

# 3. File Placement Rules

- **New screen/feature?** → `lib/features/<name>/`
- **New data model?** → `lib/data/models/<name>_model.dart`
- **New API integration?** → `lib/data/sources/<name>_data_source.dart`
- **New shared widget?** → `lib/shared/widgets/` (create if needed)
- **New test?** → Mirror the `lib/` path under `test/`

Claude may never place logic ad-hoc or outside this folder structure.

---

# 4. File Naming Rules

- Dart files: lowercase, underscore-separated: `job_model.dart`, `home_bloc.dart`
- Test files: same name as source with `_test` suffix: `job_model_test.dart`
- BLoC triad: `<feature>_bloc.dart`, `<feature>_event.dart`, `<feature>_state.dart`
- Views: `<feature>_view.dart`
- Service locators: `service_locator.dart` (one per feature)

---

# 5. Enforcement

Claude must:
- Maintain this repo structure during all operations
- Create missing folders only when necessary
- Never move files unless instructed
- Avoid producing large diffs by reorganizing without permission
- Place new features in `lib/features/`, never in legacy `lib/pages/`
- Place new models in `lib/data/models/`, never in legacy `lib/models/`

If a structure decision is ambiguous, Claude must write questions in the Plan file before proceeding.

---

End of repo_structure.md
