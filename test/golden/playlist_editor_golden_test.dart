import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

import '../support/design_harness.dart';
import '../support/fake_domain_repositories.dart';
import '../support/library_graph_fixture.dart';
import '../widget/library_screen_test.dart' show closeLibrary;
import '../widget/playlist_editor_test.dart'
    show editorPlaylist, showPlaylists, openPlaylistEditor;

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, action) in const [
    (
      'phone_create',
      YYPlatform.android,
      Size(390, 1000),
      false,
      'playlist-create',
    ),
    (
      'tablet_rename',
      YYPlatform.android,
      Size(800, 1000),
      true,
      ('playlist-rename', 'custom'),
    ),
    (
      'windows_delete',
      YYPlatform.windows,
      Size(1024, 900),
      false,
      ('playlist-delete', 'custom'),
    ),
  ]) {
    testWidgets(
      'Phase6H2 playlist $name at 130 percent',
      (tester) async {
        final fixture = LibraryGraphFixture(
          collections: FakeCollectionRepository(playlists: [editorPlaylist()]),
        );
        fixture.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setPreset(dark ? YYAccentPreset.jade : YYAccentPreset.coral)
          ..setReduceMotion(true);
        debugDisableShadows = false;
        try {
          await showPlaylists(tester, fixture, platform: platform, size: size);
          await openPlaylistEditor(tester, action);
          // Capture stable editing chrome without depending on cursor blink time.
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('library-golden')),
            matchesGoldenFile('baselines/playlist_$name.png'),
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
