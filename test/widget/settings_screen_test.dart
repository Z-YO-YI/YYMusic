import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yymusic/app/app_router.dart';
import 'package:yymusic/app/app_view_state.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_segmented_control.dart';
import 'package:yymusic/design_system/yy_text_field.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_theme_swatch.dart';
import 'package:yymusic/design_system/yy_toggle.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/domain/models/appearance_settings.dart';
import 'package:yymusic/features/settings/common/settings_screen.dart';
import 'package:yymusic/features/settings/phone/phone_settings_layout.dart';
import 'package:yymusic/features/settings/tablet/tablet_settings_layout.dart';
import 'package:yymusic/features/settings/windows/windows_settings_layout.dart';

import '../support/close_graph.dart';
import '../support/design_harness.dart';
import '../support/fake_appearance_settings_repository.dart';
import '../support/playback_graph_fixture.dart';
import '../support/settings_harness.dart';

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is YYButton && widget.label == label,
);
Finder toggle(String label) => find.byWidgetPredicate(
  (widget) => widget is YYToggle && widget.label == label,
);
Finder swatch(YYAccentPreset preset) => find.byWidgetPredicate(
  (widget) => widget is YYThemeSwatch && widget.label == preset.label,
);

void main() {
  setUpAll(loadDesignAssets);

  testWidgets(
    'actual settings controls save one root theme including glass inversion',
    (tester) async {
      final repo = FakeAppearanceSettingsRepository();
      final graph = DependencyGraph(appearanceRepository: repo);
      final semantics = tester.ensureSemantics();
      await mountSettings(tester, graph);
      expect(repo.reads, 1);
      expect(repo.saves, isEmpty);
      expect(find.text('外观设置已保存到本机'), findsOneWidget);
      await tester.tap(find.text('深色'));
      await pumpSettings(tester);
      expect(graph.appearance.mode, YYThemeMode.dark);
      expect(repo.stored.mode, AppearanceMode.dark);
      for (final preset in YYAccentPreset.values) {
        await tester.ensureVisible(swatch(preset));
        await tester.tap(swatch(preset));
        await pumpSettings(tester);
        expect(repo.stored.accent.name, preset.name);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(RegExp('^${preset.label}\$')))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
      }
      for (final label in ['Liquid Glass 导航', '减少动态效果']) {
        await tester.ensureVisible(toggle(label));
        await tester.tap(toggle(label));
        await pumpSettings(tester);
      }
      expect(graph.appearance.reduceGlass, isTrue);
      expect(repo.stored.glassEnabled, isFalse);
      expect(repo.stored.reduceMotion, isTrue);
      semantics.dispose();
      expect(tester.takeException(), isNull);
      await unmountSettings(tester, graph);
      await repo.dispose();
    },
  );

  testWidgets(
    'invalid draft never saves and valid Hex retains original input',
    (tester) async {
      final repo = FakeAppearanceSettingsRepository();
      final graph = DependencyGraph(appearanceRepository: repo);
      await mountSettings(tester, graph);
      await tester.ensureVisible(find.byType(YYTextField));
      await tester.enterText(find.byType(EditableText), 'not-a-color');
      await tester.ensureVisible(button('应用颜色'));
      await tester.tap(button('应用颜色'));
      await pumpSettings(tester);
      expect(find.text('请输入 6 位十六进制颜色，例如 #FF3B5C'), findsOneWidget);
      expect(repo.saves, isEmpty);
      expect(graph.appearance.accent.preset, YYAccentPreset.coral);
      await tester.enterText(find.byType(EditableText), 'fFeE12');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpSettings(tester);
      expect(repo.stored.customAccent, 'fFeE12');
      expect(repo.stored.accent, AppearanceAccent.custom);
      expect(find.text('颜色草稿尚未应用'), findsNothing);
      expect(
        YYAccent.contrast(
          graph.appearance.accent.color,
          graph.appearance.accent.onAccent,
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(tester.takeException(), isNull);
      await unmountSettings(tester, graph);
      await repo.dispose();
    },
  );

  testWidgets(
    'loading and load error disable writes, retry restores stored appearance',
    (tester) async {
      final gate = Completer<AppearanceSettings>();
      final repo = FakeAppearanceSettingsRepository()
        ..onRead = () => gate.future;
      final graph = DependencyGraph(appearanceRepository: repo);
      final initializing = graph.initialize();
      await mountSettings(tester, graph, initialize: false);
      expect(find.text('正在读取外观设置…'), findsOneWidget);
      expect(
        tester
            .widget<YYSegmentedControl<YYThemeMode>>(
              find.byType(YYSegmentedControl<YYThemeMode>),
            )
            .onChanged,
        isNull,
      );
      gate.completeError(StateError('private-marker'));
      await pumpSettings(tester);
      await initializing;
      expect(find.text('无法读取外观设置'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect(repo.saves, isEmpty);
      repo.onRead = () async => AppearanceSettings(
        mode: AppearanceMode.dark,
        customAccent: '#AbCD12',
        accent: AppearanceAccent.custom,
      );
      await tester.tap(button('重试'));
      await pumpSettings(tester);
      expect(graph.appearance.mode, YYThemeMode.dark);
      expect(
        tester.widget<YYTextField>(find.byType(YYTextField)).controller.text,
        '#AbCD12',
      );
      expect(repo.saves, isEmpty);
      expect(find.text('外观设置已保存到本机'), findsOneWidget);
      await unmountSettings(tester, graph);
      await repo.dispose();
    },
  );

  testWidgets(
    'pending save and failure are honest, retry saves latest snapshot',
    (tester) async {
      final gate = Completer<void>();
      final repo = FakeAppearanceSettingsRepository()
        ..onSave = (_) => gate.future;
      final graph = DependencyGraph(appearanceRepository: repo);
      await mountSettings(tester, graph);
      await tester.tap(find.text('深色'));
      await pumpSettings(tester);
      expect(find.text('正在保存外观设置…'), findsOneWidget);
      gate.completeError(StateError('private-marker'));
      await pumpSettings(tester);
      expect(find.text('外观设置尚未保存'), findsOneWidget);
      expect(find.textContaining('private-marker'), findsNothing);
      expect(graph.appearance.mode, YYThemeMode.dark);
      expect(repo.stored.mode, AppearanceMode.light);
      repo.onSave = null;
      await tester.tap(button('重试'));
      await pumpSettings(tester);
      expect(repo.stored.mode, AppearanceMode.dark);
      expect(find.text('外观设置已保存到本机'), findsOneWidget);
      await unmountSettings(tester, graph);
      await repo.dispose();
    },
  );

  testWidgets(
    'draft, selection and focus survive phone/tablet layouts and save notifications',
    (tester) async {
      final repo = FakeAppearanceSettingsRepository();
      final graph = DependencyGraph(appearanceRepository: repo);
      await mountSettings(tester, graph);
      await tester.ensureVisible(find.byType(YYTextField));
      await tester.enterText(find.byType(EditableText), '#Ab12');
      final original = tester.widget<YYTextField>(find.byType(YYTextField));
      original.controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 4,
      );
      for (final size in [
        const Size(800, 1280),
        const Size(1280, 800),
        const Size(390, 844),
      ]) {
        tester.view.physicalSize = size;
        await pumpSettings(tester);
        final field = tester.widget<YYTextField>(find.byType(YYTextField));
        expect(identical(field.controller, original.controller), isTrue);
        expect(field.controller.text, '#Ab12');
        expect(
          field.controller.selection,
          const TextSelection(baseOffset: 1, extentOffset: 4),
        );
        expect(field.focusNode.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      }
      graph.appearance.setMode(YYThemeMode.dark);
      await pumpSettings(tester);
      expect(original.controller.text, '#Ab12');
      expect(repo.stored.accent, AppearanceAccent.coral);
      expect(find.text('颜色草稿尚未应用'), findsOneWidget);
      await unmountSettings(tester, graph);
      await repo.dispose();
    },
  );

  testWidgets(
    'stale callbacks cannot edit after category change, route cover or unmount',
    (tester) async {
      final repo = FakeAppearanceSettingsRepository();
      final graph = DependencyGraph(appearanceRepository: repo);
      await mountSettings(tester, graph);
      VoidCallback captured() =>
          tester.widget<YYThemeSwatch>(swatch(YYAccentPreset.jade)).onPressed!;
      final oldSection = captured();
      await tester.tap(find.byKey(const ValueKey('settings-section-about')));
      await pumpSettings(tester);
      oldSection();
      expect(repo.saves, isEmpty);
      await tester.tap(
        find.byKey(const ValueKey('settings-section-appearance')),
      );
      await pumpSettings(tester);
      oldSection();
      final oldCover = captured();
      final router = GoRouter.of(tester.element(find.byType(SettingsScreen)));
      unawaited(router.push<void>('/settings/licenses'));
      await pumpSettings(tester);
      oldCover();
      router.pop();
      await pumpSettings(tester);
      oldCover();
      expect(repo.saves, isEmpty);
      final oldHidden = captured();
      router.go('/library');
      await pumpSettings(tester);
      oldHidden();
      router.go('/settings');
      await pumpSettings(tester);
      oldHidden();
      expect(repo.saves, isEmpty);
      final oldDisposed = captured();
      await unmountSettings(tester, graph);
      oldDisposed();
      expect(repo.saves, isEmpty);
      expect(tester.takeException(), isNull);
      await repo.dispose();
    },
  );

  testWidgets(
    'Windows keyboard activates settings only and leaves playback untouched',
    (tester) async {
      final fixture = PlaybackGraphFixture();
      await fixture.queue();
      await mountSettings(
        tester,
        fixture.graph,
        platform: YYPlatform.windows,
        size: const Size(1440, 900),
      );
      await tester.ensureVisible(find.byType(YYTextField));
      await tester.tap(find.byType(EditableText));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(fixture.engine.calls, isEmpty);
      await tester.ensureVisible(toggle('减少动态效果'));
      final target = find.descendant(
        of: toggle('减少动态效果'),
        matching: find.byType(GestureDetector),
      );
      Focus.of(tester.element(target.first)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpSettings(tester);
      expect(fixture.graph.appearance.reduceMotion, isTrue);
      expect(fixture.engine.calls, isEmpty);
      await unmountSettings(tester, fixture.graph);
    },
  );

  testWidgets(
    'system appearance follows brightness without saving OS changes',
    (tester) async {
      final repo = FakeAppearanceSettingsRepository();
      final graph = DependencyGraph(appearanceRepository: repo);
      await mountSettings(tester, graph);
      await tester.tap(find.text('系统'));
      await pumpSettings(tester);
      expect(repo.stored.mode, AppearanceMode.system);
      final saves = repo.saves.length;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpSettings(tester);
      expect(
        YYTheme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );
      expect(repo.saves.length, saves);
      expect(
        tester
            .widget<YYSegmentedControl<YYThemeMode>>(
              find.byType(YYSegmentedControl<YYThemeMode>),
            )
            .value,
        YYThemeMode.system,
      );
      await unmountSettings(tester, graph);
      await repo.dispose();
    },
  );

  testWidgets('scroll position is retained while phone changes to tablet', (
    tester,
  ) async {
    final graph = DependencyGraph();
    await mountSettings(tester, graph, size: const Size(390, 480));
    final phone = tester.widget<PhoneSettingsLayout>(
      find.byType(PhoneSettingsLayout),
    );
    final position = phone.scroll.position;
    final viewport = phone.viewportKey.currentContext;
    position.jumpTo(150);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(700, 480);
    await pumpSettings(tester);
    final tablet = tester.widget<TabletSettingsLayout>(
      find.byType(TabletSettingsLayout),
    );
    expect(identical(tablet.scroll, phone.scroll), isTrue);
    expect(identical(tablet.viewportKey.currentContext, viewport), isTrue);
    expect(
      tablet.scroll.position.pixels,
      150.0.clamp(0, tablet.scroll.position.maxScrollExtent),
    );
    expect(tester.takeException(), isNull);
    await unmountSettings(tester, graph);
  });

  testWidgets('zero area revokes old controls even after the editor returns', (
    tester,
  ) async {
    final graph = DependencyGraph();
    final router = AppRouter(
      platform: YYPlatform.android,
      viewState: AppViewState(),
    );
    final area = ValueNotifier(const Size(390, 800));
    await tester.pumpWidget(
      designHarness(
        ValueListenableBuilder(
          valueListenable: area,
          builder: (context, size, _) => Align(
            child: SizedBox.fromSize(
              size: size,
              child: SettingsScreen(
                platform: YYPlatform.android,
                controller: graph.appearanceSettings,
                navigation: router,
                viewState: graph.viewState,
              ),
            ),
          ),
        ),
        appearance: graph.appearance,
      ),
    );
    await pumpSettings(tester);
    final old = tester
        .widget<YYThemeSwatch>(swatch(YYAccentPreset.jade))
        .onPressed!;
    area.value = Size.zero;
    await pumpSettings(tester);
    old();
    expect(graph.appearance.accent.preset, YYAccentPreset.coral);
    area.value = const Size(390, 800);
    await pumpSettings(tester);
    old();
    expect(graph.appearance.accent.preset, YYAccentPreset.coral);
    tester.widget<YYThemeSwatch>(swatch(YYAccentPreset.jade)).onPressed!();
    expect(graph.appearance.accent.preset, YYAccentPreset.jade);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await closeGraph(tester, graph);
    router.dispose();
    area.dispose();
  });

  testWidgets('leaving settings does not cancel an accepted pending save', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repo = FakeAppearanceSettingsRepository()
      ..onSave = (_) => gate.future;
    final graph = DependencyGraph(appearanceRepository: repo);
    await mountSettings(tester, graph);
    await tester.tap(find.text('深色'));
    await pumpSettings(tester);
    final router = GoRouter.of(tester.element(find.byType(SettingsScreen)));
    router.go('/library');
    await pumpSettings(tester);
    gate.complete();
    await pumpSettings(tester);
    expect(repo.stored.mode, AppearanceMode.dark);
    expect(graph.appearanceSettings.unsaved, isFalse);
    router.go('/settings');
    await pumpSettings(tester);
    expect(find.text('外观设置已保存到本机'), findsOneWidget);
    await unmountSettings(tester, graph);
    await repo.dispose();
  });

  for (final (platform, size) in const [
    (YYPlatform.android, Size(360, 800)),
    (YYPlatform.android, Size(844, 390)),
    (YYPlatform.android, Size(800, 1280)),
    (YYPlatform.android, Size(1280, 800)),
    (YYPlatform.android, Size(700, 900)),
    (YYPlatform.windows, Size(840, 640)),
    (YYPlatform.windows, Size(1024, 720)),
    (YYPlatform.windows, Size(1440, 900)),
  ]) {
    testWidgets('native settings layout $platform $size at 130 percent', (
      tester,
    ) async {
      final graph = DependencyGraph();
      await mountSettings(tester, graph, size: size, platform: platform);
      expect(
        find.byType(
          platform == YYPlatform.windows
              ? WindowsSettingsLayout
              : size.width < 600
              ? PhoneSettingsLayout
              : TabletSettingsLayout,
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(button('应用颜色'));
      expect(tester.getSize(button('应用颜色')).height, greaterThanOrEqualTo(44));
      await tester.ensureVisible(toggle('减少动态效果'));
      expect(tester.getSize(toggle('减少动态效果')).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
      await unmountSettings(tester, graph);
    });
  }
}
