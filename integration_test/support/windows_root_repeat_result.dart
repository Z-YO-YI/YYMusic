import 'root_native_repeat_metrics.dart';

/// Windows Profile evidence is not interchangeable with the Android log report.
Map<String, Object> windowsRootRepeatResult({
  required String sourceCommit,
  required String nativeCommit,
  required bool testsPassed,
  required int testCount,
  required Object? metrics,
}) {
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(sourceCommit) ||
      sourceCommit != nativeCommit) {
    throw ArgumentError('Invalid Windows root probe identity');
  }
  final projected = projectRootNativeRepeatMetrics(
    sourceCommit: sourceCommit,
    platform: RootRepeatPlatform.windows,
    metrics: metrics,
  );
  final passed = testsPassed && testCount == 1 && projected != null;
  return {
    'schemaVersion': 1,
    'sourceCommit': sourceCommit,
    'nativeCommit': nativeCommit,
    'platform': 'windows',
    'purpose': 'isolated-windows-root-repeat-test',
    'passed': passed,
    'testCount': testCount,
    'diagnosticId': passed
        ? 'windows-root-repeat.passed'
        : 'windows-root-repeat.failed',
    if (passed) 'metrics': projected,
  };
}
