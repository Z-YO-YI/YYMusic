import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';

import '../support/design_harness.dart';
import '../widget/player_favorite_test.dart' show mountFavoritePlayer;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size) in const [
    ('phone', YYPlatform.android, Size(390, 844)),
    ('tablet', YYPlatform.android, Size(800, 1280)),
    ('windows', YYPlatform.windows, Size(1024, 720)),
    ('windows_narrow', YYPlatform.windows, Size(500, 640)),
  ]) {
    testWidgets(
      'player favorite $name',
      (tester) async {
        debugDisableShadows = false;
        try {
          await mountFavoritePlayer(tester, platform: platform, size: size);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('system-playlist-golden')),
            matchesGoldenFile('baselines/player_favorite_$name.png'),
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
