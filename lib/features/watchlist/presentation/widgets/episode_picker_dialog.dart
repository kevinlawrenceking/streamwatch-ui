import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../podcasts/data/data_sources/podcast_data_source.dart';
import '../../../podcasts/data/models/podcast_episode.dart';

/// Plan-Lock #4 (B-new): paginated scroll-and-pick dialog for selecting
/// an episode_id during the watchlist `change-status` -> `matched` flow.
///
/// Resolves [IPodcastDataSource] from GetIt and calls
/// `listEpisodes(podcastId, page: 1, pageSize: 50)` on init. Returns
/// the picked `episodeId` via `Navigator.pop(context, id)`, or null on
/// cancel. Does NOT touch frozen LSW-004 EpisodeListView.
///
/// Note: current backend exposes listEpisodes only by podcastId, not a
/// global listing. The caller passes a podcastId; for matched-by-anyone
/// flows the user enters the podcastId first or uses the create-edit
/// raw episode_id field as fallback.
class EpisodePickerDialog extends StatefulWidget {
  final String podcastId;

  const EpisodePickerDialog({super.key, required this.podcastId});

  @override
  State<EpisodePickerDialog> createState() => _EpisodePickerDialogState();
}

class _EpisodePickerDialogState extends State<EpisodePickerDialog> {
  bool _loading = true;
  String? _error;
  List<PodcastEpisodeModel> _episodes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ds = GetIt.instance<IPodcastDataSource>();
    final result =
        await ds.listEpisodes(widget.podcastId, page: 1, pageSize: 50);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (page) => setState(() {
        _loading = false;
        _episodes = page.items;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick matched episode'),
      content: SizedBox(
        width: 480,
        height: 420,
        child: _buildBody(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    if (_episodes.isEmpty) {
      return const Center(child: Text('No episodes found.'));
    }
    return ListView.builder(
      itemCount: _episodes.length,
      itemBuilder: (context, index) {
        final ep = _episodes[index];
        return ListTile(
          title: Text(ep.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            ep.publishedAt != null
                ? 'published ${_formatDate(ep.publishedAt!)}'
                : 'created ${_formatDate(ep.createdAt)}',
          ),
          onTap: () => Navigator.of(context).pop(ep.id),
        );
      },
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")}';
}
