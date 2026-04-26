import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../themes/app_theme.dart';
import '../../../podcasts/data/models/podcast_episode.dart';
import '../bloc/episode_detail_bloc.dart';
import '../bloc/episode_headlines_bloc.dart';
import '../bloc/episode_notifications_bloc.dart';
import '../bloc/episode_transcripts_bloc.dart';
import '../widgets/create_notification_dialog.dart';
import '../widgets/create_transcript_dialog.dart';
import '../widgets/episode_action_bar.dart';
import '../widgets/headline_candidate_card.dart';
import '../widgets/notification_card.dart';
import '../widgets/transcript_card.dart';

/// Top-level view for the Episode Detail surface (WO-077 / LSW-015).
///
/// Tabs (Overview / Transcripts / Headlines / Notifications) share the
/// same EpisodeDetailBloc context so the action bar at the top of the
/// scaffold is the single source of truth for episode-state mutations.
/// Tab-scoped blocs subscribe to EpisodeDetailBloc via BlocListener and
/// refetch when [PodcastEpisodeModel] equality changes (Plan Lock #3).
class EpisodeDetailView extends StatelessWidget {
  final String episodeId;

  const EpisodeDetailView({super.key, required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EpisodeDetailBloc>(
          create: (_) => GetIt.instance<EpisodeDetailBloc>()
            ..add(LoadEpisodeEvent(episodeId)),
        ),
        BlocProvider<EpisodeTranscriptsBloc>(
          create: (_) => GetIt.instance<EpisodeTranscriptsBloc>()
            ..add(LoadTranscriptsEvent(episodeId)),
        ),
        BlocProvider<EpisodeHeadlinesBloc>(
          create: (_) => GetIt.instance<EpisodeHeadlinesBloc>()
            ..add(LoadHeadlinesEvent(episodeId)),
        ),
        BlocProvider<EpisodeNotificationsBloc>(
          create: (_) => GetIt.instance<EpisodeNotificationsBloc>()
            ..add(LoadNotificationsEvent(episodeId)),
        ),
      ],
      child: DefaultTabController(
        length: 4,
        child: _EpisodeDetailScaffold(episodeId: episodeId),
      ),
    );
  }
}

