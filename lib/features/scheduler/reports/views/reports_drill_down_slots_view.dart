import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../themes/app_theme.dart';
import '../bloc/reported_slots_bloc.dart';
import '../constants/report_keys.dart';
import '../widgets/reported_slot_card.dart';

/// Slot-valued drill-down (expected-today, late). Infinite scroll + pull-to-
/// refresh. No inline actions — slot reports are read-only.
class ReportsDrillDownSlotsView extends StatelessWidget {
  final String reportKey;
  final String label;

  const ReportsDrillDownSlotsView({
    super.key,
    required this.reportKey,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final meta = reportMetaByKey(reportKey);
    final accent = meta?.color ?? AppColors.textDim;

    return BlocBuilder<ReportedSlotsBloc, ReportedSlotsState>(
      builder: (context, state) {
        if (state is ReportedSlotsInitial || state is ReportedSlotsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReportedSlotsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(state.message),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context.read<ReportedSlotsBloc>().add(
                        FetchReportedSlotsEvent(reportKey: reportKey),
                      ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ReportedSlotsLoaded) {
          if (state.slots.isEmpty) {
            return const _EmptyState(label: 'No slots match this report.');
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200 &&
                  state.hasMore) {
                context.read<ReportedSlotsBloc>().add(FetchReportedSlotsEvent(
                      reportKey: reportKey,
                      page: state.currentPage + 1,
                    ));
              }
              return false;
            },
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ReportedSlotsBloc>().add(
                      FetchReportedSlotsEvent(reportKey: reportKey),
                    );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.slots.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.slots.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return ReportedSlotCard(
                    slot: state.slots[index],
                    accentColor: accent,
                  );
                },
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined,
              size: 48, color: AppColors.textGhost),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}
