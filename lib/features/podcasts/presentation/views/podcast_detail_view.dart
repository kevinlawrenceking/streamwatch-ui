import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../themes/app_theme.dart';
import '../bloc/podcast_detail_bloc.dart';
import '../widgets/platform_card.dart';
import '../widgets/platform_form_dialog.dart';
import '../widgets/schedule_form_dialog.dart';
import '../widgets/schedule_slot_card.dart';

/// Podcast detail view - shows podcast info, platforms, and schedules.
class PodcastDetailView extends StatelessWidget {
  final String podcastId;

  const PodcastDetailView({super.key, required this.podcastId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PodcastDetailBloc>(
      create: (_) => GetIt.instance<PodcastDetailBloc>()
        ..add(FetchPodcastDetailEvent(podcastId)),
      child: _PodcastDetailBody(podcastId: podcastId),
    );
  }
}

class _PodcastDetailBody extends StatelessWidget {
  final String podcastId;

  const _PodcastDetailBody({required this.podcastId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PodcastDetailBloc, PodcastDetailState>(
      listener: (context, state) {
        if (state is PodcastDetailLoaded && state.actionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<PodcastDetailBloc, PodcastDetailState>(
        builder: (context, state) {
          return Scaffold(
            appBar: TmzAppBar(
              app: WatchAppIdentity.streamWatch,
              customTitle: state is PodcastDetailLoaded
                  ? state.podcast.name
                  : 'Podcast Detail',
              showBackButton: true,
              actions: [
                if (state is PodcastDetailLoaded)
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    tooltip: 'View Episodes',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/episodes',
                        arguments: podcastId,
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    context
                        .read<PodcastDetailBloc>()
                        .add(FetchPodcastDetailEvent(podcastId));
                  },
                ),
              ],
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, PodcastDetailState state) {
    if (state is PodcastDetailLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PodcastDetailError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: AppColors.textDim),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context
                    .read<PodcastDetailBloc>()
                    .add(FetchPodcastDetailEvent(podcastId));
              },
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    if (state is PodcastDetailLoaded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Podcast info header
            _PodcastInfoSection(
              state: state,
              onEdit: () => _showEditDialog(context, state),
            ),
            const SizedBox(height: 24),

            // Platforms section
            _SectionHeader(
              title: 'Platforms',
              icon: Icons.link,
              onAdd: () => _showAddPlatformDialog(context),
            ),
            const SizedBox(height: 8),
            if (state.platforms.isEmpty)
              const _EmptySection(
                message: 'No platform links yet',
                icon: Icons.link_off,
              )
            else
              ...state.platforms.map((platform) => PlatformCard(
                    platform: platform,
                    onEdit: () =>
                        _showEditPlatformDialog(context, platform),
                    onDelete: () => _confirmDeletePlatform(
                        context, platform.id, platform.platformName),
                  )),
            const SizedBox(height: 24),

            // Schedules section
            _SectionHeader(
              title: 'Schedule Slots',
              icon: Icons.schedule,
              onAdd: () => _showAddScheduleDialog(context),
            ),
            const SizedBox(height: 8),
            if (state.schedules.isEmpty)
              const _EmptySection(
                message: 'No schedule slots yet',
                icon: Icons.event_busy,
              )
            else
              ...state.schedules.map((schedule) => ScheduleSlotCard(
                    schedule: schedule,
                    onEdit: () =>
                        _showEditScheduleDialog(context, schedule),
                    onDelete: () => _confirmDeleteSchedule(
                        context, schedule.id, schedule.dayOfWeek),
                  )),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showEditDialog(
      BuildContext context, PodcastDetailLoaded state) async {
    final nameController =
        TextEditingController(text: state.podcast.name);
    final descController =
        TextEditingController(text: state.podcast.description ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Podcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: 'Podcast Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration:
                  const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.tmzRed),
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(dialogContext).pop(<String, dynamic>{
                'name': name,
                'description': descController.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    descController.dispose();

    if (result != null && context.mounted) {
      context.read<PodcastDetailBloc>().add(
            UpdatePodcastEvent(podcastId: podcastId, body: result),
          );
    }
  }

  void _showAddPlatformDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const PlatformFormDialog(),
    );
    if (result != null && context.mounted) {
      context.read<PodcastDetailBloc>().add(
            AddPlatformEvent(podcastId: podcastId, body: result),
          );
    }
  }

  void _showEditPlatformDialog(
      BuildContext context, platform) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PlatformFormDialog(existing: platform),
    );
    if (result != null && context.mounted) {
      context.read<PodcastDetailBloc>().add(
            UpdatePlatformEvent(
                platformId: platform.id, body: result),
          );
    }
  }

  void _confirmDeletePlatform(
      BuildContext context, String platformId, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Platform?'),
        content: Text('Remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<PodcastDetailBloc>()
                  .add(DeletePlatformEvent(platformId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddScheduleDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const ScheduleFormDialog(),
    );
    if (result != null && context.mounted) {
      context.read<PodcastDetailBloc>().add(
            AddScheduleEvent(podcastId: podcastId, body: result),
          );
    }
  }

  void _showEditScheduleDialog(
      BuildContext context, schedule) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ScheduleFormDialog(existing: schedule),
    );
    if (result != null && context.mounted) {
      context.read<PodcastDetailBloc>().add(
            UpdateScheduleEvent(
                scheduleId: schedule.id, body: result),
          );
    }
  }

  void _confirmDeleteSchedule(
      BuildContext context, String scheduleId, String day) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Schedule?'),
        content: Text(
            'Remove the ${day[0].toUpperCase()}${day.substring(1)} slot? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<PodcastDetailBloc>()
                  .add(DeleteScheduleEvent(scheduleId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PodcastInfoSection extends StatelessWidget {
  final PodcastDetailLoaded state;
  final VoidCallback onEdit;

  const _PodcastInfoSection({
    required this.state,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final podcast = state.podcast;

    return TmzCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.podcasts,
                color: podcast.isActive
                    ? AppColors.success
                    : AppColors.textGhost,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  podcast.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: onEdit,
              ),
            ],
          ),
          if (podcast.description != null &&
              podcast.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              podcast.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: AppColors.textDim),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TmzStatusBadge(
                status: podcast.isActive ? 'active' : 'inactive',
                color: podcast.isActive
                    ? AppColors.success
                    : AppColors.textGhost,
              ),
              const SizedBox(width: 12),
              Text(
                'Created ${_formatDate(podcast.createdAt)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: AppColors.textDim, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onAdd;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.tmzRed),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppColors.textDim,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          tooltip: 'Add $title',
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptySection({
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textGhost),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: AppColors.textGhost),
            ),
          ],
        ),
      ),
    );
  }
}
