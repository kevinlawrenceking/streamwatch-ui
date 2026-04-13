import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../themes/app_theme.dart';
import '../bloc/podcast_list_bloc.dart';
import '../widgets/create_podcast_dialog.dart';
import '../widgets/podcast_card.dart';

/// Podcast list view - shows all podcasts with pagination.
class PodcastListView extends StatelessWidget {
  const PodcastListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PodcastListBloc>(
      create: (_) =>
          GetIt.instance<PodcastListBloc>()..add(const FetchPodcastsEvent()),
      child: const _PodcastListBody(),
    );
  }
}

class _PodcastListBody extends StatelessWidget {
  const _PodcastListBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PodcastListBloc, PodcastListState>(
      listener: (context, state) {
        if (state is PodcastListLoaded) {
          if (state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionError!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<PodcastListBloc>().add(FetchPodcastsEvent(
                  includeInactive: state.includeInactive,
                ));
          }
          if (state.actionSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionSuccess!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Stack(
        children: [
          BlocBuilder<PodcastListBloc, PodcastListState>(
            builder: (context, state) {
              if (state is PodcastListLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is PodcastListError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${state.message}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: AppColors.textDim,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<PodcastListBloc>()
                              .add(const FetchPodcastsEvent());
                        },
                        child: const Text('RETRY'),
                      ),
                    ],
                  ),
                );
              }

              if (state is PodcastListLoaded) {
                if (state.podcasts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.podcasts,
                            size: 64, color: AppColors.textGhost),
                        const SizedBox(height: 16),
                        Text(
                          'No podcasts yet',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(color: AppColors.textDim),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to create one',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: AppColors.textGhost),
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
                      context.read<PodcastListBloc>().add(FetchPodcastsEvent(
                            page: state.currentPage + 1,
                            includeInactive: state.includeInactive,
                          ));
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<PodcastListBloc>().add(FetchPodcastsEvent(
                            includeInactive: state.includeInactive,
                          ));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          state.podcasts.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.podcasts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final podcast = state.podcasts[index];
                        return PodcastCard(
                          podcast: podcast,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/podcasts/detail',
                              arguments: podcast.id,
                            );
                          },
                          onDeactivate: () {
                            context.read<PodcastListBloc>().add(
                                  DeactivatePodcastEvent(podcast.id),
                                );
                          },
                          onActivate: () {
                            context.read<PodcastListBloc>().add(
                                  ActivatePodcastEvent(podcast.id),
                                );
                          },
                        );
                      },
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              backgroundColor: AppColors.tmzRed,
              foregroundColor: AppColors.textMax,
              tooltip: 'Create Podcast',
              onPressed: () => _showCreateDialog(context),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreatePodcastDialog(),
    );

    if (result != null && context.mounted) {
      context.read<PodcastListBloc>().add(CreatePodcastEvent(result));
    }
  }
}
