# StreamWatch Ingest Flow

Technical documentation for the video ingest process in the StreamWatch Flutter UI.

## Overview

The ingest flow allows users to submit videos for transcription and AI processing. Videos can be ingested via:
1. **URL** - YouTube, Twitter/X, TikTok, Instagram, Vimeo, Facebook, or direct video links
2. **File Upload** - Direct file upload with presigned S3 URLs

## Architecture

```
┌─────────────────┐     ┌─────────────┐     ┌─────────────┐
│   UploadView    │────▶│  UploadBloc │────▶│ DataSource  │
│  (UI + State)   │◀────│  (Events)   │◀────│  (REST/S3)  │
└─────────────────┘     └─────────────┘     └─────────────┘
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/features/upload/views/upload_view.dart` | Main ingest UI |
| `lib/features/upload/bloc/upload_bloc.dart` | Business logic |
| `lib/features/upload/bloc/upload_event.dart` | BLoC events |
| `lib/features/upload/bloc/upload_state.dart` | BLoC states |
| `lib/data/sources/upload_data_source.dart` | API calls |

## File Upload Flow

### 1. File Selection

When a user clicks "Select Video File", the `_pickFile()` method is called:

```dart
Future<void> _pickFile() async {
  setState(() => _isPickingFile = true);  // Show loading immediately

  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: kIsWeb,  // Load bytes on web platform
    );
    // ... handle result
  } finally {
    setState(() => _isPickingFile = false);
  }
}
```

**Important:** On web, `withData: kIsWeb` causes the file picker to read the entire file into memory before returning. For large video files (100MB+), this can take 5-20 seconds. The `_isPickingFile` state provides visual feedback during this delay.

### 2. Form Submission

When the user clicks "Start Processing", `SubmitFileJobEvent` is emitted:

```dart
bloc.add(SubmitFileJobEvent(
  filePath: _selectedFilePath,
  fileBytes: _selectedFile?.bytes,
  fileName: _selectedFileName!,
  title: ...,
  description: ...,
  celebrities: ...,           // Optional: comma-separated names
  transcriptionEngine: ...,   // 'aws' or 'gemini'
  segmentDuration: ...,       // Chunk duration in seconds
));
```

### 3. Presigned S3 Upload

The BLoC handles the three-phase upload:

```
Phase 1: Request Presigned URL (UploadPhase.requestingPresign)
    ↓
    POST /api/v1/uploads/presign
    Response: { upload_id, presigned_url, s3_key }
    ↓
Phase 2: Upload to S3 (UploadPhase.uploadingToS3)
    ↓
    PUT {presigned_url} with file bytes
    ↓
Phase 3: Finalize (UploadPhase.finalizing)
    ↓
    POST /api/v1/uploads/complete
    Response: { job_id, status, ... }
    ↓
Navigate to Job Detail
```

### 4. Progress States

The `FileUploadInProgress` state tracks:
- `phase` - Current upload phase (enum)
- `uploadId` - Server-assigned upload ID
- `bytesUploaded` - Progress for S3 upload
- `totalBytes` - Total file size
- `statusMessage` - Human-readable status

## URL Ingest Flow

URL ingestion is simpler - a single API call:

```dart
bloc.add(SubmitUrlJobEvent(
  url: url,
  title: ...,
  description: ...,
  celebrities: ...,
  transcriptionEngine: ...,
  segmentDuration: ...,
  isLive: ...,          // Live stream mode
  captureSeconds: ...,  // Duration for live capture
));
```

This calls `POST /api/v1/jobs` with the URL. The worker handles downloading.

## Form Fields

| Field | Required | Description |
|-------|----------|-------------|
| URL/File | Yes | Video source |
| Title | No | Custom title (defaults to filename or URL-derived) |
| Description | No | Video description |
| Celebrities | No | Manual celebrity list (skips AI detection) |
| Transcription Engine | Yes | AWS Transcribe (default) or Gemini |
| Chunk Duration | Yes | Segment length for processing (default 3 min) |
| Live Stream | No | Enable live capture mode (URL only) |
| Capture Duration | If Live | How long to record live stream |

## Celebrity Input

The celebrity field uses a chip/tag input pattern:
- Enter names separated by commas or newlines
- Press Enter to add chips
- Click X to remove chips
- Duplicates are detected and rejected (case-insensitive)
- If celebrities are provided, AI celebrity detection is skipped

## Error Handling

The BLoC emits `UploadError` state with:
- `failure` - Error details
- `canRetry` - Whether retry is available

Retryable errors show a "Try Again" button that emits `ResetUploadEvent`.

## Known Issues & Fixes

### File Picker Delay (Fixed)

**Problem:** After selecting a file, the UI appeared frozen for 5-20 seconds.

**Cause:** `withData: kIsWeb` reads the entire file into memory before returning.

**Fix:** Added `_isPickingFile` state to show loading indicator during file read.

```dart
// Before: No feedback during file load
await FilePicker.platform.pickFiles(...);

// After: Immediate feedback
setState(() => _isPickingFile = true);
try {
  await FilePicker.platform.pickFiles(...);
} finally {
  setState(() => _isPickingFile = false);
}
```

The button now shows a spinner and "Loading file..." text during the delay.
