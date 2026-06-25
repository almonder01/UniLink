import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LogoSize { small, medium, large }

class UnilinkLogo extends StatelessWidget {
  final LogoSize size;
  final bool showText;
  final Color? color;

  const UnilinkLogo({
    super.key,
    this.size = LogoSize.medium,
    this.showText = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = color ?? cs.primary;

    final double iconSize;
    final double fontSize;
    final double padding;
    final double radius;

    switch (size) {
      case LogoSize.small:
        iconSize = 14;
        fontSize = 14;
        padding = 6;
        radius = 8;
        break;
      case LogoSize.large:
        iconSize = 32;
        fontSize = 26;
        padding = 13;
        radius = 16;
        break;
      default:
        iconSize = 20;
        fontSize = 18;
        padding = 9;
        radius = 11;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  Color.lerp(primary, const Color(0xFF8B5CF6), 0.6)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/app_icon_3.png',
              width: iconSize,
              height: iconSize,
            )),
        if (showText) ...[
          SizedBox(width: size == LogoSize.small ? 6 : 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Uni',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: color ?? Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                TextSpan(
                  text: 'Link',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
