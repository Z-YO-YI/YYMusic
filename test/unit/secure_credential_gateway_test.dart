import 'package:flutter_test/flutter_test.dart';
import 'package:yymusic/domain/models/sensitive_credential.dart';
import 'package:yymusic/platform/contracts/secure_credential_gateway.dart';
import 'package:yymusic/platform/secure_credentials/android_secure_credential_gateway.dart';
import 'package:yymusic/platform/secure_credentials/secure_storage_credential_gateway.dart';
import 'package:yymusic/platform/secure_credentials/windows_secure_credential_gateway.dart';

void main() {
  group('Android and Windows secure credential gateways', () {
    for (final platform in ['android', 'windows']) {
      test('$platform saves, reads and idempotently deletes', () async {
        final store = _MemorySecureStringStore();
        final reference = _reference(platform == 'android' ? 'A' : 'W');
        final gateway = platform == 'android'
            ? AndroidSecureCredentialGateway.withStore(
                secureStore: store,
                referenceGenerator: () => reference,
              )
            : WindowsSecureCredentialGateway.withStore(
                secureStore: store,
                referenceGenerator: () => reference,
              );
        final credential = SensitiveCredential(
          kind: SensitiveCredentialKind.bearerToken,
          fields: const {'value': 'alpha'},
        );

        expect(await gateway.saveCredential(credential), reference);
        final restored = await gateway.readCredential(reference);
        expect(restored?.kind, SensitiveCredentialKind.bearerToken);
        expect(restored?.fields, const {'value': 'alpha'});

        await gateway.deleteCredential(reference);
        await gateway.deleteCredential(reference);
        expect(await gateway.readCredential(reference), isNull);
      });
    }
  });

  test(
    'uses deterministic versioned JSON and survives gateway recreation',
    () async {
      final store = _MemorySecureStringStore();
      final reference = _reference('C');
      final first = SecureStorageCredentialGateway(
        secureStore: store,
        referenceGenerator: () => reference,
      );
      final credential = SensitiveCredential(
        kind: SensitiveCredentialKind.customHeaders,
        fields: const {'z': 'last', 'a': 'first'},
      );

      await first.saveCredential(credential);

      expect(
        store.values[_storageKey(reference)],
        '{"schemaVersion":1,"kind":"customHeaders",'
        '"fields":{"a":"first","z":"last"}}',
      );
      final second = SecureStorageCredentialGateway(secureStore: store);
      final restored = await second.readCredential(reference);
      expect(restored?.kind, SensitiveCredentialKind.customHeaders);
      expect(restored?.fields, const {'a': 'first', 'z': 'last'});
    },
  );

  test('round-trips every credential kind with immutable fields', () async {
    final store = _MemorySecureStringStore();
    var next = 0;
    final gateway = SecureStorageCredentialGateway(
      secureStore: store,
      referenceGenerator: () => _indexedReference(next++),
    );

    for (final kind in SensitiveCredentialKind.values) {
      final reference = await gateway.saveCredential(
        SensitiveCredential(kind: kind, fields: const {'value': 'sample'}),
      );
      final restored = await gateway.readCredential(reference);
      expect(restored?.kind, kind);
      expect(restored?.fields, const {'value': 'sample'});
      expect(
        () => restored!.fields['extra'] = 'changed',
        throwsUnsupportedError,
      );
    }
  });

  test('never overwrites a colliding reference', () async {
    final store = _MemorySecureStringStore();
    final occupied = _reference('D');
    final fresh = _reference('E');
    store.values[_storageKey(occupied)] =
        '{"schemaVersion":1,"kind":"apiKey","fields":{"v":"old"}}';
    final references = [occupied, fresh].iterator;
    final gateway = SecureStorageCredentialGateway(
      secureStore: store,
      referenceGenerator: () {
        references.moveNext();
        return references.current;
      },
    );

    expect(
      await gateway.saveCredential(
        SensitiveCredential(
          kind: SensitiveCredentialKind.apiKey,
          fields: const {'v': 'new'},
        ),
      ),
      fresh,
    );
    expect(store.values[_storageKey(occupied)], contains('"old"'));
    expect(store.values[_storageKey(fresh)], contains('"new"'));
  });

  test('rejects invalid references before touching platform storage', () async {
    final store = _MemorySecureStringStore();
    final gateway = SecureStorageCredentialGateway(secureStore: store);

    final readFailure = await _captureFailure(
      gateway.readCredential('../outside-marker'),
    );
    expect(readFailure.operation, SecureCredentialOperation.read);
    expect(readFailure.kind, SecureCredentialFailureKind.invalidReference);

    final deleteFailure = await _captureFailure(
      gateway.deleteCredential('cred_too-short'),
    );
    expect(deleteFailure.operation, SecureCredentialOperation.delete);
    expect(deleteFailure.kind, SecureCredentialFailureKind.invalidReference);
    expect(store.readCount, 0);
    expect(store.deleteCount, 0);
    expect(readFailure.toString(), isNot(contains('outside-marker')));
  });

  test(
    'rejects corrupt or noncanonical payloads without leaking them',
    () async {
      final store = _MemorySecureStringStore();
      final reference = _reference('F');
      final gateway = SecureStorageCredentialGateway(secureStore: store);
      final corruptPayloads = <String>[
        'not-json-private-marker',
        '[]',
        '{"schemaVersion":2,"kind":"apiKey","fields":{"v":"x"}}',
        '{"schemaVersion":1,"kind":"unknown","fields":{"v":"x"}}',
        '{"schemaVersion":1,"kind":"apiKey","fields":{}}',
        '{"schemaVersion":1,"kind":"apiKey","fields":{"v":1}}',
        '{ "schemaVersion": 1, "kind": "apiKey", '
            '"fields": {"v": "x"} }',
        '{"kind":"apiKey","schemaVersion":1,"fields":{"v":"x"}}',
        '{"schemaVersion":1,"kind":"apiKey","fields":{"v":"x"},'
            '"extra":"private-marker"}',
      ];

      for (final payload in corruptPayloads) {
        store.values[_storageKey(reference)] = payload;
        final failure = await _captureFailure(
          gateway.readCredential(reference),
        );
        expect(failure.operation, SecureCredentialOperation.read);
        expect(failure.kind, SecureCredentialFailureKind.invalidPayload);
        expect(failure.toString(), isNot(contains('private-marker')));
        expect(failure.toString(), isNot(contains(reference)));
      }
    },
  );

  test('redacts platform failures for save, read and delete', () async {
    final reference = _reference('G');
    final credential = SensitiveCredential(
      kind: SensitiveCredentialKind.oauthToken,
      fields: const {'value': 'memory-only-marker'},
    );

    final writeStore = _MemorySecureStringStore()..failWrite = true;
    final saveFailure = await _captureFailure(
      SecureStorageCredentialGateway(
        secureStore: writeStore,
        referenceGenerator: () => reference,
      ).saveCredential(credential),
    );
    expect(saveFailure.operation, SecureCredentialOperation.save);
    expect(saveFailure.kind, SecureCredentialFailureKind.storageUnavailable);

    final readStore = _MemorySecureStringStore()..failRead = true;
    final readFailure = await _captureFailure(
      SecureStorageCredentialGateway(secureStore: readStore)
          .readCredential(reference),
    );
    expect(readFailure.operation, SecureCredentialOperation.read);

    final deleteStore = _MemorySecureStringStore()..failDelete = true;
    final deleteFailure = await _captureFailure(
      SecureStorageCredentialGateway(secureStore: deleteStore)
          .deleteCredential(reference),
    );
    expect(deleteFailure.operation, SecureCredentialOperation.delete);

    for (final failure in [saveFailure, readFailure, deleteFailure]) {
      expect(failure.kind, SecureCredentialFailureKind.storageUnavailable);
      expect(failure.toString(), isNot(contains('backend-private-marker')));
      expect(failure.toString(), isNot(contains('memory-only-marker')));
      expect(failure.toString(), isNot(contains(reference)));
    }
  });

  test(
    'serializes concurrent operations and keeps references unique',
    () async {
      final store = _MemorySecureStringStore(delayOperations: true);
      var next = 0;
      final gateway = SecureStorageCredentialGateway(
        secureStore: store,
        referenceGenerator: () => _indexedReference(next++),
      );
      final credential = SensitiveCredential(
        kind: SensitiveCredentialKind.basic,
        fields: const {'one': 'alpha', 'two': 'bravo'},
      );

      final references = await Future.wait(
        List<Future<String>>.generate(
          12,
          (_) => gateway.saveCredential(credential),
        ),
      );

      expect(references.toSet(), hasLength(12));
      expect(store.values, hasLength(12));
      expect(store.maximumActiveOperations, 1);
    },
  );

  test('fails closed for invalid generators and oversized values', () async {
    final invalidGeneratorFailure = await _captureFailure(
      SecureStorageCredentialGateway(
        secureStore: _MemorySecureStringStore(),
        referenceGenerator: () => 'predictable',
      ).saveCredential(
        SensitiveCredential(
          kind: SensitiveCredentialKind.apiKey,
          fields: const {'v': 'alpha'},
        ),
      ),
    );
    expect(
      invalidGeneratorFailure.kind,
      SecureCredentialFailureKind.referenceGenerationFailed,
    );

    final oversizedFailure = await _captureFailure(
      SecureStorageCredentialGateway(
        secureStore: _MemorySecureStringStore(),
        referenceGenerator: () => _reference('H'),
      ).saveCredential(
        SensitiveCredential(
          kind: SensitiveCredentialKind.apiKey,
          fields: {'v': List<String>.filled(16385, 'x').join()},
        ),
      ),
    );
    expect(oversizedFailure.kind, SecureCredentialFailureKind.invalidPayload);
    expect(oversizedFailure.toString(), isNot(contains('xxxx')));
  });
}

