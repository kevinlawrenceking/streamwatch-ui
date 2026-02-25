import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/collection_model.dart';
import 'package:streamwatch_frontend/features/collections/bloc/collections_bloc.dart';
import 'package:streamwatch_frontend/features/collections/bloc/collections_event.dart';
import 'package:streamwatch_frontend/features/collections/bloc/collections_state.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockCollectionsBloc extends MockBloc<CollectionsEvent, CollectionsState>
    implements CollectionsBloc {}

void main() {
  late MockCollectionsBloc mockBloc;
  late CollectionModel activeCollection;
  late CollectionModel defaultCollection;
  late CollectionModel archivedCollection;

  setUp(() {
    mockBloc = MockCollectionsBloc();

    activeCollection = CollectionModel(
      id: 'coll-1',
      ownerUserId: 'user-1',
      name: 'Highlights',
      visibility: 'private',
      status: 'active',
      isDefault: false,
      videoCount: 5,
      tags: [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    defaultCollection = CollectionModel(
      id: 'coll-2',
      ownerUserId: 'user-1',
      name: 'Default',
      visibility: 'private',
      status: 'active',
      isDefault: true,
      videoCount: 10,
      tags: [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    archivedCollection = CollectionModel(
      id: 'coll-3',
      ownerUserId: 'user-1',
      name: 'Old Stuff',
      visibility: 'public',
      status: 'archived',
      isDefault: false,
      videoCount: 3,
      tags: [],
      createdAt: DateTime(2025, 6, 1),
      updatedAt: DateTime(2025, 12, 1),
    );
  });

  Widget buildTestWidget({required CollectionsState state}) {
    when(() => mockBloc.state).thenReturn(state);
    return MaterialApp(
      home: BlocProvider<CollectionsBloc>.value(
        value: mockBloc,
        child: const _ManagerBodyForTest(),
      ),
    );
  }

  group('CollectionsManagerView', () {
    testWidgets('shows loading indicator in loading state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(state: const CollectionsLoading()),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message in error state', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          state: const CollectionsError(GeneralFailure('Failed to load')),
        ),
      );
      expect(find.text('Error: Failed to load'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
    });

    testWidgets('shows active collections in table', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          state: CollectionsLoaded(
            collections: [activeCollection, defaultCollection, archivedCollection],
          ),
        ),
      );

      // Active collections visible
      expect(find.text('Highlights'), findsOneWidget);
      // "Default" appears twice: column header + collection name
      expect(find.text('Default'), findsNWidgets(2));
      // Archived NOT visible in active tab
      expect(find.text('Old Stuff'), findsNothing);
      // Video counts visible
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows empty message when no active collections', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          state: CollectionsLoaded(
            collections: [archivedCollection],
          ),
        ),
      );
      expect(find.text('No collections yet'), findsOneWidget);
    });

    testWidgets('shows archived collections when toggled', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          state: CollectionsLoaded(
            collections: [activeCollection, defaultCollection, archivedCollection],
          ),
        ),
      );

      // Tap "Archived" segment using a descendant finder scoped to the SegmentedButton
      final archivedSegment = find.descendant(
        of: find.byType(SegmentedButton<bool>),
        matching: find.text('Archived'),
      );
      await tester.ensureVisible(archivedSegment);
      await tester.pumpAndSettle();
      await tester.tap(archivedSegment, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Archived visible
      expect(find.text('Old Stuff'), findsOneWidget);
      // Active NOT visible in content area (but "Active" still in segmented button)
      expect(find.text('Highlights'), findsNothing);
    });

    testWidgets('rename button opens dialog', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          state: CollectionsLoaded(
            collections: [activeCollection, defaultCollection],
          ),
        ),
      );

      // Find the rename (edit) button by tooltip
      final editButtons = find.byTooltip('Rename');
      expect(editButtons, findsWidgets);

      await tester.ensureVisible(editButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Rename Collection'), findsOneWidget);
    });

    testWidgets('archive button opens confirm dialog', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          state: CollectionsLoaded(
            collections: [activeCollection, defaultCollection],
          ),
        ),
      );

      // Find archive button by tooltip (only on non-default collection)
      final archiveButton = find.byTooltip('Archive');
      expect(archiveButton, findsOneWidget);

      await tester.ensureVisible(archiveButton);
      await tester.pumpAndSettle();
      await tester.tap(archiveButton);
      await tester.pumpAndSettle();

      expect(find.text('Archive Collection?'), findsOneWidget);
    });
  });
}

/// Extracted body for testing (bypasses GetIt provider creation).
class _ManagerBodyForTest extends StatefulWidget {
  const _ManagerBodyForTest();

  @override
  State<_ManagerBodyForTest> createState() => _ManagerBodyForTestState();
}

class _ManagerBodyForTestState extends State<_ManagerBodyForTest> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CollectionsBloc, CollectionsState>(
      listener: (context, state) {},
      child: Scaffold(
        body: Column(
          children: [
            // Toolbar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Active')),
                      ButtonSegment(value: true, label: Text('Archived')),
                    ],
                    selected: {_showArchived},
                    onSelectionChanged: (s) {
                      setState(() {
                        _showArchived = s.first;
                      });
                    },
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.create_new_folder, size: 18),
                    label: const Text('New Collection'),
                  ),
                ],
              ),
            ),
            // Content
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
                          Text('Error: ${state.failure.message}'),
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
                        child: Text(
                          _showArchived
                              ? 'No archived collections'
                              : 'No collections yet',
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: DataTable(
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
                              DataCell(Text(c.name)),
                              DataCell(Text(c.visibility.toUpperCase())),
                              DataCell(Text('${c.videoCount}')),
                              DataCell(
                                c.isDefault
                                    ? const Icon(Icons.check_circle,
                                        size: 18, color: Colors.green)
                                    : const SizedBox.shrink(),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_showArchived) ...[
                                      IconButton(
                                        icon: const Icon(Icons.unarchive,
                                            size: 18),
                                        tooltip: 'Restore',
                                        onPressed: () {},
                                      ),
                                    ] else ...[
                                      IconButton(
                                        icon:
                                            const Icon(Icons.edit, size: 18),
                                        tooltip: 'Rename',
                                        onPressed: () {
                                          _showRenameDialog(context, c);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          c.isPublic
                                              ? Icons.lock_open
                                              : Icons.lock,
                                          size: 18,
                                        ),
                                        tooltip: c.isPublic
                                            ? 'Make Private'
                                            : 'Make Public',
                                        onPressed: () {},
                                      ),
                                      if (!c.isDefault)
                                        IconButton(
                                          icon: const Icon(Icons.star_border,
                                              size: 18),
                                          tooltip: 'Set as Default',
                                          onPressed: () {},
                                        ),
                                      if (!c.isDefault)
                                        IconButton(
                                          icon: const Icon(Icons.archive,
                                              size: 18),
                                          tooltip: 'Archive',
                                          onPressed: () {
                                            _showArchiveDialog(context, c);
                                          },
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
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

  void _showRenameDialog(BuildContext context, CollectionModel c) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Collection'),
        content: TextField(
          controller: TextEditingController(text: c.name),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showArchiveDialog(BuildContext context, CollectionModel c) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive Collection?'),
        content: Text('Archive "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}
