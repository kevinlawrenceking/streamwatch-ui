/// Service locator for Scheduler feature.
///
/// This is a placeholder for Phase 2 development.
/// When implemented, this will register:
/// - SchedulerBloc for managing scheduled jobs
/// - SchedulerRepository for API interactions
class ServiceLocator {
  static bool _initialized = false;

  static void init() {
    if (_initialized) {
      throw Exception('Scheduler ServiceLocator already initialized!');
    }
    // Placeholder - no registrations yet
    // final sl = GetIt.instance;
    // sl.registerFactory<SchedulerBloc>(() => SchedulerBloc(...));
    _initialized = true;
  }
}
