import 'dart:convert';

import '../domain/models/sleep_timer_snapshot.dart';

/// Versioned, bounded record. Parsing has no storage or playback side effects.
abstract final class SleepTimerSnapshotCodec {
  static String encode(SleepTimerSnapshot value) => jsonEncode({
    'version': 1,
    'durationMinutes': value.durationMinutes,
    'deadlineUtc': value.deadline.toIso8601String(),
  });

  static SleepTimerSnapshot decode(String source) {
    // Never propagate parser errors that could embed stored input.
    try {
      if (source.length > 512) throw const FormatException();
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic> ||
          value.length != 3 ||
          value['version'] is! int ||
          value['version'] != 1 ||
          value['durationMinutes'] is! int ||
          value['deadlineUtc'] is! String) {
        throw const FormatException();
      }
      final rawDeadline = value['deadlineUtc'] as String;
      final deadline = DateTime.tryParse(rawDeadline);
      if (deadline == null ||
          !deadline.isUtc ||
          deadline.toIso8601String() != rawDeadline) {
        throw const FormatException();
      }
      return SleepTimerSnapshot(
        durationMinutes: value['durationMinutes'] as int,
        deadline: deadline,
      );
    } catch (_) {
      throw const FormatException('Invalid stored sleep timer');
    }
  }
}
