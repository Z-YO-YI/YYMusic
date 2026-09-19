import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/root_native_shuffle_result.dart';

void main() {
  test(
    'fixed seed distinguishes shuffle tail from the sequential successor',
    () {
      final random = Random(42);
      expect([random.nextInt(2), random.nextInt(2)], [1, 0]);
    },
  );

  const commit = '7b28a166bb5a308d2a806a5ccde88f665487cef5';
  final metrics = <String, Object?>{
    'sourceCommit': commit,
    'platform': 'android',
    'randomSeed': 42,
    'randomPrefix': [1, 0],
    'randomCallsAtChange': 3,
    'nativeEntries': ['q0', 'q1', 'q2', 'q1'],
    'nativeIndices': [0, 1, 2, 3],
    'nativeCycles': [0, 0, 0, 1],
    'rootEntries': ['q0', 'q1', 'q2', 'q1', 'q2'],
    'persistedEntries': ['q0', 'q1', 'q2', 'q1', 'q2'],
    'nativeProgressMs': [110, 120, 130, 140],
    'rootProgressMs': [111, 121, 131, 141, 151],
    'singleProgressMs': 151,
    'boundaryProgressDeltaMs': 110,
    'sameNativeBatch': true,
    'metadataAligned': true,
    'queueUnchanged': true,
    'boundaryCompleted': true,
    'continuedCurrentWithoutReload': true,
    'sequentialFallback': true,
    'shuffleStayedDisabled': true,
    'randomStopped': true,
    'disposed': true,
    'modeChangeIndex': 3,
    'modeChangeEntry': 'q1',
    'expectedRevokedNextEntry': 'q0',
    'sequentialNextEntry': 'q2',
    'completedEntry': 'q2',
    'noRestartObservedMs': 1200,
    'acousticGapMeasured': false,
    'private': 'fixture-path-not-public',
  };
  Map<String, Object> result({
    Object? data,
    int count = 1,
    bool passed = true,
  }) => rootNativeShuffleResult(
    sourceCommit: commit,
    testsPassed: passed,
    testCount: count,
    metrics: data,
  );
  String line(Map<String, Object> record) =>
      'YYMUSIC_ROOT_NATIVE_SHUFFLE_RESULT ${jsonEncode(record)}';

  test(
    'complete shuffle evidence is bounded, copied and strips private data',
    () {
      final record = result(data: metrics);
      expect(record['passed'], true);
      expect(record['purpose'], 'isolated-root-native-shuffle-test');
      expect(jsonEncode(record), isNot(contains('fixture-path')));
      final safe = record['metrics']! as Map<String, Object>;
      (metrics['nativeProgressMs']! as List<int>)[0] = 999;
      expect(safe['nativeProgressMs'], [110, 120, 130, 140]);
      (metrics['nativeProgressMs']! as List<int>)[0] = 110;
      expect(
        parseRootNativeShuffleLog('I/flutter: ${line(record)}\n', commit),
        record,
      );
    },
  );
  test('missing, skipped, failed or extra tests cannot pass', () {
    for (final record in [
      result(),
      result(data: []),
      result(data: metrics, count: 0),
      result(data: metrics, count: 2),
      result(data: metrics, passed: false),
    ]) {
      expect(record['passed'], false);
      expect(record.containsKey('metrics'), false);
    }
  });
  test('every evidence field is required', () {
    for (final key in metrics.keys.where((k) => k != 'private')) {
      expect(
        result(data: {...metrics}..remove(key))['passed'],
        false,
        reason: key,
      );
    }
  });
  test(
    'wrong ordering, mode, clock and false lifecycle facts are rejected',
    () {
      for (final change in <Map<String, Object?>>[
        {'sourceCommit': '0' * 40},
        {'platform': 'windows'},
        {'randomSeed': 42.0},
        {
          'randomPrefix': [0, 1],
        },
        {'randomCallsAtChange': 1},
        {'randomCallsAtChange': 5},
        {
          'nativeEntries': ['q0', 'q1', 'q2', 'q0'],
        },
        {
          'nativeIndices': [0, 1, 2, 3.0],
        },
        {
          'nativeCycles': [0, 0, 1, 1],
        },
        {
          'rootEntries': ['q0', 'q1', 'q2', 'q1', 'q0'],
        },
        {
          'persistedEntries': ['q0', 'q1', 'q2', 'q1'],
        },
        {
          'nativeProgressMs': [0, 120, 130, 140],
        },
        {
          'rootProgressMs': [1, 2, 3, 4, 5],
        },
        {'singleProgressMs': 10001},
        {'boundaryProgressDeltaMs': 99},
        {'modeChangeIndex': 2},
        {'modeChangeEntry': 'q2'},
        {'expectedRevokedNextEntry': 'q2'},
        {'sequentialNextEntry': 'q0'},
        {'completedEntry': 'q1'},
        {'noRestartObservedMs': 999},
        {'acousticGapMeasured': true},
        for (final key in [
          'sameNativeBatch',
          'metadataAligned',
          'queueUnchanged',
          'boundaryCompleted',
          'continuedCurrentWithoutReload',
          'sequentialFallback',
          'shuffleStayedDisabled',
          'randomStopped',
          'disposed',
        ])
          {key: false},
      ]) {
        expect(
          result(data: {...metrics, ...change})['passed'],
          false,
          reason: change.toString(),
        );
      }
    },
  );
  test('source must be a complete lowercase SHA', () {
    for (final bad in ['', '7b28a16', commit.toUpperCase(), '../private']) {
      expect(
        () => rootNativeShuffleResult(
          sourceCommit: bad,
          testsPassed: true,
          testCount: 1,
          metrics: metrics,
        ),
        throwsArgumentError,
      );
    }
  });
  test('host rejects foreign, duplicate, failed or noncanonical reports', () {
    final record = result(data: metrics), valid = line(result(data: metrics));
    for (final log in [
      'All tests passed!',
      '$valid\n$valid',
      'YYMUSIC_ROOT_NATIVE_SHUFFLE_RESULT {invalid}',
      line(result(data: metrics, passed: false)),
      line({...record, 'sourceCommit': '0' * 40}),
      line({...record, 'platform': 'windows'}),
      line({...record, 'purpose': 'isolated-root-native-repeat-test'}),
      line({...record, 'schemaVersion': 2}),
      line({...record, 'testCount': 1.0}),
      line({...record, 'diagnosticId': 'root-shuffle.failed'}),
      line({...record, 'private': 'sensitive'}),
      'x' * (4 * 1024 * 1024 + 1),
    ]) {
      expect(
        () => parseRootNativeShuffleLog(log, commit),
        throwsFormatException,
      );
    }
    expect(
      () => parseRootNativeShuffleLog(valid, '0' * 40),
      throwsFormatException,
    );
  });
}
