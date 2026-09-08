import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/domain/models/lyrics.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/lyrics_fixture.dart';
import '../support/native_lyrics_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, state) in const [
    ('phone', YYPlatform.android, Size(390, 844), 'data'),
    ('phone_landscape', YYPlatform.android, Size(590, 360), 'data'),
    ('tablet_portrait', YYPlatform.android, Size(800, 1280), 'data'),
    ('tablet_landscape', YYPlatform.android, Size(1280, 800), 'data'),
    ('windows', YYPlatform.windows, Size(1440, 900), 'data'),
    ('windows_narrow', YYPlatform.windows, Size(500, 640), 'data'),
    ('phone_empty', YYPlatform.android, Size(360, 800), 'empty'),
    ('phone_missing', YYPlatform.android, Size(390, 844), 'missing'),
    ('tablet_loading', YYPlatform.android, Size(844, 390), 'loading'),
    ('windows_error', YYPlatform.windows, Size(840, 640), 'error'),
    ('windows_plain', YYPlatform.windows, Size(1024, 720), 'plain'),
  ]) {
    testWidgets(
      'independent lyrics $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final gate = Completer<LyricsDocument?>();
        late LyricsFixture fixture;
        await tester.runAsync(() async {
          fixture = LyricsFixture();
          fixture.graph.appearance.setReduceMotion(true);
          if (state == 'empty') {
            await fixture.graph.initialize();
          } else {
            await fixture.initialize();
            await fixture.graph.playback.seek(const Duration(seconds: 15));
            await fixture.graph.playback.play();
          }
          if (state == 'missing') fixture.repository.documents.clear();
          if (state == 'loading') fixture.repository.onGet = (_) => gate.future;
          if (state == 'error') {
            fixture.repository.onGet = (_) async =>
                throw StateError('Test-only error');
          }
          if (state == 'plain') {
            fixture.repository.documents[lyricsTracks.first.ref] =
                LyricsDocument(
                  track: lyricsTracks.first.ref,
                  kind: LyricsKind.plain,
                  language: 'en',
                  lines: [
                    LyricsLine(text: 'Test-only plain lyrics'),
                    LyricsLine(text: 'Read without synchronized timestamps'),
                  ],
                );
          }
        });
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                dependencyGraphProvider.overrideWith((ref) {
                  ref.onDispose(fixture.graph.dispose);
                  return fixture.graph;
                }),
              ],
              child: RepaintBoundary(
                key: const ValueKey('native-lyrics-golden'),
                child: YYMusicApp(
                  platform: platform,
                  initialLocation: '/lyrics',
                ),
              ),
            ),
          );
          await settleLyrics(tester);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('native-lyrics-golden')),
            matchesGoldenFile('baselines/native_lyrics_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          gate.complete(null);
          await tester.pumpWidget(const SizedBox.shrink());
          await closeGraph(tester, fixture.graph);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
