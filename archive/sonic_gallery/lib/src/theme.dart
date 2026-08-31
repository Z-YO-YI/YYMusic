import 'package:flutter/material.dart';

@immutable
class SgPalette extends ThemeExtension<SgPalette> {
  const SgPalette({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.surfaceTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.error,
    required this.scrim,
    required this.glass,
    required this.glassBorder,
    required this.shadow,
    required this.playerBackground,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color surfaceTertiary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;
  final Color success;
  final Color warning;
  final Color error;
  final Color scrim;
  final Color glass;
  final Color glassBorder;
  final Color shadow;
  final Color playerBackground;
  final bool isDark;

  static const light = SgPalette(
    background: Color(0xFFF6F6F3),
    surface: Color(0xFFFFFFFF),
    surfaceSecondary: Color(0xFFECEDEA),
    surfaceTertiary: Color(0xFFE5E6E3),
    textPrimary: Color(0xFF121316),
    textSecondary: Color(0xFF696D75),
    textTertiary: Color(0xFF969AA2),
    divider: Color(0xFFD9DBDF),
    accent: Color(0xFFF05252),
    accentPressed: Color(0xFFD83F45),
    accentSoft: Color(0xFFFBE9E8),
    success: Color(0xFF23835F),
    warning: Color(0xFFB8741A),
    error: Color(0xFFD63F47),
    scrim: Color(0x47121316),
    glass: Color(0xD9FFFFFF),
    glassBorder: Color(0x14121316),
    shadow: Color(0x14121316),
    playerBackground: Color(0xFFF3F1EC),
    isDark: false,
  );

  static const dark = SgPalette(
    background: Color(0xFF0A0B0D),
    surface: Color(0xFF14161A),
    surfaceSecondary: Color(0xFF1B1E23),
    surfaceTertiary: Color(0xFF23272D),
    textPrimary: Color(0xFFF5F6F7),
    textSecondary: Color(0xFFA1A6AF),
    textTertiary: Color(0xFF717782),
    divider: Color(0xFF2B2F36),
    accent: Color(0xFFFF6464),
    accentPressed: Color(0xFFE85056),
    accentSoft: Color(0xFF30191B),
    success: Color(0xFF41B786),
    warning: Color(0xFFE3A340),
    error: Color(0xFFFF666D),
    scrim: Color(0x8F000000),
    glass: Color(0xE812161A),
    glassBorder: Color(0x1FFFFFFF),
    shadow: Color(0x5C000000),
    playerBackground: Color(0xFF111316),
    isDark: true,
  );

  @override
  SgPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSecondary,
    Color? surfaceTertiary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? accent,
    Color? accentPressed,
    Color? accentSoft,
    Color? success,
    Color? warning,
    Color? error,
    Color? scrim,
    Color? glass,
    Color? glassBorder,
    Color? shadow,
    Color? playerBackground,
    bool? isDark,
  }) {
    return SgPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceTertiary: surfaceTertiary ?? this.surfaceTertiary,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      scrim: scrim ?? this.scrim,
      glass: glass ?? this.glass,
      glassBorder: glassBorder ?? this.glassBorder,
      shadow: shadow ?? this.shadow,
      playerBackground: playerBackground ?? this.playerBackground,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  SgPalette lerp(ThemeExtension<SgPalette>? other, double t) {
    if (other is! SgPalette) return this;
    return SgPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSecondary:
          Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      surfaceTertiary: Color.lerp(surfaceTertiary, other.surfaceTertiary, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      playerBackground:
          Color.lerp(playerBackground, other.playerBackground, t)!,
      isDark: t < .5 ? isDark : other.isDark,
    );
  }
}

extension SgThemeContext on BuildContext {
  SgPalette get palette => Theme.of(this).extension<SgPalette>()!;
}

abstract final class SgSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
  static const x16 = 64.0;
}

abstract final class SgRadius {
  static const icon = 10.0;
  static const input = 12.0;
  static const button = 12.0;
  static const card = 14.0;
  static const cover = 12.0;
  static const coverLarge = 18.0;
  static const dialog = 20.0;
  static const glass = 22.0;
  static const player = 24.0;
}

abstract final class SgDuration {
  static const press = Duration(milliseconds: 140);
  static const hover = Duration(milliseconds: 120);
  static const page = Duration(milliseconds: 240);
  static const player = Duration(milliseconds: 320);
  static const panel = Duration(milliseconds: 260);
}

ThemeData sonicTheme(SgPalette palette) {
  return ThemeData(
    useMaterial3: false,
    brightness: palette.isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    splashFactory: NoSplash.splashFactory,
    fontFamilyFallback: const ['Inter', 'Noto Sans SC', 'Segoe UI'],
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        height: 40 / 34,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        height: 34 / 28,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 26 / 20,
        fontWeight: FontWeight.w600,
        color: palette.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        height: 21 / 15,
        fontWeight: FontWeight.w500,
        color: palette.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        height: 22 / 15,
        color: palette.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        color: palette.textSecondary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: palette.textSecondary,
      ),
    ),
    extensions: [palette],
  );
}

