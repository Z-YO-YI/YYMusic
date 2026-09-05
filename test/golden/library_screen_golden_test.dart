import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';
import 'package:yymusic/features/library/common/library_controller.dart';

import '../support/design_harness.dart';
import '../support/library_graph_fixture.dart';
import '../widget/library_screen_test.dart' show mountLibrary, closeLibrary;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, category, empty, menu) in const [
    (
      'phone_albums',
      YYPlatform.android,
      Size(390, 1000),
      false,
      LibraryCategory.albums,
      false,
      false,
    ),
    (
      'phone_empty',
      YYPlatform.android,
      Size(390, 1000),
      false,
      LibraryCategory.local,
      true,
      false,
    ),
    (
      'tablet_portrait_artists',
      YYPlatform.android,
      Size(800, 1200),
      true,
      LibraryCategory.artists,
      false,
      false,
    ),
    (
      'tablet_landscape_tracks',
      YYPlatform.android,
      Size(1024, 768),
      false,
      LibraryCategory.tracks,
      false,
      false,
    ),
    (
      'windows_dark_albums',
      YYPlatform.windows,
      Size(1440, 1000),
      true,
      LibraryCategory.albums,
      false,
      false,
    ),
    (
      'windows_narrow_menu',
      YYPlatform.windows,
      Size(840, 900),
      false,
      LibraryCategory.tracks,
      false,
      true,
    ),
  ]) {
    testWidgets(
      'Phase6F Library $name at 130 percent',
      (tester) async {
        final fixture = LibraryGraphFixture(count: empty ? 0 : 24);
        fixture.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        debugDisableShadows = false;
        try {
          await mountLibrary(tester, fixture, platform: platform, size: size);
          fixture.graph.libraryController.selectCategory(category);
          await tester.pumpAndSettle();
          if (menu) {
            final tile = find.byType(YYTrackTile).first;
            await tester.ensureVisible(tile);
            await tester.pumpAndSettle();
            await tester.longPress(tile);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('library-golden')),
            matchesGoldenFile('baselines/library_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await closeLibrary(tester, fixture);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
