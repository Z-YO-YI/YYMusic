import '../../domain/models/sensitive_credential.dart';

enum SecureCredentialOperation { save, read, delete }

enum SecureCredentialFailureKind {
  invalidReference,
  invalidPayload,
  storageUnavailable,
  referenceGenerationFailed,
}

/// Log-safe failure. Platform exceptions, references and secret values are
/// intentionally not retained.
final class SecureCredentialFailure implements Exception {
  const SecureCredentialFailure({required this.operation, required this.kind});

  final SecureCredentialOperation operation;
  final SecureCredentialFailureKind kind;

  @override
  String toString() =>
      'SecureCredentialFailure(operation: ${operation.name}, '
      'kind: ${kind.name}, details: <redacted>)';
}

abstract interface class SecureCredentialGateway {
  Future<String> saveCredential(SensitiveCredential credential);
  Future<SensitiveCredential?> readCredential(String reference);
  Future<void> deleteCredential(String reference);
}
