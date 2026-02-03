class Job {
  final String jobId;
  final String source;
  final String? sourceUrl;
  final String? sourceProvider;  // Provider (youtube, twitter, etc.) if resolved via yt-dlp
  final String? filePath;
  final String? title;
  final String? description;
  final String status;
  final int progressPct;
  final int completedChunks;
  final String? errorMessage;
  final String? finalSummary;     // JSON string
  final String? summaryText;      // Plain text readable summary
  final String? fullTranscript;   // Raw concatenated transcript
  final String? transcriptFinal;  // Cleaned transcript after LLM cleanup
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Speaker resolution fields
  final int? speakerCount;        // Number of detected speakers
  final bool speakersResolved;    // Whether speakers have been resolved to names

  Job({
    required this.jobId,
    required this.source,
    this.sourceUrl,
    this.sourceProvider,
    this.filePath,
    this.title,
    this.description,
    required this.status,
    required this.progressPct,
    required this.completedChunks,
    this.errorMessage,
    this.finalSummary,
    this.summaryText,
    this.fullTranscript,
    this.transcriptFinal,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.speakerCount,
    this.speakersResolved = false,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['job_id'],
      source: json['source'],
      sourceUrl: json['source_url'],
      sourceProvider: json['source_provider'],
      filePath: json['file_path'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      progressPct: json['progress_pct'] ?? 0,
      completedChunks: json['completed_chunks'] ?? 0,
      errorMessage: json['error_message'],
      finalSummary: json['final_summary'],
      summaryText: json['summary_text'],
      fullTranscript: json['full_transcript'],
      transcriptFinal: json['transcript_final'],
      createdAt: DateTime.parse(json['created_at']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      speakerCount: json['speaker_count'],
      speakersResolved: json['speakers_resolved'] ?? false,
    );
  }

  bool get isQueued => status == 'queued';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isCancelled => status == 'cancelled';

  /// Whether this job has speaker diarization data available
  bool get hasSpeakers => speakerCount != null && speakerCount! > 0;
}

class Chunk {
  final String chunkId;
  final String jobId;
  final int orderNo;
  final int startMs;
  final int endMs;
  final String? transcript;
  final String? summary;
  final String? speakersJson;  // JSON array of speaker segments from AWS Transcribe
  final DateTime createdAt;

  Chunk({
    required this.chunkId,
    required this.jobId,
    required this.orderNo,
    required this.startMs,
    required this.endMs,
    this.transcript,
    this.summary,
    this.speakersJson,
    required this.createdAt,
  });

  factory Chunk.fromJson(Map<String, dynamic> json) {
    return Chunk(
      chunkId: json['chunk_id'],
      jobId: json['job_id'],
      orderNo: json['index'] ?? 0,  // Go API returns 'index', not 'order_no'
      startMs: json['start_ms'] ?? 0,
      endMs: json['end_ms'] ?? 0,
      transcript: json['transcript'],
      summary: json['summary'],
      speakersJson: json['speakers_json'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Whether this chunk has speaker diarization data
  bool get hasSpeakers => speakersJson != null && speakersJson!.isNotEmpty;

  Duration get startTime => Duration(milliseconds: startMs);
  Duration get endTime => Duration(milliseconds: endMs);
  Duration get duration => Duration(milliseconds: endMs - startMs);

  String get formattedTimeRange {
    return '${_formatDuration(startTime)} - ${_formatDuration(endTime)}';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
