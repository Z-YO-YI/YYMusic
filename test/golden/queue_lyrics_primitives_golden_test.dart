import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_artwork_placeholder.dart';
import 'package:yymusic/design_system/yy_lyrics_line.dart';
import 'package:yymusic/design_system/yy_lyrics_player_dock.dart';
import 'package:yymusic/design_system/yy_player_data.dart';
import 'package:yymusic/design_system/yy_queue_tile.dart';
import 'package:yymusic/design_system/yy_surface.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  for (final (name, mode, accent, reduced) in const [
    ('light_coral', YYThemeMode.light, '#FF3B5C', false),
    ('dark_jade', YYThemeMode.dark, '#00A67E', false),
    ('light_white_reduced', YYThemeMode.light, '#FFFFFF', true),
  ]) {
    testWidgets(
      'Phase2J queue and lyrics primitives $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final appearance = YYAppearanceController()
          ..setMode(mode)
          ..setCustomAccent(accent)
          ..setReduceGlass(reduced)
          ..setReduceMotion(true);
        addTearDown(appearance.dispose);
        debugDisableShadows = false;
        final mouse = await tester.createGesture(
          kind: ui.PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        try {
          await tester.pumpWidget(
            designHarness(
              const _GoldenFrame(
                key: ValueKey('queue-lyrics-board'),
                child: _QueueLyricsBoard(),
              ),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          await mouse.moveTo(
            tester.getCenter(
              find.byKey(const ValueKey('queue-golden-current')),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('queue-lyrics-board')),
            matchesGoldenFile('baselines/queue_lyrics_primitives_$name.png'),
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

class _GoldenFrame extends StatelessWidget {
  const _GoldenFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(color: YYTheme.of(context).colors.base, child: child),
  );
}

class _QueueLyricsBoard extends StatelessWidget {
  const _QueueLyricsBoard();

  @override
  Widget build(BuildContext context) {
    final data = YYNowPlayingViewData(
      title: 'A Quiet Orbit',
      artist: 'Luna Harbor · Fixture',
      position: const Duration(minutes: 1, seconds: 14),
      duration: const Duration(minutes: 3, seconds: 48),
      artwork: YYArtworkKind.orbit,
      playing: true,
      favorite: true,
    );
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YYMusic · Queue & Lyrics Primitives',
            style: YYTypography.pageTitle,
          ),
          const SizedBox(height: 6),
          Text(
            'Phase 2J · 受控 Fixture / 130% / 无队列算法、Seek、计时与全屏路由',
            style: YYTypography.caption,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 440,
                  child: YYSurface(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Queue Tile', style: YYTypography.sectionTitle),
                        const SizedBox(height: 10),
                        YYQueueTile(
                          key: const ValueKey('queue-golden-current'),
                          title: 'A Quiet Orbit',
                          meta: 'Luna Harbor · Fixture',
                          durationLabel: '3:48',
                          artwork: YYArtworkKind.orbit,
                          current: true,
                          onPressed: _noop,
                          onMoveUp: _noop,
                          onMoveDown: _noop,
                          onRemove: _noop,
                        ),
                        const SizedBox(height: 6),
                        const YYQueueTile(
                          title: 'Slow Lines · Immersive',
                          meta: 'Mira Coast · Fixture',
                          durationLabel: '4:12',
                          artwork: YYArtworkKind.tide,
                          density: YYQueueTileDensity.immersive,
                          onPressed: _noop,
                          onMoveUp: _noop,
                          onMoveDown: _noop,
                          onRemove: _noop,
                        ),
                        const SizedBox(height: 6),
                        const YYQueueTile(
                          title: '禁用队列项',
                          meta: '受控状态 · Fixture',
                          durationLabel: '2:56',
                          artwork: YYArtworkKind.noon,
                          onPressed: null,
                        ),
                        const SizedBox(height: 6),
                        const YYQueueTile(
                          title: '加载队列项',
                          meta: '不创建任务',
                          durationLabel: '--:--',
                          artwork: YYArtworkKind.local,
                          loading: true,
                          onPressed: _noop,
                          onMoveUp: _noop,
                          onMoveDown: _noop,
                          onRemove: _noop,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: ColoredBox(
                      color: const Color(0xFF3D4A52),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'LYRICS · SOLID ATMOSPHERE',
                              style: YYTypography.text(
                                size: 9,
                                weight: 760,
                                spacing: .9,
                                color: const Color(0x94FFFFFF),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const YYLyricsLine(
                              text: 'Hold the light',
                              translation: '留住微光',
                              state: YYLyricsLineState.past,
                              onPressed: _noop,
                            ),
                            const SizedBox(height: 22),
                            const YYLyricsLine(
                              text: 'Stay with me',
                              translation: '与我同行',
                              state: YYLyricsLineState.active,
                              onPressed: _noop,
                            ),
                            const SizedBox(height: 22),
                            const YYLyricsLine(
                              text: 'Follow the tide',
                              translation: '跟随潮汐',
                              state: YYLyricsLineState.future,
                              onPressed: _noop,
                            ),
                            const Spacer(),
                            YYLyricsPlayerDock(
                              data: data,
                              atmosphereColor: const Color(0xFF3D4A52),
                              onPrevious: _noop,
                              onTogglePlayback: _noop,
                              onNext: _noop,
                              onSeekPreview: _noopValue,
                              onSeekCommit: _noopValue,
                              onToggleFavorite: _noop,
                              onReturnToPlayer: _noop,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}
void _noopValue(double _) {}
