import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../widget/lyrics_viewport_test.dart'
    show ViewportProbe, viewportDocument;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, size, phone, plain, manual) in [
    ('phone', const Size(390, 700), true, false, false),
    ('phone_landscape', const Size(590, 360), true, false, false),
    ('tablet', const Size(800, 1000), false, false, false),
    ('windows', const Size(1440, 900), false, false, false),
    ('windows_narrow', const Size(500, 640), false, false, false),
    ('plain', const Size(390, 700), true, true, false),
    ('manual', const Size(1024, 720), false, false, true),
  ]) {
    testWidgets(
      'lyrics body $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final appearance = YYAppearanceController()
          ..setReduceMotion(true)
          ..setMode(YYThemeMode.dark);
        final probe = ViewportProbe(document: viewportDocument(plain: plain))
          ..phone = phone;
        try {
          await tester.pumpWidget(
            designHarness(
              RepaintBoundary(
                key: const ValueKey('lyrics-body-golden'),
                child: probe.body,
              ),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          if (manual) {
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -200),
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('lyrics-body-golden')),
            matchesGoldenFile('baselines/lyrics_viewport_$name.png'),
          );
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          probe.dispose();
          appearance.dispose();
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
