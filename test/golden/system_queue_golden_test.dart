import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/domain/models/collection_models.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';
import '../widget/system_queue_actions_test.dart' show openSystemQueueMenu;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, type, action) in const [
    (
      'phone_recent',
      YYPlatform.android,
      Size(360, 1000),
      false,
      SystemPlaylistType.recent,
      '',
    ),
    (
      'tablet_favorites',
      YYPlatform.android,
      Size(1024, 768),
      true,
      SystemPlaylistType.favorites,
      '',
    ),
    (
      'windows_recent',
      YYPlatform.windows,
      Size(1024, 900),
      true,
      SystemPlaylistType.recent,
      '',
    ),
    (
      'phone_success',
      YYPlatform.android,
      Size(360, 1000),
      false,
      SystemPlaylistType.favorites,
      'queue',
    ),
    (
      'windows_failure',
      YYPlatform.windows,
      Size(1024, 900),
      true,
      SystemPlaylistType.recent,
      'fail',
    ),
  ]) {
    testWidgets(
      'Phase7E5E system queue $name 130 percent',
      (tester) async {
        final f = SystemPlaylistFixture();
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        debugDisableShadows = false;
        try {
          await mountSystemPlaylist(
            tester,
            f,
            type: type,
            platform: platform,
            size: size,
          );
          final entry = systemState(tester).controller.content!.entries
              .firstWhere((e) => e.track == null);
          final menu = await openSystemQueueMenu(
            tester,
            id: entry.identity,
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
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/system_queue_$name.png'),
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
