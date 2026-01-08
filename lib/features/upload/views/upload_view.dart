import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:file_picker/file_picker.dart';
import '../../../themes/app_theme.dart';
import '../bloc/upload_bloc.dart';

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
      ),
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
                  SegmentedButton<String>(
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
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _uploadMode = newSelection.first;
                      });
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
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: Text(_selectedFileName ?? 'Select Video File'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Selected: $_selectedFileName',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
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
                      helperText: 'Shorter chunks = faster initial results, more updates',
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

                  // Submit button
                  BlocBuilder<UploadBloc, UploadState>(
                    builder: (context, state) {
                      final isSubmitting = state is UploadSubmitting;

                      return ElevatedButton(
                        onPressed: isSubmitting ? null : _submitJob,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
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
}
