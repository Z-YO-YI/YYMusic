import 'dart:convert';

/// Accepts only complete, bounded evidence from the independent Android test.
Map<String, Object> rootNativeShuffleResult({
  required String sourceCommit,
  required bool testsPassed,
  required int testCount,
  required Object? metrics,
}) {
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(sourceCommit)) {
    throw ArgumentError('Invalid root shuffle probe identity');
  }
  const orders = <String, List<Object>>{
    'randomPrefix': [1, 0],
    'nativeEntries': ['q0', 'q1', 'q2', 'q1'],
    'nativeIndices': [0, 1, 2, 3],
    'nativeCycles': [0, 0, 0, 1],
    'rootEntries': ['q0', 'q1', 'q2', 'q1', 'q2'],
    'persistedEntries': ['q0', 'q1', 'q2', 'q1', 'q2'],
  };
  const facts = [
    'sameNativeBatch',
    'metadataAligned',
    'queueUnchanged',
    'boundaryCompleted',
    'continuedCurrentWithoutReload',
    'sequentialFallback',
    'shuffleStayedDisabled',
    'randomStopped',
    'disposed',
  ];
  const exactInts = {'randomSeed': 42, 'modeChangeIndex': 3};
  const exactStrings = {
    'modeChangeEntry': 'q1',
    'expectedRevokedNextEntry': 'q0',
    'sequentialNextEntry': 'q2',
    'completedEntry': 'q2',
  };
  bool bounded(Object? value, int min, int max) =>
      value is int && value >= min && value <= max;
  bool exactList(Object? value, List<Object> expected) =>
      value is List<Object?> &&
      value.length == expected.length &&
      List.generate(expected.length, (i) => i).every(
        (i) =>
            value[i].runtimeType == expected[i].runtimeType &&
            value[i] == expected[i],
      );
  bool clockList(Object? value, int count) =>
      value is List<Object?> &&
      value.length == count &&
      value.every((v) => bounded(v, 100, 10000));
  final valid =
      metrics is Map<String, Object?> &&
      metrics['sourceCommit'] == sourceCommit &&
      metrics['platform'] == 'android' &&
      orders.entries.every((e) => exactList(metrics[e.key], e.value)) &&
      facts.every((key) => metrics[key] == true) &&
      exactInts.entries.every(
        (e) => bounded(metrics[e.key], e.value, e.value),
      ) &&
      exactStrings.entries.every((e) => metrics[e.key] == e.value) &&
      clockList(metrics['nativeProgressMs'], 4) &&
      clockList(metrics['rootProgressMs'], 5) &&
      bounded(metrics['singleProgressMs'], 100, 10000) &&
      bounded(metrics['boundaryProgressDeltaMs'], 100, 5000) &&
      bounded(metrics['randomCallsAtChange'], 2, 4) &&
      bounded(metrics['noRestartObservedMs'], 1000, 10000) &&
      metrics['acousticGapMeasured'] == false;
  final passed = testsPassed && testCount == 1 && valid;
  return {
    'schemaVersion': 1,
    'sourceCommit': sourceCommit,
    'platform': 'android',
    'purpose': 'isolated-root-native-shuffle-test',
    'passed': passed,
    'testCount': testCount,
    'diagnosticId': passed ? 'root-shuffle.passed' : 'root-shuffle.failed',
    if (passed)
      'metrics': {
        'sourceCommit': sourceCommit,
        'platform': 'android',
        ...exactInts,
        ...exactStrings,
        for (final e in orders.entries) e.key: List<Object>.of(e.value),
        for (final key in facts) key: true,
        for (final key in ['nativeProgressMs', 'rootProgressMs'])
          key: List<int>.from(metrics[key]! as List<Object?>),
        for (final key in [
          'singleProgressMs',
          'boundaryProgressDeltaMs',
          'randomCallsAtChange',
          'noRestartObservedMs',
        ])
          key: metrics[key]!,
        'acousticGapMeasured': false,
      },
  };
}

/// Requires exactly one canonical success for the current SHA, never raw errors.
Map<String, Object> parseRootNativeShuffleLog(String log, String sourceCommit) {
  if (log.length > 4 * 1024 * 1024) {
    throw const FormatException('Root shuffle log exceeds limit');
  }
  final matches = RegExp(r'YYMUSIC_ROOT_NATIVE_SHUFFLE_RESULT ([^\r\n]*)')
      .allMatches(log)
      .toList();
  if (matches.length != 1) {
    throw const FormatException('Expected one final root shuffle report');
  }
  try {
    final decoded = jsonDecode(matches.single.group(1)!);
    if (decoded is! Map<String, Object?> || decoded['testCount'] is! int) {
      throw const FormatException();
    }
    final result = rootNativeShuffleResult(
      sourceCommit: sourceCommit,
      testsPassed: decoded['passed'] == true,
      testCount: decoded['testCount']! as int,
      metrics: decoded['metrics'],
    );
    if (result['passed'] != true || jsonEncode(result) != jsonEncode(decoded)) {
      throw const FormatException();
    }
    return result;
  } catch (_) {
    throw const FormatException('Invalid or failed root shuffle report');
  }
}
