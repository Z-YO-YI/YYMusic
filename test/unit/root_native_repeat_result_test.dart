import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/root_native_repeat_result.dart';

void main() {
  const commit = 'c8dc13e34cdc776e1644cb0e936b94fb07d8f23b';
  final metrics = <String, Object?>{
    'sourceCommit': commit,
    'platform': 'android',
    'nativeEntries': ['q0', 'q1', 'q0'],
    'nativeIndices': [0, 1, 2],
    'nativeCycles': [0, 0, 1],
    'rootEntries': ['q0', 'q1', 'q0'],
    'persistedEntries': ['q0', 'q1', 'q0'],
    'nativeProgressMs': [101, 210, 300],
    'rootProgressMs': [105, 215, 305],
    'sameNativeBatch': true,
    'metadataAligned': true,
    'historyCount': 2,
    'historyReplaced': true,
    'completedEntry': 'q0',
    'completedIndex': 2,
    'completedCycle': 1,
    'noRestartObservedMs': 1200,
    'restoreObservedMs': 1200,
    'restoredEntry': 'q0',
    'restoredWithoutPlayback': true,
    'disposed': true,
    'acousticGapMeasured': false,
    'private': 'private-path-and-credential',
  };
  Map<String, Object> result({
    Object? evidence,
    int count = 1,
    bool passed = true,
  }) => rootNativeRepeatResult(
    sourceCommit: commit,
    testsPassed: passed,
    testCount: count,
    metrics: evidence,
  );
  String report(Map<String, Object?> record) =>
      'YYMUSIC_ROOT_NATIVE_REPEAT_RESULT ${jsonEncode(record)}';

  test('one complete native root test projects bounded safe evidence', () {
    final record = result(evidence: metrics);
    expect(record['passed'], isTrue);
    expect(record['diagnosticId'], 'root-repeat.passed');
    expect(jsonEncode(record), isNot(contains('private-path')));
    final evidence = record['metrics']! as Map<String, Object>;
    expect(evidence['nativeProgressMs'], [101, 210, 300]);
    expect(evidence['rootProgressMs'], [105, 215, 305]);
    expect(evidence['acousticGapMeasured'], isFalse);
    (metrics['nativeProgressMs']! as List<int>)[0] = 110;
    expect(evidence['nativeProgressMs'], [101, 210, 300]);
    (metrics['nativeProgressMs']! as List<int>)[0] = 101;
  });

  test('missing, skipped, failed and extra tests cannot pass', () {
    for (final record in [
      result(),
      result(evidence: []),
      result(evidence: metrics, count: 0),
      result(evidence: metrics, count: 2),
      result(evidence: metrics, passed: false),
    ]) {
      expect(record['passed'], isFalse);
      expect(record.containsKey('metrics'), isFalse);
    }
  });

  test('every required metric fails closed when absent', () {
    for (final key in metrics.keys.where((k) => k != 'private')) {
      expect(
        result(evidence: {...metrics}..remove(key))['passed'],
        isFalse,
        reason: key,
      );
    }
  });

  test('wrong order, identity, types, clock and lifecycle are rejected', () {
    for (final change in <Map<String, Object?>>[
      {'sourceCommit': '0' * 40},
      {'platform': 'windows'},
      {
        'nativeEntries': ['q0', 'q0', 'q1'],
      },
      {
        'nativeIndices': [0, 1, 1],
      },
      {
        'nativeIndices': [0, 1, 2.0],
      },
      {
        'nativeCycles': [0, 1, 2],
      },
      {
        'rootEntries': ['q0', 'q1'],
      },
      {
        'persistedEntries': ['q0', 'q1', 'q1'],
      },
      {
        'nativeProgressMs': [0, 200, 300],
      },
      {
        'rootProgressMs': [100, 200, 10001],
      },
      {
        'rootProgressMs': [100, '200', 300],
      },
      {
        'rootProgressMs': [100, double.nan, 300],
      },
      {'historyCount': 3},
      {'historyCount': 2.0},
      {'historyReplaced': false},
      {'sameNativeBatch': false},
      {'metadataAligned': false},
      {'completedEntry': 'q1'},
      {'completedIndex': 1},
      {'completedCycle': 1.0},
      {'noRestartObservedMs': 999},
      {'restoreObservedMs': 10001},
      {'restoredEntry': 'q1'},
      {'restoredWithoutPlayback': false},
      {'disposed': 'true'},
      {'acousticGapMeasured': true},
    ]) {
      expect(result(evidence: {...metrics, ...change})['passed'], isFalse);
    }
  });

  test('source identity must be a full lowercase commit', () {
    for (final bad in ['', 'c8dc13e', '../private', commit.toUpperCase()]) {
      expect(
        () => rootNativeRepeatResult(
          sourceCommit: bad,
          testsPassed: true,
          testCount: 1,
          metrics: metrics,
        ),
        throwsArgumentError,
      );
    }
  });

  test('host gate requires a unique successful final report for exact SHA', () {
    final record = result(evidence: metrics);
    final line = report(record);
    expect(parseRootNativeRepeatLog('log\nI/flutter: $line\n', commit), record);
    for (final log in [
      'All tests passed!',
      '$line\n$line',
      'YYMUSIC_ROOT_NATIVE_REPEAT_RESULT {invalid-json}',
      report(result(evidence: metrics, passed: false)),
      report({...record, 'sourceCommit': '0' * 40}),
      report({...record, 'platform': 'windows'}),
      report({...record, 'schemaVersion': 2}),
      report({...record, 'purpose': 'other'}),
      report({...record, 'diagnosticId': 'root-repeat.failed'}),
      report({...record, 'testCount': 1.0}),
      report({...record, 'private': 'sensitive'}),
      'x' * (4 * 1024 * 1024 + 1),
    ]) {
      expect(
        () => parseRootNativeRepeatLog(log, commit),
        throwsFormatException,
      );
    }
    expect(
      () => parseRootNativeRepeatLog(line, '0' * 40),
      throwsFormatException,
    );
  });
}
