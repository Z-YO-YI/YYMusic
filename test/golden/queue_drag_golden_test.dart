import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import '../widget/queue_drag_screen_test.dart' show startQueueDrag;
import '../widget/queue_screen_test.dart' show queueRow;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark) in const [
    ('phone', YYPlatform.android, Size(390, 1000), false),
    ('tablet', YYPlatform.android, Size(1024, 768), true),
    ('windows', YYPlatform.windows, Size(1440, 1000), false),
  ]) {
    testWidgets(
      'Phase7E4 queue $name drag proxy at 130 percent',
      (tester) async {
        final f = SystemPlaylistFixture();
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountSystemPlaylist(
            tester,
            f,
            location: '/queue',
            platform: platform,
            size: size,
          );
          final target =
              tester.getCenter(queueRow('q-3')) + const Offset(0, 10);
          final drag = await startQueueDrag(
            tester,
            'q-1',
            windows: platform == YYPlatform.windows,
          );
          await drag.moveTo(target);
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/queue_drag_$name.png'),
          );
          await drag.cancel();
          await tester.pumpAndSettle();
        } finally {
          debugDisableShadows = true;
          await closeSystemPlaylist(tester, f);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
