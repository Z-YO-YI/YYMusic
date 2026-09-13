import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/data/sleep_timer_snapshot_codec.dart';
import 'package:yymusic/domain/models/sleep_timer_snapshot.dart';

void main() {
  final deadline = DateTime.utc(2026, 9, 13, 2, 15, 0, 0, 123);
  Map<String, Object?> record() => {
    'version': 1,
    'durationMinutes': 15,
    'deadlineUtc': deadline.toIso8601String(),
  };

  for (final minutes in [15, 30, 60]) {
    test(
      '$minutes minute snapshot roundtrip preserves exact UTC and option',
      () {
        final value = SleepTimerSnapshot(
          durationMinutes: minutes,
          deadline: deadline.toLocal(),
        );
        final encoded = SleepTimerSnapshotCodec.encode(value);
        final restored = SleepTimerSnapshotCodec.decode(encoded);
        expect(restored, value);
        expect(restored.hashCode, value.hashCode);
        expect(restored.deadline.isUtc, isTrue);
        expect(restored.deadline, deadline);
        expect(restored.durationMinutes, minutes);
        expect((jsonDecode(encoded) as Map).keys, [
          'version',
          'durationMinutes',
          'deadlineUtc',
        ]);
      },
    );
  }

  for (final invalid in [0, -15, 1, 14, 16, 45, 90]) {
    test('reject unsupported original duration $invalid', () {
      expect(
        () => SleepTimerSnapshot(durationMinutes: invalid, deadline: deadline),
        throwsFormatException,
      );
    });
  }

  test(
    'remaining uses absolute deadline, expiry boundary and clock rollback',
    () {
      final value = SleepTimerSnapshot(durationMinutes: 15, deadline: deadline);
      expect(
        value.remainingAt(deadline.subtract(const Duration(microseconds: 1))),
        const Duration(microseconds: 1),
      );
      expect(value.remainingAt(deadline), isNull);
      expect(
        value.remainingAt(deadline.add(const Duration(microseconds: 1))),
        isNull,
      );
      expect(
        value.remainingAt(deadline.subtract(const Duration(hours: 2))),
        const Duration(hours: 2),
      );
      expect(value.remainingAt(deadline.toLocal()), isNull);
      expect(value.durationMinutes, 15);
      expect(value.deadline, deadline);
    },
  );

  test('expired valid record remains distinguishable from corrupt record', () {
    final value = SleepTimerSnapshotCodec.decode(jsonEncode(record()));
    expect(value.remainingAt(deadline.add(const Duration(days: 1))), isNull);
    expect(
      SleepTimerSnapshotCodec.decode(SleepTimerSnapshotCodec.encode(value)),
      value,
    );
  });

  final invalidRecords = <String, Object?>{
    'missing version': record()..remove('version'),
    'future version': record()..['version'] = 2,
    'floating version': record()..['version'] = 1.0,
    'string duration': record()..['durationMinutes'] = '15',
    'floating duration': record()..['durationMinutes'] = 15.0,
    'unsupported duration': record()..['durationMinutes'] = 20,
    'null deadline': record()..['deadlineUtc'] = null,
    'offset instead of canonical UTC': record()
      ..['deadlineUtc'] = '2026-09-13T09:15:00.000+07:00',
    'timezone missing': record()..['deadlineUtc'] = '2026-09-13T02:15:00.000',
    'calendar overflow': record()..['deadlineUtc'] = '2026-09-32T02:15:00.000Z',
    'invalid text': record()..['deadlineUtc'] = 'private-record-text',
    'unexpected field': record()..['entryId'] = 'private-entry',
    'array': [record()],
    'null': null,
    'string': 'private-record-text',
  };
  for (final item in invalidRecords.entries) {
    test('reject ${item.key} without disclosing stored data', () {
      expect(
        () => SleepTimerSnapshotCodec.decode(jsonEncode(item.value)),
        throwsA(
          isA<FormatException>().having(
            (error) => error.toString(),
            'safe message',
            'FormatException: Invalid stored sleep timer',
          ),
        ),
      );
    });
  }
  test('malformed and oversized input fail with the same safe message', () {
    for (final source in ['{private-text', 'x' * 513]) {
      expect(
        () => SleepTimerSnapshotCodec.decode(source),
        throwsA(
          isA<FormatException>().having(
            (e) => e.source,
            'no input echoed',
            isNull,
          ),
        ),
      );
    }
  });
  test('value equality includes original choice and exact deadline', () {
    final value = SleepTimerSnapshot(durationMinutes: 15, deadline: deadline);
    expect(
      value,
      isNot(SleepTimerSnapshot(durationMinutes: 30, deadline: deadline)),
    );
    expect(
      value,
      isNot(
        SleepTimerSnapshot(
          durationMinutes: 15,
          deadline: deadline.add(const Duration(microseconds: 1)),
        ),
      ),
    );
    expect(value.toString(), 'SleepTimerSnapshot(<redacted>)');
  });
}
