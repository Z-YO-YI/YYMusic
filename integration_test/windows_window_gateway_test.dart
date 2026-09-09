import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yymusic/platform/fullscreen/native_fullscreen_gateway.dart';
import 'package:yymusic/platform/windows/windows_window_gateway.dart';

/// Real HWND, no fake platform handler, audio, network, files or input injection.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Windows runner reports real frame state and intercepts system close',
    (tester) async {
      expect(Platform.isWindows && kDebugMode, isTrue);
      await tester.pumpWidget(const ColoredBox(color: Color(0xFFF5F5F2)));
      await tester.pumpAndSettle();
      final gateway = WindowsWindowGateway();
      const channel = MethodChannel(WindowsWindowGateway.channelName);
      final closeRequested = Completer<void>();
      final closing = gateway.closeRequests.listen((_) {
        if (!closeRequested.isCompleted) closeRequested.complete();
      });
      try {
        expect((await gateway.initialize())?.customFrame, isTrue);
        await expectLater(
          channel.invokeMethod<Object?>('getState', {'hwnd': 0}),
          throwsA(isA<PlatformException>()),
        );
        final maximized = gateway.states
            .firstWhere((s) => s.maximized)
            .timeout(const Duration(seconds: 5));
        expect((await gateway.toggleMaximize()).maximized, isTrue);
        expect((await maximized).customFrame, isTrue);
        expect((await gateway.toggleMaximize()).maximized, isFalse);
        final minimized = gateway.states
            .firstWhere((s) => s.minimized)
            .timeout(const Duration(seconds: 5));
        expect((await gateway.minimize()).minimized, isTrue);
        await minimized;
        // Do not request a Flutter frame while minimized: restore natively first.
        final restored = await gateway.restore();
        expect(restored.minimized || restored.maximized, isFalse);
        await gateway.requestClose();
        await closeRequested.future.timeout(const Duration(seconds: 5));
        expect((await gateway.refresh()).customFrame, isTrue);
        // No completeClose: the integration runner must remain alive to report.
      } finally {
        await closing.cancel();
        try {
          await gateway.restore();
        } finally {
          await gateway.dispose();
        }
      }
      final detached = await channel.invokeMapMethod<String, Object?>(
        'getState',
      );
      expect(detached?['customFrame'], isFalse);
      final metrics = <String, Object>{
        'customFrame': true,
        'maximized': true,
        'restored': true,
        'minimized': true,
        'stateEvents': true,
        'closeIntercepted': true,
        'detached': true,
        'arbitraryHwndRejected': true,
      };
      binding.reportData = metrics;
      debugPrint('YYMUSIC_WINDOWS_WINDOW ${jsonEncode(metrics)}');
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Windows fullscreen restores real styles geometry and maximized state',
    (tester) async {
      expect(Platform.isWindows && kDebugMode, isTrue);
      await tester.pumpWidget(const ColoredBox(color: Color(0xFFF5F5F2)));
      final window = WindowsWindowGateway();
      final fullscreen = NativeFullscreenGateway();
      const channel = MethodChannel(NativeFullscreenGateway.channelName);
      Future<Map<String, Object?>> state() async =>
          (await channel.invokeMapMethod<String, Object?>('getState'))!;
      try {
        await window.initialize();
        await window.restore();
        expect((await fullscreen.initialize())?.enabled, isFalse);
        await expectLater(
          channel.invokeMethod<Object?>('enter', {'hwnd': 0}),
          throwsA(isA<PlatformException>()),
        );
        for (final maximized in [false, true]) {
          if (maximized) await window.toggleMaximize();
          final before = await state();
          final entered = fullscreen.states
              .firstWhere((s) => s.enabled)
              .timeout(const Duration(seconds: 5));
          expect((await fullscreen.enter()).enabled, isTrue);
          await entered;
          final active = await state();
          expect((active['style']! as int) & 0x00CF0000, 0);
          for (final (side, monitor) in [
            ('left', 'monitorLeft'),
            ('top', 'monitorTop'),
            ('right', 'monitorRight'),
            ('bottom', 'monitorBottom'),
          ]) {
            expect(active[side], active[monitor]);
          }
          // A repeated enter must not replace the pre-fullscreen restoration data.
          await fullscreen.enter();
          expect((await fullscreen.restore()).enabled, isFalse);
          final after = await state();
          for (final key in [
            'style',
            'extendedStyle',
            'left',
            'top',
            'right',
            'bottom',
          ]) {
            expect(
              after[key],
              before[key],
              reason: 'Restored $key, maximized=$maximized',
            );
          }
          expect((await window.refresh()).maximized, maximized);
        }
        await window.restore();
        await fullscreen.enter();
        final minimized = fullscreen.states
            .firstWhere((s) => !s.enabled)
            .timeout(const Duration(seconds: 5));
        await window.minimize();
        await minimized;
        expect((await window.refresh()).minimized, isTrue);
        await window.restore();
        await fullscreen.enter();
        await fullscreen.close();
        expect((await state())['enabled'], isFalse);
        binding.reportData = {
          ...?binding.reportData,
          'fullscreenRestoration': true,
          'fullscreenMinimizeRecovery': true,
        };
        debugPrint(
          'YYMUSIC_WINDOWS_FULLSCREEN restoration=true minimize=true detach=true',
        );
      } finally {
        await fullscreen.close();
        await window.restore();
        await window.dispose();
      }
      await tester.pumpAndSettle();
    },
  );
}
