import 'package:get_it/get_it.dart';
import '../../data/sources/video_type_data_source.dart';
import 'bloc/type_control_bloc.dart';
import 'bloc/rule_management_bloc.dart';
import 'bloc/candidate_review_bloc.dart';
import 'bloc/exemplar_management_bloc.dart';

/// Service locator for the type_control feature.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes feature dependencies.
  /// Must be called after global service locator is initialized.
  static void init() {
    if (_initialized) {
      throw Exception('TypeControl ServiceLocator already initialized!');
    }

    final sl = GetIt.instance;

    sl.registerFactory<TypeControlBloc>(
      () => TypeControlBloc(dataSource: sl<IVideoTypeDataSource>()),
    );

    sl.registerFactory<TypeDetailBloc>(
      () => TypeDetailBloc(dataSource: sl<IVideoTypeDataSource>()),
    );

    sl.registerFactory<RuleManagementBloc>(
      () => RuleManagementBloc(dataSource: sl<IVideoTypeDataSource>()),
    );

    sl.registerFactory<CandidateReviewBloc>(
      () => CandidateReviewBloc(dataSource: sl<IVideoTypeDataSource>()),
    );

    sl.registerFactory<ExemplarManagementBloc>(
      () => ExemplarManagementBloc(dataSource: sl<IVideoTypeDataSource>()),
    );

    _initialized = true;
  }
}
