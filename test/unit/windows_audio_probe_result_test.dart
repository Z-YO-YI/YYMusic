import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/support/windows_audio_probe_result.dart';

void main() {
  const commit = '4db58997ffe16a62da204344578a5f4b7fd9c320';
  final metrics = <String, Object>{
    'platform': 'windows',
    'completed': true,
    'proxyForHeaders': false,
    'requestHeaders': false,
    'loadMs': 20,
    'firstProgressMs': 190,
    'seekMs': 10,
    'durationMs': 3000,
    'untrusted': 'private-file-path-or-token',
  };
  Map<String, Object> result({
    bool passed = true,
    int count = 1,
    Object? evidence,
    String diagnostic = 'native-poc.failed',
  }) => windowsAudioProbeResult(
    sourceCommit: commit,
    nativeCommit: commit,
    testsPassed: passed,
    testCount: count,
    metrics: evidence,
    diagnosticId: diagnostic,
  );

  test('success requires one completed real test and bounded metrics', () {
    final record = result(evidence: metrics);
    expect(record['passed'], isTrue);
    expect(record['diagnosticId'], 'native-poc.passed');
    expect(record['nativeMetrics'], {
      'loadMs': 20,
      'firstProgressMs': 190,
      'seekMs': 10,
      'durationMs': 3000,
    });
    expect(jsonEncode(record), isNot(contains('private-file')));
  });

  test('missing metrics or zero/multiple tests never count as success', () {
    for (final record in [
      result(),
      result(count: 0, evidence: metrics),
      result(count: 2, evidence: metrics),
      result(passed: false, evidence: metrics),
    ]) {
      expect(record['passed'], isFalse);
      expect(record.containsKey('nativeMetrics'), isFalse);
    }
  });

  test('invalid timing, platform or enabled proxies fail closed', () {
    for (final change in <Map<String, Object>>[
      {'durationMs': 0},
      {'durationMs': 10000},
      {'loadMs': -1},
      {'firstProgressMs': double.nan},
      {'seekMs': 'private-token'},
      {'platform': 'android'},
      {'completed': false},
      {'proxyForHeaders': true},
      {'requestHeaders': true},
    ]) {
      expect(result(evidence: {...metrics, ...change})['passed'], isFalse);
    }
  });

  test('timeouts and invalid diagnostics cannot masquerade as passes', () {
    expect(
      result(evidence: metrics, diagnostic: 'native-poc.timeout')['passed'],
      isFalse,
    );
    expect(() => result(diagnostic: 'raw-private-error'), throwsArgumentError);
    expect(
      () => windowsAudioProbeResult(
        sourceCommit: '../invalid',
        nativeCommit: commit,
        testsPassed: true,
        testCount: 1,
        metrics: metrics,
      ),
      throwsArgumentError,
    );
  });

  final https = <String, Object>{
    'platform': 'windows',
    'fixtureSha256':
        '1b35cc093f3d56732b19ff936c21b5bca8195135d63708f6c6488eba5803ddce',
    'fixtureVerified': true,
    'rangeVerified': true,
    'completed': true,
    'disposed': true,
    'proxyForHeaders': false,
    'requestHeaders': false,
    'loadMs': 100,
    'firstProgressMs': 170,
    'seekMs': 7,
    'durationMs': 1000,
    'private': 'private-URL-or-credentials',
  };
  Map<String, Object> httpsResult({Object? evidence, int count = 2}) =>
      windowsAudioProbeResult(
        sourceCommit: commit,
        nativeCommit: commit,
        testsPassed: true,
        testCount: count,
        metrics: metrics,
        includeHttps: true,
        httpsMetrics: evidence,
      );
  test('HTTPS mode requires both original WAV and verified HTTPS and strips extras', () {
    final record = httpsResult(evidence: https);
    expect(record['passed'], isTrue);
    expect(record['testCount'], 2);
    expect(record['includeHttps'], isTrue);
    expect(jsonEncode(record), isNot(contains('private-')));
    for (final count in [0, 1, 3]) {
      expect(httpsResult(evidence: https, count: count)['passed'], isFalse);
    }
    expect(httpsResult()['passed'], isFalse);
  });
  test(
    'HTTPS fixture drift, incomplete lifecycle and invalid metrics fail closed',
    () {
      for (final change in <Map<String, Object>>[
        {'fixtureSha256': '0' * 64},
        {'fixtureVerified': false},
        {'rangeVerified': false},
        {'disposed': false},
        {'completed': false},
        {'durationMs': 3000},
        {'loadMs': -1},
        {'seekMs': double.nan},
        {'platform': 'android'},
        {'requestHeaders': true},
        {'proxyForHeaders': true},
      ]) {
        expect(httpsResult(evidence: {...https, ...change})['passed'], isFalse);
      }
    },
  );
}
