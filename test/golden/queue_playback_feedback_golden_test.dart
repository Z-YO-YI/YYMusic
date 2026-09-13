import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import '../widget/queue_playback_feedback_test.dart'
    show createSkippedRecord, details;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 844)),
    ('tablet_dark', YYPlatform.android, Size(1280, 800)),
    ('windows', YYPlatform.windows, Size(1024, 720)),
  ]) {
    testWidgets(
      'queue skipped playback $name 130 percent',
      (tester) async {
        final f = SystemPlaylistFixture();
        await createSkippedRecord(f);
        if (name == 'tablet_dark') f.graph.appearance.setMode(YYThemeMode.dark);
        debugDisableShadows = false;
        try {
          await mountSystemPlaylist(
            tester,
            f,
            location: '/queue',
            platform: platform,
            size: size,
          );
          await tester.tap(find.byKey(details));
          await settleContent(tester);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/queue_playback_feedback_$name.png'),
          );
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
