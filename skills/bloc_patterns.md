# BLoC Patterns — streamwatch-ui-legacy

## Structure

Every feature gets exactly one BLoC with three files:

```
lib/features/<feature>/bloc/
├── <feature>_bloc.dart    # BLoC class with event handlers
├── <feature>_event.dart   # Event classes (sealed or abstract)
└── <feature>_state.dart   # State classes with Equatable
```

## Event Naming

Events are imperative or descriptive:
- `LoadJobs` — request to load data
- `RefreshJobs` — explicit refresh
- `DeleteJobRequested` — user action
- `JobsFilterChanged` — parameter change

## State Pattern

States use Equatable and follow this pattern:

```dart
enum JobsStatus { initial, loading, success, failure }

class JobsState extends Equatable {
  final JobsStatus status;
  final List<Job> jobs;
  final String? errorMessage;

  const JobsState({
    this.status = JobsStatus.initial,
    this.jobs = const [],
    this.errorMessage,
  });

  JobsState copyWith({...}) => JobsState(...);

  @override
  List<Object?> get props => [status, jobs, errorMessage];
}
```

## Registration

Each feature has `service_locator.dart`:

```dart
void registerJobsFeature() {
  final sl = GetIt.instance;
  sl.registerFactory(() => JobsBloc(dataSource: sl()));
}
```

Called from top-level `lib/utils/service_locator.dart`.

## BLoC Rules

- One BLoC per feature/screen. Never share BLoCs across features.
- BLoCs never import UI widgets.
- BLoCs never make HTTP calls directly — they call DataSources.
- BLoCs emit states, never throw exceptions.
- Use `emit()` only inside event handlers.
- All async work in event handlers, not constructors.
- Dispose/close handled by BlocProvider (widget tree manages lifecycle).

## View Integration

```dart
BlocProvider(
  create: (_) => GetIt.instance<JobsBloc>()..add(LoadJobs()),
  child: JobsView(),
)
```

Views use `BlocBuilder` for UI updates and `BlocListener` for side effects (navigation, snackbars).

## Testing

```dart
blocTest<JobsBloc, JobsState>(
  'emits [loading, success] when LoadJobs succeeds',
  build: () => JobsBloc(dataSource: mockDataSource),
  act: (bloc) => bloc.add(LoadJobs()),
  expect: () => [
    JobsState(status: JobsStatus.loading),
    JobsState(status: JobsStatus.success, jobs: testJobs),
  ],
);
```

Use `bloc_test` package. Mock DataSources with `mocktail`.
