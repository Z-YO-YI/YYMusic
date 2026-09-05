import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/window_presenter.dart';

import '../support/fake_window_gateway.dart';

void main() {
  test(
    'native snapshots drive controls and pending commands suppress duplicates',
    () async {
      final native = FakeWindowGateway();
      final presenter = WindowPresenter(native, beforeClose: () async {});
      expect(presenter.available, isFalse);
      await presenter.initialize();
      await presenter.initialize();
      expect(native.calls, ['initialize']);
      expect(presenter.canControl, isTrue);
      final gate = Completer<void>();
      native.commandGate = gate.future;
      final command = presenter.toggleMaximize();
      await presenter.minimize();
      expect(presenter.canControl, isFalse);
      expect(presenter.maximized, isFalse);
      gate.complete();
      await command;
      expect(presenter.maximized, isTrue);
      expect(native.calls, ['initialize', 'toggleMaximize']);
      await presenter.close();
      expect(native.disposalCount, 1);
    },
  );
  test(
    'unsupported and failed initialization do not pretend custom controls',
    () async {
      for (final unsupported in [true, false]) {
        final native = FakeWindowGateway()..unsupported = unsupported;
        if (!unsupported) {
          native.initializeError = StateError('private-window-marker');
        }
        final presenter = WindowPresenter(native, beforeClose: () async {});
        await presenter.initialize();
        expect(presenter.available, isFalse);
        expect(presenter.errorMessage, unsupported ? isNull : '窗口操作未完成，请重试。');
        await presenter.minimize();
        expect(native.calls, ['initialize']);
        await presenter.close();
      }
    },
  );
  test('close requests are idempotent and await business shutdown before native close', () async {
    final native = FakeWindowGateway();
    final gate = Completer<void>();
    var shutdownCalls = 0;
    final presenter = WindowPresenter(
      native,
      beforeClose: () async {
        shutdownCalls++;
        await gate.future;
      },
    );
    await presenter.initialize();
    final closing = presenter.requestClose();
    native.requests.add(null);
    await presenter.requestClose();
    expect(shutdownCalls, 1);
    expect(presenter.closing, isTrue);
    expect(native.calls, ['initialize']);
    gate.complete();
    await closing;
    expect(native.calls.last, 'completeClose');
    await presenter.close();
  });
  test(
    'all business releases attempted even when shutdown reports failure',
    () async {
      final native = FakeWindowGateway();
      final presenter = WindowPresenter(
        native,
        beforeClose: () async {
          throw StateError('private');
        },
      );
      await presenter.initialize();
      await presenter.requestClose();
      expect(native.calls.last, 'completeClose');
      await presenter.close();
    },
  );
  test(
    'late initialization and close callbacks never act on a disposed root',
    () async {
      final native = FakeWindowGateway();
      final gate = Completer<void>();
      native.initializeGate = gate.future;
      final presenter = WindowPresenter(native, beforeClose: () async {});
      var notifications = 0;
      presenter.addListener(() => notifications++);
      final initializing = presenter.initialize();
      await presenter.close();
      gate.complete();
      await initializing;
      await presenter.requestClose();
      expect(notifications, 0);
      expect(native.calls, ['initialize']);
      expect(native.disposalCount, 1);
    },
  );
}
