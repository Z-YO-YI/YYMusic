import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_artwork_placeholder.dart';
import 'package:yymusic/design_system/yy_navigation.dart';
import 'package:yymusic/design_system/yy_slider.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/shells/shell_chrome.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);
  for (final (name, mode, color, reduced) in [
    ('light_coral', YYThemeMode.light, '#FF3B5C', false),
    ('dark_jade', YYThemeMode.dark, '#00A67E', false),
    ('light_white_reduced', YYThemeMode.light, '#FFFFFF', true),
  ]) {
    testWidgets(
      'Phase2B controls $name',
      (tester) async {
        // This is a full component contact sheet, not a device viewport.
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final appearance = YYAppearanceController()
          ..setMode(mode)
          ..setCustomAccent(color)
          ..setReduceGlass(reduced)
          ..setReduceMotion(true);
        addTearDown(appearance.dispose);
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            designHarness(
              const _GoldenCanvas(
                key: ValueKey('board'),
                child: _ControlsBoard(),
              ),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('board')),
            matchesGoldenFile('baselines/controls_$name.png'),
          );
        } finally {
          debugDisableShadows = true;
        }
      },
      skip: !Platform.isWindows,
      tags: ['windows-golden'],
    );
  }
  for (final (name, size) in [
    ('phone', const Size(390, 844)),
    ('tablet', const Size(600, 900)),
  ]) {
    testWidgets(
      'real Android $name shell with native navigation',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewPadding);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final graph = DependencyGraph();
        graph.appearance.setReduceMotion(true);
        debugDisableShadows = false;
        try {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                dependencyGraphProvider.overrideWith((ref) {
                  ref.onDispose(graph.dispose);
                  return graph;
                }),
              ],
              child: const RepaintBoundary(
                key: ValueKey('app'),
                child: YYMusicApp(platform: YYPlatform.android),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('app')),
            matchesGoldenFile('baselines/android_${name}_130.png'),
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

class _GoldenCanvas extends StatelessWidget {
  const _GoldenCanvas({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(color: YYTheme.of(context).colors.base, child: child),
  );
}

class _ControlsBoard extends StatelessWidget {
  const _ControlsBoard();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YYMusic · Android', style: YYTypography.pageTitle),
        const SizedBox(height: 8),
        Text(
          'Phase 2B · 导航 / 滑块 / 几何占位 · 字号 130%',
          style: YYTypography.caption,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YYTabletNavigationRail(
              height: 300,
              destinations: androidDestinations,
              selectedIndex: 2,
              onSelected: (_) {},
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phone · 64 / 32', style: YYTypography.sectionTitle),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 390,
                    child: YYMobileBottomNavigation(
                      destinations: androidDestinations,
                      selectedIndex: 0,
                      onSelected: (_) {},
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('进度示例 · 3dp / 14dp', style: YYTypography.caption),
                  YYSlider(label: '进度示例', value: .42, onChanged: (_) {}),
                  const SizedBox(height: 12),
                  Text('不可用 / 加载中', style: YYTypography.caption),
                  const YYSlider(label: '不可用', value: .6, onChanged: null),
                  const YYSlider(
                    label: '加载中',
                    value: 0,
                    loading: true,
                    onChanged: null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('无封面 Fixture · 非真实专辑', style: YYTypography.sectionTitle),
        const SizedBox(height: 20),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            for (final kind in YYArtworkKind.values)
              SizedBox(
                width: 160,
                child: Column(
                  children: [
                    YYArtworkPlaceholder(kind: kind, dimension: 160),
                    const SizedBox(height: 8),
                    Text(kind.name, style: YYTypography.caption),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
