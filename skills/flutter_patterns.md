# Flutter Patterns — streamwatch-ui-legacy

## Architecture

Pure client. No database access. All data via REST API.

```
Flutter Web App (browser)
  -> HTTPS to API Gateway
  -> Lambda Go API handles all business logic
  -> S3 signed URLs for media playback
```

## State Management

BLoC is the ONLY state management pattern. No Provider, no Riverpod, no setState for business logic.

Pattern: `BLoC + GetIt + Equatable`

## Dependency Injection

GetIt service locator. Each feature has its own `service_locator.dart`.
Top-level `lib/utils/service_locator.dart` calls all feature-level registrations.

## HTTP Client

`RestClient` in `lib/data/providers/rest_client.dart`. Wraps `http` package.
Adds auth token from `TokenStore` to every request.

## Data Flow

```
View -> BLoC Event -> BLoC Handler -> DataSource -> RestClient -> API
                                                              <- JSON
                                    <- Model <- DataSource
         <- State Update <- BLoC
View <-
```

## Error Handling

- DataSources return `Either<Failure, T>` via `ExceptionHandler`
- BLoCs emit error states, never throw
- Views show error widgets from BLoC error states

## Auth

- `AuthSessionBloc` in `lib/shared/bloc/`
- `TokenStore` persists JWT in sessionStorage (web)
- Auth probe: `GET /api/v1/jobs` to verify token validity
- `DEV_ASSUME_ADMIN=true` stubs admin session in dev mode

## Navigation

- Routes defined in `lib/app.dart`
- No `go_router` — uses basic MaterialApp routing
- Nav drawer + app bar with feature icons

## Media

- Video/audio playback via signed S3 URLs
- Thumbnails via `GET /api/v1/jobs/{id}/thumbnail`
- Never fetch raw media through the API

## Widget Patterns

- Prefer composition over inheritance
- Feature-specific widgets in `features/<name>/widgets/`
- Shared widgets in `lib/shared/widgets/` (create if needed)
- Loading states: `CircularProgressIndicator` centered
- Empty states: informative message with action button
- Error states: error message with retry button
