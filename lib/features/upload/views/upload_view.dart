import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:file_picker/file_picker.dart';
import '../../../themes/app_theme.dart';
import '../bloc/upload_bloc.dart';

/// Parses celebrity names from input text, handling comma and newline separators.
/// Returns deduplicated list preserving first-seen casing.
/// [input] - Raw text potentially containing multiple names
/// [existing] - Already-added chips to check for duplicates
/// Returns tuple: (new chips to add, duplicate names found)
({List<String> added, List<String> duplicates}) parseCelebrityInput(
  String input,
  List<String> existing,
) {
  // Split on comma or newline, trim whitespace
  final tokens = input
      .split(RegExp(r'[,\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  // Build lowercase set of existing names for dedupe
  final existingLower = existing.map((e) => e.toLowerCase()).toSet();

  final added = <String>[];
  final duplicates = <String>[];
  final seenInBatch = <String>{};

  for (final token in tokens) {
    final lower = token.toLowerCase();
    if (existingLower.contains(lower) || seenInBatch.contains(lower)) {
      duplicates.add(token);
    } else {
      added.add(token);
      seenInBatch.add(lower);
    }
  }

  return (added: added, duplicates: duplicates);
}

/// Upload page using BLoC pattern.
class UploadView extends StatelessWidget {
  const UploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UploadBloc>(
      create: (_) => GetIt.instance<UploadBloc>(),
      child: const _UploadBody(),
    );
  }
}

class _UploadBody extends StatefulWidget {
  const _UploadBody();

  @override
  State<_UploadBody> createState() => _UploadBodyState();
}

class _UploadBodyState extends State<_UploadBody> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _celebrityInputController = TextEditingController();

  /// List of celebrity names as chips (case-preserved, deduplicated)
  List<String> _celebrityChips = [];

  /// Transient message for duplicate feedback
  String? _celebrityFeedback;

  String? _selectedFilePath;
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  String _uploadMode = 'url';
  String _transcriptionEngine = 'aws';
  int _segmentDuration = 180; // Default: 3 minutes
  bool _isLive = false; // Live stream mode
  int _captureSeconds = 900; // Default: 15 minutes

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _celebrityInputController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      setState(() {
        _selectedFile = file;
        _selectedFilePath = kIsWeb ? null : file.path;
        _selectedFileName = file.name;
      });
    }
  }

  void _submitJob() {
    final bloc = context.read<UploadBloc>();
    // Emit celebrities as comma-separated string (existing backend contract)
    final celebritiesValue =
        _celebrityChips.isEmpty ? null : _celebrityChips.join(', ');

    if (_uploadMode == 'url') {
      final url = _urlController.text.trim();
      if (url.isEmpty) {
        _showError('Please enter a video URL');
        return;
      }

      bloc.add(SubmitUrlJobEvent(
        url: url,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        celebrities: celebritiesValue,
        transcriptionEngine: _transcriptionEngine,
        segmentDuration: _segmentDuration,
        isLive: _isLive,
        captureSeconds: _isLive ? _captureSeconds : null,
      ));
    } else {
      if (_selectedFile == null) {
        _showError('Please select a video file');
        return;
      }

      bloc.add(SubmitFileJobEvent(
        filePath: _selectedFilePath,
        fileBytes: _selectedFile?.bytes,
        fileName: _selectedFileName!,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        celebrities: celebritiesValue,
        transcriptionEngine: _transcriptionEngine,
        segmentDuration: _segmentDuration,
      ));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _retryUpload() {
    final bloc = context.read<UploadBloc>();
    bloc.add(const ResetUploadEvent());
  }

  /// Adds celebrity names from the input field to chips.
  /// Handles comma/newline separators and deduplication.
  void _addCelebritiesFromInput() {
    final input = _celebrityInputController.text;
    if (input.trim().isEmpty) return;

    final result = parseCelebrityInput(input, _celebrityChips);

    setState(() {
      _celebrityChips = [..._celebrityChips, ...result.added];
      _celebrityInputController.clear();

      // Show feedback for duplicates
      if (result.duplicates.isNotEmpty) {
        _celebrityFeedback =
            'Duplicate${result.duplicates.length > 1 ? 's' : ''} ignored: ${result.duplicates.join(', ')}';
      } else {
        _celebrityFeedback = null;
      }
    });

    // Clear feedback after 3 seconds
    if (_celebrityFeedback != null) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _celebrityFeedback = null;
          });
        }
      });
    }
  }

  /// Removes a celebrity chip by index.
  void _removeCelebrityChip(int index) {
    setState(() {
      _celebrityChips = List.from(_celebrityChips)..removeAt(index);
      _celebrityFeedback = null;
    });
  }

  /// Builds the celebrity chips input widget.
  Widget _buildCelebrityChipsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Celebrities (optional)',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 8),

        // Chips + input field in a container
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chips wrap
              if (_celebrityChips.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _celebrityChips.asMap().entries.map((entry) {
                    return InputChip(
                      label: Text(entry.value),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeCelebrityChip(entry.key),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              if (_celebrityChips.isNotEmpty) const SizedBox(height: 8),

              // Input field for adding new celebrities
              TextField(
                controller: _celebrityInputController,
                decoration: InputDecoration(
                  hintText: _celebrityChips.isEmpty
                      ? 'Kim Kardashian, Pete Davidson, ...'
                      : 'Add another name...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _addCelebritiesFromInput(),
                onChanged: (value) {
                  // Auto-tokenize on comma or newline
                  if (value.contains(',') || value.contains('\n')) {
                    _addCelebritiesFromInput();
                  }
                },
              ),
            ],
          ),
        ),

        // Helper text
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 12),
          child: Text(
            'Type names and press Enter, or separate with commas. If provided, AI celebrity detection is skipped.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),

        // Feedback message (duplicates)
        if (_celebrityFeedback != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              _celebrityFeedback!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UploadBloc, UploadState>(
      listener: (context, state) {
        if (state is UploadSuccess) {
          Navigator.pushNamed(context, '/job', arguments: state.job.jobId);
        } else if (state is UploadError) {
          _showError('Failed to create job: ${state.failure.message}');
        }
      },
      child: Scaffold(
        appBar: TmzAppBar(
          app: WatchAppIdentity.streamWatch,
          showBackButton: true,
          showHomeButton: true,
          customTitle: 'INGEST',
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Header
                  const Icon(
                    Icons.video_library,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ingest Video for Processing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Ingest mode selector
                  BlocBuilder<UploadBloc, UploadState>(
                    builder: (context, state) {
                      final isUploading = state is UploadSubmitting ||
                          state is FileUploadInProgress;
                      return SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'url',
                            label: Text('URL'),
                            icon: Icon(Icons.link),
                          ),
                          ButtonSegment(
                            value: 'file',
                            label: Text('File'),
                            icon: Icon(Icons.upload_file),
                          ),
                        ],
                        selected: {_uploadMode},
                        onSelectionChanged: isUploading
                            ? null
                            : (Set<String> newSelection) {
                                setState(() {
                                  _uploadMode = newSelection.first;
                                });
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // URL input or file picker
                  if (_uploadMode == 'url') ...[
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Video URL',
                        hintText:
                            'YouTube, Twitter/X, TikTok, Instagram, Vimeo, or direct video URL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                        helperText:
                            'Paste a URL from YouTube, Twitter/X, TikTok, Instagram, Vimeo, Facebook, or a direct video link',
                        helperMaxLines: 2,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Live Stream toggle
                    SwitchListTile(
                      title: const Text('Live Stream'),
                      subtitle: const Text('Record a clip from a live stream'),
                      value: _isLive,
                      onChanged: (value) {
                        setState(() {
                          _isLive = value;
                        });
                      },
                      secondary: const Icon(Icons.live_tv),
                    ),
                    // Capture duration dropdown (only shown when Live Stream is ON)
                    if (_isLive) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _captureSeconds,
                        decoration: const InputDecoration(
                          labelText: 'Capture Duration',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                          helperText: 'How long to record from the live stream',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 300,
                            child: Text('5 minutes'),
                          ),
                          DropdownMenuItem(
                            value: 900,
                            child: Text('15 minutes (default)'),
                          ),
                          DropdownMenuItem(
                            value: 1800,
                            child: Text('30 minutes'),
                          ),
                          DropdownMenuItem(
                            value: 3600,
                            child: Text('60 minutes'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _captureSeconds = value;
                            });
                          }
                        },
                      ),
                    ],
                  ] else ...[
                    BlocBuilder<UploadBloc, UploadState>(
                      builder: (context, state) {
                        final isUploading = state is FileUploadInProgress;
                        return OutlinedButton.icon(
                          onPressed: isUploading ? null : _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: Text(_selectedFileName ?? 'Select Video File'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 8),
                      _buildFileInfo(),
                    ],
                  ],

                  const SizedBox(height: 16),

                  // Title (optional)
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (optional)',
                      hintText: 'My Video Title',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description (optional)
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Video description...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 16),

                  // Celebrities (optional) - Chip input
                  _buildCelebrityChipsInput(),

                  const SizedBox(height: 16),

                  // Transcription Engine selector
                  DropdownButtonFormField<String>(
                    value: _transcriptionEngine,
                    decoration: const InputDecoration(
                      labelText: 'Transcription Engine',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.mic),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'aws',
                        child: Text('AWS Transcribe (Recommended)'),
                      ),
                      DropdownMenuItem(
                        value: 'gemini',
                        child: Text('Google Gemini'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _transcriptionEngine = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  // Chunk Duration selector
                  DropdownButtonFormField<int>(
                    value: _segmentDuration,
                    decoration: const InputDecoration(
                      labelText: 'Chunk Duration',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                      helperText:
                          'Shorter chunks = faster initial results, more updates',
                      helperMaxLines: 2,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 60,
                        child: Text('1 minute (fastest updates)'),
                      ),
                      DropdownMenuItem(
                        value: 180,
                        child: Text('3 minutes (recommended)'),
                      ),
                      DropdownMenuItem(
                        value: 300,
                        child: Text('5 minutes'),
                      ),
                      DropdownMenuItem(
                        value: 600,
                        child: Text('10 minutes'),
                      ),
                      DropdownMenuItem(
                        value: 900,
                        child: Text('15 minutes'),
                      ),
                      DropdownMenuItem(
                        value: 1800,
                        child: Text('30 minutes'),
                      ),
                      DropdownMenuItem(
                        value: 3600,
                        child: Text('1 hour'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _segmentDuration = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 32),

                  // Upload progress indicator for file uploads
                  BlocBuilder<UploadBloc, UploadState>(
                    builder: (context, state) {
                      if (state is FileUploadInProgress) {
                        return _buildUploadProgress(state);
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Submit button
                  BlocBuilder<UploadBloc, UploadState>(
                    builder: (context, state) {
                      final isSubmitting = state is UploadSubmitting;
                      final uploadProgress = state is FileUploadInProgress ? state : null;
                      final isUploading = uploadProgress != null;
                      final isError = state is UploadError;

                      if (isError && state.canRetry) {
                        return Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _retryUpload,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${state.failure.message}',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }

                      return ElevatedButton(
                        onPressed:
                            (isSubmitting || isUploading) ? null : _submitJob,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        child: (isSubmitting || isUploading)
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (uploadProgress != null) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      uploadProgress.statusMessage,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ],
                              )
                            : const Text(
                                'Start Processing',
                                style: TextStyle(fontSize: 16),
                              ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build file info display with size.
  Widget _buildFileInfo() {
    final file = _selectedFile;
    if (file == null) return const SizedBox.shrink();

    final sizeInMB = (file.size / (1024 * 1024)).toStringAsFixed(1);
    final isLarge = file.size > 10 * 1024 * 1024; // >10MB

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected: $_selectedFileName',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isLarge ? Icons.cloud_upload : Icons.upload_file,
              size: 16,
              color: isLarge ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '$sizeInMB MB${isLarge ? ' (direct S3 upload)' : ''}',
              style: TextStyle(
                color: isLarge ? Colors.blue : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build upload progress indicator.
  Widget _buildUploadProgress(FileUploadInProgress state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPhaseIcon(state.phase),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.statusMessage,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    if (state.uploadId != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Upload ID: ${state.uploadId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (state.phase == UploadPhase.uploadingToS3 &&
              state.totalBytes != null &&
              state.totalBytes! > 0) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: state.bytesUploaded != null
                  ? state.bytesUploaded! / state.totalBytes!
                  : null,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
          const SizedBox(height: 8),
          _buildPhaseSteps(state.phase),
        ],
      ),
    );
  }

  Widget _buildPhaseIcon(UploadPhase phase) {
    IconData icon;
    Color color;

    switch (phase) {
      case UploadPhase.requestingPresign:
        icon = Icons.security;
        color = Colors.orange;
        break;
      case UploadPhase.uploadingToS3:
        icon = Icons.cloud_upload;
        color = Colors.blue;
        break;
      case UploadPhase.finalizing:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildPhaseSteps(UploadPhase currentPhase) {
    return Row(
      children: [
        _buildStepIndicator(
          'Prepare',
          currentPhase.index >= UploadPhase.requestingPresign.index,
          currentPhase == UploadPhase.requestingPresign,
        ),
        Expanded(child: _buildStepLine(currentPhase.index > 0)),
        _buildStepIndicator(
          'Upload',
          currentPhase.index >= UploadPhase.uploadingToS3.index,
          currentPhase == UploadPhase.uploadingToS3,
        ),
        Expanded(child: _buildStepLine(currentPhase.index > 1)),
        _buildStepIndicator(
          'Finalize',
          currentPhase.index >= UploadPhase.finalizing.index,
          currentPhase == UploadPhase.finalizing,
        ),
      ],
    );
  }

  Widget _buildStepIndicator(String label, bool completed, bool active) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? AppColors.primary : Colors.grey[300],
            border: active
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: completed
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: completed ? AppColors.primary : Colors.grey[600],
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool completed) {
    return Container(
      height: 2,
      color: completed ? AppColors.primary : Colors.grey[300],
    );
  }
}
