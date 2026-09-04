import '../domain/models/domain_validation.dart';
import '../domain/models/track.dart';

enum PlayableSourceKind { localFile, contentUri, networkStream }

/// Ephemeral input for an [AudioEngine]. It must never be persisted or logged.
final class PlayableSource {
  factory PlayableSource.localFile({
    required TrackRef track,
    required String path,
  }) {
    final safePath = DomainValidation.text(path, 'path', maxLength: 4096);
    final isAbsolute =
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(safePath) ||
        safePath.startsWith(r'\\') ||
        safePath.startsWith('/');
    if (!isAbsolute) {
      throw ArgumentError.value(path, 'path', 'must be an absolute path');
    }
    return PlayableSource._(
      track: track,
      kind: PlayableSourceKind.localFile,
      localPath: safePath,
      uri: null,
      headers: const {},
    );
  }

  factory PlayableSource.contentUri({
    required TrackRef track,
    required Uri uri,
  }) {
    if (uri.scheme != 'content' || !uri.hasAuthority) {
      throw ArgumentError.value(
        uri,
        'uri',
        'must be an absolute Android content URI',
      );
    }
    return PlayableSource._(
      track: track,
      kind: PlayableSourceKind.contentUri,
      localPath: null,
      uri: uri,
      headers: const {},
    );
  }

  factory PlayableSource.networkStream({
    required TrackRef track,
    required Uri uri,
    Map<String, String> headers = const {},
  }) {
    if (uri.scheme != 'https' || !uri.hasAuthority || uri.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        uri,
        'uri',
        'must be an absolute credential-free HTTPS URI',
      );
    }
    return PlayableSource._(
      track: track,
      kind: PlayableSourceKind.networkStream,
      localPath: null,
      uri: uri,
      headers: _validatedHeaders(headers),
    );
  }

  const PlayableSource._({
    required this.track,
    required this.kind,
    required this.localPath,
    required this.uri,
    required this.headers,
  });

  final TrackRef track;
  final PlayableSourceKind kind;
  final String? localPath;
  final Uri? uri;

  /// Transient request headers, including runtime authorization when required.
  /// Callers must not persist or log this map.
  final Map<String, String> headers;

  @override
  String toString() =>
      'PlayableSource(track: $track, kind: ${kind.name}, '
      'locator: <redacted>, headers: <redacted>)';
}

Map<String, String> _validatedHeaders(Map<String, String> values) {
  final result = <String, String>{};
  final normalizedNames = <String>{};
  for (final entry in values.entries) {
    final name = entry.key;
    final lower = name.toLowerCase();
    if (name.trim() != name ||
        !normalizedNames.add(lower) ||
        !RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$").hasMatch(name)) {
      throw ArgumentError.value(name, 'headers', 'contains an invalid name');
    }
    final value = DomainValidation.text(
      entry.value,
      'header value',
      maxLength: 8192,
    );
    if (value.contains('\r') || value.contains('\n')) {
      throw ArgumentError('Header values must not contain line breaks');
    }
    result[name] = value;
  }
  return Map.unmodifiable(result);
}
