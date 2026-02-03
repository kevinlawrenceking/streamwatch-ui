import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tmz_ui/tmz_ui.dart' as tmz_ui;
import '../../../data/models/job_model.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../themes/app_theme.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

/// Home screen - the main landing page for StreamWatch.
/// Shows search/filter controls and a list of jobs.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => GetIt.instance<HomeBloc>()..add(const LoadJobsEvent()),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<HomeBloc>().add(SearchQueryChangedEvent(query));
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    context.read<HomeBloc>().add(StatusFilterChangedEvent(status));
  }

  void _navigateToIngest() {
    Navigator.pushNamed(context, '/ingest');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state is HomeLoaded) {
          // Show error snackbar
          if (state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionError!),
                backgroundColor: TmzColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          // Show success snackbar
          if (state.actionSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionSuccess!),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: TmzAppBar(
          app: WatchAppIdentity.streamWatch,
          actions: [
            // View mode toggle button
            BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (prev, curr) {
                final prevMode = prev is HomeLoaded ? prev.viewMode : ViewMode.list;
                final currMode = curr is HomeLoaded ? curr.viewMode : ViewMode.list;
                return prevMode != currMode;
              },
              builder: (context, state) {
                final isGridView = state is HomeLoaded && state.viewMode == ViewMode.grid;
                return IconButton(
                  icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
                  tooltip: isGridView ? 'List view' : 'Grid view',
                  onPressed: () {
                    context.read<HomeBloc>().add(const ToggleViewModeEvent());
                  },
                );
              },
            ),
            // Scheduler button (coming soon)
            IconButton(
              icon: const Icon(Icons.schedule),
              tooltip: 'Scheduler (Coming Soon)',
              onPressed: () {
                Navigator.pushNamed(context, '/scheduler');
              },
            ),
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                context.read<HomeBloc>().add(const RefreshJobsEvent());
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: Column(
          children: [
            // Search and Filter Bar
            _SearchFilterBar(
              searchController: _searchController,
              selectedStatus: _selectedStatus,
              onSearchChanged: _onSearchChanged,
              onStatusFilterChanged: _onStatusFilterChanged,
              onIngestTap: _navigateToIngest,
            ),
            // Jobs List
            Expanded(
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is HomeError) {
                    return _ErrorView(
                      message: state.failure.message,
                      onRetry: () {
                        context.read<HomeBloc>().add(const LoadJobsEvent());
                      },
                    );
                  }

                  if (state is HomeLoaded || state is HomeRefreshing) {
                    final jobs = state is HomeLoaded
                        ? state.filteredJobs
                        : (state as HomeRefreshing).filteredJobs;
                    final isRefreshing = state is HomeRefreshing;
                    final inFlightActions = state is HomeLoaded
                        ? state.inFlightActions
                        : const <String, JobActionType>{};
                    final viewMode = state is HomeLoaded
                        ? state.viewMode
                        : (state as HomeRefreshing).viewMode;

                    if (jobs.isEmpty) {
                      return _EmptyView(
                        hasFilters: _searchController.text.isNotEmpty ||
                            _selectedStatus != null,
                        onIngestTap: _navigateToIngest,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<HomeBloc>().add(const RefreshJobsEvent());
                        await context.read<HomeBloc>().stream.firstWhere(
                              (s) => s is HomeLoaded || s is HomeError,
                            );
                      },
                      child: Stack(
                        children: [
                          viewMode == ViewMode.grid
                              ? _buildGridView(jobs, inFlightActions)
                              : _buildListView(jobs, inFlightActions),
                          if (isRefreshing)
                            const Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
        // Floating Ingest Button
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToIngest,
          icon: const Icon(Icons.add),
          label: const Text('INGEST'),
          backgroundColor: TmzColors.tmzRed,
          foregroundColor: TmzColors.white,
        ),
      ),
    );
  }

  Widget _buildListView(
    List<JobModel> jobs,
    Map<String, JobActionType> inFlightActions,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _JobCard(
          job: job,
          isActionInFlight: inFlightActions.containsKey(job.jobId),
          inFlightAction: inFlightActions[job.jobId],
        );
      },
    );
  }

  Widget _buildGridView(
    List<JobModel> jobs,
    Map<String, JobActionType> inFlightActions,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: more columns on wider screens
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200 ? 4 : (width > 800 ? 3 : 2);

        return GridView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 80),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return _JobGridCard(
              job: job,
              isActionInFlight: inFlightActions.containsKey(job.jobId),
              inFlightAction: inFlightActions[job.jobId],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: TmzColors.tmzRed),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.videocam, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                const Text(
                  'StreamWatch',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Video Transcription',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Ingest'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/ingest');
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Scheduler'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/scheduler');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Settings screen
            },
          ),
        ],
      ),
    );
  }
}

