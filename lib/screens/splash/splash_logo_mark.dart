import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme_tokens.dart';
import '../../widgets/unilink_logo.dart';

class SplashLogoMark extends StatelessWidget {
  final double size;

  const SplashLogoMark({
    super.key,
    this.size = 132,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ringSize = size * 0.94;
    final plateSize = size * 0.73;
    final logoScale = (size / 132).clamp(0.7, 1.0);
    final blur = (tokens.glassBlur * 0.72).clamp(8.0, 18.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    tokens.border.withValues(alpha: tokens.isDark ? 0.78 : 1),
                width: 1.4,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.92, 0.92),
                end: const Offset(1.08, 1.08),
                duration: 1300.ms,
                curve: Curves.easeInOut,
              )
              .fade(
                begin: 0.25,
                end: 0.7,
                duration: 1300.ms,
                curve: Curves.easeInOut,
              ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                width: plateSize,
                height: plateSize,
                decoration: BoxDecoration(
                  color: tokens.elevatedSurface.withValues(
                    alpha: tokens.isDark ? 0.54 : 0.7,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.border),
                  boxShadow: tokens.softShadow,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(
                          alpha: tokens.isDark ? 0.14 : 0.42,
                        ),
                        tokens.info.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: logoScale.toDouble(),
            child: const UnilinkLogo(
              size: LogoSize.large,
              showText: false,
            ),
          ),
        ],
      ),
    );
  }
}
