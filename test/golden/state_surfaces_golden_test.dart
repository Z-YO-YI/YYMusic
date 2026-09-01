import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_feedback.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_surface.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_theme_swatch.dart';
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
      'Phase2H state surfaces $name at 130 percent',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
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
                key: ValueKey('state-surfaces-board'),
                child: _StateSurfacesBoard(),
              ),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('state-surfaces-board')),
            matchesGoldenFile('baselines/state_surfaces_$name.png'),
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

class _StateSurfacesBoard extends StatelessWidget {
  const _StateSurfacesBoard();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YYMusic · State Surfaces', style: YYTypography.pageTitle),
        const SizedBox(height: 6),
        Text(
          'Phase 2H · 受控 Fixture / 130% / 无渐变、网络、计时器与假数据',
          style: YYTypography.caption,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in YYAccentPreset.values)
              YYThemeSwatch(
                label: preset.label,
                color: Color(preset.argb),
                selected: preset == YYAccentPreset.coral,
                onPressed: _noop,
              ),
            const YYThemeSwatch(
              label: '自定义白色',
              color: Color(0xFFFFFFFF),
              selected: true,
              onPressed: _noop,
            ),
            const YYThemeSwatch(
              label: '加载主题色',
              color: Color(0xFF00A67E),
              selected: false,
              loading: true,
              onPressed: _noop,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: YYSurface(
                  padding: EdgeInsets.zero,
                  child: YYEmptyState(
                    message: '播放队列为空。\n可从歌曲“更多”菜单添加。',
                    glyph: YYGlyph.queue,
                    action: YYButton(label: '浏览 Fixture', onPressed: _noop),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const YYErrorBanner(
                      title: '示例音乐源暂不可用',
                      message: '静态错误 Fixture，不代表设备当前网络状态。',
                      actionLabel: '重试',
                      onAction: _noop,
                    ),
                    const SizedBox(height: 12),
                    const YYErrorBanner(
                      title: '操作暂不可用',
                      message: '禁用态与加载态独立于视觉层级。',
                      actionLabel: '不可用',
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: YYSurface(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '纯色 Skeleton',
                              style: YYTypography.text(weight: 700),
                            ),
                            const SizedBox(height: 16),
                            const YYSkeleton(height: 18, width: 240),
                            const SizedBox(height: 12),
                            const YYSkeleton(height: 14),
                            const SizedBox(height: 10),
                            const YYSkeleton(height: 14, width: 360),
                            const SizedBox(height: 24),
                            Text('静止、无渐变、不生成虚构内容', style: YYTypography.caption),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _noop() {}
