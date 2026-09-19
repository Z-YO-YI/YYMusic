import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/playback/just_audio_backend.dart';

import '../../integration_test/support/native_sequence_prune_trace.dart';

void main() {
  const commit = '1234567890123456789012345678901234567890';
  JustAudioPlayerSnapshot sample({int? index = 2, int ms = 100}) =>
      JustAudioPlayerSnapshot(
        currentIndex: index,
        position: Duration(milliseconds: ms),
        processing: JustAudioProcessingPhase.ready,
        playing: true,
      );

  test('trace projects only raw facts, not engine success or media data', () {
    final trace = NativeSequencePruneTrace();
    trace.record(
      NativeSequencePruneStage.before,
      sample(),
      elapsed: Duration.zero,
    );
    trace.record(
      NativeSequencePruneStage.failed,
      sample(ms: 1200),
      elapsed: const Duration(milliseconds: 1100),
    );
    expect(jsonDecode(jsonEncode(trace.toJson(sourceCommit: commit))), {
      'schemaVersion': 1,
      'sourceCommit': commit,
      'purpose': 'native-sequence-prefix-trace',
      'droppedSamples': 0,
      'samples': [
        {
          'stage': 'before',
          'elapsedMs': 0,
          'rawIndex': 2,
          'processing': 'ready',
          'playing': true,
          'positionMs': 100,
        },
        {
          'stage': 'failed',
          'elapsedMs': 1100,
          'rawIndex': 2,
          'processing': 'ready',
          'playing': true,
          'positionMs': 1200,
        },
      ],
    });
  });

  test(
    'trace preserves missing, negative, increasing and rebased raw indices',
    () {
      final trace = NativeSequencePruneTrace();
      for (final index in <int?>[2, null, -1, 3, 0, 2]) {
        trace.record(
          NativeSequencePruneStage.snapshot,
          sample(index: index),
          elapsed: Duration.zero,
        );
      }
      final samples = trace.toJson(sourceCommit: commit)['samples']! as List;
      expect(samples.map((Object? item) => (item! as Map)['rawIndex']), [
        2,
        null,
        -1,
        3,
        0,
        2,
      ]);
    },
  );

  test('coalesces position buckets but never drops stage or state changes', () {
    final trace = NativeSequencePruneTrace();
    for (final ms in [100, 101, 199, 200]) {
      trace.record(
        NativeSequencePruneStage.snapshot,
        sample(ms: ms),
        elapsed: Duration(milliseconds: ms),
      );
    }
    trace.record(
      NativeSequencePruneStage.snapshot,
      const JustAudioPlayerSnapshot(currentIndex: 2),
      elapsed: Duration.zero,
    );
    trace.record(
      NativeSequencePruneStage.failed,
      const JustAudioPlayerSnapshot(currentIndex: 2),
      elapsed: Duration.zero,
    );
    final samples = trace.toJson(sourceCommit: commit)['samples']! as List;
    expect(samples, hasLength(4));
  });

  test(
    'long traces retain the initial and terminal facts within a fixed bound',
    () {
      final trace = NativeSequencePruneTrace();
      trace.record(
        NativeSequencePruneStage.before,
        sample(),
        elapsed: Duration.zero,
      );
      for (var i = 1; i <= 100; i++) {
        trace.record(
          NativeSequencePruneStage.snapshot,
          sample(ms: i * 100),
          elapsed: Duration(milliseconds: i * 100),
        );
      }
      trace.record(
        NativeSequencePruneStage.failed,
        sample(index: 0),
        elapsed: const Duration(seconds: 11),
      );
      final result = trace.toJson(sourceCommit: commit);
      final samples = result['samples']! as List;
      expect(samples, hasLength(NativeSequencePruneTrace.maxSamples));
      expect((samples.first as Map)['stage'], 'before');
      expect((samples.last as Map)['stage'], 'failed');
      expect(result['droppedSamples'], 69);
    },
  );

  test('snapshots are immutable and do not grow after serialization', () {
    final trace = NativeSequencePruneTrace();
    trace.record(
      NativeSequencePruneStage.before,
      sample(),
      elapsed: Duration.zero,
    );
    final result = trace.toJson(sourceCommit: commit);
    final samples = result['samples']! as List;
    trace.record(
      NativeSequencePruneStage.accepted,
      sample(index: 0),
      elapsed: Duration.zero,
    );
    expect(samples, hasLength(1));
    expect(() => result['passed'] = true, throwsUnsupportedError);
    expect(() => samples.clear(), throwsUnsupportedError);
    expect(
      () => (samples.single as Map)['rawIndex'] = 0,
      throwsUnsupportedError,
    );
  });

  test('invalid identities are rejected without echoing their contents', () {
    for (final value in ['', 'old-sha', 'https://private.invalid/secret']) {
      expect(
        () => NativeSequencePruneTrace().toJson(sourceCommit: value),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'safe message',
            'Invalid diagnostic identity',
          ),
        ),
      );
    }
  });
}
