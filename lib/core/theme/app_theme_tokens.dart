import 'package:flutter/material.dart';

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  final String name;
  final Brightness brightness;
  final Color seed;
  final Color pageBackground;
  final Color surface;
  final Color surfaceAlt;
  final Color elevatedSurface;
  final Color inputFill;
  final Color border;
  final Color shadow;
  final Color textStrong;
  final Color textMuted;
  final Color accent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color heroStart;
  final Color heroEnd;
  final Color eventWarmEnd;
  final Color postCoolEnd;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusXl;
  final double radiusPill;
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double cardElevation;

  const AppThemeTokens({
    required this.name,
    required this.brightness,
    required this.seed,
    required this.pageBackground,
    required this.surface,
    required this.surfaceAlt,
    required this.elevatedSurface,
    required this.inputFill,
    required this.border,
    required this.shadow,
    required this.textStrong,
    required this.textMuted,
    required this.accent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.heroStart,
    required this.heroEnd,
    required this.eventWarmEnd,
    required this.postCoolEnd,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusXl,
    required this.radiusPill,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.cardElevation,
  });

  bool get isDark => brightness == Brightness.dark;

  BorderRadius get radiusSmBorder => BorderRadius.circular(radiusSm);
  BorderRadius get radiusMdBorder => BorderRadius.circular(radiusMd);
  BorderRadius get radiusLgBorder => BorderRadius.circular(radiusLg);
  BorderRadius get radiusXlBorder => BorderRadius.circular(radiusXl);
  BorderRadius get radiusPillBorder => BorderRadius.circular(radiusPill);

  LinearGradient get heroGradient => LinearGradient(
        colors: [heroStart, heroEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  LinearGradient brandGradient([Color? start]) {
    final base = start ?? seed;
    return LinearGradient(
      colors: [base, Color.lerp(base, heroEnd, 0.52)!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient eventGradient(Color start) {
    return LinearGradient(
      colors: [start, Color.lerp(start, eventWarmEnd, 0.4)!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient postGradient(Color start) {
    return LinearGradient(
      colors: [start, Color.lerp(start, postCoolEnd, 0.45)!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  List<BoxShadow> get softShadow => [
        BoxShadow(
          color: shadow,
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  Color subtleFill(Color color, [double alpha = 0.12]) =>
      color.withValues(alpha: alpha);

  static const AppThemeTokens unilinkLight = AppThemeTokens(
    name: 'unilink',
    brightness: Brightness.light,
    seed: Color(0xFF6366F1),
    pageBackground: Color(0xFFF6F5FF),
    surface: Colors.white,
    surfaceAlt: Color(0xFFF0EFFF),
    elevatedSurface: Colors.white,
    inputFill: Color(0xFFF0EFFF),
    border: Color(0xFFE3E0FF),
    shadow: Color(0x0D000000),
    textStrong: Color(0xFF1A1A2E),
    textMuted: Color(0xFF6B7280),
    accent: Color(0xFF8B5CF6),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF14B8A6),
    heroStart: Color(0xFF6366F1),
    heroEnd: Color(0xFF8B5CF6),
    eventWarmEnd: Color(0xFF7C2D12),
    postCoolEnd: Color(0xFF312E81),
    radiusSm: 10,
    radiusMd: 14,
    radiusLg: 16,
    radiusXl: 20,
    radiusPill: 999,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    cardElevation: 0,
  );

  static const AppThemeTokens unilinkDark = AppThemeTokens(
    name: 'unilink',
    brightness: Brightness.dark,
    seed: Color(0xFF818CF8),
    pageBackground: Color(0xFF0E0D1B),
    surface: Color(0xFF1C1A2E),
    surfaceAlt: Color(0xFF26233B),
    elevatedSurface: Color(0xFF1C1A2E),
    inputFill: Color(0xFF26233B),
    border: Color(0xFF34314A),
    shadow: Color(0x33000000),
    textStrong: Colors.white,
    textMuted: Color(0xFF9CA3AF),
    accent: Color(0xFFA78BFA),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF14B8A6),
    heroStart: Color(0xFF818CF8),
    heroEnd: Color(0xFFA78BFA),
    eventWarmEnd: Color(0xFF7C2D12),
    postCoolEnd: Color(0xFF312E81),
    radiusSm: 10,
    radiusMd: 14,
    radiusLg: 16,
    radiusXl: 20,
    radiusPill: 999,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    cardElevation: 0,
  );

  @override
  AppThemeTokens copyWith({
    String? name,
    Brightness? brightness,
    Color? seed,
    Color? pageBackground,
    Color? surface,
    Color? surfaceAlt,
    Color? elevatedSurface,
    Color? inputFill,
    Color? border,
    Color? shadow,
    Color? textStrong,
    Color? textMuted,
    Color? accent,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? heroStart,
    Color? heroEnd,
    Color? eventWarmEnd,
    Color? postCoolEnd,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    double? radiusPill,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? cardElevation,
  }) {
    return AppThemeTokens(
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      seed: seed ?? this.seed,
      pageBackground: pageBackground ?? this.pageBackground,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      elevatedSurface: elevatedSurface ?? this.elevatedSurface,
      inputFill: inputFill ?? this.inputFill,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      textStrong: textStrong ?? this.textStrong,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      eventWarmEnd: eventWarmEnd ?? this.eventWarmEnd,
      postCoolEnd: postCoolEnd ?? this.postCoolEnd,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      radiusPill: radiusPill ?? this.radiusPill,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      cardElevation: cardElevation ?? this.cardElevation,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      name: t < 0.5 ? name : other.name,
      brightness: t < 0.5 ? brightness : other.brightness,
      seed: Color.lerp(seed, other.seed, t)!,
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      elevatedSurface: Color.lerp(elevatedSurface, other.elevatedSurface, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      textStrong: Color.lerp(textStrong, other.textStrong, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      eventWarmEnd: Color.lerp(eventWarmEnd, other.eventWarmEnd, t)!,
      postCoolEnd: Color.lerp(postCoolEnd, other.postCoolEnd, t)!,
      radiusSm: _lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: _lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: _lerpDouble(radiusLg, other.radiusLg, t),
      radiusXl: _lerpDouble(radiusXl, other.radiusXl, t),
      radiusPill: _lerpDouble(radiusPill, other.radiusPill, t),
      spaceXs: _lerpDouble(spaceXs, other.spaceXs, t),
      spaceSm: _lerpDouble(spaceSm, other.spaceSm, t),
      spaceMd: _lerpDouble(spaceMd, other.spaceMd, t),
      spaceLg: _lerpDouble(spaceLg, other.spaceLg, t),
      spaceXl: _lerpDouble(spaceXl, other.spaceXl, t),
      cardElevation: _lerpDouble(cardElevation, other.cardElevation, t),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension AppThemeTokensContext on BuildContext {
  AppThemeTokens get tokens {
    return Theme.of(this).extension<AppThemeTokens>() ??
        AppThemeTokens.unilinkLight;
  }
}
