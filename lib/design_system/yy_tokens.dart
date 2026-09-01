import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// The five audited presets; custom colors are separate from this list.
enum YYAccentPreset {
  coral('珊瑚', 0xFFFF3B5C, 0xFFD92847),
  cobalt('钴蓝', 0xFF0A84FF, 0xFF0067CC),
  jade('翡翠', 0xFF00A67E, 0xFF007F61),
  amber('琥珀', 0xFFF59E0B, 0xFFC67A00, .14),
  graphite('石墨', 0xFF56606B, 0xFF3F4852, .14);

  const YYAccentPreset(
    this.label,
    this.argb,
    this.pressedArgb, [
    this.softAlpha = .12,
  ]);
  final String label;
  final int argb;
  final int pressedArgb;
  final double softAlpha;
}

/// Opaque user input is retained; readable foregrounds never mutate that input.
@immutable
final class YYAccent {
  const YYAccent._(
    this.color,
    this.pressed,
    this.softAlpha,
    this.originalHex,
    this.preset,
  );

  factory YYAccent.fromPreset(YYAccentPreset preset) => YYAccent._(
    Color(preset.argb),
    Color(preset.pressedArgb),
    preset.softAlpha,
    '#${preset.argb.toRadixString(16).substring(2).toUpperCase()}',
    preset,
  );

  factory YYAccent.custom(String hex) {
    if (!RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(hex)) {
      throw const FormatException('请输入 6 位十六进制颜色，例如 #FF3B5C');
    }
    final color = Color(
      0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16),
    );
    return YYAccent._(
      color,
      Color.lerp(color, const Color(0xFF000000), .18)!,
      .12,
      hex,
      null,
    );
  }

  final Color color;
  final Color pressed;
  final double softAlpha;
  final String originalHex;
  final YYAccentPreset? preset;
  Color get soft => color.withValues(alpha: softAlpha);
  Color get onAccent => foregroundFor(color);
  Color get onPressed => foregroundFor(pressed);

  /// Contrast ratio for opaque sRGB colors, using Flutter's linear luminance.
  static double contrast(Color first, Color second) {
    final a = first.computeLuminance();
    final b = second.computeLuminance();
    return (math.max(a, b) + .05) / (math.min(a, b) + .05);
  }

  static Color foregroundFor(Color background) {
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    return contrast(black, background) >= contrast(white, background)
        ? black
        : white;
  }

  /// A text-only accent tone with >=4.5 contrast against its actual surface.
  Color readableOn(Color background) {
    if (contrast(color, background) >= 4.5) return color;
    final target = foregroundFor(background);
    for (var step = 1; step <= 100; step++) {
      final tone = Color.lerp(color, target, step / 100)!;
      if (contrast(tone, background) >= 4.5) return tone;
    }
    return target;
  }
}

/// Semantic colors from the base HTML plus App.tsx POLISH_CSS.
@immutable
final class YYPalette {
  const YYPalette(this.brightness);
  final Brightness brightness;
  bool get isDark => brightness == Brightness.dark;
  Color get base => Color(isDark ? 0xFF0B0C0E : 0xFFF5F5F2);
  Color get elevated => Color(isDark ? 0xFF16181B : 0xFFFFFFFF);
  Color get subtle => Color(isDark ? 0xFF202328 : 0xFFECEDEA);
  Color get pressed => Color(isDark ? 0xFF2A2E34 : 0xFFE4E5E1);
  Color get text => Color(isDark ? 0xFFF5F6F7 : 0xFF111214);
  Color get secondary => Color(isDark ? 0xFFA7ACB3 : 0xFF62666C);
  Color get tertiary => Color(isDark ? 0xFF737982 : 0xFF93989F);
  Color get border => Color(isDark ? 0xFF2B2F35 : 0xFFD9DBD7);
  Color get strongBorder => Color(isDark ? 0xFF3C424A : 0xFFBEC1BC);
  Color get icon => Color(isDark ? 0xFFF1F3F4 : 0xFF202226);
  Color get secondaryIcon => Color(isDark ? 0xFFA7ACB3 : 0xFF777C83);
  Color get glassFill =>
      Color(isDark ? 0xFF181A1E : 0xFFFFFFFF)
          .withValues(alpha: isDark ? .70 : .68);
  Color get glassStroke =>
      const Color(0xFFFFFFFF).withValues(alpha: isDark ? .12 : .66);
  Color get glassHighlight =>
      const Color(0xFFFFFFFF).withValues(alpha: isDark ? .16 : .82);
  Color get scrim =>
      Color(isDark ? 0xFF000000 : 0xFF0C0E10)
          .withValues(alpha: isDark ? .58 : .38);
  static const success = Color(0xFF20A464);
  static const warning = Color(0xFFE89200);
  static const error = Color(0xFFE5484D);
}

/// Audited spacing scale and the minimum interactive hit area, in logical px.
abstract final class YYSpace {
  static const zero = 0.0, xs = 4.0, sm = 8.0, md = 12.0, lg = 16.0;
  static const xl = 20.0, xxl = 24.0, section = 32.0, huge = 40.0;
  static const giant = 48.0, spacious = 64.0, expansive = 80.0;
  static const touchTarget = 44.0;
}

