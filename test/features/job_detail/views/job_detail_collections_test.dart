import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/collection_model.dart';
import 'package:streamwatch_frontend/data/sources/collection_data_source.dart';
import 'package:streamwatch_frontend/shared/errors/failures/failure.dart';

class MockCollectionDataSource extends Mock implements ICollectionDataSource {}

// ---------------------------------------------------------------------------
// Testable widget that mirrors _CollectionsSection behaviour exactly.
// We duplicate the logic here because _CollectionsSection is file-private.
// ---------------------------------------------------------------------------
class TestCollectionsSection extends StatefulWidget {
  final String jobId;
  const TestCollectionsSection({super.key, required this.jobId});

  @override
  State<TestCollectionsSection> createState() => _TestCollectionsSectionState();
}

class _TestCollectionsSectionState extends State<TestCollectionsSection> {
  List<CollectionModel>? _memberships;
  List<CollectionModel>? _allCollections;
  bool _loading = true;
  String? _error;
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

      List<CollectionModel> memberships = [];
      List<CollectionModel> all = [];

      (results[0]).fold(
        (f) => null,
        (list) => memberships = List<CollectionModel>.from(list),
      );
      (results[1]).fold(
        (f) => null,
        (list) => all = List<CollectionModel>.from(list),
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
          backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Collections',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_memberships != null && _memberships!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _memberships!
                    .map((c) => Chip(
                          key: ValueKey('membership-${c.id}'),
                          label: Text(c.name),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: _actionInFlight
                              ? null
                              : () => _removeFromCollection(c),
                        ))
                    .toList(),
              )
            else
              const Text('Not in any collections'),
            const SizedBox(height: 12),
            if (_availableToAdd.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const ValueKey('add-dropdown'),
                      value: _selectedCollectionId,
                      decoration: const InputDecoration(
                        labelText: 'Add to collection',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: _availableToAdd
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: _actionInFlight
                          ? null
                          : (value) =>
                              setState(() => _selectedCollectionId = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: const ValueKey('add-button'),
                    onPressed:
                        _selectedCollectionId != null && !_actionInFlight
                            ? () => _addToCollection(_selectedCollectionId!)
                            : null,
                    child: const Text('Add'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockCollectionDataSource mockDS;

  final membership1 = CollectionModel(
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

  final membership2 = CollectionModel(
    id: 'coll-2',
    ownerUserId: 'user-1',
    name: 'My Default',
    visibility: 'private',
    status: 'active',
    isDefault: true,
    videoCount: 10,
    tags: [],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final availableCollection = CollectionModel(
    id: 'coll-3',
    ownerUserId: 'user-1',
    name: 'News Clips',
    visibility: 'public',
    status: 'active',
    isDefault: false,
    videoCount: 3,
    tags: [],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockDS = MockCollectionDataSource();
    final getIt = GetIt.instance;
    if (getIt.isRegistered<ICollectionDataSource>()) {
      getIt.unregister<ICollectionDataSource>();
    }
    getIt.registerSingleton<ICollectionDataSource>(mockDS);
  });

  tearDown(() {
    final getIt = GetIt.instance;
    if (getIt.isRegistered<ICollectionDataSource>()) {
      getIt.unregister<ICollectionDataSource>();
    }
  });

  Widget buildTestWidget() {
    return const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TestCollectionsSection(jobId: 'job-123'),
        ),
      ),
    );
  }

  testWidgets('renders membership chips from data source', (tester) async {
    when(() => mockDS.getVideoCollections('job-123'))
        .thenAnswer((_) async => Right([membership1, membership2]));
    when(() => mockDS.getCollections())
        .thenAnswer((_) async => Right([membership1, membership2]));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Highlights'), findsOneWidget);
    expect(find.text('My Default'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
  });

  testWidgets('shows empty message when not in any collections',
      (tester) async {
    when(() => mockDS.getVideoCollections('job-123'))
        .thenAnswer((_) async => const Right([]));
    when(() => mockDS.getCollections())
        .thenAnswer((_) async => Right([availableCollection]));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Not in any collections'), findsOneWidget);
  });

  testWidgets('tapping remove calls removeVideoFromCollection',
      (tester) async {
    when(() => mockDS.getVideoCollections('job-123'))
        .thenAnswer((_) async => Right([membership1]));
    when(() => mockDS.getCollections())
        .thenAnswer((_) async => Right([membership1]));
    when(() => mockDS.removeVideoFromCollection('coll-1', 'job-123'))
        .thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Find the delete icon on the chip
    final deleteIcon = find.descendant(
      of: find.byKey(const ValueKey('membership-coll-1')),
      matching: find.byIcon(Icons.close),
    );
    expect(deleteIcon, findsOneWidget);

    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    verify(() => mockDS.removeVideoFromCollection('coll-1', 'job-123'))
        .called(1);
  });

  testWidgets('shows dropdown with available collections', (tester) async {
    when(() => mockDS.getVideoCollections('job-123'))
        .thenAnswer((_) async => Right([membership1]));
    when(() => mockDS.getCollections()).thenAnswer(
        (_) async => Right([membership1, availableCollection]));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // The dropdown should exist with label
    expect(find.text('Add to collection'), findsOneWidget);

    // The Add button should be disabled (nothing selected yet)
    final addButton = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('add-button')));
    expect(addButton.onPressed, isNull);
  });

  testWidgets('selecting dropdown + Add calls addVideosToCollection',
      (tester) async {
    when(() => mockDS.getVideoCollections('job-123'))
        .thenAnswer((_) async => const Right([]));
    when(() => mockDS.getCollections())
        .thenAnswer((_) async => Right([availableCollection]));
    when(() => mockDS.addVideosToCollection('coll-3', ['job-123']))
        .thenAnswer((_) async => const Right(null));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Open the dropdown
    await tester.tap(find.byKey(const ValueKey('add-dropdown')));
    await tester.pumpAndSettle();

    // Select 'News Clips'
    await tester.tap(find.text('News Clips').last);
    await tester.pumpAndSettle();

    // Tap Add button
    await tester.tap(find.byKey(const ValueKey('add-button')));
    await tester.pumpAndSettle();

    verify(() => mockDS.addVideosToCollection('coll-3', ['job-123']))
        .called(1);
  });

  testWidgets('hides dropdown when no collections available to add',
      (tester) async {
    // All collections already contain this video
    when(() => mockDS.getVideoCollections('job-123'))
        .thenAnswer((_) async => Right([membership1, availableCollection]));
    when(() => mockDS.getCollections())
        .thenAnswer((_) async => Right([membership1, availableCollection]));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Add to collection'), findsNothing);
    expect(find.byKey(const ValueKey('add-button')), findsNothing);
  });

  testWidgets('shows error snackbar on remove failure', (tester) async {
    when(() => mockDS.getVideoCollections('job-123'))
        .thenAnswer((_) async => Right([membership1]));
    when(() => mockDS.getCollections())
        .thenAnswer((_) async => Right([membership1]));
    when(() => mockDS.removeVideoFromCollection('coll-1', 'job-123'))
        .thenAnswer((_) async =>
            const Left(Failure('Cannot remove from archived')));

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final deleteIcon = find.descendant(
      of: find.byKey(const ValueKey('membership-coll-1')),
      matching: find.byIcon(Icons.close),
    );
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    expect(find.text('Cannot remove from archived'), findsOneWidget);
  });
}
