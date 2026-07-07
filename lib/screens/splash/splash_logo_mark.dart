import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/unilink_logo.dart';

class SplashLogoMark extends StatelessWidget {
  final double size;

  const SplashLogoMark({
    super.key,
    this.size = 132,
  });

  @override
  Widget build(BuildContext context) {
    final ringSize = size * 0.94;
    final plateSize = size * 0.73;
    final logoScale = (size / 132).clamp(0.7, 1.0);

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
                color: Colors.white.withValues(alpha: 0.28),
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
          Container(
            width: plateSize,
            height: plateSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.32),
              ),
            ),
          ),
          Transform.scale(
            scale: logoScale.toDouble(),
            child: const UnilinkLogo(
              size: LogoSize.large,
              showText: false,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