/// Component-specific corners from the final design composition.
abstract final class YYRadius {
  static const button = 16.0, iconButton = 13.0, surface = 20.0;
  static const navigation = 14.0, panel = 24.0, dock = 26.0;
  static const hero = 28.0, dialog = 30.0, phoneNavigation = 32.0;
  static const albumArtwork = 20.0, trackArtwork = 10.0, trackRow = 14.0;
}

/// Variable axes preserve the non-hundred CSS weights instead of rounding them.
abstract final class YYTypography {
  static TextStyle text({
    double size = 14,
    double weight = 400,
    double spacing = 0,
    double height = 1.45,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['Noto Sans SC', 'Segoe UI Variable', 'Segoe UI'],
    fontSize: size,
    height: height,
    letterSpacing: spacing,
    color: color,
    fontVariations: [ui.FontVariation.weight(weight)],
    fontFeatures: const [
      ui.FontFeature('cv01'),
      ui.FontFeature('cv02'),
      ui.FontFeature('ss01'),
      ui.FontFeature('calt'),
    ],
  );
  static TextStyle get pageTitle =>
      text(size: 24, weight: 800, spacing: -.82, height: 1.2);
  static TextStyle get phoneTitle =>
      text(size: 22, weight: 800, spacing: -.82, height: 1.2);
  static TextStyle get sectionTitle =>
      text(size: 18, weight: 740, spacing: -.45);
  static TextStyle get accountName =>
      text(size: 13.5, weight: 720, spacing: -.4);
  static TextStyle get accountSubtitle =>
      text(size: 10, weight: 540, spacing: .05);
  static TextStyle get button => text(weight: 700, spacing: .1);
  static TextStyle get caption => text(size: 12, weight: 500);
  static TextStyle get albumTitle =>
      text(size: 12.5, weight: 700, spacing: -.15, height: 1.25);
  static TextStyle get albumMeta => text(size: 10, weight: 500, height: 1.3);
  static TextStyle get trackTitle => text(size: 12, weight: 670, height: 1.25);
  static TextStyle get trackMeta => text(size: 10, weight: 500, height: 1.3);
  static TextStyle get sourceChip => text(size: 9, weight: 650, height: 1.2);
}

/// Short control transitions; YYThemeData can resolve their duration to zero.
abstract final class YYMotion {
  static const standard = Cubic(.2, .8, .2, 1);
  static const enter = Cubic(.16, 1, .3, 1);
  static const press = Duration(milliseconds: 120);
  static const hover = Duration(milliseconds: 150);
  static const selected = Duration(milliseconds: 200);
}

/// Android navigation dimensions, independent of the current device model.
abstract final class YYNavigationMetrics {
  static const phoneHeight = 64.0, railWidth = 72.0, railItemHeight = 60.0;
  static const indicatorWidth = 3.0, indicatorHeight = 18.0;
  static const labelSize = 11.0, iconSize = 20.0;
}

/// Desktop chrome geometry from the final composed Windows reference.
abstract final class YYWindowsMetrics {
  static const toolbarHeight = 42.0;
  static const sidebarExpandedWidth = 240.0;
  static const sidebarCompactWidth = 72.0;
  static const inspectorWidth = 320.0;
  static const playerHeight = 88.0;
  static const compactPlayerHeight = 76.0;
  static const navigationItemHeight = 46.0;
  static const expandedGap = 14.0;
  static const compactGap = 12.0;
}

/// Small visual geometry is deliberately separate from the 44dp hit area.
abstract final class YYSliderMetrics {
  static const trackHeight = 3.0, thumbDiameter = 14.0, outerRing = 3.0;
  static const horizontalInset = 12.0, hoverScale = 1.24;
  static const hoverDuration = Duration(milliseconds: 130);
}

/// Layered, solid-color shadows; ordinary surfaces never use a gradient.
abstract final class YYShadows {
  static const surface = [
    BoxShadow(color: Color(0x0A0F1214), offset: Offset(0, 1), blurRadius: 4),
    BoxShadow(color: Color(0x0A0F1214), offset: Offset(0, 4), blurRadius: 18),
  ];
  static const hero = [
    BoxShadow(color: Color(0x0F0F1214), offset: Offset(0, 4), blurRadius: 20),
    BoxShadow(color: Color(0x0D0F1214), offset: Offset(0, 1), blurRadius: 3),
  ];
  static List<BoxShadow> primary(Color accent, {bool hovered = false}) => [
    BoxShadow(
      color: accent.withValues(alpha: hovered ? .30 : .20),
      offset: Offset(0, hovered ? 9 : 6),
      blurRadius: hovered ? 26 : 18,
    ),
  ];
  static const icon = [
    BoxShadow(color: Color(0x0F0F1214), offset: Offset(0, 1), blurRadius: 6),
  ];
  static List<BoxShadow> floating(Brightness brightness) => [
    BoxShadow(
      color: brightness == Brightness.dark
          ? const Color(0x61000000)
          : const Color(0x290F1214),
      offset: Offset(0, brightness == Brightness.dark ? 16 : 14),
      blurRadius: brightness == Brightness.dark ? 48 : 44,
    ),
  ];
}
