import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme => _build(AppThemeTokens.unilinkLight);
  static ThemeData get darkTheme => _build(AppThemeTokens.unilinkDark);

  static TextTheme _textTheme(Brightness brightness) =>
      GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: brightness).textTheme,
      );

  static ThemeData _build(AppThemeTokens tokens) {
    final cs = ColorScheme.fromSeed(
      seedColor: tokens.seed,
      brightness: tokens.brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      extensions: <ThemeExtension<dynamic>>[tokens],
      textTheme: _textTheme(tokens.brightness),
      scaffoldBackgroundColor: tokens.pageBackground,
      cardTheme: CardThemeData(
        elevation: tokens.cardElevation,
        shape: RoundedRectangleBorder(borderRadius: tokens.radiusXlBorder),
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: tokens.shadow,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.inputFill,
        border: OutlineInputBorder(
          borderRadius: tokens.radiusMdBorder,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: tokens.radiusMdBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: tokens.radiusMdBorder,
          borderSide: BorderSide(color: tokens.seed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: tokens.radiusMdBorder,
          borderSide: BorderSide(color: tokens.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: tokens.radiusMdBorder,
          borderSide: BorderSide(color: tokens.danger, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceLg,
        ),
        labelStyle: TextStyle(color: tokens.textMuted, fontSize: 14),
        hintStyle: TextStyle(color: tokens.textMuted.withValues(alpha: 0.62)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tokens.seed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: tokens.radiusMdBorder),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceXl,
            vertical: tokens.spaceLg,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: tokens.radiusMdBorder),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceXl,
            vertical: tokens.spaceLg,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: tokens.radiusMdBorder),
          side: BorderSide(color: tokens.seed, width: 1.5),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceXl,
            vertical: tokens.spaceLg,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: tokens.pageBackground,
        foregroundColor: tokens.textStrong,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: tokens.textStrong,
        ),
        iconTheme: IconThemeData(color: tokens.textStrong),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 70,
        backgroundColor: tokens.surface,
        indicatorColor: tokens.seed.withValues(alpha: tokens.isDark ? 0.2 : 0.12),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(tokens.surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: tokens.radiusLgBorder),
        ),
        side: WidgetStateProperty.all(BorderSide(color: tokens.border)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: cs.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: tokens.radiusMdBorder),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: tokens.radiusMdBorder),
        iconColor: cs.primary,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: tokens.radiusXlBorder),
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceXs),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: tokens.border.withValues(alpha: tokens.isDark ? 0.72 : 0.6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.seed
              : tokens.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.seed.withValues(alpha: 0.3)
              : tokens.textMuted.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}
