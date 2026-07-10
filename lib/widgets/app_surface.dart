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

    final content = Container(
      margin: margin,
      padding: padding,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color ?? tokens.surface,
        borderRadius: radius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );

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

    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(tokens.spaceLg + 2),
      decoration: BoxDecoration(
        gradient: gradient ?? tokens.heroGradient,
        borderRadius: borderRadius ?? tokens.radiusXlBorder,
      ),
      child: child,
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
