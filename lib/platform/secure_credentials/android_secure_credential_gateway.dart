import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'flutter_secure_string_store.dart';
import 'secure_storage_credential_gateway.dart';

final class AndroidSecureCredentialGateway
    extends SecureStorageCredentialGateway {
  AndroidSecureCredentialGateway({super.referenceGenerator})
    : super(
        secureStore: const FlutterSecureStringStore(
          FlutterSecureStorage(
            aOptions: AndroidOptions(
              resetOnError: false,
              migrateOnAlgorithmChange: true,
              migrateWithBackup: true,
              storageNamespace: 'yymusic_credentials_v1',
            ),
          ),
        ),
      );

  AndroidSecureCredentialGateway.withStore({
    required super.secureStore,
    super.referenceGenerator,
  });
}
