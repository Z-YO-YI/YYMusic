import 'dart:convert';
import 'dart:io';

import '../integration_test/support/root_native_shuffle_result.dart';

/// Run only after the independent native Flutter test exits successfully.
void main(List<String> arguments) {
  try {
    if (arguments.length != 2) throw const FormatException();
    final record = parseRootNativeShuffleLog(
      File(arguments[0]).readAsStringSync(),
      arguments[1],
    );
    stdout.writeln(
      'Verified Android root shuffle evidence: ${jsonEncode(record)}',
    );
  } catch (_) {
    stderr.writeln('Missing, failed or invalid Android root shuffle evidence');
    exitCode = 1;
  }
}
