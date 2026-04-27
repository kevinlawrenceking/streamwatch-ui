import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/watchlist/data/models/guest_watchlist_entry.dart';
import 'package:streamwatch_frontend/features/watchlist/presentation/widgets/watchlist_entry_card.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

PodcastGuestWatchlistEntry _entry({String status = 'active'}) =>
    PodcastGuestWatchlistEntry(
      id: 'wl-1',
      guestName: 'Alice',
      aliases: const ['Al'],
      reason: 'recurring guest',
      priority: 'high',
      status: status,
      createdAt: DateTime.utc(2026, 4, 20),
      updatedAt: DateTime.utc(2026, 4, 25),
    );

Widget _harness(Widget child) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('active entry shows Edit button', (tester) async {
    await tester.pumpWidget(_harness(WatchlistEntryCard(
      entry: _entry(status: 'active'),
      onEdit: () {},
      onChangeStatus: () {},
    )));
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('active entry shows Change Status button', (tester) async {
    await tester.pumpWidget(_harness(WatchlistEntryCard(
      entry: _entry(status: 'active'),
      onEdit: () {},
      onChangeStatus: () {},
    )));
    expect(find.text('Change Status'), findsOneWidget);
  });

  testWidgets('matched entry hides Edit and Change Status (terminal read-only)',
      (tester) async {
    await tester.pumpWidget(_harness(WatchlistEntryCard(
      entry: _entry(status: 'matched'),
      onEdit: () {},
      onChangeStatus: () {},
    )));
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Change Status'), findsNothing);
  });

  testWidgets('expired entry hides Edit and Change Status (terminal read-only)',
      (tester) async {
    await tester.pumpWidget(_harness(WatchlistEntryCard(
      entry: _entry(status: 'expired'),
      onEdit: () {},
      onChangeStatus: () {},
    )));
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Change Status'), findsNothing);
  });
}
