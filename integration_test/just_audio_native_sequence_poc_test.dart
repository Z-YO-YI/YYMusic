import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yymusic/domain/models/track.dart';
import 'package:yymusic/playback/audio_engine_state.dart';
import 'package:yymusic/playback/audio_sequence.dart';
import 'package:yymusic/playback/just_audio_engine.dart';
import 'package:yymusic/playback/playable_source.dart';

import 'support/deterministic_pcm_wav.dart';

/// Explicit device test; never called from the production app or old probes.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native repeat sequence preserves identity through edits', (
    _,
  ) async {
    const commit = String.fromEnvironment('YYMUSIC_SEQUENCE_SOURCE_COMMIT');
    expect(RegExp(r'^[0-9a-f]{40}$').hasMatch(commit), isTrue);
    expect(Platform.isAndroid || Platform.isWindows, isTrue);
    final directory = await Directory.systemTemp.createTemp('yy-sequence-poc-');
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final file = File('${directory.path}${Platform.pathSeparator}tone.wav');
    await file.writeAsBytes(
      buildDeterministicPcmWav(duration: const Duration(seconds: 10)),
      flush: true,
    );
    final engine = JustAudioEngine.create(
      useProxyForRequestHeaders: false,
      supportsRequestHeaders: false,
    );
    addTearDown(engine.dispose);
    AudioEngineState? latest;
    var hadError = false;
    var hadPlaying = false;
    final indices = <int>{};
    final cycles = <int>{};
    final subscription = engine.states.listen((state) {
      latest = state;
      hadError |= state.phase == AudioEnginePhase.error;
      hadPlaying |= state.phase == AudioEnginePhase.playing;
      final cursor = state.sequenceCursor;
      if (cursor != null) {
        indices.add(cursor.index);
        cycles.add(cursor.cycle);
      }
    });
    addTearDown(subscription.cancel);

    Future<AudioEngineState> waitFor(
      bool Function(AudioEngineState) predicate,
    ) async {
      bool accepted(AudioEngineState state) =>
          state.phase == AudioEnginePhase.error || predicate(state);
      final current = latest;
      final state = current != null && accepted(current)
          ? current
          : await engine.states
                .firstWhere(accepted)
                .timeout(const Duration(seconds: 25));
      expect(state.phase, isNot(AudioEnginePhase.error));
      expect(predicate(state), isTrue);
      return state;
    }

    final source = PlayableSource.localFile(
      track: TrackRef(
        trackId: 'sequence-tone',
        sourceId: 'native-sequence-poc',
        sourceType: MusicSourceType.local,
      ),
      path: file.path,
    );
    final batch = AudioSequence([
      for (var cycle = 0; cycle < 2; cycle++)
        AudioSequenceEntry(entryId: 'same', source: source, cycle: cycle),
    ]);
    await engine.loadSequence(batch).timeout(const Duration(seconds: 20));
    expect(latest!.phase, AudioEnginePhase.ready);
    expect(hadPlaying, isFalse);
    expect(latest!.sequenceCursor!.cycle, 0);
    await engine.setVolume(0.05).timeout(const Duration(seconds: 10));
    await engine.play().timeout(const Duration(seconds: 10));
    await waitFor(
      (state) =>
          state.phase == AudioEnginePhase.playing &&
          state.sequenceCursor?.index == 0 &&
          state.position >= const Duration(milliseconds: 100),
    );
    expect(
      await engine
          .appendSequence(
            AudioSequenceAppend(
              expectedTail: batch.cursors.last,
              entries: [
                for (var cycle = 2; cycle < 4; cycle++)
                  AudioSequenceEntry(
                    entryId: 'same',
                    source: source,
                    cycle: cycle,
                  ),
              ],
            ),
          )
          .timeout(const Duration(seconds: 10)),
      isTrue,
    );
    final second = await waitFor(
      (state) =>
          state.phase == AudioEnginePhase.playing &&
          state.sequenceCursor?.index == 1 &&
          state.position >= const Duration(milliseconds: 100),
    );
    expect(second.sequenceCursor!.cycle, 1);
    final appended = await waitFor(
      (state) =>
          state.phase == AudioEnginePhase.playing &&
          state.sequenceCursor?.index == 2 &&
          state.position >= const Duration(milliseconds: 100),
    );
    final cursor = appended.sequenceCursor!;
    expect(cursor.sequenceIdentity, same(batch.identity));
    expect(cursor.entryId, 'same');
    expect(cursor.cycle, 2);
    expect(
      await engine
          .pruneSequenceBefore(cursor)
          .timeout(const Duration(seconds: 10)),
      isTrue,
    );
    expect(latest!.sequenceCursor!.index, 2);
    expect(latest!.sequenceCursor!.cycle, 2);
    expect(latest!.phase, AudioEnginePhase.playing);
    expect(
      await engine
          .retainSequenceThrough(cursor)
          .timeout(const Duration(seconds: 10)),
      isTrue,
    );
    final completed = await waitFor(
      (state) => state.phase == AudioEnginePhase.completed,
    );
    expect(completed.sequenceCursor!.index, 2);
    expect(indices, {0, 1, 2});
    expect(cycles, {0, 1, 2});
    expect(hadError, isFalse);
    await engine.stop().timeout(const Duration(seconds: 10));
    expect(latest!.phase, AudioEnginePhase.idle);
    await engine.dispose().timeout(const Duration(seconds: 10));
    final metrics = <String, Object>{
      'sourceCommit': commit,
      'platform': Platform.operatingSystem,
      'observedIndices': indices.toList()..sort(),
      'observedCycles': cycles.toList()..sort(),
      'appendAccepted': true,
      'pruneAccepted': true,
      'retainAccepted': true,
      'completedAtIndex': 2,
      'disposed': true,
      'acousticGapMeasured': false,
    };
    binding.reportData = {'nativeSequence': metrics};
    debugPrint('YYMUSIC_NATIVE_SEQUENCE_POC ${jsonEncode(metrics)}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
