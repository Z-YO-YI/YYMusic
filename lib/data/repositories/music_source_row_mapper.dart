import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models/domain_failure.dart';
import '../../domain/models/music_source.dart';
import '../../domain/models/track.dart';
import '../database/app_database.dart';

final class MusicSourceRowMapper {
  const MusicSourceRowMapper();

  MusicSourceRecordsCompanion toCompanion(MusicSourceConfig source) {
    try {
      return MusicSourceRecordsCompanion.insert(
        sourceId: source.id,
        name: source.name,
        sourceType: source.type.name,
        baseUrl: Value(source.baseUrl?.toString()),
        authType: source.authType.name,
        credentialRef: Value(source.credentialRef),
        publicHeadersJson: Value(_encodeMap(source.publicHeaders)),
        endpointsJson: Value(_encodeMap(source.endpoints)),
        responseMappingJson: Value(_encodeMap(source.responseMapping)),
        enabled: Value(source.enabled),
        status: Value(source.status.name),
        lastLatencyMs: Value(source.lastLatency?.inMilliseconds),
        lastTestedAtMs: Value(
          source.lastTestedAt?.toUtc().millisecondsSinceEpoch,
        ),
        lastErrorCode: Value(source.lastErrorCode?.name),
        builtIn: Value(source.builtIn),
      );
    } catch (_) {
      throw _corrupted('encode');
    }
  }

  MusicSourceConfig fromRow(MusicSourceRow row) {
    try {
      return MusicSourceConfig(
        id: row.sourceId,
        name: row.name,
        type: MusicSourceType.values.byName(row.sourceType),
        baseUrl: row.baseUrl == null ? null : Uri.parse(row.baseUrl!),
        authType: MusicSourceAuthType.values.byName(row.authType),
        credentialRef: row.credentialRef,
        publicHeaders: _decodeMap(row.publicHeadersJson),
        endpoints: _decodeMap(row.endpointsJson),
        responseMapping: _decodeMap(row.responseMappingJson),
        enabled: row.enabled,
        status: MusicSourceStatus.values.byName(row.status),
        lastLatency: row.lastLatencyMs == null
            ? null
            : _duration(row.lastLatencyMs!),
        lastTestedAt: row.lastTestedAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                row.lastTestedAtMs!,
                isUtc: true,
              ),
        lastErrorCode: row.lastErrorCode == null
            ? null
            : DomainFailureCode.values.byName(row.lastErrorCode!),
        builtIn: row.builtIn,
      );
    } catch (_) {
      throw _corrupted('decode');
    }
  }

  String _encodeMap(Map<String, String> source) {
    final keys = source.keys.toList()..sort();
    return jsonEncode(<String, String>{
      for (final key in keys) key: source[key]!,
    });
  }

  Map<String, String> _decodeMap(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Source configuration must be a JSON object');
    }
    final result = <String, String>{};
    for (final entry in decoded.entries) {
      if (entry.value is! String) {
        throw const FormatException(
          'Source configuration values must be strings',
        );
      }
      result[entry.key] = entry.value! as String;
    }
    return Map<String, String>.unmodifiable(result);
  }

  Duration _duration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    if (duration.inMilliseconds != milliseconds) {
      throw const FormatException('Source latency is out of range');
    }
    return duration;
  }

  DomainFailure _corrupted(String operation) => DomainFailure(
    code: DomainFailureCode.databaseCorrupted,
    diagnosticId: 'music-source-row.$operation',
  );
}
