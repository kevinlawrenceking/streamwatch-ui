import 'package:get_it/get_it.dart';
import '../../data/sources/auth_data_source.dart';
import '../../data/sources/job_data_source.dart';
import '../../data/sources/upload_data_source.dart';
import 'bloc/upload_bloc.dart';

/// Service locator for the upload feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('Upload ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    // Register UploadDataSource for presigned S3 uploads
    sl.registerLazySingleton<IUploadDataSource>(
      () => UploadDataSource(auth: sl<IAuthDataSource>()),
    );

    // BLoCs as factories - new instance per widget
    sl.registerFactory<UploadBloc>(
      () => UploadBloc(
        jobDataSource: sl<IJobDataSource>(),
        uploadDataSource: sl<IUploadDataSource>(),
      ),
    );

    _initialized = true;
  }
}
