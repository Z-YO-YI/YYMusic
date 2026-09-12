import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/domain/models/collection_models.dart';

import '../support/design_harness.dart';
import '../support/native_lyrics_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../widget/shell_favorite_test.dart'
    show favoriteBar, mountFavoriteShell;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, state) in const [
    ('windows_saved', YYPlatform.windows, 'saved'),
    ('windows_busy', YYPlatform.windows, 'busy'),
    ('tablet_read_failure', YYPlatform.android, 'error'),
  ]) {
    testWidgets(
      'shell favorite $name',
      (tester) async {
        final f = SystemPlaylistFixture();
        final gate = Completer<void>();
        if (state == 'error') {
          f.collection.favoriteReader = () =>
              Stream<List<FavoriteEntry>>.error(StateError('test-only'));
        }
        debugDisableShadows = false;
        try {
          await mountFavoriteShell(
            tester,
            fixture: f,
            platform: platform,
            size: const Size(1280, 900),
          );
          if (state == 'busy') {
            f.collection.favoriteGate = gate.future;
            favoriteBar(tester).onToggleFavorite!();
            await settleLyrics(tester);
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/shell_favorite_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          gate.complete();
          await settleLyrics(tester);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
