import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/features/search/common/search_controller.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/search_graph_fixture.dart';

void main() {
  setUpAll(loadDesignAssets);
  for (final (name, platform, size, dark, query, filter, offset, error)
      in const [
        (
          'phone_idle',
          YYPlatform.android,
          Size(390, 844),
          false,
          '',
          SearchFilter.all,
          0.0,
          false,
        ),
        (
          'phone_results',
          YYPlatform.android,
          Size(390, 1000),
          false,
          '夜',
          SearchFilter.all,
          260.0,
          false,
        ),
        (
          'tablet_portrait_dark',
          YYPlatform.android,
          Size(800, 1200),
          true,
          '夜',
          SearchFilter.all,
          0.0,
          false,
        ),
        (
          'tablet_landscape_albums',
          YYPlatform.android,
          Size(1024, 768),
          false,
          '夜',
          SearchFilter.albums,
          160.0,
          false,
        ),
        (
          'windows_dark',
          YYPlatform.windows,
          Size(1440, 1000),
          true,
          '夜',
          SearchFilter.tracks,
          0.0,
          false,
        ),
        (
          'windows_narrow_error',
          YYPlatform.windows,
          Size(840, 900),
          false,
          '夜',
          SearchFilter.online,
          0.0,
          true,
        ),
      ]) {
    testWidgets(
      'Phase6D search $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final fixture = SearchGraphFixture();
        fixture.repository.remoteFailure = error;
        fixture.graph.appearance
          ..setMode(dark ? YYThemeMode.dark : YYThemeMode.light)
          ..setReduceMotion(true);
        await fixture.graph.initialize();
        fixture.graph.search
          ..selectFilter(filter)
          ..updateInput(query);
        if (query.isNotEmpty) await fixture.graph.search.submit();
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                dependencyGraphProvider.overrideWithValue(fixture.graph),
              ],
              child: RepaintBoundary(
                key: const ValueKey('search-golden'),
                child: YYMusicApp(
                  platform: platform,
                  initialLocation: '/search',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (offset > 0) {
            tester
                .widget<CustomScrollView>(
                  find.byKey(const ValueKey('screen-search')),
                )
                .controller!
                .jumpTo(offset);
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('search-golden')),
            matchesGoldenFile('baselines/search_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
          await tester.pumpWidget(const SizedBox.shrink());
          await closeGraph(tester, fixture.graph);
          await tester.runAsync(fixture.disposeFakes);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
