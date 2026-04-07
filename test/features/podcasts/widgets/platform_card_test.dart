import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_platform.dart';
import 'package:streamwatch_frontend/features/podcasts/presentation/widgets/platform_card.dart';

void main() {
  const testPlatform = PodcastPlatformModel(
    id: 'pl1',
    podcastId: 'p1',
    platformName: 'Spotify',
    platformUrl: 'https://spotify.com/show/test',
  );

  Widget buildTestWidget({VoidCallback? onEdit, VoidCallback? onDelete}) {
    return MaterialApp(
      home: Scaffold(
        body: PlatformCard(
          platform: testPlatform,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ),
    );
  }

  group('PlatformCard', () {
    testWidgets('displays platform name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('Spotify'), findsOneWidget);
    });

    testWidgets('displays platform URL', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      expect(
          find.text('https://spotify.com/show/test'), findsOneWidget);
    });

    testWidgets('calls onEdit when edit button is pressed',
        (tester) async {
      var edited = false;
      await tester
          .pumpWidget(buildTestWidget(onEdit: () => edited = true));
      await tester.tap(find.byTooltip('Edit'));
      expect(edited, isTrue);
    });

    testWidgets('calls onDelete when delete button is pressed',
        (tester) async {
      var deleted = false;
      await tester
          .pumpWidget(buildTestWidget(onDelete: () => deleted = true));
      await tester.tap(find.byTooltip('Delete'));
      expect(deleted, isTrue);
    });
  });
}
