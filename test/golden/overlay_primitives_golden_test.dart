import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/design_system/yy_dialog.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_toast.dart';
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
      'Phase2G overlay primitives $name at 130 percent',
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
                key: ValueKey('overlay-board'),
                child: _OverlayBoard(),
              ),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('overlay-board')),
            matchesGoldenFile('baselines/overlay_primitives_$name.png'),
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

class _OverlayBoard extends StatelessWidget {
  const _OverlayBoard();

  static const _items = [
    YYContextMenuItem(id: 'play', label: '立即播放', glyph: YYGlyph.play),
    YYContextMenuItem(id: 'next', label: '下一首播放', glyph: YYGlyph.next),
    YYContextMenuItem(id: 'queue', label: '添加到队列', glyph: YYGlyph.listPlus),
    YYContextMenuItem(
      id: 'favorite',
      label: '添加到喜欢',
      glyph: YYGlyph.heart,
      selected: true,
      dividerBefore: true,
    ),
    YYContextMenuItem(
      id: 'playlist',
      label: '添加到歌单',
      glyph: YYGlyph.playlist,
      loading: true,
    ),
    YYContextMenuItem(
      id: 'remove',
      label: '移除示例',
      glyph: YYGlyph.trash,
      danger: true,
      enabled: false,
    ),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YYMusic · Overlay Primitives', style: YYTypography.pageTitle),
        const SizedBox(height: 6),
        Text(
          'Phase 2G · 受控 Fixture / 130% / 无路由、计时器与真实业务',
          style: YYTypography.caption,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 224,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Context Menu · Glass', style: YYTypography.caption),
                    const SizedBox(height: 8),
                    YYContextMenu(
                      title: 'A Quiet Orbit',
                      meta: 'Luna Harbor · Fixture',
                      items: _items,
                      autofocus: false,
                    ),
                    const Spacer(),
                    const YYToast(message: 'Fixture 操作已记录', visible: true),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 680,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Windows · Opaque Dialog',
                      style: YYTypography.caption,
                    ),
                    const SizedBox(height: 8),
                    YYDialog(
                      title: '播放设置',
                      subtitle: '受控 Dialog Fixture，不读取设备或睡眠计时',
                      autofocus: false,
                      onClose: _noop,
                      body: const _FixtureBody(
                        title: '输出设备',
                        detail: '系统默认设备 · Fixture only',
                      ),
                      actions: [
                        YYButton(label: '取消', onPressed: _noop),
                        YYButton(
                          label: '完成',
                          glyph: YYGlyph.check,
                          style: YYButtonStyle.primary,
                          onPressed: _noop,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 248,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Android · Bottom Sheet', style: YYTypography.caption),
                    const Spacer(),
                    YYBottomSheet(
                      title: '添加到歌单',
                      subtitle: 'Phone Fixture',
                      autofocus: false,
                      onClose: _noop,
                      body: const _FixtureBody(
                        title: '最近使用',
                        detail: '专注工作 · 未读取真实歌单',
                      ),
                      actions: [YYButton(label: '取消', onPressed: _noop)],
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

class _FixtureBody extends StatelessWidget {
  const _FixtureBody({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = YYTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: YYTypography.text(weight: 700)),
        const SizedBox(height: 8),
        Text(
          detail,
          style: YYTypography.caption.copyWith(color: colors.secondary),
        ),
      ],
    );
  }
}

void _noop() {}
