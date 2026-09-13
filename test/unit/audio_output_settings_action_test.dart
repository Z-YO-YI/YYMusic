import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/platform/audio_output/audio_output_controller.dart';
import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

import '../support/fake_audio_output_gateway.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAudioOutputGateway gateway;
  late AudioOutputController controller;
  setUp(() async {
    gateway = FakeAudioOutputGateway();
    controller = AudioOutputController(gateway);
    await controller.initialize();
  });
  tearDown(() async {
    await controller.close();
    await gateway.close();
  });

  test('accepted launch leaves route unchanged and does not refresh', () async {
    final snapshot = controller.snapshot;
    final result = await controller.openSystemSettings(isCurrent: () => true);
    expect(result, AudioOutputSettingsResult.opened);
    expect(controller.snapshot, snapshot);
    expect(gateway.calls, ['initialize', 'open']);
    expect(controller.openingSettings, isFalse);
  });

  test('unknown capability refuses without consuming page callback', () async {
    gateway.events.add(const AudioOutputSnapshot.unavailable());
    final result = await controller.openSystemSettings(
      isCurrent: () => throw StateError('must not call'),
    );
    expect(result, AudioOutputSettingsResult.unavailable);
    expect(gateway.calls, ['initialize']);
  });

  test('revoked page intent prevents launch', () async {
    final result = await controller.openSystemSettings(isCurrent: () => false);
    expect(result, AudioOutputSettingsResult.unavailable);
    expect(gateway.calls, ['initialize']);
  });

  test('permission exception is not exposed and does not launch', () async {
    final result = await controller.openSystemSettings(
      isCurrent: () => throw StateError('private page data'),
    );
    expect(result, AudioOutputSettingsResult.unavailable);
    expect(gateway.calls, ['initialize']);
  });

  test('duplicate requests reject while native launch is pending', () async {
    final gate = Completer<AudioOutputSettingsResult>();
    gateway.onOpen = () => gate.future;
    final first = controller.openSystemSettings(isCurrent: () => true);
    expect(controller.openingSettings, isTrue);
    await flush();
    final second = await controller.openSystemSettings(isCurrent: () => true);
    expect(second, AudioOutputSettingsResult.unavailable);
    expect(gateway.calls, ['initialize', 'open']);
    gate.complete(AudioOutputSettingsResult.opened);
    await first;
  });

  test('permission is checked after pending refresh completes', () async {
    final gate = Completer<AudioOutputSnapshot>();
    final snapshot = controller.snapshot;
    gateway.onRead = () => gate.future;
    final reading = controller.refresh();
    var live = true;
    final launching = controller.openSystemSettings(isCurrent: () => live);
    await flush();
    expect(gateway.calls, ['initialize', 'refresh']);
    live = false;
    gate.complete(snapshot);
    await reading;
    expect(await launching, AudioOutputSettingsResult.unavailable);
    expect(gateway.calls, ['initialize', 'refresh']);
  });

  test('capability loss during refresh prevents queued launch', () async {
    gateway.onRead = () async => const AudioOutputSnapshot.unavailable();
    final reading = controller.refresh();
    final launching = controller.openSystemSettings(isCurrent: () => true);
    await reading;
    expect(await launching, AudioOutputSettingsResult.unavailable);
    expect(gateway.calls, ['initialize', 'refresh']);
  });

  test('permission callback close is rechecked', () async {
    final result = await controller.openSystemSettings(
      isCurrent: () {
        controller.dispose();
        return true;
      },
    );
    expect(result, AudioOutputSettingsResult.unavailable);
    expect(gateway.calls, ['initialize']);
  });

  test('permission callback capability revocation is rechecked', () async {
    final result = await controller.openSystemSettings(
      isCurrent: () {
        gateway.events.add(const AudioOutputSnapshot.unavailable());
        return true;
      },
    );
    expect(result, AudioOutputSettingsResult.unavailable);
    expect(gateway.calls, ['initialize']);
  });

  test('busy listener may close before any native dispatch', () async {
    controller.addListener(() {
      if (controller.openingSettings) controller.dispose();
    });
    expect(
      await controller.openSystemSettings(isCurrent: () => true),
      AudioOutputSettingsResult.unavailable,
    );
    expect(gateway.calls, ['initialize']);
  });

  test('close drains accepted launch and preserves actual OS result', () async {
    final gate = Completer<AudioOutputSettingsResult>();
    gateway.onOpen = () => gate.future;
    final launching = controller.openSystemSettings(isCurrent: () => true);
    await flush();
    var closed = false;
    final closing = controller.close().then((_) => closed = true);
    await flush();
    expect(closed, isFalse);
    expect(controller.openingSettings, isFalse);
    gate.complete(AudioOutputSettingsResult.opened);
    expect(await launching, AudioOutputSettingsResult.opened);
    await closing;
    expect(
      await controller.openSystemSettings(isCurrent: () => true),
      AudioOutputSettingsResult.unavailable,
    );
    expect(gateway.calls, ['initialize', 'open']);
  });

  test(
    'native exception maps to failed and permits an explicit retry',
    () async {
      gateway.onOpen = () async => throw StateError('private native detail');
      expect(
        await controller.openSystemSettings(isCurrent: () => true),
        AudioOutputSettingsResult.failed,
      );
      gateway.onOpen = null;
      expect(
        await controller.openSystemSettings(isCurrent: () => true),
        AudioOutputSettingsResult.opened,
      );
      expect(gateway.calls, ['initialize', 'open', 'open']);
    },
  );

  test('native unavailable result remains unavailable', () async {
    gateway.onOpen = () async => AudioOutputSettingsResult.unavailable;
    expect(
      await controller.openSystemSettings(isCurrent: () => true),
      AudioOutputSettingsResult.unavailable,
    );
    expect(controller.openingSettings, isFalse);
  });

  test(
    'unknown route does not hide a supported system settings capability',
    () async {
      gateway.events.add(
        const AudioOutputSnapshot(
          route: AudioOutputRoute.unknown(),
          canOpenSettings: true,
        ),
      );
      expect(
        await controller.openSystemSettings(isCurrent: () => true),
        AudioOutputSettingsResult.opened,
      );
      expect(
        controller.snapshot.route.observation,
        AudioOutputObservation.unknown,
      );
    },
  );

  test(
    'busy notification cannot reentrantly dispatch a second launch',
    () async {
      Future<AudioOutputSettingsResult>? duplicate;
      controller.addListener(() {
        if (controller.openingSettings) {
          duplicate = controller.openSystemSettings(isCurrent: () => true);
        }
      });
      expect(
        await controller.openSystemSettings(isCurrent: () => true),
        AudioOutputSettingsResult.opened,
      );
      expect(await duplicate, AudioOutputSettingsResult.unavailable);
      expect(gateway.calls, ['initialize', 'open']);
    },
  );
}
