import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/design_system/yy_search_field.dart';
import 'package:yymusic/design_system/yy_segmented_control.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_toggle.dart';
import 'package:yymusic/features/design_gallery/gallery_input_controls.dart';

import '../support/design_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets(
    'toggle preserves CSS geometry, controlled state and switch semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var value = false;
        var changes = 0;
        await tester.pumpWidget(
          designHarness(
            Center(
              child: StatefulBuilder(
                builder: (context, setState) => YYToggle(
                  label: '减少透明',
                  value: value,
                  onChanged: (next) => setState(() {
                    value = next;
                    changes++;
                  }),
                ),
              ),
            ),
          ),
        );
        final track = find.byKey(const ValueKey('toggle-track'));
        final thumb = find.byKey(const ValueKey('toggle-thumb'));
        expect(tester.getSize(track), const Size(46, 28));
        expect(tester.getSize(thumb), const Size(22, 22));
        expect(
          tester.getSize(find.byType(YYToggle)).height,
          greaterThanOrEqualTo(44),
        );
        final before = tester.getCenter(thumb).dx;
        await tester.tap(find.byType(YYToggle));
        await tester.pumpAndSettle();
        expect(changes, 1);
        expect(tester.getCenter(thumb).dx - before, 18);
        final node = tester.getSemantics(find.bySemanticsLabel('减少透明'));
        expect(node.flagsCollection.isToggled, ui.Tristate.isTrue);
        expect(node.flagsCollection.isButton, isFalse);
        tester.binding.performSemanticsAction(
          ui.SemanticsActionEvent(
            type: ui.SemanticsAction.tap,
            nodeId: node.id,
            viewId: tester.view.viewId,
          ),
        );
        await tester.pumpAndSettle();
        expect(value, false);
        expect(changes, 2);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'toggle keyboard, RTL, disabled and loading keep control with caller',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var changes = 0;
      final appearance = YYAppearanceController()
        ..setReduceMotion(true)
        ..setCustomAccent('#FFFFFF');
      addTearDown(appearance.dispose);
      Widget subject({bool enabled = true, bool loading = false}) =>
          designHarness(
            Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: YYToggle(
                  label: '开关',
                  value: true,
                  loading: loading,
                  focusNode: focus,
                  onChanged: enabled ? (_) => changes++ : null,
                ),
              ),
            ),
            appearance: appearance,
          );
      await tester.pumpWidget(subject());
      final track = tester.getRect(find.byKey(const ValueKey('toggle-track')));
      expect(
        tester.getCenter(find.byKey(const ValueKey('toggle-thumb'))).dx,
        track.left + 14,
      );
      final container = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('toggle-track')),
      );
      expect(container.duration, Duration.zero);
      expect((container.decoration! as BoxDecoration).boxShadow, isNotEmpty);
      focus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(changes, 2);
      await tester.pumpWidget(subject(enabled: false));
      await tester.tap(find.byType(YYToggle));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpWidget(subject(loading: true));
      await tester.tap(find.byType(YYToggle));
      expect(changes, 2);
    },
  );

  testWidgets(
    'segments scroll, select once and expose complete mutually-exclusive labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var selected = 0;
        var changes = 0;
        await tester.pumpWidget(
          designHarness(
            Center(
              child: SizedBox(
                width: 240,
                child: StatefulBuilder(
                  builder: (context, setState) => YYSegmentedControl<int>(
                    label: '筛选',
                    value: selected,
                    segments: const [
                      YYSegment(value: 0, label: '全部音乐'),
                      YYSegment(value: 1, label: '专辑'),
                      YYSegment(value: 2, label: '这是一个很长的中文筛选标签'),
                      YYSegment(value: 3, label: '不可用', enabled: false),
                    ],
                    onChanged: (value) => setState(() {
                      selected = value;
                      changes++;
                    }),
                  ),
                ),
              ),
            ),
            scale: 1.3,
          ),
        );
        await tester.tap(find.text('全部音乐'));
        expect(changes, 0);
        await tester.ensureVisible(find.text('这是一个很长的中文筛选标签'));
        await tester.tap(find.text('这是一个很长的中文筛选标签'));
        await tester.pumpAndSettle();
        expect(selected, 2);
        expect(changes, 1);
        final node = tester.getSemantics(
          find.bySemanticsLabel('这是一个很长的中文筛选标签'),
        );
        expect(node.flagsCollection.isSelected, ui.Tristate.isTrue);
        expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
        await tester.ensureVisible(find.text('不可用'));
        await tester.tap(find.text('不可用'));
        expect(changes, 1);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('segment keyboard actions work and loading blocks changes', (
    tester,
  ) async {
    var changes = 0;
    Widget subject(bool loading) => designHarness(
      Center(
        child: SizedBox(
          width: 130,
          child: YYSegmentedControl<int>(
            label: '选择',
            value: 0,
            loading: loading,
            segments: const [
              YYSegment(value: 0, label: '第一项'),
              YYSegment(value: 1, label: '第二项'),
            ],
            onChanged: (_) => changes++,
          ),
        ),
      ),
    );
    await tester.pumpWidget(subject(false));
    Focus.of(tester.element(find.text('第二项'))).requestFocus();
    await tester.pump();
    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    expect(viewport.contains(tester.getCenter(find.text('第二项'))), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(changes, 1);
    await tester.pumpWidget(subject(true));
    await tester.tap(find.text('第二项'));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(changes, 1);
  });

  testWidgets(
    'search preserves IME composition and only submits on the search action',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final submissions = <String>[];
      final changes = <String>[];
      await tester.pumpWidget(
        designHarness(
          Center(
            child: YYSearchField(
              controller: controller,
              label: '搜索',
              onChanged: changes.add,
              onSubmitted: submissions.add,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '音yue',
          selection: TextSelection.collapsed(offset: 4),
          composing: TextRange(start: 1, end: 4),
        ),
      );
      await tester.pump();
      expect(controller.value.composing, const TextRange(start: 1, end: 4));
      expect(submissions, isEmpty);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '音乐',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(submissions, ['音乐']);
      await tester.tap(find.byKey(const ValueKey('clear-search')));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(changes, ['音yue', '音乐', '']);
      expect(submissions, ['音乐']);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    },
  );

  testWidgets(
    'search disabled/loading cannot edit or submit and keeps error semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: '本地文本');
      addTearDown(controller.dispose);
      try {
        var calls = 0;
        for (final loading in [false, true]) {
          await tester.pumpWidget(
            designHarness(
              Center(
                child: YYSearchField(
                  controller: controller,
                  label: '搜索状态',
                  enabled: loading,
                  loading: loading,
                  errorText: '示例错误',
                  onSubmitted: (_) => calls++,
                ),
              ),
            ),
          );
          final field = tester.widget<EditableText>(find.byType(EditableText));
          expect(field.readOnly, isTrue);
          expect(field.enableInteractiveSelection, isFalse);
          await tester.tap(find.byType(EditableText), warnIfMissed: false);
          await tester.pump();
          expect(field.focusNode.hasFocus, isFalse);
          field.onSubmitted!('不能提交');
          expect(calls, 0);
          expect(
            tester
                .getSemantics(find.bySemanticsLabel('示例错误'))
                .flagsCollection
                .isLiveRegion,
            isTrue,
          );
        }
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'search supports long-press selection and explicit clipboard actions',
    (tester) async {
      final controller = TextEditingController(text: 'YY music');
      addTearDown(controller.dispose);
      String clipboard = '粘贴示例';
      var reads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.hasStrings') {
            return {'value': clipboard.isNotEmpty};
          }
          if (call.method == 'Clipboard.getData') {
            reads++;
            return {'text': clipboard};
          }
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        designHarness(
          Center(
            child: SizedBox(
              width: 320,
              child: YYSearchField(controller: controller, label: '剪贴板示例'),
            ),
          ),
        ),
      );
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final word = editable.getLocalRectForCaret(const TextPosition(offset: 4));
      await tester.longPressAt(editable.localToGlobal(word.center));
      await tester.pumpAndSettle();
      expect(controller.selection.isCollapsed, isFalse);
      expect(find.text('复制'), findsOneWidget);
      expect(reads, 0);
      await tester.tap(find.text('复制'));
      await tester.pumpAndSettle();
      expect(clipboard, isNotEmpty);
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
      final state = tester.state<EditableTextState>(find.byType(EditableText));
      state.showToolbar();
      await tester.pumpAndSettle();
      await tester.tap(find.text('粘贴'));
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'search reflows at 130 percent, 360/600 widths and keyboard insets',
    (tester) async {
      final controller = TextEditingController(
        text: '很长的中文搜索内容 Mixed Latin 123',
      );
      addTearDown(controller.dispose);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      for (final width in [360.0, 600.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpWidget(
          designHarness(
            ScrollNotificationObserver(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: YYSearchField(
                    controller: controller,
                    label: '搜索',
                    errorText: '长错误消息也应该完整换行展示，而不是截断或者覆盖输入内容。',
                  ),
                ),
              ),
            ),
            scale: 1.3,
          ),
        );
        // Padding is part of the input hit area, not just the short text line.
        final hitArea = tester.getRect(
          find.byKey(const ValueKey('search-surface')),
        );
        await tester.tapAt(Offset(hitArea.left + 20, hitArea.top + 6));
        await tester.pumpAndSettle();
        final surface = tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey('search-surface')),
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('search-surface'))).height,
          closeTo(width < 600 ? 52.275 : 58, .01),
        );
        expect(
          (surface.decoration! as BoxDecoration).borderRadius,
          BorderRadius.circular(width < 600 ? 18 : 20),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .focusNode
              .hasFocus,
          isTrue,
        );
      }
    },
  );

  testWidgets('search does not dispose caller controllers or stale listeners', (
    tester,
  ) async {
    final first = TextEditingController(), second = TextEditingController();
    final firstFocus = FocusNode(), secondFocus = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);
    Widget subject(TextEditingController controller, FocusNode focus) =>
        designHarness(
          Center(
            child: YYSearchField(
              controller: controller,
              label: '外部状态',
              focusNode: focus,
            ),
          ),
        );
    await tester.pumpWidget(subject(first, firstFocus));
    await tester.pumpWidget(subject(second, secondFocus));
    first.text = '旧值';
    second.text = '新值';
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller,
      same(second),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    first.text = '仍可使用';
    second.text = '仍可使用';
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'toggle hover and cancelled press show feedback without changing value',
    (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );
      var changes = 0;
      await tester.pumpWidget(
        designHarness(
          Center(
            child: YYToggle(
              label: '反馈',
              value: false,
              onChanged: (_) => changes++,
            ),
          ),
        ),
      );
      final pointer = await tester.createGesture(
        kind: ui.PointerDeviceKind.mouse,
      );
      await pointer.addPointer(location: const Offset(1, 1));
      await pointer.moveTo(tester.getCenter(find.byType(YYToggle)));
      await tester.pumpAndSettle();
      final track = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey('toggle-track')),
      );
      expect(track.duration, const Duration(milliseconds: 160));
      expect((track.decoration! as BoxDecoration).boxShadow, isNotEmpty);
      await pointer.down(tester.getCenter(find.byType(YYToggle)));
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        .98,
      );
      await pointer.cancel();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(changes, 0);
      await pointer.removePointer();
    },
  );

  testWidgets(
    'Gallery search stays a user text example with working loading switch',
    (tester) async {
      await tester.pumpWidget(
        designHarness(
          const Center(
            child: SizedBox(width: 350, child: GalleryInputControls()),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '我的输入');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('已提交示例：我的输入'), findsOneWidget);
      await tester.tap(find.text('专辑'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<YYSegmentedControl<String>>(
              find.byType(YYSegmentedControl<String>),
            )
            .value,
        'albums',
      );
      await tester.tap(find.byKey(const ValueKey('gallery-loading-toggle')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
