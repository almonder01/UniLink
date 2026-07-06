import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

String genderAssetPath(String? gender) =>
    gender == 'female' ? 'assets/images/female.png' : 'assets/images/male.png';

Uint8List? decodeBase64Image(String? data) {
  if (data == null || data.isEmpty) return null;
  try {
    return base64Decode(data);
  } catch (_) {
    return null;
  }
}

class UserAvatar extends StatelessWidget {
  final String? photoBase64;
  final String? gender;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.photoBase64,
    this.gender,
    this.radius = 18,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bytes = decodeBase64Image(photoBase64);
    final size = radius * 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? cs.primary.withValues(alpha: 0.12),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
          : Padding(
              padding: EdgeInsets.all(radius * 0.22),
              child: Image.asset(
                genderAssetPath(gender),
                fit: BoxFit.contain,
              ),
            ),
    );
  }
}

class ClubAvatar extends StatelessWidget {
  final Color color;
  final String? logoBase64;
  final bool showBackground;
  final double size;
  final double borderRadius;
  final VoidCallback? onTap;

  const ClubAvatar({
    super.key,
    required this.color,
    this.logoBase64,
    this.showBackground = true,
    this.size = 40,
    this.borderRadius = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = decodeBase64Image(logoBase64);
    final effectiveRadius =
        borderRadius < size * 0.32 ? size * 0.32 : borderRadius;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: showBackground ? null : Colors.transparent,
        gradient: showBackground
            ? LinearGradient(
                colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: bytes != null
            ? Padding(
                padding: EdgeInsets.all(showBackground ? size * 0.16 : 0),
                child: Image.memory(
                  bytes,
                  width: size,
                  height: size,
                  fit: showBackground ? BoxFit.contain : BoxFit.cover,
                  gaplessPlayback: true,
                ),
              )
            : Image.asset(
                'assets/images/club.png',
                width: size * 0.58,
                height: size * 0.58,
                fit: BoxFit.contain,
              ),
      ),
    );

    if (onTap == null) return avatar;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: avatar,
      ),
    );
  }
}
