import '../../domain/models/sensitive_credential.dart';

abstract interface class SecureCredentialGateway {
  Future<String> saveCredential(SensitiveCredential credential);
  Future<SensitiveCredential?> readCredential(String reference);
  Future<void> deleteCredential(String reference);
}
