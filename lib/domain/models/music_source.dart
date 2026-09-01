import 'domain_failure.dart';
import 'domain_validation.dart';
import 'track.dart';

enum MusicSourceAuthType {
  none,
  system,
  apiKey,
  bearer,
  basic,
  oauth,
  customHeaders,
}

enum MusicSourceStatus {
  disconnected,
  testing,
  connected,
  error,
  disabled,
  unauthorized,
  rateLimited,
  schemaMismatch,
  offline,
}

final class MusicSourceConfig {
  factory MusicSourceConfig({
    required String id,
    required String name,
    required MusicSourceType type,
    Uri? baseUrl,
    required MusicSourceAuthType authType,
    String? credentialRef,
    Map<String, String> publicHeaders = const {},
    Map<String, String> endpoints = const {},
    Map<String, String> responseMapping = const {},
    bool enabled = false,
    MusicSourceStatus status = MusicSourceStatus.disconnected,
    Duration? lastLatency,
    DateTime? lastTestedAt,
    DomainFailureCode? lastErrorCode,
    bool builtIn = false,
  }) {
    if (type == MusicSourceType.local && baseUrl != null) {
      throw ArgumentError('Local sources must not have a baseUrl');
    }
    if (type == MusicSourceType.rest &&
        (baseUrl == null ||
            baseUrl.scheme != 'https' ||
            !baseUrl.hasAuthority ||
            baseUrl.userInfo.isNotEmpty ||
            baseUrl.hasQuery ||
            baseUrl.hasFragment)) {
      throw ArgumentError(
        'REST sources require a credential-free absolute HTTPS base URL',
      );
    }
    if (lastLatency != null && lastLatency.isNegative) {
      throw ArgumentError.value(
        lastLatency,
        'lastLatency',
        'must not be negative',
      );
    }
    final safeHeaders = _publicHeaders(publicHeaders);
    final safeEndpoints = _endpoints(endpoints);
    final safeMapping = _responseMapping(responseMapping);
    return MusicSourceConfig._(
      id: DomainValidation.identifier(id, 'id'),
      name: DomainValidation.text(name, 'name', maxLength: 512),
      type: type,
      baseUrl: baseUrl,
      authType: authType,
      credentialRef: credentialRef == null
          ? null
          : DomainValidation.identifier(credentialRef, 'credentialRef'),
      publicHeaders: safeHeaders,
      endpoints: safeEndpoints,
      responseMapping: safeMapping,
      enabled: enabled,
      status: status,
      lastLatency: lastLatency,
      lastTestedAt: lastTestedAt == null
          ? null
          : DomainValidation.utc(lastTestedAt, 'lastTestedAt'),
      lastErrorCode: lastErrorCode,
      builtIn: builtIn,
    );
  }

  const MusicSourceConfig._({
    required this.id,
    required this.name,
    required this.type,
    required this.baseUrl,
    required this.authType,
    required this.credentialRef,
    required this.publicHeaders,
    required this.endpoints,
    required this.responseMapping,
    required this.enabled,
    required this.status,
    required this.lastLatency,
    required this.lastTestedAt,
    required this.lastErrorCode,
    required this.builtIn,
  });

  final String id;
  final String name;
  final MusicSourceType type;
  final Uri? baseUrl;
  final MusicSourceAuthType authType;
  final String? credentialRef;
  final Map<String, String> publicHeaders;
  final Map<String, String> endpoints;
  final Map<String, String> responseMapping;
  final bool enabled;
  final MusicSourceStatus status;
  final Duration? lastLatency;
  final DateTime? lastTestedAt;
  final DomainFailureCode? lastErrorCode;
  final bool builtIn;
}

Map<String, String> _publicHeaders(Map<String, String> values) {
  final result = <String, String>{};
  final normalizedNames = <String>{};
  for (final entry in values.entries) {
    final name = entry.key.trim();
    final lower = name.toLowerCase();
    if (name != entry.key || !normalizedNames.add(lower)) {
      throw ArgumentError(
        'Public header names must be trimmed and unique ignoring case',
      );
    }
    final sensitive =
        lower == 'authorization' ||
        lower == 'proxy-authorization' ||
        lower == 'cookie' ||
        lower == 'set-cookie' ||
        lower == 'x-api-key' ||
        lower == 'api-key' ||
        lower == 'apikey' ||
        lower.endsWith('-key') ||
        lower.contains('token') ||
        lower.contains('secret') ||
        lower.contains('password') ||
        lower.contains('credential');
    if (sensitive) {
      throw ArgumentError.value(
        name,
        'publicHeaders',
        'contains a sensitive header name',
      );
    }
    if (!RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$").hasMatch(name)) {
      throw ArgumentError.value(
        name,
        'publicHeaders',
        'contains an invalid header name',
      );
    }
    DomainValidation.text(name, 'public header name', maxLength: 128);
    final value = DomainValidation.text(
      entry.value,
      'public header value',
      maxLength: 2048,
    );
    if (value.contains('\r') || value.contains('\n')) {
      throw ArgumentError('Public header values must not contain line breaks');
    }
    result[name] = value;
  }
  return Map.unmodifiable(result);
}

Map<String, String> _endpoints(Map<String, String> values) {
  final result = <String, String>{};
  for (final entry in values.entries) {
    final key = DomainValidation.identifier(entry.key, 'endpoint key');
    final path = entry.value;
    if (!path.startsWith('/') || path.contains('://')) {
      throw ArgumentError.value(
        path,
        'endpoint path',
        'must be a relative absolute path',
      );
    }
    result[key] = DomainValidation.text(path, 'endpoint path', maxLength: 2048);
  }
  return Map.unmodifiable(result);
}

Map<String, String> _responseMapping(Map<String, String> values) {
  final result = <String, String>{};
  final allowed = RegExp(r'^[A-Za-z0-9_$.[\]-]{1,160}$');
  for (final entry in values.entries) {
    final key = DomainValidation.identifier(entry.key, 'mapping key');
    if (!allowed.hasMatch(entry.value)) {
      throw ArgumentError.value(
        entry.value,
        'response mapping',
        'must be a restricted field path, not executable code',
      );
    }
    result[key] = entry.value;
  }
  return Map.unmodifiable(result);
}
