import 'dart:convert';
import 'dart:io';

import '../integration_test/support/root_native_repeat_result.dart';

/// Run only after the native Flutter command exits successfully.
void main(List<String> arguments) {
  try {
    if (arguments.length != 2) throw const FormatException();
    final record = parseRootNativeRepeatLog(
      File(arguments[0]).readAsStringSync(),
      arguments[1],
    );
    stdout.writeln(
      'Verified Android root native evidence: ${jsonEncode(record)}',
    );
  } catch (_) {
    stderr.writeln('Missing, failed or invalid Android root native evidence');
    exitCode = 1;
  }
}
