import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/domain/models/collection_models.dart';
import 'package:yymusic/features/lyrics/common/lyrics_screen.dart';

import '../support/design_harness.dart';
import '../support/system_playlist_fixture.dart';
import '../widget/lyrics_favorite_test.dart' show mountFavoriteLyrics;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, failure) in const [
    ('tablet', YYPlatform.android, Size(800, 1280), false),
    ('windows', YYPlatform.windows, Size(1024, 720), false),
    ('phone_read_failure', YYPlatform.android, Size(390, 844), true),
  ]) {
    testWidgets(
      'lyrics favorite $name',
      (tester) async {
        final f = SystemPlaylistFixture();
        if (failure) {
          f.collection.favoriteReader = () =>
              Stream<List<FavoriteEntry>>.error(StateError('test-only'));
        }
        debugDisableShadows = false;
        try {
          await mountFavoriteLyrics(
            tester,
            fixture: f,
            platform: platform,
            size: size,
          );
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(LyricsScreen),
            matchesGoldenFile('baselines/lyrics_favorite_$name.png'),
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
