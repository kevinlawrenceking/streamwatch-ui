import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/job.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_page.dart';

class JobDetailPage extends StatefulWidget {
  final String jobId;

  const JobDetailPage({super.key, required this.jobId});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  final ApiService _apiService = ApiService();

  Job? _job;
  List<Chunk> _chunks = [];
  WebSocketChannel? _channel;
  bool _isLoading = true;
  String? _error;
  final List<Map<String, dynamic>> _events = [];

  // Streaming summary state
  String? _streamingSummary;
  int _segmentsCompleted = 0;
  int _segmentsTotal = 0;
  bool _summaryIsFinal = false;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _loadJobDetails() async {
    try {
      final jobData = await _apiService.getJob(widget.jobId);
      final chunksData = await _apiService.getJobChunks(widget.jobId);

      setState(() {
        _job = Job.fromJson(jobData);
        _chunks = chunksData.map((c) => Chunk.fromJson(c)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _connectWebSocket() {
    final wsUrl = _apiService.getWebSocketUrl(widget.jobId);
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _channel!.stream.listen(
      (message) {
        final event = jsonDecode(message);
        _handleWebSocketEvent(event);
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
      },
      onDone: () {
        debugPrint('WebSocket closed');
      },
    );
  }

  void _handleWebSocketEvent(Map<String, dynamic> event) {
    setState(() {
      _events.insert(0, event);
    });

    final type = event['type'];
    final payload = event['payload'] ?? <String, dynamic>{};

    switch (type) {
      // Progress updates
      case 'job_started':
      case 'job_update':
      case 'transcription_started':
      case 'transcription_progress':
      case 'metadata_ready':
        _updateJobStatus(payload);
        break;

      // Chunk completed - add new segment in real-time
      case 'chunk_completed':
        _addChunkFromEvent(payload);
        break;

      // Summary updates (streaming)
      case 'summarization_started':
      case 'summarization_completed':
        _updateStreamingSummary(payload);
        break;

      // Job completed
      case 'job_completed':
        _updateJobStatus({'status': 'completed', 'progress_pct': 100});
        // Mark summary as final when job completes
        setState(() {
          _summaryIsFinal = true;
        });
        // Reload final data to ensure we have everything
        _loadJobDetails();
        break;

      // Job failed
      case 'job_failed':
        _showError(payload['error_message'] ?? 'Job failed');
        break;

      // Legacy event names (for backwards compatibility)
      case 'job.update':
        _updateJobStatus(payload);
        break;
      case 'chunk.ready':
        _addChunk(payload);
        break;
      case 'job.done':
        _updateJobStatus({'status': 'completed', 'progress_pct': 100});
        setState(() {
          _summaryIsFinal = true;
        });
        _loadJobDetails();
        break;
      case 'error':
        _showError(payload['message'] ?? 'Unknown error');
        break;
    }
  }

  void _updateJobStatus(Map<String, dynamic> payload) {
    if (_job == null) return;

    setState(() {
      _job = Job(
        jobId: _job!.jobId,
        source: _job!.source,
        sourceUrl: _job!.sourceUrl,
        sourceProvider: _job!.sourceProvider,
        filePath: _job!.filePath,
        title: _job!.title,
        description: _job!.description,
        status: payload['status'] ?? _job!.status,
        progressPct: payload['progress_pct'] ?? _job!.progressPct,
        completedChunks: payload['completed_chunks'] ?? _job!.completedChunks,
        errorMessage: _job!.errorMessage,
        finalSummary: _job!.finalSummary,
        summaryText: _job!.summaryText,
        fullTranscript: _job!.fullTranscript,
        transcriptFinal: _job!.transcriptFinal,
        createdAt: _job!.createdAt,
        startedAt: _job!.startedAt,
        completedAt: _job!.completedAt,
      );
    });
  }

  Future<void> _addChunk(Map<String, dynamic> payload) async {
    // Reload from API to get the complete chunk with all fields
    debugPrint('chunk.ready event received, reloading chunks...');
    try {
      final chunksData = await _apiService.getJobChunks(widget.jobId);
      debugPrint('API returned ${chunksData.length} chunks');

      if (mounted) {
        setState(() {
          _chunks = chunksData.map((c) => Chunk.fromJson(c)).toList();
        });
        debugPrint('UI updated with ${_chunks.length} chunks');
      }
    } catch (e) {
      debugPrint('Error loading chunks: $e');
    }
  }

  void _addChunkFromEvent(Map<String, dynamic> payload) {
    // Create chunk directly from WebSocket event for instant UI update
    debugPrint('chunk_completed event received: $payload');

    final chunkIndex = payload['chunk_index'] as int? ?? _chunks.length;
    final chunkId = payload['chunk_id'] as String? ?? '${widget.jobId}_C_${chunkIndex.toString().padLeft(4, '0')}';
    final startMs = payload['start_ms'] as int? ?? 0;
    final endMs = payload['end_ms'] as int? ?? 0;
    final transcript = payload['transcript'] as String?;
    final summary = payload['summary'] as String?;

    // Create new chunk from event data
    final newChunk = Chunk(
      chunkId: chunkId,
      jobId: widget.jobId,
      orderNo: chunkIndex + 1,
      startMs: startMs,
      endMs: endMs,
      transcript: transcript,
      summary: summary,
      createdAt: DateTime.now(),
    );

    setState(() {
      // Check if chunk already exists (by chunkId)
      final existingIndex = _chunks.indexWhere((c) => c.chunkId == chunkId);
      if (existingIndex >= 0) {
        // Update existing chunk
        _chunks[existingIndex] = newChunk;
        debugPrint('Updated existing chunk at index $existingIndex');
      } else {
        // Add new chunk
        _chunks.add(newChunk);
        // Sort by orderNo to maintain correct order
        _chunks.sort((a, b) => a.orderNo.compareTo(b.orderNo));
        debugPrint('Added new chunk, total: ${_chunks.length}');
      }
    });

    // Update job progress if provided
    final progressPct = payload['progress_pct'] as int?;
    if (progressPct != null && _job != null) {
      _updateJobStatus({'progress_pct': progressPct, 'completed_chunks': _chunks.length});
    }
  }

  void _updateStreamingSummary(Map<String, dynamic> payload) {
    debugPrint('summarization event received: $payload');
    setState(() {
      // Handle both legacy and new payload formats
      _streamingSummary = payload['summary_text'] as String? ??
                          payload['summary'] as String? ??
                          _streamingSummary;
      _segmentsCompleted = payload['segments_completed'] as int? ??
                           payload['completed_chunks'] as int? ??
                           _chunks.length;
      _segmentsTotal = payload['segments_total'] as int? ??
                       payload['estimated_chunks'] as int? ??
                       _segmentsTotal;
      _summaryIsFinal = payload['is_final'] as bool? ?? false;
    });
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
        title: Text(
          _job?.title ?? 'Job ${widget.jobId}',
          style: const TextStyle(color: Color(0xFFE0E0E0)),
        ),
        backgroundColor: const Color(0xFFCE0000),  // TMZ Red
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _loadJobDetails();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildJobInfoCard(),
                      const SizedBox(height: 16),
                      _buildProgressCard(),
                      const SizedBox(height: 16),
                      // Show streaming summary while processing
                      if (_job!.isProcessing && _streamingSummary != null) ...[
                        _buildStreamingSummarySection(),
                        const SizedBox(height: 16),
                      ],
                      if (_job!.isCompleted) ...[
                        _buildFinalSummarySection(),
                        const SizedBox(height: 16),
                        _buildDownloadsSection(),
                        const SizedBox(height: 16),
                        _buildFullTranscriptSection(),
                        const SizedBox(height: 16),
                      ],
                      _buildChunksSection(),
                      const SizedBox(height: 16),
                      _buildEventsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildJobInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildInfoRow('Job ID', _job!.jobId),
            _buildInfoRow('Source', _job!.source.toUpperCase()),
            if (_job!.sourceUrl != null)
              _buildInfoRow('URL', _job!.sourceUrl!, isUrl: true),
            if (_job!.sourceProvider != null)
              _buildProviderRow('Platform', _job!.sourceProvider!),
            if (_job!.description != null)
              _buildInfoRow('Description', _job!.description!),
            _buildInfoRow('Created', _formatDateTime(_job!.createdAt)),
            if (_job!.startedAt != null)
              _buildInfoRow('Started', _formatDateTime(_job!.startedAt!)),
            if (_job!.completedAt != null)
              _buildInfoRow('Completed', _formatDateTime(_job!.completedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _buildStatusChip(_job!.status),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _job!.progressPct / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _job!.isFailed ? Colors.red : const Color(0xFFCE0000),  // TMZ Red
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_job!.progressPct}%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_job!.completedChunks} segments processed',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChunksSection() {
    if (_chunks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No segments available yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Processed Segments (${_chunks.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            ..._chunks.map((chunk) => _buildChunkTile(chunk)),
          ],
        ),
      ),
    );
  }

  Widget _buildChunkTile(Chunk chunk) {
    final thumbnailUrl = _apiService.getChunkThumbnailUrl(widget.jobId, chunk.chunkId);

    return ExpansionTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 80,
          height: 45,
          child: Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.videocam,
                  size: 24,
                  color: Colors.grey[500],
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      title: Text('Segment ${chunk.orderNo}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chunk.formattedTimeRange,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if (chunk.summary != null) ...[
            const SizedBox(height: 4),
            Text(
              chunk.summary!,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      children: [
        if (chunk.transcript != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transcript:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(chunk.transcript!),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEventsSection() {
    if (_events.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Real-time Events',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _events.length > 10 ? 10 : _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(_getEventIcon(event['type']), size: 20),
                    title: Text(event['type']),
                    subtitle: Text(
                      event['payload'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isUrl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isUrl ? const Color(0xFFCE0000) : null,  // TMZ Red
                decoration: isUrl ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderRow(String label, String provider) {
    // Map providers to display names
    final Map<String, String> providerNames = {
      'youtube': 'YouTube',
      'twitter': 'Twitter/X',
      'tiktok': 'TikTok',
      'instagram': 'Instagram',
      'vimeo': 'Vimeo',
      'facebook': 'Facebook',
    };

    final displayName = providerNames[provider.toLowerCase()] ?? provider;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Chip(
              label: Text(displayName),
              avatar: const Icon(Icons.play_circle, size: 18),
              backgroundColor: const Color(0xFFCE0000).withOpacity(0.1),  // TMZ Red
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCE0000)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Live Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('$_segmentsCompleted/$_segmentsTotal segments'),
                  backgroundColor: const Color(0xFFCE0000).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: Color(0xFFCE0000),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _streamingSummary ?? 'Generating summary...',
                key: ValueKey(_streamingSummary),
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Summary updates as more content is processed...',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalSummarySection() {
    if (_job?.summaryText == null || _job!.summaryText!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Final Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            Text(
              _job!.summaryText!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullTranscriptSection() {
    // Show nothing if no transcripts exist
    if ((_job?.fullTranscript == null || _job!.fullTranscript!.isEmpty) &&
        (_job?.transcriptFinal == null || _job!.transcriptFinal!.isEmpty)) {
      return const SizedBox.shrink();
    }

    // Prefer cleaned transcript over raw
    final hasCleanedTranscript = _job?.transcriptFinal != null && _job!.transcriptFinal!.isNotEmpty;
    final transcriptToShow = hasCleanedTranscript ? _job!.transcriptFinal! : _job!.fullTranscript!;
    final transcriptLabel = hasCleanedTranscript ? 'Cleaned Transcript' : 'Full Transcript (Raw)';
    final transcriptIcon = hasCleanedTranscript ? Icons.auto_fix_high : Icons.description;
    final transcriptColor = hasCleanedTranscript ? Colors.green : const Color(0xFFCE0000);  // TMZ Red

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(transcriptIcon, color: transcriptColor),
                const SizedBox(width: 8),
                Text(
                  transcriptLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (hasCleanedTranscript) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('AI Cleaned'),
                    backgroundColor: Colors.green.withOpacity(0.2),
                    labelStyle: const TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
              ],
            ),
            const Divider(),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Text(
                  transcriptToShow,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'processing':
        color = const Color(0xFFCE0000);  // TMZ Red
        break;
      case 'failed':
        color = Colors.red;
        break;
      case 'queued':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'job_started':
        return Icons.play_arrow;
      case 'job_update':
      case 'job.update':
        return Icons.update;
      case 'metadata_ready':
        return Icons.info_outline;
      case 'transcription_started':
        return Icons.mic;
      case 'transcription_progress':
        return Icons.hearing;
      case 'transcription_completed':
        return Icons.mic_none;
      case 'chunk_completed':
      case 'chunk.ready':
        return Icons.check_circle;
      case 'summarization_started':
        return Icons.auto_awesome;
      case 'summarization_completed':
        return Icons.summarize;
      case 'thumbnail_ready':
        return Icons.image;
      case 'job_completed':
      case 'job.done':
        return Icons.done_all;
      case 'job_failed':
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDownloadsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download, color: Color(0xFFCE0000)),  // TMZ Red
                const SizedBox(width: 8),
                Text(
                  'Downloads & Media',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),

            // Download Transcript
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Download Transcript'),
              subtitle: const Text('AI-cleaned full transcript'),
              trailing: const Icon(Icons.download_outlined),
              onTap: () => _launchUrl(_apiService.getTranscriptDownloadUrl(widget.jobId)),
            ),

            // Download Summary
            ListTile(
              leading: const Icon(Icons.summarize),
              title: const Text('Download Summary'),
              subtitle: const Text('Full video summary'),
              trailing: const Icon(Icons.download_outlined),
              onTap: () => _launchUrl(_apiService.getSummaryDownloadUrl(widget.jobId)),
            ),

            // Play Video
            ListTile(
              leading: const Icon(Icons.play_circle_filled, color: Color(0xFFCE0000)),  // TMZ Red
              title: const Text('Play Video'),
              subtitle: const Text('Watch in player'),
              trailing: const Icon(Icons.play_arrow),
              onTap: _openVideoPlayer,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open download'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openVideoPlayer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          videoUrl: _apiService.getVideoStreamUrl(widget.jobId),
          title: _job?.title ?? 'Video Playback',
        ),
      ),
    );
  }
}
