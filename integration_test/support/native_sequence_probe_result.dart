/// Produces only bounded, whitelisted evidence after the native test runner ends.
Map<String, Object> nativeSequenceProbeResult({
  required String sourceCommit,
  required String nativeCommit,
  required bool testsPassed,
  required int testCount,
  required Object? metrics,
  String diagnosticId = 'sequence-poc.failed',
}) {
  final commit = RegExp(r'^[0-9a-f]{40}$');
  if (!commit.hasMatch(sourceCommit) ||
      !commit.hasMatch(nativeCommit) ||
      sourceCommit != nativeCommit) {
    throw ArgumentError('Invalid sequence probe identity');
  }
  const diagnostics = {
    'sequence-poc.failed',
    'sequence-poc.timeout',
    'sequence-poc.runner-failed',
  };
  if (!diagnostics.contains(diagnosticId)) {
    throw ArgumentError('Invalid sequence probe diagnostic');
  }
  bool exactIndices(Object? value) =>
      value is List<Object?> &&
      value.length == 3 &&
      List.generate(
        3,
        (index) => index,
      ).every((index) => value[index] is int && value[index] == index);
  final progress = <int>[];
  var valid = false;
  if (metrics is Map<String, Object?>) {
    valid =
        metrics['sourceCommit'] == sourceCommit &&
        metrics['platform'] == 'windows' &&
        exactIndices(metrics['observedIndices']) &&
        exactIndices(metrics['observedCycles']) &&
        metrics['appendAccepted'] == true &&
        metrics['pruneAccepted'] == true &&
        metrics['retainAccepted'] == true &&
        metrics['completedAtIndex'] is int &&
        metrics['completedAtIndex'] == 2 &&
        metrics['disposed'] == true &&
        metrics['acousticGapMeasured'] == false;
    final positions = metrics['progressMs'];
    if (positions is List<Object?> && positions.length == 3) {
      for (final value in positions) {
        if (value is int && value >= 100 && value <= 10000) {
          progress.add(value);
        }
      }
    }
    valid = valid && progress.length == 3;
  }
  final passed =
      testsPassed &&
      testCount == 1 &&
      valid &&
      diagnosticId == 'sequence-poc.failed';
  return {
    'schemaVersion': 1,
    'sourceCommit': sourceCommit,
    'nativeCommit': nativeCommit,
    'platform': 'windows',
    'purpose': 'isolated-native-sequence-test',
    'passed': passed,
    'testCount': testCount,
    'diagnosticId': passed ? 'sequence-poc.passed' : diagnosticId,
    if (passed)
      'sequenceMetrics': {
        'observedIndices': [0, 1, 2],
        'observedCycles': [0, 1, 2],
        'progressMs': progress,
        'appendAccepted': true,
        'pruneAccepted': true,
        'retainAccepted': true,
        'completedAtIndex': 2,
        'disposed': true,
        'acousticGapMeasured': false,
      },
  };
}
