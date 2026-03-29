# Code Style — streamwatch-ui-legacy

## Language

Dart (Flutter). Target: web (Chrome).

## Formatting

- `dart format` (default Dart formatter, 80-char line width)
- Run `flutter analyze` before every commit — no new warnings

## Naming

- Classes: `PascalCase` (e.g., `JobsBloc`, `VideoTypeModel`)
- Files: `snake_case` (e.g., `jobs_bloc.dart`, `video_type_model.dart`)
- Variables/functions: `camelCase` (e.g., `loadJobs`, `jobTitle`)
- Constants: `camelCase` for top-level, `UPPER_SNAKE_CASE` avoided in Dart
- Private: `_leadingUnderscore`
- BLoC events: imperative (`LoadJobs`, `DeleteJobRequested`)
- BLoC states: descriptive (`JobsStatus.loading`, `JobsStatus.success`)

## Imports

- Dart SDK first, then packages, then relative imports
- Use relative imports within the same package (`import '../models/job.dart'`)
- No wildcard imports

## No Emojis

No emojis in code, comments, commits, logs, or UI strings. This is a hard rule.

## Models

- All models in `lib/data/models/`
- `fromJson` factory constructor required
- Equatable for value equality
- Immutable (final fields)
- Backward compatible JSON shapes unless explicitly requested

## Error Handling

- DataSources return `Either<Failure, T>`
- BLoCs handle failures via state, never throw
- UI shows error states from BLoC state
