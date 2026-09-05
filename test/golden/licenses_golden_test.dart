import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/flutter_license_repository.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);
  final native = File('assets/legal/android_audio/notices.json')
      .readAsStringSync();
  for (final (name, platform, size, dark, showText) in [
    ('phone_light', YYPlatform.android, const Size(390, 844), false, false),
    ('tablet_dark', YYPlatform.android, const Size(1024, 768), true, false),
    ('windows_text', YYPlatform.windows, const Size(1440, 900), false, true),
  ]) {
    testWidgets(
      'license page $name uses complete audited native materials at 130 percent',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repository = FlutterLicenseRepository(
          frameworkLoader: () => const Stream<LicenseEntry>.empty(),
          nativeLoader: () async => native,
        );
        final graph = DependencyGraph(licenses: repository);
        graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        graph.appearance.setReduceMotion(true);
        addTearDown(graph.dispose);
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [dependencyGraphProvider.overrideWithValue(graph)],
              child: RepaintBoundary(
                key: const ValueKey('license-page-golden'),
                child: YYMusicApp(
                  platform: platform,
                  initialLocation: '/settings/licenses',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (showText) {
            await tester.tap(
              find.text('Android · org.checkerframework:checker-qual:3.41.0'),
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('license-page-golden')),
            matchesGoldenFile('baselines/licenses_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
