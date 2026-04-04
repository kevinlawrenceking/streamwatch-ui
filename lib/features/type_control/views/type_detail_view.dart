import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../data/models/job_model.dart';
import '../../../data/models/video_type_model.dart';
import '../../../data/sources/job_data_source.dart';
import '../../../themes/app_theme.dart';
import '../bloc/candidate_review_bloc.dart';
import '../bloc/candidate_review_event.dart';
import '../bloc/candidate_review_state.dart';
import '../bloc/exemplar_management_bloc.dart';
import '../bloc/exemplar_management_event.dart';
import '../bloc/exemplar_management_state.dart';
import '../widgets/exemplar_card.dart';
import '../bloc/rule_management_bloc.dart';
import '../bloc/rule_management_event.dart';
import '../bloc/rule_management_state.dart';
import '../bloc/type_control_bloc.dart';
import '../bloc/type_control_event.dart';
import '../bloc/type_control_state.dart';

/// Type detail screen with tabs for Versions, Rules, Candidates,
/// Exemplars, and Prompt Preview.
class TypeDetailView extends StatelessWidget {
  final String videoTypeId;

  const TypeDetailView({super.key, required this.videoTypeId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TypeDetailBloc>(
          create: (_) => GetIt.instance<TypeDetailBloc>()
            ..add(SelectTypeEvent(videoTypeId)),
        ),
        BlocProvider<RuleManagementBloc>(
          create: (_) => GetIt.instance<RuleManagementBloc>(),
        ),
        BlocProvider<CandidateReviewBloc>(
          create: (_) => GetIt.instance<CandidateReviewBloc>(),
        ),
        BlocProvider<ExemplarManagementBloc>(
          create: (_) => GetIt.instance<ExemplarManagementBloc>(),
        ),
      ],
      child: _TypeDetailBody(videoTypeId: videoTypeId),
    );
  }
}

class _TypeDetailBody extends StatefulWidget {
  final String videoTypeId;

  const _TypeDetailBody({required this.videoTypeId});

  @override
  State<_TypeDetailBody> createState() => _TypeDetailBodyState();
}

