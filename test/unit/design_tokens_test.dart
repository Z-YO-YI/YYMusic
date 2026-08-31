import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

void main() {
  test('five audited presets preserve raw color and pressed color', () {
    expect(YYAccentPreset.values.length, 5);
    final accents = YYAccentPreset.values.map(YYAccent.fromPreset).toList();
    expect(accents.map((accent) => accent.color.toARGB32()), [
      0xFFFF3B5C,
      0xFF0A84FF,
      0xFF00A67E,
      0xFFF59E0B,
      0xFF56606B,
    ]);
    expect(accents.map((accent) => accent.pressed.toARGB32()), [
      0xFFD92847,
      0xFF0067CC,
      0xFF007F61,
      0xFFC67A00,
      0xFF3F4852,
    ]);
    expect(accents.map((accent) => accent.softAlpha), [
      .12,
      .12,
      .12,
      .14,
      .14,
    ]);
  });

  test(
    'custom HEX is retained verbatim and invalid inputs do not change state',
    () {
      final controller = YYAppearanceController();
      addTearDown(controller.dispose);
      controller.setCustomAccent('aAbB09');
      expect(controller.accent.originalHex, 'aAbB09');
      expect(controller.accent.color.toARGB32(), 0xFFAABB09);
      final original = controller.accent;
      for (final invalid in [
        '',
        '#ABC',
        '#12345678',
        ' #123456',
        '12345G',
        '#123456\n',
      ]) {
        expect(
          () => controller.setCustomAccent(invalid),
          throwsFormatException,
          reason: invalid,
        );
        expect(controller.accent, same(original));
      }
    },
  );

  test('contrast meets 4.5 for presets and a broad custom color grid', () {
    final accents = YYAccentPreset.values.map(YYAccent.fromPreset).toList();
    for (var r = 0; r <= 255; r += 51) {
      for (var g = 0; g <= 255; g += 51) {
        for (var b = 0; b <= 255; b += 51) {
          accents.add(
            YYAccent.custom(
              ((r << 16) | (g << 8) | b).toRadixString(16).padLeft(6, '0'),
            ),
          );
        }
      }
    }
    for (final accent in accents) {
      final raw = accent.color;
      expect(
        YYAccent.contrast(accent.onAccent, accent.color),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        YYAccent.contrast(accent.onPressed, accent.pressed),
        greaterThanOrEqualTo(4.5),
      );
      for (final brightness in Brightness.values) {
        final palette = YYPalette(brightness);
        for (final background in [
          palette.base,
          palette.elevated,
          Color.alphaBlend(accent.soft, palette.elevated),
        ]) {
          expect(
            YYAccent.contrast(accent.readableOn(background), background),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(
          YYAccent.contrast(palette.secondary, palette.elevated),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(accent.color, raw);
    }
  });

  test('appearance is session-only with explicit System and reduced motion behavior', () {
    final controller = YYAppearanceController();
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);
    expect(controller.resolve(Brightness.dark).brightness, Brightness.light);
    controller.setMode(YYThemeMode.light);
    controller.setPreset(YYAccentPreset.coral);
    expect(notifications, 0);
    controller.setMode(YYThemeMode.system);
    expect(controller.resolve(Brightness.dark).brightness, Brightness.dark);
    expect(controller.resolve(Brightness.light).brightness, Brightness.light);
    expect(
      controller
          .resolve(Brightness.light, systemReduceMotion: true)
          .motion(YYMotion.press),
      Duration.zero,
    );
    controller.setReduceMotion(true);
    controller.setReduceGlass(true);
    final theme = controller.resolve(Brightness.light);
    expect(theme.motion(YYMotion.press), Duration.zero);
    expect(theme.reduceGlass, isTrue);
    expect(notifications, 3);
  });

  test(
    'polish typography retains exact fractional sizes and variable weights',
    () {
      expect(YYTypography.pageTitle.letterSpacing, -.82);
      expect(YYTypography.accountName.fontSize, 13.5);
      expect(YYTypography.accountName.fontVariations!.single.value, 720);
      expect(YYTypography.accountSubtitle.fontSize, 10);
      expect(YYTypography.accountSubtitle.fontVariations!.single.value, 540);
      expect(YYSpace.touchTarget, 44);
      expect(YYRadius.surface, 20);
    },
  );
}