Future<SecureCredentialFailure> _captureFailure(
  Future<Object?> operation,
) async {
  try {
    await operation;
  } on SecureCredentialFailure catch (failure) {
    return failure;
  }
  throw TestFailure('Expected SecureCredentialFailure');
}

String _reference(String character) =>
    'cred_${List<String>.filled(32, character).join()}';

String _indexedReference(int index) =>
    'cred_${index.toRadixString(16).padLeft(32, '0')}';

String _storageKey(String reference) => 'yymusic_credential_$reference';

final class _MemorySecureStringStore implements SecureStringStore {
  _MemorySecureStringStore({this.delayOperations = false});

  final bool delayOperations;
  final Map<String, String> values = {};
  var failRead = false;
  var failWrite = false;
  var failDelete = false;
  var readCount = 0;
  var deleteCount = 0;
  var _activeOperations = 0;
  var maximumActiveOperations = 0;

  @override
  Future<String?> read(String key) => _track(() {
    readCount += 1;
    if (failRead) throw StateError('backend-private-marker');
    return values[key];
  });

  @override
  Future<void> write(String key, String value) => _track(() {
    if (failWrite) throw StateError('backend-private-marker');
    values[key] = value;
  });

  @override
  Future<void> delete(String key) => _track(() {
    deleteCount += 1;
    if (failDelete) throw StateError('backend-private-marker');
    values.remove(key);
  });

  Future<T> _track<T>(T Function() action) async {
    _activeOperations += 1;
    maximumActiveOperations = maximumActiveOperations < _activeOperations
        ? _activeOperations
        : maximumActiveOperations;
    try {
      if (delayOperations) await Future<void>.delayed(Duration.zero);
      return action();
    } finally {
      _activeOperations -= 1;
    }
  }
}
