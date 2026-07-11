import 'package:flutter/material.dart';

import '../../core/theme/app_theme_tokens.dart';

class SplashProgressLine extends StatelessWidget {
  final double width;

  const SplashProgressLine({
    super.key,
    this.width = 168,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          minHeight: 4,
          color: tokens.info.withValues(alpha: tokens.isDark ? 0.92 : 0.78),
          backgroundColor: tokens.surfaceAlt.withValues(
            alpha: tokens.isDark ? 0.62 : 0.82,
          ),
        ),
      ),
    );
  }
}
