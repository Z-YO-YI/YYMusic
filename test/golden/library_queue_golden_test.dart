import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/library_graph_fixture.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../widget/library_queue_actions_test.dart' show openLibraryQueueMenu;
import '../widget/library_screen_test.dart' show mountLibrary, closeLibrary;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, action) in const [
    ('phone_menu', YYPlatform.android, Size(360, 800), false, ''),
    ('tablet_menu', YYPlatform.android, Size(1024, 768), true, ''),
    ('windows_menu', YYPlatform.windows, Size(1440, 1000), true, ''),
    ('phone_success', YYPlatform.android, Size(390, 1000), false, 'queue'),
    ('windows_failure', YYPlatform.windows, Size(1024, 900), false, 'fail'),
  ]) {
    testWidgets(
      'Phase7E5B library queue $name 130 percent',
      (tester) async {
        final f = LibraryGraphFixture(count: 4);
        f.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        debugDisableShadows = false;
        try {
          await mountLibrary(tester, f, platform: platform, size: size);
          final menu = await openLibraryQueueMenu(
            tester,
            f,
            windows: platform == YYPlatform.windows,
          );
          if (action.isNotEmpty) {
            if (action == 'fail') {
              f.collection.beforeQueueWrite = (_) async =>
                  throw StateError('private-marker');
            }
            menu.onSelected!('queue');
            await settleContent(tester);
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('library-golden')),
            matchesGoldenFile('baselines/library_queue_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closeLibrary(tester, f);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
