import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/platform/contracts/window_gateway.dart';
import 'package:yymusic/platform/windows/windows_window_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(WindowsWindowGateway.channelName);
  final calls = <MethodCall>[];
  var snapshot = <String, Object>{
    'maximized': false,
    'minimized': false,
    'customFrame': true,
  };
  setUp(() {
    calls.clear();
    snapshot = {'maximized': false, 'minimized': false, 'customFrame': true};
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return snapshot;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));
  Future<void> event(String name, Object? arguments) async {
    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall(name, arguments)),
      null,
    );
  }

  test('window commands carry no HWND, paths or arbitrary arguments', () async {
    final gateway = WindowsWindowGateway();
    expect((await gateway.initialize())?.customFrame, isTrue);
    await gateway.initialize();
    await gateway.minimize();
    await gateway.toggleMaximize();
    await gateway.restore();
    await gateway.startDrag();
    await gateway.refresh();
    await gateway.requestClose();
    await gateway.completeClose();
    expect(calls.map((c) => c.method), [
      'configure',
      'minimize',
      'toggleMaximize',
      'restore',
      'startDrag',
      'getState',
      'requestClose',
      'completeClose',
    ]);
    expect(calls.every((c) => c.arguments == null), isTrue);
    await gateway.dispose();
    await gateway.dispose();
    expect(calls.where((c) => c.method == 'detach').length, 1);
  });
  test(
    'native state and close events are decoded and unsubscribe on dispose',
    () async {
      final gateway = WindowsWindowGateway();
      await gateway.initialize();
      final states = <WindowSnapshot>[];
      var requested = 0;
      final subscription = gateway.states.listen(states.add);
      final closing = gateway.closeRequests.listen((_) => requested++);
      await event('stateChanged', {
        'maximized': true,
        'minimized': false,
        'customFrame': true,
      });
      await event('closeRequested', null);
      expect(states.single.maximized, isTrue);
      expect(requested, 1);
      await subscription.cancel();
      await closing.cancel();
      await gateway.dispose();
      await event('closeRequested', null);
      expect(requested, 1);
      await expectLater(
        gateway.minimize(),
        throwsA(isA<WindowOperationException>()),
      );
    },
  );
  test(
    'missing runner returns unsupported and malformed native replies detach',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw MissingPluginException(),
      );
      final missing = WindowsWindowGateway();
      expect(await missing.initialize(), isNull);
      await missing.dispose();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return {'private-path': 'not-for-display'};
      });
      final broken = WindowsWindowGateway();
      await expectLater(
        broken.initialize(),
        throwsA(isA<WindowOperationException>()),
      );
      expect(calls.map((c) => c.method), ['configure', 'detach']);
      await broken.dispose();
    },
  );
  test(
    'late configure is followed by detach when root is already disposed',
    () async {
      final gate = Completer<Object?>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'configure') return await gate.future;
        return snapshot;
      });
      final gateway = WindowsWindowGateway();
      final initializing = gateway.initialize();
      final disposing = gateway.dispose();
      gate.complete(snapshot);
      expect(await initializing, isNull);
      await disposing;
      expect(calls.map((c) => c.method), ['configure', 'detach']);
    },
  );
}
