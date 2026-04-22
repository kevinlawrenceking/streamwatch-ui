import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/widgets/reported_episode_card.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

PodcastEpisodeModel ep({
  String? ts,
  String? ps,
  DateTime? reviewedAt,
}) {
  return PodcastEpisodeModel(
    id: 'e1',
    podcastId: 'p1',
    title: 'An Episode',
    createdAt: DateTime(2026, 4, 20),
    transcriptStatus: ts,
    processingStatus: ps,
    reviewedAt: reviewedAt,
  );
}

Widget _host(Widget card) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: card),
    );

Finder _markReviewedButton() => find.widgetWithText(OutlinedButton, 'Mark Reviewed');
Finder _requestClipButton() => find.widgetWithText(OutlinedButton, 'Request Clip');

void main() {
  group('ReportedEpisodeCard E6 visibility matrix', () {
    testWidgets('transcript-pending: both actions hidden', (tester) async {
      await tester.pumpWidget(_host(ReportedEpisodeCard(
        episode: ep(ts: 'pending', ps: 'detected'),
        reportKey: 'transcript-pending',
        accentColor: AppColors.info,
      )));
      expect(_markReviewedButton(), findsNothing);
      expect(_requestClipButton(), findsNothing);
    });

    testWidgets('pending-clip-request: both actions hidden', (tester) async {
      await tester.pumpWidget(_host(ReportedEpisodeCard(
        episode: ep(ts: 'ready', ps: 'clip_requested'),
        reportKey: 'pending-clip-request',
        accentColor: AppColors.info,
      )));
      expect(_markReviewedButton(), findsNothing);
      expect(_requestClipButton(), findsNothing);
    });

    testWidgets('pending-review: Mark Reviewed shown, Request Clip hidden',
        (tester) async {
      await tester.pumpWidget(_host(ReportedEpisodeCard(
        episode: ep(ts: 'ready', ps: 'transcribed', reviewedAt: null),
        reportKey: 'pending-review',
        accentColor: AppColors.info,
      )));
      expect(_markReviewedButton(), findsOneWidget);
      expect(_requestClipButton(), findsNothing);
    });

    testWidgets('recent + ready + unreviewed + pre-clip: both actions shown',
        (tester) async {
      await tester.pumpWidget(_host(ReportedEpisodeCard(
        episode: ep(ts: 'ready', ps: 'transcribed', reviewedAt: null),
        reportKey: 'recent',
        accentColor: AppColors.info,
      )));
      expect(_markReviewedButton(), findsOneWidget);
      expect(_requestClipButton(), findsOneWidget);
    });

    testWidgets('recent + already reviewed: Mark hidden, Request still shown if eligible',
        (tester) async {
      await tester.pumpWidget(_host(ReportedEpisodeCard(
        episode: ep(
            ts: 'ready', ps: 'reviewed', reviewedAt: DateTime(2026, 4, 21)),
        reportKey: 'recent',
        accentColor: AppColors.info,
      )));
      expect(_markReviewedButton(), findsNothing);
      expect(_requestClipButton(), findsOneWidget);
    });

    testWidgets('recent + transcript not ready: both hidden', (tester) async {
      await tester.pumpWidget(_host(ReportedEpisodeCard(
        episode: ep(ts: 'pending', ps: 'detected'),
        reportKey: 'recent',
        accentColor: AppColors.info,
      )));
      expect(_markReviewedButton(), findsNothing);
      // RC shown by status alone even without ready transcript? E6 rule is
      // only "pre-clip_requested" — so yes RC is shown.
      expect(_requestClipButton(), findsOneWidget);
    });

    testWidgets('headline-ready mirrors recent visibility rules',
        (tester) async {
      await tester.pumpWidget(_host(ReportedEpisodeCard(
        episode: ep(ts: 'ready', ps: 'transcribed', reviewedAt: null),
        reportKey: 'headline-ready',
        accentColor: AppColors.info,
      )));
      expect(_markReviewedButton(), findsOneWidget);
      expect(_requestClipButton(), findsOneWidget);
    });

    testWidgets('in-flight disables both buttons and shows spinner',
        (tester) async {
      await tester.pumpWidget(_host(ReportedEpisodeCard(
        episode: ep(ts: 'ready', ps: 'transcribed'),
        reportKey: 'recent',
        accentColor: AppColors.info,
        inFlight: true,
        onMarkReviewed: () {},
        onRequestClip: () {},
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final mr = tester.widget<OutlinedButton>(_markReviewedButton());
      final rc = tester.widget<OutlinedButton>(_requestClipButton());
      expect(mr.onPressed, isNull);
      expect(rc.onPressed, isNull);
    });
  });
}
