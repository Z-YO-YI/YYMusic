import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'flutter_secure_string_store.dart';
import 'secure_storage_credential_gateway.dart';

final class WindowsSecureCredentialGateway
    extends SecureStorageCredentialGateway {
  WindowsSecureCredentialGateway({super.referenceGenerator})
    : super(
        secureStore: const FlutterSecureStringStore(
          FlutterSecureStorage(
            wOptions: WindowsOptions(useBackwardCompatibility: false),
          ),
        ),
      );

  WindowsSecureCredentialGateway.withStore({
    required super.secureStore,
    super.referenceGenerator,
  });
}
