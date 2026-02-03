import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:tmz_ui/tmz_ui.dart' as tmz_ui;
import 'package:url_launcher/url_launcher.dart';
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
        // Responsive grid: 2 columns on narrow, scales up on wider screens
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1400
            ? 5
            : width > 1100
                ? 4
                : width > 800
                    ? 3
                    : width > 500
                        ? 2
                        : 1;

        // Card height: thumbnail (16:9 aspect) + content area (~120px)
        // For a 200px wide card: thumbnail = 112.5px, content = 120px, total = 232.5px
        // childAspectRatio = width / height = 200 / 232.5 = 0.86
        // Adjusted for new compact design: ~0.75 to give more room
        return GridView.builder(
          padding: const EdgeInsets.all(16).copyWith(bottom: 80),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
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
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
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

/// Professional grid card for media library view.
/// Shows: thumbnail with status badge, title (2 lines), compact metadata rows, action icons.
/// No transcript/summary text - that belongs on the details screen.
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
      elevation: 2,
      color: TmzColors.gray90,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/job', arguments: job.jobId);
        },
        hoverColor: TmzColors.gray80.withValues(alpha: 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with fixed 16:9 aspect ratio
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail image
                  Image.network(
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
                      return _ThumbnailSkeleton();
                    },
                  ),
                  // Status badge - top right
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _CompactStatusBadge(status: job.status),
                  ),
                  // Flag indicator - top left
                  if (job.isFlagged)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(
                          Icons.flag,
                          size: 14,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            color: Colors.black.withValues(alpha: 0.7),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${job.progressPct}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          LinearProgressIndicator(
                            value: job.progressPct / 100,
                            minHeight: 2,
                            backgroundColor: Colors.black38,
                            valueColor: const AlwaysStoppedAnimation<Color>(TmzColors.tmzRed),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Content area - fixed height with consistent spacing
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title - 2 lines max
                    Text(
                      job.title ?? 'Video ${job.jobId.substring(0, 8)}',
                      style: TmzTextStyles.bodyBold.copyWith(
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Metadata row 1: Date + Type
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 11,
                          color: TmzColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(job.createdAt),
                          style: TmzTextStyles.caption.copyWith(fontSize: 10),
                        ),
                        if (job.typeCode != null) ...[
                          const SizedBox(width: 8),
                          _CompactTypeBadge(typeCode: job.typeCode!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Metadata row 2: Source
                    Row(
                      children: [
                        Icon(
                          job.source == 'url' ? Icons.link : Icons.upload_file,
                          size: 11,
                          color: TmzColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            job.source == 'url'
                                ? _extractDomain(job.sourceUrl)
                                : (job.filename ?? 'File'),
                            style: TmzTextStyles.caption.copyWith(fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Action row - bottom aligned
                    const Divider(height: 12, thickness: 1, color: TmzColors.gray70),
                    _GridCardActionRow(job: job),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _extractDomain(String? url) {
    if (url == null) return 'URL';
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return 'URL';
    }
  }
}

/// Compact status badge for grid thumbnails.
class _CompactStatusBadge extends StatelessWidget {
  final String status;

  const _CompactStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = getJobStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: TmzColors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Compact type badge for grid cards.
class _CompactTypeBadge extends StatelessWidget {
  final String typeCode;

  const _CompactTypeBadge({required this.typeCode});

  @override
  Widget build(BuildContext context) {
    final color = _getTypeColor(typeCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        typeCode.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getTypeColor(String code) {
    switch (code.toLowerCase()) {
      case 'tv_clip':
        return Colors.blue;
      case 'interview':
        return Colors.cyan;
      case 'news':
        return Colors.orange;
      case 'podcast':
        return Colors.green;
      case 'press':
        return Colors.teal;
      case 'documentary':
        return Colors.purple;
      case 'commercial':
        return Colors.amber;
      default:
        return TmzColors.gray50;
    }
  }
}

/// Action row for grid cards with download and link icons.
class _GridCardActionRow extends StatelessWidget {
  final JobModel job;

  const _GridCardActionRow({required this.job});

  Future<void> _downloadFile(BuildContext context, String url, String type) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not download $type'),
              backgroundColor: TmzColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _openExternalLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open link'),
              backgroundColor: TmzColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataSource = GetIt.instance<IJobDataSource>();
    final isCompleted = job.isCompleted;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Summary download
        _GridActionIcon(
          icon: Icons.summarize_outlined,
          tooltip: isCompleted ? 'Download Summary' : 'Summary not ready',
          enabled: isCompleted,
          onTap: () => _downloadFile(
            context,
            dataSource.getSummaryDownloadUrl(job.jobId),
            'summary',
          ),
        ),
        // SRT download
        _GridActionIcon(
          icon: Icons.subtitles_outlined,
          tooltip: isCompleted ? 'Download SRT' : 'SRT not ready',
          enabled: isCompleted,
          onTap: () => _downloadFile(
            context,
            dataSource.getSrtDownloadUrl(job.jobId),
            'SRT',
          ),
        ),
        // External link (only for URL sources)
        if (job.source == 'url' && job.sourceUrl != null)
          _GridActionIcon(
            icon: Icons.open_in_new,
            tooltip: 'Open Source',
            enabled: true,
            onTap: () => _openExternalLink(context, job.sourceUrl!),
          ),
      ],
    );
  }
}

/// Individual action icon for grid card action row.
class _GridActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _GridActionIcon({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? TmzColors.textSecondary : TmzColors.gray70,
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader for thumbnail while loading.
class _ThumbnailSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
