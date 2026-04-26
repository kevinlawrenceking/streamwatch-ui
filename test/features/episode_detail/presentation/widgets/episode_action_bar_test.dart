import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_detail_bloc.dart';
import 'package:streamwatch_frontend/features/episode_detail/presentation/widgets/episode_action_bar.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';

class MockEpisodeDetailBloc
    extends MockBloc<EpisodeDetailEvent, EpisodeDetailState>
    implements EpisodeDetailBloc {}

PodcastEpisodeModel _ep({
  String? transcriptStatus,
  String? processingStatus,
  DateTime? reviewedAt,
}) {
  return PodcastEpisodeModel(
    id: 'e1',
    podcastId: 'p',
    title: 't',
    createdAt: DateTime.utc(2026, 4, 25),
    transcriptStatus: transcriptStatus,
    processingStatus: processingStatus,
    reviewedAt: reviewedAt,
  );
}

const _markReviewedKey = Key('episode_action_bar.mark_reviewed');
const _requestClipKey = Key('episode_action_bar.request_clip');
const _editMetadataKey = Key('episode_action_bar.edit_metadata');

Widget _harness(PodcastEpisodeModel episode,
    {bool isMutating = false, EpisodeDetailBloc? bloc}) {
  final blocInstance = bloc ?? MockEpisodeDetailBloc();
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<EpisodeDetailBloc>.value(
        value: blocInstance,
        child: EpisodeActionBar(
          episode: episode,
          isMutating: isMutating,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const LoadEpisodeEvent('e1'));
  });

  group('Mark Reviewed visibility (E6 derived, reportKey-free)', () {
    testWidgets('shown when reviewedAt null + transcriptStatus ready',
        (tester) async {
      await tester.pumpWidget(
          _harness(_ep(transcriptStatus: 'ready', reviewedAt: null)));
      expect(find.byKey(_markReviewedKey), findsOneWidget);
    });

    testWidgets('hidden when transcriptStatus pending', (tester) async {
      await tester.pumpWidget(_harness(_ep(transcriptStatus: 'pending')));
      expect(find.byKey(_markReviewedKey), findsNothing);
    });

    testWidgets('hidden when transcriptStatus null', (tester) async {
      await tester.pumpWidget(_harness(_ep()));
      expect(find.byKey(_markReviewedKey), findsNothing);
    });

    testWidgets('hidden when already reviewed', (tester) async {
      await tester.pumpWidget(_harness(
          _ep(transcriptStatus: 'ready', reviewedAt: DateTime(2026, 4, 24))));
      expect(find.byKey(_markReviewedKey), findsNothing);
    });

    testWidgets('hidden when transcriptStatus completed', (tester) async {
      await tester.pumpWidget(_harness(_ep(transcriptStatus: 'completed')));
      expect(find.byKey(_markReviewedKey), findsNothing);
    });
  });

  group('Request Clip visibility (E6 derived, reportKey-free)', () {
    testWidgets('shown for processingStatus=detected', (tester) async {
      await tester.pumpWidget(_harness(_ep(processingStatus: 'detected')));
      expect(find.byKey(_requestClipKey), findsOneWidget);
    });

    testWidgets('shown for processingStatus=transcribed', (tester) async {
      await tester.pumpWidget(_harness(_ep(processingStatus: 'transcribed')));
      expect(find.byKey(_requestClipKey), findsOneWidget);
    });

    testWidgets('shown for processingStatus=reviewed', (tester) async {
      await tester.pumpWidget(_harness(_ep(processingStatus: 'reviewed')));
      expect(find.byKey(_requestClipKey), findsOneWidget);
    });

    testWidgets('shown for null processingStatus (treated as earliest)',
        (tester) async {
      await tester.pumpWidget(_harness(_ep()));
      expect(find.byKey(_requestClipKey), findsOneWidget);
    });

    testWidgets('hidden for processingStatus=clip_requested', (tester) async {
      await tester
          .pumpWidget(_harness(_ep(processingStatus: 'clip_requested')));
      expect(find.byKey(_requestClipKey), findsNothing);
    });

    testWidgets('hidden for processingStatus=completed', (tester) async {
      await tester.pumpWidget(_harness(_ep(processingStatus: 'completed')));
      expect(find.byKey(_requestClipKey), findsNothing);
    });
  });

  group('Edit Metadata visibility', () {
    testWidgets('always shown regardless of state', (tester) async {
      await tester.pumpWidget(_harness(_ep()));
      expect(find.byKey(_editMetadataKey), findsOneWidget);
    });

    testWidgets('shown even when other actions are hidden', (tester) async {
      await tester.pumpWidget(_harness(_ep(
          transcriptStatus: 'completed',
          processingStatus: 'completed',
          reviewedAt: DateTime(2026, 4, 24))));
      expect(find.byKey(_markReviewedKey), findsNothing);
      expect(find.byKey(_requestClipKey), findsNothing);
      expect(find.byKey(_editMetadataKey), findsOneWidget);
    });
  });

  group('isMutating', () {
    testWidgets('all visible buttons are disabled while mutating',
        (tester) async {
      await tester.pumpWidget(_harness(
          _ep(transcriptStatus: 'ready', processingStatus: 'detected'),
          isMutating: true));
      final markBtn =
          tester.widget<OutlinedButton>(find.byKey(_markReviewedKey));
      final clipBtn =
          tester.widget<OutlinedButton>(find.byKey(_requestClipKey));
      final editBtn =
          tester.widget<OutlinedButton>(find.byKey(_editMetadataKey));
      expect(markBtn.onPressed, isNull);
      expect(clipBtn.onPressed, isNull);
      expect(editBtn.onPressed, isNull);
    });

    testWidgets('mutating spinner shows', (tester) async {
      await tester.pumpWidget(_harness(_ep(), isMutating: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Tap dispatches MarkReviewedEvent', () {
    testWidgets('Mark Reviewed tap fires event on bloc', (tester) async {
      final bloc = MockEpisodeDetailBloc();
      when(() => bloc.state).thenReturn(EpisodeDetailLoaded(episode: _ep()));
      await tester
          .pumpWidget(_harness(_ep(transcriptStatus: 'ready'), bloc: bloc));
      await tester.tap(find.byKey(_markReviewedKey));
      verify(() => bloc.add(const MarkReviewedEvent('e1'))).called(1);
    });

    testWidgets('Request Clip tap fires event on bloc', (tester) async {
      final bloc = MockEpisodeDetailBloc();
      when(() => bloc.state).thenReturn(EpisodeDetailLoaded(episode: _ep()));
      await tester
          .pumpWidget(_harness(_ep(processingStatus: 'detected'), bloc: bloc));
      await tester.tap(find.byKey(_requestClipKey));
      verify(() => bloc.add(const RequestClipEvent('e1'))).called(1);
    });
  });
}
