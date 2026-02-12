import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:sangeet/main.dart' show initializeAllServices;

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
  Player? _player;
  VideoController? _controller;
  bool _showSplash = true;
  bool _videoReady = false;
  bool _videoFinished = false;
  bool _isLoading = false;
  Timer? _fallbackTimer;
  StreamSubscription? _playingSubscription;
  StreamSubscription? _completedSubscription;
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    try {
      final player = Player();
      _player = player;
      _controller = VideoController(player);
      _initVideo();
    } catch (e) {
      print('Splash: Player init failed: $e');
      // Video failed — go straight to loading services
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onVideoFinished();
      });
      return;
    }
    
    // Fallback timer in case video fails to load (4 seconds max)
    _fallbackTimer = Timer(const Duration(seconds: 4), () {
      if (!_videoFinished) {
        _onVideoFinished();
      }
    });
  }

  Future<void> _initVideo() async {
    try {
      // Listen for when video actually starts playing (first frame ready)
      _playingSubscription = _player!.stream.playing.listen((playing) {
        if (playing && !_videoReady && mounted) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted && !_videoReady) {
              setState(() {
                _videoReady = true;
              });
            }
          });
        }
      });

      // Listen for video completion — video done, now hold and load services
      _completedSubscription = _player!.stream.completed.listen((completed) {
        if (completed && !_videoFinished) {
          _onVideoFinished();
        }
      });

      // Listen for errors — video failed, go to loading
      _errorSubscription = _player!.stream.error.listen((error) {
        print('Splash video error: $error');
        if (!_videoFinished) {
          _onVideoFinished();
        }
      });

      // Set volume to 0 (splash videos are usually silent)
      await _player!.setVolume(0);

      // Open the video asset and start playing
      await _player!.open(
        Media('asset:///${widget.videoAsset}'),
        play: true,
      );

      // If duration is specified, use timer instead of waiting for video end
      if (widget.duration != null) {
        Timer(widget.duration!, () {
          if (!_videoFinished) {
            _onVideoFinished();
          }
        });
      }
    } catch (e) {
      print('Failed to initialize splash video: $e');
      _onVideoFinished();
    }
  }

  /// Called when video finishes (or fails). Holds on last frame and starts loading services.
  void _onVideoFinished() {
    if (_videoFinished) return;
    _fallbackTimer?.cancel();
    
    if (!mounted) return;
    
    // Cancel stream subscriptions but KEEP player alive to hold last frame
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();
    
    setState(() {
      _videoFinished = true;
      _isLoading = true;
    });
    
    // Now initialize all services while showing the last video frame
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      await initializeAllServices();
    } catch (e) {
      print('Services: Initialization error: $e');
    }
    
    // Services loaded — transition to the main app
    if (mounted) {
      setState(() {
        _showSplash = false;
        _isLoading = false;
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
    _player?.dispose();
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
          // Video player — show when ready, KEEP showing after video ends to hold last frame
          if (_videoReady && _controller != null)
            Center(
              child: Video(
                controller: _controller!,
                fit: BoxFit.cover,
                controls: NoVideoControls,
              ),
            ),
          // Last frame of video stays visible until services finish loading
        ],
      ),
    );
  }
}

/// No controls for splash video
Widget NoVideoControls(VideoState state) {
  return const SizedBox.shrink();
}