class _EpisodeDetailScaffold extends StatelessWidget {
  final String episodeId;
  const _EpisodeDetailScaffold({required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EpisodeDetailBloc, EpisodeDetailState>(
      listenWhen: (prev, curr) =>
          curr is EpisodeDetailLoaded && curr.lastActionError != null,
      listener: (context, state) {
        if (state is EpisodeDetailLoaded && state.lastActionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.lastActionError!)),
          );
          context
              .read<EpisodeDetailBloc>()
              .add(const EpisodeDetailErrorAcknowledged());
        }
      },
      builder: (context, state) {
        if (state is EpisodeDetailInitial || state is EpisodeDetailLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Episode')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is EpisodeDetailError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Episode')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<EpisodeDetailBloc>()
                        .add(LoadEpisodeEvent(episodeId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is EpisodeDetailLoaded) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.episode.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Transcripts'),
                  Tab(text: 'Headlines'),
                  Tab(text: 'Notifications'),
                ],
              ),
            ),
            body: Column(
              children: [
                EpisodeActionBar(
                  episode: state.episode,
                  isMutating: state.isMutating,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(episode: state.episode),
                      _TranscriptsTab(episodeId: episodeId),
                      _HeadlinesTab(episodeId: episodeId),
                      _NotificationsTab(episodeId: episodeId),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ============================================================================
// Tab 1: Overview -- stateless, consumes EpisodeDetailBloc.state.episode.
// ============================================================================

class _OverviewTab extends StatelessWidget {
  final PodcastEpisodeModel episode;
  const _OverviewTab({required this.episode});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(context, 'Title', episode.title),
          if (episode.episodeDescription != null &&
              episode.episodeDescription!.isNotEmpty)
            _row(context, 'Description', episode.episodeDescription!),
          if (episode.platformType != null && episode.platformType!.isNotEmpty)
            _row(context, 'Platform', episode.platformType!),
          if (episode.platformEpisodeUrl != null &&
              episode.platformEpisodeUrl!.isNotEmpty)
            _row(context, 'Platform URL', episode.platformEpisodeUrl!),
          if (episode.guestNames != null && episode.guestNames!.isNotEmpty)
            _row(context, 'Guests', episode.guestNames!.join(', ')),
          const Divider(),
          _row(context, 'Processing', episode.processingStatus ?? '(unknown)'),
          _row(context, 'Transcript', episode.transcriptStatus ?? '(unknown)'),
          _row(context, 'Headline', episode.headlineStatus ?? '(unknown)'),
          _row(context, 'Notification',
              episode.notificationStatus ?? '(unknown)'),
          const Divider(),
          if (episode.publishedAt != null)
            _row(context, 'Published', _formatDate(episode.publishedAt!)),
          if (episode.discoveredAt != null)
            _row(context, 'Discovered', _formatDate(episode.discoveredAt!)),
          if (episode.reviewedAt != null)
            _row(context, 'Reviewed', _formatDate(episode.reviewedAt!)),
          _row(context, 'Created', _formatDate(episode.createdAt)),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.textDim, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// Tab 2: Transcripts.
// ============================================================================

class _TranscriptsTab extends StatelessWidget {
  final String episodeId;
  const _TranscriptsTab({required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Tab subscription: refetch when episode changes (Plan Lock #3).
        BlocListener<EpisodeDetailBloc, EpisodeDetailState>(
          listenWhen: (prev, curr) =>
              prev is EpisodeDetailLoaded &&
              curr is EpisodeDetailLoaded &&
              prev.episode != curr.episode,
          listener: (context, _) => context
              .read<EpisodeTranscriptsBloc>()
              .add(LoadTranscriptsEvent(episodeId)),
        ),
        // SnackBar listener for action errors.
        BlocListener<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
          listenWhen: (prev, curr) =>
              curr is EpisodeTranscriptsLoaded && curr.lastActionError != null,
          listener: (context, state) {
            if (state is EpisodeTranscriptsLoaded &&
                state.lastActionError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.lastActionError!)),
              );
              context
                  .read<EpisodeTranscriptsBloc>()
                  .add(const EpisodeTranscriptsErrorAcknowledged());
            }
          },
        ),
      ],
      child: BlocBuilder<EpisodeTranscriptsBloc, EpisodeTranscriptsState>(
        builder: (context, state) {
          if (state is EpisodeTranscriptsInitial ||
              state is EpisodeTranscriptsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EpisodeTranscriptsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<EpisodeTranscriptsBloc>()
                        .add(LoadTranscriptsEvent(episodeId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is EpisodeTranscriptsLoaded) {
            return Stack(
              children: [
                state.transcripts.isEmpty
                    ? const _EmptyState(
                        icon: Icons.subtitles_outlined,
                        label: 'No transcripts yet.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.transcripts.length,
                        itemBuilder: (_, index) {
                          final t = state.transcripts[index];
                          return TranscriptCard(
                            transcript: t,
                            inFlight: state.isMutating,
                            onSetPrimary: () => context
                                .read<EpisodeTranscriptsBloc>()
                                .add(SetPrimaryTranscriptEvent(t.id)),
                            onDelete: () => context
                                .read<EpisodeTranscriptsBloc>()
                                .add(DeleteTranscriptEvent(t.id)),
                          );
                        },
                      ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'transcripts_fab',
                    onPressed: state.isMutating
                        ? null
                        : () async {
                            final body = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (_) => const CreateTranscriptDialog(),
                            );
                            if (body != null && context.mounted) {
                              context
                                  .read<EpisodeTranscriptsBloc>()
                                  .add(CreateTranscriptEvent(
                                    episodeId: episodeId,
                                    body: body,
                                  ));
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('New Transcript'),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ============================================================================
// Tab 3: Headlines.
// ============================================================================

class _HeadlinesTab extends StatelessWidget {
  final String episodeId;
  const _HeadlinesTab({required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EpisodeDetailBloc, EpisodeDetailState>(
          listenWhen: (prev, curr) =>
              prev is EpisodeDetailLoaded &&
              curr is EpisodeDetailLoaded &&
              prev.episode != curr.episode,
          listener: (context, _) => context
              .read<EpisodeHeadlinesBloc>()
              .add(LoadHeadlinesEvent(episodeId)),
        ),
        BlocListener<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
          listenWhen: (prev, curr) =>
              curr is EpisodeHeadlinesLoaded && curr.lastActionError != null,
          listener: (context, state) {
            if (state is EpisodeHeadlinesLoaded &&
                state.lastActionError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.lastActionError!)),
              );
              context
                  .read<EpisodeHeadlinesBloc>()
                  .add(const EpisodeHeadlinesErrorAcknowledged());
            }
          },
        ),
      ],
      child: BlocBuilder<EpisodeHeadlinesBloc, EpisodeHeadlinesState>(
        builder: (context, state) {
          if (state is EpisodeHeadlinesInitial ||
              state is EpisodeHeadlinesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EpisodeHeadlinesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<EpisodeHeadlinesBloc>()
                        .add(LoadHeadlinesEvent(episodeId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is EpisodeHeadlinesLoaded) {
            return Stack(
              children: [
                Column(
                  children: [
                    if (state.isGenerating)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: AppColors.info,
                        child: Text(
                          'Generating headlines... refresh to see new candidates.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: AppColors.textMax),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: state.candidates.isEmpty
                          ? const _EmptyState(
                              icon: Icons.title,
                              label: 'No headline candidates yet.')
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.candidates.length,
                              itemBuilder: (_, index) {
                                final c = state.candidates[index];
                                return HeadlineCandidateCard(
                                  candidate: c,
                                  inFlight: state.isMutating,
                                  onApprove: () => context
                                      .read<EpisodeHeadlinesBloc>()
                                      .add(ApproveHeadlineEvent(
                                        candidateId: c.id,
                                        episodeId: episodeId,
                                      )),
                                  onDelete: () => context
                                      .read<EpisodeHeadlinesBloc>()
                                      .add(DeleteHeadlineEvent(c.id)),
                                );
                              },
                            ),
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'headlines_fab',
                    onPressed: state.isMutating
                        ? null
                        : () => context
                            .read<EpisodeHeadlinesBloc>()
                            .add(GenerateHeadlinesEvent(episodeId)),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate'),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ============================================================================
// Tab 4: Notifications.
// ============================================================================

class _NotificationsTab extends StatelessWidget {
  final String episodeId;
  const _NotificationsTab({required this.episodeId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<EpisodeDetailBloc, EpisodeDetailState>(
          listenWhen: (prev, curr) =>
              prev is EpisodeDetailLoaded &&
              curr is EpisodeDetailLoaded &&
              prev.episode != curr.episode,
          listener: (context, _) => context
              .read<EpisodeNotificationsBloc>()
              .add(LoadNotificationsEvent(episodeId)),
        ),
        BlocListener<EpisodeNotificationsBloc, EpisodeNotificationsState>(
          listenWhen: (prev, curr) =>
              curr is EpisodeNotificationsLoaded &&
              curr.lastActionError != null,
          listener: (context, state) {
            if (state is EpisodeNotificationsLoaded &&
                state.lastActionError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.lastActionError!)),
              );
              context
                  .read<EpisodeNotificationsBloc>()
                  .add(const EpisodeNotificationsErrorAcknowledged());
            }
          },
        ),
      ],
      child: BlocBuilder<EpisodeNotificationsBloc, EpisodeNotificationsState>(
        builder: (context, state) {
          if (state is EpisodeNotificationsInitial ||
              state is EpisodeNotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is EpisodeNotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context
                        .read<EpisodeNotificationsBloc>()
                        .add(LoadNotificationsEvent(episodeId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is EpisodeNotificationsLoaded) {
            return Stack(
              children: [
                state.notifications.isEmpty
                    ? const _EmptyState(
                        icon: Icons.notifications_outlined,
                        label: 'No notifications yet.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.notifications.length,
                        itemBuilder: (_, index) {
                          final n = state.notifications[index];
                          return NotificationCard(
                            notification: n,
                            inFlight: state.isMutating,
                            onSend: () => context
                                .read<EpisodeNotificationsBloc>()
                                .add(SendNotificationEvent(n.id)),
                            onDelete: () => context
                                .read<EpisodeNotificationsBloc>()
                                .add(DeleteNotificationEvent(n.id)),
                          );
                        },
                      ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.extended(
                    heroTag: 'notifications_fab',
                    onPressed: state.isMutating
                        ? null
                        : () async {
                            final body = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (_) => const CreateNotificationDialog(),
                            );
                            if (body != null && context.mounted) {
                              context
                                  .read<EpisodeNotificationsBloc>()
                                  .add(CreateNotificationEvent(
                                    episodeId: episodeId,
                                    body: body,
                                  ));
                            }
                          },
                    icon: const Icon(Icons.add),
                    label: const Text('New Notification'),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ============================================================================
// Shared empty-state placeholder.
// ============================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textGhost),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}
