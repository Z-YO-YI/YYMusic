import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/platform/contracts/fullscreen_gateway.dart';
import 'package:yymusic/platform/fullscreen/native_fullscreen_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(NativeFullscreenGateway.channelName);
  final calls = <MethodCall>[];
  var enabled = false;
  Future<Object?> respond(MethodCall call) async {
    calls.add(call);
    if (call.method == 'enter') enabled = true;
    if (call.method == 'restore' || call.method == 'detach') enabled = false;
    return {'enabled': enabled};
  }

  Future<void> event(Object? value, {String method = 'stateChanged'}) =>
      messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall(method, value)),
        (_) {},
      );
  setUp(() {
    calls.clear();
    enabled = false;
    messenger.setMockMethodCallHandler(channel, respond);
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('one handshake and no-argument commands use the independent fullscreen channel', () async {
    final gateway = NativeFullscreenGateway();
    final first = gateway.initialize();
    expect(gateway.initialize(), same(first));
    expect((await first)?.enabled, isFalse);
    expect((await gateway.enter()).enabled, isTrue);
    expect((await gateway.restore()).enabled, isFalse);
    await gateway.close();
    await gateway.close();
    expect(calls.map((e) => e.method), [
      'configure',
      'enter',
      'restore',
      'detach',
    ]);
    expect(calls.every((e) => e.arguments == null), isTrue);
  });

  test(
    'missing native host is unsupported and never pretends to enter',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw MissingPluginException(),
      );
      final gateway = NativeFullscreenGateway();
      expect(await gateway.initialize(), isNull);
      await expectLater(
        gateway.enter(),
        throwsA(isA<FullscreenOperationException>()),
      );
      await gateway.close();
    },
  );

  test('commands without initialization fail closed but a later handshake recovers', () async {
    final gateway = NativeFullscreenGateway();
    await expectLater(
      gateway.enter(),
      throwsA(isA<FullscreenOperationException>()),
    );
    expect(calls, isEmpty);
    await gateway.initialize();
    expect((await gateway.enter()).enabled, isTrue);
    await gateway.close();
    expect(enabled, isFalse);
  });

  for (final value in [
    null,
    <String, Object>{},
    {'enabled': 'true'},
    {'enabled': 1},
  ]) {
    test(
      'malformed handshake $value fails with fixed error and closes safely',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'configure' ? value : {'enabled': false};
        });
        final gateway = NativeFullscreenGateway();
        await expectLater(
          gateway.initialize(),
          throwsA(isA<FullscreenOperationException>()),
        );
        await gateway.close();
        expect(calls.map((e) => e.method), ['configure', 'detach']);
      },
    );
  }

  test('native exceptions never expose private error details', () async {
    final gateway = NativeFullscreenGateway();
    await gateway.initialize();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'enter') {
        throw PlatformException(
          code: 'private-marker',
          message: 'private-marker',
        );
      }
      return respond(call);
    });
    await expectLater(
      gateway.enter(),
      throwsA(
        predicate<Object>(
          (e) => e.toString() == 'Fullscreen operation unavailable',
        ),
      ),
    );
    expect((await gateway.restore()).enabled, isFalse);
    await gateway.close();
  });

  test(
    'native mode events are decoded and malformed events are sanitized',
    () async {
      final gateway = NativeFullscreenGateway();
      final states = <FullscreenSnapshot>[];
      final errors = <Object>[];
      var done = false;
      final subscription = gateway.states.listen(
        states.add,
        onError: errors.add,
        onDone: () => done = true,
      );
      await event({'enabled': true});
      expect(states, isEmpty);
      await gateway.initialize();
      await event({'enabled': true});
      await event({'private-marker': true});
      await event({'enabled': false}, method: 'unknown');
      await event({'enabled': false});
      expect(states.map((s) => s.enabled), [true, false]);
      expect(errors.single, isA<FullscreenOperationException>());
      await gateway.close();
      expect(done, isTrue);
      await event({'enabled': true});
      expect(states, hasLength(2));
      await subscription.cancel();
    },
  );

  test(
    'native operations are serialized and restore follows a delayed enter',
    () async {
      final gate = Completer<Object?>();
      final started = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'enter') {
          started.complete();
          return gate.future;
        }
        return {'enabled': false};
      });
      final gateway = NativeFullscreenGateway();
      await gateway.initialize();
      final entering = gateway.enter();
      final restoring = gateway.restore();
      await started.future;
      expect(calls.map((c) => c.method), ['configure', 'enter']);
      gate.complete({'enabled': true});
      expect((await entering).enabled, isTrue);
      expect((await restoring).enabled, isFalse);
      await gateway.close();
      expect(calls.map((c) => c.method), [
        'configure',
        'enter',
        'restore',
        'detach',
      ]);
    },
  );

  test(
    'close revokes queued commands but drains the accepted enter before detach',
    () async {
      final gate = Completer<Object?>();
      final started = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'enter') {
          started.complete();
          return gate.future;
        }
        return {'enabled': false};
      });
      final gateway = NativeFullscreenGateway();
      await gateway.initialize();
      final entering = gateway.enter();
      await started.future;
      final queued = expectLater(
        gateway.enter(),
        throwsA(isA<FullscreenOperationException>()),
      );
      final closing = gateway.close();
      expect(gateway.close(), same(closing));
      expect(calls.map((c) => c.method), ['configure', 'enter']);
      gate.complete({'enabled': true});
      await entering;
      await queued;
      await closing;
      expect(calls.map((c) => c.method), ['configure', 'enter', 'detach']);
      await expectLater(
        gateway.restore(),
        throwsA(isA<FullscreenOperationException>()),
      );
      await expectLater(
        gateway.initialize(),
        throwsA(isA<FullscreenOperationException>()),
      );
    },
  );

  test(
    'close before handshake completes returns no capability and then detaches',
    () async {
      final gate = Completer<Object?>();
      final started = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'configure') {
          started.complete();
          return gate.future;
        }
        return {'enabled': false};
      });
      final gateway = NativeFullscreenGateway();
      final initializing = gateway.initialize();
      await started.future;
      final closing = gateway.close();
      gate.complete({'enabled': false});
      expect(await initializing, isNull);
      await closing;
      expect(calls.map((c) => c.method), ['configure', 'detach']);
    },
  );

  test('unused close makes no platform calls', () async {
    final gateway = NativeFullscreenGateway();
    await gateway.close();
    expect(calls, isEmpty);
  });

  test(
    'detach failure is surfaced but streams and handlers are always released',
    () async {
      final gateway = NativeFullscreenGateway();
      await gateway.initialize();
      var done = false;
      gateway.states.listen((_) {}, onDone: () => done = true);
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'private-marker'),
      );
      await expectLater(
        gateway.close(),
        throwsA(isA<FullscreenOperationException>()),
      );
      expect(done, isTrue);
    },
  );

  testWidgets(
    'timeout is bounded and recovery command still reaches the host',
    (tester) async {
      final gate = Completer<Object?>();
      final gateway = NativeFullscreenGateway();
      await gateway.initialize();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'enter' ? gate.future : {'enabled': false};
      });
      final entered = expectLater(
        gateway.enter(),
        throwsA(isA<FullscreenOperationException>()),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 9));
      await entered;
      expect((await gateway.restore()).enabled, isFalse);
      gate.complete({'enabled': true});
      await tester.pump();
      await gateway.close();
      expect(calls.map((c) => c.method), [
        'configure',
        'enter',
        'restore',
        'detach',
      ]);
    },
  );

  test(
    'closing before queued handshake runs never advertises support',
    () async {
      final gateway = NativeFullscreenGateway();
      final initialized = expectLater(
        gateway.initialize(),
        throwsA(isA<FullscreenOperationException>()),
      );
      final closing = gateway.close();
      await initialized;
      await closing;
      expect(calls.map((c) => c.method), ['detach']);
    },
  );
}
