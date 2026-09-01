import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_credential_gateway.dart';

final class FlutterSecureStringStore implements SecureStringStore {
  const FlutterSecureStringStore(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
