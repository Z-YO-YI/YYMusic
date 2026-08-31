import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonic_gallery/src/theme.dart';

void main() {
  test('light and dark palettes preserve the coral brand direction', () {
    expect(SgPalette.light.accent, const Color(0xFFF05252));
    expect(SgPalette.dark.accent, const Color(0xFFFF6464));
    expect(SgPalette.light.background, const Color(0xFFF6F6F3));
    expect(SgPalette.dark.background, const Color(0xFF0A0B0D));
  });

  test('responsive tokens match the four point spacing system', () {
    expect(SgSpace.x1, 4);
    expect(SgSpace.x4, 16);
    expect(SgSpace.x16, 64);
    expect(SgRadius.glass, 22);
  });
}

