import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/watchlist/presentation/bloc/watchlist_bloc.dart';
import 'package:streamwatch_frontend/features/watchlist/presentation/widgets/watchlist_create_dialog.dart';

// WO-112-RED / LSW-VER-T2 AC4 — regression guard on a clean-round-trip surface
// beyond the 3 known-broken Pattern A forms. WatchlistCreateDialog emits keys
// that exactly match CreateGuestWatchlistEntryRequest's json tags
// (guest_name, aliases, reason, priority); the handler enforces the contract
// with json.Decoder.DisallowUnknownFields. This test pins the payload shape so
// any future field-drop drift on this surface fails CI.

class _MockWatchlistBloc extends MockBloc<WatchlistEvent, WatchlistState>
    implements WatchlistBloc {}

class _FakeWatchlistEvent extends Fake implements WatchlistEvent {}

Widget _harness(WatchlistBloc bloc) => MaterialApp(
      home: BlocProvider<WatchlistBloc>.value(
        value: bloc,
        child: const Scaffold(body: WatchlistCreateDialog()),
      ),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeWatchlistEvent());
  });

  late _MockWatchlistBloc bloc;

  setUp(() {
    bloc = _MockWatchlistBloc();
    when(() => bloc.state).thenReturn(const WatchlistInitial());
  });

  testWidgets(
      'Create dispatches CreateWatchlistEntryEvent with exact contract keys',
      (tester) async {
    await tester.pumpWidget(_harness(bloc));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Guest name'), 'Jane Doe');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Aliases (comma-separated)'),
        'JD, J. Doe');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Reason'), 'recurring guest');

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    final captured = verify(() => bloc.add(captureAny())).captured;
    expect(captured.length, 1);
    final event = captured.single as CreateWatchlistEntryEvent;

    expect(event.body.keys.toSet(),
        {'guest_name', 'aliases', 'reason', 'priority'});
    expect(event.body['guest_name'], 'Jane Doe');
    expect(event.body['aliases'], ['JD', 'J. Doe']);
    expect(event.body['reason'], 'recurring guest');
    expect(event.body['priority'], 'medium');
  });

  testWidgets('Create omits reason when blank but keeps the other 3 keys',
      (tester) async {
    await tester.pumpWidget(_harness(bloc));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Guest name'), 'Jane Doe');

    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    final captured = verify(() => bloc.add(captureAny())).captured;
    final event = captured.single as CreateWatchlistEntryEvent;

    expect(event.body.keys.toSet(), {'guest_name', 'aliases', 'priority'});
    expect(event.body.containsKey('reason'), isFalse);
  });
}
