import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/domain_failure.dart';
import '../../domain/models/lyrics.dart';
import '../../domain/models/track.dart';
import '../database/app_database.dart';

final class LyricsRowMapper {
  const LyricsRowMapper();

  LyricsCacheRecordsCompanion toCompanion(
    LyricsDocument document, {
    required DateTime updatedAt,
  }) {
    try {
      return LyricsCacheRecordsCompanion.insert(
        trackSourceType: document.track.sourceType.name,
        trackSourceId: document.track.sourceId,
        trackId: document.track.trackId,
        kind: document.kind.name,
        linesJson: jsonEncode(
          document.lines
              .map(
                (line) => <String, Object?>{
                  'startMs': line.start?.inMilliseconds,
                  'endMs': line.end?.inMilliseconds,
                  'text': line.text,
                  'translation': line.translation,
                },
              )
              .toList(growable: false),
        ),
        language: document.language,
        translationLanguage: Value(document.translationLanguage),
        offsetMs: Value(document.offset.inMilliseconds),
        updatedAtMs: updatedAt.toUtc().millisecondsSinceEpoch,
      );
    } catch (_) {
      throw _corrupted('encode');
    }
  }

  LyricsDocument fromRow(LyricsCacheRow row) {
    try {
      // Validate the persisted cache timestamp even though it is not exposed by
      // the current domain contract.
      DateTime.fromMillisecondsSinceEpoch(row.updatedAtMs, isUtc: true);
      final kind = LyricsKind.values.byName(row.kind);
      return LyricsDocument(
        track: TrackRef(
          trackId: row.trackId,
          sourceId: row.trackSourceId,
          sourceType: MusicSourceType.values.byName(row.trackSourceType),
        ),
        kind: kind,
        lines: _decodeLines(row.linesJson),
        language: row.language,
        translationLanguage: row.translationLanguage,
        offset: _duration(row.offsetMs),
      );
    } catch (_) {
      throw _corrupted('decode');
    }
  }

  List<LyricsLine> _decodeLines(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! List<Object?>) {
      throw const FormatException('Lyrics lines must be a JSON array');
    }
    final result = <LyricsLine>[];
    for (final value in decoded) {
      if (value is! Map<String, Object?> ||
          value.length != 4 ||
          !value.containsKey('startMs') ||
          !value.containsKey('endMs') ||
          !value.containsKey('text') ||
          !value.containsKey('translation')) {
        throw const FormatException('Invalid lyrics line shape');
      }
      final startMs = value['startMs'];
      final endMs = value['endMs'];
      final text = value['text'];
      final translation = value['translation'];
      if ((startMs != null && startMs is! int) ||
          (endMs != null && endMs is! int) ||
          text is! String ||
          (translation != null && translation is! String)) {
        throw const FormatException('Invalid lyrics line value');
      }
      final validStartMs = startMs as int?;
      final validEndMs = endMs as int?;
      result.add(
        LyricsLine(
          start: validStartMs == null ? null : _duration(validStartMs),
          end: validEndMs == null ? null : _duration(validEndMs),
          text: text,
          translation: translation as String?,
        ),
      );
    }
    return List<LyricsLine>.unmodifiable(result);
  }

  Duration _duration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    if (duration.inMilliseconds != milliseconds) {
      throw const FormatException('Lyrics duration is out of range');
    }
    return duration;
  }

  DomainFailure _corrupted(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'lyrics-row.$operation',
  );
}
