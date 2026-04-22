import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';
import '../constants/report_keys.dart';

/// Single count tile in the scheduler reports row. Tapping navigates to
/// `/scheduler/reports` with the report's key/label/category as Map args.
class ReportCountCard extends StatelessWidget {
  final ReportMeta meta;
  final int? count;
  final bool loading;
  final String? error;

  const ReportCountCard({
    super.key,
    required this.meta,
    this.count,
    this.loading = false,
    this.error,
  });

  void _onTap(BuildContext context) {
    Navigator.of(context).pushNamed(
      '/scheduler/reports',
      arguments: <String, String>{
        'reportKey': meta.key,
        'label': meta.label,
        'category': meta.category,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        margin: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () => _onTap(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(meta.icon, color: meta.color, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        meta.label,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: AppColors.textDim,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildValue(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValue(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (error != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            'Err',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }
    return Text(
      (count ?? 0).toString(),
      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
            color: meta.color,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
