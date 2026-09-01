import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_album_card.dart';
import 'package:yymusic/design_system/yy_artwork_placeholder.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/design_system/yy_track_tile.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);
  for (final (name, mode, hex) in [
    ('light_coral', YYThemeMode.light, '#FF3B5C'),
    ('dark_jade', YYThemeMode.dark, '#00A67E'),
    ('light_white', YYThemeMode.light, '#FFFFFF'),
  ]) {
    testWidgets(
      'Phase2D content cards $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1080);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final appearance = YYAppearanceController()
          ..setMode(mode)
          ..setCustomAccent(hex)
          ..setReduceMotion(true);
        addTearDown(appearance.dispose);
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            designHarness(
              const _ContentCardBoard(),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('content-card-board')),
            matchesGoldenFile('baselines/content_cards_$name.png'),
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

class _ContentCardBoard extends StatelessWidget {
  const _ContentCardBoard();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const ValueKey('content-card-board'),
    child: ColoredBox(
      color: YYTheme.of(context).colors.base,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('YYMusic', style: YYTypography.phoneTitle),
            const SizedBox(height: 8),
            Text(
              'Phase 2D · 内容组件 Fixture\n130% 字号 · 非真实曲库或播放',
              style: YYTypography.caption,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final width = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: 18,
                  children: [
                    SizedBox(
                      width: width,
                      child: YYAlbumCard(
                        title: 'A Quiet Orbit',
                        subtitle: 'Luna Harbor · EP',
                        artwork: YYArtworkKind.orbit,
                        selected: true,
                        onPressed: _noop,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: const YYAlbumCard(
                        title: 'Blue Hour',
                        subtitle: '禁用状态',
                        artwork: YYArtworkKind.tide,
                        onPressed: null,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: const YYAlbumCard(
                        title: 'Noon Geometry',
                        subtitle: '加载状态',
                        artwork: YYArtworkKind.noon,
                        loading: true,
                        onPressed: _noop,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            const YYTrackTile(
              title: 'A Quiet Orbit',
              subtitle: 'Luna Harbor · The Small Hours',
              sourceLabel: 'Cloud API',
              durationLabel: '3:48',
              artwork: YYArtworkKind.orbit,
              playing: true,
              onPressed: _noop,
              onMore: _noop,
            ),
            const YYTrackTile(
              title: 'Slow Lines',
              subtitle: 'Mira Coast · Blue Hour',
              sourceLabel: '本地',
              durationLabel: '4:12',
              artwork: YYArtworkKind.tide,
              onPressed: _noop,
              onMore: _noop,
            ),
            const YYTrackTile(
              title: 'Warm Static',
              subtitle: '禁用状态',
              sourceLabel: 'REST',
              durationLabel: '2:56',
              artwork: YYArtworkKind.noon,
              onPressed: null,
            ),
            const YYTrackTile(
              title: 'Current No. 4',
              subtitle: '加载状态',
              sourceLabel: 'Cloud API',
              durationLabel: '5:03',
              artwork: YYArtworkKind.mono,
              loading: true,
              onPressed: _noop,
            ),
          ],
        ),
      ),
    ),
  );
}

void _noop() {}
