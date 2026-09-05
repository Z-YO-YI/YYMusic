import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/app/yy_music_app.dart';
import 'package:yymusic/design_system/yy_theme.dart';
import 'package:yymusic/domain/models/software_license.dart';
import 'package:yymusic/domain/repositories/license_repository.dart';
import 'package:yymusic/features/settings/common/licenses_screen.dart';

import '../support/design_harness.dart';

final class _Repository implements LicenseRepository {
  _Repository(this.result);
  Future<List<SoftwareLicense>> Function() result;
  int calls = 0;
  @override
  Future<List<SoftwareLicense>> load() {
    calls++;
    return result();
  }
}

final _licenses = [
  SoftwareLicense(
    packages: ['package_alpha', 'package_shared'],
    text:
        'First paragraph.\n\n${'Complete license sentence. ' * 300}\nTHE LAST PARAGRAPH.',
  ),
  SoftwareLicense(
    packages: ['Android · org.checkerframework:checker-qual:3.41.0'],
    text: 'Full synthetic MIT text for UI tests.',
  ),
];

Future<void> _mount(
  WidgetTester tester,
  _Repository repository, {
  Size size = const Size(390, 844),
  YYPlatform platform = YYPlatform.android,
  String route = '/settings/licenses',
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final graph = DependencyGraph(licenses: repository);
  graph.appearance.setMode(dark ? YYThemeMode.dark : YYThemeMode.light);
  graph.appearance.setReduceMotion(true);
  addTearDown(graph.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dependencyGraphProvider.overrideWithValue(graph)],
      child: YYMusicApp(platform: platform, initialLocation: route),
    ),
  );
}

void main() {
  setUpAll(loadDesignAssets);

  testWidgets(
    'settings navigation opens searchable licenses and returns to settings',
    (tester) async {
      final repository = _Repository(() async => _licenses);
      await _mount(tester, repository, route: '/settings');
      await tester.pumpAndSettle();
      await tester.tap(find.text('开源许可'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensesScreen), findsOneWidget);
      expect(repository.calls, 1);
      await tester.enterText(find.byType(EditableText), 'SHARED');
      await tester.pumpAndSettle();
      expect(find.text('package_alpha 等 2 个组件'), findsOneWidget);
      expect(
        find.text('Android · org.checkerframework:checker-qual:3.41.0'),
        findsNothing,
      );
      await tester.enterText(find.byType(EditableText), 'not-present');
      await tester.pumpAndSettle();
      expect(find.text('没有匹配的组件'), findsOneWidget);
      expect(repository.calls, 1);
      await tester.tap(find.text('返回设置'));
      await tester.pumpAndSettle();
      expect(find.byType(LicensesScreen), findsNothing);
      expect(find.byKey(const ValueKey('screen-settings')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (platform, size, dark) in [
    (YYPlatform.android, const Size(390, 844), false),
    (YYPlatform.android, const Size(844, 390), true),
    (YYPlatform.android, const Size(1024, 768), false),
    (YYPlatform.windows, const Size(1440, 900), true),
  ]) {
    testWidgets(
      'complete native license dialog at $platform $size dark=$dark and 130 percent text',
      (tester) async {
        await _mount(
          tester,
          _Repository(() async => _licenses),
          platform: platform,
          size: size,
          dark: dark,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('package_alpha 等 2 个组件'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('complete-license-text')))
              .data,
          _licenses.first.text,
        );
        expect(find.text('许可原文'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('许可原文'), findsNothing);
        expect(find.byType(LicensesScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'loading, fixed safe failure, retry and late completion survive unmount',
    (tester) async {
      final pending = Completer<List<SoftwareLicense>>();
      final repository = _Repository(() => pending.future);
      await _mount(tester, repository);
      await tester.pump();
      expect(find.text('正在读取许可信息…'), findsOneWidget);
      pending.completeError(StateError('private-path-marker'));
      await tester.pumpAndSettle();
      expect(find.text('无法读取许可信息，请重试。'), findsOneWidget);
      expect(find.textContaining('private-path-marker'), findsNothing);
      repository.result = () async => _licenses;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(repository.calls, 2);
      expect(find.text('package_alpha 等 2 个组件'), findsOneWidget);
      final late = Completer<List<SoftwareLicense>>();
      await tester.pumpWidget(const SizedBox.shrink());
      await _mount(tester, _Repository(() => late.future));
      await tester.pumpWidget(const SizedBox.shrink());
      late.complete(_licenses);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
