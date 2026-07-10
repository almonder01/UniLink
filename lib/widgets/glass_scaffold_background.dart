import 'package:flutter/material.dart';

import '../core/theme/app_theme_tokens.dart';

class GlassScaffoldBackground extends StatelessWidget {
  final Widget child;

  const GlassScaffoldBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (tokens.glassBlur <= 0) {
      return ColoredBox(color: tokens.pageBackground, child: child);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: tokens.isDark
                  ? const [
                      Color(0xFF071416),
                      Color(0xFF0F172A),
                      Color(0xFF172554),
                    ]
                  : const [
                      Color(0xFFEAF8F6),
                      Color(0xFFF7F2FF),
                      Color(0xFFE0F7FF),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _GlassRibbonPainter(tokens: tokens),
          ),
        ),
        child,
      ],
    );
  }
}

class _GlassRibbonPainter extends CustomPainter {
  final AppThemeTokens tokens;

  const _GlassRibbonPainter({required this.tokens});

  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          tokens.heroStart.withValues(alpha: tokens.isDark ? 0.22 : 0.18),
          tokens.heroEnd.withValues(alpha: tokens.isDark ? 0.12 : 0.16),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: tokens.isDark ? 0.06 : 0.28)
      ..strokeWidth = size.shortestSide * 0.018
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final ribbon = Path()
      ..moveTo(-size.width * 0.18, size.height * 0.18)
      ..cubicTo(
        size.width * 0.22,
        -size.height * 0.04,
        size.width * 0.55,
        size.height * 0.18,
        size.width * 1.16,
        -size.height * 0.02,
      )
      ..lineTo(size.width * 1.12, size.height * 0.22)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.38,
        size.width * 0.22,
        size.height * 0.22,
        -size.width * 0.14,
        size.height * 0.43,
      )
      ..close();
    canvas.drawPath(ribbon, lightPaint);

    final lowerRibbon = Path()
      ..moveTo(-size.width * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.58,
        size.height * 0.88,
        size.width * 1.14,
        size.height * 0.62,
      )
      ..lineTo(size.width * 1.12, size.height * 1.08)
      ..lineTo(-size.width * 0.08, size.height * 1.08)
      ..close();
    canvas.drawPath(
      lowerRibbon,
      Paint()
        ..shader = LinearGradient(
          colors: [
            tokens.info.withValues(alpha: tokens.isDark ? 0.16 : 0.18),
            tokens.accent.withValues(alpha: tokens.isDark ? 0.14 : 0.13),
            Colors.transparent,
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ).createShader(Offset.zero & size),
    );

    final highlight = Path()
      ..moveTo(size.width * 0.08, size.height * 0.08)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.22,
        size.width * 0.62,
        size.height * 0.02,
        size.width * 0.92,
        size.height * 0.16,
      );
    canvas.drawPath(highlight, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassRibbonPainter oldDelegate) {
    return oldDelegate.tokens != tokens;
  }
}
