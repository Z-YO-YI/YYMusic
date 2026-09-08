import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/design_harness.dart';
import '../support/playlist_add_harness.dart';
import '../support/playlist_content_probe.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark) in const [
    ('phone', YYPlatform.android, Size(390, 1000), false),
    ('tablet_dark', YYPlatform.android, Size(800, 1100), true),
    ('windows', YYPlatform.windows, Size(1440, 1000), false),
  ]) {
    testWidgets(
      'Phase6H6 add picker $name at 130 percent',
      (tester) async {
        final f = CatalogDetailGraphFixture(trackCount: 5);
        f.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        for (final (id, title) in [
          ('a', '夜间聆听'),
          ('b', '沿途的声音'),
          ('c', '缓慢的周末'),
        ]) {
          await f.collection.createPlaylist(contentPlaylist(id, name: title));
        }
        debugDisableShadows = false;
        try {
          await mountDetail(tester, f, platform: platform, size: size);
          await openDetailPicker(tester, f);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('detail-golden')),
            matchesGoldenFile('baselines/playlist_add_$name.png'),
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
