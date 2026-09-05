import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/catalog_detail_location.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_sections.dart';
import 'package:yymusic/features/catalog_detail/common/catalog_detail_state.dart';

import '../support/catalog_detail_graph_fixture.dart';
import '../support/catalog_detail_harness.dart';
import '../support/design_harness.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, artist, empty, error, albums)
      in const [
        (
          'phone_album',
          YYPlatform.android,
          Size(390, 1000),
          false,
          false,
          false,
          false,
          false,
        ),
        (
          'phone_empty',
          YYPlatform.android,
          Size(390, 1000),
          false,
          false,
          true,
          false,
          false,
        ),
        (
          'tablet_portrait_artist_albums',
          YYPlatform.android,
          Size(800, 1200),
          true,
          true,
          false,
          false,
          true,
        ),
        (
          'tablet_landscape_artist_tracks',
          YYPlatform.android,
          Size(1024, 768),
          false,
          true,
          false,
          false,
          false,
        ),
        (
          'windows_dark_album',
          YYPlatform.windows,
          Size(1440, 1000),
          true,
          false,
          false,
          false,
          false,
        ),
        (
          'windows_narrow_error',
          YYPlatform.windows,
          Size(840, 900),
          false,
          false,
          false,
          true,
          false,
        ),
      ]) {
    testWidgets(
      'Phase6G2 Detail $name at 130 percent',
      (tester) async {
        final fixture = CatalogDetailGraphFixture(trackCount: empty ? 0 : 45);
        fixture.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        if (error) {
          fixture.repository.onAlbum = (_, _) async =>
              throw StateError('private-marker');
        }
        debugDisableShadows = false;
        try {
          await mountDetail(
            tester,
            fixture,
            platform: platform,
            size: size,
            location: catalogDetailLocation(
              artist
                  ? ArtistDetailTarget(fixture.artist.ref)
                  : AlbumDetailTarget(fixture.album.ref),
            ).toString(),
          );
          if (albums) {
            final button = find.byKey(const ValueKey(CatalogDetailTab.albums));
            await tester.ensureVisible(button);
            await tester.pumpAndSettle();
            await tester.tap(button);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('detail-golden')),
            matchesGoldenFile('baselines/catalog_detail_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closeDetail(tester, fixture);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
