import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:integration_test/integration_test.dart';

import 'just_audio_native_sequence_poc_test.dart' as sequence_poc;
import 'support/native_sequence_probe_result.dart';

/// Explicit Profile diagnostic; never part of the production or old audio probe.
void main() {
  const enabled = bool.fromEnvironment('YYMUSIC_WINDOWS_SEQUENCE_PROBE');
  const sourceCommit = String.fromEnvironment('YYMUSIC_SEQUENCE_SOURCE_COMMIT');
  const nativeCommit = String.fromEnvironment('YYMUSIC_PROBE_NATIVE_COMMIT');
  if (!kProfileMode ||
      !Platform.isWindows ||
      !enabled ||
      !RegExp(r'^[0-9a-f]{40}$').hasMatch(sourceCommit) ||
      sourceCommit != nativeCommit) {
    stderr.writeln(
      'YYMUSIC_WINDOWS_SEQUENCE_PROBE disabled-or-invalid-identity',
    );
    exit(64);
  }
  final resultFile = File('native-sequence-poc-result.json');
  if (resultFile.existsSync()) {
    stderr.writeln('YYMUSIC_WINDOWS_SEQUENCE_PROBE existing-result-refused');
    exit(64);
  }
  sequence_poc.main();
  unawaited(
    _report(
      IntegrationTestWidgetsFlutterBinding.instance,
      resultFile,
      sourceCommit,
      nativeCommit,
    ),
  );
}

Future<void> _report(
  IntegrationTestWidgetsFlutterBinding binding,
  File resultFile,
  String sourceCommit,
  String nativeCommit,
) async {
  var passed = false;
  var diagnostic = 'sequence-poc.failed';
  try {
    passed = await binding.allTestsPassed.future.timeout(
      const Duration(minutes: 3),
    );
  } on TimeoutException {
    diagnostic = 'sequence-poc.timeout';
  } catch (_) {
    diagnostic = 'sequence-poc.runner-failed';
  }
  final result = nativeSequenceProbeResult(
    sourceCommit: sourceCommit,
    nativeCommit: nativeCommit,
    testsPassed: passed,
    testCount: binding.results.length,
    metrics: binding.reportData?['nativeSequence'],
    diagnosticId: diagnostic,
  );
  try {
    await resultFile.writeAsString(jsonEncode(result), flush: true);
  } catch (_) {
    stderr.writeln('YYMUSIC_WINDOWS_SEQUENCE_PROBE result-write-failed');
    exit(74);
  }
  exit(result['passed'] == true ? 0 : 1);
}
