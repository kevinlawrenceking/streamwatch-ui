import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final ApiService _apiService = ApiService(baseUrl: 'http://localhost:8080');
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _selectedFilePath;
  String? _selectedFileName;
  PlatformFile? _selectedFile;
  String _uploadMode = 'url'; // 'url' or 'file'

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
      withData: kIsWeb, // Load file bytes on web
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

  Future<void> _submitJob() async {
    if (_isLoading) return;

    // Validation
    if (_uploadMode == 'url' && _urlController.text.trim().isEmpty) {
      _showError('Please enter a video URL');
      return;
    }

    if (_uploadMode == 'file' && _selectedFile == null) {
      _showError('Please select a video file');
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;

      if (_uploadMode == 'url') {
        response = await _apiService.createJobFromUrl(
          url: _urlController.text.trim(),
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );
      } else {
        response = await _apiService.createJobFromFile(
          filePath: _selectedFilePath,
          fileBytes: _selectedFile?.bytes,
          fileName: _selectedFileName!,
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        );
      }

      final jobId = response['job_id'];

      if (mounted) {
        // Navigate to job monitoring page
        Navigator.pushNamed(context, '/job', arguments: jobId);
      }
    } catch (e) {
      _showError('Failed to create job: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('StreamWatch - Upload Video'),
        backgroundColor: const Color(0xFFCE0000),  // TMZ Red
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
                  color: Color(0xFFCE0000),  // TMZ Red
                ),
                const SizedBox(height: 16),
                const Text(
                  'Upload Video for Processing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Upload mode selector
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'url',
                      label: Text('URL'),
                      icon: Icon(Icons.link),
                    ),
                    ButtonSegment(
                      value: 'file',
                      label: Text('Upload File'),
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
                      hintText: 'YouTube, Twitter/X, TikTok, Instagram, Vimeo, or direct video URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                      helperText: 'Paste a URL from YouTube, Twitter/X, TikTok, Instagram, Vimeo, Facebook, or a direct video link',
                      helperMaxLines: 2,
                    ),
                    maxLines: 2,
                  ),
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

                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFFCE0000),  // TMZ Red
                    foregroundColor: const Color(0xFFE0E0E0),  // Off-white text
                  ),
                  child: _isLoading
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
                ),

                const SizedBox(height: 16),

                // View recent jobs button
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/jobs');
                  },
                  child: const Text('View Recent Jobs'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
