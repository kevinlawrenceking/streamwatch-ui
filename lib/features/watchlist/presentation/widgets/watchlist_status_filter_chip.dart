import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';

/// Filter chip row for the watchlist view: All / Active / Matched / Expired.
class WatchlistStatusFilterChip extends StatelessWidget {
  final String? selected; // null = All
  final ValueChanged<String?> onSelected;

  const WatchlistStatusFilterChip({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final entries = <_FilterEntry>[
      const _FilterEntry(label: 'All', value: null),
      const _FilterEntry(label: 'Active', value: 'active'),
      const _FilterEntry(label: 'Matched', value: 'matched'),
      const _FilterEntry(label: 'Expired', value: 'expired'),
    ];
    return Wrap(
      spacing: 8,
      children: entries.map((e) {
        final isSelected = selected == e.value;
        return FilterChip(
          label: Text(e.label),
          selected: isSelected,
          onSelected: (_) => onSelected(e.value),
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor: AppColors.surfaceElevated,
        );
      }).toList(),
    );
  }
}

class _FilterEntry {
  final String label;
  final String? value;
  const _FilterEntry({required this.label, required this.value});
}
