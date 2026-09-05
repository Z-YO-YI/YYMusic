import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/catalog_detail_menu_harness.dart';
import '../support/design_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, favorite, error) in const [
    ('phone_menu', YYPlatform.android, Size(390, 1000), false, false, false),
    ('tablet_menu', YYPlatform.android, Size(1024, 768), false, true, false),
    (
      'windows_dark_menu',
      YYPlatform.windows,
      Size(840, 900),
      true,
      false,
      true,
    ),
  ]) {
    testWidgets(
      'Phase6G4 detail $name at 130 percent',
      (tester) async {
        final f = CatalogDetailGraphFixture();
        f.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        debugDisableShadows = false;
        try {
          await mountDetail(tester, f, platform: platform, size: size);
          final track = f.repository.trackData[name == 'phone_menu' ? 2 : 0];
          if (favorite) {
            await f.collection.setFavorite(track.ref, favorite: true);
          }
          if (error) {
            f.collection.favoriteReader = () =>
                Stream.error(StateError('private-marker'));
          }
          await openDetailMenu(tester, track);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('detail-golden')),
            matchesGoldenFile('baselines/catalog_detail_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closeDetail(tester, f);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
