import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashSignalBars extends StatelessWidget {
  final double scale;

  const SplashSignalBars({
    super.key,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    const heights = [16.0, 24.0, 34.0, 24.0, 16.0];
    final safeScale = scale.clamp(0.72, 1.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(heights.length, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 3 * safeScale),
          child: Container(
            width: 6 * safeScale,
            height: heights[index] * safeScale,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(999),
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
                delay: (index * 120).ms,
              )
              .scale(
                begin: const Offset(1, 0.42),
                end: const Offset(1, 1),
                alignment: Alignment.bottomCenter,
                duration: 620.ms,
                curve: Curves.easeInOut,
              ),
        );
      }),
    );
  }
}
