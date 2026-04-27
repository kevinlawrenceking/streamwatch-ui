import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:streamwatch_frontend/features/podcasts/data/data_sources/podcast_data_source.dart';
import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';
import 'package:streamwatch_frontend/features/watchlist/presentation/widgets/episode_picker_dialog.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

class MockPodcastDataSource extends Mock implements IPodcastDataSource {}

PodcastEpisodeModel _ep(String id) => PodcastEpisodeModel(
      id: id,
      podcastId: 'p-1',
      title: 'Episode $id',
      createdAt: DateTime.utc(2026, 4, 25),
    );

Widget _harness({String podcastId = 'p-1'}) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: EpisodePickerDialog(podcastId: podcastId),
      ),
    );

void main() {
  late MockPodcastDataSource ds;

  setUp(() {
    ds = MockPodcastDataSource();
    if (GetIt.instance.isRegistered<IPodcastDataSource>()) {
      GetIt.instance.unregister<IPodcastDataSource>();
    }
    GetIt.instance.registerSingleton<IPodcastDataSource>(ds);
  });

  tearDown(() {
    if (GetIt.instance.isRegistered<IPodcastDataSource>()) {
      GetIt.instance.unregister<IPodcastDataSource>();
    }
  });

  testWidgets('shows loading scaffold while listEpisodes is in flight',
      (tester) async {
    when(() => ds.listEpisodes(any(),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'))).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 30));
      return Right(const PaginatedResponse<PodcastEpisodeModel>(
        items: [],
        total: 0,
        page: 1,
        pageSize: 50,
      ));
    });
    await tester.pumpWidget(_harness());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('loaded list: tap on row Navigator.pops the episodeId',
      (tester) async {
    when(() => ds.listEpisodes(any(),
            page: any(named: 'page'), pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => Right(PaginatedResponse<PodcastEpisodeModel>(
              items: [_ep('e-1'), _ep('e-2')],
              total: 2,
              page: 1,
              pageSize: 50,
            )));

    String? returnedId;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () async {
              returnedId = await showDialog<String>(
                context: ctx,
                builder: (_) => const EpisodePickerDialog(podcastId: 'p-1'),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Episode e-1'), findsOneWidget);
    await tester.tap(find.text('Episode e-1'));
    await tester.pumpAndSettle();
    expect(returnedId, 'e-1');
  });

  testWidgets('empty state when listEpisodes returns no items', (tester) async {
    when(() => ds.listEpisodes(any(),
            page: any(named: 'page'), pageSize: any(named: 'pageSize')))
        .thenAnswer(
            (_) async => Right(const PaginatedResponse<PodcastEpisodeModel>(
                  items: [],
                  total: 0,
                  page: 1,
                  pageSize: 50,
                )));
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();
    expect(find.text('No episodes found.'), findsOneWidget);
  });
}
