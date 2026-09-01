import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_context_menu.dart';
import 'package:yymusic/design_system/yy_dialog.dart';
import 'package:yymusic/design_system/yy_icon.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/features/design_gallery/gallery_overlay_primitives.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  const items = [
    YYContextMenuItem(
      id: 'play',
      label: '立即播放',
      glyph: YYGlyph.play,
      selected: true,
    ),
    YYContextMenuItem(
      id: 'loading',
      label: '添加到歌单',
      glyph: YYGlyph.playlist,
      loading: true,
    ),
    YYContextMenuItem(
      id: 'remove',
      label: '移除示例',
      glyph: YYGlyph.trash,
      enabled: false,
      danger: true,
      dividerBefore: true,
    ),
    YYContextMenuItem(id: 'queue', label: '添加到队列', glyph: YYGlyph.listPlus),
  ];

  testWidgets(
    'Context Menu keeps audited geometry and independent controlled states',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final selected = <String>[];
      try {
        await tester.pumpWidget(
          designHarness(
            Center(
              child: YYContextMenu(
                title: 'A Quiet Orbit',
                meta: 'Luna Harbor',
                items: items,
                autofocus: false,
                onSelected: selected.add,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getSize(find.byType(YYContextMenu)).width,
          YYOverlayMetrics.contextMenuWidth,
        );
        for (final item in items) {
          expect(
            tester
                .getSize(find.byKey(ValueKey('context-menu-item-${item.id}')))
                .height,
            YYOverlayMetrics.contextMenuItemHeight,
          );
        }
        final glass = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(YYContextMenu),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final glassDecoration = glass.decoration as BoxDecoration;
        expect(
          glassDecoration.borderRadius,
          BorderRadius.circular(YYRadius.contextMenu),
        );
        final selectedNode = tester.getSemantics(find.bySemanticsLabel('立即播放'));
        expect(selectedNode.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('添加到歌单'))
              .flagsCollection
              .isEnabled,
          ui.Tristate.isFalse,
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('移除示例'))
              .flagsCollection
              .isEnabled,
          ui.Tristate.isFalse,
        );

        await tester.tap(find.bySemanticsLabel('立即播放'));
        await tester.tap(find.bySemanticsLabel('添加到歌单'));
        await tester.tap(find.bySemanticsLabel('移除示例'));
        expect(selected, ['play']);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('Context Menu adapts to phone width at 130 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      designHarness(
        Center(
          child: YYContextMenu(
            title: 'A Quiet Orbit',
            items: items,
            autofocus: false,
          ),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(YYContextMenu)).width,
      YYOverlayMetrics.phoneContextMenuWidth,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Context Menu arrows wrap, activate, and Escape dismisses', (
    tester,
  ) async {
    final appearance = YYAppearanceController()..setReduceMotion(true);
    addTearDown(appearance.dispose);
    final selected = <String>[];
    var dismissed = 0;
    await tester.pumpWidget(
      designHarness(
        Center(
          child: YYContextMenu(
            items: items,
            onSelected: selected.add,
            onDismiss: () => dismissed++,
          ),
        ),
        appearance: appearance,
      ),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus?.debugLabel, contains('play'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, contains('queue'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, contains('play'));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(selected, ['play']);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(dismissed, 1);
  });

  testWidgets('Dialog keeps 680/30/72 geometry, traps focus, and restores it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previous = FocusNode(debugLabel: 'previous-control');
    final cancel = FocusNode(debugLabel: 'dialog-cancel');
    final complete = FocusNode(debugLabel: 'dialog-complete');
    addTearDown(previous.dispose);
    addTearDown(cancel.dispose);
    addTearDown(complete.dispose);
    late StateSetter setHostState;
    var visible = false;
    var dismissals = 0;
    final appearance = YYAppearanceController()..setReduceMotion(true);
    addTearDown(appearance.dispose);

    await tester.pumpWidget(
      designHarness(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            void dismiss() {
              dismissals++;
              setState(() => visible = false);
            }

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  YYButton(
                    label: '打开设置',
                    focusNode: previous,
                    onPressed: () => setState(() => visible = true),
                  ),
                  if (visible)
                    YYDialog(
                      title: '播放设置',
                      subtitle: 'Dialog Fixture',
                      onClose: dismiss,
                      body: const Text('受控内容'),
                      actions: [
                        YYButton(
                          label: '取消',
                          focusNode: cancel,
                          onPressed: dismiss,
                        ),
                        YYButton(
                          label: '完成',
                          focusNode: complete,
                          onPressed: dismiss,
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
        appearance: appearance,
        scale: 1.3,
      ),
    );
    previous.requestFocus();
    await tester.pump();
    expect(previous.hasFocus, isTrue);
    setHostState(() => visible = true);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('yy-dialog'))).width,
      YYOverlayMetrics.dialogMaxWidth,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('yy-modal-header'))).height,
      greaterThanOrEqualTo(YYOverlayMetrics.dialogSectionMinHeight),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('yy-modal-footer'))).height,
      greaterThanOrEqualTo(YYOverlayMetrics.dialogSectionMinHeight),
    );
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('yy-modal-surface')),
    );
    expect(
      (surface.decoration as BoxDecoration).borderRadius,
      BorderRadius.circular(YYRadius.dialog),
    );
    final dialogSemantics = tester.getSemantics(
      find.bySemanticsLabel('对话框，播放设置'),
    );
    expect(
      dialogSemantics.getSemanticsData().flagsCollection.scopesRoute,
      isTrue,
    );
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'YY modal close');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(cancel.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(complete.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'YY modal close');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(YYDialog), findsNothing);
    expect(dismissals, 1);
    expect(previous.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bottom Sheet is full-width, safe, and stable at 130 percent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var closed = 0;
    await tester.pumpWidget(
      designHarness(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(padding: const EdgeInsets.only(top: 24, bottom: 20)),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: YYBottomSheet(
                title: '添加到歌单',
                subtitle: 'Phone Fixture',
                autofocus: false,
                onClose: () => closed++,
                body: const Text('受控内容，不读取真实歌单。'),
                actions: [YYButton(label: '取消', onPressed: () => closed++)],
              ),
            ),
          ),
        ),
        scale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('yy-bottom-sheet'))).width,
      390,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('yy-bottom-sheet'))).height,
      lessThanOrEqualTo(752),
    );
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('yy-modal-surface')),
    );
    expect(
      (surface.decoration as BoxDecoration).borderRadius,
      const BorderRadius.vertical(top: Radius.circular(YYRadius.dialog)),
    );
    await tester.tap(find.bySemanticsLabel('关闭添加到歌单'));
    await tester.tap(find.bySemanticsLabel('取消'));
    expect(closed, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Toast is controlled, live, motion-safe, and Gallery stays local',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final appearance = YYAppearanceController()..setReduceMotion(true);
      addTearDown(appearance.dispose);
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          designHarness(
            const SingleChildScrollView(
              child: GalleryOverlayPrimitives(platform: YYPlatform.windows),
            ),
            appearance: appearance,
            scale: 1.3,
          ),
        );
        await tester.pumpAndSettle();

        final toast = find.byKey(const ValueKey('yy-toast'));
        expect(tester.getSize(toast).height, greaterThanOrEqualTo(42));
        expect(tester.getSize(toast).width, lessThanOrEqualTo(420));
        expect(
          tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).duration,
          Duration.zero,
        );
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration,
          Duration.zero,
        );
        final toastNode = tester.getSemantics(
          find.bySemanticsLabel('Fixture 操作已记录'),
        );
        expect(
          toastNode.getSemanticsData().flagsCollection.isLiveRegion,
          isTrue,
        );

        await tester.tap(find.bySemanticsLabel('立即播放'));
        await tester.pump();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('overlay-fixture-status')),
              )
              .data,
          'Fixture：选择菜单 play（未执行业务）',
        );
        await tester.tap(find.bySemanticsLabel('隐藏 Toast Fixture'));
        await tester.pump();
        expect(find.bySemanticsLabel('Fixture：选择菜单 play（未执行业务）'), findsNothing);
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          0,
        );
        await tester.pump(const Duration(seconds: 3));
        expect(
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
          0,
        );
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );
}
