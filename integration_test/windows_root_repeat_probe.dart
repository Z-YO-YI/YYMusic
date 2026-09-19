import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import 'support/root_native_repeat_metrics.dart';
import 'support/root_native_repeat_scenario.dart';
import 'support/windows_root_repeat_result.dart';

/// Isolated, opt-in Profile entry. Never imported by the production app.
void main() {
  const enabled = bool.fromEnvironment('YYMUSIC_WINDOWS_ROOT_REPEAT_PROBE');
  const sourceCommit = String.fromEnvironment(
    'YYMUSIC_ROOT_REPEAT_SOURCE_COMMIT',
  );
  const nativeCommit = String.fromEnvironment('YYMUSIC_PROBE_NATIVE_COMMIT');
  if (!kProfileMode ||
      !Platform.isWindows ||
      !enabled ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(sourceCommit) ||
      sourceCommit != nativeCommit) {
    stderr.writeln(
      'YYMUSIC_WINDOWS_ROOT_REPEAT_PROBE disabled-or-invalid-identity',
    );
    exit(64);
  }
  final resultFile = File('root-native-repeat-poc-result.json');
  if (resultFile.existsSync()) {
    stderr.writeln('YYMUSIC_WINDOWS_ROOT_REPEAT_PROBE existing-result-refused');
    exit(64);
  }
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Map<String, Object>? metrics;
  registerRootNativeRepeatScenario(
    sourceCommit: sourceCommit,
    platform: RootRepeatPlatform.windows,
    onMetrics: (value) => metrics = value,
  );
  unawaited(() async {
    var passed = false;
    try {
      passed = await binding.allTestsPassed.future.timeout(
        const Duration(minutes: 3),
      );
    } catch (_) {
      // No raw plugin, path, exception or stack is copied into the result.
    }
    final result = windowsRootRepeatResult(
      sourceCommit: sourceCommit,
      nativeCommit: nativeCommit,
      testsPassed: passed,
      testCount: binding.results.length,
      metrics: metrics,
    );
    try {
      await resultFile.writeAsString(jsonEncode(result), flush: true);
    } catch (_) {
      stderr.writeln('YYMUSIC_WINDOWS_ROOT_REPEAT_PROBE result-write-failed');
      exit(74);
    }
    exit(result['passed'] == true ? 0 : 1);
  }());
}
