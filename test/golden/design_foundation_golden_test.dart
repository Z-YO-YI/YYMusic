import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_profile_header.dart';
import 'package:yymusic/design_system/yy_surface.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);
  for (final mode in [YYThemeMode.light, YYThemeMode.dark]) {
    testWidgets(
      'native components ${mode.name} at 390dp and 130 percent',
      (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        debugDisableShadows = false;
        try {
          final appearance = YYAppearanceController()
            ..setMode(mode)
            ..setReduceMotion(true);
          addTearDown(appearance.dispose);
          await tester.pumpWidget(
            designHarness(
              const _GoldenFrame(
                key: ValueKey('golden'),
                child: _ComponentBoard(),
              ),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('golden')),
            matchesGoldenFile('baselines/components_${mode.name}_390_130.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
  testWidgets(
    'all 44 original SVGs in the native icon atlas',
    (tester) async {
      tester.view.physicalSize = const Size(800, 590);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        designHarness(
          _GoldenFrame(
            key: const ValueKey('atlas'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEW_ICON_SPRITE · 44',
                    style: YYTypography.sectionTitle,
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 18,
                    children: [
                      for (final glyph in YYGlyph.values)
                        SizedBox(
                          width: 86,
                          height: 62,
                          child: Column(
                            children: [
                              YYIcon(glyph: glyph, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                glyph.assetName,
                                textAlign: TextAlign.center,
                                style: YYTypography.text(size: 10),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('atlas')),
        matchesGoldenFile('baselines/icon_atlas_800.png'),
      );
    },
    skip: !Platform.isWindows,
    tags: ['windows-golden'],
  );
}

class _GoldenFrame extends StatelessWidget {
  const _GoldenFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(color: YYTheme.of(context).colors.base, child: child),
  );
}

class _ComponentBoard extends StatelessWidget {
  const _ComponentBoard();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('YYMusic', style: YYTypography.phoneTitle),
        const SizedBox(height: 8),
        Text(
          'Android · Phase 2A\n原生组件回归 / 字号 130%',
          style: YYTypography.caption,
        ),
        const SizedBox(height: 24),
        const YYSurface(child: YYProfileHeader()),
        const SizedBox(height: 24),
        Text('按钮与状态', style: YYTypography.sectionTitle),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            YYButton(
              label: '主操作',
              glyph: YYGlyph.plus,
              style: YYButtonStyle.primary,
              onPressed: () {},
            ),
            YYButton(
              label: '已选择',
              glyph: YYGlyph.check,
              selected: true,
              onPressed: () {},
            ),
            YYIconButton(
              glyph: YYGlyph.heart,
              label: '示例收藏',
              selected: true,
              onPressed: () {},
            ),
            const YYButton(
              label: '播放未接入',
              glyph: YYGlyph.play,
              onPressed: null,
            ),
            const YYButton(
              label: '加载状态示例',
              glyph: YYGlyph.more,
              loading: true,
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(height: 28),
        const YYGlassSurface(
          height: 100,
          child: Row(
            children: [
              YYIcon(glyph: YYGlyph.music, size: 28),
              SizedBox(width: 12),
              Expanded(child: Text('局部玻璃表面')),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const YYSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('中文与 English 123'),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  YYIcon(glyph: YYGlyph.home),
                  YYIcon(glyph: YYGlyph.search),
                  YYIcon(glyph: YYGlyph.library),
                  YYIcon(glyph: YYGlyph.settings),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
