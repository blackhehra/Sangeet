import 'dart:async';
import 'package:flutter/material.dart';

/// A marquee text widget that scrolls horizontally when text overflows
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final bool startAfter;
  final Duration pauseDuration;
  final Duration backDuration;
  final Duration velocityFactor;
  final VoidCallback? onFinish;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection = TextDirection.ltr,
    this.startAfter = true,
    this.pauseDuration = const Duration(seconds: 1),
    this.backDuration = const Duration(milliseconds: 800),
    this.velocityFactor = const Duration(milliseconds: 50),
    this.onFinish,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: widget.velocityFactor * widget.text.length,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimationIfNeeded();
    });
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _resetAnimation();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimationIfNeeded();
      });
    }
  }

  void _resetAnimation() {
    _timer?.cancel();
    _animationController.reset();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  void _startAnimationIfNeeded() {
    if (!mounted) return;
    
    // Check if text overflows
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: widget.textDirection,
      maxLines: 1,
    );
    textPainter.layout();
    
    if (_scrollController.hasClients) {
      final containerWidth = context.size?.width ?? 0;
      final textWidth = textPainter.width;
      
      // Only start marquee if text is significantly longer than container
      if (textWidth > containerWidth + 30) { // Increased threshold for safety
        _startMarquee();
      }
    }
  }

  void _startMarquee() {
    if (widget.startAfter) {
      _timer = Timer(widget.pauseDuration, () {
        if (mounted) {
          _animationController.forward().then((_) {
            if (mounted) {
              _timer = Timer(widget.pauseDuration, () {
                if (mounted) {
                  _animationController.reverse().then((_) {
                    if (mounted) {
                      widget.onFinish?.call();
                      _startMarquee(); // Loop the animation
                    }
                  });
                }
              });
            }
          });
        }
      });
    } else {
      _animationController.forward().then((_) {
        if (mounted) {
          _animationController.reverse().then((_) {
            if (mounted) {
              widget.onFinish?.call();
              _startMarquee(); // Loop the animation
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // First check if text needs marquee
        final textPainter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          textDirection: widget.textDirection,
          maxLines: 1,
        );
        textPainter.layout();
        
        final textWidth = textPainter.width;
        final needsMarquee = textWidth > constraints.maxWidth + 30; // Increased threshold for safety
        
        // If text doesn't need marquee, show normal text with ellipsis
        if (!needsMarquee) {
          return Text(
            widget.text,
            style: widget.style,
            textAlign: widget.textAlign,
            textDirection: widget.textDirection,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        
        // Otherwise show marquee with gradient fade effect
        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: const [0.0, 0.05, 0.95, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  // Calculate the maximum scroll distance to prevent overflow
                  // Add extra scroll to ensure all text is visible
                  final maxScroll = textWidth > constraints.maxWidth 
                      ? textWidth - constraints.maxWidth + 40 // Add 40px extra scroll
                      : 0.0;
                  
                  return Transform.translate(
                    offset: Offset(-_animation.value * maxScroll, 0),
                    child: child,
                  );
                },
                child: Text(
                  widget.text,
                  style: widget.style,
                  textAlign: widget.textAlign,
                  textDirection: widget.textDirection,
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getTextWidth() {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: widget.textDirection,
      maxLines: 1,
    );
    textPainter.layout();
    return textPainter.width;
  }
}
