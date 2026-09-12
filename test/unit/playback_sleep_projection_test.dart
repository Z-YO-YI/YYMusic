import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/app/playback_presenter.dart';
import 'package:yymusic/app/playback_sleep_action.dart';
import 'package:yymusic/playback/audio_engine.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_sleep_timer_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late FakeAudioEngine engine;
  late FakeLibraryRepository library;
  late PlaybackController root;
  late PlaybackPresenter presenter;

  setUp(() {
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    root = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
    );
    presenter = PlaybackPresenter(root);
  });
  tearDown(() async {
    presenter.dispose();
    await root.close();
    await engine.dispose();
    await library.dispose();
  });

  PlaybackSleepAction action(PlaybackSleepChoice choice) =>
      presenter.sleepAction(choice, isCurrent: () => true)!;

  Future<void> start() async {
    await root.replaceQueue([playbackFixtureEntry()]);
    await root.play();
    engine.calls.clear();
  }

  test('default projection borrows root without timer or audio work', () {
    expect(presenter.sleepState, same(root.sleepTimer));
    expect(presenter.selectedSleepChoice, PlaybackSleepChoice.off);
    expect(presenter.canSetSleepTimer, isTrue);
    expect(presenter.canSleepAtCurrentEntryEnd, isFalse);
    expect(engine.calls, isEmpty);
  });

  for (final pair in [
    (PlaybackSleepChoice.fifteen, PlaybackSleepDuration.fifteen),
    (PlaybackSleepChoice.thirty, PlaybackSleepDuration.thirty),
    (PlaybackSleepChoice.sixty, PlaybackSleepDuration.sixty),
  ]) {
    test('${pair.$1} uses exact selected root duration', () {
      expect(action(pair.$1)(), PlaybackSleepActionResult.accepted);
      expect(presenter.selectedSleepChoice, pair.$1);
      expect(root.sleepTimer.duration, pair.$2);
      expect(presenter.sleepState, same(root.sleepTimer));
      expect(
        action(PlaybackSleepChoice.off)(),
        PlaybackSleepActionResult.accepted,
      );
      expect(root.sleepTimer.duration, isNull);
      expect(presenter.selectedSleepChoice, PlaybackSleepChoice.off);
      expect(engine.calls, isEmpty);
    });
  }

  test(
    'current entry enabled only when root permits, consumed selection clears',
    () async {
      expect(
        presenter.sleepAction(
          PlaybackSleepChoice.currentEntry,
          isCurrent: () => true,
        ),
        isNull,
      );
      await start();
      expect(presenter.canSleepAtCurrentEntryEnd, isTrue);
      expect(
        action(PlaybackSleepChoice.currentEntry)(),
        PlaybackSleepActionResult.accepted,
      );
      expect(presenter.selectedSleepChoice, PlaybackSleepChoice.currentEntry);
      engine.complete();
      expect(presenter.canSleepAtCurrentEntryEnd, isFalse);
      expect(presenter.selectedSleepChoice, isNull);
      expect(root.sleepTimer.phase, PlaybackSleepPhase.expired);
    },
  );

  test('loading does not expose current-entry action', () async {
    await root.replaceQueue([playbackFixtureEntry()]);
    final gate = Completer<void>();
    engine.loadGate = gate.future;
    final playing = root.play();
    await Future<void>.delayed(Duration.zero);
    expect(presenter.canSleepAtCurrentEntryEnd, isFalse);
    gate.complete();
    await playing;
    expect(presenter.canSleepAtCurrentEntryEnd, isTrue);
  });

  test('changed playback snapshot revokes old action', () async {
    await start();
    final old = action(PlaybackSleepChoice.currentEntry);
    await root.pause();
    expect(old(), PlaybackSleepActionResult.rejected);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(
      action(PlaybackSleepChoice.currentEntry)(),
      PlaybackSleepActionResult.accepted,
    );
  });

  test('same playback object but changed sleep intent revokes old action', () {
    final old = action(PlaybackSleepChoice.off);
    final playback = root.state;
    root.setSleepTimer(PlaybackSleepDuration.sixty);
    expect(root.state, same(playback));
    expect(old(), PlaybackSleepActionResult.rejected);
    expect(root.sleepTimer.duration, PlaybackSleepDuration.sixty);
  });

  test('one-shot action cannot reapply after success', () {
    final apply = action(PlaybackSleepChoice.fifteen);
    expect(apply(), PlaybackSleepActionResult.accepted);
    final sleep = root.sleepTimer;
    expect(apply(), PlaybackSleepActionResult.rejected);
    expect(root.sleepTimer, same(sleep));
  });

  test(
    'off-to-off notification revokes sibling action despite same snapshots',
    () {
      final old = action(PlaybackSleepChoice.fifteen);
      final sleep = root.sleepTimer;
      final playback = root.state;
      expect(
        action(PlaybackSleepChoice.off)(),
        PlaybackSleepActionResult.accepted,
      );
      expect(root.sleepTimer, same(sleep));
      expect(root.state, same(playback));
      expect(old(), PlaybackSleepActionResult.rejected);
    },
  );

  test('false UI permit rejects and consumes action', () {
    var current = false;
    final apply = presenter.sleepAction(
      PlaybackSleepChoice.fifteen,
      isCurrent: () => current,
    )!;
    expect(apply(), PlaybackSleepActionResult.rejected);
    current = true;
    expect(apply(), PlaybackSleepActionResult.rejected);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
  });

  test('throwing UI permit is a safe rejection', () {
    final apply = presenter.sleepAction(
      PlaybackSleepChoice.fifteen,
      isCurrent: () => throw StateError('private-route-detail'),
    )!;
    expect(apply(), PlaybackSleepActionResult.rejected);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
  });

  test('UI permit changing root intent is rechecked', () {
    final apply = presenter.sleepAction(
      PlaybackSleepChoice.fifteen,
      isCurrent: () {
        root.setSleepTimer(PlaybackSleepDuration.sixty);
        return true;
      },
    )!;
    expect(apply(), PlaybackSleepActionResult.rejected);
    expect(root.sleepTimer.duration, PlaybackSleepDuration.sixty);
  });

  test('recursive UI permit cannot execute action twice', () {
    late PlaybackSleepAction apply;
    apply = presenter.sleepAction(
      PlaybackSleepChoice.thirty,
      isCurrent: () {
        expect(apply(), PlaybackSleepActionResult.rejected);
        return true;
      },
    )!;
    expect(apply(), PlaybackSleepActionResult.accepted);
    expect(root.sleepTimer.duration, PlaybackSleepDuration.thirty);
  });

  test('root notification cannot replay accepted action', () {
    final apply = action(PlaybackSleepChoice.fifteen);
    root.addListener(() => expect(apply(), PlaybackSleepActionResult.rejected));
    expect(apply(), PlaybackSleepActionResult.accepted);
  });

  test('presenter disposal revokes old action and factories', () {
    final old = action(PlaybackSleepChoice.fifteen);
    presenter.dispose();
    expect(old(), PlaybackSleepActionResult.rejected);
    expect(
      presenter.sleepAction(PlaybackSleepChoice.off, isCurrent: () => true),
      isNull,
    );
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
    expect(engine.disposalCount, 0);
  });

  test('permit disposing presenter is rechecked', () {
    final apply = presenter.sleepAction(
      PlaybackSleepChoice.fifteen,
      isCurrent: () {
        presenter.dispose();
        return true;
      },
    )!;
    expect(apply(), PlaybackSleepActionResult.rejected);
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
  });

  test('closed root cannot be modified by retained or fresh action', () async {
    final old = action(PlaybackSleepChoice.fifteen);
    await root.close();
    expect(old(), PlaybackSleepActionResult.rejected);
    expect(presenter.canSetSleepTimer, isFalse);
    expect(
      presenter.sleepAction(PlaybackSleepChoice.fifteen, isCurrent: () => true),
      isNull,
    );
    expect(root.sleepTimer.phase, PlaybackSleepPhase.off);
  });

  test('unavailable engine permits off but not activation', () async {
    final unavailable = PlaybackController(UnavailableAudioEngine());
    final view = PlaybackPresenter(unavailable);
    try {
      expect(view.canSetSleepTimer, isFalse);
      for (final choice in PlaybackSleepChoice.values) {
        final apply = view.sleepAction(choice, isCurrent: () => true);
        if (choice == PlaybackSleepChoice.off) {
          expect(apply!(), PlaybackSleepActionResult.accepted);
        } else {
          expect(apply, isNull);
        }
      }
    } finally {
      view.dispose();
      await unavailable.close();
    }
  });

  test(
    'scheduler failure produces safe failed result and no selected card',
    () async {
      final failedRoot = PlaybackController(
        engine,
        sleepScheduler: (_, _) => throw StateError('private-scheduler-detail'),
      );
      final view = PlaybackPresenter(failedRoot);
      try {
        final apply = view.sleepAction(
          PlaybackSleepChoice.fifteen,
          isCurrent: () => true,
        )!;
        expect(apply(), PlaybackSleepActionResult.failed);
        expect(view.sleepState.phase, PlaybackSleepPhase.failed);
        expect(view.selectedSleepChoice, isNull);
        expect(apply(), PlaybackSleepActionResult.rejected);
      } finally {
        view.dispose();
        await failedRoot.close();
      }
    },
  );
}
