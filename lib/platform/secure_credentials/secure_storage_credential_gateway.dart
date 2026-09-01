import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../domain/models/sensitive_credential.dart';
import '../contracts/secure_credential_gateway.dart';

abstract interface class SecureStringStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

typedef CredentialReferenceGenerator = String Function();

final Random _credentialRandom = Random.secure();

String generateSecureCredentialReference() {
  final bytes = List<int>.generate(
    24,
    (_) => _credentialRandom.nextInt(256),
    growable: false,
  );
  return 'cred_${base64UrlEncode(bytes).replaceAll('=', '')}';
}

/// Versioned codec and serialized access around a platform secure string store.
/// Secret payloads are never returned in exceptions or written to the database.
base class SecureStorageCredentialGateway implements SecureCredentialGateway {
  SecureStorageCredentialGateway({
    required SecureStringStore secureStore,
    CredentialReferenceGenerator? referenceGenerator,
  }) : _store = secureStore,
       _referenceGenerator =
           referenceGenerator ?? generateSecureCredentialReference;

  static final RegExp _referencePattern = RegExp(r'^cred_[A-Za-z0-9_-]{32}$');
  static const int _maxReferenceAttempts = 8;
  static const int _maxFields = 64;
  static const int _maxFieldValueLength = 16384;
  static const int _maxPayloadBytes = 65536;
  static const Set<String> _payloadKeys = {'schemaVersion', 'kind', 'fields'};

  final SecureStringStore _store;
  final CredentialReferenceGenerator _referenceGenerator;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<String> saveCredential(SensitiveCredential credential) =>
      _serialized(() async {
        final payload = _encode(credential, SecureCredentialOperation.save);
        for (var attempt = 0; attempt < _maxReferenceAttempts; attempt += 1) {
          final reference = _nextReference();
          final key = _storageKey(reference, SecureCredentialOperation.save);
          if (await _readRaw(key, SecureCredentialOperation.save) != null) {
            continue;
          }
          await _writeRaw(key, payload);
          return reference;
        }
        throw const SecureCredentialFailure(
          operation: SecureCredentialOperation.save,
          kind: SecureCredentialFailureKind.referenceGenerationFailed,
        );
      });

  @override
  Future<SensitiveCredential?> readCredential(String reference) =>
      _serialized(() async {
        final key = _storageKey(reference, SecureCredentialOperation.read);
        final payload = await _readRaw(key, SecureCredentialOperation.read);
        if (payload == null) return null;
        return _decode(payload);
      });

  @override
  Future<void> deleteCredential(String reference) => _serialized(() async {
    final key = _storageKey(reference, SecureCredentialOperation.delete);
    try {
      await _store.delete(key);
    } catch (_) {
      throw const SecureCredentialFailure(
        operation: SecureCredentialOperation.delete,
        kind: SecureCredentialFailureKind.storageUnavailable,
      );
    }
  });

  Future<T> _serialized<T>(Future<T> Function() action) {
    final previous = _operationTail;
    final released = Completer<void>();
    _operationTail = released.future;
    return previous.then((_) => action()).whenComplete(() {
      if (!released.isCompleted) released.complete();
    });
  }

  String _nextReference() {
    try {
      final reference = _referenceGenerator();
      if (_referencePattern.hasMatch(reference)) return reference;
    } catch (_) {
      // Converted below into a log-safe generation failure.
    }
    throw const SecureCredentialFailure(
      operation: SecureCredentialOperation.save,
      kind: SecureCredentialFailureKind.referenceGenerationFailed,
    );
  }

  String _storageKey(String reference, SecureCredentialOperation operation) {
    if (!_referencePattern.hasMatch(reference)) {
      throw SecureCredentialFailure(
        operation: operation,
        kind: SecureCredentialFailureKind.invalidReference,
      );
    }
    return 'yymusic_credential_$reference';
  }

  Future<String?> _readRaw(
    String key,
    SecureCredentialOperation operation,
  ) async {
    try {
      return await _store.read(key);
    } catch (_) {
      throw SecureCredentialFailure(
        operation: operation,
        kind: SecureCredentialFailureKind.storageUnavailable,
      );
    }
  }

  Future<void> _writeRaw(String key, String payload) async {
    try {
      await _store.write(key, payload);
    } catch (_) {
      throw const SecureCredentialFailure(
        operation: SecureCredentialOperation.save,
        kind: SecureCredentialFailureKind.storageUnavailable,
      );
    }
  }

  String _encode(
    SensitiveCredential credential,
    SecureCredentialOperation operation,
  ) {
    try {
      if (credential.fields.length > _maxFields ||
          credential.fields.values.any(
            (value) => value.length > _maxFieldValueLength,
          )) {
        throw SecureCredentialFailure(
          operation: operation,
          kind: SecureCredentialFailureKind.invalidPayload,
        );
      }
      final keys = credential.fields.keys.toList()..sort();
      final fields = <String, String>{
        for (final key in keys) key: credential.fields[key]!,
      };
      final payload = jsonEncode(<String, Object>{
        'schemaVersion': 1,
        'kind': credential.kind.name,
        'fields': fields,
      });
      if (utf8.encode(payload).length > _maxPayloadBytes) {
        throw SecureCredentialFailure(
          operation: operation,
          kind: SecureCredentialFailureKind.invalidPayload,
        );
      }
      return payload;
    } on SecureCredentialFailure {
      rethrow;
    } catch (_) {
      throw SecureCredentialFailure(
        operation: operation,
        kind: SecureCredentialFailureKind.invalidPayload,
      );
    }
  }

  SensitiveCredential _decode(String payload) {
    try {
      if (utf8.encode(payload).length > _maxPayloadBytes) {
        throw _invalidPayload();
      }
      final Object? decoded = jsonDecode(payload);
      if (decoded is! Map<String, Object?> ||
          decoded.length != _payloadKeys.length ||
          !decoded.keys.toSet().containsAll(_payloadKeys) ||
          decoded['schemaVersion'] != 1 ||
          decoded['kind'] is! String) {
        throw _invalidPayload();
      }
      final Object? fieldsValue = decoded['fields'];
      if (fieldsValue is! Map<String, Object?> ||
          fieldsValue.isEmpty ||
          fieldsValue.length > _maxFields ||
          fieldsValue.values.any(
            (value) => value is! String || value.length > _maxFieldValueLength,
          )) {
        throw _invalidPayload();
      }
      final kindName = decoded['kind']! as String;
      SensitiveCredentialKind? kind;
      for (final candidate in SensitiveCredentialKind.values) {
        if (candidate.name == kindName) kind = candidate;
      }
      if (kind == null) throw _invalidPayload();
      final credential = SensitiveCredential(
        kind: kind,
        fields: fieldsValue.map(
          (key, value) => MapEntry(key, value! as String),
        ),
      );
      if (_encode(credential, SecureCredentialOperation.read) != payload) {
        throw _invalidPayload();
      }
      return credential;
    } on SecureCredentialFailure {
      rethrow;
    } catch (_) {
      throw _invalidPayload();
    }
  }

  SecureCredentialFailure _invalidPayload() => const SecureCredentialFailure(
    operation: SecureCredentialOperation.read,
    kind: SecureCredentialFailureKind.invalidPayload,
  );
}
