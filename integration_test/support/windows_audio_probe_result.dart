import 'pinned_https_audio_fixture.dart';

/// Builds a bounded, non-sensitive diagnostic record, never plugin errors.
Map<String, Object> windowsAudioProbeResult({
  required String sourceCommit,
  required String nativeCommit,
  required bool testsPassed,
  required int testCount,
  required Object? metrics,
  String diagnosticId = 'native-poc.failed',
  bool includeHttps = false,
  Object? httpsMetrics,
}) {
  final commit = RegExp(r'^[0-9a-f]{40}$');
  if (!commit.hasMatch(sourceCommit) || !commit.hasMatch(nativeCommit)) {
    throw ArgumentError('Invalid probe commit identity');
  }
  const diagnostics = {
    'native-poc.failed',
    'native-poc.timeout',
    'native-poc.runner-failed',
  };
  if (!diagnostics.contains(diagnosticId)) {
    throw ArgumentError('Invalid probe diagnostic');
  }
  final safeMetrics = <String, Object>{};
  var metricsValid = false;
  if (metrics is Map<String, Object>) {
    metricsValid =
        metrics['platform'] == 'windows' &&
        metrics['completed'] == true &&
        metrics['proxyForHeaders'] == false &&
        metrics['requestHeaders'] == false;
    for (final key in ['loadMs', 'firstProgressMs', 'seekMs', 'durationMs']) {
      final value = metrics[key];
      if (value is! int || value < 0 || value > 20000) {
        metricsValid = false;
      } else {
        safeMetrics[key] = value;
      }
    }
    final duration = safeMetrics['durationMs'];
    metricsValid =
        metricsValid && duration is int && duration >= 2900 && duration <= 3100;
  }
  final safeHttps = <String, Object>{};
  var httpsValid = !includeHttps;
  if (includeHttps && httpsMetrics is Map<String, Object>) {
    httpsValid =
        httpsMetrics['platform'] == 'windows' &&
        httpsMetrics['fixtureSha256'] == httpsFixtureSha256 &&
        httpsMetrics['fixtureVerified'] == true &&
        httpsMetrics['rangeVerified'] == true &&
        httpsMetrics['completed'] == true &&
        httpsMetrics['disposed'] == true &&
        httpsMetrics['proxyForHeaders'] == false &&
        httpsMetrics['requestHeaders'] == false;
    for (final key in ['loadMs', 'firstProgressMs', 'seekMs', 'durationMs']) {
      final value = httpsMetrics[key];
      if (value is! int || value < 0 || value > 30000) {
        httpsValid = false;
      } else {
        safeHttps[key] = value;
      }
    }
    final duration = safeHttps['durationMs'];
    httpsValid =
        httpsValid && duration is int && duration >= 950 && duration <= 1050;
  }
  final passed =
      testsPassed &&
      testCount == (includeHttps ? 2 : 1) &&
      metricsValid &&
      httpsValid &&
      diagnosticId == 'native-poc.failed';
  return {
    'schemaVersion': 1,
    'sourceCommit': sourceCommit,
    'nativeCommit': nativeCommit,
    'platform': 'windows',
    'passed': passed,
    'testCount': testCount,
    'includeHttps': includeHttps,
    'diagnosticId': passed ? 'native-poc.passed' : diagnosticId,
    if (passed) 'nativeMetrics': safeMetrics,
    if (passed && includeHttps)
      'httpsMetrics': {
        ...safeHttps,
        'fixtureSha256': httpsFixtureSha256,
        'fixtureVerified': true,
        'rangeVerified': true,
      },
  };
}
