import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sangeet/core/theme/app_theme.dart';

/// Animated equalizer bars indicator for currently playing song
/// Uses a single AnimationController with sin() phase offsets for efficiency
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Phase offsets for each bar to create natural look
  static const List<double> _phaseOffsets = [0.0, 1.2, 2.5, 3.8];
  // Speed multipliers for each bar
  static const List<double> _speeds = [1.0, 1.3, 0.9, 1.15];
  // Height ranges [min, max] for each bar
  static const List<List<double>> _heightRanges = [
    [0.3, 1.0],
    [0.4, 0.8],
    [0.2, 0.9],
    [0.35, 0.85],
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _barHeight(int index, double animValue) {
    final phase = _phaseOffsets[index];
    final speed = _speeds[index];
    final sinVal = (math.sin((animValue * speed * 2 * math.pi) + phase) + 1.0) / 2.0;
    final minH = _heightRanges[index][0];
    final maxH = _heightRanges[index][1];
    return minH + sinVal * (maxH - minH);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primaryColor;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              return Container(
                width: widget.size / 6,
                height: widget.isPlaying
                    ? widget.size * _barHeight(index, _controller.value)
                    : widget.size * 0.4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(widget.size / 12),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
