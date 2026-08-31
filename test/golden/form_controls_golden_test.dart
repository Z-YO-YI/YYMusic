import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_search_field.dart';
import 'package:yymusic/design_system/yy_segmented_control.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_toggle.dart';
import 'package:yymusic/design_system/yy_tokens.dart';

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
      'Phase2C form controls $name at 130 percent',
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
              const _FormBoard(),
              appearance: appearance,
              scale: 1.3,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('form-board')),
            matchesGoldenFile('baselines/forms_$name.png'),
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

class _FormBoard extends StatefulWidget {
  const _FormBoard();
  @override
  State<_FormBoard> createState() => _FormBoardState();
}

class _FormBoardState extends State<_FormBoard> {
  final _empty = TextEditingController();
  final _text = TextEditingController(text: '音乐 Music · 输入示例');
  final _error = TextEditingController(text: '未提交的示例');
  final _disabled = TextEditingController(text: '不可用');
  final _loading = TextEditingController(text: '加载状态展示');
  @override
  void dispose() {
    for (final controller in [_empty, _text, _error, _disabled, _loading]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const ValueKey('form-board'),
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
              'Phase 2C · 原生输入与选择\n130% 字号 · 非真实搜索结果',
              style: YYTypography.caption,
            ),
            const SizedBox(height: 24),
            YYSearchField(controller: _empty, label: '空输入'),
            const SizedBox(height: 16),
            YYSearchField(controller: _text, label: '有内容'),
            const SizedBox(height: 16),
            YYSearchField(
              controller: _error,
              label: '错误状态',
              errorText: '示例校验消息 · 不发送网络请求',
            ),
            const SizedBox(height: 16),
            YYSearchField(controller: _disabled, label: '禁用', enabled: false),
            const SizedBox(height: 16),
            YYSearchField(controller: _loading, label: '加载', loading: true),
            const SizedBox(height: 24),
            Text('分段选择', style: YYTypography.sectionTitle),
            const SizedBox(height: 12),
            YYSegmentedControl<int>(
              label: '示例类型',
              value: 1,
              segments: const [
                YYSegment(value: 0, label: '全部'),
                YYSegment(value: 1, label: '歌曲'),
                YYSegment(value: 2, label: '专辑'),
                YYSegment(value: 3, label: '不可用', enabled: false),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 12),
            YYSegmentedControl<int>(
              label: '禁用分段',
              value: 0,
              segments: const [
                YYSegment(value: 0, label: '不可用'),
                YYSegment(value: 1, label: '未选择'),
              ],
              onChanged: null,
            ),
            const SizedBox(height: 24),
            Text('开关 · 46 / 28 / 22', style: YYTypography.sectionTitle),
            const SizedBox(height: 12),
            for (final (label, value, enabled, loading) in [
              ('关闭', false, true, false),
              ('开启', true, true, false),
              ('禁用', true, false, false),
              ('加载状态', false, true, true),
            ])
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: YYTypography.text(size: 13, weight: 680),
                    ),
                  ),
                  YYToggle(
                    label: label,
                    value: value,
                    loading: loading,
                    onChanged: enabled ? (_) {} : null,
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
