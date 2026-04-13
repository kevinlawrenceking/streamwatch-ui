import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../themes/app_theme.dart';
import '../../data/models/podcast_episode.dart';
import '../bloc/episode_list_bloc.dart';

/// Episode list view - read-only paginated list of episodes.
class EpisodeListView extends StatelessWidget {
  final String podcastId;

  const EpisodeListView({super.key, required this.podcastId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EpisodeListBloc>(
      create: (_) => GetIt.instance<EpisodeListBloc>()
        ..add(FetchEpisodesEvent(podcastId: podcastId)),
      child: _EpisodeListBody(podcastId: podcastId),
    );
  }
}

class _EpisodeListBody extends StatelessWidget {
  final String podcastId;

  const _EpisodeListBody({required this.podcastId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EpisodeListBloc, EpisodeListState>(
      builder: (context, state) {
        if (state is EpisodeListLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is EpisodeListError) {
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
                        .read<EpisodeListBloc>()
                        .add(FetchEpisodesEvent(podcastId: podcastId));
                  },
                  child: const Text('RETRY'),
                ),
              ],
            ),
          );
        }

        if (state is EpisodeListLoaded) {
          if (state.episodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_music,
                      size: 64, color: AppColors.textGhost),
                  const SizedBox(height: 16),
                  Text(
                    'No episodes yet',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: AppColors.textDim),
                  ),
                ],
              ),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200 &&
                  state.hasMore) {
                context.read<EpisodeListBloc>().add(FetchEpisodesEvent(
                      podcastId: podcastId,
                      page: state.currentPage + 1,
                    ));
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                context
                    .read<EpisodeListBloc>()
                    .add(FetchEpisodesEvent(podcastId: podcastId));
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

                  return _EpisodeCard(episode: state.episodes[index]);
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

class _EpisodeCard extends StatelessWidget {
  final PodcastEpisodeModel episode;

  const _EpisodeCard({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.headphones, color: AppColors.tmzRed, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    episode.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (episode.source != null) ...[
                        Text(
                          episode.source!,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: AppColors.tmzRed,
                                    fontSize: 10,
                                  ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (episode.publishedAt != null)
                        Text(
                          _formatDate(episode.publishedAt!),
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: AppColors.textDim,
                                    fontSize: 10,
                                  ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (episode.sourceUrl != null)
              const Icon(Icons.open_in_new,
                  size: 16, color: AppColors.textGhost),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
