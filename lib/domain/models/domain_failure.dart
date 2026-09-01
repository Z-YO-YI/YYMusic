import 'domain_validation.dart';

enum DomainFailureCode {
  permissionDenied,
  permissionPermanentlyDenied,
  localFileMissing,
  unsupportedAudioFormat,
  metadataReadFailed,
  playbackOpenFailed,
  playbackInterrupted,
  networkOffline,
  networkTimeout,
  tlsFailed,
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  serverError,
  schemaMismatch,
  streamUrlExpired,
  sourceDisabled,
  sourceRemoved,
  secureStorageUnavailable,
  databaseCorrupted,
  unknown,
}

/// A safe failure envelope. Raw exception text, URLs and headers stay outside it.
final class DomainFailure implements Exception {
  DomainFailure({
    required this.code,
    required String diagnosticId,
    String? sourceId,
    this.retryable = false,
  }) : diagnosticId = _safeDiagnosticId(diagnosticId),
       sourceId = sourceId == null
           ? null
           : DomainValidation.identifier(sourceId, 'sourceId');

  final DomainFailureCode code;
  final String diagnosticId;
  final String? sourceId;
  final bool retryable;

  @override
  String toString() =>
      'DomainFailure(code: ${code.name}, diagnosticId: $diagnosticId, '
      'sourceId: ${sourceId ?? '-'}, retryable: $retryable)';
}

String _safeDiagnosticId(String value) {
  final id = DomainValidation.identifier(value, 'diagnosticId');
  if (!RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(id)) {
    throw ArgumentError.value(
      value,
      'diagnosticId',
      'must use a log-safe identifier',
    );
  }
  return id;
}
