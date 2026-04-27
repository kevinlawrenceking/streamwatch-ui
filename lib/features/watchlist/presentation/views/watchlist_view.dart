import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../themes/app_theme.dart';
import '../bloc/watchlist_bloc.dart';
import '../widgets/watchlist_change_status_dialog.dart';
import '../widgets/watchlist_create_dialog.dart';
import '../widgets/watchlist_edit_dialog.dart';
import '../widgets/watchlist_entry_card.dart';
import '../widgets/watchlist_status_filter_chip.dart';

/// Top-level Watchlist view -- LSW-016 / WO-078 (Plan-Lock #9 top-level
/// route). Renders the entry list with a status filter chip row and
/// a Create CTA. Mutation dialogs (create / edit / change-status) are
/// modals over this view per Anchor #7.
class WatchlistView extends StatelessWidget {
  const WatchlistView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WatchlistBloc, WatchlistState>(
      listenWhen: (prev, curr) =>
          curr is WatchlistLoaded &&
          (curr.lastActionError != null || curr.lastActionMessage != null),
      listener: (context, state) {
        if (state is! WatchlistLoaded) return;
        if (state.lastActionError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.lastActionError!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<WatchlistBloc>().add(const WatchlistErrorAcknowledged());
        } else if (state.lastActionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.lastActionMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
          context.read<WatchlistBloc>().add(const WatchlistErrorAcknowledged());
        }
      },
      builder: (context, state) {
        if (state is WatchlistInitial || state is WatchlistLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is WatchlistError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context
                .read<WatchlistBloc>()
                .add(const LoadGuestWatchlistEvent()),
          );
        }
        final loaded = state as WatchlistLoaded;
        return Column(
          children: [
            _Header(
              filter: loaded.statusFilter,
              isMutating: loaded.isMutating,
              onFilter: (s) => context
                  .read<WatchlistBloc>()
                  .add(WatchlistFilterChangedEvent(s)),
              onCreate: () => _showCreate(context),
            ),
            Expanded(
              child: loaded.entries.isEmpty
                  ? const Center(child: Text('No watchlist entries.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: loaded.entries.length,
                      itemBuilder: (context, index) {
                        final entry = loaded.entries[index];
                        return WatchlistEntryCard(
                          entry: entry,
                          onEdit: () => showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<WatchlistBloc>(),
                              child: WatchlistEditDialog(entry: entry),
                            ),
                          ),
                          onChangeStatus: () => showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<WatchlistBloc>(),
                              child: WatchlistChangeStatusDialog(entry: entry),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showCreate(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<WatchlistBloc>(),
        child: const WatchlistCreateDialog(),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? filter;
  final bool isMutating;
  final ValueChanged<String?> onFilter;
  final VoidCallback onCreate;

  const _Header({
    required this.filter,
    required this.isMutating,
    required this.onFilter,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: const Border(
          bottom: BorderSide(color: AppColors.textGhost, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: WatchlistStatusFilterChip(
              selected: filter,
              onSelected: onFilter,
            ),
          ),
          const SizedBox(width: 12),
          if (isMutating)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add entry'),
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
