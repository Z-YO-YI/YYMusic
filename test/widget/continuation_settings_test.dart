import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/app_routes.dart';
import 'package:yymusic/app/dependency_graph.dart';
import 'package:yymusic/app/layout_class.dart';
import 'package:yymusic/design_system/yy_feedback.dart';
import 'package:yymusic/design_system/yy_toggle.dart';
import 'package:yymusic/features/settings/common/settings_screen.dart';

import '../support/design_harness.dart';
import '../support/fake_playback_continuation_repository.dart';
import '../support/settings_harness.dart';

const toggleKey = ValueKey('continuation-toggle');
Future<void> openPlaybackSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('settings-section-playback')));
  await pumpSettings(tester);
}

void main() {
  setUpAll(loadDesignAssets);
  for (final (platform, size) in const [
    (YYPlatform.android, Size(360, 800)),
    (YYPlatform.android, Size(1280, 800)),
    (YYPlatform.windows, Size(1024, 720)),
  ]) {
    testWidgets('real settings persists toggle on $platform $size', (
      tester,
    ) async {
      final repo = FakePlaybackContinuationRepository()..stored = false;
      final graph = DependencyGraph(continuationRepository: repo);
      await mountSettings(tester, graph, platform: platform, size: size);
      await openPlaybackSettings(tester);
      expect(tester.widget<YYToggle>(find.byKey(toggleKey)).value, isFalse);
      expect(find.byType(YYToggle), findsOneWidget);
      await tester.tap(find.byKey(toggleKey));
      await pumpSettings(tester);
      expect(graph.playback.continueAfterTrack, isTrue);
      expect(repo.stored, isTrue);
      expect(graph.viewState.selection(AppRoute.settings), 'playback');
      expect(tester.takeException(), isNull);
      await unmountSettings(tester, graph);
    });
  }

  testWidgets('write failure retry is safe and stale callback cannot edit', (
    tester,
  ) async {
    final repo = FakePlaybackContinuationRepository()
      ..writeError = StateError('private-marker');
    final graph = DependencyGraph(continuationRepository: repo);
    await mountSettings(tester, graph);
    await openPlaybackSettings(tester);
    final stale = tester.widget<YYToggle>(find.byKey(toggleKey)).onChanged!;
    await tester.tap(find.byKey(toggleKey));
    await pumpSettings(tester);
    expect(find.text('播放偏好尚未保存'), findsOneWidget);
    expect(find.textContaining('private-marker'), findsNothing);
    stale(true);
    expect(graph.playback.continueAfterTrack, isFalse);
    repo.writeError = null;
    await tester.ensureVisible(find.text('重试'));
    await tester.tap(find.text('重试'));
    await pumpSettings(tester);
    expect(repo.stored, isFalse);
    expect(find.byType(YYErrorBanner), findsNothing);
    await unmountSettings(tester, graph);
  });

  testWidgets('read failure preserves data and explicit toggle recovers', (
    tester,
  ) async {
    final repo = FakePlaybackContinuationRepository()
      ..readError = StateError('private-marker');
    final graph = DependencyGraph(continuationRepository: repo);
    await mountSettings(tester, graph);
    await openPlaybackSettings(tester);
    expect(find.text('无法读取播放偏好'), findsOneWidget);
    expect(repo.writes, isEmpty);
    await tester.tap(find.byKey(toggleKey));
    await pumpSettings(tester);
    expect(repo.stored, isFalse);
    expect(find.text('无法读取播放偏好'), findsNothing);
    await unmountSettings(tester, graph);
  });

  testWidgets('hidden route and changed section revoke callbacks', (
    tester,
  ) async {
    final repo = FakePlaybackContinuationRepository();
    final graph = DependencyGraph(continuationRepository: repo);
    await mountSettings(tester, graph);
    await openPlaybackSettings(tester);
    final stale = tester.widget<YYToggle>(find.byKey(toggleKey)).onChanged!;
    await tester.tap(find.byKey(const ValueKey('settings-section-appearance')));
    await pumpSettings(tester);
    stale(false);
    expect(repo.writes, isEmpty);
    await openPlaybackSettings(tester);
    final hidden = tester.widget<YYToggle>(find.byKey(toggleKey)).onChanged!;
    tester
        .widget<SettingsScreen>(find.byType(SettingsScreen))
        .navigation
        .goTo(AppRoute.home);
    await pumpSettings(tester);
    hidden(false);
    expect(repo.writes, isEmpty);
    await unmountSettings(tester, graph);
  });

  testWidgets(
    'saved playback section survives width changes and keyboard activation',
    (tester) async {
      final repo = FakePlaybackContinuationRepository();
      final graph = DependencyGraph(continuationRepository: repo);
      graph.viewState.select(AppRoute.settings, 'playback');
      await mountSettings(tester, graph);
      expect(find.byKey(toggleKey), findsOneWidget);
      tester.view.physicalSize = const Size(1280, 800);
      await pumpSettings(tester);
      expect(find.byKey(toggleKey), findsOneWidget);
      await tester.tap(find.byKey(toggleKey));
      await pumpSettings(tester);
      final target = find.descendant(
        of: find.byKey(toggleKey),
        matching: find.byType(GestureDetector),
      );
      Focus.of(tester.element(target.first)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpSettings(tester);
      expect(repo.writes, [false, true]);
      expect(tester.takeException(), isNull);
      await unmountSettings(tester, graph);
    },
  );

  testWidgets('busy save allows final choice and close waits', (tester) async {
    final repo = FakePlaybackContinuationRepository();
    final graph = DependencyGraph(continuationRepository: repo);
    await mountSettings(tester, graph);
    await openPlaybackSettings(tester);
    final gate = Completer<void>();
    repo.writeGate = gate.future;
    try {
      await tester.tap(find.byKey(toggleKey));
      await pumpSettings(tester);
      expect(find.text('正在保存播放偏好…'), findsOneWidget);
      await tester.tap(find.byKey(toggleKey));
      await pumpSettings(tester);
    } finally {
      gate.complete();
    }
    await unmountSettings(tester, graph);
    expect(repo.stored, isTrue);
  });
}
