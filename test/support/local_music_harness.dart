import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/features/local_music/common/local_music_controller.dart';
import 'package:yymusic/features/local_music/common/local_music_panel.dart';

import 'design_harness.dart';

Future<void> mountLocalPanel(
  WidgetTester tester,
  LocalMusicController controller, {
  YYPlatform platform = YYPlatform.android,
  Size size = const Size(390, 1000),
  YYAppearanceController? appearance,
  ValueNotifier<bool>? enabled,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  Widget panel(bool value) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LocalMusicPanel(
        controller: controller,
        platform: platform,
        enabled: value,
      ),
    ),
  );
  await tester.pumpWidget(
    designHarness(
      Builder(
        builder: (context) => RepaintBoundary(
          key: const ValueKey('local-music-golden'),
          child: ColoredBox(
            color: YYTheme.of(context).colors.base,
            child: enabled == null
                ? panel(true)
                : ValueListenableBuilder<bool>(
                    valueListenable: enabled,
                    builder: (_, value, _) => panel(value),
                  ),
          ),
        ),
      ),
      appearance: appearance,
      scale: 1.3,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> unmountLocalPanel(
  WidgetTester tester,
  LocalMusicController controller,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  var closed = false;
  final closing = controller.close().then((_) => closed = true);
  for (var i = 0; i < 12 && !closed; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    // Disposal schedules event tasks in the test binding's fake timer zone.
    await tester.pump(Duration.zero);
  }
  expect(closed, isTrue, reason: 'Local overview shutdown must finish');
  await closing;
}
