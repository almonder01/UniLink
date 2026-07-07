import 'package:flutter/material.dart';

class SplashProgressLine extends StatelessWidget {
  final double width;

  const SplashProgressLine({
    super.key,
    this.width = 168,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          minHeight: 4,
          color: Colors.white.withValues(alpha: 0.92),
          backgroundColor: Colors.white.withValues(alpha: 0.22),
        ),
      ),
    );
  }
}
