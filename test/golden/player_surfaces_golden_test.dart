import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_artwork_placeholder.dart';
import 'package:yymusic/design_system/yy_player_data.dart';
import 'package:yymusic/design_system/yy_player_surface.dart';
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
      'Phase2F player surfaces $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 560);
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
        try {
          await tester.pumpWidget(
            designHarness(
              const _GoldenFrame(
                key: ValueKey('player-board'),
                child: _PlayerBoard(),
              ),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('player-board')),
            matchesGoldenFile('baselines/player_surfaces_$name.png'),
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

class _PlayerBoard extends StatelessWidget {
  const _PlayerBoard();

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
      shuffle: true,
      repeat: YYRepeatState.one,
    );
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YYMusic · Player Surfaces', style: YYTypography.pageTitle),
          const SizedBox(height: 6),
          Text(
            'Phase 2F · 受控 Fixture / 130% / 不调用音频与队列',
            style: YYTypography.caption,
          ),
          const SizedBox(height: 20),
          Text('Windows · 88dp', style: YYTypography.sectionTitle),
          const SizedBox(height: 8),
          YYDesktopPlayerBar(
            data: data,
            onOpen: _noop,
            onTogglePlayback: _noop,
            onPrevious: _noop,
            onNext: _noop,
            onToggleShuffle: _noop,
            onCycleRepeat: _noop,
            onToggleFavorite: _noop,
            onOpenFullscreen: _noop,
            onOpenLyrics: _noop,
            onOpenQueue: _noop,
            onOpenSettings: _noop,
            onSeekPreview: _noopValue,
            onSeekCommit: _noopValue,
            onVolumePreview: _noopValue,
            onVolumeCommit: _noopValue,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 816,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Windows Narrow · 76dp', style: YYTypography.caption),
                    const SizedBox(height: 6),
                    YYDesktopPlayerBar(
                      data: data,
                      compact: true,
                      onOpen: _noop,
                      onTogglePlayback: _noop,
                      onPrevious: _noop,
                      onNext: _noop,
                      onToggleShuffle: _noop,
                      onCycleRepeat: _noop,
                      onToggleFavorite: _noop,
                      onOpenFullscreen: _noop,
                      onOpenLyrics: _noop,
                      onOpenQueue: _noop,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Android Phone · 64dp', style: YYTypography.caption),
                    const SizedBox(height: 6),
                    YYMiniPlayer(
                      data: data,
                      onOpen: _noop,
                      onTogglePlayback: _noop,
                      onNext: _noop,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Loading / Disabled', style: YYTypography.caption),
          const SizedBox(height: 6),
          SizedBox(width: 390, child: YYMiniPlayer(data: data, loading: true)),
        ],
      ),
    );
  }
}

void _noop() {}
void _noopValue(double _) {}
