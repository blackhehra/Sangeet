import 'package:flutter/material.dart';
import 'package:sangeet/core/theme/app_theme.dart';

/// Animated listening wave indicator
class ListeningWaveIndicator extends StatefulWidget {
  const ListeningWaveIndicator({super.key});

  @override
  State<ListeningWaveIndicator> createState() => _ListeningWaveIndicatorState();
}

class _ListeningWaveIndicatorState extends State<ListeningWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AnimatedBar(controller: _controller, delay: 0.0),
          const SizedBox(width: 2),
          _AnimatedBar(controller: _controller, delay: 0.2),
          const SizedBox(width: 2),
          _AnimatedBar(controller: _controller, delay: 0.4),
        ],
      ),
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _AnimatedBar({
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final value = (controller.value + delay) % 1.0;
        final height = 4.0 + (12.0 * (0.5 + 0.5 * (value < 0.5 ? value * 2 : (1 - value) * 2)));
        
        return Container(
          width: 3,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
