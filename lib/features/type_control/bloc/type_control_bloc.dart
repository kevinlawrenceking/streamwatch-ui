import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/sources/video_type_data_source.dart';
import 'type_control_event.dart';
import 'type_control_state.dart';

/// BLoC for managing the type list (types screen).
class TypeControlBloc extends Bloc<TypeControlEvent, TypeControlState> {
  final IVideoTypeDataSource _dataSource;

  TypeControlBloc({required IVideoTypeDataSource dataSource})
      : _dataSource = dataSource,
        super(const TypeControlInitial()) {
    on<LoadTypesEvent>(_onLoadTypes);
  }

  Future<void> _onLoadTypes(
    LoadTypesEvent event,
    Emitter<TypeControlState> emit,
  ) async {
    emit(const TypeControlLoading());

    final result = await _dataSource.getVideoTypes();

    result.fold(
      (failure) => emit(TypeControlError(failure)),
      (types) => emit(TypeControlLoaded(types: types)),
    );
  }
}

/// BLoC for managing type detail (versions, rules, prompt).
class TypeDetailBloc extends Bloc<TypeControlEvent, TypeDetailState> {
  final IVideoTypeDataSource _dataSource;

  TypeDetailBloc({required IVideoTypeDataSource dataSource})
      : _dataSource = dataSource,
        super(const TypeDetailInitial()) {
    on<SelectTypeEvent>(_onSelectType);
    on<LoadRulesEvent>(_onLoadRules);
    on<RenderTypePromptEvent>(_onRenderTypePrompt);
    on<RenderVersionPromptEvent>(_onRenderVersionPrompt);
    on<ActivateVersionEvent>(_onActivateVersion);
    on<RollbackVersionEvent>(_onRollbackVersion);
  }

  Future<void> _onSelectType(
    SelectTypeEvent event,
    Emitter<TypeDetailState> emit,
  ) async {
    emit(const TypeDetailLoading());

    final typeResult = await _dataSource.getVideoType(event.videoTypeId);

    await typeResult.fold(
      (failure) async => emit(TypeDetailError(failure)),
      (type) async {
        final versionsResult =
            await _dataSource.getVersions(event.videoTypeId);

        await versionsResult.fold(
          (failure) async => emit(TypeDetailError(failure)),
          (versions) async {
            final loaded = TypeDetailLoaded(
              type: type,
              versions: versions,
            );
            emit(loaded);

            // Auto-load rules for the active version
            final activeVersion = loaded.activeVersion;
            if (activeVersion != null) {
              emit(loaded.copyWith(
                isRulesLoading: true,
                selectedVersionId: activeVersion.id,
              ));
              final rulesResult =
                  await _dataSource.getRules(activeVersion.id);
              if (state is! TypeDetailLoaded) return;
              final latestState = state as TypeDetailLoaded;
              rulesResult.fold(
                (failure) => emit(latestState.copyWith(
                  isRulesLoading: false,
                )),
                (rules) => emit(latestState.copyWith(
                  rules: rules,
                  isRulesLoading: false,
                )),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _onLoadRules(
    LoadRulesEvent event,
    Emitter<TypeDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TypeDetailLoaded) return;

    emit(currentState.copyWith(
      isRulesLoading: true,
      selectedVersionId: event.versionId,
      clearRules: true,
    ));

    final result = await _dataSource.getRules(event.versionId);

    if (state is! TypeDetailLoaded) return;
    final latestState = state as TypeDetailLoaded;

    result.fold(
      (failure) => emit(latestState.copyWith(
        isRulesLoading: false,
        actionError: failure.message,
      )),
      (rules) => emit(latestState.copyWith(
        rules: rules,
        isRulesLoading: false,
      )),
    );
  }

  Future<void> _onRenderTypePrompt(
    RenderTypePromptEvent event,
    Emitter<TypeDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TypeDetailLoaded) return;

    emit(currentState.copyWith(isPromptLoading: true, clearPrompt: true));

    final result = await _dataSource.renderTypePrompt(event.videoTypeId);

    if (state is! TypeDetailLoaded) return;
    final latestState = state as TypeDetailLoaded;

    result.fold(
      (failure) => emit(latestState.copyWith(
        isPromptLoading: false,
        actionError: failure.message,
      )),
      (prompt) => emit(latestState.copyWith(
        renderedPrompt: prompt,
        isPromptLoading: false,
      )),
    );
  }

  Future<void> _onRenderVersionPrompt(
    RenderVersionPromptEvent event,
    Emitter<TypeDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TypeDetailLoaded) return;

    emit(currentState.copyWith(isPromptLoading: true, clearPrompt: true));

    final result = await _dataSource.renderVersionPrompt(event.versionId);

    if (state is! TypeDetailLoaded) return;
    final latestState = state as TypeDetailLoaded;

    result.fold(
      (failure) => emit(latestState.copyWith(
        isPromptLoading: false,
        actionError: failure.message,
      )),
      (prompt) => emit(latestState.copyWith(
        renderedPrompt: prompt,
        isPromptLoading: false,
      )),
    );
  }

  Future<void> _onActivateVersion(
    ActivateVersionEvent event,
    Emitter<TypeDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TypeDetailLoaded) return;

    final result = await _dataSource.activateVersion(event.versionId);

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionError: failure.message,
      )),
      (_) {
        // Reload the type detail to get fresh version statuses
        add(SelectTypeEvent(event.videoTypeId));
      },
    );
  }

  Future<void> _onRollbackVersion(
    RollbackVersionEvent event,
    Emitter<TypeDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TypeDetailLoaded) return;

    final result = await _dataSource.rollbackVersion(event.videoTypeId);

    result.fold(
      (failure) => emit(currentState.copyWith(
        actionError: failure.message,
      )),
      (_) {
        // Reload the type detail to get fresh version statuses
        add(SelectTypeEvent(event.videoTypeId));
      },
    );
  }
}
