import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/lyrics.dart';
import 'package:yymusic/domain/models/lyrics_timeline.dart';

import '../support/lyrics_fixture.dart';

void main() {
  final ref = lyricsTracks.first.ref;
  final standard = LyricsTimeline(timedLyrics(ref));
  for (final (seconds, expected) in [
    (-1, null),
    (0, null),
    (9, null),
    (10, 0),
    (19, 0),
    (20, 1),
    (30, 2),
    (39, 2),
    (40, null),
    (100, null),
  ]) {
    test('half-open intervals at $seconds seconds return $expected', () {
      expect(standard.activeIndex(Duration(seconds: seconds)), expected);
    });
  }

  test('positive offset delays display and seek at microsecond precision', () {
    final timeline = LyricsTimeline(
      timedLyrics(ref, offset: const Duration(microseconds: 1000001)),
    );
    expect(timeline.activeIndex(const Duration(seconds: 11)), isNull);
    expect(timeline.activeIndex(const Duration(microseconds: 11000001)), 0);
    expect(timeline.seekTarget(0), const Duration(microseconds: 11000001));
  });

  test('negative offset advances display and clamps negative seek to zero', () {
    final timeline = LyricsTimeline(
      timedLyrics(ref, offset: const Duration(seconds: -15)),
    );
    expect(timeline.activeIndex(Duration.zero), 0);
    expect(timeline.seekTarget(0), Duration.zero);
    expect(timeline.seekTarget(1), const Duration(seconds: 5));
    expect(timeline.activeIndex(const Duration(seconds: 25)), isNull);
  });

  test(
    'duplicates, gaps, zero length and expired overlap are deterministic',
    () {
      final timeline = LyricsTimeline(
        _document([(0, 100), (10, 15), (10, 20), (30, 30), (40, 45)]),
      );
      expect(timeline.activeIndex(const Duration(seconds: 9)), 0);
      expect(timeline.activeIndex(const Duration(seconds: 10)), 2);
      expect(timeline.activeIndex(const Duration(seconds: 20)), isNull);
      expect(timeline.activeIndex(const Duration(seconds: 30)), isNull);
      expect(timeline.activeIndex(const Duration(seconds: 40)), 4);
      expect(timeline.activeIndex(const Duration(seconds: 45)), isNull);
    },
  );

  test(
    'plain bilingual document stays unchanged and cannot highlight or seek',
    () {
      final document = LyricsDocument(
        track: ref,
        kind: LyricsKind.plain,
        language: 'en',
        translationLanguage: 'zh',
        lines: [LyricsLine(text: 'Actual text', translation: '实际文本')],
      );
      final timeline = LyricsTimeline(document);
      expect(timeline.document, same(document));
      expect(timeline.activeIndex(const Duration(seconds: 30)), isNull);
      expect(timeline.seekTarget(0), isNull);
    },
  );

  test(
    'invalid indices and target at or beyond known duration are rejected',
    () {
      expect(standard.seekTarget(-1), isNull);
      expect(standard.seekTarget(3), isNull);
      expect(standard.seekTarget(0, duration: Duration.zero), isNull);
      expect(
        standard.seekTarget(0, duration: const Duration(seconds: -1)),
        isNull,
      );
      expect(
        standard.seekTarget(0, duration: const Duration(seconds: 10)),
        isNull,
      );
      expect(
        standard.seekTarget(1, duration: const Duration(seconds: 15)),
        isNull,
      );
      expect(
        standard.seekTarget(0, duration: const Duration(seconds: 11)),
        const Duration(seconds: 10),
      );
      expect(standard.seekTarget(2), const Duration(seconds: 30));
    },
  );

  test('extreme offsets never wrap native signed microsecond arithmetic', () {
    const max = 0x7fffffffffffffff;
    final positive = LyricsTimeline(
      timedLyrics(ref, offset: const Duration(microseconds: max)),
    );
    expect(positive.activeIndex(Duration.zero), isNull);
    expect(positive.seekTarget(0), isNull);
    final negative = LyricsTimeline(
      timedLyrics(ref, offset: const Duration(microseconds: -max - 1)),
    );
    expect(negative.activeIndex(Duration.zero), isNull);
    expect(negative.activeIndex(const Duration(microseconds: max)), isNull);
    expect(negative.seekTarget(0), Duration.zero);
    final edge = LyricsTimeline(
      LyricsDocument(
        track: ref,
        kind: LyricsKind.synchronized,
        language: 'en',
        lines: [
          LyricsLine(
            start: const Duration(microseconds: max - 2),
            end: const Duration(microseconds: max),
            text: 'Edge',
          ),
        ],
      ),
    );
    expect(edge.activeIndex(const Duration(microseconds: max - 1)), 0);
    expect(edge.activeIndex(const Duration(microseconds: max)), isNull);
    expect(edge.seekTarget(0), const Duration(microseconds: max - 2));
  });

  test(
    'binary lookup matches a linear oracle for large overlapping timelines',
    () {
      final random = Random(75);
      final lines = <(int, int)>[];
      var start = 0;
      for (var i = 0; i < 10000; i++) {
        start += random.nextInt(4);
        lines.add((start, start + random.nextInt(8)));
      }
      final timeline = LyricsTimeline(_document(lines));
      for (var i = 0; i < 1000; i++) {
        final time = random.nextInt(start + 10);
        var candidate = -1;
        for (var index = 0; index < lines.length; index++) {
          if (lines[index].$1 > time) break;
          candidate = index;
        }
        final expected = candidate >= 0 && time < lines[candidate].$2
            ? candidate
            : null;
        expect(timeline.activeIndex(Duration(seconds: time)), expected);
      }
    },
  );
}

LyricsDocument _document(List<(int, int)> ranges) => LyricsDocument(
  track: lyricsTracks.first.ref,
  kind: LyricsKind.synchronized,
  language: 'en',
  lines: [
    for (final (start, end) in ranges)
      LyricsLine(
        start: Duration(seconds: start),
        end: Duration(seconds: end),
        text: 'Test line',
      ),
  ],
);
