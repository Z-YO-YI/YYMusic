import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_button.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/design_system/yy_tokens.dart';
import 'package:yymusic/features/design_gallery/design_gallery_screen.dart';

import '../support/design_harness.dart';
import '../support/fake_audio_engine.dart';
import 'foundation_app_test.dart' show mount;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadDesignAssets);

  testWidgets(
    'Android gallery changes shared appearance and returns without replacing graph',
    (tester) async {
      final engine = FakeAudioEngine();
      final graph = DependencyGraph(audioEngine: engine);
      await mount(
        tester,
        platform: YYPlatform.android,
        size: const Size(390, 844),
        graph: graph,
      );
      final playback = graph.playback;
      final appearance = graph.appearance;
      await tester.tap(find.byKey(const ValueKey('open-design-gallery')));
      await tester.pumpAndSettle();
      expect(find.byType(DesignGalleryScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('theme-dark')));
      await tester.pumpAndSettle();
      expect(appearance.mode, YYThemeMode.dark);
      expect(
        YYTheme.of(tester.element(find.byType(DesignGalleryScreen))).brightness,
        Brightness.dark,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('custom-accent-input')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('custom-accent-input')),
        '#001122',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('apply-accent')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-accent')));
      await tester.pumpAndSettle();
      expect(appearance.accent.originalHex, '#001122');
      await tester.enterText(
        find.byKey(const ValueKey('custom-accent-input')),
        '#bad',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('apply-accent')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-accent')));
      await tester.pumpAndSettle();
      expect(find.textContaining('请输入 6 位'), findsOneWidget);
      expect(appearance.accent.originalHex, '#001122');
      await tester.ensureVisible(find.byKey(const ValueKey('reduce-glass')));
      await tester.tap(find.byKey(const ValueKey('reduce-glass')));
      await tester.pumpAndSettle();
      expect(appearance.reduceGlass, isTrue);
      await tester.ensureVisible(find.byKey(const ValueKey('demo-primary')));
      await tester.tap(find.byKey(const ValueKey('demo-primary')));
      await tester.pumpAndSettle();
      expect(find.textContaining('已点击 1 次'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('demo-favorite')));
      await tester.tap(find.byKey(const ValueKey('demo-favorite')));
      await tester.pumpAndSettle();
      expect(find.textContaining('示例已收藏'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
      expect(graph.appearance, same(appearance));
      expect(graph.playback, same(playback));
      expect(engine.disposalCount, 0);
      expect(
        graph.playback.isAvailable,
        isTrue,
      ); // Fake only; production stays unavailable.
      await tester.tap(find.byKey(const ValueKey('open-design-gallery')));
      await tester.pumpAndSettle();
      expect(
        YYTheme.of(tester.element(find.byType(DesignGalleryScreen)))
            .accent
            .originalHex,
        '#001122',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(engine.disposalCount, 1);
    },
  );

  testWidgets(
    'gallery reflows with real fonts at 130 percent on phone and tablet',
    (tester) async {
      await mount(
        tester,
        platform: YYPlatform.android,
        size: const Size(360, 800),
        route: '/design-system',
        scale: 1.3,
      );
      for (final size in [
        const Size(360, 800),
        const Size(390, 844),
        const Size(600, 900),
        const Size(1280, 800),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$size');
        for (final element in find.byType(YYButton).evaluate()) {
          final size = tester.getSize(find.byWidget(element.widget));
          expect(size.width, greaterThanOrEqualTo(44));
          expect(size.height, greaterThanOrEqualTo(44));
        }
        await tester.ensureVisible(find.text('fullscreen-exit'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.ensureVisible(find.byKey(const ValueKey('gallery-back')));
      await tester.tap(find.byKey(const ValueKey('gallery-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
    },
  );

  testWidgets(
    'System observes OS brightness and reduced animation without changing raw accent',
    (tester) async {
      final graph = DependencyGraph();
      graph.appearance.setMode(YYThemeMode.system);
      graph.appearance.setPreset(YYAccentPreset.jade);
      await mount(
        tester,
        platform: YYPlatform.android,
        size: const Size(390, 844),
        graph: graph,
        route: '/design-system',
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();
      final theme = YYTheme.of(
        tester.element(find.byType(DesignGalleryScreen)),
      );
      expect(theme.brightness, Brightness.dark);
      expect(theme.reduceMotion, isTrue);
      expect(theme.accent.color.toARGB32(), 0xFF00A67E);
      expect(graph.playback.isAvailable, isFalse);
    },
  );

  testWidgets('Windows retains its shell and does not expose Android gallery', (
    tester,
  ) async {
    await mount(
      tester,
      platform: YYPlatform.windows,
      size: const Size(1024, 720),
    );
    expect(find.byKey(const ValueKey('open-design-gallery')), findsNothing);
    expect(find.byType(DesignGalleryScreen), findsNothing);
  });
}
