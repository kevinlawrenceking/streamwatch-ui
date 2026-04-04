import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../data/models/video_type_model.dart';
import '../../../themes/app_theme.dart';
import '../bloc/type_control_bloc.dart';
import '../bloc/type_control_event.dart';
import '../bloc/type_control_state.dart';

/// Type list screen - shows all video types for TypeControl.
class TypeListView extends StatelessWidget {
  const TypeListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TypeControlBloc>(
      create: (_) =>
          GetIt.instance<TypeControlBloc>()..add(const LoadTypesEvent()),
      child: const _TypeListBody(),
    );
  }
}

class _TypeListBody extends StatelessWidget {
  const _TypeListBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TmzAppBar(
        app: WatchAppIdentity.streamWatch,
        customTitle: 'Type Control',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<TypeControlBloc>().add(const LoadTypesEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<TypeControlBloc, TypeControlState>(
        builder: (context, state) {
          if (state is TypeControlLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TypeControlError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.failure.message}',
                    style: Theme.of(context).textTheme.bodyMedium!
                        .copyWith(color: AppColors.textDim),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<TypeControlBloc>()
                          .add(const LoadTypesEvent());
                    },
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            );
          }

          if (state is TypeControlLoaded) {
            if (state.types.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.category_outlined,
                        size: 64, color: AppColors.textGhost),
                    const SizedBox(height: 16),
                    Text(
                      'No video types defined yet',
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(color: AppColors.textDim),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.types.length,
              itemBuilder: (context, index) {
                return _TypeCard(type: state.types[index]);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final VideoTypeModel type;

  const _TypeCard({required this.type});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/type-control/detail',
              arguments: type.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.category,
                color: type.isActive ? AppColors.success : AppColors.textGhost,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Updated ${_formatDate(type.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall!,
                    ),
                  ],
                ),
              ),
              _StatusChip(status: type.status),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textGhost),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'draft':
        return AppColors.warning;
      case 'archived':
        return AppColors.textGhost;
      default:
        return AppColors.textGhost;
    }
  }
}
