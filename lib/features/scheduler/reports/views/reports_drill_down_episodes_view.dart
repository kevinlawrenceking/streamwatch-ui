import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../themes/app_theme.dart';
import '../bloc/reported_episodes_bloc.dart';
import '../constants/report_keys.dart';
import '../widgets/reported_episode_card.dart';

/// Episode-valued drill-down (recent, transcript-pending, headline-ready,
/// pending-review, pending-clip-request). Infinite scroll + pull-to-refresh +
/// inline actions (mark-reviewed, request-clip) driven by the E6 visibility
/// matrix.
class ReportsDrillDownEpisodesView extends StatelessWidget {
  final String reportKey;
  final String label;

  const ReportsDrillDownEpisodesView({
    super.key,
    required this.reportKey,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final meta = reportMetaByKey(reportKey);
    final accent = meta?.color ?? AppColors.textDim;

    return BlocConsumer<ReportedEpisodesBloc, ReportedEpisodesState>(
      listenWhen: (prev, curr) =>
          curr is ReportedEpisodesLoaded && curr.lastActionError != null,
      listener: (context, state) {
        if (state is ReportedEpisodesLoaded && state.lastActionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.lastActionError!)),
          );
          context
              .read<ReportedEpisodesBloc>()
              .add(const ActionErrorAcknowledgedEvent());
        }
      },
      builder: (context, state) {
        if (state is ReportedEpisodesInitial ||
            state is ReportedEpisodesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReportedEpisodesError) {
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
                  onPressed: () => context.read<ReportedEpisodesBloc>().add(
                        FetchReportedEpisodesEvent(reportKey: reportKey),
                      ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ReportedEpisodesLoaded) {
          if (state.episodes.isEmpty) {
            return const _EmptyState(label: 'No episodes match this report.');
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200 &&
                  state.hasMore) {
                context
                    .read<ReportedEpisodesBloc>()
                    .add(FetchReportedEpisodesEvent(
                      reportKey: reportKey,
                      page: state.currentPage + 1,
                    ));
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ReportedEpisodesBloc>().add(
                      FetchReportedEpisodesEvent(reportKey: reportKey),
                    );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.episodes.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.episodes.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final ep = state.episodes[index];
                  final isInFlight =
                      state.inFlightEpisodeIds.contains(ep.id);
                  return ReportedEpisodeCard(
                    episode: ep,
                    reportKey: reportKey,
                    accentColor: accent,
                    inFlight: isInFlight,
                    onMarkReviewed: () => context
                        .read<ReportedEpisodesBloc>()
                        .add(MarkReviewedRequestedEvent(ep.id)),
                    onRequestClip: () => context
                        .read<ReportedEpisodesBloc>()
                        .add(RequestClipRequestedEvent(ep.id)),
                  );
                },
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 48, color: AppColors.textGhost),
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
