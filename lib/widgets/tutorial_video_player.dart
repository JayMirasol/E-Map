import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TutorialVideoPlayer extends StatefulWidget {
  final String videoPath;
  final bool autoPlay;

  const TutorialVideoPlayer({
    super.key,
    required this.videoPath,
    this.autoPlay = true,
  });

  @override
  State<TutorialVideoPlayer> createState() => _TutorialVideoPlayerState();
}

class _TutorialVideoPlayerState extends State<TutorialVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(widget.videoPath);
      await _controller.initialize();
      setState(() {
        _isInitialized = true;
      });
      // Auto-play the video if enabled
      if (widget.autoPlay) {
        _controller.play();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 8),
            Text(
              'Unable to load video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Please check that the video file exists in assets/videos/',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 170,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Video player
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Play/Pause button
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                    });
                  },
                ),

                // Progress bar
                Expanded(
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Color(0xFF66BB6A),
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),

                // Time display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),

                // Fullscreen button
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: () {
                    // Navigate to fullscreen player
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            _FullscreenVideoPlayer(controller: _controller),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Fullscreen video player
class _FullscreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenVideoPlayer({required this.controller});

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // Controls overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress bar
                    VideoProgressIndicator(
                      widget.controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFF66BB6A),
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Controls
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            widget.controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              if (widget.controller.value.isPlaying) {
                                widget.controller.pause();
                              } else {
                                widget.controller.play();
                              }
                            });
                          },
                        ),
                        const Spacer(),
                        Text(
                          '${_formatDuration(widget.controller.value.position)} / ${_formatDuration(widget.controller.value.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.fullscreen_exit,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
