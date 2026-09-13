import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/playback/audio_engine.dart';
import 'package:yymusic/playback/playback_continuation_restore.dart';
import 'package:yymusic/playback/playback_controller.dart';
import 'package:yymusic/playback/playback_state.dart';

import '../support/fake_audio_engine.dart';
import '../support/fake_domain_repositories.dart';
import '../support/fake_playback_dependencies.dart';

void main() {
  late FakeAudioEngine engine;
  late FakeLibraryRepository library;
  late PlaybackController player;
  setUp(() {
    engine = FakeAudioEngine();
    library = FakeLibraryRepository(tracks: [playbackFixtureTrack]);
    player = PlaybackController(
      engine,
      library: library,
      sourceResolver: FakePlaybackSourceResolver(),
    );
  });
  tearDown(() async {
    await player.close();
    await engine.dispose();
    await library.dispose();
  });

  for (final enabled in [false, true]) {
    test('restores $enabled exactly once without audio commands', () {
      final restore = player.captureContinuationRestore()!;
      expect(restore.isCurrent, isTrue);
      expect(restore.isCurrent, isTrue);
      expect(restore(enabled), PlaybackContinuationRestoreResult.restored);
      expect(player.continueAfterTrack, enabled);
      expect(restore.isCurrent, isFalse);
      expect(restore(!enabled), PlaybackContinuationRestoreResult.superseded);
      expect(engine.calls, isEmpty);
    });
  }

  test('one root issues only one startup restore permit', () {
    expect(player.captureContinuationRestore(), isNotNull);
    expect(player.captureContinuationRestore(), isNull);
  });

  test('explicit unchanged default defeats a pending false restore', () {
    final restore = player.captureContinuationRestore()!;
    var notifications = 0;
    player.addListener(() => notifications++);
    player.setContinueAfterTrack(true);
    expect(notifications, 0);
    expect(restore.isCurrent, isFalse);
    expect(restore(false), PlaybackContinuationRestoreResult.superseded);
    expect(player.continueAfterTrack, isTrue);
  });

  test('explicit change and reversion do not revive a restore', () {
    final restore = player.captureContinuationRestore()!;
    player.setContinueAfterTrack(false);
    player.setContinueAfterTrack(true);
    expect(restore(false), PlaybackContinuationRestoreResult.superseded);
    expect(engine.calls, isEmpty);
  });

  test('choice made before capture cannot be overridden by startup', () {
    player.setContinueAfterTrack(true);
    expect(player.captureContinuationRestore(), isNull);
  });

  test('closed root revokes pending permits and rejects new ones', () async {
    final restore = player.captureContinuationRestore()!;
    await player.close();
    expect(restore.isCurrent, isFalse);
    expect(restore(false), PlaybackContinuationRestoreResult.superseded);
    expect(player.captureContinuationRestore(), isNull);
  });

  test('listener explicit choice wins during restoration notification', () {
    final restore = player.captureContinuationRestore()!;
    player.addListener(() {
      if (!player.continueAfterTrack) player.setContinueAfterTrack(true);
    });
    expect(restore(false), PlaybackContinuationRestoreResult.superseded);
    expect(player.continueAfterTrack, isTrue);
    expect(engine.calls, isEmpty);
  });

  test(
    'listener close during restoration safely supersedes the result',
    () async {
      final restore = player.captureContinuationRestore()!;
      player.addListener(player.dispose);
      expect(restore(false), PlaybackContinuationRestoreResult.superseded);
      await player.close();
      expect(restore.isCurrent, isFalse);
    },
  );

  test('restoration never replays an already completed track', () async {
    final restore = player.captureContinuationRestore()!;
    await player.replaceQueue([playbackFixtureEntry()]);
    await player.play();
    engine.complete();
    await Future<void>.delayed(Duration.zero);
    engine.calls.clear();
    expect(restore(true), PlaybackContinuationRestoreResult.restored);
    await Future<void>.delayed(Duration.zero);
    expect(player.state.phase, PlaybackPhase.completed);
    expect(engine.calls, isEmpty);
  });

  test(
    'restoration of a preference does not require an available audio engine',
    () async {
      final unavailable = PlaybackController(UnavailableAudioEngine());
      expect(
        unavailable.captureContinuationRestore()!(false),
        PlaybackContinuationRestoreResult.restored,
      );
      expect(unavailable.continueAfterTrack, isFalse);
      await unavailable.close();
    },
  );
}
