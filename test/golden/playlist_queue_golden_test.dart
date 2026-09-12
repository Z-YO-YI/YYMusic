import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_fixture.dart';
import '../support/playlist_content_harness.dart';
import '../widget/playlist_queue_actions_test.dart' show openPlaylistQueueMenu;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, action) in const [
    ('tablet_menu', YYPlatform.android, Size(1024, 768), true, ''),
    ('windows_menu', YYPlatform.windows, Size(1024, 900), false, ''),
    ('phone_success', YYPlatform.android, Size(360, 1000), false, 'queue'),
    ('windows_failure', YYPlatform.windows, Size(1024, 900), true, 'fail'),
  ]) {
    testWidgets(
      'Phase7E5D playlist queue $name 130 percent',
      (tester) async {
        final f = PlaylistContentFixture(count: 5);
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountPlaylist(tester, f, platform: platform, size: size);
          final menu = await openPlaylistQueueMenu(
            tester,
            id: 'e-3',
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
            find.byKey(const ValueKey('playlist-golden')),
            matchesGoldenFile('baselines/playlist_queue_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closePlaylist(tester, f);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
