import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/video_type_model.dart';
import '../../../themes/app_theme.dart';
import '../bloc/exemplar_management_bloc.dart';
import '../bloc/exemplar_management_event.dart';

/// Valid exemplar_kind values for the dropdown.
const _exemplarKinds = ['canonical', 'counter_example', 'edge_case'];

/// Labels for displaying exemplar_kind values.
const _exemplarKindLabels = {
  'canonical': 'Canonical',
  'counter_example': 'Counter Example',
  'edge_case': 'Edge Case',
};

class ExemplarCard extends StatefulWidget {
  final VideoTypeExemplarModel exemplar;
  final String videoTypeId;
  final bool isUpdating;

  const ExemplarCard({
    super.key,
    required this.exemplar,
    required this.videoTypeId,
    this.isUpdating = false,
  });

  @override
  State<ExemplarCard> createState() => _ExemplarCardState();
}

class _ExemplarCardState extends State<ExemplarCard> {
  bool _isEditingWeight = false;
  bool _isEditingNotes = false;
  late TextEditingController _weightController;
  late TextEditingController _notesController;
  String? _weightError;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.exemplar.weight.toStringAsFixed(1),
    );
    _notesController = TextEditingController(
      text: widget.exemplar.notes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ExemplarCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exemplar != widget.exemplar) {
      _weightController.text = widget.exemplar.weight.toStringAsFixed(1);
      _notesController.text = widget.exemplar.notes ?? '';
      _isEditingWeight = false;
      _isEditingNotes = false;
      _weightError = null;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageSection(),
                const SizedBox(height: 8),
                _buildInfoSection(context),
              ],
            ),
          ),
          if (widget.isUpdating)
            const Positioned(
              top: 8,
              right: 8,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: TmzColors.tmzRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final imageUrl = widget.exemplar.imageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(),
          ),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: TmzColors.gray90,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Icon(
            Icons.videocam_outlined,
            size: 32,
            color: TmzColors.gray50,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kind icon
        Icon(
          widget.exemplar.isCanonical
              ? Icons.star
              : widget.exemplar.isCounterExample
                  ? Icons.cancel_outlined
                  : Icons.warning_amber,
          color: widget.exemplar.isCanonical
              ? Colors.amber
              : widget.exemplar.isCounterExample
                  ? TmzColors.error
                  : Colors.orange,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.exemplar.displayName,
                style: TmzTextStyles.bodyBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Metadata row
              Row(
                children: [
                  _buildKindDropdown(context),
                  if (widget.exemplar.jobSource != null) ...[
                    const SizedBox(width: 6),
                    Icon(
                      widget.exemplar.jobSource == 'upload'
                          ? Icons.upload_file
                          : Icons.link,
                      size: 14,
                      color: TmzColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      widget.exemplar.jobSource!,
                      style: TmzTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                  if (widget.exemplar.jobTypeCode != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.exemplar.jobTypeCode!,
                      style: TmzTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: TmzColors.tmzRed,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Weight row
              _buildWeightRow(context),
              // Notes row
              _buildNotesRow(context),
              // Job ID line
              if (widget.exemplar.jobId != widget.exemplar.displayName) ...[
                const SizedBox(height: 2),
                Text(
                  widget.exemplar.jobId,
                  style: TmzTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: TmzColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          tooltip: 'Delete exemplar',
          onPressed: () => _showDeleteDialog(context),
        ),
      ],
    );
  }

  Widget _buildKindDropdown(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: widget.exemplar.exemplarKind,
      onSelected: (newKind) {
        if (newKind != widget.exemplar.exemplarKind) {
          context.read<ExemplarManagementBloc>().add(
                UpdateExemplarEvent(
                  exemplarId: widget.exemplar.id,
                  exemplarKind: newKind,
                ),
              );
        }
      },
      itemBuilder: (_) => _exemplarKinds.map((kind) {
        return PopupMenuItem<String>(
          value: kind,
          child: Text(_exemplarKindLabels[kind] ?? kind),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getKindColor(widget.exemplar.exemplarKind)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _getKindColor(widget.exemplar.exemplarKind)
                .withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.exemplar.exemplarKind.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _getKindColor(widget.exemplar.exemplarKind),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: 14,
              color: _getKindColor(widget.exemplar.exemplarKind),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightRow(BuildContext context) {
    if (_isEditingWeight) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text(
              'Weight: ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(
              width: 80,
              child: TextFormField(
                controller: _weightController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  errorText: _weightError,
                  errorStyle: const TextStyle(fontSize: 10),
                ),
                onFieldSubmitted: (_) => _submitWeight(context),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _submitWeight(context),
              child: const Icon(Icons.check, size: 16, color: TmzColors.success),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => setState(() {
                _isEditingWeight = false;
                _weightError = null;
                _weightController.text =
                    widget.exemplar.weight.toStringAsFixed(1);
              }),
              child: const Icon(Icons.close, size: 16, color: TmzColors.error),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: GestureDetector(
        onTap: () => setState(() => _isEditingWeight = true),
        child: Row(
          children: [
            Text(
              'Weight: ${widget.exemplar.weight.toStringAsFixed(1)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 12, color: TmzColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _submitWeight(BuildContext context) {
    final text = _weightController.text.trim();
    final value = double.tryParse(text);
    if (value == null || value < 0.0 || value > 10.0) {
      setState(() => _weightError = '0.0 - 10.0');
      return;
    }
    if (value == widget.exemplar.weight) {
      setState(() {
        _isEditingWeight = false;
        _weightError = null;
      });
      return;
    }
    setState(() {
      _isEditingWeight = false;
      _weightError = null;
    });
    context.read<ExemplarManagementBloc>().add(
          UpdateExemplarEvent(
            exemplarId: widget.exemplar.id,
            weight: value,
          ),
        );
  }

  Widget _buildNotesRow(BuildContext context) {
    if (_isEditingNotes) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _notesController,
                autofocus: true,
                style: TmzTextStyles.caption.copyWith(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  hintText: 'Add notes...',
                ),
                onFieldSubmitted: (_) => _submitNotes(context),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _submitNotes(context),
              child: const Icon(Icons.check, size: 16, color: TmzColors.success),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => setState(() {
                _isEditingNotes = false;
                _notesController.text = widget.exemplar.notes ?? '';
              }),
              child: const Icon(Icons.close, size: 16, color: TmzColors.error),
            ),
          ],
        ),
      );
    }

    final notes = widget.exemplar.notes;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: GestureDetector(
        onTap: () => setState(() => _isEditingNotes = true),
        child: Row(
          children: [
            Expanded(
              child: Text(
                notes != null && notes.isNotEmpty ? notes : 'No notes',
                style: TmzTextStyles.caption.copyWith(
                  fontSize: 10,
                  color: TmzColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit, size: 12, color: TmzColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _submitNotes(BuildContext context) {
    final newNotes = _notesController.text.trim();
    final oldNotes = widget.exemplar.notes ?? '';
    if (newNotes == oldNotes) {
      setState(() => _isEditingNotes = false);
      return;
    }
    setState(() => _isEditingNotes = false);
    context.read<ExemplarManagementBloc>().add(
          UpdateExemplarEvent(
            exemplarId: widget.exemplar.id,
            notes: newNotes,
          ),
        );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Exemplar?'),
        content: Text(
          'Remove "${widget.exemplar.displayName}" from exemplars? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TmzColors.error),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ExemplarManagementBloc>().add(
                    DeleteExemplarEvent(
                      exemplarId: widget.exemplar.id,
                      videoTypeId: widget.videoTypeId,
                    ),
                  );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getKindColor(String kind) {
    switch (kind) {
      case 'canonical':
        return Colors.amber;
      case 'counter_example':
        return TmzColors.error;
      case 'edge_case':
        return Colors.orange;
      default:
        return TmzColors.gray50;
    }
  }
}
