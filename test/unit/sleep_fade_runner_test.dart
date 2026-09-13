import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/playback/sleep_fade_runner.dart';

void main() {
  late _Fixture f;
  setUp(() => f = _Fixture());
  tearDown(() async {
    f.gate?.complete();
    f.gate = null;
    await f.runner.close();
  });

  test('samples amplitude then pauses once and restores once', () async {
    final done = f.runner.start();
    await _flush();
    expect(f.calls, ['gain:1.0']);
    f.tick(1000);
    await _flush();
    f.tick(2000);
    final result = await done;
    expect(result.status, SleepFadeStatus.completed);
    expect(f.calls, ['gain:1.0', 'gain:0.5', 'gain:0.0', 'pause', 'restore']);
    expect(identical(f.runner.start(), done), isTrue);
    await f.runner.close();
    expect(f.calls.where((call) => call == 'restore'), hasLength(1));
  });

  test('cancel before start has no borrowed side effects', () async {
    final result = await f.runner.close();
    expect(result.status, SleepFadeStatus.cancelled);
    expect(f.calls, isEmpty);
    expect(f.wakes, isEmpty);
  });

  test('owner revocation before start does not touch volume', () async {
    f.current = false;
    expect((await f.runner.start()).status, SleepFadeStatus.cancelled);
    expect(f.calls, isEmpty);
  });

  test('cancel wakes wait and ignores retained timer callbacks', () async {
    final done = f.runner.start();
    await _flush();
    final wake = f.wakes.single;
    f.runner.cancel();
    expect((await done).status, SleepFadeStatus.cancelled);
    wake.fire();
    await _flush();
    expect(wake.isActive, isFalse);
    expect(f.calls, ['gain:1.0', 'restore']);
  });

  test('cancel drains slow gain before restoring and never pauses', () async {
    final gate = f.gate = Completer<void>();
    final done = f.runner.start();
    await _flush();
    var closed = false;
    final close = f.runner.close().then((_) => closed = true);
    await _flush();
    expect(closed, isFalse);
    expect(f.calls, ['gain:1.0']);
    gate.complete();
    f.gate = null;
    await close;
    expect((await done).status, SleepFadeStatus.cancelled);
    expect(f.calls, ['gain:1.0', 'restore']);
  });

  test('late wake jumps to end without replaying missed steps', () async {
    final done = f.runner.start();
    await _flush();
    f.tick(9000);
    expect((await done).status, SleepFadeStatus.completed);
    expect(f.calls, ['gain:1.0', 'gain:0.0', 'pause', 'restore']);
  });

  test('clock regression cannot increase amplitude', () async {
    unawaited(f.runner.start());
    await _flush();
    f.tick(1000);
    await _flush();
    f.tick(200);
    await _flush();
    expect(f.calls, ['gain:1.0', 'gain:0.5', 'gain:0.5']);
  });

  test('owner revoked during write prevents pause and restores', () async {
    f.elapsed = const Duration(seconds: 2);
    f.onGain = () => f.current = false;
    expect((await f.runner.start()).status, SleepFadeStatus.cancelled);
    expect(f.calls, ['gain:0.0', 'restore']);
  });

  test('owner revoked by clock callback never writes', () async {
    f.onClock = () => f.current = false;
    expect((await f.runner.start()).status, SleepFadeStatus.cancelled);
    expect(f.calls, isEmpty);
  });

  test(
    'synchronous gain callback can close without self-await deadlock',
    () async {
      Future<SleepFadeOutcome>? close;
      f.onGain = () => close = f.runner.close();
      final done = f.runner.start();
      expect((await done).status, SleepFadeStatus.cancelled);
      expect(identical(done, close), isTrue);
      expect(f.calls, ['gain:1.0', 'restore']);
    },
  );

  test('scheduler reentrant cancellation cancels returned timer', () async {
    f.onSchedule = () => f.runner.cancel();
    expect((await f.runner.start()).status, SleepFadeStatus.cancelled);
    expect(f.wakes.single.isActive, isFalse);
    expect(f.calls, ['gain:1.0', 'restore']);
  });

  test(
    'synchronous wake and retained old callback cannot consume next wait',
    () async {
      var first = true;
      f.onSchedule = () {
        if (first) {
          first = false;
          f.elapsed = const Duration(seconds: 1);
          f.wakes.last.fire();
        }
      };
      final done = f.runner.start();
      await _flush();
      expect(f.wakes, hasLength(2));
      expect(f.wakes.first.isActive, isFalse);
      f.wakes.first.fire();
      await _flush();
      expect(f.calls, ['gain:1.0', 'gain:0.5']);
      f.tick(2000);
      expect((await done).status, SleepFadeStatus.completed);
    },
  );

  for (final operation in SleepFadeOperation.values) {
    test('$operation failure is observable with safe diagnostics', () async {
      f.failure = operation;
      if (operation == SleepFadeOperation.pause ||
          operation == SleepFadeOperation.restore) {
        f.elapsed = const Duration(seconds: 2);
      }
      final result = await f.runner.start();
      expect(result.status, SleepFadeStatus.failed);
      expect(result.failure, operation);
      expect(result.restorationFailed, operation == SleepFadeOperation.restore);
      expect(result.toString(), isNot(contains('private payload')));
      final touched = !{
        SleepFadeOperation.ownership,
        SleepFadeOperation.clock,
      }.contains(operation);
      expect(
        f.calls.where((call) => call == 'restore'),
        hasLength(touched ? 1 : 0),
      );
    });
  }

  test(
    'failed gain still restores; simultaneous restore failure is retained',
    () async {
      f.failure = SleepFadeOperation.gain;
      f.restoreFails = true;
      final result = await f.runner.start();
      expect(result.status, SleepFadeStatus.failed);
      expect(result.failure, SleepFadeOperation.gain);
      expect(result.restorationFailed, isTrue);
      expect(f.calls, ['gain:1.0', 'restore']);
    },
  );

  test(
    'restoration reads latest owner volume after cancelled in-flight gain',
    () async {
      var userVolume = 0.8;
      double? restored;
      f.onRestore = () => restored = userVolume;
      final gate = f.gate = Completer<void>();
      final done = f.runner.start();
      await _flush();
      f.runner.cancel();
      userVolume = 0.2;
      gate.complete();
      f.gate = null;
      await done;
      expect(restored, 0.2);
    },
  );
}

Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final class _Fixture {
  _Fixture() {
    runner = SleepFadeRunner(
      writeGain: (gain) async {
        calls.add('gain:$gain');
        onGain?.call();
        await gate?.future;
        fail(SleepFadeOperation.gain);
      },
      pause: () async {
        calls.add('pause');
        fail(SleepFadeOperation.pause);
      },
      restore: () async {
        calls.add('restore');
        onRestore?.call();
        if (restoreFails) throw StateError('private payload');
        fail(SleepFadeOperation.restore);
      },
      isCurrent: () {
        fail(SleepFadeOperation.ownership);
        return current;
      },
      elapsed: () {
        onClock?.call();
        fail(SleepFadeOperation.clock);
        return elapsed;
      },
      scheduler: (delay, callback) {
        fail(SleepFadeOperation.schedule);
        final wake = _Wake(callback);
        wakes.add(wake);
        onSchedule?.call();
        return wake;
      },
    );
  }

  late final SleepFadeRunner runner;
  Duration elapsed = Duration.zero;
  bool current = true;
  bool restoreFails = false;
  SleepFadeOperation? failure;
  Completer<void>? gate;
  void Function()? onGain;
  void Function()? onClock;
  void Function()? onRestore;
  void Function()? onSchedule;
  final calls = <String>[];
  final wakes = <_Wake>[];

  void tick(int milliseconds) {
    elapsed = Duration(milliseconds: milliseconds);
    wakes.last.fire();
  }

  void fail(SleepFadeOperation operation) {
    if (failure == operation) throw StateError('private payload');
  }
}

final class _Wake implements Timer {
  _Wake(this.callback);
  final void Function() callback;
  bool _active = true;
  void fire() => callback();
  @override
  bool get isActive => _active;
  @override
  int get tick => 0;
  @override
  void cancel() => _active = false;
}