class _TypeDetailBodyState extends State<_TypeDetailBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RuleManagementBloc, RuleManagementState>(
          listener: (context, state) {
            if (state is RuleManagementSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
              // Reload rules for the selected version
              final detailState = context.read<TypeDetailBloc>().state;
              if (detailState is TypeDetailLoaded &&
                  detailState.selectedVersionId != null) {
                context
                    .read<TypeDetailBloc>()
                    .add(LoadRulesEvent(detailState.selectedVersionId!));
              }
            } else if (state is RuleManagementError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BlocListener<CandidateReviewBloc, CandidateReviewState>(
          listener: (context, state) {
            if (state is CandidateReviewError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BlocListener<ExemplarManagementBloc, ExemplarManagementState>(
          listener: (context, state) {
            if (state is ExemplarManagementError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: BlocConsumer<TypeDetailBloc, TypeDetailState>(
        listener: (context, state) {
          if (state is TypeDetailLoaded) {
            if (state.actionError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionError!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state.actionSuccess != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.actionSuccess!),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is TypeDetailLoading) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Type Detail'),
                backgroundColor: AppColors.surfaceElevated,
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is TypeDetailError) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Type Detail'),
                backgroundColor: AppColors.surfaceElevated,
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${state.failure.message}',
                      style: Theme.of(context).textTheme.bodyMedium!
                          .copyWith(color: AppColors.textDim),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('GO BACK'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is TypeDetailLoaded) {
            return Scaffold(
              appBar: AppBar(
                title: Text(state.type.name),
                backgroundColor: AppColors.surfaceElevated,
                bottom: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Versions'),
                    Tab(text: 'Rules'),
                    Tab(text: 'Candidates'),
                    Tab(text: 'Exemplars'),
                    Tab(text: 'Prompt'),
                  ],
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  _VersionsTab(state: state),
                  _RulesTab(
                    state: state,
                    videoTypeId: widget.videoTypeId,
                  ),
                  _CandidatesTab(videoTypeId: widget.videoTypeId),
                  _ExemplarsTab(videoTypeId: widget.videoTypeId),
                  _PromptTab(state: state),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Versions Tab
// ---------------------------------------------------------------------------

class _VersionsTab extends StatelessWidget {
  final TypeDetailLoaded state;

  const _VersionsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.versions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColors.textGhost),
            const SizedBox(height: 16),
            Text(
              'No versions yet',
              style:
                  Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textDim),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.versions.length,
      itemBuilder: (context, index) {
        final version = state.versions[index];
        return _VersionCard(
          version: version,
          videoTypeId: state.type.id,
        );
      },
    );
  }
}

class _VersionCard extends StatelessWidget {
  final VideoTypeVersionModel version;
  final String videoTypeId;

  const _VersionCard({
    required this.version,
    required this.videoTypeId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  version.isActive
                      ? Icons.check_circle
                      : version.isDraft
                          ? Icons.edit
                          : Icons.archive,
                  color: _getVersionStatusColor(version.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Version ${version.versionNumber}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: version.status),
                const Spacer(),
                if (version.isDraft)
                  TextButton.icon(
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text('Activate'),
                    onPressed: () =>
                        _showActivateDialog(context, version, videoTypeId),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (version.definitionJson != null &&
                version.definitionJson!.isNotEmpty) ...[
              Text(
                'Definition',
                style: Theme.of(context).textTheme.bodySmall!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.textGhost),
                ),
                child: _DefinitionFields(
                    definition: version.definitionJson!),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Created: ${_formatDate(version.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall!,
                ),
                const SizedBox(width: 16),
                Text(
                  'Updated: ${_formatDate(version.updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall!,
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.rule, size: 16),
              label: const Text('View Rules'),
              onPressed: () {
                context
                    .read<TypeDetailBloc>()
                    .add(LoadRulesEvent(version.id));
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                textStyle: Theme.of(context).textTheme.bodySmall!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivateDialog(
    BuildContext context,
    VideoTypeVersionModel version,
    String videoTypeId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Activate Version?'),
        content: Text(
          'This will activate Version ${version.versionNumber} and archive '
          'the current active version. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<TypeDetailBloc>().add(
                    ActivateVersionEvent(
                      versionId: version.id,
                      videoTypeId: videoTypeId,
                    ),
                  );
            },
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

}

/// Renders definition_json fields as labeled rows instead of raw JSON.
class _DefinitionFields extends StatelessWidget {
  final Map<String, dynamic> definition;

  const _DefinitionFields({required this.definition});

  @override
  Widget build(BuildContext context) {
    // Known definition fields in display order
    const fieldOrder = [
      'type_code',
      'what_it_is',
      'must_have',
      'must_not_have',
      'may_have',
      'notes',
      'signals',
      'flags',
      'format_guidance',
    ];

    final entries = <MapEntry<String, dynamic>>[];

    // Add known fields in order
    for (final key in fieldOrder) {
      if (definition.containsKey(key) && definition[key] != null) {
        entries.add(MapEntry(key, definition[key]));
      }
    }

    // Add any remaining fields not in the known list
    for (final entry in definition.entries) {
      if (!fieldOrder.contains(entry.key) && entry.value != null) {
        entries.add(entry);
      }
    }

    if (entries.isEmpty) {
      return Text(
        'No definition fields',
        style: Theme.of(context).textTheme.bodySmall!
            .copyWith(color: AppColors.textDim),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          _buildField(context, entries[i].key, entries[i].value),
          if (i < entries.length - 1)
            Divider(color: AppColors.textGhost, height: 8, thickness: 0.5),
        ],
      ],
    );
  }

  Widget _buildField(BuildContext context, String key, dynamic value) {
    final label = _formatLabel(key);

    // Arrays: bulleted list under a bold label
    if (value is List) {
      if (value.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDim,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 3),
            ...value.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(fontSize: 11)),
                      Expanded(
                        child: Text(
                          '$item',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    }

    // Maps: each key-value on its own line, indented under the section label
    if (value is Map) {
      final mapEntries = (value as Map<String, dynamic>)
          .entries
          .where((e) => e.value != null)
          .toList();
      if (mapEntries.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDim,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 3),
            ...mapEntries.map((e) {
              final entryValue = e.value is List
                  ? (e.value as List).join(', ')
                  : '${e.value}';
              return Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatLabel(e.key)}:  ',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entryValue,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    // Scalars: label and value side by side
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:  ',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDim,
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              '$value',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ---------------------------------------------------------------------------
// Rules Tab - enhanced with CRUD + reorder for draft versions
// ---------------------------------------------------------------------------

class _RulesTab extends StatelessWidget {
  final TypeDetailLoaded state;
  final String videoTypeId;

  const _RulesTab({required this.state, required this.videoTypeId});

  @override
  Widget build(BuildContext context) {
    if (state.isRulesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.rules == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rule, size: 64, color: AppColors.textGhost),
            const SizedBox(height: 16),
            Text(
              'Select a version from the Versions tab\nto view its rules',
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textDim),
            ),
          ],
        ),
      );
    }

    // Check if selected version is draft (enable editing)
    final selectedVersion = state.selectedVersionId != null
        ? state.versions
            .where((v) => v.id == state.selectedVersionId)
            .firstOrNull
        : null;
    final isDraft = selectedVersion?.isDraft ?? false;

    if (state.rules!.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rule, size: 64, color: AppColors.textGhost),
                const SizedBox(height: 16),
                Text(
                  'No rules defined for this version',
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: AppColors.textDim),
                ),
              ],
            ),
          ),
          if (isDraft && state.selectedVersionId != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () => _showCreateRuleDialog(
                    context, state.selectedVersionId!),
                child: const Icon(Icons.add),
              ),
            ),
        ],
      );
    }

    return Stack(
      children: [
        ReorderableListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.rules!.length,
          buildDefaultDragHandles: isDraft,
          onReorder: isDraft && state.selectedVersionId != null
              ? (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final ids =
                      state.rules!.map((r) => r.id).toList();
                  final moved = ids.removeAt(oldIndex);
                  ids.insert(newIndex, moved);
                  context.read<RuleManagementBloc>().add(
                        ReorderRulesEvent(
                          versionId: state.selectedVersionId!,
                          orderedRuleIds: ids,
                        ),
                      );
                }
              : (_, __) {},
          itemBuilder: (context, index) {
            final rule = state.rules![index];
            return _RuleCard(
              key: ValueKey(rule.id),
              rule: rule,
              index: index,
              isDraft: isDraft,
            );
          },
        ),
        if (isDraft && state.selectedVersionId != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () => _showCreateRuleDialog(
                  context, state.selectedVersionId!),
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }

  void _showCreateRuleDialog(BuildContext context, String versionId) {
    final textController = TextEditingController();
    final sourceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Rule'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Rule Text *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop();
              context.read<RuleManagementBloc>().add(
                    CreateRuleEvent(
                      versionId: versionId,
                      ruleText: textController.text.trim(),
                      source: sourceController.text.trim().isEmpty
                          ? null
                          : sourceController.text.trim(),
                    ),
                  );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final VideoTypeRuleModel rule;
  final int index;
  final bool isDraft;

  const _RuleCard({
    super.key,
    required this.rule,
    required this.index,
    required this.isDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rule number
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rule.isActive
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.textGhost,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${rule.ruleOrder}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rule.isActive ? AppColors.success : AppColors.textGhost,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rule.ruleText,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: rule.isDeprecated
                          ? TextDecoration.lineThrough
                          : null,
                      color: rule.isDeprecated
                          ? AppColors.textDim
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusChip(status: rule.status),
                      if (rule.source != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Source: ${rule.source}',
                          style: Theme.of(context).textTheme.bodySmall!,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Edit / Deprecate actions (draft only, active rules only)
            if (isDraft && rule.isActive) ...[
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: 'Edit rule',
                onPressed: () => _showEditRuleDialog(context, rule),
              ),
              IconButton(
                icon: const Icon(Icons.block, size: 18),
                tooltip: 'Deprecate rule',
                onPressed: () => _showDeprecateDialog(context, rule),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditRuleDialog(BuildContext context, VideoTypeRuleModel rule) {
    final textController = TextEditingController(text: rule.ruleText);
    final sourceController =
        TextEditingController(text: rule.source ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Rule'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Rule Text *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop();
              context.read<RuleManagementBloc>().add(
                    UpdateRuleEvent(
                      ruleId: rule.id,
                      ruleText: textController.text.trim(),
                      source: sourceController.text.trim().isEmpty
                          ? null
                          : sourceController.text.trim(),
                    ),
                  );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeprecateDialog(BuildContext context, VideoTypeRuleModel rule) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deprecate Rule?'),
        content: Text(
          'This will mark rule #${rule.ruleOrder} as deprecated. '
          'It will appear struck-through and be excluded from prompts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<RuleManagementBloc>()
                  .add(DeprecateRuleEvent(rule.id));
            },
            child: const Text('Deprecate'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Candidates Tab
// ---------------------------------------------------------------------------

class _CandidatesTab extends StatefulWidget {
  final String videoTypeId;

  const _CandidatesTab({required this.videoTypeId});

  @override
  State<_CandidatesTab> createState() => _CandidatesTabState();
}

class _CandidatesTabState extends State<_CandidatesTab> {
  String _statusFilter = 'all';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      context
          .read<CandidateReviewBloc>()
          .add(LoadCandidatesEvent(widget.videoTypeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CandidateReviewBloc, CandidateReviewState>(
      builder: (context, state) {
        if (state is CandidateReviewLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CandidateReviewError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.failure.message}',
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: AppColors.textDim),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context
                      .read<CandidateReviewBloc>()
                      .add(LoadCandidatesEvent(widget.videoTypeId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is CandidateReviewLoaded) {
          final filtered = _statusFilter == 'all'
              ? state.candidates
              : state.candidates
                  .where((c) => c.status == _statusFilter)
                  .toList();

          return Column(
            children: [
              // Filter chips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border(
                    bottom: BorderSide(color: AppColors.textGhost),
                  ),
                ),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pending',
                      selected: _statusFilter == 'pending',
                      onTap: () =>
                          setState(() => _statusFilter = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Approved',
                      selected: _statusFilter == 'approved',
                      onTap: () =>
                          setState(() => _statusFilter = 'approved'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Rejected',
                      selected: _statusFilter == 'rejected',
                      onTap: () =>
                          setState(() => _statusFilter = 'rejected'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Merged',
                      selected: _statusFilter == 'merged',
                      onTap: () =>
                          setState(() => _statusFilter = 'merged'),
                    ),
                    const Spacer(),
                    if (state.isSubmitting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              // Candidate list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _statusFilter == 'all'
                              ? 'No candidates yet'
                              : 'No $_statusFilter candidates',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.textDim),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _CandidateCard(
                            candidate: filtered[index],
                            videoTypeId: widget.videoTypeId,
                          );
                        },
                      ),
              ),
            ],
          );
        }

        // Initial state
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.how_to_vote, size: 64, color: AppColors.textGhost),
              const SizedBox(height: 16),
              Text(
                'Loading candidates...',
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(color: AppColors.textDim),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final VideoTypeRuleCandidateModel candidate;
  final String videoTypeId;

  const _CandidateCard({
    required this.candidate,
    required this.videoTypeId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidate.candidateText,
                    style: Theme.of(context).textTheme.bodyMedium!,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: candidate.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (candidate.source != null)
                  Text(
                    'Source: ${candidate.source}',
                    style: Theme.of(context).textTheme.bodySmall!,
                  ),
                const Spacer(),
                Text(
                  _formatDate(candidate.createdAt),
                  style: Theme.of(context).textTheme.bodySmall!,
                ),
              ],
            ),
            // Action buttons for pending candidates
            if (candidate.isPending) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.success),
                    onPressed: () =>
                        _showApproveDialog(context, candidate, videoTypeId),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.error),
                    onPressed: () =>
                        _showRejectDialog(context, candidate, videoTypeId),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.merge_type, size: 16),
                    label: const Text('Merge'),
                    style:
                        TextButton.styleFrom(foregroundColor: AppColors.warning),
                    onPressed: () =>
                        _showMergeDialog(context, candidate, videoTypeId),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(
    BuildContext context,
    VideoTypeRuleCandidateModel candidate,
    String videoTypeId,
  ) {
    final ruleTextController =
        TextEditingController(text: candidate.candidateText);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Candidate'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will create a new rule from the candidate.'),
              const SizedBox(height: 12),
              TextField(
                controller: ruleTextController,
                decoration: const InputDecoration(
                  labelText: 'Rule Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CandidateReviewBloc>().add(
                    ApproveCandidateEvent(
                      candidateId: candidate.id,
                      videoTypeId: videoTypeId,
                      ruleText: ruleTextController.text.trim().isEmpty
                          ? null
                          : ruleTextController.text.trim(),
                    ),
                  );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    VideoTypeRuleCandidateModel candidate,
    String videoTypeId,
  ) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Candidate'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason *',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop();
              context.read<CandidateReviewBloc>().add(
                    RejectCandidateEvent(
                      candidateId: candidate.id,
                      videoTypeId: videoTypeId,
                      reason: reasonController.text.trim(),
                    ),
                  );
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(
    BuildContext context,
    VideoTypeRuleCandidateModel candidate,
    String videoTypeId,
  ) {
    final targetRuleIdController = TextEditingController();
    final ruleTextController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Merge Candidate'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Merge this candidate into an existing rule.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetRuleIdController,
                decoration: const InputDecoration(
                  labelText: 'Target Rule ID *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ruleTextController,
                decoration: const InputDecoration(
                  labelText: 'Updated Rule Text (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            onPressed: () {
              if (targetRuleIdController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop();
              context.read<CandidateReviewBloc>().add(
                    MergeCandidateEvent(
                      candidateId: candidate.id,
                      videoTypeId: videoTypeId,
                      targetRuleId: targetRuleIdController.text.trim(),
                      ruleText: ruleTextController.text.trim().isEmpty
                          ? null
                          : ruleTextController.text.trim(),
                    ),
                  );
            },
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exemplars Tab
// ---------------------------------------------------------------------------

class _ExemplarsTab extends StatefulWidget {
  final String videoTypeId;

  const _ExemplarsTab({required this.videoTypeId});

  @override
  State<_ExemplarsTab> createState() => _ExemplarsTabState();
}

class _ExemplarsTabState extends State<_ExemplarsTab> {
  String _kindFilter = 'all';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      context
          .read<ExemplarManagementBloc>()
          .add(LoadExemplarsEvent(widget.videoTypeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExemplarManagementBloc, ExemplarManagementState>(
      builder: (context, state) {
        if (state is ExemplarManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ExemplarManagementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.failure.message}',
                  style: Theme.of(context).textTheme.bodyMedium!
                      .copyWith(color: AppColors.textDim),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => context
                      .read<ExemplarManagementBloc>()
                      .add(LoadExemplarsEvent(widget.videoTypeId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is ExemplarManagementLoaded) {
          final filtered = _kindFilter == 'all'
              ? state.exemplars
              : state.exemplars
                  .where((e) => e.exemplarKind == _kindFilter)
                  .toList();

          return Stack(
            children: [
              Column(
                children: [
                  // Filter chips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border(
                        bottom: BorderSide(color: AppColors.textGhost),
                      ),
                    ),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _kindFilter == 'all',
                          onTap: () =>
                              setState(() => _kindFilter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Canonical',
                          selected: _kindFilter == 'canonical',
                          onTap: () =>
                              setState(() => _kindFilter = 'canonical'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Counter',
                          selected: _kindFilter == 'counter_example',
                          onTap: () => setState(
                              () => _kindFilter = 'counter_example'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Edge Case',
                          selected: _kindFilter == 'edge_case',
                          onTap: () =>
                              setState(() => _kindFilter = 'edge_case'),
                        ),
                        const Spacer(),
                        if (state.isSubmitting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  // Exemplar list
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              _kindFilter == 'all'
                                  ? 'No exemplars yet'
                                  : 'No $_kindFilter exemplars',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: AppColors.textDim),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final exemplar = filtered[index];
                              return ExemplarCard(
                                exemplar: exemplar,
                                videoTypeId: widget.videoTypeId,
                                isUpdating: state.updatingExemplarIds
                                    .contains(exemplar.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  onPressed: () => _showBulkCreateDialog(context),
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        }

        // Initial state
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library, size: 64, color: AppColors.textGhost),
              const SizedBox(height: 16),
              Text(
                'Loading exemplars...',
                style: Theme.of(context).textTheme.bodyMedium!
                    .copyWith(color: AppColors.textDim),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBulkCreateDialog(BuildContext context) {
    final searchController = TextEditingController();
    final notesController = TextEditingController();
    String selectedKind = 'canonical';
    List<JobModel> searchResults = [];
    Set<String> selectedJobIds = {};
    bool isSearching = false;
    Timer? debounce;

    final jobDS = GetIt.instance<IJobDataSource>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void doSearch(String query) {
            debounce?.cancel();
            if (query.trim().isEmpty) {
              setDialogState(() {
                searchResults = [];
                isSearching = false;
              });
              return;
            }
            setDialogState(() => isSearching = true);
            debounce = Timer(const Duration(milliseconds: 300), () async {
              final result = await jobDS.getRecentJobs(
                limit: 20,
                status: 'completed',
                searchQuery: query.trim(),
              );
              result.fold(
                (_) => setDialogState(() => isSearching = false),
                (jobs) => setDialogState(() {
                  searchResults = jobs;
                  isSearching = false;
                }),
              );
            });
          }

          return AlertDialog(
            title: const Text('Add Exemplar Jobs'),
            content: SizedBox(
              width: 500,
              height: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search jobs by title or filename',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                          : null,
                    ),
                    onChanged: doSearch,
                  ),
                  // Selected count
                  if (selectedJobIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${selectedJobIds.length} job(s) selected',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: AppColors.tmzRed,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Search results
                  Expanded(
                    child: searchResults.isEmpty &&
                            searchController.text.isEmpty
                        ? Center(
                            child: Text(
                              'Type to search completed jobs',
                              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: AppColors.textDim),
                            ),
                          )
                        : searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  isSearching
                                      ? 'Searching...'
                                      : 'No jobs found',
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: AppColors.textDim),
                                ),
                              )
                            : ListView.builder(
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final job = searchResults[index];
                                  final isSelected = selectedJobIds
                                      .contains(job.jobId);
                                  return CheckboxListTile(
                                    value: isSelected,
                                    dense: true,
                                    title: Text(
                                      job.title ??
                                          job.filename ??
                                          job.jobId,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium!
                                          .copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      '${job.source}  •  ${job.typeCode ?? 'untyped'}  •  ${_formatDate(job.createdAt)}',
                                      style: Theme.of(context).textTheme.bodySmall!,
                                    ),
                                    onChanged: (checked) {
                                      setDialogState(() {
                                        if (checked == true) {
                                          selectedJobIds.add(job.jobId);
                                        } else {
                                          selectedJobIds
                                              .remove(job.jobId);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                  ),
                  const Divider(),
                  // Kind dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedKind,
                    decoration: const InputDecoration(
                      labelText: 'Kind',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'canonical',
                          child: Text('Canonical')),
                      DropdownMenuItem(
                          value: 'counter_example',
                          child: Text('Counter Example')),
                      DropdownMenuItem(
                          value: 'edge_case',
                          child: Text('Edge Case')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedKind = val);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  // Notes
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: selectedJobIds.isEmpty
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        context.read<ExemplarManagementBloc>().add(
                              BulkCreateExemplarsEvent(
                                videoTypeId: widget.videoTypeId,
                                jobIds: selectedJobIds.toList(),
                                exemplarKind: selectedKind,
                                notes:
                                    notesController.text.trim().isEmpty
                                        ? null
                                        : notesController.text.trim(),
                              ),
                            );
                      },
                child: Text(selectedJobIds.isEmpty
                    ? 'Add'
                    : 'Add ${selectedJobIds.length} Job(s)'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Prompt Tab
// ---------------------------------------------------------------------------

class _PromptTab extends StatelessWidget {
  final TypeDetailLoaded state;

  const _PromptTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border(
              bottom: BorderSide(color: AppColors.textGhost),
            ),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Render Prompt'),
                onPressed: state.isPromptLoading
                    ? null
                    : () {
                        context.read<TypeDetailBloc>().add(
                              RenderTypePromptEvent(state.type.id),
                            );
                      },
              ),
              const SizedBox(width: 12),
              if (state.activeVersion != null)
                Text(
                  'Active: v${state.activeVersion!.versionNumber}',
                  style: Theme.of(context).textTheme.bodySmall!,
                ),
              const Spacer(),
              if (state.renderedPrompt != null) ...[
                Icon(
                  state.renderedPrompt!.fromCache
                      ? Icons.cached
                      : Icons.refresh,
                  size: 14,
                  color: AppColors.textDim,
                ),
                const SizedBox(width: 4),
                Text(
                  state.renderedPrompt!.fromCache
                      ? 'From cache'
                      : 'Freshly rendered',
                  style: Theme.of(context).textTheme.bodySmall!,
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy prompt',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: state.renderedPrompt!.prompt),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prompt copied to clipboard'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
              // Rollback button
              if (state.versions
                  .where((v) => v.isArchived)
                  .isNotEmpty) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Rollback'),
                  onPressed: () =>
                      _showRollbackDialog(context, state.type.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Prompt content
        Expanded(
          child: _buildPromptContent(context),
        ),
      ],
    );
  }

  Widget _buildPromptContent(BuildContext context) {
    if (state.isPromptLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.renderedPrompt == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 64, color: AppColors.textGhost),
            const SizedBox(height: 16),
            Text(
              'Click "Render Prompt" to generate\nthe classification prompt',
              textAlign: TextAlign.center,
              style:
                  Theme.of(context).textTheme.bodyMedium!.copyWith(color: AppColors.textDim),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hash info
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.textGhost),
            ),
            child: Row(
              children: [
                const Icon(Icons.fingerprint,
                    size: 14, color: AppColors.textDim),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Hash: ${state.renderedPrompt!.hash.substring(0, 16)}...',
                    style: TmzTextStyles.mono,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Rendered prompt text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.textGhost),
            ),
            child: SelectableText(
              state.renderedPrompt!.prompt,
              style: TmzTextStyles.mono.copyWith(
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRollbackDialog(BuildContext context, String videoTypeId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rollback Version?'),
        content: const Text(
          'This will create a new version from the most recent archived '
          'version and activate it. The current active version will be '
          'archived. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<TypeDetailBloc>()
                  .add(RollbackVersionEvent(videoTypeId));
            },
            child: const Text('Rollback'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getColor(String status) {
    switch (status) {
      case 'active':
      case 'approved':
        return AppColors.success;
      case 'draft':
      case 'pending':
        return AppColors.warning;
      case 'archived':
      case 'deprecated':
      case 'rejected':
        return AppColors.textGhost;
      case 'merged':
        return AppColors.info;
      case 'canonical':
        return AppColors.warning;
      case 'counter example':
        return AppColors.error;
      case 'edge case':
        return AppColors.warning;
      default:
        return AppColors.textGhost;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.success.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? AppColors.success
                : AppColors.textGhost,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? AppColors.success : AppColors.textDim,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _getVersionStatusColor(String status) {
  switch (status) {
    case 'active':
      return AppColors.success;
    case 'draft':
      return AppColors.warning;
    case 'archived':
      return AppColors.textGhost;
    default:
      return AppColors.textGhost;
  }
}

String _formatDate(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
