import 'dart:convert';

import 'root_native_repeat_metrics.dart';

/// Whitelists evidence from the isolated Android root test after its teardown.
Map<String, Object> rootNativeRepeatResult({
  required String sourceCommit,
  required bool testsPassed,
  required int testCount,
  required Object? metrics,
}) {
  final projected = projectRootNativeRepeatMetrics(
    sourceCommit: sourceCommit,
    platform: RootRepeatPlatform.android,
    metrics: metrics,
  );
  final passed = testsPassed && testCount == 1 && projected != null;
  return {
    'schemaVersion': 1,
    'sourceCommit': sourceCommit,
    'platform': 'android',
    'purpose': 'isolated-root-native-repeat-test',
    'passed': passed,
    'testCount': testCount,
    'diagnosticId': passed ? 'root-repeat.passed' : 'root-repeat.failed',
    if (passed) 'metrics': projected,
  };
}

/// Host-side gate: exactly one final, successful, canonical report for this SHA.
/// Raw log contents never appear in exceptions or the returned evidence.
Map<String, Object> parseRootNativeRepeatLog(String log, String sourceCommit) {
  if (log.length > 4 * 1024 * 1024) {
    throw const FormatException('Root native probe log exceeds limit');
  }
  final matches = RegExp(r'YYMUSIC_ROOT_NATIVE_REPEAT_RESULT ([^\r\n]*)')
      .allMatches(log)
      .toList();
  if (matches.length != 1) {
    throw const FormatException('Expected one final root native report');
  }
  try {
    final decoded = jsonDecode(matches.single.group(1)!);
    if (decoded is! Map<String, Object?> || decoded['testCount'] is! int) {
      throw const FormatException();
    }
    final result = rootNativeRepeatResult(
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
    throw const FormatException('Invalid or failed root native report');
  }
}
