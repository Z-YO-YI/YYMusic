import 'domain_validation.dart';
import 'track.dart';

enum LyricsKind { plain, synchronized }

final class LyricsLine {
  LyricsLine({
    Duration? start,
    Duration? end,
    required String text,
    String? translation,
  }) : start = start,
       end = end,
       text = DomainValidation.text(text, 'text', maxLength: 4096),
       translation = translation == null
           ? null
           : DomainValidation.text(
               translation,
               'translation',
               maxLength: 4096,
             ) {
    if ((start == null) != (end == null)) {
      throw ArgumentError(
        'Lyrics start and end must both be present or absent',
      );
    }
    if (start != null && (start.isNegative || end!.isNegative || end < start)) {
      throw ArgumentError('Lyrics time range must be non-negative and ordered');
    }
  }

  final Duration? start;
  final Duration? end;
  final String text;
  final String? translation;
}

final class LyricsDocument {
  factory LyricsDocument({
    required TrackRef track,
    required LyricsKind kind,
    required Iterable<LyricsLine> lines,
    required String language,
    String? translationLanguage,
    Duration offset = Duration.zero,
  }) {
    final copy = List<LyricsLine>.unmodifiable(lines);
    if (copy.isEmpty) {
      throw ArgumentError.value(copy, 'lines', 'must not be empty');
    }
    final synchronized = kind == LyricsKind.synchronized;
    if (copy.any((line) => (line.start != null) != synchronized)) {
      throw ArgumentError('Lyrics line timing must match document kind');
    }
    if (synchronized) {
      for (var index = 1; index < copy.length; index++) {
        if (copy[index].start! < copy[index - 1].start!) {
          throw ArgumentError(
            'Synchronized lyrics must be sorted by start time',
          );
        }
      }
    }
    final hasTranslation = copy.any((line) => line.translation != null);
    if (hasTranslation != (translationLanguage != null)) {
      throw ArgumentError(
        'translationLanguage must match translated line content',
      );
    }
    return LyricsDocument._(
      track: track,
      kind: kind,
      lines: copy,
      language: DomainValidation.text(language, 'language', maxLength: 64),
      translationLanguage: translationLanguage == null
          ? null
          : DomainValidation.text(
              translationLanguage,
              'translationLanguage',
              maxLength: 64,
            ),
      offset: offset,
    );
  }

  const LyricsDocument._({
    required this.track,
    required this.kind,
    required this.lines,
    required this.language,
    required this.translationLanguage,
    required this.offset,
  });

  final TrackRef track;
  final LyricsKind kind;
  final List<LyricsLine> lines;
  final String language;
  final String? translationLanguage;
  final Duration offset;
}