/// Search and filter bar component.
class _SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedStatus;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusFilterChanged;
  final VoidCallback onIngestTap;

  const _SearchFilterBar({
    required this.searchController,
    required this.selectedStatus,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.onIngestTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TmzColors.gray90,
        border: Border(
          bottom: BorderSide(color: TmzColors.gray70, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 3,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by title, description, URL...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Status filter dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                hintText: 'All Status',
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(
                  value: null,
                  child: Text('All Status'),
                ),
                DropdownMenuItem(
                  value: 'queued',
                  child: Text('Queued'),
                ),
                DropdownMenuItem(
                  value: 'processing',
                  child: Text('Processing'),
                ),
                DropdownMenuItem(
                  value: 'completed',
                  child: Text('Completed'),
                ),
                DropdownMenuItem(
                  value: 'failed',
                  child: Text('Failed'),
                ),
              ],
              onChanged: onStatusFilterChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Job card for the list.
class _JobCard extends StatelessWidget {
  final JobModel job;
  final bool isActionInFlight;
  final JobActionType? inFlightAction;

  const _JobCard({
    required this.job,
    this.isActionInFlight = false,
    this.inFlightAction,
  });

  @override
  Widget build(BuildContext context) {
    final dataSource = GetIt.instance<IJobDataSource>();
    final thumbnailUrl = dataSource.getJobThumbnailUrl(job.jobId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/job', arguments: job.jobId);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              child: SizedBox(
                width: 140,
                height: 100,
                child: Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: TmzColors.gray80,
                      child: Icon(
                        Icons.videocam,
                        size: 40,
                        color: TmzColors.gray50,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: TmzColors.gray80,
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
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title, status, and flags
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Flag indicator
                        if (job.isFlagged) ...[
                          const Icon(
                            Icons.flag,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            job.title ?? 'Job ${job.jobId.substring(0, 8)}...',
                            style: TmzTextStyles.bodyBold,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        tmz_ui.TmzStatusBadge(status: job.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Source info
                    Row(
                      children: [
                        Icon(
                          job.source == 'url' ? Icons.link : Icons.upload_file,
                          size: 14,
                          color: TmzColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.source == 'url'
                                ? job.sourceUrl ?? 'URL'
                                : job.filename ?? 'Uploaded file',
                            style: TmzTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Date, progress, and action buttons
                    Row(
                      children: [
                        Text(
                          _formatDateTime(job.createdAt),
                          style: TmzTextStyles.caption,
                        ),
                        if (job.isProcessing) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${job.progressPct}%',
                            style: TmzTextStyles.caption.copyWith(
                              color: TmzColors.tmzRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Action buttons
                        _JobActionButtons(
                          job: job,
                          isActionInFlight: isActionInFlight,
                          inFlightAction: inFlightAction,
                        ),
                      ],
                    ),
                    // Progress bar for processing jobs
                    if (job.isProcessing) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: job.progressPct / 100,
                        minHeight: 3,
                        backgroundColor: TmzColors.gray70,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Job card for grid view - vertical layout with image, title, status.
class _JobGridCard extends StatelessWidget {
  final JobModel job;
  final bool isActionInFlight;
  final JobActionType? inFlightAction;

  const _JobGridCard({
    required this.job,
    this.isActionInFlight = false,
    this.inFlightAction,
  });

  @override
  Widget build(BuildContext context) {
    final dataSource = GetIt.instance<IJobDataSource>();
    final thumbnailUrl = dataSource.getJobThumbnailUrl(job.jobId);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/job', arguments: job.jobId);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail - takes up most of the card
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: TmzColors.gray80,
                        child: Icon(
                          Icons.videocam,
                          size: 48,
                          color: TmzColors.gray50,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: TmzColors.gray80,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                  // Status badge overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: tmz_ui.TmzStatusBadge(status: job.status),
                  ),
                  // Flag indicator overlay
                  if (job.isFlagged)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.flag,
                          size: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  // Progress overlay for processing jobs
                  if (job.isProcessing)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            color: Colors.black54,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${job.progressPct}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          LinearProgressIndicator(
                            value: job.progressPct / 100,
                            minHeight: 3,
                            backgroundColor: Colors.black38,
                            valueColor: AlwaysStoppedAnimation<Color>(TmzColors.tmzRed),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Content area
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      job.title ?? 'Job ${job.jobId.substring(0, 8)}...',
                      style: TmzTextStyles.bodyBold.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Type badge and date row
                    Row(
                      children: [
                        if (job.typeCode != null) ...[
                          _TypeBadge(typeCode: job.typeCode!),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            _formatDateTime(job.createdAt),
                            style: TmzTextStyles.caption.copyWith(fontSize: 10),
                          ),
                        ),
                        if (job.source == 'url' && job.sourceUrl != null)
                          _SourceLinkButton(url: job.sourceUrl!),
                      ],
                    ),
                    // Summary preview (if available)
                    if (_getSummary(job) != null) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          _getSummary(job)!,
                          style: TmzTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: TmzColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String? _getSummary(JobModel job) {
    final raw = job.finalSummary ?? job.summaryText;
    if (raw == null) return null;

    // Try to parse as JSON and extract executive_summary
    if (raw.trimLeft().startsWith('{')) {
      try {
        final parsed = jsonDecode(raw) as Map<String, dynamic>;
        final execSummary = parsed['executive_summary'] as String?;
        if (execSummary != null && execSummary.isNotEmpty) {
          return execSummary;
        }
      } catch (_) {
        // Not valid JSON, fall through to return raw
      }
    }
    return raw;
  }

  String _truncateSummary(String summary, int maxLength) {
    if (summary.length <= maxLength) return summary;
    return '${summary.substring(0, maxLength).trim()}...';
  }
}

/// Type badge for content classification.
class _TypeBadge extends StatelessWidget {
  final String typeCode;

  const _TypeBadge({required this.typeCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getTypeColor(typeCode).withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getTypeColor(typeCode), width: 1),
      ),
      child: Text(
        typeCode.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _getTypeColor(typeCode),
        ),
      ),
    );
  }

  Color _getTypeColor(String code) {
    switch (code.toLowerCase()) {
      case 'interview':
        return Colors.blue;
      case 'news':
        return Colors.orange;
      case 'documentary':
        return Colors.purple;
      case 'podcast':
        return Colors.green;
      case 'press':
        return Colors.teal;
      case 'sports':
        return Colors.red;
      case 'entertainment':
        return Colors.pink;
      default:
        return TmzColors.gray50;
    }
  }
}

/// Compact link button that opens the source URL.
class _SourceLinkButton extends StatelessWidget {
  final String url;

  const _SourceLinkButton({required this.url});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: url,
      child: InkWell(
        onTap: () async {
          // Copy URL to clipboard and show feedback
          // ignore: depend_on_referenced_packages
          await Future.delayed(Duration.zero); // Allow the tap to complete
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.link,
            size: 16,
            color: TmzColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Action buttons for job controls (pause/resume, flag, delete).
class _JobActionButtons extends StatelessWidget {
  final JobModel job;
  final bool isActionInFlight;
  final JobActionType? inFlightAction;

  const _JobActionButtons({
    required this.job,
    required this.isActionInFlight,
    this.inFlightAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause/Resume button (only for pausable/resumable jobs)
        if (job.canPause || job.canResume)
          _ActionButton(
            icon: job.isPaused || job.pauseRequested ? Icons.play_arrow : Icons.pause,
            tooltip: job.isPaused || job.pauseRequested ? 'Resume' : 'Pause',
            isLoading: isActionInFlight &&
                (inFlightAction == JobActionType.pause ||
                    inFlightAction == JobActionType.resume),
            isDisabled: isActionInFlight,
            onPressed: () {
              if (job.isPaused || job.pauseRequested) {
                context.read<HomeBloc>().add(ResumeJobEvent(job.jobId));
              } else {
                context.read<HomeBloc>().add(PauseJobEvent(job.jobId));
              }
            },
          ),
        // Flag button
        _ActionButton(
          icon: job.isFlagged ? Icons.flag : Icons.flag_outlined,
          tooltip: job.isFlagged ? 'Unflag' : 'Flag',
          iconColor: job.isFlagged ? Colors.orange : null,
          isLoading: isActionInFlight && inFlightAction == JobActionType.flag,
          isDisabled: isActionInFlight,
          onPressed: () => _showFlagDialog(context),
        ),
        // Delete button
        _ActionButton(
          icon: Icons.delete_outline,
          tooltip: job.canDelete ? 'Delete' : 'Cannot delete (processing or flagged)',
          iconColor: job.canDelete ? TmzColors.error : TmzColors.gray50,
          isLoading: isActionInFlight && inFlightAction == JobActionType.delete,
          isDisabled: isActionInFlight || !job.canDelete,
          onPressed: job.canDelete ? () => _showDeleteDialog(context) : null,
        ),
      ],
    );
  }

  void _showFlagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(job.isFlagged ? 'Unflag job?' : 'Flag job?'),
        content: Text(
          job.isFlagged
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
              context.read<HomeBloc>().add(ToggleFlagJobEvent(
                    jobId: job.jobId,
                    isFlagged: !job.isFlagged,
                  ));
            },
            child: Text(job.isFlagged ? 'Unflag' : 'Flag'),
          ),
        ],
      ),
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
            style: TextButton.styleFrom(foregroundColor: TmzColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<HomeBloc>().add(DeleteJobEvent(job.jobId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Single action button with loading state.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? iconColor;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    this.iconColor,
    this.isLoading = false,
    this.isDisabled = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: Icon(icon, size: 18),
      color: iconColor,
      tooltip: tooltip,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: isDisabled ? null : onPressed,
    );
  }
}

/// Empty state view.
class _EmptyView extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onIngestTap;

  const _EmptyView({
    required this.hasFilters,
    required this.onIngestTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off : Icons.videocam_off,
            size: 64,
            color: TmzColors.gray50,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No jobs match your search' : 'No jobs yet',
            style: TmzTextStyles.body.copyWith(color: TmzColors.textSecondary),
          ),
          const SizedBox(height: 24),
          if (!hasFilters)
            ElevatedButton.icon(
              onPressed: onIngestTap,
              icon: const Icon(Icons.add),
              label: const Text('INGEST VIDEO'),
            ),
        ],
      ),
    );
  }
}

/// Error view.
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
          const Icon(Icons.error_outline, size: 64, color: TmzColors.error),
          const SizedBox(height: 16),
          Text(
            'Error: $message',
            style: TmzTextStyles.body.copyWith(color: TmzColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}
