import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/features/player/common/shell_player.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/playback_graph_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);
  for (final (name, width, mode, accent, failure) in const [
    ('windows_light', 320.0, YYThemeMode.light, '#FF3B5C', false),
    ('tablet_dark', 260.0, YYThemeMode.dark, '#00A67E', false),
    ('error_white', 320.0, YYThemeMode.light, '#FFFFFF', true),
  ]) {
    testWidgets(
      'Phase5B inspector $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = Size(width, 980);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final fixture = PlaybackGraphFixture();
        fixture.graph.appearance
          ..setMode(mode)
          ..setCustomAccent(accent)
          ..setReduceMotion(true);
        await fixture.queue();
        if (failure) fixture.engine.loadError = StateError('fixture failure');
        await fixture.graph.playbackPresenter.togglePlayback();
        if (!failure) {
          await fixture.graph.playback.seek(const Duration(seconds: 74));
          await fixture.graph.playback.play();
        }
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            designHarness(
              RepaintBoundary(
                key: const ValueKey('inspector'),
                child: ShellPlayer(
                  presenter: fixture.graph.playbackPresenter,
                  inspector: true,
                ),
              ),
              appearance: fixture.graph.appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('inspector')),
            matchesGoldenFile('baselines/inspector_${name}_130.png'),
          );
        } finally {
          debugDisableShadows = true;
          await tester.pumpWidget(const SizedBox.shrink());
          await closeGraph(tester, fixture.graph);
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
}
