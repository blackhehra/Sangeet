import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class SplashVideoPage extends StatefulWidget {
  final Widget child;
  final String videoAsset;
  final Duration? duration;
  final VoidCallback? onComplete;

  const SplashVideoPage({
    super.key,
    required this.child,
    this.videoAsset = 'assets/videos/splash.mp4',
    this.duration,
    this.onComplete,
  });

  @override
  State<SplashVideoPage> createState() => _SplashVideoPageState();
}

class _SplashVideoPageState extends State<SplashVideoPage> {
  late final Player _player;
  late final VideoController _controller;
  bool _showSplash = true;
  bool _videoReady = false;
  Timer? _fallbackTimer;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _completedSubscription;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initVideo();
    
    // Fallback timer in case video fails to load (6 seconds max)
    _fallbackTimer = Timer(const Duration(seconds: 6), () {
      if (_showSplash) {
        _onSplashComplete();
      }
    });
  }

  Future<void> _initVideo() async {
    try {
      // Listen for when video actually starts playing (first frame ready)
      _playingSubscription = _player.stream.playing.listen((playing) {
        if (playing && !_videoReady && mounted) {
          // Small delay to ensure first frame is rendered
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && !_videoReady) {
              setState(() {
                _videoReady = true;
              });
            }
          });
        }
      });

      // Listen for video completion
      _completedSubscription = _player.stream.completed.listen((completed) {
        if (completed && _showSplash) {
          _onSplashComplete();
        }
      });

      // Listen for errors
      _errorSubscription = _player.stream.error.listen((error) {
        print('Splash video error: $error');
        if (_showSplash) {
          _onSplashComplete();
        }
      });

      // Set volume to 0 first (splash videos are usually silent)
      await _player.setVolume(0);

      // Open the video asset and start playing
      await _player.open(
        Media('asset:///${widget.videoAsset}'),
        play: true,
      );

      // If duration is specified, use timer instead of waiting for video end
      if (widget.duration != null) {
        Timer(widget.duration!, () {
          if (_showSplash) {
            _onSplashComplete();
          }
        });
      }
    } catch (e) {
      print('Failed to initialize splash video: $e');
      // If video fails, skip splash
      _onSplashComplete();
    }
  }

  void _onSplashComplete() {
    _fallbackTimer?.cancel();
    if (mounted && _showSplash) {
      setState(() {
        _showSplash = false;
      });
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Show app logo while video is loading
          if (!_videoReady)
            Center(
              child: Image.asset(
                'assets/images/ic_launcher.png',
                width: 120,
                height: 120,
              ),
            ),
          // Video player - only show when first frame is ready to avoid stutter
          if (_videoReady)
            Center(
              child: Video(
                controller: _controller,
                fit: BoxFit.cover,
                controls: NoVideoControls,
              ),
            ),
        ],
      ),
    );
  }
}

/// No controls for splash video
Widget NoVideoControls(VideoState state) {
  return const SizedBox.shrink();
}
