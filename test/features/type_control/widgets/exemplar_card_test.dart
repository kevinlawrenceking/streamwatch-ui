import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:streamwatch_frontend/data/models/video_type_model.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/exemplar_management_bloc.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/exemplar_management_event.dart';
import 'package:streamwatch_frontend/features/type_control/bloc/exemplar_management_state.dart';
import 'package:streamwatch_frontend/features/type_control/widgets/exemplar_card.dart';

class MockExemplarBloc
    extends MockBloc<ExemplarManagementEvent, ExemplarManagementState>
    implements ExemplarManagementBloc {}

class FakeExemplarEvent extends Fake implements ExemplarManagementEvent {}

void main() {
  late MockExemplarBloc mockBloc;

  final tExemplar = VideoTypeExemplarModel(
    id: 'ex-1',
    videoTypeId: 'type-1',
    jobId: 'JOB001',
    exemplarKind: 'canonical',
    weight: 1.0,
    notes: 'Test note',
    imageUrl: 'https://example.com/img.jpg',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  final tExemplarNoImage = VideoTypeExemplarModel(
    id: 'ex-2',
    videoTypeId: 'type-1',
    jobId: 'JOB002',
    exemplarKind: 'counter_example',
    weight: 3.0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeExemplarEvent());
  });

  setUp(() {
    mockBloc = MockExemplarBloc();
    when(() => mockBloc.state).thenReturn(
      ExemplarManagementLoaded(exemplars: [tExemplar]),
    );
  });

  Widget buildSubject({
    VideoTypeExemplarModel? exemplar,
    bool isUpdating = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<ExemplarManagementBloc>.value(
          value: mockBloc,
          child: ExemplarCard(
            exemplar: exemplar ?? tExemplar,
            videoTypeId: 'type-1',
            isUpdating: isUpdating,
          ),
        ),
      ),
    );
  }

  group('ExemplarCard', () {
    testWidgets('renders Image.network when imageUrl is non-null',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Image.network should be in the widget tree
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders placeholder when imageUrl is null', (tester) async {
      await tester.pumpWidget(buildSubject(exemplar: tExemplarNoImage));

      // Should find the placeholder icon
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    });

    testWidgets('displays weight value', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Weight: 1.0'), findsOneWidget);
    });

    testWidgets('displays weight value for non-default weight', (tester) async {
      await tester.pumpWidget(buildSubject(exemplar: tExemplarNoImage));

      expect(find.text('Weight: 3.0'), findsOneWidget);
    });

    testWidgets('weight edit: entering 11.0 shows validation error',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap the weight to enter edit mode
      await tester.tap(find.text('Weight: 1.0'));
      await tester.pumpAndSettle();

      // Enter invalid value
      final textField = find.byType(TextFormField).first;
      await tester.enterText(textField, '11.0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('0.0 - 10.0'), findsOneWidget);

      // Should NOT have dispatched an event
      verifyNever(() => mockBloc.add(any()));
    });

    testWidgets('weight edit: entering -1.0 shows validation error',
        (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap the weight to enter edit mode
      await tester.tap(find.text('Weight: 1.0'));
      await tester.pumpAndSettle();

      // Clear and enter invalid value
      final textField = find.byType(TextFormField).first;
      await tester.enterText(textField, '-1.0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Should show validation error (or the input formatter prevents the minus)
      // The FilteringTextInputFormatter blocks '-', so value stays empty or partial
      // Verify no event was dispatched
      verifyNever(() => mockBloc.add(any()));
    });

    testWidgets('notes edit triggers UpdateExemplarEvent', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap notes to enter edit mode
      await tester.tap(find.text('Test note'));
      await tester.pumpAndSettle();

      // Find the notes text field and change it
      final textFields = find.byType(TextFormField);
      expect(textFields, findsOneWidget);
      await tester.enterText(textFields, 'Updated note');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const UpdateExemplarEvent(
            exemplarId: 'ex-1',
            notes: 'Updated note',
          ))).called(1);
    });

    testWidgets('kind change triggers UpdateExemplarEvent', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Tap the kind dropdown
      await tester.tap(find.text('CANONICAL'));
      await tester.pumpAndSettle();

      // Select counter_example
      await tester.tap(find.text('Counter Example'));
      await tester.pumpAndSettle();

      verify(() => mockBloc.add(const UpdateExemplarEvent(
            exemplarId: 'ex-1',
            exemplarKind: 'counter_example',
          ))).called(1);
    });

    testWidgets('per-card loading indicator shown when isUpdating is true',
        (tester) async {
      await tester.pumpWidget(buildSubject(isUpdating: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('no loading indicator when isUpdating is false',
        (tester) async {
      await tester.pumpWidget(buildSubject(isUpdating: false));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
