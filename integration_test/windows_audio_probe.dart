import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import 'just_audio_native_local_poc_test.dart' as native_poc;
import 'support/windows_audio_probe_result.dart';

/// Development-only entry point for a verified Windows Debug runtime copy.
void main() {
  const enabled = bool.fromEnvironment('YYMUSIC_WINDOWS_AUDIO_PROBE');
  const sourceCommit = String.fromEnvironment('YYMUSIC_PROBE_SOURCE_COMMIT');
  const nativeCommit = String.fromEnvironment('YYMUSIC_PROBE_NATIVE_COMMIT');
  final commitPattern = RegExp(r'^[0-9a-f]{40}$');
  if (!kDebugMode ||
      !Platform.isWindows ||
      !enabled ||
      !commitPattern.hasMatch(sourceCommit) ||
      !commitPattern.hasMatch(nativeCommit)) {
    stderr.writeln('YYMUSIC_WINDOWS_AUDIO_PROBE disabled-or-invalid-identity');
    exit(64);
  }

  final resultFile = File('native-audio-poc-result.json');
  if (resultFile.existsSync()) {
    stderr.writeln('YYMUSIC_WINDOWS_AUDIO_PROBE existing-result-refused');
    exit(64);
  }
  native_poc.main();
  final binding = IntegrationTestWidgetsFlutterBinding.instance;
  unawaited(_report(binding, resultFile, sourceCommit, nativeCommit));
}

Future<void> _report(
  IntegrationTestWidgetsFlutterBinding binding,
  File resultFile,
  String sourceCommit,
  String nativeCommit,
) async {
  var passed = false;
  var diagnostic = 'native-poc.failed';
  try {
    passed = await binding.allTestsPassed.future.timeout(
      const Duration(minutes: 3),
    );
  } on TimeoutException {
    diagnostic = 'native-poc.timeout';
  } catch (_) {
    diagnostic = 'native-poc.runner-failed';
  }
  // Never persist failure details: plugin exceptions can include local paths.
  final Object? metrics = binding.reportData?['nativeAudio'];
  final result = windowsAudioProbeResult(
    sourceCommit: sourceCommit,
    nativeCommit: nativeCommit,
    testsPassed: passed,
    testCount: binding.results.length,
    metrics: metrics,
    diagnosticId: diagnostic,
  );
  try {
    await resultFile.writeAsString(jsonEncode(result), flush: true);
  } catch (_) {
    stderr.writeln('YYMUSIC_WINDOWS_AUDIO_PROBE result-write-failed');
    exit(74);
  }
  // Per-test teardown has completed before allTestsPassed is resolved.
  exit(result['passed'] == true ? 0 : 1);
}
