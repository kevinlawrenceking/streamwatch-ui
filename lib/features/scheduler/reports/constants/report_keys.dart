import 'package:flutter/material.dart';

import '../../../../themes/app_theme.dart';

/// Shape of a report's `items` payload — determines which drill-down view +
/// which bloc is used when navigating to /scheduler/reports.
enum ReportShape { slots, episodes }

/// Static metadata for a single WO-065 report endpoint.
///
/// `key` is the wire-slug (final path segment under /api/v1/reports/) and is
/// treated as the source-of-truth identifier everywhere in the feature —
/// routing args, bloc state, test fixtures. Do not alter.
@immutable
class ReportMeta {
  final String key;
  final String label;
  final String category;
  final Color color;
  final IconData icon;
  final ReportShape shape;

  const ReportMeta({
    required this.key,
    required this.label,
    required this.category,
    required this.color,
    required this.icon,
    required this.shape,
  });
}

/// Full ordered list of the 7 WO-065 reports. Order is display order in the
/// scheduler reports row. Slot-valued reports come first (schedule-oriented),
/// then episode-valued reports (content-pipeline-oriented).
const List<ReportMeta> kReports = <ReportMeta>[
  ReportMeta(
    key: 'expected-today',
    label: 'Expected Today',
    category: 'scheduled',
    color: AppColors.info,
    icon: Icons.today,
    shape: ReportShape.slots,
  ),
  ReportMeta(
    key: 'late',
    label: 'Late',
    category: 'operational',
    color: AppColors.warning,
    icon: Icons.schedule_outlined,
    shape: ReportShape.slots,
  ),
  ReportMeta(
    key: 'recent',
    label: 'Recent',
    category: 'content',
    color: ContentTypeColors.podcast,
    icon: Icons.fiber_new,
    shape: ReportShape.episodes,
  ),
  ReportMeta(
    key: 'transcript-pending',
    label: 'Transcript Pending',
    category: 'pipeline',
    color: ContentTypeColors.interview,
    icon: Icons.subtitles,
    shape: ReportShape.episodes,
  ),
  ReportMeta(
    key: 'headline-ready',
    label: 'Headline Ready',
    category: 'editorial',
    color: ContentTypeColors.documentary,
    icon: Icons.title,
    shape: ReportShape.episodes,
  ),
  ReportMeta(
    key: 'pending-review',
    label: 'Pending Review',
    category: 'editorial-action',
    color: ContentTypeColors.musicVideo,
    icon: Icons.rate_review,
    shape: ReportShape.episodes,
  ),
  ReportMeta(
    key: 'pending-clip-request',
    label: 'Pending Clip Request',
    category: 'clip-queue',
    color: ContentTypeColors.press,
    icon: Icons.content_cut,
    shape: ReportShape.episodes,
  ),
];

/// Lookup a report by its wire-slug. Returns null if unknown.
ReportMeta? reportMetaByKey(String key) {
  for (final r in kReports) {
    if (r.key == key) return r;
  }
  return null;
}
