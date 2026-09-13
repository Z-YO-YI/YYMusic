import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/platform/audio_output/audio_output_controller.dart';
import 'package:yymusic/platform/contracts/audio_output_gateway.dart';

AudioOutputSnapshot output(String label) => AudioOutputSnapshot(
  route: AudioOutputRoute.systemDefault(label),
  canOpenSettings: true,
);

final class OutputGateway implements AudioOutputGateway {
  final events = StreamController<AudioOutputSnapshot>.broadcast(sync: true);
  final reads = <Completer<AudioOutputSnapshot>>[];
  int initializations = 0, refreshes = 0, closes = 0, launches = 0;
  @override
  Stream<AudioOutputSnapshot> get states => events.stream;
  Future<AudioOutputSnapshot> read() {
    final result = Completer<AudioOutputSnapshot>();
    reads.add(result);
    return result.future;
  }

  @override
  Future<AudioOutputSnapshot> initialize() {
    initializations++;
    return read();
  }

  @override
  Future<AudioOutputSnapshot> refresh() {
    refreshes++;
    return read();
  }

  @override
  Future<AudioOutputSettingsResult> openSystemSettings() async {
    launches++;
    return AudioOutputSettingsResult.opened;
  }

  @override
  Future<void> close() async {
    closes++;
    await events.close();
  }
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late OutputGateway gateway;
  late AudioOutputController controller;
  setUp(() {
    gateway = OutputGateway();
    controller = AudioOutputController(gateway);
  });
  tearDown(() async {
    for (final read in gateway.reads) {
      if (!read.isCompleted) {
        read.complete(const AudioOutputSnapshot.unavailable());
      }
    }
    await controller.close();
    await gateway.events.close();
  });

  test(
    'starts unknown and initializes once without launching settings',
    () async {
      expect(controller.snapshot, const AudioOutputSnapshot.unavailable());
      final first = controller.initialize();
      expect(identical(first, controller.initialize()), isTrue);
      await flush();
      gateway.reads.single.complete(output('Speakers'));
      await first;
      expect(controller.snapshot, output('Speakers'));
      await controller.initialize();
      expect(gateway.initializations, 1);
      expect(gateway.launches, 0);
    },
  );

  test('refresh before initialize performs initialization', () async {
    final work = controller.refresh();
    await flush();
    gateway.reads.single.complete(output('Default'));
    await work;
    await controller.initialize();
    expect(gateway.initializations, 1);
    expect(gateway.refreshes, 0);
  });

  test('refresh burst coalesces and suppresses obsolete read', () async {
    final work = controller.initialize();
    await flush();
    final refresh = controller.refresh();
    expect(identical(refresh, controller.refresh()), isTrue);
    gateway.reads.first.complete(output('Old'));
    await flush();
    expect(controller.snapshot, const AudioOutputSnapshot.unavailable());
    expect(gateway.refreshes, 1);
    gateway.reads.last.complete(output('New'));
    await Future.wait([work, refresh]);
    expect(controller.snapshot, output('New'));
  });

  test('newer stream observation wins over pending read', () async {
    final work = controller.initialize();
    await flush();
    gateway.events.add(output('New'));
    gateway.reads.single.complete(output('Old'));
    await work;
    expect(controller.snapshot, output('New'));
  });

  test('read failure clears previously confirmed output', () async {
    final work = controller.initialize();
    await flush();
    gateway.reads.single.complete(output('Old'));
    await work;
    final refresh = controller.refresh();
    await flush();
    gateway.reads.last.completeError(StateError('private native payload'));
    await refresh;
    expect(controller.snapshot, const AudioOutputSnapshot.unavailable());
  });

  test('stream error invalidates route and rejects older read', () async {
    final work = controller.initialize();
    await flush();
    gateway.events.add(output('Old'));
    gateway.events.addError(StateError('private native payload'));
    gateway.reads.single.complete(output('Old'));
    await work;
    expect(controller.snapshot, const AudioOutputSnapshot.unavailable());
  });

  test('refresh recovers after a failed read', () async {
    final work = controller.initialize();
    await flush();
    gateway.reads.single.completeError(StateError('native failure'));
    await work;
    final retry = controller.refresh();
    await flush();
    gateway.reads.last.complete(output('Recovered'));
    await retry;
    expect(controller.snapshot, output('Recovered'));
  });

  test(
    'listener refresh is drained without overlapping native calls',
    () async {
      controller.addListener(() {
        if (controller.snapshot == output('First')) controller.refresh();
      });
      final work = controller.initialize();
      await flush();
      gateway.reads.single.complete(output('First'));
      await flush();
      expect(gateway.reads.length, 2);
      gateway.reads.last.complete(output('Second'));
      await work;
      expect(controller.snapshot, output('Second'));
    },
  );

  test('late read error cannot erase a newer stream observation', () async {
    final work = controller.initialize();
    await flush();
    gateway.events.add(output('New'));
    gateway.reads.single.completeError(StateError('old read failure'));
    await work;
    expect(controller.snapshot, output('New'));
  });

  test('identical observations do not notify twice', () async {
    var count = 0;
    controller.addListener(() => count++);
    final work = controller.initialize();
    await flush();
    gateway.events.add(output('Default'));
    gateway.events.add(output('Default'));
    gateway.reads.single.complete(output('Default'));
    await work;
    expect(count, 1);
  });

  test(
    'close drains accepted read but does not close borrowed gateway',
    () async {
      final work = controller.initialize();
      await flush();
      unawaited(controller.refresh());
      var closed = false;
      final closing = controller.close().then((_) => closed = true);
      await flush();
      expect(closed, isFalse);
      gateway.events.add(output('Late'));
      gateway.reads.single.complete(output('Late'));
      await Future.wait([work, closing]);
      await controller.refresh();
      await controller.initialize();
      expect(controller.snapshot, const AudioOutputSnapshot.unavailable());
      expect(gateway.refreshes, 0);
      expect(gateway.closes, 0);
      expect(gateway.events.hasListener, isFalse);
    },
  );

  test('listener may close synchronously during publication', () async {
    controller.addListener(controller.dispose);
    final work = controller.initialize();
    await flush();
    gateway.events.add(output('Default'));
    gateway.reads.single.complete(output('Default'));
    await work;
    await controller.close();
    expect(controller.snapshot, const AudioOutputSnapshot.unavailable());
  });

  test(
    'close before scheduled initialization invokes no native work',
    () async {
      final work = controller.initialize();
      await controller.close();
      await work;
      expect(gateway.reads, isEmpty);
      expect(gateway.events.hasListener, isFalse);
    },
  );
}
