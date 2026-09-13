import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/platform/audio_output/native_audio_output_gateway.dart';
import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(NativeAudioOutputGateway.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late NativeAudioOutputGateway gateway;
  late List<MethodCall> calls;
  Object? snapshot, result, error;
  Completer<void>? gate;
  setUp(() {
    calls = [];
    snapshot = {'observation': 'unknown', 'canOpenSettings': true};
    result = 'opened';
    error = null;
    gate = null;
    gateway = NativeAudioOutputGateway(channel: channel);
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      await gate?.future;
      if (error != null) throw error!;
      return call.method == 'getState' ? snapshot : result;
    });
  });
  tearDown(() async {
    await gateway.close();
    messenger.setMockMethodCallHandler(channel, null);
  });
  test(
    'initialize is idempotent with unknown route and independent capability',
    () async {
      final first = gateway.initialize();
      expect(identical(first, gateway.initialize()), isTrue);
      final state = await first;
      expect(state.route.label, isNull);
      expect(state.canOpenSettings, isTrue);
      expect(calls.single.arguments, isNull);
    },
  );
  for (final source in ['systemDefault', 'playerRoute']) {
    test('preserves $source provenance', () async {
      snapshot = {
        'observation': source,
        'label': 'Speaker',
        'canOpenSettings': false,
      };
      expect((await gateway.initialize()).route.observation.name, source);
      expect(
        await gateway.openSystemSettings(),
        AudioOutputSettingsResult.unavailable,
      );
    });
  }
  for (final invalid in [
    null,
    true,
    <String, Object?>{},
    {'observation': 'unknown', 'canOpenSettings': 'yes'},
    {'observation': 'unknown', 'canOpenSettings': true, 'label': 'invented'},
    {
      'observation': 'playerRoute',
      'label': 'private\nlabel',
      'canOpenSettings': true,
    },
  ]) {
    test('invalid snapshot fails closed without route or capability', () async {
      snapshot = invalid;
      expect(
        await gateway.initialize(),
        const AudioOutputSnapshot.unavailable(),
      );
      expect(
        await gateway.openSystemSettings(),
        AudioOutputSettingsResult.unavailable,
      );
      expect(calls, hasLength(1));
    });
  }
  for (final value in ['opened', 'unavailable', 'failed', null, true]) {
    test('explicit launch result $value and no arbitrary arguments', () async {
      await gateway.initialize();
      result = value;
      expect(await gateway.openSystemSettings(), switch (value) {
        'opened' => AudioOutputSettingsResult.opened,
        'unavailable' => AudioOutputSettingsResult.unavailable,
        _ => AudioOutputSettingsResult.failed,
      });
      expect(calls.last.method, 'openSystemSettings');
      expect(calls.last.arguments, isNull);
    });
  }
  test('launch before initialization never invokes host', () async {
    expect(
      await gateway.openSystemSettings(),
      AudioOutputSettingsResult.unavailable,
    );
    expect(calls, isEmpty);
  });
  test(
    'refresh failure clears prior known route and disables launch',
    () async {
      snapshot = {
        'observation': 'systemDefault',
        'label': 'Speaker',
        'canOpenSettings': true,
      };
      await gateway.initialize();
      final states = <AudioOutputSnapshot>[];
      final sub = gateway.states.listen(states.add);
      error = PlatformException(code: 'private');
      expect(await gateway.refresh(), const AudioOutputSnapshot.unavailable());
      expect(states.single, const AudioOutputSnapshot.unavailable());
      expect(
        await gateway.openSystemSettings(),
        AudioOutputSettingsResult.unavailable,
      );
      await sub.cancel();
    },
  );
  test('missing plugin can reconnect on refresh', () async {
    messenger.setMockMethodCallHandler(channel, null);
    expect(await gateway.initialize(), const AudioOutputSnapshot.unavailable());
    messenger.setMockMethodCallHandler(channel, (_) async => snapshot);
    expect((await gateway.refresh()).canOpenSettings, isTrue);
  });
  test(
    'launch exception does not expose native details or claim success',
    () async {
      await gateway.initialize();
      error = PlatformException(code: 'private launch failure');
      expect(
        await gateway.openSystemSettings(),
        AudioOutputSettingsResult.failed,
      );
    },
  );
  test('close drains accepted read and revokes queued launch', () async {
    gate = Completer<void>();
    final read = gateway.initialize();
    await Future<void>.delayed(Duration.zero);
    final opening = gateway.openSystemSettings();
    var closed = false;
    final closing = gateway.close().then((_) => closed = true);
    await Future<void>.delayed(Duration.zero);
    expect(closed, isFalse);
    gate!.complete();
    expect(await read, const AudioOutputSnapshot.unavailable());
    expect(await opening, AudioOutputSettingsResult.unavailable);
    await closing;
    expect(calls, hasLength(1));
    expect(await gateway.initialize(), const AudioOutputSnapshot.unavailable());
    expect(await gateway.refresh(), const AudioOutputSnapshot.unavailable());
  });
  test('close cannot retract a launch already accepted by the OS', () async {
    await gateway.initialize();
    gate = Completer<void>();
    final opening = gateway.openSystemSettings();
    await Future<void>.delayed(Duration.zero);
    final closing = gateway.close();
    gate!.complete();
    expect(await opening, AudioOutputSettingsResult.opened);
    await closing;
    expect(await gateway.initialize(), const AudioOutputSnapshot.unavailable());
  });
  test('state listener can close reentrantly', () async {
    Future<void>? closing;
    final sub = gateway.states.listen((_) => closing = gateway.close());
    expect(await gateway.initialize(), const AudioOutputSnapshot.unavailable());
    await sub.cancel();
    await closing;
    expect(
      await gateway.openSystemSettings(),
      AudioOutputSettingsResult.unavailable,
    );
  });
}
