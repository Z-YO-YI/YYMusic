import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
}
