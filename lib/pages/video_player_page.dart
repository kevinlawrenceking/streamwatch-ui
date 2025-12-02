import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerPage({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      // Add listener for play/pause state changes
      _controller.addListener(() {
        if (mounted) {
          final isPlaying = _controller.value.isPlaying;
          if (isPlaying != _isPlaying) {
            setState(() {
              _isPlaying = isPlaying;
            });
          }
        }
      });

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        // Auto-play on load
        _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Color(0xFFE0E0E0)),
        ),
        backgroundColor: const Color(0xFFCE0000),  // TMZ Red
        iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
      ),
      body: Center(
        child: _error != null
            ? _buildErrorWidget()
            : !_isInitialized
                ? const CircularProgressIndicator(
                    color: Color(0xFFCE0000),
                  )
                : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Error loading video',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _error!,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCE0000),
            foregroundColor: const Color(0xFFE0E0E0),
          ),
          child: const Text('Go Back'),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Video player
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              // Play/Pause overlay button
              if (!_isPlaying)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 64,
                    color: Colors.white,
                    icon: const Icon(Icons.play_arrow),
                    onPressed: _togglePlayPause,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFFCE0000),  // TMZ Red
              bufferedColor: Colors.grey,
              backgroundColor: Colors.black26,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Time display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_controller.value.position),
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                _formatDuration(_controller.value.duration),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rewind 10s
            IconButton(
              icon: const Icon(Icons.replay_10),
              color: Colors.white,
              iconSize: 32,
              onPressed: () {
                final newPosition = _controller.value.position - const Duration(seconds: 10);
                _controller.seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
              },
            ),

            const SizedBox(width: 24),

            // Play/Pause
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              color: const Color(0xFFCE0000),  // TMZ Red
              iconSize: 48,
              onPressed: _togglePlayPause,
            ),

            const SizedBox(width: 24),

            // Forward 10s
            IconButton(
              icon: const Icon(Icons.forward_10),
              color: Colors.white,
              iconSize: 32,
              onPressed: () {
                final newPosition = _controller.value.position + const Duration(seconds: 10);
                _controller.seekTo(newPosition < _controller.value.duration ? newPosition : _controller.value.duration);
              },
            ),
          ],
        ),
      ],
    );
  }
}
