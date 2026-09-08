import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/library/common/library_controller.dart';

import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../support/system_playlist_fixture.dart';
import '../support/system_playlist_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, type, count) in const [
    (
      'phone_favorites',
      YYPlatform.android,
      Size(390, 1000),
      false,
      SystemPlaylistType.favorites,
      5,
    ),
    (
      'tablet_recent',
      YYPlatform.android,
      Size(800, 1100),
      true,
      SystemPlaylistType.recent,
      5,
    ),
    (
      'tablet_queue',
      YYPlatform.android,
      Size(1024, 768),
      false,
      SystemPlaylistType.queue,
      5,
    ),
    (
      'windows_queue',
      YYPlatform.windows,
      Size(1440, 1000),
      true,
      SystemPlaylistType.queue,
      5,
    ),
    (
      'phone_empty',
      YYPlatform.android,
      Size(390, 1000),
      false,
      SystemPlaylistType.queue,
      0,
    ),
    (
      'phone_error',
      YYPlatform.android,
      Size(390, 1000),
      true,
      SystemPlaylistType.queue,
      0,
    ),
    (
      'phone_links',
      YYPlatform.android,
      Size(390, 1000),
      false,
      SystemPlaylistType.queue,
      0,
    ),
  ]) {
    testWidgets(
      'Phase6H12 system playlist $name at 130 percent',
      (tester) async {
        final f = SystemPlaylistFixture(count: count);
        f.graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
        if (name == 'phone_error') {
          f.collection.systemReader = (_, _) async =>
              throw StateError('private-marker');
        }
        debugDisableShadows = false;
        try {
          await mountSystemPlaylist(
            tester,
            f,
            platform: platform,
            size: size,
            type: type,
            location: name == 'phone_links' ? '/library' : null,
          );
          if (name == 'phone_links') {
            f.graph.libraryController.selectCategory(LibraryCategory.playlists);
            await settleContent(tester);
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/system_playlist_$name.png'),
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
