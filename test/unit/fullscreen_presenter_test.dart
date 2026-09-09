import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/fullscreen_presenter.dart';
import 'package:yymusic/platform/contracts/fullscreen_gateway.dart';

import '../support/fake_fullscreen_gateway.dart';

Future<void> flushFullscreen() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void route(
  FullscreenPresenter presenter, {
  bool eligible = true,
  bool modal = false,
  bool player = true,
  bool Function()? current,
}) => presenter.setRoute(
  Object(),
  eligible: eligible,
  modal: modal,
  player: player,
  isCurrent: current ?? () => true,
);

void main() {
  late FakeFullscreenGateway gateway;
  late FullscreenPresenter presenter;
  setUp(() {
    gateway = FakeFullscreenGateway();
    presenter = FullscreenPresenter(gateway, automatic: false);
  });
  tearDown(() => presenter.close());

  test('Windows initializes once and only enters by explicit intent', () async {
    route(presenter);
    await Future.wait([presenter.initialize(), presenter.initialize()]);
    await flushFullscreen();
    expect(gateway.calls, ['initialize']);
    expect(presenter.canToggle, isTrue);
    presenter.toggle();
    await flushFullscreen();
    expect(presenter.enabled && presenter.hideChrome, isTrue);
    presenter.toggle();
    await flushFullscreen();
    expect(presenter.enabled, isFalse);
    expect(gateway.calls, ['initialize', 'enter', 'restore']);
  });

  test('Android enters new pages but retains one session between player and lyrics', () async {
    await presenter.close();
    gateway = FakeFullscreenGateway();
    presenter = FullscreenPresenter(gateway, automatic: true);
    route(presenter);
    await presenter.initialize();
    await flushFullscreen();
    route(presenter, player: false);
    await flushFullscreen();
    expect(gateway.calls, ['initialize', 'enter']);
    route(presenter, eligible: false);
    await flushFullscreen();
    expect(gateway.calls.last, 'restore');
  });

  test('cover and exit revoke queued entry before any native call', () async {
    await presenter.initialize();
    route(presenter);
    presenter.toggle();
    route(presenter, eligible: false, modal: true);
    await flushFullscreen();
    expect(gateway.calls, ['initialize']);
    expect(presenter.canToggle || presenter.canOpenPlayer, isFalse);
  });

  test(
    'route current check revokes a stale entry even before observer catches up',
    () async {
      await presenter.initialize();
      var current = true;
      route(presenter, current: () => current);
      presenter.toggle();
      current = false;
      await flushFullscreen();
      expect(gateway.calls, ['initialize']);
    },
  );

  test(
    'accepted late entry is restored after leaving with no second entry',
    () async {
      final pending = Completer<FullscreenSnapshot>();
      gateway.onEnter = () => pending.future;
      await presenter.initialize();
      route(presenter);
      presenter.toggle();
      await flushFullscreen();
      expect(presenter.busy && presenter.exitBeforeBack, isTrue);
      route(presenter, eligible: false);
      pending.complete(const FullscreenSnapshot(enabled: true));
      await flushFullscreen();
      expect(gateway.calls, ['initialize', 'enter', 'restore']);
      expect(presenter.enabled, isFalse);
    },
  );

  test('native exit event wins over an older enter response', () async {
    final pending = Completer<FullscreenSnapshot>();
    gateway.onEnter = () => pending.future;
    await presenter.initialize();
    route(presenter);
    presenter.toggle();
    await flushFullscreen();
    gateway.emit(true);
    gateway.emit(false);
    pending.complete(const FullscreenSnapshot(enabled: true));
    await flushFullscreen();
    expect(presenter.enabled, isFalse);
    expect(gateway.calls, ['initialize', 'enter', 'restore']);
  });

  for (final hidden in ['background', 'zero viewport']) {
    test('$hidden restores and returning alone never re-enters', () async {
      await presenter.initialize();
      route(presenter);
      presenter.toggle();
      await flushFullscreen();
      if (hidden == 'background') {
        presenter.setForeground(false);
        presenter.setForeground(true);
      } else {
        presenter.setVisible(false);
        presenter.setVisible(true);
      }
      await flushFullscreen();
      expect(presenter.enabled, isFalse);
      expect(gateway.calls, ['initialize', 'enter', 'restore']);
      presenter.toggle();
      await flushFullscreen();
      expect(gateway.calls.last, 'enter');
    });
  }

  test('keyboard entry targets only the next player and is revoked by another route', () async {
    await presenter.initialize();
    route(presenter, eligible: false);
    presenter.enterOnNextPlayer();
    route(presenter);
    await flushFullscreen();
    expect(presenter.enabled, isTrue);
    route(presenter, eligible: false);
    await flushFullscreen();
    presenter.enterOnNextPlayer();
    route(presenter, eligible: false, modal: true);
    route(presenter);
    await flushFullscreen();
    expect(presenter.enabled, isFalse);
  });

  test(
    'restore failure leaves chrome and a safe retry available without spinning',
    () async {
      await presenter.initialize();
      route(presenter);
      presenter.toggle();
      await flushFullscreen();
      gateway.failRestore = true;
      presenter.restore();
      await flushFullscreen();
      expect(presenter.enabled, isTrue);
      expect(presenter.hideChrome, isFalse);
      expect(presenter.errorMessage, isNot(contains('private diagnostic')));
      expect(gateway.calls, ['initialize', 'enter', 'restore']);
      gateway.failRestore = false;
      presenter.restore();
      await flushFullscreen();
      expect(presenter.enabled, isFalse);
      expect(presenter.errorMessage, isNull);
    },
  );

  test(
    'entry failure makes one recovery attempt and preserves readable failure',
    () async {
      gateway.failEnter = true;
      await presenter.initialize();
      route(presenter);
      presenter.toggle();
      await flushFullscreen();
      expect(gateway.calls, ['initialize', 'enter', 'restore']);
      expect(presenter.errorMessage, isNotNull);
      expect(presenter.errorMessage, isNot(contains('private diagnostic')));
      gateway.failEnter = false;
      presenter.toggle();
      await flushFullscreen();
      expect(presenter.enabled, isTrue);
      expect(presenter.errorMessage, isNull);
    },
  );

  test('unsupported host has no button or automatic native requests', () async {
    gateway.supported = false;
    route(presenter);
    await presenter.initialize();
    presenter.toggle();
    await flushFullscreen();
    expect(presenter.available || presenter.canToggle, isFalse);
    expect(presenter.errorMessage, isNull);
    expect(gateway.calls, ['initialize']);
  });

  test(
    'failed initialization is sanitized and shutdown still releases gateway',
    () async {
      gateway.failInitialize = true;
      await presenter.initialize();
      expect(presenter.available, isFalse);
      expect(presenter.errorMessage, isNotNull);
      expect(presenter.errorMessage, isNot(contains('private diagnostic')));
      await presenter.close();
      expect(gateway.calls, ['initialize', 'close']);
    },
  );

  test('initial native session outside eligible routes is restored', () async {
    gateway.enabled = true;
    await presenter.initialize();
    await flushFullscreen();
    expect(gateway.calls, ['initialize', 'restore']);
    expect(presenter.enabled, isFalse);
  });

  test(
    'a native exit during handshake is not overwritten by the earlier snapshot',
    () async {
      final pending = Completer<FullscreenSnapshot?>();
      gateway.onInitialize = () => pending.future;
      route(presenter);
      final initializing = presenter.initialize();
      gateway.emit(false);
      pending.complete(const FullscreenSnapshot(enabled: true));
      await initializing;
      await flushFullscreen();
      expect(presenter.enabled, isFalse);
      expect(gateway.calls, ['initialize']);
    },
  );

  test('listener may close reentrantly without issuing queued entry', () async {
    await presenter.initialize();
    route(presenter);
    presenter.addListener(presenter.dispose);
    presenter.toggle();
    await flushFullscreen();
    await presenter.close();
    expect(gateway.calls, ['initialize', 'close']);
  });

  test(
    'close drains accepted work, releases once and ignores late route updates',
    () async {
      final pending = Completer<FullscreenSnapshot>();
      gateway.onEnter = () => pending.future;
      await presenter.initialize();
      route(presenter);
      presenter.toggle();
      await flushFullscreen();
      var closed = false;
      final closing = presenter.close().then((_) => closed = true);
      route(presenter);
      presenter.toggle();
      await flushFullscreen();
      expect(closed, isFalse);
      pending.complete(const FullscreenSnapshot(enabled: true));
      await closing;
      await presenter.close();
      expect(gateway.calls, ['initialize', 'enter', 'close']);
    },
  );

  test(
    'close while handshake waits never enters a former Android page',
    () async {
      final pending = Completer<void>();
      gateway.initializeWait = pending.future;
      route(presenter);
      final initialize = presenter.initialize();
      final close = presenter.close();
      pending.complete();
      await Future.wait([initialize, close]);
      expect(gateway.calls, ['initialize', 'close']);
    },
  );
}
