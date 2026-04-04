import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/chunk_model.dart';
import '../../../data/models/celebrity_model.dart';
import '../../../data/models/collection_model.dart';
import '../../../data/sources/auth_data_source.dart';
import '../../../data/sources/collection_data_source.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../models/cast.dart';
import '../../../themes/app_theme.dart';
import '../../../utils/config.dart';
import '../../video_player/views/video_player_view.dart';
import '../bloc/job_detail_bloc.dart';

/// Job detail page using BLoC pattern with HTTP polling for updates.
///
/// Uses polling instead of WebSocket because WebSocket is not supported
/// in Lambda/API Gateway serverless deployments.
class JobDetailView extends StatelessWidget {
  final String jobId;

  const JobDetailView({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JobDetailBloc>(
      create: (_) => GetIt.instance<JobDetailBloc>(param1: jobId)
        ..add(const LoadJobDetailEvent()),
      // Polling auto-starts after successful load in BLoC
      child: const _JobDetailBody(),
    );
  }
}

class _JobDetailBody extends StatelessWidget {
  const _JobDetailBody();

  void _showLogViewer(BuildContext context, String jobId) {
    showDialog(
      context: context,
      builder: (context) => _LogViewerDialog(jobId: jobId),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete job?'),
        content: const Text('This removes the job and its results.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.tmzRed),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<JobDetailBloc>().add(const DeleteJobDetailEvent());
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFlagDialog(BuildContext context, bool currentlyFlagged) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(currentlyFlagged ? 'Unflag job?' : 'Flag job?'),
        content: Text(
          currentlyFlagged
              ? 'This will remove the flag from this job.'
              : 'This marks the job for review and prevents deletion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<JobDetailBloc>().add(ToggleFlagJobDetailEvent(
                    isFlagged: !currentlyFlagged,
                  ));
            },
            child: Text(currentlyFlagged ? 'Unflag' : 'Flag'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JobDetailBloc, JobDetailState>(
      listener: (context, state) {
        if (state is JobDetailLoaded) {
          // Handle job deletion - navigate back
          if (state.jobDeleted) {
            Navigator.of(context).pop();
            return;
          }
          // Show error snackbar
          if (state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionError!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          // Show success snackbar
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
      child: BlocBuilder<JobDetailBloc, JobDetailState>(
        builder: (context, state) {
          if (state is JobDetailLoading) {
            return Scaffold(
              appBar: TmzAppBar(
                app: WatchAppIdentity.streamWatch,
                showBackButton: true,
                showHomeButton: true,
                customTitle: 'Loading...',
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is JobDetailError) {
            return Scaffold(
              appBar: TmzAppBar(
                app: WatchAppIdentity.streamWatch,
                showBackButton: true,
                showHomeButton: true,
                customTitle: 'Error',
              ),
              body: _ErrorView(
                message: state.failure.message,
                onRetry: () {
                  context.read<JobDetailBloc>().add(const LoadJobDetailEvent());
                },
              ),
            );
          }

          if (state is JobDetailLoaded) {
            final job = state.job;
            final isActionInFlight = state.inFlightAction != null;

            return Scaffold(
              appBar: TmzAppBar(
                app: WatchAppIdentity.streamWatch,
                showBackButton: true,
                showHomeButton: true,
                customTitle: job.title ?? 'Video ${job.jobId}',
                actions: [
                  // Pause/Resume button
                  if (job.canPause || job.canResume)
                    _buildActionButton(
                      context: context,
                      icon: job.isPaused || job.pauseRequested ? Icons.play_arrow : Icons.pause,
                      tooltip: job.isPaused || job.pauseRequested ? 'Resume' : 'Pause',
                      isLoading: isActionInFlight &&
                          (state.inFlightAction == JobDetailActionType.pause ||
                              state.inFlightAction == JobDetailActionType.resume),
                      isDisabled: isActionInFlight,
                      onPressed: () {
                        if (job.isPaused || job.pauseRequested) {
                          context.read<JobDetailBloc>().add(const ResumeJobDetailEvent());
                        } else {
                          context.read<JobDetailBloc>().add(const PauseJobDetailEvent());
                        }
                      },
                    ),
                  // Flag button
                  _buildActionButton(
                    context: context,
                    icon: job.isFlagged ? Icons.flag : Icons.flag_outlined,
                    tooltip: job.isFlagged ? 'Unflag' : 'Flag',
                    iconColor: job.isFlagged ? AppColors.warning : null,
                    isLoading: isActionInFlight && state.inFlightAction == JobDetailActionType.flag,
                    isDisabled: isActionInFlight,
                    onPressed: () => _showFlagDialog(context, job.isFlagged),
                  ),
                  // Delete button
                  _buildActionButton(
                    context: context,
                    icon: Icons.delete_outline,
                    tooltip: job.canDelete ? 'Delete' : 'Cannot delete (processing or flagged)',
                    iconColor: job.canDelete ? AppColors.tmzRed : AppColors.textGhost,
                    isLoading: isActionInFlight && state.inFlightAction == JobDetailActionType.delete,
                    isDisabled: isActionInFlight || !job.canDelete,
                    onPressed: job.canDelete ? () => _showDeleteDialog(context) : null,
                  ),
                  // View Log button
                  IconButton(
                    icon: const Icon(Icons.terminal),
                    tooltip: 'View Worker Log',
                    onPressed: () => _showLogViewer(context, job.jobId),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Poll error banner (non-blocking warning)
                    if (state.pollError != null)
                      _PollErrorBanner(message: state.pollError!),
                    // Flag indicator banner
                    if (job.isFlagged)
                      _FlagBanner(flagNote: job.flagNote),
                    _JobInfoCard(job: job, celebrities: state.celebrities),
                    const SizedBox(height: 16),
                    _CollectionsSection(jobId: job.jobId),
                    const SizedBox(height: 16),
                    // Only show progress bar when NOT completed
                    if (!job.isCompleted) ...[
                      _ProgressCard(job: job, isPolling: state.isPolling),
                      const SizedBox(height: 16),
                    ],
                    if (job.isCompleted) ...[
                      _FinalSummarySection(job: job),
                      const SizedBox(height: 16),
                      _PeopleSection(jobId: job.jobId),
                      const SizedBox(height: 16),
                      _FullTranscriptSection(job: job, chunks: state.chunks),
                      const SizedBox(height: 16),
                    ],
                    _ChunksSection(chunks: state.chunks, jobId: job.jobId),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    Color? iconColor,
    bool isLoading = false,
    bool isDisabled = false,
    VoidCallback? onPressed,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMax),
        ),
      );
    }

    return IconButton(
      icon: Icon(icon),
      color: iconColor,
      tooltip: tooltip,
      onPressed: isDisabled ? null : onPressed,
    );
  }
}

/// Banner showing the job is flagged
class _FlagBanner extends StatelessWidget {
  final String? flagNote;

  const _FlagBanner({this.flagNote});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              flagNote ?? 'This job has been flagged for review',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobInfoCard extends StatefulWidget {
  final JobModel job;
  final List<CelebrityModel> celebrities;

  const _JobInfoCard({required this.job, this.celebrities = const []});

  @override
  State<_JobInfoCard> createState() => _JobInfoCardState();
}

class _JobInfoCardState extends State<_JobInfoCard> {
  bool _showVideoPlayer = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  String? _videoError;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  bool _hasSourceUrl() {
    return widget.job.sourceUrl != null && widget.job.sourceUrl!.isNotEmpty;
  }

  Future<void> _openSourceUrl() async {
    final url = widget.job.sourceUrl;
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Find local video file in storage path
  String? _findLocalVideoPath() {
    final storagePath = widget.job.storagePath;
    if (storagePath == null || storagePath.isEmpty) return null;

    final jobId = widget.job.jobId;
    final extensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];

    // Try job ID based filename first (how files are saved after upload)
    for (final ext in extensions) {
      final path = '$storagePath/$jobId.$ext';
      if (File(path).existsSync()) return path;
      // Also try Windows path separator
      final winPath = '$storagePath\\$jobId.$ext';
      if (File(winPath).existsSync()) return winPath;
    }

    // Try original_video.mp4 (for URL downloads)
    final originalPath = '$storagePath/original_video.mp4';
    if (File(originalPath).existsSync()) return originalPath;
    final originalPathWin = '$storagePath\\original_video.mp4';
    if (File(originalPathWin).existsSync()) return originalPathWin;

    // Try original uploaded filename
    final filename = widget.job.filename;
    if (filename != null && filename.isNotEmpty) {
      final uploadedPath = '$storagePath/$filename';
      if (File(uploadedPath).existsSync()) return uploadedPath;
      final uploadedPathWin = '$storagePath\\$filename';
      if (File(uploadedPathWin).existsSync()) return uploadedPathWin;
    }

    return null;
  }

  bool _isS3Url(String? url) {
    if (url == null) return false;
    return url.contains('.s3.amazonaws.com/') || url.contains('.s3.us-east-1.amazonaws.com/');
  }

  bool _isExternalVideoUrl(String? url) {
    if (url == null) return false;
    // URLs that can't be played in-app (require their own players)
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com') ||
        url.contains('dailymotion.com') ||
        url.contains('twitch.tv');
  }

  Future<String?> _getPresignedVideoUrl() async {
    final dataSource = GetIt.instance<IJobDataSource>();
    final streamUrl = dataSource.getVideoStreamUrl(widget.job.jobId);

    try {
      // Make request without following redirects to get the presigned URL
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(streamUrl));
      request.followRedirects = false;

      final response = await client.send(request);
      client.close();

      if (response.statusCode == 303 || response.statusCode == 302) {
        // Get the redirect location (presigned URL)
        return response.headers['location'];
      } else if (response.statusCode == 200) {
        // Direct stream, use the original URL
        return streamUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting presigned URL: $e');
      return null;
    }
  }

  bool _isWebPlayableFormat(String? filename) {
    if (filename == null) return true; // Assume playable if unknown
    final lower = filename.toLowerCase();
    // Web-playable formats (h.264/h.265 in mp4/webm containers)
    if (lower.endsWith('.mp4') || lower.endsWith('.webm') || lower.endsWith('.m4v')) {
      return true;
    }
    // Formats that often don't play in browser (ProRes, etc)
    if (lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv') || lower.endsWith('.wmv')) {
      return false;
    }
    return true; // Default to trying in-app
  }

  void _playVideo() async {
    // For external video platforms (YouTube, etc), open in browser
    if (_hasSourceUrl() && _isExternalVideoUrl(widget.job.sourceUrl)) {
      _openSourceUrl();
      return;
    }

    // Simple approach: open streaming URL directly in browser
    // Browser follows the 303 redirect to the presigned S3 URL
    final dataSource = GetIt.instance<IJobDataSource>();
    final streamUrl = dataSource.getVideoStreamUrl(widget.job.jobId);
    final uri = Uri.parse(streamUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Future: in-app Chewie player (disabled for now due to CORS/redirect issues)
  void _playVideoInAppFuture() async {
    if (_hasSourceUrl() && _isExternalVideoUrl(widget.job.sourceUrl)) {
      _openSourceUrl();
      return;
    }

    final presignedUrl = await _getPresignedVideoUrl();

    if (presignedUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load video. Try again later.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    if (!_isWebPlayableFormat(widget.job.filename)) {
      final uri = Uri.parse(presignedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoPlayerView(
            videoUrl: presignedUrl,
            title: widget.job.title ?? widget.job.filename ?? 'Video',
          ),
        ),
      );
    }
  }

  void _initializeController() {
    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _videoError = error.toString();
        });
      }
    });
  }

  void _closeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _showVideoPlayer = false;
      _isVideoInitialized = false;
      _videoError = null;
    });
  }

  Future<void> _launchDownload(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open download'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = GetIt.instance<IJobDataSource>();
    final thumbnailUrl = dataSource.getJobThumbnailUrl(widget.job.jobId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Video Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                // Download menu (only show when completed)
                if (widget.job.isCompleted)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.download),
                    tooltip: 'Download Options',
                    onSelected: (value) {
                      switch (value) {
                        case 'transcript_cleaned':
                          _launchDownload(context, dataSource.getTranscriptDownloadUrl(widget.job.jobId, cleaned: true));
                          break;
                        case 'transcript_raw':
                          _launchDownload(context, dataSource.getTranscriptDownloadUrl(widget.job.jobId, cleaned: false));
                          break;
                        case 'srt':
                          _launchDownload(context, dataSource.getSrtDownloadUrl(widget.job.jobId));
                          break;
                        case 'summary':
                          _launchDownload(context, dataSource.getSummaryDownloadUrl(widget.job.jobId));
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'transcript_cleaned',
                        child: ListTile(
                          leading: Icon(Icons.description, color: AppColors.tmzRed),
                          title: Text('Transcript (Cleaned)'),
                          subtitle: Text('With speaker labels'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'transcript_raw',
                        child: ListTile(
                          leading: Icon(Icons.description_outlined),
                          title: Text('Transcript (Raw)'),
                          subtitle: Text('Original transcription'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'srt',
                        child: ListTile(
                          leading: Icon(Icons.subtitles, color: AppColors.tmzRed),
                          title: Text('Subtitles (SRT)'),
                          subtitle: Text('For video players'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'summary',
                        child: ListTile(
                          leading: Icon(Icons.summarize, color: AppColors.tmzRed),
                          title: Text('Summary'),
                          subtitle: Text('Overview + segments'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Video thumbnail with play button - larger size
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.28,
                  child: _showVideoPlayer
                      ? _buildVideoPlayer()
                      : _buildThumbnailWithPlayButton(thumbnailUrl),
                ),
                const SizedBox(width: 24),
                // Right side: Job info (remaining width)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title first
                      if (widget.job.title != null)
                        _InfoRow(label: 'Title', value: widget.job.title!),
                      // Celebrities (AI-identified)
                      if (widget.celebrities.isNotEmpty)
                        _InfoRow(
                          label: 'Celebrities',
                          value: widget.celebrities.map((c) => c.name).join(', '),
                        ),
                      // Combined Source row - shows URL link or file path
                      _SourceRow(job: widget.job),
                      if (widget.job.sourceProvider != null)
                        _ProviderRow(label: 'Platform', provider: widget.job.sourceProvider!),
                      if (widget.job.typeCode != null)
                        _TypeRow(typeCode: widget.job.typeCode!, confidence: widget.job.typeConfidence),
                      if (widget.job.description != null)
                        _InfoRow(label: 'Description', value: widget.job.description!),
                      _InfoRow(label: 'Created', value: _formatDateTime(widget.job.createdAt)),
                      if (widget.job.completedAt != null)
                        _InfoRow(label: 'Completed', value: _formatDateTime(widget.job.completedAt!)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailWithPlayButton(String thumbnailUrl) {
    final hasUrl = _hasSourceUrl();

    return GestureDetector(
      onTap: _playVideo,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceOverlay,
                    child: const Icon(
                      Icons.videocam,
                      size: 64,
                      color: AppColors.textGhost,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
            // Action button overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                color: AppColors.bg.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasUrl ? Icons.open_in_new : Icons.download,
                      size: 72,
                      color: AppColors.textMax,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.bg.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        hasUrl ? 'Watch Original' : 'Download Video',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textMax),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoError != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: AppColors.error, size: 40),
              const SizedBox(height: 8),
              Text(
                'Video unavailable',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppColors.textGhost),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _closeVideo,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isVideoInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.zero,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: VideoPlayer(_videoController!),
          ),
        ),
        const SizedBox(height: 8),
        _InlineVideoControls(
          controller: _videoController!,
          onClose: _closeVideo,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Compact inline video controls
class _InlineVideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onClose;

  const _InlineVideoControls({
    required this.controller,
    required this.onClose,
  });

  @override
  State<_InlineVideoControls> createState() => _InlineVideoControlsState();
}

class _InlineVideoControlsState extends State<_InlineVideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;

    return Row(
      children: [
        IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            if (isPlaying) {
              widget.controller.pause();
            } else {
              widget.controller.play();
            }
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: position.inMilliseconds.toDouble(),
              min: 0,
              max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
              onChanged: (value) {
                widget.controller.seekTo(Duration(milliseconds: value.toInt()));
              },
              activeColor: AppColors.tmzRed,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDuration(position),
          style: Theme.of(context).textTheme.labelSmall!,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.close),
          iconSize: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Combined Source row - shows clickable URL link or file path
class _SourceRow extends StatelessWidget {
  final JobModel job;

  const _SourceRow({required this.job});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine what to show: URL or file path
    final hasUrl = job.sourceUrl != null && job.sourceUrl!.isNotEmpty;
    final hasFilePath = job.filePath != null && job.filePath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 120,
            child: Text(
              'Source:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: hasUrl
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _launchUrl(context, job.sourceUrl!),
                      child: Text(
                        job.sourceUrl!,
                        style: const TextStyle(
                          color: AppColors.tmzRed,
                        ),
                      ),
                    ),
                  )
                : Text(hasFilePath ? job.filePath! : job.source.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  final String label;
  final String provider;

  const _ProviderRow({required this.label, required this.provider});

  @override
  Widget build(BuildContext context) {
    final providerNames = {
      'youtube': 'YouTube',
      'twitter': 'Twitter/X',
      'tiktok': 'TikTok',
      'instagram': 'Instagram',
      'vimeo': 'Vimeo',
      'facebook': 'Facebook',
    };

    final displayName = providerNames[provider.toLowerCase()] ?? provider;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(displayName),
                avatar: const Icon(Icons.play_circle, size: 18),
                backgroundColor: AppColors.tmzRed.withValues(alpha: 0.1),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row widget for displaying type classification with a chip
class _TypeRow extends StatelessWidget {
  final String typeCode;
  final double? confidence;

  const _TypeRow({required this.typeCode, this.confidence});

  @override
  Widget build(BuildContext context) {
    // Format type code: replace underscores with spaces and title case
    final displayName = typeCode
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Type:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(displayName),
                avatar: const Icon(Icons.category, size: 18),
                backgroundColor: AppColors.info.withValues(alpha: 0.1),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Non-blocking error banner for poll failures
class _PollErrorBanner extends StatelessWidget {
  final String message;

  const _PollErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final JobModel job;
  final bool isPolling;

  const _ProgressCard({required this.job, required this.isPolling});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // Polling indicator
                    if (isPolling) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.tmzRed),
                        ),
                      ),
                    ],
                  ],
                ),
                _StatusChip(status: job.status),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: job.progressPct / 100,
              minHeight: 8,
              backgroundColor: Theme.of(context).colorScheme.outline,
              valueColor: AlwaysStoppedAnimation<Color>(
                job.isFailed ? AppColors.error : AppColors.tmzRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${job.progressPct}%',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${job.completedChunks} segments processed',
              style: TextStyle(color: AppColors.textGhost),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}

class _FinalSummarySection extends StatelessWidget {
  final JobModel job;

  const _FinalSummarySection({required this.job});

  @override
  Widget build(BuildContext context) {
    if (job.summaryText == null || job.summaryText!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Final Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            Text(
              job.summaryText!,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullTranscriptSection extends StatefulWidget {
  final JobModel job;
  final List<ChunkModel> chunks;

  const _FullTranscriptSection({required this.job, required this.chunks});

  @override
  State<_FullTranscriptSection> createState() => _FullTranscriptSectionState();
}

class _FullTranscriptSectionState extends State<_FullTranscriptSection> {
  bool _showBySegment = false;

  @override
  Widget build(BuildContext context) {
    // Priority: fullTranscript (merged with speaker labels) > transcriptFinal > chunk transcripts
    final hasFullTranscript = widget.job.fullTranscript != null && widget.job.fullTranscript!.isNotEmpty;
    final hasFinalTranscript = widget.job.transcriptFinal != null && widget.job.transcriptFinal!.isNotEmpty;
    final hasChunkTranscripts = widget.chunks.any((c) => c.transcript != null && c.transcript!.isNotEmpty);

    if (!hasFullTranscript && !hasFinalTranscript && !hasChunkTranscripts) {
      return const SizedBox.shrink();
    }

    // Use fullTranscript (speaker-resolved) first, then transcriptFinal, then fall back to chunks
    final displayTranscript = hasFullTranscript
        ? widget.job.fullTranscript!
        : (hasFinalTranscript ? widget.job.transcriptFinal! : null);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: AppColors.tmzRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Full Transcript',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                // Toggle button only if we have both full transcript AND chunk transcripts
                if (displayTranscript != null && hasChunkTranscripts)
                  TextButton.icon(
                    onPressed: () => setState(() => _showBySegment = !_showBySegment),
                    icon: Icon(_showBySegment ? Icons.article : Icons.segment, size: 18),
                    label: Text(_showBySegment ? 'Full View' : 'By Segment'),
                  ),
              ],
            ),
            const Divider(),
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              child: SingleChildScrollView(
                child: _showBySegment || displayTranscript == null
                    ? _buildSegmentView()
                    : _buildFullView(displayTranscript),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullView(String transcript) {
    return SelectableText(
      transcript,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(height: 1.6),
    );
  }

  Widget _buildSegmentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < widget.chunks.length; i++) ...[
          if (widget.chunks[i].transcript != null && widget.chunks[i].transcript!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.tmzRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Segment ${i + 1} (${widget.chunks[i].formattedTimeRange})',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.tmzRed,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              widget.chunks[i].transcript!,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ],
    );
  }
}

class _ChunksSection extends StatelessWidget {
  final List<ChunkModel> chunks;
  final String jobId;

  const _ChunksSection({required this.chunks, required this.jobId});

  @override
  Widget build(BuildContext context) {
    if (chunks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No segments available yet',
              style: TextStyle(color: AppColors.textGhost),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processed Segments (${chunks.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ...chunks.map((chunk) => _ChunkTile(chunk: chunk, jobId: jobId)),
          ],
        ),
      ),
    );
  }
}

class _ChunkTile extends StatelessWidget {
  final ChunkModel chunk;
  final String jobId;

  const _ChunkTile({required this.chunk, required this.jobId});

  @override
  Widget build(BuildContext context) {
    final dataSource = GetIt.instance<IJobDataSource>();
    final thumbnailUrl = dataSource.getChunkThumbnailUrl(jobId, chunk.chunkId);

    // orderNo is already 1-based from the API (segment_num in Python worker)
    final displaySegmentNum = chunk.orderNo;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail on the left - 10% bigger (176x99)
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: SizedBox(
              width: 176,
              height: 99,
              child: Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceOverlay,
                    child: Icon(
                      Icons.videocam,
                      size: 36,
                      color: AppColors.textGhost,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Segment $displaySegmentNum',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      chunk.formattedTimeRange,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textGhost),
                    ),
                  ],
                ),
                if (chunk.summary != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    chunk.summary!,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Error: $message'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Section showing which collections this job belongs to, with add/remove.
class _CollectionsSection extends StatefulWidget {
  final String jobId;

  const _CollectionsSection({required this.jobId});

  @override
  State<_CollectionsSection> createState() => _CollectionsSectionState();
}

class _CollectionsSectionState extends State<_CollectionsSection> {
  List<CollectionModel>? _memberships;
  List<CollectionModel>? _allCollections;
  bool _loading = true;
  String? _error;
  bool _expanded = true;
  String? _selectedCollectionId;
  bool _actionInFlight = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ds = GetIt.instance<ICollectionDataSource>();
      final results = await Future.wait([
        ds.getVideoCollections(widget.jobId),
        ds.getCollections(),
      ]);

      if (!mounted) return;

      final membershipsResult = results[0] as dynamic;
      final allResult = results[1] as dynamic;

      List<CollectionModel> memberships = [];
      List<CollectionModel> all = [];

      membershipsResult.fold(
        (f) => null,
        (list) => memberships = list as List<CollectionModel>,
      );
      allResult.fold(
        (f) => null,
        (list) => all = list as List<CollectionModel>,
      );

      setState(() {
        _memberships = memberships;
        _allCollections = all;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<CollectionModel> get _availableToAdd {
    if (_allCollections == null || _memberships == null) return [];
    final memberIds = _memberships!.map((m) => m.id).toSet();
    return _allCollections!
        .where((c) => c.isActive && !memberIds.contains(c.id))
        .toList();
  }

  Future<void> _addToCollection(String collectionId) async {
    setState(() => _actionInFlight = true);
    final ds = GetIt.instance<ICollectionDataSource>();
    final result =
        await ds.addVideosToCollection(collectionId, [widget.jobId]);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _actionInFlight = false);
      },
      (_) {
        setState(() {
          _selectedCollectionId = null;
          _actionInFlight = false;
        });
        _loadData();
      },
    );
  }

  Future<void> _removeFromCollection(CollectionModel collection) async {
    setState(() => _actionInFlight = true);
    final ds = GetIt.instance<ICollectionDataSource>();
    final result =
        await ds.removeVideoFromCollection(collection.id, widget.jobId);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(failure.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _actionInFlight = false);
      },
      (_) {
        setState(() => _actionInFlight = false);
        _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: AppColors.tmzRed),
                  const SizedBox(width: 8),
                  Text(
                    'Collections',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    Text(
                      '${_memberships?.length ?? 0}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textGhost),
                    ),
                    const SizedBox(width: 8),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              )
            else
              _buildContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Membership chips
          if (_memberships != null && _memberships!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _memberships!.map((c) => Chip(
                label: Text(c.name),
                avatar: Icon(
                  c.isPublic ? Icons.public : Icons.lock,
                  size: 16,
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: _actionInFlight
                    ? null
                    : () => _removeFromCollection(c),
              )).toList(),
            )
          else
            Text(
              'Not in any collections',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textGhost),
            ),
          const SizedBox(height: 12),
          // Add to collection row
          if (_availableToAdd.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCollectionId,
                    decoration: const InputDecoration(
                      labelText: 'Add to collection',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _availableToAdd
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    c.isPublic ? Icons.public : Icons.lock,
                                    size: 14,
                                    color: AppColors.textGhost,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(c.name),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: _actionInFlight
                        ? null
                        : (value) => setState(
                            () => _selectedCollectionId = value),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectedCollectionId != null && !_actionInFlight
                      ? () => _addToCollection(_selectedCollectionId!)
                      : null,
                  child: _actionInFlight
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.textMax),
                        )
                      : const Text('Add'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Section showing speakers/cast for a job
class _PeopleSection extends StatefulWidget {
  final String jobId;

  const _PeopleSection({required this.jobId});

  @override
  State<_PeopleSection> createState() => _PeopleSectionState();
}

class _PeopleSectionState extends State<_PeopleSection> {
  List<SpeakerMapping>? _speakers;
  List<Cast>? _cast;
  bool _loading = true;
  String? _error;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final baseUrl = Config.instance.apiBaseUrl;

      // Get auth token for authenticated requests
      final headers = <String, String>{};
      final auth = GetIt.instance<IAuthDataSource>();
      final tokenResult = await auth.getAuthToken();
      tokenResult.fold((_) {}, (token) {
        if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      });

      // Load both speakers and cast in parallel
      final results = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/v1/jobs/${widget.jobId}/speakers'), headers: headers),
        http.get(Uri.parse('$baseUrl/api/v1/jobs/${widget.jobId}/cast'), headers: headers),
      ]);

      final speakersResponse = results[0];
      final castResponse = results[1];

      List<SpeakerMapping> speakers = [];
      List<Cast> cast = [];

      if (speakersResponse.statusCode == 200) {
        final data = json.decode(speakersResponse.body);
        if (data is List) {
          speakers = data.map((s) => SpeakerMapping.fromJson(s)).toList();
        }
      }

      if (castResponse.statusCode == 200) {
        final data = json.decode(castResponse.body);
        if (data is List) {
          cast = data.map((c) => Cast.fromJson(c)).toList();
        }
      }

      if (mounted) {
        setState(() {
          _speakers = speakers;
          _cast = cast;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if no data
    if (!_loading && (_speakers?.isEmpty ?? true) && (_cast?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (clickable to expand/collapse)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.people, color: AppColors.tmzRed),
                  const SizedBox(width: 8),
                  Text(
                    'People',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  if (_loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    Text(
                      '${_speakers?.length ?? 0} speakers',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textGhost),
                    ),
                    const SizedBox(width: 8),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ],
              ),
            ),
          ),
          // Content
          if (_expanded) ...[
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              )
            else
              _buildContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_speakers == null || _speakers!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No speaker data available'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speaker mappings table
          Table(
            columnWidths: const {
              0: FixedColumnWidth(100),
              1: FlexColumnWidth(2),
              2: FixedColumnWidth(100),
              3: FlexColumnWidth(1),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header row
              TableRow(
                decoration: BoxDecoration(
                  color: AppColors.tmzRed.withValues(alpha: 0.1),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Speaker', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Confidence', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Source', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              // Data rows
              ..._speakers!.map((speaker) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      speaker.speakerLabel,
                      style: TmzTextStyles.mono,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      speaker.resolvedName ?? 'Unknown',
                      style: TextStyle(
                        fontWeight: speaker.resolvedName != null ? FontWeight.w500 : FontWeight.normal,
                        color: speaker.resolvedName != null ? null : AppColors.textGhost,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildConfidenceBadge(speaker.confidence),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildSourceBadge(speaker.resolutionSource),
                  ),
                ],
              )),
            ],
          ),
          // AI reasoning if available
          if (_speakers!.any((s) => s.aiReasoning != null && s.aiReasoning!.isNotEmpty)) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text('AI Reasoning', style: Theme.of(context).textTheme.labelLarge!),
              tilePadding: EdgeInsets.zero,
              children: [
                ..._speakers!
                    .where((s) => s.aiReasoning != null && s.aiReasoning!.isNotEmpty)
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${s.speakerLabel}: ',
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  s.aiReasoning!,
                                  style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.textGhost),
                                ),
                              ),
                            ],
                          ),
                        )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(double? confidence) {
    if (confidence == null) return const Text('-');

    final percent = (confidence * 100).toInt();
    Color color;
    if (percent >= 80) {
      color = AppColors.success;
    } else if (percent >= 50) {
      color = AppColors.warning;
    } else {
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$percent%',
        style: Theme.of(context).textTheme.bodySmall!.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    IconData icon;
    Color color;
    String label;

    switch (source) {
      case 'ai_guess':
        icon = Icons.auto_awesome;
        color = ContentTypeColors.documentary;
        label = 'AI';
        break;
      case 'manual':
        icon = Icons.person;
        color = AppColors.info;
        label = 'Manual';
        break;
      case 'facewatch':
        icon = Icons.face;
        color = ContentTypeColors.press;
        label = 'Face';
        break;
      case 'voiceprint':
        icon = Icons.mic;
        color = AppColors.info;
        label = 'Voice';
        break;
      default:
        icon = Icons.help_outline;
        color = AppColors.textGhost;
        label = source;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color)),
      ],
    );
  }
}

/// Dialog to view worker log for a job
class _LogViewerDialog extends StatefulWidget {
  final String jobId;

  const _LogViewerDialog({required this.jobId});

  @override
  State<_LogViewerDialog> createState() => _LogViewerDialogState();
}

class _LogViewerDialogState extends State<_LogViewerDialog> {
  String? _logContent;
  String? _error;
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLog() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final dataSource = GetIt.instance<IJobDataSource>();
    final result = await dataSource.getJobLog(widget.jobId);

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      (log) => setState(() {
        _logContent = log;
        _loading = false;
        // Scroll to bottom after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.terminal, color: AppColors.tmzRed),
                const SizedBox(width: 8),
                Text(
                  'Worker Log',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                // Refresh button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _loadLog,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: AppColors.error, size: 48),
                              const SizedBox(height: 16),
                              Text(_error!, style: const TextStyle(color: AppColors.error)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadLog,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppColors.bg.withValues(alpha: 0.87),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            child: SelectableText(
                              _logContent ?? 'No log content',
                              style: TmzTextStyles.mono.copyWith(
                                fontSize: 12,
                                color: AppColors.success,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
            ),
            // Footer with helpful info
            const SizedBox(height: 8),
            Text(
              'Look for "GEMINI SPEAKER RESOLUTION" section to verify speaker attribution',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textGhost,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
