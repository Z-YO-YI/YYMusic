import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/domain/models/collection_models.dart';

import '../support/design_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import '../widget/playback_history_screen_test.dart' show confirmPagePlayback;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark) in const [
    ('phone', YYPlatform.android, Size(390, 1000), false),
    ('windows', YYPlatform.windows, Size(1440, 1000), true),
  ]) {
    testWidgets(
      'Phase6H13 $name history save failure is distinct from audio failure',
      (tester) async {
        final f = SystemPlaylistFixture();
        f.collection.onHistoryRecord = (_) async =>
            throw StateError('private-marker');
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountSystemPlaylist(
            tester,
            f,
            type: SystemPlaylistType.recent,
            platform: platform,
            size: size,
          );
          await f.graph.playback.play();
          await confirmPagePlayback(tester, f);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/playback_history_$name.png'),
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
