import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamwatch_frontend/features/podcasts/data/models/podcast_episode.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/bloc/reported_episodes_bloc.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/views/reports_drill_down_episodes_view.dart';
import 'package:streamwatch_frontend/features/scheduler/reports/widgets/reported_episode_card.dart';
import 'package:streamwatch_frontend/themes/app_theme.dart';

/// Test helper: event that directly swaps in a specific state. Lets widget
/// tests emit state transitions without wiring a real data source.
class _EmitStateEvent extends ReportedEpisodesEvent {
  final ReportedEpisodesState next;
  const _EmitStateEvent(this.next);
  @override
  List<Object?> get props => [next];
}

class FakeReportedEpisodesBloc
    extends Bloc<ReportedEpisodesEvent, ReportedEpisodesState>
    implements ReportedEpisodesBloc {
  FakeReportedEpisodesBloc(super.seed) {
    on<FetchReportedEpisodesEvent>((e, emit) {});
    on<MarkReviewedRequestedEvent>((e, emit) {});
    on<RequestClipRequestedEvent>((e, emit) {});
    on<ActionErrorAcknowledgedEvent>((e, emit) {
      final s = state;
      if (s is ReportedEpisodesLoaded) {
        emit(s.copyWith(clearLastActionError: true));
      }
    });
    on<_EmitStateEvent>((e, emit) => emit(e.next));
  }
}

PodcastEpisodeModel _ep(String id) => PodcastEpisodeModel(
      id: id,
      podcastId: 'p',
      title: 'Episode $id',
      createdAt: DateTime(2026, 4, 20),
      transcriptStatus: 'ready',
      processingStatus: 'transcribed',
    );

Widget _host(ReportedEpisodesState seed, {String reportKey = 'recent'}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: BlocProvider<ReportedEpisodesBloc>(
        create: (_) => FakeReportedEpisodesBloc(seed),
        child: ReportsDrillDownEpisodesView(
          reportKey: reportKey,
          label: 'Recent',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows loading spinner', (tester) async {
    await tester.pumpWidget(_host(const ReportedEpisodesLoading()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders ReportedEpisodeCards for episodes', (tester) async {
    await tester.pumpWidget(_host(ReportedEpisodesLoaded(
      reportKey: 'recent',
      episodes: [_ep('a'), _ep('b')],
      hasMore: false,
    )));
    expect(find.byType(ReportedEpisodeCard), findsNWidgets(2));
  });

  testWidgets('empty state when episodes is empty', (tester) async {
    await tester.pumpWidget(_host(const ReportedEpisodesLoaded(
      reportKey: 'recent',
      episodes: [],
      hasMore: false,
    )));
    expect(find.text('No episodes match this report.'), findsOneWidget);
  });

  testWidgets(
      'surfaces SnackBar when bloc transitions to Loaded with lastActionError',
      (tester) async {
    final seed = ReportedEpisodesLoaded(
      reportKey: 'recent',
      episodes: [_ep('a')],
      hasMore: false,
    );
    await tester.pumpWidget(_host(seed));
    expect(find.text('Mark reviewed failed'), findsNothing);

    // Transition into a state with lastActionError — BlocListener fires here.
    final bloc = tester
        .element(find.byType(ReportsDrillDownEpisodesView))
        .read<ReportedEpisodesBloc>();
    bloc.add(_EmitStateEvent(seed.copyWith(
      lastActionError: 'Mark reviewed failed',
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mark reviewed failed'), findsOneWidget);
  });

  testWidgets('shows error state on ReportedEpisodesError', (tester) async {
    await tester.pumpWidget(_host(const ReportedEpisodesError('network')));
    expect(find.text('network'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
