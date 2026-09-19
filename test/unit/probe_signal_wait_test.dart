import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/probe_signal_wait.dart';

void main() {
  test('existing fact needs no stream subscription', () async {
    final signals = StreamController<void>.broadcast();
    await waitForProbeSignal(
      signals.stream,
      () => true,
      const Duration(seconds: 1),
    );
    expect(signals.hasListener, isFalse);
    await signals.close();
  });

  test('observed change completes and cancels the subscription', () async {
    final signals = StreamController<void>.broadcast(sync: true);
    var accepted = false;
    final pending = waitForProbeSignal(
      signals.stream,
      () => accepted,
      const Duration(seconds: 1),
    );
    signals.add(null);
    expect(signals.hasListener, isTrue);
    accepted = true;
    signals.add(null);
    await pending;
    expect(signals.hasListener, isFalse);
    await signals.close();
  });

  test(
    'deadline rejects and cancels instead of leaving a firstWhere listener',
    () async {
      final signals = StreamController<void>.broadcast();
      await expectLater(
        waitForProbeSignal(
          signals.stream,
          () => false,
          const Duration(milliseconds: 2),
        ),
        throwsA(isA<TimeoutException>()),
      );
      expect(signals.hasListener, isFalse);
      await signals.close();
    },
  );

  test(
    'source error, closure and predicate exception reject and cancel',
    () async {
      for (var mode = 0; mode < 3; mode++) {
        final signals = StreamController<void>.broadcast(sync: true);
        var failPredicate = false;
        final pending = waitForProbeSignal(signals.stream, () {
          if (failPredicate) throw StateError('predicate');
          return false;
        }, const Duration(seconds: 1));
        final checked = expectLater(pending, throwsStateError);
        if (mode == 0) {
          signals.addError(StateError('source'));
        } else if (mode == 1) {
          await signals.close();
        } else {
          failPredicate = true;
          signals.add(null);
        }
        await checked;
        expect(signals.hasListener, isFalse);
        await signals.close();
      }
    },
  );
}
