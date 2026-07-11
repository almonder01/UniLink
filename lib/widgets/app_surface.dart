import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme_tokens.dart';

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = borderRadius ?? tokens.radiusXlBorder;
    final effectiveBorder = border ??
        (tokens.glassBlur > 0
            ? Border.all(color: tokens.border, width: 1)
            : null);

    final surfaceChild = tokens.glassBlur > 0
        ? Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(
                            alpha: tokens.isDark ? 0.16 : 0.42,
                          ),
                          Colors.white.withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              child,
            ],
          )
        : child;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? tokens.surface,
        borderRadius: radius,
        border: effectiveBorder,
        boxShadow:
            boxShadow ?? (tokens.glassBlur > 0 ? tokens.softShadow : null),
      ),
      child: surfaceChild,
    );

    if (tokens.glassBlur > 0) {
      content = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.glassBlur,
          sigmaY: tokens.glassBlur,
        ),
        child: content,
      );
    }

    content = ClipRRect(
      borderRadius: radius,
      clipBehavior: clipBehavior,
      child: content,
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }
}

class AppGradientPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final BorderRadius? borderRadius;

  const AppGradientPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final radius = borderRadius ?? tokens.radiusXlBorder;

    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(tokens.spaceLg + 2),
      decoration: BoxDecoration(
        gradient: gradient ?? tokens.heroGradient,
        borderRadius: radius,
        border: tokens.glassBlur > 0
            ? Border.all(color: tokens.border, width: 1)
            : null,
        boxShadow: tokens.glassBlur > 0 ? tokens.softShadow : null,
      ),
      child: Stack(
        children: [
          if (tokens.glassBlur > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(
                          alpha: tokens.isDark ? 0.12 : 0.32,
                        ),
                        Colors.white.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

class AppStatusPill extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final Border? border;

  const AppStatusPill({
    super.key,
    required this.child,
    required this.color,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: tokens.spaceSm,
            vertical: tokens.spaceXs,
          ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: tokens.radiusPillBorder,
        border: border,
      ),
      child: child,
    );
  }
}
