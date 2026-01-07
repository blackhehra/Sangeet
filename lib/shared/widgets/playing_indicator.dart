import 'package:flutter/material.dart';
import 'package:sangeet/core/theme/app_theme.dart';

/// Animated equalizer bars indicator for currently playing song
class PlayingIndicator extends StatefulWidget {
  final Color? color;
  final double size;
  final bool isPlaying;

  const PlayingIndicator({
    super.key,
    this.color,
    this.size = 14,
    this.isPlaying = true,
  });

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  // Different durations for each bar to create natural look
  static const List<int> _durations = [450, 500, 400, 550];
  // Different height ranges for each bar
  static const List<List<double>> _heightRanges = [
    [0.3, 1.0],
    [0.4, 0.8],
    [0.2, 0.9],
    [0.35, 0.85],
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(4, (index) {
      return AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[index]),
      );
    });

    _animations = List.generate(4, (index) {
      return Tween<double>(
        begin: _heightRanges[index][0],
        end: _heightRanges[index][1],
      ).animate(
        CurvedAnimation(
          parent: _controllers[index],
          curve: Curves.easeInOut,
        ),
      );
    });

    if (widget.isPlaying) {
      _startAnimations();
    }
  }

  void _startAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      // Stagger the start of each bar
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  void _stopAnimations() {
    for (var controller in _controllers) {
      controller.stop();
    }
  }

  @override
  void didUpdateWidget(PlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryColor;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: widget.size / 6,
                height: widget.isPlaying 
                    ? widget.size * _animations[index].value
                    : widget.size * 0.4, // Static height when paused
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.size / 12),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
