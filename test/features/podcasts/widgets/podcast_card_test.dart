import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/podcasts/data/models/podcast.dart';
import 'package:streamwatch_frontend/features/podcasts/presentation/widgets/podcast_card.dart';

void main() {
  final activePodcast = PodcastModel(
    id: 'p1',
    name: 'Active Podcast',
    description: 'An active podcast',
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );

  final inactivePodcast = PodcastModel(
    id: 'p2',
    name: 'Inactive Podcast',
    isActive: false,
    deactivatedAt: DateTime(2026, 1, 3),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 3),
  );

  Widget buildTestWidget(PodcastModel podcast, {VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: PodcastCard(
          podcast: podcast,
          onTap: onTap,
        ),
      ),
    );
  }

  group('PodcastCard', () {
    testWidgets('displays podcast name', (tester) async {
      await tester.pumpWidget(buildTestWidget(activePodcast));
      expect(find.text('Active Podcast'), findsOneWidget);
    });

    testWidgets('displays description when present', (tester) async {
      await tester.pumpWidget(buildTestWidget(activePodcast));
      expect(find.text('An active podcast'), findsOneWidget);
    });

    testWidgets('displays ACTIVE badge for active podcast',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(activePodcast));
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('displays INACTIVE badge for inactive podcast',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(inactivePodcast));
      expect(find.text('INACTIVE'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
          buildTestWidget(activePodcast, onTap: () => tapped = true));
      await tester.tap(find.text('Active Podcast'));
      expect(tapped, isTrue);
    });

    testWidgets('shows popup menu with action', (tester) async {
      await tester.pumpWidget(buildTestWidget(activePodcast));
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Deactivate'), findsOneWidget);
    });
  });
}
