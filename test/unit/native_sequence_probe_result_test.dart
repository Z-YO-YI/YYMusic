import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/native_sequence_probe_result.dart';

void main() {
  const commit = 'bd0c37460a0b1372a99317ef4f8d25c04ec4a881';
  final metrics = <String, Object?>{
    'sourceCommit': commit,
    'platform': 'windows',
    'observedIndices': [0, 1, 2],
    'observedCycles': [0, 1, 2],
    'progressMs': [100, 200, 300],
    'appendAccepted': true,
    'pruneAccepted': true,
    'retainAccepted': true,
    'completedAtIndex': 2,
    'disposed': true,
    'acousticGapMeasured': false,
    'private': 'do-not-persist-path-or-token',
  };
  Map<String, Object> result({
    Object? evidence,
    int count = 1,
    bool passed = true,
    String diagnostic = 'sequence-poc.failed',
  }) => nativeSequenceProbeResult(
    sourceCommit: commit,
    nativeCommit: commit,
    testsPassed: passed,
    testCount: count,
    metrics: evidence,
    diagnosticId: diagnostic,
  );

  test('sequence result requires one test and projects only safe evidence', () {
    final record = result(evidence: metrics);
    expect(record['passed'], isTrue);
    expect(record['diagnosticId'], 'sequence-poc.passed');
    expect(record['purpose'], 'isolated-native-sequence-test');
    expect(jsonEncode(record), isNot(contains('do-not-persist')));
    final projected = record['sequenceMetrics']! as Map<String, Object>;
    expect(projected['progressMs'], [100, 200, 300]);
    expect(projected['acousticGapMeasured'], isFalse);
  });

  test(
    'missing, skipped, failed and multiple tests never count as success',
    () {
      for (final record in [
        result(),
        result(evidence: []),
        result(evidence: metrics, count: 0),
        result(evidence: metrics, count: 2),
        result(evidence: metrics, passed: false),
      ]) {
        expect(record['passed'], isFalse);
        expect(record.containsKey('sequenceMetrics'), isFalse);
      }
    },
  );

  test('every required native metric must be present', () {
    for (final key in metrics.keys.where((key) => key != 'private')) {
      expect(
        result(evidence: {...metrics}..remove(key))['passed'],
        isFalse,
        reason: key,
      );
    }
  });

  test('identity, order, types, clock bounds and lifecycle fail closed', () {
    for (final change in <Map<String, Object?>>[
      {'sourceCommit': '0' * 40},
      {'platform': 'android'},
      {
        'observedIndices': [0, 2, 1],
      },
      {
        'observedIndices': [0, 1, 2, 3],
      },
      {
        'observedIndices': [0.0, 1, 2],
      },
      {
        'observedCycles': [0, 1, 1],
      },
      {'observedCycles': '0,1,2'},
      {
        'progressMs': [99, 200, 300],
      },
      {
        'progressMs': [100, 10001, 300],
      },
      {
        'progressMs': [100, '200', 300],
      },
      {
        'progressMs': [100, double.nan, 300],
      },
      {
        'progressMs': [100, 200],
      },
      {'appendAccepted': 'true'},
      {'pruneAccepted': false},
      {'retainAccepted': false},
      {'completedAtIndex': 2.0},
      {'disposed': false},
      {'acousticGapMeasured': true},
    ]) {
      expect(result(evidence: {...metrics, ...change})['passed'], isFalse);
    }
  });

  test('timeout, runner failures and untrusted diagnostics cannot pass', () {
    for (final diagnostic in [
      'sequence-poc.timeout',
      'sequence-poc.runner-failed',
    ]) {
      expect(
        result(evidence: metrics, diagnostic: diagnostic)['passed'],
        isFalse,
      );
    }
    expect(
      () => result(diagnostic: 'private-plugin-error'),
      throwsArgumentError,
    );
  });

  test('source and native identities must be exact matching commits', () {
    for (final native in ['0' * 40, '../path', commit.toUpperCase()]) {
      expect(
        () => nativeSequenceProbeResult(
          sourceCommit: commit,
          nativeCommit: native,
          testsPassed: true,
          testCount: 1,
          metrics: metrics,
        ),
        throwsArgumentError,
      );
    }
  });
}
