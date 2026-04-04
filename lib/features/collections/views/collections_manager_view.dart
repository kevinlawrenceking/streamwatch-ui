import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../data/models/collection_model.dart';
import '../../../themes/app_theme.dart';
import '../bloc/collections_bloc.dart';
import '../bloc/collections_event.dart';
import '../bloc/collections_state.dart';

/// Collections manager screen.
///
/// Displays a table of collections with actions: rename, visibility toggle,
/// make default, and archive.
class CollectionsManagerView extends StatelessWidget {
  const CollectionsManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CollectionsBloc>(
      create: (_) =>
          GetIt.instance<CollectionsBloc>()..add(const LoadCollectionsEvent()),
      child: const _ManagerBody(),
    );
  }
}

class _ManagerBody extends StatefulWidget {
  const _ManagerBody();

  @override
  State<_ManagerBody> createState() => _ManagerBodyState();
}

class _ManagerBodyState extends State<_ManagerBody> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CollectionsBloc, CollectionsState>(
      listener: (context, state) {
        if (state is CollectionsLoaded) {
          if (state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionError!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
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
      child: Scaffold(
        appBar: TmzAppBar(
          app: WatchAppIdentity.streamWatch,
          customTitle: 'Collections',
        ),
        body: Column(
          children: [
            // Toolbar
            _Toolbar(
              showArchived: _showArchived,
              onToggleArchived: (value) {
                setState(() {
                  _showArchived = value;
                });
              },
              onCreateTap: () => _showCreateDialog(context),
            ),
            // Table
            Expanded(
              child: BlocBuilder<CollectionsBloc, CollectionsState>(
                builder: (context, state) {
                  if (state is CollectionsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CollectionsError) {
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
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context
                                  .read<CollectionsBloc>()
                                  .add(const LoadCollectionsEvent());
                            },
                            child: const Text('RETRY'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is CollectionsLoaded) {
                    final collections = _showArchived
                        ? state.collections
                            .where((c) => c.status == 'archived')
                            .toList()
                        : state.collections
                            .where((c) => c.isActive)
                            .toList();

                    if (collections.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open,
                                size: 64, color: AppColors.textGhost),
                            const SizedBox(height: 16),
                            Text(
                              _showArchived
                                  ? 'No archived collections'
                                  : 'No collections yet',
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(color: AppColors.textDim),
                            ),
                          ],
                        ),
                      );
                    }

                    return _CollectionsTable(
                      collections: collections,
                      showArchived: _showArchived,
                      onRename: (c) => _showRenameDialog(context, c),
                      onToggleVisibility: (c) => _toggleVisibility(context, c),
                      onMakeDefault: (c) => _confirmMakeDefault(context, c),
                      onArchive: (c) => _confirmArchive(context, c),
                      onRestore: (c) => _restoreCollection(context, c),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Collection name'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<CollectionsBloc>().add(
                    CreateCollectionEvent(name: value.trim()),
                  );
              Navigator.of(dialogContext).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                context.read<CollectionsBloc>().add(
                      CreateCollectionEvent(name: name),
                    );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, CollectionModel collection) {
    final nameController = TextEditingController(text: collection.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Collection'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Collection name'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              context.read<CollectionsBloc>().add(
                    UpdateCollectionEvent(
                      collectionId: collection.id,
                      name: value.trim(),
                    ),
                  );
              Navigator.of(dialogContext).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                context.read<CollectionsBloc>().add(
                      UpdateCollectionEvent(
                        collectionId: collection.id,
                        name: name,
                      ),
                    );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _toggleVisibility(BuildContext context, CollectionModel collection) {
    final newVisibility = collection.isPublic ? 'private' : 'public';
    context.read<CollectionsBloc>().add(
          UpdateCollectionEvent(
            collectionId: collection.id,
            visibility: newVisibility,
          ),
        );
  }

  void _confirmMakeDefault(BuildContext context, CollectionModel collection) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Set as Default?'),
        content: Text(
          'New ingested videos will be added to "${collection.name}" by default.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CollectionsBloc>().add(
                    MakeDefaultEvent(collection.id),
                  );
            },
            child: const Text('Set Default'),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context, CollectionModel collection) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive Collection?'),
        content: Text(
          'Archive "${collection.name}"? It will no longer appear in active lists. Videos remain accessible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CollectionsBloc>().add(
                    UpdateCollectionEvent(
                      collectionId: collection.id,
                      status: 'archived',
                    ),
                  );
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _restoreCollection(BuildContext context, CollectionModel collection) {
    context.read<CollectionsBloc>().add(
          UpdateCollectionEvent(
            collectionId: collection.id,
            status: 'active',
          ),
        );
  }
}

/// Toolbar with archive toggle and create button.
class _Toolbar extends StatelessWidget {
  final bool showArchived;
  final ValueChanged<bool> onToggleArchived;
  final VoidCallback onCreateTap;

  const _Toolbar({
    required this.showArchived,
    required this.onToggleArchived,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.textGhost, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Active / Archived toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Active')),
              ButtonSegment(value: true, label: Text('Archived')),
            ],
            selected: {showArchived},
            onSelectionChanged: (s) => onToggleArchived(s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.create_new_folder, size: 18),
            label: const Text('New Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tmzRed,
              foregroundColor: AppColors.textMax,
            ),
          ),
        ],
      ),
    );
  }
}

/// DataTable of collections.
class _CollectionsTable extends StatelessWidget {
  final List<CollectionModel> collections;
  final bool showArchived;
  final void Function(CollectionModel) onRename;
  final void Function(CollectionModel) onToggleVisibility;
  final void Function(CollectionModel) onMakeDefault;
  final void Function(CollectionModel) onArchive;
  final void Function(CollectionModel) onRestore;

  const _CollectionsTable({
    required this.collections,
    required this.showArchived,
    required this.onRename,
    required this.onToggleVisibility,
    required this.onMakeDefault,
    required this.onArchive,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceElevated),
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Visibility')),
              DataColumn(label: Text('Videos'), numeric: true),
              DataColumn(label: Text('Default')),
              DataColumn(label: Text('Actions')),
            ],
            rows: collections.map((c) {
              return DataRow(
                cells: [
                  // Name
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          c.isDefault ? Icons.folder_special : Icons.folder,
                          size: 18,
                          color: c.isDefault ? AppColors.tmzRed : null,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: c.isDefault
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Visibility badge
                  DataCell(_VisibilityBadge(visibility: c.visibility)),
                  // Video count
                  DataCell(Text('${c.videoCount}')),
                  // Default indicator
                  DataCell(
                    c.isDefault
                        ? const Icon(Icons.check_circle,
                            size: 18, color: AppColors.success)
                        : const SizedBox.shrink(),
                  ),
                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showArchived) ...[
                          IconButton(
                            icon: const Icon(Icons.unarchive, size: 18),
                            tooltip: 'Restore',
                            onPressed: () => onRestore(c),
                          ),
                        ] else ...[
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Rename',
                            onPressed: () => onRename(c),
                          ),
                          IconButton(
                            icon: Icon(
                              c.isPublic ? Icons.lock_open : Icons.lock,
                              size: 18,
                            ),
                            tooltip: c.isPublic
                                ? 'Make Private'
                                : 'Make Public',
                            onPressed: () => onToggleVisibility(c),
                          ),
                          if (!c.isDefault)
                            IconButton(
                              icon: const Icon(Icons.star_border, size: 18),
                              tooltip: 'Set as Default',
                              onPressed: () => onMakeDefault(c),
                            ),
                          if (!c.isDefault)
                            IconButton(
                              icon: const Icon(Icons.archive, size: 18),
                              tooltip: 'Archive',
                              onPressed: () => onArchive(c),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${collections.length} collection${collections.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.bodySmall!,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small visibility badge.
class _VisibilityBadge extends StatelessWidget {
  final String visibility;

  const _VisibilityBadge({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final isPublic = visibility == 'public';
    final color = isPublic ? AppColors.info : AppColors.textGhost;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        visibility.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
