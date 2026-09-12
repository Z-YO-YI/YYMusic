import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/catalog_detail_location.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/design_harness.dart';
import '../support/playlist_content_harness.dart' show settleContent;
import '../widget/catalog_queue_actions_test.dart' show openCatalogQueueMenu;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, artist, action) in const [
    ('phone_artist_menu', YYPlatform.android, Size(360, 800), false, true, ''),
    (
      'tablet_artist_success',
      YYPlatform.android,
      Size(1024, 768),
      true,
      true,
      'queue',
    ),
    (
      'windows_album_failure',
      YYPlatform.windows,
      Size(1024, 900),
      false,
      false,
      'fail',
    ),
  ]) {
    testWidgets(
      'Phase7E5C catalog queue $name 130 percent',
      (tester) async {
        final f = CatalogDetailGraphFixture(trackCount: 4);
        f.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        debugDisableShadows = false;
        try {
          await mountDetail(
            tester,
            f,
            platform: platform,
            size: size,
            location: artist
                ? catalogDetailLocation(ArtistDetailTarget(f.artist.ref))
                      .toString()
                : null,
          );
          final menu = await openCatalogQueueMenu(
            tester,
            f,
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
            find.byKey(const ValueKey('detail-golden')),
            matchesGoldenFile('baselines/catalog_queue_$name.png'),
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
