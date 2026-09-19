import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/root_native_repeat_metrics.dart';
import '../../integration_test/support/root_native_repeat_result.dart';
import '../../integration_test/support/windows_root_repeat_result.dart';

const _commit = '4380386c5c229d1e82ea48e5fbdc1f6cf0d53483';
Map<String, Object?> _metrics() => {
  'sourceCommit': _commit,
  'platform': 'windows',
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
};

Map<String, Object> _result(
  Object? metrics, {
  bool passed = true,
  int count = 1,
}) => windowsRootRepeatResult(
  sourceCommit: _commit,
  nativeCommit: _commit,
  testsPassed: passed,
  testCount: count,
  metrics: metrics,
);

void main() {
  test('Windows result has separate identity and fresh safe metrics', () {
    final metrics = {..._metrics(), 'private': 'must-not-be-exposed'};
    final result = _result(metrics);
    expect(result['passed'], isTrue);
    expect(result['nativeCommit'], _commit);
    expect(result['purpose'], 'isolated-windows-root-repeat-test');
    expect(result['diagnosticId'], 'windows-root-repeat.passed');
    expect(jsonEncode(result), isNot(contains('must-not-be-exposed')));
    final projected = result['metrics']! as Map<String, Object>;
    (metrics['rootProgressMs']! as List<int>)[0] = 999;
    expect(projected['rootProgressMs'], [105, 215, 305]);
    expect(projected['acousticGapMeasured'], isFalse);
  });

  test('Windows cannot pass absent failed skipped or extra test outcomes', () {
    for (final result in [
      _result(null),
      _result([]),
      _result(_metrics(), passed: false),
      _result(_metrics(), count: 0),
      _result(_metrics(), count: 2),
    ]) {
      expect(result['passed'], isFalse);
      expect(result.containsKey('metrics'), isFalse);
    }
  });

  test('every Windows native root fact is required', () {
    for (final key in _metrics().keys) {
      expect(_result(_metrics()..remove(key))['passed'], isFalse, reason: key);
    }
  });

  test('Windows rejects wrong clocks history identities and lifecycle', () {
    for (final change in <Map<String, Object?>>[
      {'sourceCommit': '0' * 40},
      {'platform': 'android'},
      {
        'nativeEntries': ['q0', 'q0', 'q1'],
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
        'nativeProgressMs': [99, 200, 300],
      },
      {
        'rootProgressMs': [100, 200, 10001],
      },
      {
        'rootProgressMs': [100, '200', 300],
      },
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
      expect(_result({..._metrics(), ...change})['passed'], isFalse);
    }
  });

  test('source and native must be the same full lowercase commit', () {
    for (final bad in ['', '4380386', '../private', _commit.toUpperCase()]) {
      expect(
        () => windowsRootRepeatResult(
          sourceCommit: bad,
          nativeCommit: bad,
          testsPassed: true,
          testCount: 1,
          metrics: _metrics(),
        ),
        throwsArgumentError,
      );
    }
    expect(
      () => windowsRootRepeatResult(
        sourceCommit: _commit,
        nativeCommit: '0' * 40,
        testsPassed: true,
        testCount: 1,
        metrics: _metrics(),
      ),
      throwsArgumentError,
    );
  });

  test('shared projection does not broaden the Android result contract', () {
    expect(
      rootNativeRepeatResult(
        sourceCommit: _commit,
        testsPassed: true,
        testCount: 1,
        metrics: _metrics(),
      )['passed'],
      isFalse,
    );
    final android = {..._metrics(), 'platform': 'android'};
    expect(_result(android)['passed'], isFalse);
    expect(
      projectRootNativeRepeatMetrics(
        sourceCommit: _commit,
        platform: RootRepeatPlatform.android,
        metrics: android,
      ),
      isNotNull,
    );
  });
}
