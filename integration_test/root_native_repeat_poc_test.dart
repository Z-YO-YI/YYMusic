import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import 'support/root_native_repeat_metrics.dart';
import 'support/root_native_repeat_result.dart';
import 'support/root_native_repeat_scenario.dart';

/// Explicit Android entry; its log and result contracts remain unchanged.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const commit = String.fromEnvironment('YYMUSIC_ROOT_REPEAT_SOURCE_COMMIT');
  Map<String, Object>? metrics;
  registerRootNativeRepeatScenario(
    sourceCommit: commit,
    platform: RootRepeatPlatform.android,
    onMetrics: (value) => metrics = value,
  );
  // The host gate also requires flutter test's successful exit. Teardown failure,
  // absent/duplicate output or another test cannot be upgraded to success.
  unawaited(() async {
    var passed = false;
    try {
      passed = await binding.allTestsPassed.future.timeout(
        const Duration(minutes: 4),
      );
    } catch (_) {
      /* Report only the fixed failure diagnostic. */
    }
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) return;
    final result = rootNativeRepeatResult(
      sourceCommit: commit,
      testsPassed: passed,
      testCount: binding.results.length,
      metrics: metrics,
    );
    debugPrintSynchronously(
      'YYMUSIC_ROOT_NATIVE_REPEAT_RESULT ${jsonEncode(result)}',
    );
  }());
}
