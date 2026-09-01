import 'domain_validation.dart';

enum SensitiveCredentialKind {
  apiKey,
  bearerToken,
  basic,
  oauthToken,
  customHeaders,
}

/// Ephemeral in-memory secret value. It must never be serialized to the DB.
final class SensitiveCredential {
  factory SensitiveCredential({
    required SensitiveCredentialKind kind,
    required Map<String, String> fields,
  }) {
    if (fields.isEmpty) {
      throw ArgumentError.value(fields, 'fields', 'must not be empty');
    }
    final copy = <String, String>{};
    for (final entry in fields.entries) {
      final key = DomainValidation.identifier(entry.key, 'credential field');
      if (entry.value.isEmpty) {
        throw ArgumentError.value(
          entry.value,
          key,
          'secret value must not be empty',
        );
      }
      copy[key] = entry.value;
    }
    return SensitiveCredential._(kind: kind, fields: Map.unmodifiable(copy));
  }

  const SensitiveCredential._({required this.kind, required this.fields});

  final SensitiveCredentialKind kind;
  final Map<String, String> fields;

  @override
  String toString() =>
      'SensitiveCredential(kind: ${kind.name}, fields: <redacted>)';
}
