import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_detail_bloc.dart';
import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_headlines_bloc.dart';
import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_notifications_bloc.dart';
import 'package:streamwatch_frontend/features/episode_detail/presentation/bloc/episode_transcripts_bloc.dart';
import 'package:streamwatch_frontend/features/episode_detail/presentation/views/episode_detail_view.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';

class MockEpisodeDetailBloc
    extends MockBloc<EpisodeDetailEvent, EpisodeDetailState>
    implements EpisodeDetailBloc {}

class MockEpisodeTranscriptsBloc
    extends MockBloc<EpisodeTranscriptsEvent, EpisodeTranscriptsState>
    implements EpisodeTranscriptsBloc {}

class MockEpisodeHeadlinesBloc
    extends MockBloc<EpisodeHeadlinesEvent, EpisodeHeadlinesState>
    implements EpisodeHeadlinesBloc {}

class MockEpisodeNotificationsBloc
    extends MockBloc<EpisodeNotificationsEvent, EpisodeNotificationsState>
    implements EpisodeNotificationsBloc {}

PodcastEpisodeModel _ep() => PodcastEpisodeModel(
      id: 'e1',
      podcastId: 'p1',
      title: 'Episode One',
      createdAt: DateTime.utc(2026, 4, 25),
    );

void main() {
  late MockEpisodeDetailBloc detail;
  late MockEpisodeTranscriptsBloc transcripts;
  late MockEpisodeHeadlinesBloc headlines;
  late MockEpisodeNotificationsBloc notifications;

  setUp(() {
    detail = MockEpisodeDetailBloc();
    transcripts = MockEpisodeTranscriptsBloc();
    headlines = MockEpisodeHeadlinesBloc();
    notifications = MockEpisodeNotificationsBloc();

    // Wire mocks into GetIt for the view's BlocProvider create-callbacks.
    final sl = GetIt.instance;
    if (sl.isRegistered<EpisodeDetailBloc>())
      sl.unregister<EpisodeDetailBloc>();
    if (sl.isRegistered<EpisodeTranscriptsBloc>()) {
      sl.unregister<EpisodeTranscriptsBloc>();
    }
    if (sl.isRegistered<EpisodeHeadlinesBloc>()) {
      sl.unregister<EpisodeHeadlinesBloc>();
    }
    if (sl.isRegistered<EpisodeNotificationsBloc>()) {
      sl.unregister<EpisodeNotificationsBloc>();
    }
    sl.registerFactory<EpisodeDetailBloc>(() => detail);
    sl.registerFactory<EpisodeTranscriptsBloc>(() => transcripts);
    sl.registerFactory<EpisodeHeadlinesBloc>(() => headlines);
    sl.registerFactory<EpisodeNotificationsBloc>(() => notifications);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('renders Loading scaffold when state is Initial', (tester) async {
    when(() => detail.state).thenReturn(const EpisodeDetailInitial());
    when(() => transcripts.state).thenReturn(const EpisodeTranscriptsInitial());
    when(() => headlines.state).thenReturn(const EpisodeHeadlinesInitial());
    when(() => notifications.state)
        .thenReturn(const EpisodeNotificationsInitial());

    await tester.pumpWidget(
      const MaterialApp(home: EpisodeDetailView(episodeId: 'e1')),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Episode'), findsOneWidget);
  });

  testWidgets('renders Error scaffold with retry button when state is Error',
      (tester) async {
    when(() => detail.state).thenReturn(const EpisodeDetailError('boom'));
    when(() => transcripts.state).thenReturn(const EpisodeTranscriptsInitial());
    when(() => headlines.state).thenReturn(const EpisodeHeadlinesInitial());
    when(() => notifications.state)
        .thenReturn(const EpisodeNotificationsInitial());

    await tester.pumpWidget(
      const MaterialApp(home: EpisodeDetailView(episodeId: 'e1')),
    );

    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('renders 4 tabs + action bar when episode is Loaded',
      (tester) async {
    when(() => detail.state).thenReturn(EpisodeDetailLoaded(episode: _ep()));
    when(() => transcripts.state)
        .thenReturn(const EpisodeTranscriptsLoaded(transcripts: []));
    when(() => headlines.state)
        .thenReturn(const EpisodeHeadlinesLoaded(candidates: []));
    when(() => notifications.state)
        .thenReturn(const EpisodeNotificationsLoaded(notifications: []));

    await tester.pumpWidget(
      const MaterialApp(home: EpisodeDetailView(episodeId: 'e1')),
    );

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Transcripts'), findsOneWidget);
    expect(find.text('Headlines'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);
    // Title appears in both AppBar and Overview tab row -- accept either.
    expect(find.text('Episode One'), findsAtLeastNWidgets(1));
    expect(find.text('Edit Metadata'), findsOneWidget); // action bar
  });

  testWidgets('Overview tab renders episode metadata rows', (tester) async {
    final ep = _ep().copyWith(
      episodeDescription: 'Lorem ipsum',
      processingStatus: 'detected',
    );
    when(() => detail.state).thenReturn(EpisodeDetailLoaded(episode: ep));
    when(() => transcripts.state)
        .thenReturn(const EpisodeTranscriptsLoaded(transcripts: []));
    when(() => headlines.state)
        .thenReturn(const EpisodeHeadlinesLoaded(candidates: []));
    when(() => notifications.state)
        .thenReturn(const EpisodeNotificationsLoaded(notifications: []));

    await tester.pumpWidget(
      const MaterialApp(home: EpisodeDetailView(episodeId: 'e1')),
    );
    // Default tab is Overview.
    expect(find.text('Lorem ipsum'), findsOneWidget);
    expect(find.text('detected'), findsOneWidget);
  });
}
